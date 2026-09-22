# Technical Notes

## Architecture

The final build uses a patched x64 host plus an independently authored D3D12 sidecar. The host dynamically locates `foo_enhanced_spectrum_analyzer_dx12.dll` beside itself and resolves the community DX12 dispatch bridge. FFT analysis, averaging and spectrum-point generation remain in the host; compatible spectrum/overlay geometry is submitted through the native D3D12 path. The established GDI renderer remains available.

## Confirmed identities

- Upstream 1.9.2.0 x64 input: `7d49351661573a9ee27c8578ecdc66678289d2bdb531b43a1185df76ddb16b54` (138,752 bytes)
- Final runtime-validated host: `b0e4df422ebb54246167a711cf15a8bae6a7bc544e73dd0cbadd43995ca4efe8` (163,328 bytes)
- Final DX12 sidecar: `151d54a4626312f1aa6acb4aae54fad2e199b67cf008e7367196ffd7d3239541` (29,184 bytes)

## Final scheduler architecture

Windows Performance Recorder showed the original rapid context-menu animation stalls were caused by modal-menu starvation on foobar2000's UI thread. During subsequent compatibility testing, a second issue was found: the scheduler test lineage retained the component's original 10 ms `SetTimer` while also starting a separate 10 ms timer-queue render source. Those sources were not coalesced against each other and could effectively double-drive rendering, starving normal foobar2000 UI input even though spectrum animation itself remained smooth.

The final host therefore uses the original 10 ms Windows timer as the **only normal-playback rendering cadence**. The thread-local `WH_MSGFILTER` path remains restricted to `MSGF_MENU` and synchronously services the existing `WM_TIMER` ID 8 route only while modal menus own message dispatch. This preserves the context-menu animation fix without a second continuous render scheduler.

## Anti-aliasing

The GDI+ AA setting now selects `AntiAlias8x4` rather than the slower `AntiAlias8x8` mode accidentally present in the earlier test lineage. The existing gradient-boundary AA pass remains intact. Runtime testing after removal of duplicate render scheduling confirmed smooth nested and fullscreen playback with AA enabled in both instances.

## Fullscreen theme integration

When UI Theme Integration is enabled, the fullscreen/DUI instance now performs a low-rate refresh through the component's existing UI-theme colour assignment path. The refresh is intentionally decoupled from the per-frame render cadence; observed colour propagation is approximately 0.5-1 second and avoids adding continuous theme work to every frame.

## DX12 unsupported-hardware fallback

If `D3D12CreateDevice` returns `DXGI_ERROR_UNSUPPORTED`, the sidecar records D3D12 as unavailable for the current foobar2000 process and subsequent calls return to GDI fallback without repeated hardware initialisation attempts. Other failure modes are not permanently cached, preserving retry/device-loss recovery on supported hardware.

## Native DX12 overlays

- Grid: 30 logarithmic frequency divisions plus 11 horizontal level lines.
- Left Labels: 0 through -90 dB.
- Bottom Labels: 20, 50, 100, 200, 500, 1K, 2K, 5K, 10K and 20K.
- Peak Detector: original live peak records and frequency/decibel mappings.
- Calibration Line: original position, colour and alpha behaviour.

## Public reconstruction format

Patcher format `devilhood-esa-patch-v3` performs **one user-visible operation** from the exact untouched upstream 1.9.2.0 x64 input to the final host. Internally it reconstructs the audited pre-final community host in memory, applies the complete final 1.9.3.0 write set plus appended community code/data/unwind payload, verifies the complete final SHA-256, and only then creates output files. The intermediate host is never written to disk.

The package contains no original or modified upstream analyzer DLL. Inherited upstream bytes, including the Options dialog, are copied from the user's own verified input at runtime. Output files use exclusive creation and are never overwritten.
