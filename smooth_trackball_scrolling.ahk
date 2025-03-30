; =============================================================================
; BOILERPLATE
; =============================================================================

#Persistent
#SingleInstance Force

SetTitleMatchMode RegEx
CoordMode, Mouse, Screen

; =============================================================================
; GLOBAL VARS
; =============================================================================

; Parameters - basic functionality
global smoothTrackballScrollingShortcut := ""
global smoothTrackballScrollingShortcut2 := ""
global sensitivity := ""
global smoothingWindowMaxSize := ""
global invertDirection := ""
global refreshInterval := ""

; Parameters - activating/deactivating scrolling
global mode := ""
global holdDuration := ""

; Parameters - angle snapping
global snapOn := ""
global alwaysSnap := ""
global snapThreshold := ""
global snapRatio := ""

; Parameters - scroll wheel modifiers
global addCtrl := ""
global addShift := ""
global addAlt := ""

; Mouse hook pointer
global hHook := 0

; State variables - activating/deactivating scrolling
global active := 0
global fsmState := 0  
; fsmState is only used for 2 key MO modes
; 0: base state
; 1: hotkey 1 down (unsure if tap, hold, or smooth scrolling)
; 2: hotkey 2 down (unsure if tap, hold, or smooth scrolling)
; 3: symmetric mode only, hotkey 1 held
; 4: hotkey 2 held
; 5: smooth scrolling
; 6: hotkey 1 down after smooth scrolling was active
; 7: hotkey 2 down after smooth scrolling was active
; 8: asymmetric mode only, both hotkeys held
; 9: asymmetric mode only, hotkey 2 held
global tapDetected := 0
; tapDetected is only used for 1 key LT mode
; 0: base state
; 1: hotkey 1 down (unsure if tap or smooth scrolling)
; 2: smooth scrolling

; State variables - basic functionality
global windowUnderMouse := 0
global cursorX := 0
global cursorY := 0
global cursorXMouseGetPos := 0
global cursorYMouseGetPos := 0
global accumulatorX := 0
global accumulatorY := 0

; State variables - angle snapping
global snapState := 0
global snapDeviation := 0.0

; State variables - smoothing windows
global smoothingWindowX := []
global smoothingWindowY := []
global smoothingWindowNextIndex := 0
global smoothingWindowCurrentSize := 0

; State variables - scroll wheel modifiers
global accumulatorWheel := 0

; State variables - ugly quick fix to prevent modifiers from interfering
; global sendModifiers := 0

; =============================================================================
; GUI AND SETUP
; =============================================================================

Init:
    GOSUB InitializeSettings
    InitializeHook()
    RemoveDynamicHotkeys()
    UpdateDynamicHotKeys()
    SmoothingWindowsInit()
return

