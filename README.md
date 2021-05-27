FalCAuN-ARCH-COMP
=================

[![Build](https://github.com/MasWag/FalCAuN-ARCH-COMP/workflows/shellcheck/badge.svg)](https://github.com/MasWag/FalCAuN-ARCH-COMP/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)


This repository contains the materials to execute [FalCAuN](https://github.com/MasWag/FalCAuN) with the benchmark for ARCH-COMP's [falsification](https://easychair.org/publications/paper/ps5t) track.

On the benchmarks
-----------------

FalCAuN can handle the following benchmarks

- AT
    - AT1
    - AT2
    - AT6a
    - AT6b
    - AT6c
- CC
    - CC1
    - CC2
    - CC3
- SC

FalCAuN cannot handle F16 benchmark because it is not a Simulink model but a pure MATLAB script, which is currently not supported.
