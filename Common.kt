/*****h* FalCAuN-ARCH-COMP/Common
 *  NAME
 *   Common.kt
 *  DESCRIPTION
 *   The common configuration for running FalCAuN via kscript.
 *  AUTHOR
 *   Masaki Waga
 *  HISTORY
 *    - 2024/04/26: Initial version
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

// Constants for the GA-based equivalence testing
val maxTest = 50000
val populationSize = 50
val crossoverProb = 0.9
val mutationProb = 0.01

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
var MealyFixedSetLogger = LoggerFactory.getLogger(MealyFixedSetEQOracle::class.java) as Logger
MealyFixedSetLogger.level = Level.DEBUG
