#Requires AutoHotkey v2.0
#SingleInstance Force
#Include smooth_scrolling_backend.ahk
Persistent

; =============================================================================
; READ CONFIG
; =============================================================================

hotkey1 := IniRead("config.ini", "Hotkeys", "hotkey1")
hotkey2 := IniRead("config.ini", "Hotkeys", "hotkey2", "")
panicButton := IniRead("config.ini", "Hotkeys", "panicButton", "")
mode := IniRead("config.ini", "Hotkeys", "mode")
holdDuration := IniRead("config.ini", "Hotkeys", "holdDuration") + 0

; =============================================================================
; PANIC BUTTON
; =============================================================================

if (panicButton != "")
    Hotkey(panicButton, PanicFunction)
PanicFunction(_) {
    ExitApp()
}

; =============================================================================
; ON_OFF
; =============================================================================

if (mode = "ON_OFF") {
    Hotkey("$" hotkey1, OnOffKey1Down)
    Hotkey("$" hotkey1 " Up", OnOffKey1Up)
    Hotkey("$" hotkey2, OnOffKey2Down)
    Hotkey("$" hotkey2 " Up", OnOffKey2Up)

    onOffKey1FlipFlop := false
    onOffKey2FlipFlop := false

    OnOffKey1Down(_) {
        global onOffKey1FlipFlop
        if (onOffKey1FlipFlop)
            return  ; ignore autorepeats
        onOffKey1FlipFlop := true
        ScrollingActivate()
    }

    OnOffKey2Down(_) {
        global onOffKey2FlipFlop
        if (onOffKey2FlipFlop)
            return  ; ignore autorepeats
        onOffKey2FlipFlop := true
        ScrollingDeactivate()
    }

    OnOffKey1Up(_) {
        global onOffKey1FlipFlop
        onOffKey1FlipFlop := false
    }

    OnOffKey2Up(_) {
        global onOffKey1FlipFlop
        onOffKey1FlipFlop := false
    }
}

; =============================================================================
; ONE_KEY_TOGGLE
; =============================================================================

else if (mode = "ONE_KEY_TOGGLE") {
    Hotkey("$" hotkey1, OneKeyToggleDown)
    Hotkey("$" hotkey1 " Up", OneKeyToggleUp)

    oneKeyToggleFlipFlop := false

    OneKeyToggleDown(_) {
        global oneKeyToggleFlipFlop
        if (oneKeyToggleFlipFlop)
            return  ; ignore autorepeats
        oneKeyToggleFlipFlop := true
        if (IsSmoothScrollingActive()) {
            ScrollingDeactivate()
        } else {
            ScrollingActivate()
        }
    }

    OneKeyToggleUp(_) {
        global oneKeyToggleFlipFlop
        oneKeyToggleFlipFlop := false
    }
}

; =============================================================================
; ONE_KEY_MOMENTARY
; =============================================================================

else if (mode = "ONE_KEY_MOMENTARY") {
    Hotkey("$" hotkey1, OneKeyMomentaryDown)
    Hotkey("$" hotkey1 " Up", OneKeyMomentaryUp)

    oneKeyMomentaryFlipFlop := false

    OneKeyMomentaryDown(_) {
        global oneKeyMomentaryFlipFlop
        if (oneKeyMomentaryFlipFlop)
            return  ; ignore autorepeats
        oneKeyMomentaryFlipFlop := true
        ScrollingActivate()
    }
    
    OneKeyMomentaryUp(_) {
        global oneKeyMomentaryFlipFlop
        oneKeyMomentaryFlipFlop := false
        ScrollingDeactivate() 
    }
}

; =============================================================================
; ONE_KEY_TAP_TOGGLE
; =============================================================================

else if (mode = "ONE_KEY_TAP_TOGGLE") {
    Hotkey("$" hotkey1, OneKeyTapToggleDown)
    Hotkey("$" hotkey1 " Up", OneKeyTapToggleUp)

    oneKeyTapToggleFlipFlop := false
    oneKeyTapToggleKeyDown := false

    OneKeyTapToggleTimer() {
        global oneKeyTapToggleKeyDown
        oneKeyTapToggleKeyDown := true
        Send("{" hotkey1 " down}")
    }
    
    OneKeyTapToggleDown(_) {
        global oneKeyTapToggleFlipFlop
        if (oneKeyTapToggleFlipFlop)
            return  ; ignore autorepeats
        oneKeyTapToggleFlipFlop := true

        SetTimer(OneKeyTapToggleTimer, -holdDuration)
    }
    
    OneKeyTapToggleUp(_) {
        global oneKeyTapToggleFlipFlop, oneKeyTapToggleKeyDown
        oneKeyTapToggleFlipFlop := false

        SetTimer(OneKeyTapToggleTimer, 0)
        if (oneKeyTapToggleKeyDown) {
            oneKeyTapToggleKeyDown := false
            Send("{" hotkey1 " up}")
        } else {
            if IsSmoothScrollingActive() {
                ScrollingDeactivate()
            } else {
                ScrollingActivate()
            }
        }
    }
}

