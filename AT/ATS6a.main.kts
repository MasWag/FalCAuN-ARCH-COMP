#!/usr/bin/env kscript
/*****h* kotlin/ATS6a
 *  NAME
 *   ATS6a.main.kts
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
 *   ./ATS6a.main.kts
 *
 ********/

// Import the constants for AutoTrans
@file:Import("./AutoTrans.kt")

import kotlin.streams.toList
import java.io.BufferedReader
import java.io.StringReader

import net.maswag.*

// Define the output mapper
val velocityValues = listOf(35.0, null)
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
//val stlGRotationLt3000 = "$rotation < 3000.0 && []_[0, ${(30 / signalStep).toInt()}] ($prevMaxRotation < 3000.0)"
val stlGRotationLt3000 = "[]_[0, ${(30 / signalStep).toInt()}] ($prevMaxRotation < 3000.0)"
val stlNotGRotationLt3000 = "<>_[0, ${(30 / signalStep).toInt()}] ($prevMaxRotation > 3000.0)"
//val STLGVelocityLt35 = "$velocity < 35.0 && []_[0,${(4 / signalStep).toInt()}] ($prevMaxVelocity < 35.0)"
val STLGVelocityLt35 = "[]_[0,${(4 / signalStep).toInt()}] ($prevMaxVelocity < 35.0)"
val stlList = listOf(
    //"($stlGRotationLt3000) -> ($STLGVelocityLt35)",
    // We use || instead of -> because specification strengthening does not support -> yet
    // "(!($stlGRotationLt3000)) || ($STLGVelocityLt35)",
    // Similarly, we use <>! instead of ![]
    "($stlNotGRotationLt3000) || ($STLGVelocityLt35)",
).stream().map { stlString ->
    stlFactory.parse(
        stlString,
        inputMapper,
        outputMapperReader.outputMapper,
        outputMapperReader.largest
    )
}.toList()
val signalLength = (30 / signalStep).toInt()
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
