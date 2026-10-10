# Synchronous FIFO specification

Implemented scope: fixed 8-bit data, 16 entries, one rising-edge clock, registered read output and active-low synchronous reset. No fall-through/bypass path or vendor IP. Other widths/depths are not implemented configurations of this revision.

## Interface

| Signal | Direction | Meaning |
|---|---|---|
| clk | Input | Common clock |
| rst_n | Input | Active-low synchronous reset |
| wr_en | Input | Write request |
| wdata[7:0] | Input | Write data |
| rd_en | Input | Read request |
| rdata[7:0] | Output | Registered read data |
| full | Output | Occupancy is 16 |
| empty | Output | Occupancy is 0 |

Occupancy and pointers are internal. The scoreboard maintains an independent expected occupancy from its reference queue.

## Requirements

| ID | Requirement |
|---|---|
| R01 | At a rising edge with rst_n low, reset takes priority: pointers, occupancy and rdata become zero. |
| R02 | Reset is synchronous; changing reset between rising edges does not itself update state. |
| R03 | On a non-reset rising edge accept write iff wr_en is high and pre-edge occupancy is below 16; store wdata and advance the write pointer. |
| R04 | Accept read iff rd_en is high and pre-edge occupancy is above zero; return the oldest entry and advance the read pointer. |
| R05 | Accepted read updates rdata after that edge's NBA/register updates, with no extra edge latency. Otherwise rdata holds, except on reset. |
| R06 | Occupancy changes by accepted writes minus accepted reads and remains in 0..16. |
| R07 | full and empty reflect current occupancy and cannot both be high. |
| R08 | Rejected writes do not change queued data/write pointer; rejected reads do not change read pointer/rdata. |
| R09 | Both requests use the same pre-edge state: at empty write only, at full read only, at intermediate occupancy both. No empty bypass or full replacement write. |
| R10 | Each pointer wraps from address 15 to 0; data order survives repeated wraparound. |
| R11 | Reset discards pending entries; memory need not be cleared because old entries are invalid until overwritten by accepted writes. |
| R12 | With neither request accepted, pointers, occupancy and rdata hold; flags remain consistent. |

## Timing contract

Inputs are stable before posedge. Monitor captures requests/data/pre-edge flags at posedge and registered outputs after DUT updates. Scoreboard derives acceptance from the reference queue size rather than trusting DUT flags, then checks those flags independently. Current driver/reset changes occur on negedge; current monitor waits 1 ns after posedge with a 10 ns clock.