; =============================================================================
; ONE_KEY_HOLD_TOGGLE
; =============================================================================

else if (mode = "ONE_KEY_HOLD_TOGGLE") {
    Hotkey("$" hotkey1, OneKeyHoldToggleDown)
    Hotkey("$" hotkey1 " Up", OneKeyHoldToggleUp)

    oneKeyHoldToggleFlipFlop := false
    oneKeyHoldToggleLock := true
    
    OneKeyHoldToggleTimer() {
        ScrollingActivate()
    }

    OneKeyHoldToggleDown(_) {
        global oneKeyHoldToggleFlipFlop, oneKeyHoldToggleLock
        if (oneKeyHoldToggleFlipFlop)
            return  ; ignore autorepeats
        oneKeyHoldToggleFlipFlop := true

        if (IsSmoothScrollingActive()) {
            oneKeyHoldToggleLock := true
            ScrollingDeactivate()
        } else {
            oneKeyHoldToggleLock := false
            SetTimer(OneKeyHoldToggleTimer, -holdDuration)
        }
    }

    OneKeyHoldToggleUp(_) {
        global oneKeyHoldToggleFlipFlop
        oneKeyHoldToggleFlipFlop := false

        if (oneKeyHoldToggleLock)
            return  ; ignore up event after toggle off
        SetTimer(OneKeyHoldToggleTimer, 0)
        if (not IsSmoothScrollingActive())
            Send("{" hotkey1 " down}{" hotkey1 " up}")
    }
}

; =============================================================================
; ONE_KEY_HOLD_MOMENTARY
; =============================================================================

else if (mode = "ONE_KEY_HOLD_MOMENTARY") {
    Hotkey("$" hotkey1, OneKeyHoldMomentaryDown)
    Hotkey("$" hotkey1 " Up", OneKeyHoldMomentaryUp)

    oneKeyHoldMomentaryFlipFlop := false
    oneKeyHoldMomentaryTapped := true
    
    OneKeyHoldMomentaryTimer() {
        global oneKeyHoldMomentaryTapped
        oneKeyHoldMomentaryTapped := false
    }
    
    OneKeyHoldMomentaryDown(_) {
        global oneKeyHoldMomentaryFlipFlop, oneKeyHoldMomentaryTapped
        if (oneKeyHoldMomentaryFlipFlop)
            return  ; ignore autorepeats
        oneKeyHoldMomentaryFlipFlop := true

        ScrollingActivate()
        oneKeyHoldMomentaryTapped := true
        SetTimer(OneKeyHoldMomentaryTimer, -holdDuration)
    }
    
    OneKeyHoldMomentaryUp(_) {
        global oneKeyHoldMomentaryFlipFlop
        oneKeyHoldMomentaryFlipFlop := false

        ScrollingDeactivate()
        SetTimer(OneKeyHoldMomentaryTimer, 0)
        if (oneKeyHoldMomentaryTapped)
            Send("{" hotkey1 " down}{" hotkey1 " up}")
    }
}

; =============================================================================
; TWO_KEY_TAP_TOGGLE
; =============================================================================

