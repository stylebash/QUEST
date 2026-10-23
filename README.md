<h1 align="center">QUEST</h1>

<div align="center">

  #### Quick Utility for External Subprocess Tasks

</div>

> [!TIP]
> Convention over configuration.

> A helper class to streamline processing external AHK scripts asynchronously or synchronously.

- Handles inter-process communication (IPC) via Windows WM_COPYDATA and Base64 JSON payloads.
- Almost zero boilerplate **code.**
- Convention over configuration.
  - Loose and versatile convention as well.
- Call nested object data directly.
  - QUEST handles unpacking objects for you.
  - Map() and object literals: {} are treated the same, too.
- Chain data dependent processes (synchronous mode).
- Nest dispatcher branches towards leaf processes "missions".
- Easily track and trace subprocess events by naming a "mission" to an "adventurer".

---

## What?

Writing concurrent tasks, background workers, or splitting heavy processing in AutoHotkey usually means dealing with messy inter-process communication, pipes, or raw command-line piping.\
This class tackles that pain point.

You can define missions, spawn "adventurer" subprocesses, set timeouts, and pass structured supplies or primitive data back and forth seamlessly.

- **Asynchronous & Serial Execution** – run tasks in parallel or chain them sequentially where subsequent steps can reference previous results (`prev`).
- **Windows-native IPC** – uses `WM_COPYDATA` (`0x004A`) under the hood so data is transmitted cleanly between parent dispatchers and child scripts without writing temporary files.
- **Built-in Safety Guardrails** – per-task deadlines automatically terminate hanging adventurer processes and catch errors gracefully.

You'll want this if you just want:

- To make your AHK files talk to each other without losing your sanity.
- To run background jobs or heavy logic in isolated child subprocesses.
- Structured task chains with clean callback handling.
- To keep your main UI thread responsive while adventurers do the heavy lifting.

---

## Installation

QUEST is structured around `QUEST.ahk` and requires a JSON helper (such as cJSON by G33kDude).

### Option 1: Manual copy (recommended)

1. Download `[QUEST.ahk](QUEST.ahk)` from this repository.
2. Place it in your project folder or a shared `lib` directory, for example:

   ```text
   your_ahk_project/
     lib/
       QUEST.ahk
       JSON.ahk
     main.ahk
```

```
3. Include it at the top of your main script:

   ```ahk
   #Requires AutoHotkey v2.0
   #Include "lib\QUEST.ahk"
```

### Requirements

- AutoHotkey v2.0 or later
- Windows (utilizes `WM_COPYDATA` and Crypt32 Base64 encoding functions)
- A JSON library compatible with your setup (e.g., cJSON)

---

## Usage

After including the file, you can set your target adventurer script file, pass supplies or primitives via `QUEST.Dispatch()`, and handle results using a callback function.

### Basic usage

```ahk
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "lib\JSON.ahk"
#Include "QUEST.ahk"

; Define a simple mission payload
mission := "basicString"

; Specify the target adventurer script file
QUEST.missionFile := "mission.ahk"

; Dispatch the mission with a callback for results
QUEST.Dispatch(mission, MissionResults)

MissionResults(results) {
    OutputDebug results
}
```

On your target adventurer script (`mission.ahk`), read the incoming supplies and report back:

```ahk
#Requires AutoHotkey v2.0
#Include "QUEST.ahk"

; Access incoming supplies passed from the dispatcher
payLoad := "Supply received: " . QUEST.items.supply . "; Type: " . Type(QUEST.items.supply)

; Send results back to the dispatcher and auto-exit
QUEST.Report(payLoad)
```

### Parallel dispatches

You can dispatch an array of structured tasks simultaneously, assigning specific names or properties to each adventurer:

```ahk
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "lib\JSON.ahk"
#Include "QUEST.ahk"

QUEST.missionFile := "mission.ahk"
QUEST.missionDeadline := 3000

zords := [
    { adventurerName: "kimberly", supplies: { callout: "Dinozord Power!" } },
    { adventurerName: "jason", supplies: { callout: "Dinozord Power!" } }
]

QUEST.Dispatch(zords, AsyncReport)

AsyncReport(resultsMap) {
    for ranger, dinozord in resultsMap {
        OutputDebug StrTitle(ranger) . ": " . dinozord
    }
}
```

### Sequential / Serial task chains (`prev`)

Chain tasks sequentially where downstream tasks can consume results from previous steps using the `prev` context:

```ahk
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "lib\JSON.ahk"
#Include "QUEST.ahk"

serialMissions := [
    { callout: "We need Dinozord power, now!" },
    (prev) => ({ log: prev.log, callout: "Megazord battle mode, now!" })
]

QUEST.Dispatch(serialMissions, SerialReport, {}, "serial")

SerialReport(results) {
    resultOnStep := QUEST.UnpackSerialResults(results)
    for index, res in resultOnStep {
        OutputDebug res['log']
    }
}
```

notes\*\*

- If an adventurer doesn't report back after a set `QUEST.missionDeadline`, the task is automatically marked as failed to prevent deadlocks.
- More usage examples (covering primitive types, structured maps, errors, and array conventions) can be found in the [usageExamples/](usageExamples/) folder.

---

## Configuration & API Reference

| Method / Property                                              | Description                                                                                                                       |
| :------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| `QUEST.Dispatch(missions, [callback], [backupSupplies], [mode])` | Spawns sub-processes. Dispatches missions asynchronously (`parallel`) or synchronously (`sequential`/`serial`).                   |
| `QUEST.Report(payload, [missionId], [hwnd], [autoExit])`       | Reports data back to the parent dispatcher and exits by default.                                                                  |
| `QUEST.UnpackSerialResults(resultsMap, [targetKey])`           | Helper to flatten and unpack serial execution result maps into an array.                                                          |
| `QUEST.missionFile`                                            | Sets the target adventurer script file name.                                                                                      |
| `QUEST.missionDeadline`                                        | Sets the timeout threshold in milliseconds before a task is killed.                                                               |
| `QUEST.keepDispatcherAlive`                                    | Keeps the main dispatcher process persistent even after all missions are complete and have reported back.                         |
| `QUEST.traceAndLog`                                            | `true` or `false`. Toggle file-based trace logging (`QUEST_trace_and.log`).                                                       |
| `QUEST.traceAndLogFileName`                                    | Filename where log data is saved. Defaults to: `QUEST_trace_and.log`.                                                             |
| `QUEST.items.supply`                                           | Retrieve singular primitive data passed from the dispatcher.                                                                      |
| `QUEST.items.<key>`                                            | If the dispatcher passes a map object or an object literal, QUEST unpacks the object so you just have to call the specific \[key\]. |
| `QUEST.Get(key, [defaultValue])`                               | Alternative to `QUEST.items.____`. Retrieves a supply value safely from initialized adventurer options.                           |

---

*QUEST is provided as-is under the MIT License.*