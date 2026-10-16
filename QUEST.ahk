/** QUEST
 * Quick Utility for External Subprocess Tasks
 * Version 1.0
 * Make your AHK files talk to each other.
 * 
 * Author: stylebash
 * Contact: https://github.com/stylebash
*/



#Requires AutoHotkey v2.0
#SingleInstance Off
#Include lib/JSON.ahk ; cJSON by G33kDude

/**
 * Quick Utility for External Subprocess Tasks (QUEST)
 * Manages asynchronous parallel and sequential task delegation to adventurer AutoHotkey 
 * subprocesses using WM_COPYDATA inter-process communication and Base64-encoded JSON payloads.
 * 
 * ============================================================================
 * EXECUTION MODEL:
 * This class operates in two distinct modes within the same codebase:
 * 
 * 1. DISPATCHER MODE (Main Script Process)
 *    - Triggered when A_Args is empty.
 *    - Listens for Windows WM_COPYDATA messages (_OnDataReceived).
 *    - Spawns child AHK subprocesses via CLI (`A_AhkPath /script mission.ahk`).
 *    - Tracks pending tasks, timeouts, and result aggregation (parallel/serial).
 * 
 * 2. (WORKER) / "ADVENTURER" MODE (Child Subprocess / Nested Sub-Dispatcher)
 *    - Triggered when A_Args[1] contains a Base64-encoded JSON payload.
 *    - Parses task supplies, window HWND, and taskId into QUEST.items.
 *    - Executes mission logic, then calls QUEST.Report() to serialize results 
 *      and pass them back to the parent Dispatcher's HWND via WM_COPYDATA.
 *    - Supports nested dispatching by initializing worker-level WM_COPYDATA listeners.
 * 
 * IPC DATA PROTOCOL (WM_COPYDATA):
 * - dwData  : Integer missionId
 * - cbData  : Byte size of UTF-8 JSON string
 * - lpData  : Pointer to raw UTF-8 JSON buffer
 * ============================================================================
 */
class QUEST {
    static WM_COPYDATA := 0x004A
    static pendingMissions := Map()
    static missionCounter := 0
    static activeMissionCount := 0
    static isInitialized := false
    static items := Map()
    static isAdventurerThread := false
    static adventurerName := ""
    static traceAndLog := false
    static traceAndLogFileName := "QUEST_trace_and.log"
    
    static _keepDispatcherAlive := false
    static keepDispatcherAlive {
        set {
            this._keepDispatcherAlive := value
            if (value) {
                Persistent(true)
            } else {
                this._CheckFinished()
            }
        }
        get => this._keepDispatcherAlive
    }

    static missionDeadline := 1000
    static dispatcherHwnd := 0
    static currentMissionId := 0

    static missionFile := 'mission.ahk'

    /**
     * Auto-initialize thread state when class is loaded.
     * Determines whether this script instance is the main Dispatcher or a spawned adventurer (worker).
     */
    static __New() {
        DetectHiddenWindows(true)
        if (A_Args.Length >= 1 && A_Args[1] != "") {
            this._AutoInitAdventurer(A_Args[1])
        } else {
            this._AutoInitDispatcher()
        }
    }

    /**
     * Initializes the process as a Dispatcher listening for incoming WM_COPYDATA results.
     * Allows worker threads to double as sub-dispatchers.
     */
    static _AutoInitDispatcher() {
        DetectHiddenWindows(true)
        if (!this.isInitialized) {
            DetectHiddenWindows(true)
            OnMessage(this.WM_COPYDATA, ObjBindMethod(this, "_OnDataReceived"))
            this.isInitialized := true
        }
        return true
    }

