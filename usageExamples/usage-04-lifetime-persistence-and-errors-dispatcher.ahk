#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../lib/JSON.ahk ; cJSON by G33kDude
#Include ../QUEST.ahk

items := [
  "dontReportOnTime",
  "dontReportAtAll",
  "reportImmediately",
  "simulateError",
  "random value 1",
  "random value 2"
]

QUEST.missionFile         := "usage-04-lifetime-persistence-and-errors-mission.ahk"
QUEST.missionDeadline     := 500  ; mission expires for our Adventurers after 500ms
QUEST.keepDispatcherAlive := true ; This Dispatcher won't be terminated even after all mission loops complete.
; You can terminate the script manually from your editor or your system tray.
; Or use ExitApp() at the end of a condition on your program.

; Let's extract the contents and call QUEST.Dispatch one by one.
for item in items 
  QUEST.Dispatch(item, ReportResults)


/**
 * Below, we're expected to see 6 reports, because we sent out 6 adventurers.
 * 3 of which are error reports we induced.
 */
ReportResults(report) {
  if report == 'done'
    OutputDebug 'report received immediately'
  else
    OutputDebug report
}
; Notice how we have adventurer identities on some of the reports.
; Since we haven't attached an adventurer name on the mission, QUEST will 
; give each an anonymous numbered name internally.
; We'll learn how to attach an adventurer name on the next 
;   usage demo file: "usage-05-QUEST-array-convention-dispatcher.ahk".

/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. We can set an expiry time for missions.
 * 2. We're capable of telling our dispatcher to work for unpaid overtimes.
 * 3. We can get error reports from our Adventurer's missions.
 *   i. We also learned about adventurer names.
 */