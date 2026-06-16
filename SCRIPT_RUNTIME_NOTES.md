# Kotlin Script Runtime Notes

The `.main.kts` scripts are executable entrypoints that run through `kscript`.
The bootstrap line at the top of each script records the local runtime assumptions
needed on this machine:

## Usage

Run every `.main.kts` script from the repository root:

```sh
./run_all_main_kts.sh
```

Pass an experiment count to all scripts by giving it as the first argument:

```sh
./run_all_main_kts.sh 10
```

For the standard 10-repetition batch, use the tiny wrapper:

```sh
./run_all_main_kts_10.sh
```

For a quick initialization check without running experiments:

```sh
./run_all_main_kts.sh 0
```

Each script is executed from its own benchmark directory, matching the documented
manual usage such as `cd AT && ./AT1.main.kts`.

## Local Assumptions

- SDKMAN is installed by Homebrew at `/opt/homebrew/opt/sdkman-cli/libexec`.
  This is used when `SDKMAN_DIR` is unset or points somewhere without
  `bin/sdkman-init.sh`.
- macOS `/usr/libexec/java_home` is available. When JDK 17 is installed, the
  bootstrap sets `JAVA_HOME` to that JDK before invoking `kscript`.
- This Java pin is needed because the installed Kotlin compiler used by
  `kscript` is Kotlin 1.8.22, which fails before compilation under the default
  OpenJDK 26.0.1 runtime.

The AT scripts also depend on `AT/sldemo_autotrans_data.mat`, copied from the
MATLAB R2026a automatic transmission example. The Simulink model
`AT/Autotrans_shift.mdl` loads `sldemo_autotrans_data`, which defines variables
such as `converter_data` and `vehicledata`; keeping the data file in `AT/` avoids
depending on a user-specific MATLAB examples directory under
`~/Documents/MATLAB/Examples`.

The verified local MATLAB installation was `/Applications/MATLAB_R2026a.app`.
