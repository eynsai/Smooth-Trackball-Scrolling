#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
CoordMode("Mouse", "Screen")
OnExit RemoveMouseHook

; =============================================================================
; PUBLIC INTERFACE FUNCTIONS
; =============================================================================

; Check if smooth scrolling is active.
IsSmoothScrollingActive() {
    return active
}

; Check if angle snapping is on.
IsAngleSnapOn() {
    return snapOn
}

; Freeze the cursor and begin generating scroll inputs.
ScrollingActivate() {
    global active := 1
    global accumulatorX := 0
    global accumulatorY := 0
    global accumulatorWheel := 0
    global remainderX := 0
    global remainderY := 0
    global snapState := 0
    global snapDeviation := 0.0
    global cursorXMouseGetPos, cursorYMouseGetPos, windowUnderMouse, controlUnderMouse
    MouseGetPos(&cursorXMouseGetPos, &cursorYMouseGetPos, &windowUnderMouse, &controlUnderMouse, 3)
    SmoothingWindowsReset()
    SetTimer(TimerScroll, refreshInterval)
    SetTimer(TimerWheel, refreshInterval)
}

; Unfreeze the cursor and stop generating scroll inputs.
ScrollingDeactivate() {
    global active := 0
    SetTimer(TimerScroll, 0)
    SetTimer(TimerWheel, 0) 
}

; Turn angle snapping on.
AngleSnapOn() {
    global snapOn := true
    global snapDeviation := 0.0
    SmoothingWindowsReset()
}

; Turn angle snapping off.
AngleSnapOff() {
    global snapOff := true
    global snapDeviation := 0.0
    SmoothingWindowsReset()
}

; =============================================================================
; INITIALIZATION
; =============================================================================

; Core state variables
global active := false
global cursorX := 0
global cursorY := 0
global accumulatorX := 0
global accumulatorY := 0
global accumulatorWheel := 0
global remainderX := 0
global remainderY := 0
global cursorXMouseGetPos := 0
global cursorYMouseGetPos := 0
global windowUnderMouse := ""
global controlUnderMouse := ""

; Texture
global sensitivity := IniRead("config.ini", "Texture", "sensitivity")
global refreshInterval := IniRead("config.ini", "Texture", "refreshInterval")

; Smoothing windows
global smoothingWindowX := []
global smoothingWindowY := []
global smoothingWindowNextIndex := 1
global smoothingWindowCurrentSize := 0
global smoothingWindowMaxSize := IniRead("config.ini", "Texture", "smoothingWindowMaxSize")
Loop smoothingWindowMaxSize {
    smoothingWindowX.Push(0)
    smoothingWindowY.Push(0)
}

; Angle snapping
global snapOn := StrLower(IniRead("config.ini", "Axis Snapping", "snapOnByDefault")) = "true"
global snapRatio := IniRead("config.ini", "Axis Snapping", "snapRatio")
global snapThreshold := IniRead("config.ini", "Axis Snapping", "snapThreshold")
global snapState := 0
global snapDeviation := 0.0

; Acceleration
global accelerationOn := StrLower(IniRead("config.ini", "Acceleration", "accelerationOn")) = "true"
accelerationBlend := IniRead("config.ini", "Acceleration", "accelerationBlend")
accelerationScale := IniRead("config.ini", "Acceleration", "accelerationScale") 
accelerationScale *= refreshInterval
global accelerationP := accelerationBlend / accelerationScale
global accelerationQ := accelerationBlend + 1
global accelerationR := accelerationScale

; Modifier emulation
global addShift := StrLower(IniRead("config.ini", "Modifier Emulation", "addShift")) = "true"
global addCtrl := StrLower(IniRead("config.ini", "Modifier Emulation", "addCtrl")) = "true"
global addAlt := StrLower(IniRead("config.ini", "Modifier Emulation", "addAlt")) = "true"

; Create mouse hook
global hHook := DllCall("SetWindowsHookEx", "int", 14, "ptr", CallbackCreate(MouseHook, "Fast"), "ptr", 0, "uint", 0, "ptr")  ; WH_MOUSE_LL is 14

; =============================================================================
; MOUSE HOOK FUNCTIONS
; =============================================================================

