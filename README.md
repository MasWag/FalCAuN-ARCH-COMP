FalCAuN-ARCH-COMP
=================

[![Build](https://github.com/MasWag/FalCAuN-ARCH-COMP/workflows/shellcheck/badge.svg)](https://github.com/MasWag/FalCAuN-ARCH-COMP/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)


This repository contains the materials to execute [FalCAuN](https://github.com/MasWag/FalCAuN) with the benchmark for ARCH-COMP's [falsification](https://easychair.org/publications/paper/ps5t) track.

Requirements
------------

To execute the scripts in this repository. You need to install [FalCAuN](https://github.com/MasWag/FalCAuN).

In addition to FalCAuN, you need to install the following tools.

- [MATLAB](https://www.mathworks.com/products/matlab.html) with Simulink and Stateflow. Some benchmarks require additional toolboxes.
- [kscript](https://github.com/kscripting/kscript)

Usage
-----

You can run the experiment by running the scripts, for example, `cd AT && ./AT1.main.kts`. Since the scripts are sensitive to the current directory, you need to run the scripts in the directory of the benchmark. You can also specify the number of repetitions, for example, `cd AT && ./AT1.main.kts 10`.

### Old scripts

For archival purposes, we keep the old shell scripts used until ARCH-COMP 2023. The usage is similar to the current scripts, for example, `cd ./AT && ./run_falcaun_AT1.sh`.

On the benchmarks
-----------------

FalCAuN can handle the following benchmarks

- `AT`
    - `AT1`
    - `AT2`
    - `AT6{a,b,c,abc}`
- `CC`
    - `CC1`
    - `CC2`
    - `CC3`
    - `CC4`
- `SC`
- `PM`


Note on the unsupported benchmarks
----------------------------------

### AFC (powertrain)

FalCAuN can execute the AFC model but for any requirements, it crashes due to stack overflow. This is because, in FalCAuN, `always_[11, 50]` is encoded to an LTL formulas with 50 nests of next operators, which is too large for its back-end model checker.

### AT (transmission)

FalCAuN can falsify AT1, AT2, and AT6{a,b,c,abc}. However, AT5{1,2,3,4} are infeasible because encoding of `ev_[0.001, 0.1]` is impossible or makes the LTL formula super huge (same as AFC).

### NN (neural)

Encoding of `always_[1.0, 37.0]` makes the LTL formula too large (same as AFC). 

<!-- ### WT -->

<!-- - WT1, WT2, WT3, WT4 -->

### CC (Chasing Cars)

FalCAuN can falsify CC1, CC2, CC3, and CC4.
However, CC5 and CCx are infeasible because the STL formulas are encoded to huge LTL formulas (same reason as AFC).

### F16 (f16-gcas)

FalCAuN cannot handle F16 benchmark because it is not a pure Simulink model but requires quite a lot of wrapper in MATLAB, which is currently not supported.

### SB (Synthetic Benchmark)

"Instance 1" is not available for SB benchmarks. FalCAuN does not support piecewise constant inputs.

<!-- ### sabo -->

<!-- FalCAuN cannot handle sabo benchmark because it is not a Simulink model but a model implemented in python. It is a future work to support such models. -->

