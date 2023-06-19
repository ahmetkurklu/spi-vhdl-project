# spi-vhdl-project

## Introduction
The objective of this lab is to develop a "simplified" SPI (Serial Peripheral Interface) device and verify that its operation complies with its specifications. This device should be designed to be implemented on an FPGA (Field-Programmable Gate Array) and therefore described in a VHDL file.

### Load specifications

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/7303dae3-b320-4840-8827-e791054762fc)

## Conception

To implement the SPI peripheral, I have chosen to use a state machine. It consists of 5 states, which are as follows:

* Idle: This is the waiting state where the peripheral stays when the "clr" input is '1'. It waits for the "rd" or "wr" inputs to go to '1' to initiate a read or write action. When "rd" goes to '1', the "rdy" output goes to '0', the counters "cpt" and "cpt_sck" are initialized to 0, and the state of the machine transitions to the "Read" state. When "wr" goes to '1', the "rdy" output goes to '0', the "write_register" takes the data word from the "data_in" input, and the state transitions to the "WaitWrite" state. In this state, both the "MISO" and "SCK" outputs are low ('0').

* Read: The Read state is responsible for performing the read operation. In this state, on each falling edge of the "SCK" signal, a left shift operation is performed on the "shift_register" with the value from the "MISO" input. After 8 shifts controlled by the "cpt" counter, the "read_register" takes the word stored in the "shift_register", and the machine transitions to the "WaitRead" state.

* WaitRead: The WaitRead state simulates the delay before copying the "read_register" to the "data_out" output. It waits for one clock cycle before making this copy. Then, the machine transitions back to the Idle state.

* WaitWrite: The WaitWrite state simulates the delay before copying the "write_register" to the "shift_register". It waits for one clock cycle. The 7th bit of "shift_register" is placed on the "MOSI" output. The "cpt_sck" and "cpt" counters are initialized to 0, and the machine transitions to the Write state.

* Write: The Write state is responsible for performing the write operation. In this state, on each falling edge of the "SCK" signal, a left shift operation is performed on the "shift_register" with the value from the "MISO" input, and the 7th bit of "shift_register" is placed on the "MOSI" output. After 8 shifts controlled by the "cpt" counter, the machine transitions back to the Idle state.

The left shifts on the "shift_register" in the Write and Read states are performed using a function called "d_reg_dec". This function takes two parameters, a std_logic_vector X and a std_logic dec. The function performs concatenation between bits (6-0) of X and the dec bit, which corresponds to a left shift plus the dec bit.

The system clock "clk" operates at a frequency of 100MHz, while the SPI communication runs at 5MHz, which is 20 times slower. To address this, I use a counter "cpt_sck" that starts at 0 when entering one of the Read or Write states. This counter should be incremented 20 times, triggered by rising edges of the "clk" clock. Additionally, there is an output signal initially set to low, and this signal is assigned to the "SCK" output at the end of the process. In the Read or Write state, the "cpt_sck" counter is incremented, and after 10 increments, the output signal is inverted using the "not" function. Then, after 20 increments, the output signal is inverted again, and the "cpt_sck" counter is set back to 0. This action is repeated 8 times, controlled by the "cpt" counter to manage the number of shifts. In the end, we obtain an "SCK" signal running at 5MHz, which is 20 times slower than the 100MHz "clk" clock.

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/121eb3e7-6fe9-402f-810c-edb5f5c232b7)

We obtain this state machine using Quartus.

## Verification

To verify that our peripheral functions correctly, we will perform tests to validate the desired operating mode specified in the specifications document.

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/b1e5176d-adb7-490f-ad59-9fa354f731cb)

In this first screenshot, we can observe that the signal clr is '1' on the first rising edge, which sets rdy to '1'. The MOSI and SCK outputs are at a low state ('0'), indicating that we are in the "Repos" state. At 30 ns, both the rd and wr signals transition to '1' simultaneously. However, the read operation takes priority, so we enter the "Lecture" state. The rdy signal then transitions to '0', and the SCK clock starts. With each rising edge of SCK, we read the value of the MISO input. The system uses the configuration CPOL = 0 and CPHA = 0, which means that the MISO bit changes on each falling edge of SCK, and the read operation occurs on each rising edge of SCK. The SCK signal indeed has 8 rising edges, corresponding to the 8 bits in a byte. At the end of the last falling edge of SCK, the machine transitions to the "WaitRead" state to perform the copy operation from shift_register to data_out, which is then displayed.

On vérifie le résultat sur data_out :

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/6c715e4c-50e9-402b-8ac4-c91a4da2cb25)

The rising edges of SCK are indicated by the white lines, and the word to be read is therefore "10010101". We can observe that at the end of the "Lecture" state, the word displayed on data_out is indeed the same word, "10010101". Following the completion of the read operation, SCK transitions to '0', and rdy transitions to '1', causing the machine to enter the "Repos" state.

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/f9d49d35-c636-4ef1-bd2a-35f80c8dffc7)

In this second screenshot, we are testing the write operation. The wr signal transitions to '1' at 1700 ns, initiating the write operation and causing rdy to transition to '0'. The machine first enters the "WaitWrite" state to perform the copy operation from data_in to shift_register during one clock cycle. Then, the machine transitions to the "Write" state. SCK starts toggling, and at each rising edge, the 7th bit of shift_register is placed on the MOSI output. The system uses the configuration CPOL = 0 and CPHA = 0, so the write operation on MOSI occurs at each falling edge of SCK. We can observe that the write operation is performed 8 times for one byte, as there are 8 rising edges of SCK. At the end, the rdy signal transitions to '1', SCK transitions to '0', and MOSI transitions to '0'. The machine then returns to the "Repos" state.

We verify the result on MOSI:

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/62618568-a6e1-4425-9006-87eaddf88647)

The word on data_in is "10101010", and the rising edges of SCK are marked by white lines. We can observe that the word on data_in is correctly reflected on the MOSI output, indicating that the write operation is functioning properly.

We will now verify the SCK signal:

![image](https://github.com/ahmetkurklu/spi-vhdl-project/assets/24780090/c57f035d-a375-4efa-8497-b58834fda072)

Indeed, it is clear that one period of the SCK signal lasts for 20 periods of the clk signal, thus confirming that the specifications have been met.

## Conclusion

During this lab, we designed a simplified SPI peripheral using the Quartus software and simulated it using ModelSim. We learned how to implement a shift register and how to manage a system that operates with two clocks. We also learned how to implement our system on an FPGA.