InitializeSettings:

    ; Read settings from registry
    Menu Tray, NoStandard
    Menu Tray, Add, Settings
    Menu Tray, Add, Run on startup, RunOnStartup
    Menu Tray, Standard
    RegRead, smoothTrackballScrollingShortcut, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothTrackballScrollingShortcut
    RegRead, smoothTrackballScrollingShortcut2, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothTrackballScrollingShortcut2
    RegRead, sensitivity, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, sensitivity
    RegRead, smoothingWindowMaxSize, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothingWindowMaxSize
    RegRead, invertDirection, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, invertDirection
    RegRead, refreshInterval, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, refreshInterval
    RegRead, mode, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, mode
    RegRead, holdDuration, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, holdDuration
    RegRead, snapOn, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, snapOn
    RegRead, alwaysSnap, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, alwaysSnap
    RegRead, snapThreshold, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, snapThreshold
    RegRead, snapRatio, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, snapRatio
    RegRead, addCtrl, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, addCtrl
    RegRead, addShift, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, addShift
    RegRead, addAlt, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, addAlt
    RegRead, runOnStartup, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Smooth Trackball Scrolling

    ; Default values
    If (smoothTrackballScrollingShortcut = "")
        smoothTrackballScrollingShortcut := "F1"
    If (smoothTrackballScrollingShortcut2 = "")
        smoothTrackballScrollingShortcut2 := ""
    If (sensitivity = "")
        sensitivity := 4
    If (smoothingWindowMaxSize = "")
        smoothingWindowMaxSize := 6
    If (invertDirection = "")
        invertDirection := false
    If (refreshInterval = "")
        refreshInterval := 10
    If (mode = "")
        mode := "MO (1 key)"
    If (holdDuration = "")
        holdDuration := 500
    If (snapOn = "")
        snapOn := 1
    If (alwaysSnap = "")
        alwaysSnap := 1
    If (snapThreshold = "")
        snapThreshold := 10
    If (snapRatio = "")
        snapRatio := 1.5
    If (addCtrl = "")
        addCtrl := 1
    If (addShift = "")
        addShift := 0
    If (addAlt = "")
        addAlt := 0

    ; Run on startup stuff
    If (runOnStartup = "") {
        runOnStartup := false
    } Else {
        runOnStartup := true
        Menu Tray, Check, Run on startup
        RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Smooth Trackball Scrolling, %A_ScriptFullPath%
    }

return

RunOnStartup:
    If (runOnStartup) {
        Menu %A_ThisMenu%, UnCheck, %A_ThisMenuItem%
        runOnStartup := false
        RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Smooth Trackball Scrolling
    } Else {
        Menu %A_ThisMenu%, Check, %A_ThisMenuItem%
        runOnStartup := true
        RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Smooth Trackball Scrolling, %A_ScriptFullPath%
    }
return

RemoveDynamicHotkeys() {
    Try {
        Hotkey, %smoothTrackballScrollingShortcut%, Off
    }
    Try {
        Hotkey, *%smoothTrackballScrollingShortcut% Up, Off
    }
    Try {
        Hotkey, %smoothTrackballScrollingShortcut2%, Off
    }
    Try {
        Hotkey, *%smoothTrackballScrollingShortcut2% Up, Off
    }
    return
}

UpdateDynamicHotKeys() {
    Hotkey, %smoothTrackballScrollingShortcut%, HotkeyOn
    Hotkey, *%smoothTrackballScrollingShortcut% Up, HotkeyOff
    Hotkey, %smoothTrackballScrollingShortcut%, On
    Hotkey, *%smoothTrackballScrollingShortcut% Up, On
    If (mode = "MO (2 key sym.)" or mode = "MO (2 key asym.)" or mode = "TG (2 key asym.)") {
        Hotkey, %smoothTrackballScrollingShortcut2%, Hotkey2On
        Hotkey, *%smoothTrackballScrollingShortcut2% Up, Hotkey2Off
        Hotkey, %smoothTrackballScrollingShortcut2%, On
        Hotkey, *%smoothTrackballScrollingShortcut2% Up, On
    }
    return
}

