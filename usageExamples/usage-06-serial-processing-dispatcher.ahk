#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../lib/JSON.ahk ; cJSON by G33kDude
#Include ../QUEST.ahk

/**
 * In "parallel" mode, all missions will execute as soon as possible.
 * In "serial" mode, a mission can only run as soon as the 
 *   previous mission in the array is finished and have delivered its' payload.
 */


dataDependentSerialMissions_Func := getSerialMissionsFunc()
dataDependentSerialMissions_Lambda := getSerialMissionsLambda()

QUEST.missionFile := "usage-06-serial-processing-mission.ahk"
; Up to this point in the usage tutorials, we're always using "parallel" processing as our "mode".
; In this demo, you'll see how we could effectively use "serial" processing "mode".
; And why you might want to use it.

; We're not gonna use any backupSupplies so we'll just leave it blank on these.
QUEST.Dispatch(dataDependentSerialMissions_Func, dataDependentSerialProcessReport_Func, , "serial")
QUEST.Dispatch(dataDependentSerialMissions_Lambda, dataDependentSerialProcessReport_Lambda , , "sequence")
QUEST.Dispatch(dataDependentSerialMissions_Lambda, UnpackWithTargetIndexKeyReport , , "serialized")

; #region: itsPackingTime

/**
 * We're returning an array where only the first item is not a fat arrow function.
 * Fat arrow (lambda) functions are the key to executing data dependent missions.
 */
getSerialMissionsFunc() {
  ; Below, notice how we could use object literals or Map().
  ; Both types have their own methods to extracting its index values.
  ; But with QUEST, we've unified these so you could use the dot notation convention when calling 
  ; for the results of the previous step. Use whichever you prefer.
  return [
    ; Step 1: Start with 10 + 5; No data dependency yet as it is the first step.
    Map("action", "add", "a", 10, "b", 5),
    ; Step 2: Multiply previous answer (15) by 2
    (results) => {
      action: "multiply",
      a: results,
      b: 2
    },
    ; Step 3: Subtract 6 from previous answer (30)
    (results) => Map("action", "subtract", "a", results, "b", 6),
    ; Step 4: Divide previous answer (24) by 3 -> Final Answer
    (results) => {
      action: "divide",
      a: results.Last, ; The same as calling `results`, but this is just more explicit.
      b: 3
    }
  ]
}
  
/**
 * You can use regular functions to pass mission details as we have been doing so far.
 * You can use lambdas too, whichever feels cleanest for you.
 */
getSerialMissionsLambda() => [
  { 
    adventurerName: "earth", 
    supplies: { 
      returnType: "objectLiteral",
      action: "add",
      a: 10,
      b: 5
    } 
  },
  (prev) => { 
    adventurerName: "fire", 
    supplies: { 
      returnType: "objectLiteral",
      action: "multiply",
      ; Call for the results of the previous step labeled as: `prev`
      ; Performed by the adventurer:                          `earth`
      ; Carrying an object with one of the indexes named as:  `someIndexName`
      a: prev.earth.someIndexName,
      b: 2
    } 
  },
  (prev) => Map(
    'adventurerName', 'wind',
    'supplies', 
    Map(
      'action', 'subtract', 
      'returnType', 'singularPrimitive',
      'a', prev.fire.someIndexName, 
      'b', 6
    )
  ),
  (prev) => Map(
    'adventurerName', 'water',
    'supplies',
    Map( 
      'action', 'divide',
      'a', prev,
      'b', 3
    )
  ),
  ; ---------------------------------------------------
  ; Let's keep going and see a different final result
  ; ---------------------------------------------------
  (prev) => Map(
    'adventurerName', 'heart',
    'supplies',
    Map( 
      'action', 'divide',
      'a', prev,
      'b', 2
    )
  ),
  (prev) => Map(
    'adventurerName', 'byYourGangCombined',
    'supplies',
    Map( 
      'action', 'divide',
      'a', prev,
      'b', 4
    )
  ),
  (prev) => Map(
    'adventurerName', 'IamCaptain67',
    'supplies',
    Map(
      'action', 'divide',
      'a', prev,
      'b', 5
    ),
  )
]
; #endRegion itsPackingTime

