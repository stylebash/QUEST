#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk ; cJSON by G33kDude

try {
    ; QUEST.traceAndLog := true
    Init()
} catch Error as err {
    QUEST.TraceLogger("Layer 2 Top-Level Fatal Error: " . err.Message . " (Line " . err.Line . " in " . err.What . ")")
    QUEST.Report(Map("error", true, "message", "Layer 2 Crash: " . err.Message))
}

Init() {
    if (QUEST.adventurerName == "skelerena") {
        HandleSkelly()
        return
    } else {

        callout := QUEST.items.callout
        log := QUEST.items.log

        transform := RangerCallout(callout)
        QUEST.Report(transform)
    }
    
    return
}

HandleSkelly() {
    QUEST.TraceLogger("HandleSkelly() entered by " . QUEST.adventurerName)
    
    scriptPath := A_ScriptDir . "\usage-01-sub-mission.ahk"
    if (!FileExist(scriptPath)) {
        QUEST.TraceLogger("Layer 2 error: Layer 3 script missing at " . scriptPath)
        QUEST.Report(Map("error", true, "message", "Missing " . scriptPath))
        return
    }

    QUEST.missionFile := scriptPath

    subTask := { action: QUEST.items.action }

    QUEST.TraceLogger("Layer 2 dispatching Layer 3...")
    QUEST.Dispatch(subTask, Errmulation)
}

Errmulation(resultMap) {
    QUEST.TraceLogger("Errmulation received result from Layer 3")
    QUEST.Report(resultMap)
}


RangerCallout(callout) {
    switch (callout) {
        case "Dinozord Power!":
            Dinozord()
        case "We need Dinozord power, now!":
            transform := {
                log: "Five Zords combined into a Tank!",
                form: "Dino Tank Mode"
            }
        case "Megazord battle mode, now!":
            transform := {
                log: "Tank to Humanoid Robot!",
                form: "Dino Megazord Battle Mode"
            }
        case "Dragonzord Battle Mode, now!":
            transform := {
                log: "Dragonzord combines with Mastodon, Triceratops, and Sabertooth Tiger",
                form: "Dragonzord Battle Mode"
            }
        case "Mega Dragonzord, power up!":
            transform := {
                log: "Dino Megazord combines with the Dragonzord",
                form: "Mega Dragonzord"
            }
        case "We need Ultrazord power, now!":
            transform := {
                log: "Mega Dragonzord combines with Titanus",
                form: "Ultrazord"
            }
    }

    return transform
}

Dinozord() {
    zord := ""
    switch (QUEST.adventurerName) {
        case "jason":
            zord := QUEST.items.red . " " . QUEST.items.callout
        case "zach":
            zord := QUEST.items.black . " " . QUEST.items.callout
        case "billy":
            zord := QUEST.items.blue . " " . QUEST.items.callout
        case "trinity":
            zord := QUEST.items.yellow . " " . QUEST.items.callout
        case "kimberly":
            zord := QUEST.items.pink . " " . QUEST.items.callout
        case "tommy":
            zord := QUEST.items.green . "!"
    }

    QUEST.Report(zord)
}