    /**
     * Initializes a subprocess adventurer (worker) by decoding its Base64 JSON payload
     * and mapping input options/supplies into QUEST.items.
     */
    static _AutoInitAdventurer(encodedBase64String) {
    this.isAdventurerThread := true
    Persistent(true)

    OnError(ObjBindMethod(this, "_OnAdventurerUnhandledError"))

    try {
        jsonString := QUEST._Base64Decode(encodedBase64String)
        parsed := JSON.Load(jsonString)
        
        optsMap := Map()
        optsMap.DefineProp("__Get", { Call: (self, name, params) => self.Has(name) ? self[name] : "" })

        if (Type(parsed) == "Map") {
            for k, v in parsed {
                optsMap[k] := v
            }
        } else if (IsObject(parsed)) {
            for k, v in parsed.OwnProps() {
                optsMap[k] := parsed.%k%
            }
        }

        if (optsMap.Has("dispatcherHwnd")) {
            this.dispatcherHwnd := Integer(optsMap["dispatcherHwnd"])
        }
        if (optsMap.Has("taskId")) {
            this.currentMissionId := Integer(optsMap["taskId"])
        }

        ; Extract adventurerName / item priority without over-writing
        if (optsMap.Has("adventurerName") && optsMap["adventurerName"] != "") {
            this.adventurerName := optsMap["adventurerName"]
            optsMap.Delete("adventurerName")
            if (optsMap.Has("item"))
                optsMap.Delete("item")
        } else if (optsMap.Has("item") && optsMap["item"] != "") {
            this.adventurerName := optsMap["item"]
            optsMap.Delete("item")
        } else {
            this.adventurerName := "adventurer_1"
        }

        ; Store pure user supplies into QUEST.items
        this.items := optsMap

        ; LOG AFTER PARSING: Accurately reflects assigned state
        this.TraceLogger("Mission started. Adventurer: '" . this.adventurerName . "' | Dispatcher HWND: " . this.dispatcherHwnd)

    } catch Error as err {
        QUEST.SendErrorToMain("Adventurer Initialization Failure: " . err.Message . " (Line " . err.Line . ")")
    }
}

    /**
     * Global error handler for uncaught exceptions inside adventurer subprocesses.
     */
    static _OnAdventurerUnhandledError(err, mode) {
        this.SendErrorToMain("Uncaught Adventurer Error: " . err.Message . " at line " . err.Line . " in " . err.File)
        return true
    }

    /**
     * Formats an error payload and reports it back to the main dispatcher window, then exits.
     */
    static SendErrorToMain(message) {
        errPayload := Map(
            "error", true,
            "message", message
        )
        this.Report(errPayload)
        ExitApp()
    }

    /**
     * Retrieves a supply value by key from the adventurer's initialized options map.
     */
    static Get(key, defaultValue := "") {
        if (Type(this.items) == "Map") {
            return this.items.Has(key) ? this.items[key] : defaultValue
        }
        return defaultValue
    }

    /**
     * Helper to retrieve or lazily generate an auto-numbered adventurer name.
     */
    static _ResolveAdventurerName(explicitName, isSingleDispatch) {
        if (explicitName != "") {
            return explicitName
        }
        if (isSingleDispatch && HasProp(this, "adventurerName") && this.adventurerName != "") {
            return this.adventurerName
        }
        this._globalAdventurerIndex++
        return "adventurer_" . this._globalAdventurerIndex
    }

    /**
     * Safely extracts mission supplies from either a Map or an Object literal ({}),
     * stripping out control properties without relying on Map-only methods.
     */
    static _ExtractSupplies(source) {
        supplies := Map()
        if (Type(source) == "Map") {
            for k, v in source {
                if (k != "adventurerName" && k != "script" && k != "missionFile" && k != "missionDeadline" && k != "supplies" && k != "opts") {
                    supplies[k] := v
                }
            }
        } else if (IsObject(source)) {
            for k, v in source.OwnProps() {
                if (k != "adventurerName" && k != "script" && k != "missionFile" && k != "missionDeadline" && k != "supplies" && k != "opts") {
                    supplies[k] := source.%k%
                }
            }
        }
        return supplies
    }