Settings:

    RemoveDynamicHotkeys()

    Gui New, -Resize, Settings
    Gui Show, W300 H690

    Gui, Add, Text,, Hotkey 1:
    GUI, Add, Edit, vGuiSmoothTrackballScrollingShortcut
    GuiControl,,GuiSmoothTrackballScrollingShortcut, %smoothTrackballScrollingShortcut%

    Gui, Add, Text,, Hotkey 2:
    GUI, Add, Edit, vGuiSmoothTrackballScrollingShortcut2
    GuiControl,,GuiSmoothTrackballScrollingShortcut2, %smoothTrackballScrollingShortcut2%

    If (mode = "MO (1 key)") {
        modeNum := 1
    } Else If (mode = "TG (1 key)") {
        modeNum := 2
    } Else If (mode = "MO (2 key sym.)") {
        modeNum := 3
    } Else If (mode = "MO (2 key asym.)") {
        modeNum := 4
    } Else If (mode = "TG (2 key asym.)") {
        modeNum := 5
    } Else If (mode = "LT (1 key)") {
        modeNum := 6
    } Else {
        modeNum := 0
    }
    Gui, Add, Text,, Hotkey Mode:
    Gui, Add, DropDownList, vGuiMode Choose%modeNum%, MO (1 key)|TG (1 key)|MO (2 key sym.)|MO (2 key asym.)|TG (2 key asym.) |LT (1 key)

    Gui, Add, Text,, Hold Duration:
    Gui, Add, Edit, vGuiHoldDurationEdit
    Gui, Add, UpDown, vGuiHoldDuration Range10-999999, %holdDuration%

    Gui, Add, Text,,  ; spacer

    Gui, Add, Text,, Refresh Interval:
    Gui, Add, Edit, vGuiRefreshIntervalEdit
    Gui, Add, UpDown, vGuiRefreshInterval Range10-1000, %refreshInterval%

    Gui, Add, Text,, Smoothing Window Size:
    Gui, Add, Edit, vGuiSmoothingWindowSizeEdit
    Gui, Add, UpDown, vGuiSmoothingWindowSize Range1-100, %smoothingWindowMaxSize%

    Gui, Add, Text,, Sensitivity:
    Gui, Add, Edit, vGuiSensitivityEdit
    Gui, Add, UpDown, vGuiSensitivity Range1-50, %sensitivity%

    Gui, Add, Checkbox, vGuiInvertDirection, Invert Direction
    GuiControl,,GuiInvertDirection, %invertDirection%

    Gui, Add, Text,,  ; spacer

    Gui, Add, Text,, Angle Snapping Threshold:
    Gui, Add, Edit, vGuiSnapThreshold
    GuiControl,,GuiSnapThreshold, %snapThreshold%

    Gui, Add, Text,, Angle Snapping Ratio:
    Gui, Add, Edit, vGuiSnapRatio
    GuiControl,,GuiSnapRatio, %snapRatio%

    Gui, Add, Checkbox, vGuiSnapOn, Angle Snapping On
    GuiControl,,GuiSnapOn, %snapOn%

    Gui, Add, Checkbox, vGuiAlwaysSnap, Always Angle Snap
    GuiControl,,GuiAlwaysSnap, %alwaysSnap%
    
    Gui, Add, Text,,  ; spacer

    Gui, Add, Text,, While scrolling with wheel:

    Gui, Add, Checkbox, vGuiAddCtrl, Emulate Ctrl
    GuiControl,,GuiAddCtrl, %addCtrl%

    Gui, Add, Checkbox, vGuiAddShift, Emulate Shift
    GuiControl,,GuiAddShift, %addShift%

    Gui, Add, Checkbox, vGuiAddAlt, Emulate Alt
    GuiControl,,GuiAddAlt, %addAlt%

    Gui, Add, Text,,  ; spacer

    Gui, Add, Button, Default, Save Settings

return

ButtonSaveSettings:

    ; Get settings from GUI
    GuiControlGet, smoothTrackballScrollingShortcut,, GuiSmoothTrackballScrollingShortcut
    GuiControlGet, smoothTrackballScrollingShortcut2,, GuiSmoothTrackballScrollingShortcut2
    GuiControlGet, mode,, GuiMode
    GuiControlGet, holdDuration,, GuiHoldDuration
    GuiControlGet, sensitivity,, GuiSensitivity
    GuiControlGet, invertDirection,, GuiInvertDirection
    GuiControlGet, refreshInterval,, GuiRefreshInterval
    GuiControlGet, smoothingWindowMaxSize,, GuiSmoothingWindowSize
    GuiControlGet, snapThreshold,, GuiSnapThreshold
    GuiControlGet, snapRatio,, GuiSnapRatio
    GuiControlGet, snapOn,, GuiSnapOn
    GuiControlGet, alwaysSnap,, GuiAlwaysSnap
    GuiControlGet, addCtrl,, GuiAddCtrl
    GuiControlGet, addShift,, GuiAddShift
    GuiControlGet, addAlt,, GuiAddAlt
    Gui Hide

    ; Save settings to registry
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothTrackballScrollingShortcut, %smoothTrackballScrollingShortcut%
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothTrackballScrollingShortcut2, %smoothTrackballScrollingShortcut2%
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, mode, %mode%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, holdDuration, %holdDuration%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, sensitivity, %sensitivity%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, refreshInterval, %refreshInterval%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, invertDirection, %invertDirection%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothingWindowMaxSize, %smoothingWindowMaxSize%
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, snapThreshold, %snapThreshold%
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, snapRatio, %snapRatio%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, snapOn, %snapOn%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, alwaysSnap, %alwaysSnap%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, addCtrl, %addCtrl%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, addShift, %addShift%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, addAlt, %addAlt%

    ; Update hotkeys
    UpdateDynamicHotKeys()
    
