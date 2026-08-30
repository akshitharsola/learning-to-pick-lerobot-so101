# Hardware & Camera Diagnostics

This directory contains diagnostic utilities for hardware validation, camera indexing, and optical alignment verification.

---

## 1. Scripts in this Directory

| Script | Purpose | Dependencies |
|---|---|---|
| [`live_camera_check.py`](file:///Users/akshitharsola/Documents/GALWAY/IR_PRoject/Machines/thesis-code/diagnostics/live_camera_check.py) | Real-time dual-camera visualization stream using Rerun | `opencv-python`, `rerun-sdk` |

---

## 2. Why Rerun is Used Over `cv2.imshow`

On Linux workstations configured with headless Python environments, standard `cv2.imshow()` throws a GUI backend error:
```
cv2.error: OpenCV(4.x) ... The function is not implemented. Rebuild the library with Windows, GTK+ 2.x or Cocoa support.
```
To bypass this limitation without recompiling OpenCV:
- [`live_camera_check.py`](file:///Users/akshitharsola/Documents/GALWAY/IR_PRoject/Machines/thesis-code/diagnostics/live_camera_check.py) connects to the top overhead camera (`/dev/video0`) and wrist camera (`/dev/video2`).
- Applies a hardware-compensating **180° rotation** to the inverted wrist camera frame.
- Logs both RGB video streams in real time to the **Rerun** visualizer (`rr.init("camera_check", spawn=True)`), rendering smooth live visual feeds in native GUI or web browser.

---

## 3. How to Run Camera Diagnostics

```bash
conda activate lerobot
python diagnostics/live_camera_check.py
```

### Verification Checklist:
1. **Top Camera:** Ensure the full workspace (robot base, picking area, and receptacle bin) is clearly visible without occlusion.
2. **Wrist Camera:** Ensure the gripper fingers appear symmetrically at the bottom of the feed and that objects directly in front of the fingers are sharply focused.
3. **Orientation:** Confirm the wrist camera feed is upright (rotation handled automatically).