    /**
     * Main dispatcher method to delegate missions to adventurer subprocesses.
     * Supports both parallel and sequential (serial) execution modes.
     */
    static Dispatch(missions, reportToThisFunc := "", backupSupplies := {}, mode := "parallel") {
        this._AutoInitDispatcher()
        Persistent(true)
        results := Map()
        mode := StrLower(mode)

        ; Ensure global sequence counter exists across ALL dispatches
        if (!HasProp(this, "_globalAdventurerIndex")) {
            this._globalAdventurerIndex := 0
        }

        ; Track whether the user passed a single mission or an array
        isSingleDispatch := (Type(missions) != "Array")

        if (isSingleDispatch) {
            missions := [missions]
        }

        if (missions.Length == 0) {
            this._CheckFinished()
            if (reportToThisFunc) {
                reportToThisFunc.Call(results)
            }
            return
        }

        ; Route execution flow based on concurrency mode
        if (mode == "sequential" || mode == "serial" || mode == "serialized" || mode == "sequence" || mode == "synchronous" || mode == "sync") {
            this._RunNextSequential(missions, backupSupplies, 1, results, reportToThisFunc, isSingleDispatch)
        } else {
            tracker := { remaining: missions.Length }

            for index, mission in missions {
                adventurerName := ""
                supplies := Map()
                scriptFile := ""
                deadline := 0

                if (!IsObject(mission) || Type(mission) == "String" || Type(mission) == "Integer" || Type(mission) == "Float") {
                    ; Primitive mission value
                    adventurerName := this._ResolveAdventurerName("", isSingleDispatch)
                    supplies := mission

                } else if (Type(mission) == "Map") {
                    ; Map object mission definition
                    explicitName := (mission.Has("adventurerName") && mission.Get("adventurerName", "") != "") ? mission["adventurerName"] : ""
                    adventurerName := this._ResolveAdventurerName(explicitName, isSingleDispatch)

                    scriptFile := (mission.Has("script") && mission["script"] != "") ? mission["script"] 
                        : (mission.Has("missionFile") && mission["missionFile"] != "") ? mission["missionFile"] : ""
                    deadline   := (mission.Has("missionDeadline") && mission.Get("missionDeadline", 0) != 0) ? mission["missionDeadline"] : 0
                    
                    if (mission.Has("supplies") && mission.Get("supplies", "") != "") {
                        supplies := mission["supplies"]
                    } else if (mission.Has("opts") && mission.Get("opts", "") != "") {
                        supplies := mission["opts"]
                    } else {
                        supplies := this._ExtractSupplies(mission)
                    }

                } else {
                    ; Plain Object Literal ({ key: val }) or Struct mission definition
                    explicitName := (HasProp(mission, "adventurerName") && mission.adventurerName != "") ? mission.adventurerName : ""
                    adventurerName := this._ResolveAdventurerName(explicitName, isSingleDispatch)

                    scriptFile := HasProp(mission, "script") && mission.script != "" ? mission.script 
                        : HasProp(mission, "missionFile") && mission.missionFile != "" ? mission.missionFile : ""
                    deadline   := HasProp(mission, "missionDeadline") ? mission.missionDeadline : 0

                    if (HasProp(mission, "supplies")) {
                        supplies := mission.supplies
                    } else if (HasProp(mission, "opts")) {
                        supplies := mission.opts
                    } else {
                        supplies := this._ExtractSupplies(mission)
                    }
                }

                missionArray := [adventurerName, supplies]
                this._DispatchMission(adventurerName, missionArray, supplies, backupSupplies, scriptFile, deadline, results, tracker, reportToThisFunc)
            }
        }
    }

    /**
     * Helper to wrap parallel task dispatch and handle completion aggregation via callbacks.
     */
    static _DispatchMission(adventurerName, missionArray, missionSupplies, backupSupplies, missionFile, missionDeadline, results, tracker, reportToThisFunc) {
        this.FetchData(
            missionArray,
            (resolvedKey, payload, elapsedMs) => (
                results[String(resolvedKey)] := payload,
                (--tracker.remaining == 0) ? (
                    reportToThisFunc ? reportToThisFunc.Call(
                        (results.Count == 1) ? payload : results
                    ) : 0,
                    this._CheckFinished()
                ) : 0
            ),
            missionSupplies,
            backupSupplies,
            missionFile,
            missionDeadline
        )
    }

