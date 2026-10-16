#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk ; cJSON by G33kDude


; We know we're getting our adventure to this mission carries indexes "greetings" and "package"
greetings := QUEST.items.greetings
package := QUEST.items.package == "" ? "None" : QUEST.items.package ; If we're calling an index of items that doesn't exist, it's default will be ""

; We can send structured data types from the dispatcher, so that means
; we can send the same from the mission file as well.
payLoad := { received: 'Greetings: ' . greetings . ', Package: ' . package }

QUEST.Report(payLoad)


/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. If we know the index name(s) of the item's object we're receiving, 
 *    we can call it directly in dot notation from QUEST.items
 * 2. If the index we're calling doesn't exist, the default value returned is an empty string "".
 * 3. We can send structured data types back as well.
 */