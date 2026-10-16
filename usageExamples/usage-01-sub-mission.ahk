#Requires AutoHotkey v2.0
#Include ../QUEST.ahk

simulateError()

simulateError() {
    errResponse := Map(
        "error", true,
        "message", "Your actions don't matter. You FAIL!."
    )
    QUEST.Report(errResponse)
}