# Runtime Test Matrix

The final byte pair has been confirmed working in foobar2000. After installation:

1. Confirm normal spectrum animation using the established GDI renderer.
2. Confirm normal spectrum animation using the native DX12 renderer.
3. Test Gradient with Line disabled, then enable Line and confirm it remains independent.
4. Test Peak, RMS and Peak Max separately and together.
5. Test Grid, Left Labels, Bottom Labels, Peak Detector and Calibration Line separately and together.
6. Change overlay colours/alpha and toggle Anti-aliasing.
7. Stop playback and confirm no artificial 1 px/baseline artefact remains in silent regions.
8. Resize repeatedly, switch layouts and stop/restart playback.
9. Rapidly alternate right-click/context-menu interaction between the playlist, Waveform Minibar and other panels; spectrum animation should remain responsive.
10. Leave a context menu open briefly and confirm the analyzer continues updating without making menu interaction sluggish.
11. Close foobar2000 while playback is active and confirm clean shutdown.

## Known host limitation

During interactive parent-window resizing, JSplitter/JScript Panel 3 can expose temporary composition-coordinate movement. Equivalent native DX12 visualisers show the same behaviour. The release keeps DX12 active during resizing rather than substituting the GDI renderer.