    /**
     * Spawns an adventurer subprocess, serializes supplies/options to Base64 JSON,
     * and sets up timeout timers to safeguard against hanging processes.
     */
    static FetchData(key, callback, supplies := {}, backupSupplies := {}, targetScript := "", deadline := 0) {
        Persistent(true)

        dataKeyStr := String(IsObject(key) ? key[1] : key)
        
        missionScript := (targetScript != "") ? targetScript : (this.missionFile != "" ? this.missionFile : "mission.ahk")
        
        fullScriptPath := RegExMatch(missionScript, "^[A-Za-z]:\\") 
            ? missionScript 
            : A_ScriptDir . "\" . missionScript

        if (!FileExist(fullScriptPath)) {
            errPayload := Map(
                "error", true,
                "message", Format("Adventurer mission file not found: '{1}'", fullScriptPath)
            )

            if (callback) {
                callback.Call(dataKeyStr, errPayload, 0)
            }
            this._CheckFinished()
            return
        }

        mergedOpts := Map()

        ; Helper function to merge backup supplies and task-specific supplies into a single map
        mergeIntoMap(sourceData, targetMap) {
            if (!IsObject(sourceData)) {
                targetMap["supply"] := sourceData
            } else if (Type(sourceData) == "Array") {
                for idx, item in sourceData {
                    targetMap["supply_" . idx] := item
                }
            } else if (Type(sourceData) == "Map") {
                for k, v in sourceData {
                    if (k != "adventurerName" && k != "script" && k != "missionDeadline") {
                        targetMap[k] := v
                    }
                }
            } else if (IsObject(sourceData)) {
                for k, v in sourceData.OwnProps() {
                    if (k != "adventurerName" && k != "script" && k != "missionDeadline") {
                        targetMap[k] := sourceData.%k%
                    }
                }
            }
        }

        mergeIntoMap(backupSupplies, mergedOpts)
        mergeIntoMap(supplies, mergedOpts)

        this.missionCounter++
        this.activeMissionCount++
        missionId := this.missionCounter

        ; Ensure nested dispatchers route child responses back to THIS running process window
        currentHwnd := Integer(A_ScriptHwnd)

        mergedOpts["item"]           := dataKeyStr
        mergedOpts["dispatcherHwnd"] := currentHwnd
        mergedOpts["taskId"]         := missionId

        jsonOpts := JSON.Dump(mergedOpts)
        encodedOpts := this._Base64Encode(jsonOpts)
        
        this.TraceLogger("Dispatching adventurer. Target: " . fullScriptPath . " | Given Dispatcher HWND: " . mergedOpts["dispatcherHwnd"])
        pid := this.RunCmd(fullScriptPath, encodedOpts)

        if (pid == 0) {
            this.activeMissionCount--
            errPayload := Map(
                "error", true,
                "message", Format("Failed to launch adventurer process for mission: '{1}'", fullScriptPath)
            )
            if (callback) {
                callback.Call(dataKeyStr, errPayload, 0)
            }
            this._CheckFinished()
            return
        }

        if (deadline <= 0) {
            deadline := this.missionDeadline
        }

        timerFunc := ""
        if (deadline > 0) {
            timerFunc := ObjBindMethod(this, "_OnTaskTimeout", missionId)
            SetTimer(timerFunc, -Abs(deadline))
        }

        this.pendingMissions[missionId] := {
            dataKey: dataKeyStr,
            callback: callback,
            startTime: A_TickCount,
            pid: pid,
            timerFunc: timerFunc
        }
    }

    /**
     * Executes the AutoHotkey interpreter CLI command to launch a detached/hidden mission script.
     */
    static RunCmd(scriptPath, encodedPayload) {
        adventurerPid := 0
        try {
            cmd := '"' . A_AhkPath . '" /script "' . scriptPath . '" "' . encodedPayload . '"'
            Run(cmd, A_ScriptDir, "Hide", &adventurerPid)
        } catch Any {
            return 0
        }
        return adventurerPid
    }

