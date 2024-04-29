#!/usr/bin/env kscript
/*****h* SC/SCa
 *  NAME
 *   SCa.main.kts
 *  DESCRIPTION
 *   Script to falsify the stream condenser benchmark by FalCAuN
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
 *  USAGE
 *   ./SCa.main.kts
 *
 ********/

// Import the common configuration
@file:Import("../Common.kt")

import kotlin.streams.toList
import java.io.BufferedReader
import java.io.StringReader

import net.maswag.*

import net.maswag.InputMapperReader

// Define the configuration of the automatic transmission model
val initScript = """
%% Init Script for the StreamCondenser model

%% Load the StreamCondenser model
mdl = 'steamcondense_RNN_22';
load_system(mdl);


%% References
% * Yaghoubi, Shakiba, and Georgios Fainekos. "Gray-box Adversarial Testing for Control Systems with Machine Learning Components.", HSCC (2019)
"""
val paramNames = listOf("input")
var signalStep = 1.0
val simulinkSimulationStep = 0.0025

// Define the input mapper
val inputValues = listOf(3.99, 4.00, 4.01)
val inputMapper = InputMapperReader.make(listOf(inputValues))

// Define the output signal names
val pressure = "signal(3)"

// Define the output mapper
val ignoredValues = listOf(null)
val pressureValues = listOf(87.0, 87.5, null)
val outputMapperReader = OutputMapperReader(listOf(ignoredValues, ignoredValues, ignoredValues, ignoredValues, pressureValues, pressureValues))
outputMapperReader.parse()
val mapperString = listOf("previous_max_output(3)", "previous_min_output(3)").joinToString("\n")
val signalMapper: ExtendedSignalMapper = ExtendedSignalMapper.parse(BufferedReader(StringReader(mapperString)))
assert(signalMapper.size() == 2)
val mapper =
    NumericSULMapper(inputMapper, outputMapperReader.largest, outputMapperReader.outputMapper, signalMapper)

// Define the pseudo signal names
// Pseudo signals representing the maximum and minimum values between sampling points
// These signals exclude the begin time and include the end time
val prevMaxPressure = "output(4)"
val prevMinPressure = "output(5)"

// Define the STL properties
val stlFactory = STLFactory()
val stlList = listOf(
    "(alw_[${(30 / signalStep).toInt()},${(35 / signalStep).toInt()}] ($prevMaxPressure < 87.5 && $prevMaxPressure > 87))"
).stream().map { stlString ->
    stlFactory.parse(
        stlString,
        inputMapper,
        outputMapperReader.outputMapper,
        outputMapperReader.largest
    )
}.toList()
// We need to add by one because the first sample is at time 0
val signalLength = (35 / signalStep).toInt() + 1
val properties = AdaptiveSTLList(stlList, signalLength)

// Load the automatic transmission model. This automatically closes MATLAB
SimulinkSUL(initScript, paramNames, signalStep, simulinkSimulationStep).use { autoTransSUL ->
    // Configure and run the verifier
    val verifier = NumericSULVerifier(autoTransSUL, signalStep, properties, mapper)
    // Timeout must be set before adding equivalence testing
    verifier.setTimeout(10 * 60) // 10 minutes
    // We first try the corner cases
    verifier.addCornerCaseEQOracle(signalLength, signalLength / 2);
    // Then, search with GA
    verifier.addGAEQOracleAll(
        signalLength,
        maxTest,
        ArgParser.GASelectionKind.Tournament,
        populationSize,
        crossoverProb,
        mutationProb
    )
    val result = verifier.run()

    // Print the result
    if (result) {
        println("The property is likely satisfied")
    } else {
        for (i in 0 until verifier.cexProperty.size) {
            println("${verifier.cexProperty[i]} is falsified by the following counterexample")
            println("cex concrete input: ${verifier.cexConcreteInput[i]}")
            println("cex abstract input: ${verifier.cexAbstractInput[i]}")
            println("cex output: ${verifier.cexOutput[i]}")
        }
    }
    println("Execution time for simulation: ${verifier.simulationTimeSecond} [sec]")
    println("Number of simulations: ${verifier.simulinkCount}")
    println("Number of simulations for equivalence testing: ${verifier.simulinkCountForEqTest}")
}