return

; =============================================================================
; SET UP THE MOUSE HOOK
; =============================================================================

; Create a mouse movement hook
InitializeHook() {
    ; WH_MOUSE_LL is 14
    hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", RegisterCallback("MouseProc"), "ptr", 0, "uint", 0)
    return
}

; Message pump to continually process mouse movement messages
While, hHook and DllCall("GetMessage", "ptr", 0, "ptr", 0, "uint", 0, "uint", 0) {
    continue
}

; Clean up the mouse hook on exit
OnExit, Unhook
Return

Unhook:
If (hHook != 0) {
    DllCall("UnhookWindowsHookEx", "ptr", hHook)
}
ExitApp

; =============================================================================
; HOTKEY LOGIC
; =============================================================================

HotkeyOn:
    If (mode = "MO (1 key)") {
        If (active = 0) {
            ScrollingActivate()
        }
    } Else If (mode = "TG (1 key)") {
        If (active = 0) {
            ScrollingActivate()
        } Else {
            ScrollingDeactivate()
        }
    } Else If (mode = "MO (2 key sym.)") {
        If (fsmState = 0) {
            fsmState := 1
            SetTimer, TimerHold, -%holdDuration%
        } Else If (fsmState = 2) {
            fsmState := 5
            if (active = 0) {
                ScrollingActivate()
            }
        }
    } Else If (mode = "MO (2 key asym.)") {
        If (fsmState = 0) {
            fsmState := 1
            Send, {%smoothTrackballScrollingShortcut% down}
        } Else If (fsmState = 2) {
            fsmState := 5
            if (active = 0) {
                ScrollingActivate()
            }
        } Else If (fsmState = 9) { 
            fsmState := 8
            Send, {%smoothTrackballScrollingShortcut% down}
        }
    } Else If (mode = "TG (2 key asym.)") {
        If (active = 0) {
            ScrollingActivate()
        }
    } Else If (mode = "LT (1 key)") {
        If (tapDetected = 0) {
            tapDetected := 1
            SetTimer, TimerTap, -%holdDuration%
        }
    }
return

HotkeyOff:
    If (mode = "MO (1 key)") {
        If (active = 1) {
            ScrollingDeactivate()
        }
    } Else If (mode = "MO (2 key sym.)") {
        If (fsmState = 1) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut%}
        } Else If (fsmState = 3) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut% up}
        } Else If (fsmState = 5) {
            fsmState := 7
            If (active = 1) {
                ScrollingDeactivate()
            }
        } Else If (fsmState = 6) {
            fsmState := 0
        }
    } Else If (mode = "MO (2 key asym.)") {
        If (fsmState = 1) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut% up}
        } Else If (fsmState = 5) {
            fsmState := 7
            If (active = 1) {
                ScrollingDeactivate()
            }
        } Else If (fsmState = 6) {
            fsmState := 0
        } Else If (fsmState = 8) {
            fsmState := 9
            Send {%smoothTrackballScrollingShortcut% up}
        }
    } Else If (mode = "LT (1 key)") {
        If (tapDetected = 1) {
            tapDetected := 0
            Send {%smoothTrackballScrollingShortcut%}
        } Else If (tapDetected = 2) {
            tapDetected := 0
                If (active = 1) {
                    ScrollingDeactivate()
            }
        }
    }
