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

; Parameters
global smoothTrackballScrollingShortcut := ""
global sensitivity := ""
global smoothingWindowMaxSize := ""
global invertDirection := ""
global refreshInterval := ""

global snapOn := ""
global alwaysSnap := ""
global snapThreshold := ""
global snapRatio := ""

global addCtrl := ""
global addShift := ""
global addAlt := ""

; Mouse hook pointer
global hHook := 0

; State variables - basic functionality
global active := 0
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
global wheelModifiers := 0
global accumulatorWheel := 0

; =============================================================================
; GUI AND SETUP
; =============================================================================

Init:
    GOSUB InitializeSettings
    GOSUB UpdateDynamicHotKeys
    GOSUB InitializeHook
    SmoothingWindowsInit()
return

InitializeSettings:

    ; Read settings from registry
    Menu Tray, NoStandard
    Menu Tray, Add, Settings
    Menu Tray, Add, Run on startup, RunOnStartup
    Menu Tray, Standard
    RegRead, smoothTrackballScrollingShortcut, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothTrackballScrollingShortcut
    RegRead, sensitivity, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, sensitivity
    RegRead, smoothingWindowMaxSize, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, smoothingWindowMaxSize
    RegRead, invertDirection, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, invertDirection
    RegRead, refreshInterval, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling, refreshInterval
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
    If (sensitivity = "")
        sensitivity := 4
    If (smoothingWindowMaxSize = "")
        smoothingWindowMaxSize := 6
    If (invertDirection = "")
        invertDirection := false
    If (refreshInterval = "")
        refreshInterval := 10
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

    ; Initialize wheelModifiers
    GOSUB UpdateModifiers

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

UpdateDynamicHotKeys:
    Hotkey, %smoothTrackballScrollingShortcut%, HotkeyOn
    Hotkey, *%smoothTrackballScrollingShortcut% Up, HotkeyOff
return

UpdateModifiers:
    wheelModifiers := 0
    If addCtrl = 1
        wheelModifiers += 0x08
    If addShift = 1
        wheelModifiers += 0x04
    If addAlt = 1
        wheelModifiers += 0x20
return

Settings:
    Gui New, -Resize, Settings
    Gui Show, W220 H500

    Gui, Add, Text,, Hotkey:
    GUI, Add, Edit, vGuiSmoothTrackballScrollingShortcut
    GuiControl,,GuiSmoothTrackballScrollingShortcut, %smoothTrackballScrollingShortcut%

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
    GOSUB UpdateDynamicHotKeys

    ; Update wheelModifiers
    GOSUB UpdateModifiers
    
return

; =============================================================================
; SET UP THE MOUSE HOOK
; =============================================================================

; Create a mouse movement hook
InitializeHook:
    ; WH_MOUSE_LL is 14
    hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", RegisterCallback("MouseProc"), "ptr", 0, "uint", 0)
return

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
    If (active = 0) {
        active := 1
        accumulatorX := 0
        accumulatorY := 0
        accumulatorWheel := 0
        snapState := 0
        snapDeviation := 0.0
        SmoothingWindowsReset()
        MouseGetPos , cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse
        SetTimer TimerScroll, %refreshInterval%
        SetTimer TimerWheel, 10
    }
return

HotkeyOff:
    If (active = 1) {
        active := 0
        SetTimer TimerScroll, Off
        SetTimer TimerWheel, Off
    }
return

MouseProc(nCode, wParam, lParam) {

    ; Extract part of MSLLHOOKSTRUCT from lParam
    ; More specifically, extract pt (8 bytes) and mouseData (4 bytes)
    VarSetCapacity(msll, 24, 0) ; MSLLHOOKSTRUCT is 24 bytes in size
    DllCall("RtlMoveMemory", "ptr", &msll, "ptr", lParam, "ptr", 12)

    ; Return early if user isn't pressing the hotkey
    If (not GetKeyState(smoothTrackballScrollingShortcut, "P"))  {

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
    PostWheelVertical(accumulatorWheel, wheelModifiers, cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse)
    accumulatorWheel := 0
return

TimerScroll:

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
    } If (smoothingWindowCurrentSize < smoothingWindowMaxSize) {
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