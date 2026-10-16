#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk

QUEST.missionFile := "usage-07-nested-dispatcher-mission-02.ahk"

QUEST.Dispatch("Dispatch to another dispatcher", DispatchReportLayer3)

DispatchReportLayer3(results) {
  QUEST.Report(results)
}