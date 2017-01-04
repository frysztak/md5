# Simple MD5 implementation in VHDL
MD5 hash function is implemented as a finite state machine.

## Entity description
* `clk`, `reset` - clock and reset.
* `data_in` - 32-bit input. Used to load message length and 32-bit chunks of message itself.
* `data_out` - 32-bit output. Used to output 32-bit chunks of calculated hash.
* `done` - 1-bit output. Set high when hash is done calculating and can be shifted out.
* `start` - 1-bit input. Depending on current state of the machine, it can either trigger loading of input message
(states `load_length` and `load_data`) or it can trigger the machine to output calculated hash.

## Functional description
Initially, machine resides in `idle` state. The only way to exit this state is to set input `start` to logical 1.
Doing so will trigger state change to `load_length`. In this state, machine expects to receive length of the
message to process, in bits.

One clock cycle later we're in `load_data` state. Actual loading of input data will start in the next cycle.
From this point on, 32-bit chunks of input message are latched on each rising edge, until they reach or exceed
message length specified previously.

MD5 specification requires input message to be padded in a specific way:
* append one '1' bit
* add zeroes to fill the buffer
* set last 64 bits to `message_length` (in bits)
All those steps are executed in state `pad`.

Following that, endianness of input message needs to be swapped (state `rotate`).

Now computation of the hash can finally begin. There are 4 main stages: 1, 2, 3 and 4. Each of those is further 
divided into `F` and `B`. `F` is computed first, because it's required to compute `B`.
State `stageN_F` (`N` is the stage number) only computes `F`, whereas `stageN_B` computes `B` and performs 
required shifts (A to D and so on). Machine jumps back and forth between `stageN_F` and `stageN_B`, each time 
incrementing `loop_counter`. Once 16 iterations are done, machine goes to the next stage.

Exiting `stage4_B`, machine enters `stage5`, where constants `a0`, `b0`, `c0`, `d0` are added to `A`, `B`, `C`, `D`
respectively. Following that, in `stage6` endianness of `ABCD` is swapped. This concludes computation stage.
Machine enters state `finished`, sets output `done` high, and awaits for the hash to be read.

Setting `start` high again triggers machine to enter `store_data` and output computed hash.
User can expect first chunk one rising edge later. Once four 32-bit chunks are shifted out, machine enters
`idle` state.

## State graph
![alt text][state_graph]

[state_graph]: graph.png
