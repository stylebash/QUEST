#Requires AutoHotkey v2.0
#Include ../lib/outputDebugOverload.ahk
#Include ../QUEST.ahk                                                                       ; SETUP Requirement #1
; Note** You don't need to setup #SingleInstance for your mission scripts.
; QUEST handles that for you.

payLoad := 'Supply received: ' . QUEST.items.supply . '; Type: ' . Type(QUEST.items.supply) ; SETUP Requirement #2
QUEST.Report(payLoad)                                                                       ; SETUP Requirement-ish #3

/**
 * -- REVIEW --
 * In this demo, we learned that to setup using QUEST as a mission file,
 * we need only need 1 step:
 * 1. Include the QUEST.ahk file
 *   1.a. You don't need to setup your mission file's instance state.
 *     i.e. you don't need #SingleInstance declarations. QUEST does this already. 
 * 
 * And to use QUEST packages and communicating back to the dispatcher:
 * A. We open our bag of QUEST.items.supply to use on the mission. 
 * B. We can send data back to our dispatcher when we include a "payload" on our QUEST.Report().
 *   - If we don't want to send any data back (We have no loot, Kazuma!!! 😩 ), 
 *      we can just call QUEST.Report() to report we're done with the mission.
 *   - If Adventurer-san doesn't turn in their QUEST.Report(), 
 *      the dispatcher is going to assume that Adventurer-san got KIA in the mission. 
 *      Poor Adventurer-san.
 */