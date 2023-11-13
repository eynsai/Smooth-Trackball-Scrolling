# Smooth-Trackball-Scrolling

Hold down a hotkey to turn your trackball into a scroll wheel!
You can either set it to snap to the X-Y axes, or have it scroll along both axes at once to emulate 2D panning!

You don't have to install AutoHotKey to use this - check the releases for a `.exe` download.

Other people have written several great alternatives to this script, such as [TrackballScroll](https://github.com/Seelge/TrackballScroll/tree/master).
However, this script seeks to differentiate itself by implementing continuous scrolling motion, as opposed to stepped.

## Settings

### Basics: 
- `Hotkey`: What key to use as the hotkey. See the [AHK docs](https://www.autohotkey.com/docs/v1/Hotkeys.htm) for more information on how to format this.
- `Sensitivity`: Movement sensitivity.
- `Invert Direction`: Inverts scrolling direction.

### Smoothness:
- `Refresh Interval`: How often the script sends mouse wheel updates. The minimum and default value is 10 (ms). I recommend trying to use this value, but if you experience some apps behaving weirdly or inconsistently in response to scrolling, try bumping it up to something like 16 or 20. Basically set this to as low as it can go without causing problems.
- `Smoothing Window Size`: How much smoothing to apply. Higher values correspond to more smoothing and "momentum". Lower settings are snappier and more responsive. I recommend a value around 3 to 10, depending on your personal preference. If you increase your `Refresh Interval`, you might want to decrease your `Smoothing Window Size`, as the total amount of smoothing actually scales with the product of these two parameters.

### Angle Snapping
- `Angle Snapping Threshold`: Controls how hard it is to break away from being snapped to an axis. This parameter sets how much you have to move perpendiular to the axis to become un-snapped. A higher value will make it harder to un-snap from an axis. I recommend a value around 10, but this depends on how you want your snapping to work.
- `Angle Snapping Ratio`: Controls how hard it is to break away from being snapped to an axis. This parameter sets how much your movement direction can deviate angularly from the axis before you become un-snapped. A higher value will make it harder to un-snap from an axis. I recommend a value around 1.5, but this depends on how you want your snapping to work.
- `Angle Snapping On`: Whether or not you want angle snapping at all.
- `Always Angle Snap`: If this is on, when you become un-snapped from one axis, you snap to the other axis. If this is off, when you un-snap from one axis, you stay un-snapped.

### Modifier Emulation
- `Emulate Ctrl`, `Emulate Shift`, and `Emulate Alt`: If you check one or more of these boxes, the hotkey will act as the respective key or key combination. This is intended to allow you to use your mouse wheel to zoom while holding down the hotkey (check the box or boxes corresponding to your software's zoom modifier key), thus allowing you to control pan and zoom using a single hotkey. Note that these modifiers will only be enabled while you keep your trackball still. When you move your trackball, these modifiers will be disabled so that they don't turn vertical scrolling into zooming or horizontal scrolling.

## Known Issues

- Unfortunately, I've found that some programs will not respond to the scroll inputs from my script, most notably Windows Explorer. I think a re-write of this script in a low-level language that can interface properly with the Windows input API will solve this, but I won't have time for this in the forseeable future.
- Some software, most notably Chromium-based browsers, do not respond well to simultaneous scrolling inputs along both the X and Y axes. Using angle snap will fix this.
