#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk

; QUEST.Get("action") is the same exact equivalent to QUEST.items.action
; This is an alternative to using the dot notation convention we've been seeing in the tutorials so far.
action := QUEST.Get("action")

; the 2nd argument "0", is the default value. 
; In QUEST terms, "0" here is basically our backupSupply, but declared in the mission file.
a := Float(QUEST.Get("a", 0)) ; Let's typecast it into a float.

b := Float(QUEST.Get("b", 0))
result := 0

switch action {
    case "add":      result := a + b
    case "subtract": result := a - b
    case "multiply": result := a * b
    case "divide":   result := (b != 0) ? (a / b) : 0 ; This is why we've typecasted the values into a float.
}

returnType := QUEST.items.returnType

if (returnType == "objectLiteral") {
    report := {
        someIndexName: result,
        forNothing: {},
        butReallyNothing: '{}',
        uselessData: 5423,
        butGoodForDemo: 5423,
    }
} else if (returnType == "map") {
    report := Map(
        "something", result,
        "forNothing", {},
        "butReallyNothing", '{}',
        "uselessData", 5423,
        "butGoodForDemo", 54223,
    )
} else if (returnType == "singularPrimitive") 
    report := result
 else if (returnType == "array") 
    report := [result]
 else 
    report := result



QUEST.Report(report)

/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. QUEST.Get("<index name>") is another way to retrieve a supplied item.
 *   Example: QUEST.Get("action")
 * 2. Use QUEST.Get("<index name>", <default value>) so there is a usable item as a backup
 *   Example: QUEST.Get("a", 0)
 * /