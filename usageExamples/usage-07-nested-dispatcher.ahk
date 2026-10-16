#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../lib/JSON.ahk ; cJSON by G33kDude
#Include ../QUEST.ahk

/**
 * Open the other example files for this specific demo and you'll see 
 * code similar to below:
 */

QUEST.missionFile := "usage-07-nested-dispatcher-mission-00.ahk"
QUEST.Dispatch('go nest and multiply', DispatchNestResult)

DispatchNestResult(results) {
  OutputDebug results
}


/**
 * -- REVIEW --
 * In this demo, we learned that to setup nested dispatchers with QUEST:
 * 1. We don't need to do anything special.
 * 2. We just setup and call QUEST.Dispatch as how we already do in the previous usage example files.
 *   And it's accompanying callback functions.
 */