; #region: showResultsFunctions

dataDependentSerialProcessReport_Func(results) {
  ; Let's unpack the results of each adventurer's report step-by-step
  ; and put it into an Array.
  resultOnStep := QUEST.UnpackSerialResults(results)

  ; We know the contents of the Array are singular primitives
  OutputDebug "Step 1 (10 + 5) = " . resultOnStep[1], 
    "Step 2 (15 * 2) = " . resultOnStep[2], 
    "Step 3 (30 - 6) = " . resultOnStep[3], 
    "Step 4 (24 / 3) = " . resultOnStep[4], 
    "Final Result: " . resultOnStep[-1] ; [-1] ensures we're retrieving the last index
}

dataDependentSerialProcessReport_Lambda(results) {
    ; Unpack like how we unpacked in the function above
    resultOnStep := QUEST.UnpackSerialResults(results)

    ; But since we know we're receiving a Map for some of the items in the array,
    ; we retrieve the value inside a map with an index key
    OutputDebug "Step 1 (10 + 5) = " . resultOnStep[1]['someIndexName'], 
      "Step 2 (15 * 2) = " . resultOnStep[2]['someIndexName'], 
      "Step 3 (30 - 6) = " . resultOnStep[3], 
      "Step 4 (24 / 3) = " . resultOnStep[4], 
      "Final Result: " . resultOnStep[-1] ; the value adventurer: 'IamCaptain67' is holding.
}

UnpackWithTargetIndexKeyReport(results) {
    ; Another way to unpack. 
    ; We know the index key we're looking for on a couple of the mission results, 
    ; so that's the argument we're passing.
    resultOnStep := QUEST.UnpackSerialResults(results, "someIndexName")

    ; Since we've specified the index key when we've unpacked it, we don't have to 
    ; specify it again when we call it on the corresponding step now.
    OutputDebug "Step 1 (10 + 5) = " . resultOnStep[1], 
      "Step 2 (15 * 2) = " . resultOnStep[2], 
      "Step 3 (30 - 6) = " . resultOnStep[3], 
      "Step 4 (24 / 3) = " . resultOnStep[4], 
      "Final Result: " . resultOnStep[-1]
}

InconsequentialSerialProcessReport(results) {
  OutputDebug results, ":Inconsequential Serial Process Report"
}
; #endRegion showResultsFunctions


; #region: inconsequentialSerialMissions

; You don't have to use "serial" mode only for data dependent type missions.
; With a little caveat, you can choose to process your missions in "serial" mode with the same mental model as doing it in "parallel" mode for whatever reason.
/**
 * Think of each adventurer as a person waiting in line for their turn.
 * And one QUEST.Dispatch() call is forming a separate line of adventurers.
 * Even with all these lines, there is only one QUEST.missionFile all adventurers will look 
 * at to know where to go if they don't carry a 'missionFile' with them.
 * --------------------------------------------------------------------
 * The CAVEAT:
 * - An adventurer may go to the wrong mission if you don't manage and monitor which missionFile they should use.
 * 
 * 
 * You have to think about the estimated total completion time of each line of QUEST.Dispatch() call in 'serial' mode.
 * Mutate QUEST.missionFile with this in mind.
 * --------------------------------------------------------------------
 * 
 * There are 2 approaches for handling this:
 * 1. Include the missionFile for every item in the Array of adventurer mission detail.
 * 2. Wait for all the processes to finish before changing the missionFile via `Sleep` e.g. `Sleep 1000`.
*/

; Approach 1 example -----------------------------------------------------------------------------------------------------------------------------------------------
inconsequentialSerialMissions_Example1 := [
  {
    missionFile: "usage-05-QUEST-array-convention-mission.ahk",
    supplies: {
      supply: 'single data primitive'
    }
  },
  {
    missionFile: "usage-05-QUEST-array-convention-mission.ahk",
    supplies: {
      supply: 7465
    }
  },
  {
    missionFile: "usage-04-lifetime-persistence-and-errors-mission.ahk",
    adventurerName: "Truffles",
    supplies: {
      supply: "reportImmediately"
    }
  }
]

