#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../lib/JSON.ahk ; cJSON by G33kDude
#Include ../QUEST.ahk

/**
 * No explanations in this usage example file pair (dispatcher, mission).
 * Just a quick peek on what you can do, 
 * how easy it is to pass data between files, 
 * and how to use QUEST.
 */

Init()

Init() {
    standByCarrier := Titanus()
    _summonZords := SummonZords()
    serialMissions := getSerialMissionsFunc()
    serialMissionsLambda := getSerialMissionsLambda()
    
    QUEST.missionFile := "usage-01-quickOverview-mission.ahk"
    QUEST.missionDeadline := 3000
    QUEST.Dispatch(_summonZords, asyncSummon, standByCarrier)
    QUEST.Dispatch(serialMissions, serialReportArea, standByCarrier, 'sync')
    QUEST.Dispatch(serialMissionsLambda, NestedDispatcherReport, standByCarrier, 'serial')
}

NestedDispatcherReport(results) {
    OutputDebug results
}

serialReportArea(results) {
    resultOnStep := QUEST.UnpackSerialResults(results)

    for index, result in resultOnStep {
        OutputDebug result['log'], ':' . result['form']
    }
}

asyncSummon(resultsMap) {
    for ranger, dinozord in resultsMap {
        OutputDebug StrTitle(ranger) . ": " . dinozord
    }
}

SummonZords() {
    return [
        { adventurerName: "kimberly", supplies: { callout: "Dinozord Power!" } },
        { adventurerName: "zach", supplies: { callout: "Dinozord Power!" } },
        { adventurerName: "billy", supplies: { callout: "Dinozord Power!" } },
        { adventurerName: "jason", supplies: { callout: "Dinozord Power!" } },
        { adventurerName: "tommy", supplies: { callout: "Dinozord Power!" } },
        { adventurerName: "trinity", supplies: { callout: "Dinozord Power!" } }
    ]
}

getSerialMissionsFunc() {
    t1 := { callout: "We need Dinozord power, now!" }
    t2 := (prev) => ({ 
        log: prev.log,
        callout: "Megazord battle mode, now!" })
    t3 := (prev) => ({ 
        log: prev,
        callout: "Dragonzord Battle Mode, now!" })
    t4 := (prev) => ({
            supplies: {
                log: prev.log,
                callout: "Mega Dragonzord, power up!" 
            }
        })
    t5 := (prev) => ({ 
        log: prev.log,
        callout: "We need Ultrazord power, now!" })
    return [t1, t2, t3, t4, t5]
}

getSerialMissionsLambda() => [
    { 
        adventurerName: "skelerena", 
        missionDeadline: 1000, 
        supplies: { 
            action: "kill zordon",
        } 
    },
    (prev) => { adventurerName: "rita", supplies: { action: "Skelerena failed. You can't see this step." } },
    (prev) => { adventurerName: "zed", supplies: { action: "Failed mission, the plans are ruined!" } }
]

Titanus() {
    return {
        red:    "Tyrannosaurus",
        black:  "Mastodon",
        blue:   "Triceratops",
        yellow: "Sabertooth Tiger",
        pink:   "Pterodactyl",
        green:  "Dragonzord"
    }
}