return

Hotkey2On:
    If (mode = "MO (2 key sym.)") {
        If (fsmState = 0) {
            fsmState := 2
            SetTimer, TimerHold, -%holdDuration%
        } Else If (fsmState = 1) {
            fsmState := 5
            if (active = 0) {
                ScrollingActivate()
            }
        }
    } Else If (mode = "MO (2 key asym.)") {
        If (fsmState = 0) {
            fsmState := 2
            SetTimer, TimerHold, -%holdDuration%
        } Else If (fsmState = 1) {
            fsmState := 8
            Send {%smoothTrackballScrollingShortcut2% down}
        }
    } Else If (mode = "TG (2 key asym.)") {
        If (active = 1) {
            ScrollingDeactivate()
        }
    }
return

Hotkey2Off:
    If (mode = "MO (2 key sym.)") {
        If (fsmState = 2) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut2%}
        } Else If (fsmState = 4) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut2% up}
        } Else If (fsmState = 5) {
            fsmState := 6
            If (active = 1) {
                ScrollingDeactivate()
            }
        } Else If (fsmState = 7) {
            fsmState := 0
        }
    } Else If (mode = "MO (2 key asym.)") {
        If (fsmState = 2) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut2%}
        } Else If (fsmState = 4) {
            fsmState := 0
            Send {%smoothTrackballScrollingShortcut2% up}
        } Else If (fsmState = 5) {
            fsmState := 6
            If (active = 1) {
                ScrollingDeactivate()
            }
        } Else If (fsmState = 7) {
            fsmState := 0
        } Else If (fsmState = 8) {
            fsmState := 1
            Send {%smoothTrackballScrollingShortcut2% up}
        } Else If (fsmState = 9) { 
            fsmState := 0
            Send, {%smoothTrackballScrollingShortcut2% up}
        }
    }
return

ScrollingActivate() {
    active := 1
    accumulatorX := 0
    accumulatorY := 0
    accumulatorWheel := 0
    snapState := 0
    snapDeviation := 0.0
    SmoothingWindowsReset()
    MouseGetPos , cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse
    SetTimer TimerScroll, %refreshInterval%
    SetTimer TimerWheel, %refreshInterval%
    ; sendModifiers := 1
}

ScrollingDeactivate() {
    active := 0
    SetTimer TimerScroll, Off
    SetTimer TimerWheel, Off
    ; sendModifiers := 1
}

TimerHold:
    ; This subroutine will run once after holdDuration
    ; If the user is still holding only a single hotkey at that point, assume the user wants to send a hold for that key
    If (fsmState = 1) {
        fsmState := 3
        Send {%smoothTrackballScrollingShortcut% down}
    } Else If (fsmState = 2) {
        fsmState := 4
        Send {%smoothTrackballScrollingShortcut2% down}
    }
return

TimerTap:
    ; Check if the key has been pressed and the timer has expired
    If (tapDetected = 1) {
        ; Change the state of tapDetected to indicate a long press has been detected
        tapDetected := 2
        ; Activate smooth scrolling
        ScrollingActivate()
    }
return

