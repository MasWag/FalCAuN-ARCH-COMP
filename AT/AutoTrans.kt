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

// The scripts depends on FalCAuN-core and FalCAuN-matlab
@file:DependsOn("net.maswag:FalCAuN-core:1.0-SNAPSHOT", "net.maswag:FalCAuN-matlab:1.0-SNAPSHOT")
// We assume that the MATLAB_HOME environment variable is set
@file:KotlinOptions("-Djava.library.path=$MATLAB_HOME/bin/maca64/:$MATLAB_HOME/bin/maci64:$MATLAB_HOME/bin/glnxa64")

import ch.qos.logback.classic.Level
import ch.qos.logback.classic.Logger
import org.slf4j.LoggerFactory
import net.automatalib.modelchecker.ltsmin.AbstractLTSmin
import net.automatalib.modelchecker.ltsmin.LTSminVersion

import net.maswag.InputMapperReader

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
var signalStep = 1.0
val simulinkSimulationStep = 0.0025

// Define the input mapper
val throttleValues = listOf(0.0, 50.0, 100.0)
val brakeValues = listOf(0.0, 325.0 * 0.5, 325.0)
val inputMapper = InputMapperReader.make(listOf(throttleValues, brakeValues))

// Constants for the GA-based equivalence testing
val maxTest = 50000
val populationSize = 50
val crossoverProb = 0.9
val mutationProb = 0.01

// Define the output signal names
val velocity = "signal(0)"
val rotation = "signal(1)"
val gear = "signal(2)"

// The following suppresses the debug log
var updaterLogger = LoggerFactory.getLogger(AbstractAdaptiveSTLUpdater::class.java) as Logger
updaterLogger.level = Level.INFO
var updateListLogger = LoggerFactory.getLogger(AdaptiveSTLList::class.java) as Logger
updateListLogger.level = Level.INFO
var LTSminVersionLogger = LoggerFactory.getLogger(LTSminVersion::class.java) as Logger
LTSminVersionLogger.level = Level.INFO
var AbstractLTSminLogger = LoggerFactory.getLogger(AbstractLTSmin::class.java) as Logger
AbstractLTSminLogger.level = Level.INFO
var EQSearchProblemLogger = LoggerFactory.getLogger(EQSearchProblem::class.java) as Logger
EQSearchProblemLogger.level = Level.INFO
var SimulinkSteadyStateGeneticAlgorithmLogger = LoggerFactory.getLogger(EQSteadyStateGeneticAlgorithm::class.java) as Logger
SimulinkSteadyStateGeneticAlgorithmLogger.level = Level.INFO