MouseHook(nCode, wParam, lParam)
{
    ; Pass on messages with nCode < 0, as per Microsoft specifications
    if (nCode < 0)
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)

    ; Extract info from MSLLHOOKSTRUCT
    static msllSize := 16  ; the actual struct is bigger, but we only need the first 16 bytes
    static msllBuffer := Buffer(msllSize, 0)
    DllCall("RtlMoveMemory", "ptr", msllBuffer.Ptr, "ptr", lParam, "ptr", msllSize)
    messageX         := NumGet(msllBuffer,  0,  "int")
    messageY         := NumGet(msllBuffer,  4,  "int")
    messageMouseData := NumGet(msllBuffer,  8, "uint")
    messageFlags     := NumGet(msllBuffer, 12, "uint")
    
    ; If user isn't pressing the hotkey, store cursor position for later
    if (not active) {
        global cursorX := messageX
        global cursorY := messageY
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
    }

    ; Handle mouse movements
    if (wParam = 0x0200) {
        deltaX := messageX - cursorX
        deltaY := messageY - cursorY
        global accumulatorX += deltaX
        global accumulatorY += deltaY
        return 1
    }

    ; Handle vertical wheel movements
    if (wParam = 0x020A) {
        wheelDelta := messageMouseData >> 16
        if (wheelDelta & 0x8000)
            wheelDelta := -(0x10000 - wheelDelta)
        global accumulatorWheel += wheelDelta
        return 1
    }

    ; Pass on all other messages (e.g. clicks)
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
}

RemoveMouseHook(ExitReason, ExitCode) {
    if (hHook)
        DllCall("UnhookWindowsHookEx", "ptr", hHook)
}

; =============================================================================
; WHEEL INPUT FUNCTIONS
; =============================================================================

SendWheel(deltaH, deltaV) {
    lowOrderX := cursorXMouseGetPos & 0xFFFF
    highOrderY := cursorYMouseGetPos & 0xFFFF
    if (controlUnderMouse != "") {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16, highOrderY << 16 | lowOrderX, controlUnderMouse, "ahk_id " windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16, highOrderY << 16 | lowOrderX, controlUnderMouse, "ahk_id " windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    } else {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16, highOrderY << 16 | lowOrderX,, "ahk_id " windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16, highOrderY << 16 | lowOrderX,, "ahk_id " windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    }
}

SendWheelWithModifiers(deltaH, deltaV, shift, ctrl, alt) {
    lowOrderX := cursorXMouseGetPos & 0xFFFF
    highOrderY := cursorYMouseGetPos & 0xFFFF
    modifiers := 0x00
    if (shift)
        modifiers += 0x04
    if (ctrl)
        modifiers += 0x08
    if (alt)
        modifiers += 0x20
    if (controlUnderMouse != "") {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16 | modifiers, highOrderY << 16 | lowOrderX, controlUnderMouse, "ahk_id " windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16 | modifiers, highOrderY << 16 | lowOrderX, controlUnderMouse, "ahk_id " windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    } else {
        if (deltaV != 0)
            PostMessage(0x20A, deltaV << 16 | modifiers, highOrderY << 16 | lowOrderX,, "ahk_id " windowUnderMouse)  ; 0x20A = WM_MOUSEWHEEL
        if (deltaH != 0)
            PostMessage(0x20E, deltaH << 16 | modifiers, highOrderY << 16 | lowOrderX,, "ahk_id " windowUnderMouse)  ; 0x20E = WM_MOUSEHWHEEL
    }
}

; =============================================================================
; SMOOTHING WINDOWS
; =============================================================================

SmoothingWindowsReset() {
    global smoothingWindowNextIndex := 1
    global smoothingWindowCurrentSize := 0
}

SmoothingWindowsPush(x, y) {
    global smoothingWindowX, smoothingWindowY
    smoothingWindowX[smoothingWindowNextIndex] := x
    smoothingWindowY[smoothingWindowNextIndex] := y
    if (smoothingWindowNextIndex = smoothingWindowMaxSize) {
        global smoothingWindowNextIndex := 1
    } else {
        global smoothingWindowNextIndex += 1
    }
    if (smoothingWindowCurrentSize < smoothingWindowMaxSize) {
        global smoothingWindowCurrentSize += 1
    }
}