MouseProc(nCode, wParam, lParam) {

    ; Extract part of MSLLHOOKSTRUCT from lParam
    ; More specifically, extract pt (8 bytes) and mouseData (4 bytes)
    VarSetCapacity(msll, 24, 0) ; MSLLHOOKSTRUCT is 24 bytes in size
    DllCall("RtlMoveMemory", "ptr", &msll, "ptr", lParam, "ptr", 12)

    ; Return early if user isn't pressing the hotkey
    If (not active)  {

        ; Extract the mouse coordinates from the MSLLHOOKSTRUCT
        messageX := NumGet(msll, 0, "Int")
        messageY := NumGet(msll, 4, "Int")

        ; Store cursor position for later
        ; We could do this lazily when the hotkey gets pressed
        ; But this is more responsive and fixes some weird edge case glitches
        cursorX := messageX
        cursorY := messageY

        ; Allow cursor movement by calling next hook
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "uint", wParam, "ptr", lParam)
    }

    ; Handle mouse wheel movements
    If (wParam = 0x20A) {

        ; Extract the wheel movement from the MSLLHOOKSTRUCT (the lower order word isn't used)
        wheelDelta := NumGet(msll, 8, "UInt") >> 16

        ; Discard lower order word and convert back to a signed integer
        If (wheelDelta & 0x8000) {
            wheelDelta := -(0x10000 - wheelDelta)
        }

        ; Add wheel delta to accumulator
        accumulatorWheel += wheelDelta

        ; Block scroll wheel movement
        return 1
    
    ; Handle mouse cursor movements
    } Else {

        ; Extract the mouse coordinates from the MSLLHOOKSTRUCT
        messageX := NumGet(msll, 0, "Int")
        messageY := NumGet(msll, 4, "Int")

        ; Calculate mouse movements
        deltaX := messageX - cursorX
        deltaY := messageY - cursorY

        ; Calculate scrolling magnitudes
        scrollX := deltaX * sensitivity
        scrollY := deltaY * sensitivity * -1
        if (invertDirection) {
            scrollX := scrollX * -1
            scrollY := scrollY * -1
        }

        ; Add scrolling magnitudes to accumulators
        accumulatorX := accumulatorX + scrollX
        accumulatorY := accumulatorY + scrollY

        ; Block user's cursor movement
        return 1
    }
}

