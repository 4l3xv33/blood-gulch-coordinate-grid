# Blood Gulch Coordinate Grid

An interactive coordinate reference for Blood Gulch in Halo Trial.

**Live site:** [https://4l3xv33.github.io/blood-gulch-coordinate-grid/](https://4l3xv33.github.io/blood-gulch-coordinate-grid/)

Open `index.html`, hover over a grid intersection to inspect its `x, y, z` coordinate, and click an intersection to copy the value. Grid spacing can be changed between 1, 2, 5, and 10 world units.

The displayed `z` value is the Blood Gulch BSP surface height plus `0.5`, matching the actor-origin offset used for AI placement.

## Files

- `index.html` — interactive map and coordinate-grid interface
- `blood-gulch-map.png` — overhead reference image
- `grid-points.js` — browser-ready coordinate and BSP-height data
- `grid-points.json` — the same coordinate data in JSON form
- `generate-grid.ps1` — local regeneration helper for an Invader-extracted Blood Gulch BSP

## Running locally

The page can be opened directly from disk. A local static server also works:

```powershell
python -m http.server 8765
```

Then open `http://127.0.0.1:8765/`.

## Game-content notice

This is an unofficial fan-made coordinate tool. Halo and related game content are property of their respective owners. The included reference image is provided for identification and modding-reference purposes.
