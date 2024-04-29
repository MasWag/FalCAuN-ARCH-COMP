#!/usr/bin/env kscript
/*****h* CC/CCx
 *  NAME
 *   CCx.main.kts
 *  DESCRIPTION
 *   Script to falsify the chasing cars benchmark against the CCx formula by FalCAuN
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
 *   ./CCx.main.kts
 *
 ********/

// Import the constants for Chasing Cars
@file:Import("./Cars.kt")

import kotlin.streams.toList
import java.io.BufferedReader
import java.io.StringReader

import net.maswag.*

// Define the output mapper
val ignoredValues = listOf(null)
val yDiffValues = listOf(7.5, null)
val outputMapperReader = OutputMapperReader(listOf(ignoredValues, ignoredValues, ignoredValues, ignoredValues, ignoredValues, yDiffValues, yDiffValues, yDiffValues, yDiffValues))
outputMapperReader.parse()
val mapperString = listOf("previous_min($y2 - $y1)", "previous_min($y3 - $y2)", "previous_min($y4 - $y3)", "previous_min($y5 - $y4)").joinToString("\n")
val signalMapper: ExtendedSignalMapper = ExtendedSignalMapper.parse(BufferedReader(StringReader(mapperString)))
assert(signalMapper.size() == 1)
val mapper =
    NumericSULMapper(inputMapper, outputMapperReader.largest, outputMapperReader.outputMapper, signalMapper)

// Define the pseudo signal names
// Pseudo signals representing the maximum and minimum values between sampling points
// These signals exclude the begin time and include the end time
val diffy2y1 = "signal(5)"
val diffy3y2 = "signal(6)"
val diffy4y3 = "signal(7)"
val diffy5y4 = "signal(8)"

// Define the STL properties
val stlFactory = STLFactory()
val stlList = listOf(
    "(alw_[0,${(50 / signalStep).toInt()}] $diffy2y1 > 7.5) && (alw_[0,${(50 / signalStep).toInt()}] $diffy3y2 > 7.5) && (alw_[0,${(50 / signalStep).toInt()}] $diffy4y3 > 7.5) && (alw_[0,${(50 / signalStep).toInt()}] $diffy5y4 > 7.5)"
).stream().map { stlString ->
    stlFactory.parse(
        stlString,
        inputMapper,
        outputMapperReader.outputMapper,
        outputMapperReader.largest
    )
}.toList()
// We need to add by one because the first sample is at time 0
val signalLength = (50 / signalStep).toInt() + 1
val properties = AdaptiveSTLList(stlList, signalLength)

// Load the automatic transmission model. This automatically closes MATLAB
SimulinkSUL(initScript, paramNames, signalStep, simulinkSimulationStep).use { autoTransSUL ->
    // Configure and run the verifier
    val verifier = NumericSULVerifier(autoTransSUL, signalStep, properties, mapper)
    // Timeout must be set before adding equivalence testing
    verifier.setTimeout(20 * 60) // 20 minutes
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
