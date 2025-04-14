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

@file:Import("../Common.kt") // Import the common configuration

import net.maswag.falcaun.*
import net.maswag.falcaun.*
import java.io.BufferedReader
import java.io.StringReader
import kotlin.streams.toList

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
// Input range:
// - u_1: 3.99 <= u_1 <= 4.01
val inputValues = listOf(3.99, 4.00, 4.01)
val inputMapper = InputMapperReader.make(listOf(inputValues))

// Define the output signal names
val pressure = "signal(3)"

logger.info("This is the script to falsify the stream condense benchmark against the SCa formula by FalCAuN")

// The number of repetitions of the experiment
var experimentSize = 1
if (args.size > 0) {
    experimentSize = args[0].toInt()
    logger.info("The experiment is executed for $experimentSize times")
} else {
    logger.info("The number of repetitions of the experiment is not specified. We use the default repetition size $experimentSize")
}

// Define the output mapper
val ignoredValues = listOf(null)
val pressureValues = listOf(87.0, 87.5, null)
val outputMapperReader =
    OutputMapperReader(listOf(ignoredValues, ignoredValues, ignoredValues, ignoredValues, pressureValues, pressureValues))
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
// SC: □_[30,35] 87 <= y_4 <= 87.5
val stlFactory = STLFactory()
val stlList =
    listOf(
        "(alw_[${(30 / signalStep).toInt()},${(35 / signalStep).toInt()}] ($prevMaxPressure < 87.5 && $prevMinPressure > 87))",
    ).stream().map { stlString ->
        stlFactory.parse(
            stlString,
            inputMapper,
            outputMapperReader.outputMapper,
            outputMapperReader.largest,
        )
    }.toList()
// We need to add by one because the first sample is at time 0
val signalLength = (35 / signalStep).toInt() + 1

// Load the automatic transmission model. This automatically closes MATLAB
SimulinkSUL(initScript, paramNames, signalStep, simulinkSimulationStep).use { sul ->
    // Create a list to store the results
    val results = mutableListOf<ExperimentSummary>()
    // Repeat the following experiment for the specified number of times
    for (i in 0 until experimentSize) {
        val properties = AdaptiveSTLList(stlList, signalLength)
        // Since SUL counts the number of simulations and the execution time, we need to clear it before each experiment
        sul.clear()
        logger.info("Experiment ${i + 1} / $experimentSize")
        // Configure and run the verifier
        val verifier = NumericSULVerifier(sul, signalStep, properties, mapper)
        // Timeout must be set before adding equivalence testing
        verifier.setTimeout(10 * 60) // 10 minutes
        // We first try the corner cases
        verifier.addCornerCaseEQOracle(signalLength, signalLength / 2)
        // Then, search with GA
        verifier.addGAEQOracleAll(
            signalLength,
            maxTest,
            ArgParser.GASelectionKind.Tournament,
            populationSize,
            crossoverProb,
            mutationProb,
        )
        // Run the experiment
        var result = runExperiment(verifier, "SC", "SCa")
        results.add(result)
    }
    FileOutputStream("result-SCa.csv").apply { writeCsv(results) }
    logger.info("The results are written to result-SCa.csv")
}
