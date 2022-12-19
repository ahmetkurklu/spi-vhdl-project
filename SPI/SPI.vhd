library ieee;
use ieee.std_logic_1164.all;

entity SPI is
  port (
		  clk: in std_logic;
        clr: in std_logic;
        rd: in std_logic;
        wr: in std_logic;
        data_in: in std_logic_vector(7 downto 0);
        data_out: out std_logic_vector(7 downto 0);
        rdy : out std_logic;
        MOSI : out std_logic;
        MISO : in std_logic;
        SCK: out std_logic);
end entity;

architecture seq of SPI is

	--Fonction qui permet de faire le décalage a gauche
   function f_reg_dec (x: std_logic_vector; dec : std_logic) return std_logic_vector is 	
		begin
			return x(6 downto 0) & dec;
	end;
	
	--Déclaration du type pour la machine a état
	type t_state is (Repos, WaitRead,WaitWrite,Read,Write);
	signal state : t_state;
	
	--Compteurs
	signal cpt : integer range 0 to 8;
	signal cpt_sck : integer range 0 to 20;
	--signal intermediare qui va etre appliquer sur SCK
	signal sortie : std_logic;
	
	signal write_register : std_logic_vector(7 downto 0);
	signal read_register : std_logic_vector(7 downto 0);
	
begin
	process(clr,clk)
	variable shift_register : std_logic_vector(7 downto 0);
	begin
		if(clr = '1') then
			state <= Repos;
			rdy <= '1';
			sortie <='0';
		elsif(rising_edge(clk))then
			case state is
			when Repos => 		--Etat Repos dans lequel MOSI et SCK sont
				rdy <= '1';		-- a l'etat bas
				MOSI <= '0';
				sortie <='0';
				if(rd ='1')then --Quand rd = '1' on passe dans l'etat Read
					rdy<='0';
					state<=Read;
					cpt <= 0;
					cpt_sck <= 0;
				elsif(wr = '1')then  --Quand rd = '1' on passe dans l'etat WaitWrite
					rdy <= '0';			--on copie data_in sur write_register
					state <= WaitWrite;
					write_register <= data_in;
				end if;
			when WaitWrite => --Etat WaitWrite permet de faire une temporisation de
				shift_register := write_register; -- un cout d'horloge et le premier bit 
				MOSI <= shift_register(7);	--dans shift register est ecrit sur MOSI
				state <= Write; -- On passe ensuite a l'etat Write
				cpt_sck <= 0;
				cpt <= 0;
			when Write => 			--Etat Write pour l'ecriture 
				if(cpt < 8)then	
					if(cpt_sck < 19) then	--SCK controler par cpt_sck on inverse ça valeur
						cpt_sck <= cpt_sck+1;-- tout les 10 cout d'horloge de clk
						if(cpt_sck = 9)then
							sortie <= not(sortie);
						end if;
					else
						cpt_sck <= 0;		--A chaque fois que SCK est sur une nouvel periode
						sortie <= not(sortie);-- on fait un décalage a gauche sur shift_register
						cpt <= cpt +1;			--et on ecrit le 7ieme bit sur MOSI
						shift_register := f_reg_dec(shift_register,MISO);
						MOSI <= shift_register(7);
					end if;
				else
					sortie <= '0'; -- au bout de 8 décalage et ecriture on passe a l'etat Repos
					rdy <= '1';
					MOSI <='0';
					state <= Repos;
				end if;
			when Read =>	--Etat Read pour la lecture
				if(cpt < 8)then
					if(cpt_sck < 19) then  --SCK gerer de la même façon que l'etat Write
						cpt_sck <= cpt_sck+1;
						if(cpt_sck = 9)then
							sortie <= not(sortie);
							--A chaque front montant de SCK on lit la valeur sur MISO 
							shift_register := f_reg_dec(shift_register,MISO); 
						end if;
					else
						cpt_sck <= 0;
						sortie <= not(sortie);
						cpt <= cpt +1;
					end if;
				else
					sortie <= '0';	--au bout de 8 lecture on passe a l'etat WaitRead
					rdy <= '1';			
					read_register <= shift_register;
					state <= WaitRead;
				end if;
			when WaitRead => --etat Wait read
				data_out <= read_register;--Perme une temporisation de un cout d'horloge clk
				state <= Repos;--Pour la copie de read_register sur data_out 
			end case; --On passe ensuite a l'etat Repos
		end if;
	end process;	
	SCK <=sortie when state = Read else
			sortie when state = Write else
			'0';
end architecture;