QUEST.Dispatch(inconsequentialSerialMissions_Example1, InconsequentialSerialProcessReport , , "sequential")

; Approach 2 example -----------------------------------------------------------------------------------------------------------------------------------------------
Sleep 1000                                                          ; Wait for all the missions to finish first, before changing (mutating) the missionFile
; Comment the line above or remove it. An error will occur.
; The error: An adventurer that was supposed to go to "usage-06-serial-processing-mission.ahk" went to "usage-05-QUEST-array-convention-mission.ahk" instead.
QUEST.missionFile := "usage-05-QUEST-array-convention-mission.ahk"

; Let's jumble the items here and remove missionFile from some of the items
; Now, it's understood that we're defaulting to use the QUEST.missionFile we declared in our mutation above
; unless exclusively specified otherwise, like how we see it in the second item of the Array below
inconsequentialSerialMissions_Example2 := [
  {
    supplies: {
      supply: 'single data primitive'
    }
  },
  {
    missionFile: "usage-04-lifetime-persistence-and-errors-mission.ahk",
    adventurerName: "Truffles",
    supplies: {
      supply: "reportImmediately"
    }
  },
  {
    supplies: {
      supply: 7465
    }
  }
]

QUEST.Dispatch(inconsequentialSerialMissions_Example2, InconsequentialSerialProcessReport , , "synchronous")
QUEST.Dispatch(inconsequentialSerialMissions_Example2, InconsequentialSerialProcessReport , , "sync")         ; Same exact code and effect as above, we're just demonstrating that 'sync' is valid as a synonym of 'serial' processing too.

; #endRegion inconsequentialSerialMissions

  /**
   * -- REVIEW --
 * In this demo, we learned that:
 * 1. We pass 'serial'/'sequence'/'sequential'/'serialized'/'synchronous'/'sync' as a 4th argument to the `mode` parameter of QUEST.Dispatch()
 * 2. We could use 'serial' mode exactly the same as how we use 'parallel' mode normally.
 * 3. To use sequentially dispatched, data dependent missions, we pass an Array with fat arrow (lambda) function items.
 *   3.a. Each lambda function accepts one parameter, which is used to receive the results of the previous step.
 *     3.a.i. Using the parameter. Let's assume the parameter is named `results`.
 *       3.a.i.1. If receiving a singular primitive, we can use `results` directly.
 *       3.a.i.2. `results.Last` is the same as `results` but more explicit.
 *       3.a.i.3. If receiving a Map or an Object literal, we can use `results.someDeclaredIndexName` to retrieve the value.
 *       3.a.i.4. If receiving a Map or an Object literal from a named adventurer, we use `results.adventurerName.someDeclaredIndexName` to retrieve the value.
 *   3.b. We can use Map() and object literals `{}` interchangeably.
 * 
 * 4. We can unpack the result data on the callback function ourselves, or we could use `QUEST.UnpackSerialResults(parameter)` function to unpack the results of a data dependent mission.
 *   4.a. This function returns an array.
 *     4.a.i. Each item represents each mission in consecutive order of the dispatch call.
 *   4.b. How to unpack data.
 *     4.b.i. Expecting singular primitives only: QUEST.UnpackSerialResults(results)
 *       4.b.i.1. You know a specific step contains a singular primitive, call it like this: <variable name>[<index number>].
 *         example: resultOnStep[1], resultOnStep[2], resultOnStep[3], etc...
 *       4.b.i.2. You know a specific step contains a Map or an object literal, call it like this: <variable name>[<index number>][<Index name>].
 *         example: resultOnStep[2]['someIndexName']
 *     4.b.ii. Expecting Map or an Object literal on SOME (not all) of the results: QUEST.UnpackSerialResults(results, "someIndexName")
 *       4.b.ii.1. We don't have to recall the specific indexes anymore on specific steps. We can just call it like how we do in 4.b.i.1.
 * 
 * 5. We should be mindful of the caveat when mutating `QUEST.missionFile`.
 */