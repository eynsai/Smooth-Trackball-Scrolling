# Smooth-Trackball-Scrolling

Hold down a hotkey to turn your trackball into a scroll wheel!
You can either set it to snap to the X-Y axes, or have it scroll along both axes at once to emulate 2D panning!

You don't have to install AutoHotKey to use this - check the releases for a `.exe` download.

Other people have written several great alternatives to this script, such as [TrackballScroll](https://github.com/Seelge/TrackballScroll/tree/master).
However, this script seeks to differentiate itself by implementing continuous scrolling motion, as opposed to stepped.

## Settings

- `Hotkey`: What key to use as the hotkey. See the [AHK docs](https://www.autohotkey.com/docs/v1/Hotkeys.htm) for more information on how to format this.
- `Refresh Interval`: How often the script sends mouse wheel updates. I recommend keeping this at the minimum (10ms) unless you're experiencing problems with programs not being able to keep up with that rate.
- `Smoothing Window Size`: How much smoothing to apply. Higher values correspond to more smoothing. I recommend a value around 10.
- `Sensitivity`: Movement sensitivity. I recommend a value around 4.
- `Invert Direction`: Inverts scrolling direction.
- `Angle Snapping Threshold`: Controls how hard it is to break away from being snapped to an axis. This parameter sets how much you have to move perpendiular to the axis to become un-snapped. A higher value will make it harder to un-snap from an axis. I recommend a value around 10, but this depends on how you want your snapping to work.
- `Angle Snapping Ratio`: Controls how hard it is to break away from being snapped to an axis. This parameter sets how much your movement direction can deviate angularly from the axis before you become un-snapped. A higher value will make it harder to un-snap from an axis. I recommend a value around 1, but this depends on how you want your snapping to work.
- `Angle Snapping On`: Whether or not you want angle snapping at all.
- `Always Angle Snap`: If this is on, when you become un-snapped from one axis, you snap to the other axis. If this is off, when you un-snap from one axis, you stay un-snapped.

## To-Do

Unfortunately, I've found that my script has compatibility issues with some programs.
I think a re-write of this script in a low-level language that can interface properly with the Windows input API will solve this, but I won't have time for this in the forseeable future. 

