; =============================================================================
; NUKE THE SETTINGS
; =============================================================================

Init:
    RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Smooth Trackball Scrolling
    RegDelete, HKEY_CURRENT_USER\Software\Smooth Trackball Scrolling
    ExitApp
return