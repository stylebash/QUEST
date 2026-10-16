#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk

; Let's carry back all the items we brought into the field mission.
; To check how QUEST has merged and restructured our supplied data.
carryBackItemSupply := QUEST.items.supply == "" ? QUEST.items : QUEST.items.supply

QUEST.Report(carryBackItemSupply)


/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. We use QUEST.items.supply if we know we're accepting a singular primitive data type.
 * 2. If the data we're accepting is an object literal of a Map(), QUEST.items.supply is an empty string ""
 * /