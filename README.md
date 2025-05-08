# Version 2 Update!

A big thanks to everyone who provided feedback, opened issues/PRs, or just simply tried the script out.
I hope that this update improves functionality for some of you.
That being said, this update involved rewriting a lot of the code from scratch, and therefore there are likely some bugs that slipped in.
If you encounter any issues, please let me know!

- Better app compatibility
    - Version 2 is now compatible with the windows file explorer, .NET apps, and windows store apps.
        - This was accomplished by attempting to post wheel input messages to target controls as well as target windows.
- Usability improvements
    - The mouse hook has been modified to no longer block mouse buttons, making it easier and safer to use mouse buttons as hotkeys.
    - Hotkey modes have been rewritten based on some user feedback.
        - A couple modes haven't been implemented yet.
- Code quality improvements
    - Upgraded to AutoHotKey v2.
    - The code has been split into a sort of backend "API" (`smooth_scrolling_backend.ahk`), and an "app" (`smooth_scrolling_app.ahk`) that uses this backend.
        - `smooth_scrolling_backend.ahk` implements all of the low-level functionality behind smooth scrolling, and users who want highly customized behavior or functionality can simply include this script into their own code.
        - `smooth_scrolling_app.ahk` provides some baseline functionality for users who aren't interested in implementing their own hotkey functionality.
    - Settings are now stored in a config.ini file instead of in the registry, making the code easier to modify and maintain.
- More features
    - A panic button has been added.
    - An acceleration curve that emulates the windows mouse acceleration curve has been added.
        - This feature is intended for users who don't use the windows acceleration curve for mouse movement, but still want acceleration for scrolling.
    - Angle snapping can now be dynamically turned on and off, which might be useful for certain art or design softwares.
        - For now, this feature is API-only.

# Summary

Hold down a hotkey to turn your trackball into a scroll wheel!
You can either set it to snap to the X-Y axes, or have it scroll along both axes at once to emulate 2D panning!
You don't have to install AutoHotKey to use this - check the releases for a `.exe` download.