TimerWheel:
    If (accumulatorWheel = 0) {
        return
    }
    wheelModifiers := 0
    If (addCtrl = 1 ^ GetKeyState("Ctrl", "P"))
        wheelModifiers += 0x08
    If (addShift = 1 ^ GetKeyState("Shift", "P")) 
        wheelModifiers += 0x04
    If (addAlt = 1 ^ GetKeyState("Alt", "P"))
        wheelModifiers += 0x20
    PostWheelVertical(accumulatorWheel, wheelModifiers, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
    accumulatorWheel := 0
return

TimerScroll:

    ; Ugly quick fix to prevent modifiers from interfering
    ; If (sendModifiers = 1) {
    ;     SendInput, {Ctrl UP}
    ;     SendInput, {Shift UP}
    ;     SendInput, {Alt UP}
    ;     sendModifiers := 0
    ; }

    ; Apply smoothing window
    SmoothingWindowsPush(accumulatorX, accumulatorY)
    smoothedX := SmoothingWindowsGetMeanX()
    smoothedY := SmoothingWindowsGetMeanY()

    ; Reset accumulators
    accumulatorX := 0
    accumulatorY := 0

    ; Post wheel movements based on snap logic

    If (snapOn = 0 or snapState = 3) {
        ; Snapping is off
        If (smoothedX != 0) {
            PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
        }
        If (smoothedY != 0) {
            PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
        }

    } Else If (snapState = 1) {
        ; X axis snap
        snapDeviation := snapDeviation + smoothedY
        If (snapDeviation > 0) {
            snapDeviation := Max(0, snapDeviation - Abs(smoothedX) * snapRatio)
        } Else If (snapDeviation < 0) {
            snapDeviation := Min(0, snapDeviation + Abs(smoothedX) * snapRatio)
        }
        If (Abs(snapDeviation) > snapThreshold) {
            If (alwaysSnap = 1) {
                ; Switch to Y axis snap
                PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
                snapState := 2
                snapDeviation := 0.0
                SmoothingWindowsReset()
            } Else {
                ; Switch to no snap
                PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
                PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
                snapState := 3
                snapDeviation := 0
                SmoothingWindowsReset()
            }
        } Else {
            PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
        }


    } Else If (snapState = 2) {
        ; Y axis snap
        snapDeviation := snapDeviation + smoothedX
        If (snapDeviation > 0) {
            snapDeviation := Max(0, snapDeviation - Abs(smoothedY) * snapRatio)
        } Else If (snapDeviation < 0) {
            snapDeviation := Min(0, snapDeviation + Abs(smoothedY) * snapRatio)
        }
        If (Abs(snapDeviation) > snapThreshold) {
            If (alwaysSnap = 1) {
                ; Switch to X axis snap
                PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
                snapState := 1
                snapDeviation := 0.0
                SmoothingWindowsReset()
            } Else {
                ; Switch to no snap
                PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
                PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
                snapState := 3
                snapDeviation := 0
                SmoothingWindowsReset()
            }
        } Else {
            PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
        }

    } Else {
        ; Snap direction not determined yet
        If (smoothedX = 0 and smoothedY = 0) {
        } Else If (Abs(smoothedX) = Abs(smoothedY)) {
            PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
            PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
        } Else If (Abs(smoothedX) > Abs(smoothedY)) {
            ; Switch to X axis snap
            PostWheelHorizontal(smoothedX, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
            snapState := 1
        } Else {
            ; Switch to Y axis snap
            PostWheelVertical(smoothedY, 0x0, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
            snapState := 2
        }
    }

return

SmoothingWindowsInit() {
    smoothingWindowX := []
    smoothingWindowY := []
    smoothingWindowNextIndex := 1
    smoothingWindowCurrentSize := 0
    Loop %smoothingWindowMaxSize% {
        smoothingWindowX.Push(0)
        smoothingWindowY.Push(0)
    }
}

SmoothingWindowsReset() {
    smoothingWindowNextIndex := 1
    smoothingWindowCurrentSize := 0
}

SmoothingWindowsPush(x, y) {
    ; Update circular array
    smoothingWindowX[smoothingWindowNextIndex] := x
    smoothingWindowY[smoothingWindowNextIndex] := y
    If (smoothingWindowNextIndex = smoothingWindowMaxSize) {
        smoothingWindowNextIndex := 1
    } Else {
        smoothingWindowNextIndex := smoothingWindowNextIndex + 1
    } 
    If (smoothingWindowCurrentSize < smoothingWindowMaxSize) {
        smoothingWindowCurrentSize := smoothingWindowCurrentSize + 1
    }
}

SmoothingWindowsGetMeanX() {
    If (smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop %smoothingWindowCurrentSize% {
        mean := mean + smoothingWindowX[A_Index]
    }
    mean := mean / smoothingWindowCurrentSize
    return mean
}

SmoothingWindowsGetMeanY() {
    If (smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop %smoothingWindowCurrentSize% {
        mean := mean + smoothingWindowY[A_Index]
    }
    mean := mean / smoothingWindowCurrentSize
    return mean
}

PostWheelVertical(delta, modifiers, x, y, targetWindow) {
    ; CoordMode, Mouse, Screen
    lowOrderX := x & 0xFFFF
    highOrderY := y & 0xFFFF
    ; Windows message magic, 0x20A is WM_MOUSEWHEEL
    PostMessage, 0x20A, Round(delta) << 16 | modifiers, highOrderY << 16 | lowOrderX ,, ahk_id %targetWindow%
    ; ToolTip, %xPos% %yPos% %windowUnderMouse% %delta%
}

PostWheelHorizontal(delta, modifiers, x, y, targetWindow) {
    ; CoordMode, Mouse, Screen
    lowOrderX := x & 0xFFFF
    highOrderY := y & 0xFFFF
    ; Windows message magic, 0x20E is WM_MOUSEHWHEEL
    PostMessage, 0x20E, Round(delta) << 16 | modifiers, highOrderY << 16 | lowOrderX ,, ahk_id %targetWindow%
}