else if (mode = "TWO_KEY_TAP_TOGGLE") {
    Hotkey("$" hotkey1, TwoKeyTapToggleKey1Down)
    Hotkey("$" hotkey1 " Up", TwoKeyTapToggleKey1Up)
    Hotkey("$" hotkey2, TwoKeyTapToggleKey2Down)
    Hotkey("$" hotkey2 " Up", TwoKeyTapToggleKey2Up)

    twoKeyTapToggleKey1FlipFlop := false
    twoKeyTapToggleKey2FlipFlop := false
    twoKeyTapToggleKey1State := false
    twoKeyTapToggleKey2State := false
    twoKeyTapToggleTimedOut := false
    twoKeyTapToggleLocked := false

    TwoKeyTapToggleTimer() {
        global twoKeyTapToggleTimedOut
        twoKeyTapToggleTimedOut := true
        if (twoKeyTapToggleKey1State) {
            Send("{" hotkey1 " down}")
        }
        if (twoKeyTapToggleKey2State) {
            Send("{" hotkey2 " down}")
        }
    }
    
    TwoKeyTapToggleKey1Down(_) {
        global twoKeyTapToggleKey1FlipFlop, twoKeyTapToggleKey1State, twoKeyTapToggleTimedOut, twoKeyTapToggleLocked
        if (twoKeyTapToggleKey1FlipFlop)
            return  ; ignore autorepeats
        twoKeyTapToggleKey1FlipFlop := true

        twoKeyTapToggleKey1State := true
        if (twoKeyTapToggleLocked) {
            return
        }
        if (IsSmoothScrollingActive()) {
            ScrollingDeactivate()
            twoKeyTapToggleLocked := true
            return
        }
        if (twoKeyTapToggleTimedOut) {
            Send("{" hotkey1 " down}")
            return
        }
        if (twoKeyTapToggleKey2State) {
            SetTimer(TwoKeyTapToggleTimer, 0)
            if (not IsSmoothScrollingActive()) {
                ScrollingActivate()
            }
        } else {
            SetTimer(TwoKeyTapToggleTimer, -holdDuration)
        }
    }

    TwoKeyTapToggleKey2Down(_) {
        global twoKeyTapToggleKey2FlipFlop, twoKeyTapToggleKey2State, twoKeyTapToggleTimedOut, twoKeyTapToggleLocked
        if (twoKeyTapToggleKey2FlipFlop)
            return  ; ignore autorepeats
        twoKeyTapToggleKey2FlipFlop := true

        twoKeyTapToggleKey2State := true
        if (twoKeyTapToggleLocked) {
            return
        }
        if (IsSmoothScrollingActive()) {
            ScrollingDeactivate()
            twoKeyTapToggleLocked := true
            return
        }
        if (twoKeyTapToggleTimedOut) {
            Send("{" hotkey2 " down}")
            return
        }
        if (twoKeyTapToggleKey1State) {
            SetTimer(TwoKeyTapToggleTimer, 0)
            if (not IsSmoothScrollingActive()) {
                ScrollingActivate()
            }
        } else {
            SetTimer(TwoKeyTapToggleTimer, -holdDuration)
        }
    }

    TwoKeyTapToggleKey1Up(_) {
        global twoKeyTapToggleKey1FlipFlop, twoKeyTapToggleKey1State, twoKeyTapToggleTimedOut, twoKeyTapToggleLocked
        twoKeyTapToggleKey1FlipFlop := false

        twoKeyTapToggleKey1State := false
        if (twoKeyTapToggleTimedOut) {
            Send("{" hotkey1 " up}")
        } else if ((not IsSmoothScrollingActive()) and (not twoKeyTapToggleLocked)) {
            Send("{" hotkey1 " down}")
            Send("{" hotkey1 " up}")
        }
        if (not twoKeyTapToggleKey2State) {
            SetTimer(TwoKeyTapToggleTimer, 0)
            twoKeyTapToggleTimedOut := false
            twoKeyTapToggleLocked := false
        }
    }

    TwoKeyTapToggleKey2Up(_) {
        global twoKeyTapToggleKey2FlipFlop, twoKeyTapToggleKey2State, twoKeyTapToggleTimedOut, twoKeyTapToggleLocked
        twoKeyTapToggleKey2FlipFlop := false

        twoKeyTapToggleKey2State := false
        if (twoKeyTapToggleTimedOut) {
            Send("{" hotkey2 " up}")
        } else if ((not IsSmoothScrollingActive()) and (not twoKeyTapToggleLocked)) {
            Send("{" hotkey2 " down}")
            Send("{" hotkey2 " up}")
        }
        if (not twoKeyTapToggleKey1State) {
            SetTimer(TwoKeyTapToggleTimer, 0)
            twoKeyTapToggleTimedOut := false
            twoKeyTapToggleLocked := false
        }
    }
}

; =============================================================================
; INVALID MODE
; =============================================================================

else {
    MsgBox "Error: Unsupported mode " mode " in config.ini."
    ExitApp
}