Other people have written several great alternatives to this script, such as [TrackballScroll](https://github.com/Seelge/TrackballScroll/tree/master).
However, this script seeks to differentiate itself by implementing continuous scrolling motion, as opposed to stepped.

# Settings

Whereas version 1 used registry keys to store settings, version 2 stores all settings in a `config.ini` file. This makes it easier to swap between different settings, as well as to restore or reset settings in the event of problems.

## Hotkeys

### `hotkey1`, `hotkey2`
- Hotkeys to control smooth scrolling.
- Can be any AutoHotKey hotkey string representing a single unmodified key or button (e.g. F1, MButton, LControl).
- The use of more complex hotkey strings involving modifiers (e.g. ^F1, ~MButton, LControl Up) may cause issues.
- Depending on the selected mode, hotkey2 may or may not be used.

### `panicButton`
- Button to force-quit the script.

### `mode`
- Various ways to control smooth scrolling.

| Mode                   | Description                                                                                                                                                                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ON_OFF                 | Smooth scrolling is turned on when hotkey1 is pressed down, and turned off when hotkey2 is pressed down. Intended to facilitate integration with custom keyboard firmware (to prevent the keyboard from needing to keep track of smooth scrolling state). |
| ONE_KEY_TOGGLE         | Smooth scrolling is toggled when hotkey1 is pressed. Original functionality of hotkey1 is blocked.                                                                                                                                                        |
| ONE_KEY_MOMENTARY      | Smooth scrolling is turned on while hotkey1 is held. Original functionality of hotkey1 is blocked.                                                                                                                                                        |
| ONE_KEY_TAP_TOGGLE     | Smooth scrolling is toggled when hotkey1 is tapped for shorter than holdDuration. Original functionality is retained if hotkey1 is held.                                                                                                                  |
| ONE_KEY_HOLD_TOGGLE    | Smooth scrolling is toggled when hotkey1 is held for longer than holdDuration. Original functionality is retained if hotkey1 is tapped.                                                                                                                   |
| ONE_KEY_HOLD_MOMENTARY | Smooth scrolling is turned on while hotkey1 is held for longer than holdDuration. Original functionality is retained if hotkey1 is tapped.                                                                                                                |
| TWO_KEY_TAP_TOGGLE     | Smooth scrolling is toggled when hotkey1 and hotkey2 are simultanously tapped for shorter than holdDuration. Original functionality is retained if only one hotkey is tapped/held.                                                                        |
| TWO_KEY_HOLD_TOGGLE    | *(Not implemented yet)* Smooth scrolling is toggled when hotkey1 and hotkey2 are simultanously held for longer than holdDuration. Original functionality is retained if only one hotkey is tapped/held.                                                   |
| TWO_KEY_HOLD_MOMENTARY | *(Not implemented yet)* Smooth scrolling is turned on while hotkey1 and hotkey2 are simultanously held for longer than holdDuration. Original functionality is retained if only one hotkey is tapped/held.                                                |

### `holdDuration`
- Only relevant if a TAP or HOLD mode is used.
- Controls the duration, in milliseconds, that differentiates between a tap and a hold.

## Texture

### `sensitivity`
- Sensitivity.
- Can be any non-zero real number.
- Negative values can be used to invert scroll direction.

### `refreshInterval`
- How often the script runs, in milliseconds.
- Higher values can increase reliability at the cost of smoothness.
- Must be an integer greater than or equal to 10.
- A value of 10 is recommended, but if you experience some apps responding weirdly, try bumping it up to around 16 or 20.

### `smoothingWindowMaxSize`
- How much smoothing to apply.
- Lower settings are snappier, while higher settings have more smoothness and momentum.
- Must be an integer greater than or equal to 1.
- A value of around 3 to 10 is recommended.

## Axis Snapping

### `snapOnByDefault`
- Whether or not to use axis snapping at the start of the script.
- Must be true or false.
- Note that several apps, including chromium-based browsers, will have problems if angle snapping is turned off.
- Therefore, it is recommended that you leave this on unless you specifically need omnidirectional scrolling.

### `snapRatio`
- The snap ratio controls how much your movement direction can deviate from the axis before you become un-snapped.
- A higher value will make it harder to un-snap from an axis.
- Must be a positive real number.
- A value of 1.5 is recommended, but this depends on how you want your snapping to work.

### `snapThreshold`
- The snap threshold controls how much you have to move perpendicular to the axis before you become un-snapped.
- A higher value will make it harder to un-snap from an axis.
- Must be a positive real number.
- A value of 10 is recommended, but this depends on how you want your snapping to work.

## Acceleration

### `accelerationOn`
- Whether or not to apply an acceleration curve (https://www.desmos.com/calculator/bchynqgg5g) to smooth scrolling.
- Must be true or false.
- Note that, if you use Windows mouse acceleration, that acceleration will be applied independently of this setting.
- Therefore, this setting is mostly for people who don't want acceleration on their cursor movement, but want it when scrolling.

### `accelerationBlend`
- Controls the shape of the acceleration curve.
- Must be a real number between 0 and 1.
- A value of 0.872116 is recommended, since this best replicates the Windows mouse acceleration curve.

### `accelerationScale`
- Controls the scale of the acceleration curve.
- Must be a positive real number.
- Smaller values will result in acceleration being applied to only very slow scrolling, with linear behavior when scrolling faster.
- Larger values will result in acceleration applying to both slow and fast scrolling.
- A value of between roughly 100-1000 is recommended, but it's best to set it to taste (you might also need to tweak sensitivity).

## Modifier Emulation

### `addShift`, `addCtrl`, `addAlt`
- Enabling these options will add the respective modifiers when you scroll with your physical scroll wheel (not your trackball).
- This allows you to control pan and zoom using the same hotkey(s) as smooth scrolling.
- Each option must be true or false.

# API

Everything is implemented in `smooth_scrolling_backend.ahk`. 

| Function                  | Returns | Description                    |
| ------------------------- | ------- | ------------------------------ |
| IsSmoothScrollingActive() | bool    | Check if angle snapping is on. |
| IsAngleSnapOn()           | bool    | Check if angle snapping is on. |
| ScrollingActivate()       | None    | Start smooth scrolling.        |
| ScrollingDeactivate()     | None    | Stop smooth scrolling.         |
| AngleSnapOn()             | None    | Turn angle snapping on.        |
| AngleSnapOff()            | None    | Turn angle snapping off.       |