# Runtime Test Matrix

The final byte pair has been runtime-confirmed. After installation:

1. Confirm normal spectrum animation using the established GDI renderer.
2. Confirm normal spectrum animation using the native DX12 renderer on supported hardware.
3. Test Gradient with Line disabled, then enable Line and confirm it remains independent.
4. Test Peak, RMS and Peak Max separately and together.
5. Test Grid, Left Labels, Bottom Labels, Peak Detector and Calibration Line separately and together.
6. Enable Anti-aliasing in both nested and fullscreen instances and confirm foobar2000 remains responsive during playback.
7. While playback is active, enter/exit fullscreen using both double-click and Escape and confirm context menus remain responsive.
8. With UI Theme Integration enabled in fullscreen, change foobar2000 UI colours and confirm the fullscreen colours refresh automatically within roughly 0.5-1 second.
9. Stop playback and confirm no artificial 1 px/baseline artefact remains in silent regions.
10. Resize repeatedly, switch layouts and stop/restart playback.
11. Rapidly alternate right-click/context-menu interaction between the playlist, Waveform Minibar and other panels; spectrum animation should remain responsive.
12. Leave a context menu open briefly and confirm the analyzer continues updating without making menu interaction sluggish.
13. On hardware without D3D12 support, leave the sidecar installed and confirm stable GDI fallback without recurring responsiveness loss.
14. Close foobar2000 while playback is active and confirm clean shutdown.

## Known host limitation

During interactive parent-window resizing, JSplitter/JScript Panel 3 can expose temporary composition-coordinate movement. Equivalent native DX12 visualisers show the same behaviour. The release keeps DX12 active during resizing rather than substituting the GDI renderer.