    /**
     * Unpacks results from a completed sequential or parallel run into a clean Array.
     */
    static UnpackSerialResults(resultsMap, targetKey := "") {
        unpacked := []

        ; 1. Direct Array input
        if (Type(resultsMap) == "Array") {
            for val in resultsMap
                unpacked.Push(this._ExtractValue(val, targetKey))
            return unpacked
        }

        ; 2. Map input: check for explicit insertion-order key list first
        if (Type(resultsMap) == "Map") {
            if (HasProp(resultsMap, "__orderedKeys") && IsObject(resultsMap.__orderedKeys)) {
                for key in resultsMap.__orderedKeys {
                    if (resultsMap.Has(key))
                        unpacked.Push(this._ExtractValue(resultsMap[key], targetKey))
                }
                return unpacked
            }

            ; Fallback for standard Maps without explicit order metadata
            for key, val in resultsMap {
                unpacked.Push(this._ExtractValue(val, targetKey))
            }
        }

        return unpacked
    }

    /**
     * Extracts a specific property or value from a task payload.
     */
    static _ExtractValue(payload, targetKey := "") {
        if (!IsObject(payload))
            return payload

        ; 1. Try explicit targetKey first
        if (targetKey != "") {
            if (Type(payload) == "Map" && payload.Has(targetKey))
                return payload[targetKey]
            if (HasProp(payload, targetKey))
                return payload.%targetKey%
        }

        ; 2. Map payload handling
        if (Type(payload) == "Map") {
            if (payload.Count == 1) {
                for _, v in payload
                    return v
            }
            return payload
        }

        ; 3. Plain Object payload handling ({ key: val })
        if (IsObject(payload)) {
            props := [payload.OwnProps()*]
            if (props.Length == 1)
                return payload.%props[1]%
            return payload
        }

        return payload
    }

    /**
     * Lists common output property synonyms used for automatic value unpacking.
     */
    static _GetOutputSynonyms() {
        return [
            "output", "outputs", "result", "results", "value", 
            "calculatedAnswer", "calculatedAnswers", "calculated", 
            "score", "scores", "answer", "answers", "grade", 
            "yield", "turnout", "return", "returns", "outcome", 
            "outcomes", "conclusion", "conclusions", "solution", 
            "solutions", "effect", "effects", "report", "reports", 
            "record", "records", "deliver", "delivers", "data"
        ]
    }

    ; =========================================================================
    ; NESTED CLASS: Handles sequential state resolution (prev)
    ; =========================================================================
    class SerialContext {
        __New(resultsMap) {
            this.map := resultsMap
            
            ; Extract keys in exact execution sequence using __orderedKeys if available
            this.keys := []
            if (HasProp(resultsMap, "__orderedKeys") && IsObject(resultsMap.__orderedKeys)) {
                for k in resultsMap.__orderedKeys
                    this.keys.Push(String(k))
            } else {
                for k, v in resultsMap
                    this.keys.Push(String(k))
            }
        }

        __Get(name, params) {
            ; 1. Positional access: prev.Last
            if (name == "Last" && this.keys.Length > 0) {
                lastKey := this.keys[this.keys.Length]
                return this._WrapIfMap(QUEST._ExtractValue(this.map[lastKey]))
            }

            ; 2. Explicit step name lookup: prev.asdf or prev.adventurer_2
            if (this.map.Has(name)) {
                return this._WrapIfMap(QUEST._ExtractValue(this.map[name]))
            }

            ; 3. Implicit Delegation: Look directly inside the IMMEDIATELY PRECEDING step's payload
            if (this.keys.Length > 0) {
                lastKey := this.keys[this.keys.Length]
                lastPayload := this.map[lastKey]

                if (Type(lastPayload) == "Map") {
                    if (lastPayload.Has(name))
                        return lastPayload[name]
                } else if (IsObject(lastPayload)) {
                    if (HasProp(lastPayload, name))
                        return lastPayload.%name%
                } else if (name == "value" || name == "result") {
                    return lastPayload
                }
            }

            throw PropertyError("Unknown serial step or property access: " . name)
        }

        __Item[index] {
            get {
                if (index > 0 && index <= this.keys.Length) {
                    key := this.keys[index]
                    return this._WrapIfMap(QUEST._ExtractValue(this.map[key]))
                }
                throw IndexError("SerialContext index out of bounds: " . index)
            }
        }

