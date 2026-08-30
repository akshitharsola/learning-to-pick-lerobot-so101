#!/usr/bin/env python
"""Live dual-camera viewer for checking wrist/top camera alignment, using Rerun
(the pip opencv build here is headless, so cv2.imshow doesn't work).
Ctrl+C in the terminal to quit.
"""
import cv2
import rerun as rr

TOP_IDX = 0
WRIST_IDX = 2
WIDTH, HEIGHT = 640, 480

rr.init("camera_check", spawn=True)

top_cap = cv2.VideoCapture(TOP_IDX)
top_cap.set(cv2.CAP_PROP_FRAME_WIDTH, WIDTH)
top_cap.set(cv2.CAP_PROP_FRAME_HEIGHT, HEIGHT)

wrist_cap = cv2.VideoCapture(WRIST_IDX)
wrist_cap.set(cv2.CAP_PROP_FRAME_WIDTH, WIDTH)
wrist_cap.set(cv2.CAP_PROP_FRAME_HEIGHT, HEIGHT)

print("Live view running in the Rerun window — Ctrl+C here to quit.")

try:
    while True:
        ok_top, top_frame = top_cap.read()
        ok_wrist, wrist_frame = wrist_cap.read()

        if not ok_top or not ok_wrist:
            print("Failed to read from one or both cameras.")
            break

        wrist_frame = cv2.rotate(wrist_frame, cv2.ROTATE_180)

        rr.log("cameras/top", rr.Image(cv2.cvtColor(top_frame, cv2.COLOR_BGR2RGB)))
        rr.log("cameras/wrist", rr.Image(cv2.cvtColor(wrist_frame, cv2.COLOR_BGR2RGB)))
except KeyboardInterrupt:
    pass
finally:
    top_cap.release()
    wrist_cap.release()