SmoothingWindowsGetMeanX() {
    if (smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop smoothingWindowCurrentSize {
        mean += smoothingWindowX[A_Index]
    }
    return mean / smoothingWindowCurrentSize
}

SmoothingWindowsGetMeanY() {
    if (smoothingWindowCurrentSize = 0) {
        return 0
    }
    mean := 0
    Loop smoothingWindowCurrentSize {
        mean += smoothingWindowY[A_Index]
    }
    return mean / smoothingWindowCurrentSize
}

; =============================================================================
; TIMERS
; =============================================================================

TimerWheel() {
    If (accumulatorWheel = 0) {
        return
    }
    SendWheelWithModifiers(0, accumulatorWheel, ((addShift = 1) ^ GetKeyState("Shift", "P")), ((addCtrl = 1) ^ GetKeyState("Ctrl", "P")), ((addAlt = 1) ^ GetKeyState("Alt", "P")))
    global accumulatorWheel := 0
}

TimerScroll() {
    ; Apply smoothing window and reset accumulators
    SmoothingWindowsPush(accumulatorX, accumulatorY)
    smoothedX := SmoothingWindowsGetMeanX()
    smoothedY := SmoothingWindowsGetMeanY() * -1
    global accumulatorX := 0
    global accumulatorY := 0

    ; Apply angle snapping
    if (snapOn) {
        if (snapState = 0) {  ; Snapping is on, but we haven't decided which axis to snap to yet
            if (Abs(smoothedX) > Abs(smoothedY)) {  ; Switch to X axis snap
                smoothedY := 0
                global remainderY := 0
                global snapState := 1
            } else if (Abs(smoothedX) < Abs(smoothedY)) {  ; Switch to Y axis snap
                smoothedX := 0
                global remainderX := 0
                global snapState := 2
            }
        } else if (snapState = 1) {  ; Snapping is on, and we're snapped to the X axis
            global snapDeviation := snapDeviation + smoothedY
            if (snapDeviation > 0) {
                global snapDeviation := Max(0, snapDeviation - Abs(smoothedX) * snapRatio)
            } else if (snapDeviation < 0) {
                global snapDeviation := Min(0, snapDeviation + Abs(smoothedX) * snapRatio)
            }
            if (Abs(snapDeviation) > snapThreshold) {  ; Switch to Y axis snap
                smoothedX := 0
                global remainderX := 0
                global snapState := 2
                global snapDeviation := 0.0
                SmoothingWindowsReset()
            } else {  ; Remain snapped to X axis
                smoothedY := 0
                global remainderY := 0
            }
        } else if (snapState = 2) {  ; Snapping is on, and we're snapped to the Y axis
            global snapDeviation := snapDeviation + smoothedX
            if (snapDeviation > 0) {
                global snapDeviation := Max(0, snapDeviation - Abs(smoothedY) * snapRatio)
            } else if (snapDeviation < 0) {
                global snapDeviation := Min(0, snapDeviation + Abs(smoothedY) * snapRatio)
            }
            if (Abs(snapDeviation) > snapThreshold) {  ; Switch to X axis snap
                smoothedY := 0
                global remainderY := 0
                global snapState := 1
                global snapDeviation := 0.0
                SmoothingWindowsReset()
            } else {
                smoothedX := 0
                global remainderX := 0
            }
        }
    }

    ; Apply acceleration (v_out = p * square(min(v_in - r, 0)) + q * (v_in - r) + r)
    if (accelerationOn and ((smoothedX != 0) or (smoothedY != 0))) {
        speed := Sqrt(smoothedX * smoothedX + smoothedY * smoothedY)
        speed_offset := speed - accelerationR
        scale_factor := accelerationQ * speed_offset + accelerationR
        if (speed_offset < 0)
            scale_factor += accelerationP * speed_offset * speed_offset
        scale_factor /= speed
        smoothedX *= scale_factor
        smoothedY *= scale_factor
    }

    ; Apply sensitivity adjustment
    smoothedX *= sensitivity
    smoothedY *= sensitivity
    
    ; Apply previous rounding errors, and save new rounding errors
    smoothedX += remainderX
    smoothedY += remainderY
    roundedX := Round(smoothedX)
    roundedY := Round(smoothedY)
    global remainderX := smoothedX - roundedX
    global remainderY := smoothedY - roundedY

    ; Send wheel input
    SendWheel(roundedX, roundedY)
}

