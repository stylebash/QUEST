#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../lib/outputDebugOverload.ahk
#Include ../lib/JSON.ahk ; cJSON by G33kDude
#Include ../QUEST.ahk

; We will pass this as a 2nd argument on calling QUEST.Dispatch()
; In previous usage tutorial files, we have been passing a blank object literal.
; What is it for? 
;   It fills up an adventurer's supplies with their default values if it doesn't exist.
backupSupplies := {
    prevDoc:        "thisDoesNotExist",
    inDoc:          "prettyButDoesNotExist",
    tags:           {},
    searchText:     "",
    sortMode:       "score_desc",
    pageLimit:      100,
    pageNumber:     1,
    fastPagination: false
}

dispatchList := [
  {
    ; We can override 'missionFile' and 'missionDeadline' here.
    ; We'll also add 'adventurerName' and 'supplies', QUEST reserved index names
    ;   we're only able to recognize and process if it's inside an object literal inside an array
    missionFile:    "usageExamples.worker.ahk",
    missionDeadline: 2000,
    adventurerName: "Tako",
    supplies: {
      personalFood:  "apple",
      personalRelic: "Peanut's tears"
    }
  },
  {
    ; missionFile: Since it's ommitted here, we'll be using what's set, or what's in default
    ; missionDeadline: same behavior as how missionFile is handled.
    ; adventurerName: An anonymous Adventurer-san? QUEST will automatically assign them a numbered name in
    ;   this format: adventurer_<#>. Example: adventurer_2
    supplies: {
      searchText: "my dog",
      sortMode:   "score_asc",
    }
  },
  ; Since it's an empty object literal, the mission file will be sent with backupSupplies
  ;   containing the default values and a numbered anonymous adventurer name.
  {},
  ; Same behavior as how the empty object literal above is handled.
  Map(),
  {
    ; In this mission file, the adventurer's only sending a single primitive 
    ; data type back.
    missionFile: "usage-04-lifetime-persistence-and-errors-mission.ahk",
    ; Let's identify this adventurer as "Ice cream".
    adventurerName: "Ice cream",
    supplies: {
      supply: "reportImmediately"
    }
  },
  {
    ; Let's identify this one as a numbered anonymous adventurer.
    missionFile: "usage-04-lifetime-persistence-and-errors-mission.ahk",
    supplies: {
      supply: "reportImmediately"
    }
  },
  {
    ; Leaving a blank is the same as declaring an anonymous adventurer.
    adventurerName: "",
    missionFile: "usage-04-lifetime-persistence-and-errors-mission.ahk",
    supplies: {
      supply: "reportImmediately"
    }
  }
]

dispatchList2 := [
  'single data primitive',
  7465,
  {
    missionFile: "usage-04-lifetime-persistence-and-errors-mission.ahk",
    adventurerName: "Truffles",
    supplies: {
      supply: "reportImmediately"
    }
  }
]


QUEST.missionFile := "usage-05-QUEST-array-convention-mission.ahk"
; We're sending the whole array, we're not looping and sending each adventurer out one by one.
QUEST.Dispatch(dispatchList, ArReyport, backupSupplies)
QUEST.Dispatch(dispatchList2, ArReyport)

; Whether our adventurer's sending back a singular primitive data type or a structured data,
; we're getting a Map(). This only happens if we're dispatching an array as a pack.
ArReyport(report) {
  for adventurerName, lootCargo in report {
    ; With an array dispatched as a pack, we can identify which report belongs to which adventurer.
    OutputDebug adventurerName, lootCargo
  }
}


/**
 * -- REVIEW --
 * In this demo, we learned that:
 * 1. The convention is a loosely coupled structure.
 * 2. We can set mission parameters per array item.
 * 3. We can dispatch an array of adventurers as a pack, we don't need to loop through each item.
 *   3.a. If the item in the array is an object, there are reserved words that QUEST recognizes.
 *     3.a.i. 'missionFile', 'missionDeadline', 'adventurerName', 'supplies'
 *     3.a.ii. the reserved words have default values if not used.
 *   3.b. We can send an array mix of primitives and objects.
 *   3.c. Reports are tied to an adventurer name if we dispatch an array as a pack.
 * 4. backupSupplies can be used to fill up an adventurer's supplies if it doesn't exist.
 */