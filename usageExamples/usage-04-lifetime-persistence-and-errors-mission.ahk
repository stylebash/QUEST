#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk

supply := QUEST.items.supply

switch supply{
  case "dontReportOnTime":
    ; Adventurer-san slept on the job... Again. 🙄
    ; Report from this Adventurer-san's mission should come [3rd]
    Sleep 1000      ; 🙄
    QUEST.Report()  ; ... 🙄
  case "dontReportAtAll":
    ; let's say Adventurer-san got KIA in the field.
    ; Report from this Adventurer-san's mission should come [4th]
    return
  case "reportImmediately":
    ; Our vanilla Boy scout Adventurer.
    ; Report from this Adventurer-san's mission should come [1st]
    QUEST.Report('done')
  case "simulateError":
    ; Adventurer-san? ... Adventurer-san!?... Adventurer-saaaaaaaaaaaaaaaaaaan!!!
    ; Report from this Adventurer-san's mission should come [2nd]
    simulateError()
  default:
    QUEST.Report('default reached by ' . QUEST.adventurerName)
}

simulateError() {
    errResponse := Map(
        "error", true,
        "message", "An error occured in the subprocess. And this is the error message sent back by Adventurer-san."
    )
    QUEST.Report(errResponse)
}

/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. Adventurer-san can 'report' an error message back to our dispatcher.
 * 2. If Adventurer-san doesn't report back after a set amount of time has passed,
 *    even if they report back eventually, that mission will be marked as failed (an error).
 * 3. In the same vein as the previous point, if Adventurer-san doesn't report at all,
 *    that mission will be marked as failed, too.
 */