        _WrapIfMap(val) {
            if (Type(val) == "Map") {
                wrapper := {}
                for k, v in val
                    wrapper.%k% := v
                return wrapper
            }
            return val
        }
    }

    /**
     * Reports task results back from an adventurer subprocess to the parent Dispatcher window via WM_COPYDATA.
     */
    static Report(strResults := true, missionId := 0, hwnd := 0, autoExit := true) {
        DetectHiddenWindows(true)
        this.TraceLogger("Report() called by " . this.adventurerName . " targeting HWND " . this.dispatcherHwnd)
        targetHwnd := (hwnd != 0) ? Integer(hwnd) : this.dispatcherHwnd
        targetMissionId := (missionId != 0) ? missionId : this.currentMissionId

        if (targetHwnd == 0) {
            return false
        }

        strResults := JSON.Dump(strResults)

        ; Prepare UTF-8 string buffer for IPC transmission
        byteCount := StrPut(strResults, "UTF-8")
        buf := Buffer(byteCount, 0)
        StrPut(strResults, buf, "UTF-8")

        cds := Buffer(A_PtrSize == 8 ? 24 : 12, 0)
        NumPut("UPtr", targetMissionId, cds, 0)
        NumPut("UInt", byteCount,     cds, A_PtrSize)
        NumPut("UPtr", buf.Ptr,       cds, A_PtrSize == 8 ? 16 : 8)

        result := SendMessage(this.WM_COPYDATA, targetMissionId, cds.Ptr,, "ahk_id " . targetHwnd)

        if (autoExit) {
            ExitApp()
        }

        return result
    }

    /**
     * Encodes a string into Base64 using Windows Crypt32 API.
     */
    static _Base64Encode(str) {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CRYPT_STRING_NOCRLF := 0x40000000
        
        utf8Buf := Buffer(StrPut(str, "UTF-8"))
        StrPut(str, utf8Buf, "UTF-8")
        
        outLen := 0
        DllCall("Crypt32\CryptBinaryToStringW", "Ptr", utf8Buf, "UInt", utf8Buf.Size - 1, "UInt", CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, "Ptr", 0, "UInt*", &outLen)
        
        outBuf := Buffer(outLen * 2)
        DllCall("Crypt32\CryptBinaryToStringW", "Ptr", utf8Buf, "UInt", utf8Buf.Size - 1, "UInt", CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, "Ptr", outBuf, "UInt*", &outLen)
        
        return StrGet(outBuf)
    }

