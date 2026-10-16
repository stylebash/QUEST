#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../lib/JSON.ahk ; cJSON by G33kDude
#Include ../QUEST.ahk

; Primitives
; You only want to pass a simple, singular data type
missionString := 'basicString'
missionInt := 11234
missionFloat := 3.14

; Is actually an int in AHKv2, so we're really passing a '1' or a '0' here.
; And that's what you'll see when receiving this as an item on either your dispatcher or mission files.
missionBool := true

missionObjLiteral := { greetings: 'wasssssuuuuuuup' }
missionMap := Map(
    'greetings', "Hiya!",
    'package', 5234534
)

QUEST.missionFile := "usage-02-bareBasicSetup-mission.ahk"

/**
 * Previously, we learned that this dispatcher file is terminated immediately after a full mission loop.
 * Now, we're showing that this dispatcher file will not die until all missions are complete.
*/
QUEST.Dispatch(missionString, PrimitiveResults)
QUEST.Dispatch(missionInt, PrimitiveResults)
QUEST.Dispatch(missionFloat, PrimitiveResults)
QUEST.Dispatch(missionBool, PrimitiveResults)

; We can set to change which mission to dispatch to before every dispatch
QUEST.missionFile := "usage-03-multi-dispatches-mission.ahk"

QUEST.Dispatch(missionObjLiteral, StructuredResults)
QUEST.Dispatch(missionMap, StructuredResults)
/**
 * Where's the demo for passing an ARRAY?
 * We can still pass simple, flat arrays. 
 * In addition to that, array structures using QUEST conventions 
 * unlocks capabilities we have available on the class.
 * A whole demo just for arrays is on: "usage-05-QUEST-array-convention-dispatcher.ahk"
 * We'll be utilizing the 3rd parameter for QUEST.Dispatch() then as well.
 */


PrimitiveResults(results) {
  OutputDebug results
}

/**
 * This is an introduction on our format conventions with QUEST for structured data.
*/
StructuredResults(results) {
  ; If the adventurer sends back a map, array, or object literal from its mission,
  ; we're going to receive a map.
  OutputDebug results, ':Full Object'

  ; Extract and do what you want with it as you would
  for key, item in results{
    OutputDebug 'key: ' . key . '`n           item: ' . item
  }
}
/**
 * QUEST sends and receives data between files via string. 
 * And this string is formatted via cJSON, the JSON helper class.
 * So your items are fully prepped for it's intended use on either your dispatcher or mission files. 
 */


/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. We can call QUEST.Dispatch() multiple times and 
 *    will only terminate the dispatcher script after the last call runs its last mission loop.
 * 2. We can change which mission to dispatch to before every dispatch.
 * 3. Receiving singular data type primitives is different from structured data types.
 *    - When receiving structured data types, we're going to receive a map.
 *    - And we're going to have to unpack it accordingly. 
 */