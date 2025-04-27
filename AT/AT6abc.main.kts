#!/usr/bin/env kscript
/*****h* kotlin/AT6abc
 *  NAME
 *   AT6abc.main.kts
 *  DESCRIPTION
 *   Script to falsify the automatic transmission benchmark against the S6a formula by FalCAuN
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
 *  USAGE
 *   ./AT6abc.main.kts
 *
 ********/

@file:Import("./AutoTrans.kt") // Import the constants for AutoTrans

import net.maswag.falcaun.*
import java.io.BufferedReader
import java.io.StringReader
import kotlin.streams.toList

logger.info("This is the script to falsify the automatic transmission benchmark against the S6a formula by FalCAuN")

// The number of repetitions of the experiment
var experimentSize = 1
if (args.size > 0) {
    experimentSize = args[0].toInt()
    logger.info("The experiment is executed for $experimentSize times")
} else {
    logger.info("The number of repetitions of the experiment is not specified. We use the default repetition size $experimentSize")
}

// Define the output mapper
val velocityValues = listOf(35.0, 50.0, 65.0, null)
val rotationValues = listOf(3000.0, null)
val ignoreValues = listOf(null)
val gearValues = listOf(null)
val outputMapperReader = OutputMapperReader(listOf(ignoreValues, ignoreValues, gearValues, velocityValues, rotationValues))
outputMapperReader.parse()
val mapperString = listOf("previous_max_output(0)", "previous_max_output(1)").joinToString("\n")
val signalMapper: ExtendedSignalMapper = ExtendedSignalMapper.parse(BufferedReader(StringReader(mapperString)))
assert(signalMapper.size() == 2)
val mapper =
    NumericSULMapper(inputMapper, outputMapperReader.largest, outputMapperReader.outputMapper, signalMapper)

// Define the pseudo signal names
// Pseudo signals representing the maximum and minimum values between sampling points
// These signals exclude the begin time and include the end time
val prevMaxVelocity = "output(3)"
val prevMaxRotation = "output(4)"

// Define the STL properties
val stlFactory = STLFactory()
// val stlGRotationLt3000 = "$rotation < 3000.0 && []_[0, ${(30 / signalStep).toInt()}] ($prevMaxRotation < 3000.0)"
val stlGRotationLt3000 = "[]_[0, ${(30 / signalStep).toInt()}] ($prevMaxRotation < 3000.0)"
val stlNotGRotationLt3000 = "<>_[0, ${(30 / signalStep).toInt()}] ($prevMaxRotation > 3000.0)"
// val stlGVelocityLt35 = "$velocity < 35.0 && []_[0,${(4 / signalStep).toInt()}] ($prevMaxVelocity < 35.0)"
val stlGVelocityLt35 = "[]_[0,${(4 / signalStep).toInt()}] ($prevMaxVelocity < 35.0)"
val stlGVelocityLt50 = "[]_[0,${(8 / signalStep).toInt()}] ($prevMaxVelocity < 50.0)"
val stlGVelocityLt65 = "[]_[0,${(20 / signalStep).toInt()}] ($prevMaxVelocity < 65.0)"
val stlList =
    listOf(
        // We use || instead of -> because specification strengthening does not support -> yet
        // Similarly, we use <>! instead of ![]
        "($stlNotGRotationLt3000) || (($stlGVelocityLt35) && ($stlGVelocityLt50) && ($stlGVelocityLt65))",
    ).stream().map { stlString ->
        stlFactory.parse(
            stlString,
            inputMapper,
            outputMapperReader.outputMapper,
            outputMapperReader.largest,
        )
    }.toList()
// We need to add by one because the first sample is at time 0
val signalLength = (30 / signalStep).toInt() + 1

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
        var result = runExperiment(verifier, simulinkSimulationStep, "AT", "AT6abc")
        results.add(result)
    }
    FileOutputStream("result-AT6abc.csv").apply { writeCsv(results) }
    logger.info("The results are written to result-AT6abc.csv")
}
