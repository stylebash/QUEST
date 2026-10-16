#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk                                       ; SETUP Requirement #1

; You only want to pass a single, simple, primitive data
mission := 'basicString'

; defaults to mission.ahk in the same directory as this dispatcher file.
; but we can set it up like so 
QUEST.missionFile := "usage-02-bareBasicSetup-mission.ahk"  ; SETUP --Optional--, but kind of Required for most custom code

/**
 * This is how we delegate missions to our adventurers.
 * QUEST.Dispatch() has 4 parameters: missionMixedDataType, callBackFunctionName, backupSuppliesObjectLiteral, processingMode ('parallel', 'serial')
 * Only the first parameter is mandatory.
 * Terminates (exits) this dispatcher script immediately after our callback- MissionResults, end
 */
; =============================================
; QUEST.Dispatch(mission) ; is perfectly valid. Set your adventurer(s) on a mission and you don't care about the result.
; =============================================
; But if you do care about the result, we set where our adventurer's report data lands (callback function name). Like so:

QUEST.Dispatch(mission, MissionResults)                     ; SETUP Requirement #2

/**
 * This is where you receive the results of your adventurer(s) quest
 * It's required to accept a single parameter.
 *   otherwise, we have no container for our adventurer's report.
 * @param loot mixed
 * Caveat: Your editor might falsely flag a name conflict on this declaration. 
 * Unless there really are 2 symbol declarations (variables, functions) with the 
 * same name in your file, you can ignore.
 */
MissionResults(results) {                                   ; SETUP Requirement #3
  ; "results" is what our adventurer turned in.
  OutputDebug results ; Check it out from your debug panel.
}
  /**
  * We can access "results" directly if it's a primitive.
  * Since in AHK v2, all data types are technically objects, we're defining this set as a primitive:
  * String, Integer, Float, Boolean
  * Object literals and Maps are non-primitives, but you can still access the indexes directly like usual.
  *   e.g. results.name, results.age, results.address, etc.
  * 
  * Arrays are a little bit more special when passing through and used with QUEST. 
  *   We have packing conventions and 
  *   have added extra deets you might want to use on the inbound package.
  * We'll show that later in one of the other usage examples ("usage-05-QUEST-array-convention-dispatcher.ahk").
  */

/**
 * -- REVIEW --
 * In this demo, we learned that to setup using QUEST as a dispatcher,
 * we need 3-4 steps:
 * 1. Include the QUEST.ahk file
 * 2. Call QUEST.Dispatch(mission, callBackFunctionName)
 * 3. Create a function that receives the results
 * 4. --OPTIONAL-- set which adventurer we're assigning the QUEST to, like so:
 *     QUEST.adventurerFile := "usage-02-bareBasicSetup-adventurer.ahk"
 * - We also learned that primitives can be directly accessed with no unpacking needed.
 * - Finally, we learned that QUEST terminates the dispatcher script immediately 
 *  after a full loop of a mission run.
 */