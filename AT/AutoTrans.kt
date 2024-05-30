/*****h* AT/AutoTrans
 *  NAME
 *   AutoTrans.kt
 *  DESCRIPTION
 *   Common configuration for the automatic transmission model [Hoxha et al., ARCH@CPSWeek 2014].
 *  AUTHOR
 *   Masaki Waga
 *  HISTORY
 *    - 2024/04/25: Initial version
 *  COPYRIGHT
 *   Copyright (c) 2024 Masaki Waga
 *   Released under the MIT license
 *   https://opensource.org/licenses/mit-license.php
 *
 *  PORTABILITY
 *   This script assumes the following:
 *   - FalCAuN is installed, for example, by mvn install.
 *   - The environment variable MATLAB_HOME is set to the root directory of MATLAB, e.g., /Applications/MATLAB_R2024a.app/ or /usr/local/MATLAB/R2024a.
 *
 ********/

@file:Import("../Common.kt") // Import the common configuration

import net.maswag.falcaun.*

// Define the configuration of the automatic transmission model
val initScript = """
%% Init Script for the Automatic transmission  model
% We use the automatic transmission model in [Hoxha et al.,
% ARCH@CPSWeek 2014].

%% Add the example directory to the path
versionString = version('-release');
oldpath = path;
path(strcat(userpath, '/Examples/R', versionString, '/simulink_automotive/ModelingAnAutomaticTransmissionControllerExample/'), oldpath);

%% Load the AT model
mdl = 'Autotrans_shift';
load_system(mdl);

%% References
% * [Hoxha et al., ARCH@CPSWeek 2014]: *Benchmarks for Temporal
% Logic Requirements for Automotive Systems*, ARCH@CPSWeek 2014,
% Bardh Hoxha, Houssam Abbas, Georgios E. Fainekos
"""
val paramNames = listOf("throttle", "brake")
val simulinkSimulationStep = 0.0025

// Define the input mapper
var signalStep = 2.0
val throttleValues = listOf(0.0, 50.0, 100.0)
val brakeValues = listOf(0.0, 325.0)
val inputMapper = InputMapperReader.make(listOf(throttleValues, brakeValues))

// Define the output signal names
val velocity = "signal(0)"
val rotation = "signal(1)"
val gear = "signal(2)"
