Automatic Transmission Model
============================

Files
-----

- `./run_falcaun_AT1_2.sh`: Script to falsify AT1 and AT2.
- `./run_falcaun_AT1_2_constrained.sh`: Script to falsify AT1 and AT2 with input constraints.
- `./run_falcaun_AT5.sh`: Script to falsify variants of AT51, AT52, AT53, AT54 with input constraint 1. We note that the specification is different from the original ones due to the limitation of FalCAuN. See the following remarks for the detail.
- `./run_falcaun_AT6.sh`: Script to falsify AT6a, AT6b, and AT6c.
- `./run_falcaun_AT6c_constrained.sh`: Script to falsify AT6c with input constraints.
- `Makefile`: Makefile to generate the documents for these scripts.
- `init_falcaun.m`: Initialization MATLAB script of AT for FalCAuN.

Usage
-----

To run the benchmark, execute the scripts above. For each script, a document can be generated by [ROBODoc](https://rfsber.home.xs4all.nl/Robo/index.html). An example is as follows.

```sh
make doc
```

Remarks for FalCAuN
-------------------

- We used signal step = 2.0. It did not work with signal step = 1.0 due to stack overflow. This is because the nest of the next operator becomes too deep for LTSMin.
- The interval in the `.stl` file is the half of the original because the signal step is 2.0.
- Due to the discrete-time semantics of FalCAuN, we cannot execute AT51, AT52, AT53, and AT54. Nevertheless, `run_falcaun_AT5.sh` contains variants of the original specifications. See `run_falcaun_AT5.sh` for the detail.
- Similarly, FalCAuN cannot handle the timing constraints in AT6a and AT6b if the input signal is constrained.
