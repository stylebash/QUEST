/** OutputDebug Overload
 * Version 1.0
 * Overloads native OutputDebug function.
 * Accepts all data types and any number of arguments unlike the vanilla function.
 * 
 * Author: stylebash
 * Contact: https://github.com/stylebash
*/

; Suppress that damn MessageBox
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off

OnError(GlobalErrorHandler)

GlobalErrorHandler(err, mode) {
    RawOut("[Runtime Error]: " . err.Message . " `n(Line " . err.Line . " in " . err.File . ")")
    return 1
}

global null := { ToString: (self) => "<Null>" }
MAX_STRINGIFY_DEPTH := 10
FORMAT_TYPES := [
    "bare", ; yes, you can type all of it in one hand. You're welcome.
    "typed"
]

/**
 * The only function we need to call out of this file.
 *
 * @override and @overload Native OutputDebug(Text)
 * @param {...Any} args - One or more values, objects, or arrays to output.
 * @returns {Void}
 * 
 * @remarks
 * - Multiple arguments are separated by a new line in the output debug stream.
 * - calling the function multiple times delineates each call by a blank line.
 *
 * @example
 * OutputDebug 'name', 32, true, [1, 2, 3]
 * output:
 * [String]: "name"
 * [Integer]: 32
 * [Integer]: 1
 * [Array]: [1, 2, 3]
 * 
 * OutputDebug(true)                ; output: [Integer]: 1
 * OutputDebug [1, 2, 3]            ; output: [Array]: [1, 2, 3]
 * OutputDebug [1, 2, 3], 'typed'   ; output: [Array]: [1, 2, 3] ; 'typed' is the default format argument
 * OutputDebug [1, 2, 3], 'bare'    ; output: [1, 2, 3] ; "[Array]: " is ommitted. We're only showing the raw data in the Debug Console
 * OutputDebug 'name', 32, true, [1, 2, 3], ':custom print label'
 * output:
 * [custom print label] (String): "name"
 * [custom print label] (Integer): 32
 * [custom print label] (Integer): 1
 * [custom print label] (Array): [1, 2, 3]
 *
 */
OutputDebug(args*) {
    static isBusy := false
    
    if isBusy
        return

    isBusy := true
    try {
        if args.Length == 0 {
            RawOut("[OutputDebug] <No Arguments Passed>")
            return
        }

        formatType := FORMAT_TYPES[2]
        maxIdx := args.Length

        formatType := WereDoingCustomLabels(args, maxIdx, formatType, 'formatType')
        maxIdx := WereDoingCustomLabels(args, maxIdx, formatType, 'maxIdx')

        outStr := outStrFormat(formatType, args, maxIdx)
        
        RawOut(outStr)
    } catch Error as err {
        RawOut("[OutputDebug Error] " . err.Message)
    } finally {
        isBusy := false
    }
}

outStrFormat(formatType, args, maxIdx) {
    outStr := ""
    Loop maxIdx {
        if A_Index > 1
            outStr .= "`n"
        
        if args.Has(A_Index)
            outStr .= FormatValue(args[A_Index], formatType)
        else
            outStr .= "<Unset>"
    }

    return outStr
}

WereDoingCustomLabels(args, maxIdx, formatType, returningData) {
    if args.Length > 1 && args.Has(maxIdx) && Type(args[maxIdx]) == "String" {
        lastArg := args[maxIdx]
        if ArrContains(lastArg, FORMAT_TYPES) || SubStr(lastArg, 1, 1) == ":" {
            formatType := Trim(lastArg, ":")
            maxIdx--
        }
    }

    switch returningData {
        case 'formatType':
            return formatType
        case 'maxIdx': 
            return maxIdx
    }
}

/**
 * Checks if lookForThis exists in the array.
 * Why something like this doesn't exist in AHK is beyond me.
 * @param {Any} lookForThis as long as it's not an (object) data type
 * @param {array} arr one dimensional array
 * @returns {Boolean} but more line an integer in AHK.
 */
