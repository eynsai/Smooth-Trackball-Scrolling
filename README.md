# Smooth-Trackball-Scrolling

Hold down a hotkey to turn your trackball into a scroll wheel!
You can either set it to snap to the X-Y axes, or have it scroll along both axes at once to emulate 2D panning!

You don't have to install AutoHotKey to use this - check the releases for a `.exe` download.

Other people have written several great alternatives to this script, such as [TrackballScroll](https://github.com/Seelge/TrackballScroll/tree/master).
However, this script seeks to differentiate itself by implementing continuous scrolling motion, as opposed to stepped.

## Settings

### Basics: 
- `Hotkey 1`: What key to use as the hotkey.
  - See the [AHK docs](https://www.autohotkey.com/docs/v1/Hotkeys.htm) for more information on how to format this.
  - Only single keys (keyboard or mouse) can be used - no combinations or modifiers.
  - If you end up accidently locking yourself out of your system, first use `CTRL+SHIFT+ESCAPE` to launch task manager and kill `smooth_trackball_scrolling.exe`. Then, run `smooth_trackball_scrolling_reset.exe`. This will reset all your settings back to default.
- `Hotkey 2`: A second hotkey, if you're using a 2 key mode. See below for more details.
  - Formatted the same way as `Hotkey 1`.
- `Mode`: Switch between momentary and toggle modes using one or two hotkeys.
  - `MO (1 key)`: Smooth scrolling is active when `Hotkey 1` is held, and inactive when `Hotkey 1` isn't held. `Hotkey 2` doesn't do anything.
  - `TG (1 key)`: Smooth scrolling is toggled when `Hotkey 1` is pressed down. `Hotkey 2` doesn't do anything.
  - `MO (2 key sym.)`: Smooth scrolling is active when `Hotkey 1` and `Hotkey 2` are both held.
    - This mode is intended for use with two keyboard keys.
    - You can start holding the two hotkeys in either order.
    - The original functionality of both hotkeys can still be used by tapping/holding the key individually.
      - If you tap a hotkey individually, the tap action will be sent upon key release.
      - If you hold a hotkey individually, the hold will start after a hold delay (configurable via `Hold Duration`).
  - `MO (2 key asym.)`: Smooth scrolling is active when `Hotkey 1` and `Hotkey 2` are both held.
    - This mode is intended for use with the two mouse buttons (`LButton` and `RButton`).
    - You must start holding `Hotkey 2` before `Hotkey 1`.
    - The original functionality of both hotkeys can still be used by tapping/holding the key individually.
      - If you tap `Hotkey 1` individually, the tap action will be sent immediately.
      - If you hold `Hotkey 1` individually, the hold action will start immediately.
      - If you tap `Hotkey 2` individually, the tap action will be sent upon key release.
      - If you hold `Hotkey 2` individually, the hold action will start after a hold delay (configurable via `Hold Duration`).
  - `TG (2 key asym.)`: `Hotkey1` turns smooth scrolling on, while `Hotkey2` turns smooth scrolling off.
    - This mode is intended to make it easier to integrate this script with QMK keyboard firmware and stuff.
- `Hold Duration`: Only applicable when using 2 key MO modes. The duration of the delay before a hold action starts. 

### Responsiveness, Smoothing, and Sensitivity:
- `Refresh Interval`: How often the script sends mouse wheel updates. The minimum and default value is 10 (ms). I recommend trying to use this value, but if you experience some apps behaving weirdly or inconsistently in response to scrolling, try bumping it up to something like 16 or 20. Basically set this to as low as it can go without causing problems.
- `Smoothing Window Size`: How much smoothing to apply. Higher values correspond to more smoothing and "momentum". Lower settings are snappier and more responsive. I recommend a value around 3 to 10, depending on your personal preference. If you increase your `Refresh Interval`, you might want to decrease your `Smoothing Window Size`, as the total amount of smoothing actually scales with the product of these two parameters.
- `Sensitivity`: Movement sensitivity.
- `Invert Direction`: Inverts scrolling direction.

### Angle Snapping
- `Angle Snapping Threshold`: Controls how hard it is to break away from being snapped to an axis. This parameter sets how much you have to move perpendiular to the axis to become un-snapped. A higher value will make it harder to un-snap from an axis. I recommend a value around 10, but this depends on how you want your snapping to work.
- `Angle Snapping Ratio`: Controls how hard it is to break away from being snapped to an axis. This parameter sets how much your movement direction can deviate angularly from the axis before you become un-snapped. A higher value will make it harder to un-snap from an axis. I recommend a value around 1.5, but this depends on how you want your snapping to work.
- `Angle Snapping On`: Whether or not you want angle snapping at all.
- `Always Angle Snap`: If this is on, when you become un-snapped from one axis, you snap to the other axis. If this is off, when you un-snap from one axis, you stay un-snapped.

### Modifier Emulation
- `Emulate Ctrl`, `Emulate Shift`, and `Emulate Alt`: If you check one or more of these boxes, the hotkey will add the respective key or key combination when you scroll with your real physical scroll wheel (not your trackball). This is to allow you to use your mouse wheel to zoom while holding down the hotkey (check the box or boxes corresponding to your software's zoom modifier key), thus allowing you to control pan and zoom using a single hotkey.

## Known Issues

- Unfortunately, I've found that some programs will not respond to the scroll inputs from my script, most notably Windows Explorer. I think a re-write of this script in a low-level language that can interface properly with the Windows input API will solve this, but I won't have time for this in the forseeable future.
- Some software, most notably Chromium-based browsers, do not respond well to simultaneous scrolling inputs along both the X and Y axes. Using angle snap will fix this.
- Using key combinations as the hotkey is currently not supported. I think I know how to fix this; I just need to rewrite the relevant part of the script, which I might not have time to do for the time being.