    /**
     * Decodes a Base64 string into UTF-8 using Windows Crypt32 API.
     */
    static _Base64Decode(base64Str) {
        static CRYPT_STRING_BASE64 := 0x00000001
        
        outLen := 0
        DllCall("Crypt32\CryptStringToBinaryW", "Str", base64Str, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", &outLen, "Ptr", 0, "Ptr", 0)
        
        outBuf := Buffer(outLen * 2)
        DllCall("Crypt32\CryptStringToBinaryW", "Str", base64Str, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", outBuf, "UInt*", &outLen, "Ptr", 0, "Ptr", 0)
        
        return StrGet(outBuf, "UTF-8")
    }

    /**
     * Timeout callback triggered when an adventurer task exceeds its deadline.
     * Terminates the adventurer process and invokes the error callback.
     */
    static _OnTaskTimeout(missionId) {
        if (!this.pendingMissions.Has(missionId)) {
            return
        }

        missionInfo := this.pendingMissions[missionId]
        elapsedMs := A_TickCount - missionInfo.startTime

        if (missionInfo.pid != 0 && ProcessExist(missionInfo.pid)) {
            try ProcessClose(missionInfo.pid)
        }

        errPayload := Map(
            "error", true,
            "message", Format("Mission of '{1}' deadline reached after {2} ms. Adventurer-san died? 😟 😭", missionInfo.dataKey, elapsedMs)
        )

        callback := missionInfo.callback
        dataKey := missionInfo.dataKey

        this.pendingMissions.Delete(missionId)
        this.activeMissionCount--

        if (callback) {
            callback.Call(dataKey, errPayload, elapsedMs)
        }

        this._CheckFinished()
    }

    /**
     * Recursively runs the next step in a sequential/serial mission chain.
     */
    static _RunNextSequential(missions, backupSupplies, index, resultsMap, reportToThisFunc, isSingleDispatch := false) {
        if (index > missions.Length) {
            if (reportToThisFunc) {
                finalOutput := resultsMap
                if (resultsMap.Count == 1) {
                    for k, v in resultsMap {
                        finalOutput := v
                    }
                }
                reportToThisFunc.Call(finalOutput)
            }
            this._CheckFinished()
            return
        }

        item := missions[index]
        
        ; Instantiates SerialContext for step functions to access previous results (`prev`)
        ctx := QUEST.SerialContext(resultsMap)
        
        ; Evaluate step function if Callable
        rawMission := (HasMethod(item)) ? item.Call(ctx) : item
        
        ; Sanitize raw SerialContext references out of mission envelope
        mission := this._SanitizeSerialPayload(rawMission, ctx)
        
        adventurerName := ""
        opts := Map()
        scriptFile := ""
        deadline := 0

        if (!IsObject(mission) || Type(mission) == "String" || Type(mission) == "Integer" || Type(mission) == "Float") {
            adventurerName := this._ResolveAdventurerName("", isSingleDispatch)
            opts := mission

        } else if (Type(mission) == "Map") {
            explicitName := (mission.Has("adventurerName") && mission.Get("adventurerName", "") != "") ? mission["adventurerName"] : ""
            adventurerName := this._ResolveAdventurerName(explicitName, isSingleDispatch)

            scriptFile := (mission.Has("script") && mission.Get("script", "") != "") ? mission["script"] 
                        : (mission.Has("missionFile") && mission.Get("missionFile", "") != "") ? mission["missionFile"] : ""
            deadline   := (mission.Has("missionDeadline") && mission.Get("missionDeadline", 0) != 0) ? mission["missionDeadline"] : 0
            
            if (mission.Has("supplies") && mission.Get("supplies", "") != "") {
                opts := mission["supplies"]
            } else if (mission.Has("opts") && mission.Get("opts", "") != "") {
                opts := mission["opts"]
            } else {
                opts := this._ExtractSupplies(mission)
            }

        } else {
            ; Plain Object Literal ({ key: val }) or Struct
            explicitName := (HasProp(mission, "adventurerName") && mission.adventurerName != "") ? mission.adventurerName : ""
            adventurerName := this._ResolveAdventurerName(explicitName, isSingleDispatch)

            scriptFile := HasProp(mission, "script") && mission.script != "" ? mission.script 
                        : HasProp(mission, "missionFile") && mission.missionFile != "" ? mission.missionFile : ""
            deadline   := HasProp(mission, "missionDeadline") ? mission.missionDeadline : 0

            if (HasProp(mission, "supplies")) {
                opts := mission.supplies
            } else if (HasProp(mission, "opts")) {
                opts := mission.opts
            } else {
                opts := this._ExtractSupplies(mission)
            }
        }

        ; Sanitize opts explicitly in case supplies/opts carried raw context
        opts := this._SanitizeSerialPayload(opts, ctx)

        itemArray := [adventurerName, opts]
        
        this.FetchData(
            itemArray,
            (key, payload, elapsedMs) => (
                ; Track insertion key order explicitly on the Map object
                (!HasProp(resultsMap, "__orderedKeys") ? resultsMap.__orderedKeys := [] : 0),
                resultsMap.__orderedKeys.Push(String(key)),

                ; Store raw payload
                resultsMap[String(key)] := payload,

                (Type(payload) == "Map" && payload.Has("error"))
                    ? (
                        reportToThisFunc ? reportToThisFunc.Call((resultsMap.Count == 1) ? payload : resultsMap) : 0,
                        this._CheckFinished()
                    )
                    : this._RunNextSequential(missions, backupSupplies, index + 1, resultsMap, reportToThisFunc, isSingleDispatch)
            ),
            opts,
            backupSupplies,
            scriptFile,
            deadline
        )
    }

    /**
     * Pre-IPC Serialization Sanitizer
     * 
     * Recursively inspects step payload values before IPC serialization.
     * Unwraps raw SerialContext references into their preceding scalar result (.Last).
     */
    static _SanitizeSerialPayload(payload, serialCtx) {
        ; 1. Direct match: step lambda returned `results` directly
        if (Type(payload) == "QUEST.SerialContext" || Type(payload) == "SerialContext") {
            return serialCtx.Last
        }

        ; 2. Plain Object / Struct Literal ({ action: "multiply", a: results })
        if (Type(payload) == "Object") {
            sanitized := {}
            for prop, val in payload.OwnProps() {
                if (Type(val) == "QUEST.SerialContext" || Type(val) == "SerialContext") {
                    sanitized.%prop% := serialCtx.Last
                } else if (Type(val) == "Object" || Type(val) == "Map") {
                    sanitized.%prop% := this._SanitizeSerialPayload(val, serialCtx)
                } else {
                    sanitized.%prop% := val
                }
            }
            return sanitized
        }

        ; 3. Map structure (Map('action', 'subtract', 'a', results))
        if (Type(payload) == "Map") {
            sanitized := Map()
            for key, val in payload {
                if (Type(val) == "QUEST.SerialContext" || Type(val) == "SerialContext") {
                    sanitized[key] := serialCtx.Last
                } else if (Type(val) == "Object" || Type(val) == "Map") {
                    sanitized[key] := this._SanitizeSerialPayload(val, serialCtx)
                } else {
                    sanitized[key] := val
                }
            }
            return sanitized
        }

        ; 4. Scalar primitives (Float, Integer, String) pass through unchanged
        return payload
    }

    /**
     * Message handler for incoming WM_COPYDATA messages sent by adventurer subprocesses.
     */
    static _OnDataReceived(wParam, lParam, msg, hwnd) {
        this.TraceLogger("WM_COPYDATA received on HWND " . hwnd . " from HWND " . wParam)
        missionId := NumGet(lParam, 0, "UPtr")
        cbData := NumGet(lParam, A_PtrSize, "UInt")
        lpData := NumGet(lParam, A_PtrSize == 8 ? 16 : 8, "UPtr")

        if (lpData == 0 || cbData == 0) {
            return true
        }

        payloadStr := StrGet(lpData, "UTF-8")

        if (!this.pendingMissions.Has(missionId)) {
            return true
        }

        missionInfo := this.pendingMissions[missionId]
        elapsedMs := A_TickCount - missionInfo.startTime

        if (missionInfo.timerFunc) {
            SetTimer(missionInfo.timerFunc, 0)
        }

        ; Safely remove pending task before firing callbacks
        this.pendingMissions.Delete(missionId)
        this.activeMissionCount--

        parsedResult := ""
        try {
            parsedResult := JSON.Load(payloadStr)
        } catch Error as err {
            parsedResult := Map("error", true, "message", "JSON Parse Error: " . err.Message)
        }

        if (HasProp(missionInfo, "callback") && missionInfo.callback) {
            missionInfo.callback.Call(missionInfo.dataKey, parsedResult, elapsedMs)
        }

        this._CheckFinished()
        return true
    }

    /**
     * Checks if all active missions are completed and handles process persistence state.
     */
    static _CheckFinished() {
        if (this.activeMissionCount <= 0) {
            this.activeMissionCount := 0
            ; Do not drop persistence if this process is an active adventurer thread waiting to report back
            if (!this.keepDispatcherAlive && !this.isAdventurerThread) {
                Persistent(false)
            }
        }
    }

    /**
     * Logs a message to the a file.
     * On the same directory as where the script calling it is located
     * 
     * For this function to actually start logging events to a file, make sure QUEST.traceAndLog is set to true, first.
     * You can change the name of the log file by changing the value of QUEST.traceAndLogFileName
     * @param {string} msg
     */
    static TraceLogger(msg) {
        if (this.traceAndLog) {
            try FileAppend("[" . A_Now . "." . A_MSec . "] [PID " . ProcessExist() . "] " . msg . "`n", A_ScriptDir . "\" . this.traceAndLogFileName)
        }
    }
}