ArrContains(lookForThis, arr) {
    for v in arr
        if v == lookForThis
            return true
    return false
}

GetNullMessage() {
    appendMessage := "`n; Warning: null is not a reserved word in AHK. "
    ; additionalMessage := "Use something else to represent this data."
    ; additionalMessage := "Use synonymous data to represent null instead."
    ; additionalMessage := "Use a synonym for null instead."
    ; additionalMessage := "Use an empty data representation in place of null instead."
    ; additionalMessage := "Use an empty data representation of prompt type in place of null instead."
    additionalMessage := "Use a prompt empty data representation of any type in place of null instead."
    return appendMessage . additionalMessage
}

/**
 * Final stringified format output we'll see in the Debug Console.
 * @param {Any} val 
 * @param {String} formatType 
 */
FormatValue(val, formatType := FORMAT_TYPES[2]) {
    strVal := Stringify(val)

    switch formatType {
        case FORMAT_TYPES[1]:
            if (val == null)
                strVal := "<Null>" . GetNullMessage()
        
        case FORMAT_TYPES[2]:
            strVal := "[" . Type(val) . "]: " . strVal
            if (val == null)
                strVal := "[Null]: <Null>" . GetNullMessage()
        
        default:
            if (val == null)
                strVal := "[" . formatType . "] (" . Type(val) . "): " . strVal . GetNullMessage()
            else
                strVal := "[" . formatType . "] (" . Type(val) . "): " . strVal
    }

    return strVal
}

/**
 * Contains the blackbox magic sauce.
 * It's why this only works on windows.
 * @param str 
 */
RawOut(str) {
    cleanStr := RTrim(String(str), "`r`n") . "`n"
    
    try {
        FileAppend(cleanStr, "*", "UTF-8")
    } catch {
        DllCall("kernel32\OutputDebugStringW", "WStr", cleanStr)
    }
}

/**
 * ♬♫ ♪ And iiiiiiiiiiiii'll make a striiiiiiiiiiiiiiiiing... Out of youuuuuuuuuuuuuuuuuuuuuuuu ♪♫ ♩
 * @param val 
 * @param depth 
 */
Stringify(val, depth := 0) {
    global MAX_STRINGIFY_DEPTH

    if (val == null)
        return "<Null>"

    if !IsObject(val)
        return Type(val) == "String" ? '"' val '"' : String(val)

    if depth >= MAX_STRINGIFY_DEPTH
        return "<" . Type(val) . " MaxDepthExceeded>"

    try {
        if val is Array {
            out := "["
            for i, item in val
                out .= (i > 1 ? ", " : "") . (IsSet(item) ? Stringify(item, depth + 1) : "<Unset>")
            return out . "]"
        }
        
        if val is Map {
            out := "Map("
            i := 0
            for k, v in val
                out .= (i++ ? ", " : "") . Stringify(k, depth + 1) . ": " . Stringify(v, depth + 1)
            return out . ")"
        }

        if val is Class
            return "<Class>"

        propNames := []
        try {
            enum := Object.prototype.OwnProps.Call(val)
            while enum(&k) {
                propNames.Push(k)
            }
        } catch {
            return "<" . Type(val) . ">"
        }

        out := "{"
        i := 0
        for k in propNames {
            try {
                desc := Object.prototype.GetOwnPropDesc.Call(val, k)
                
                if Object.prototype.HasOwnProp.Call(desc, "get") || Object.prototype.HasOwnProp.Call(desc, "set") {
                    out .= (i++ ? ", " : "") . k . ": <Getter/Setter>"
                    continue
                }
                if Object.prototype.HasOwnProp.Call(desc, "call") {
                    out .= (i++ ? ", " : "") . k . ": <Method>"
                    continue
                }

                v := desc.value
                out .= (i++ ? ", " : "") . k . ": " . Stringify(v, depth + 1)
            } catch {
                out .= (i++ ? ", " : "") . k . ": <Unreadable>"
            }
        }
        return out . "}"
    } catch {
        return "<" . Type(val) . ">"
    }
}