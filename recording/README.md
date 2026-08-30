# Teleoperation Demonstration Recording

This directory contains shell scripts used to record human teleoperated demonstrations on the **SO-101 Leader-Follower** robotic arm setup using LeRobot.

---

## 1. Hardware Architecture & Calibration

The demonstration system relies on a bilateral teleoperation setup:
- **Leader Arm:** Passive SO-101 6-DoF arm held by the human demonstrator, connected via USB serial (`/dev/ttyACM0`).
- **Follower Arm:** Active SO-101 6-DoF arm driven by Feetech STS3215 bus servos, connected via USB serial (`/dev/ttyACM1`).
- **Overhead Camera (Top):** Logitech Webcam C170 (`/dev/video0`), capturing a global 640×480 @ 30 FPS workspace view.
- **Wrist-Mounted Camera (Wrist):** Generic USB webcam (`/dev/video2`), capturing a close-up 640×480 @ 30 FPS gripper view with hardware 180° inverted mounting.

```bash
# Verify USB devices before recording
ls -l /dev/ttyACM* /dev/video*
sudo chmod 666 /dev/ttyACM*
```

---

## 2. Directory Structure

```
recording/
└── recording_sessions/
    ├── v1_deprecated/       # Initial 10 sessions (discarded due to camera mount shift)
    │   ├── record_session1.sh ... record_session10.sh
    │   └── record_trial.sh
    └── v2_current/          # Validated 7 sessions used for final thesis models
        ├── record_session_v2_1.sh ... record_session_v2_7.sh
```

---

## 3. Difference Between v1 and v2 Recordings

### Why v1 is Deprecated:
- During preliminary evaluations on the real robot, both ACT and Diffusion policies demonstrated high approach accuracy but missed final grasps by 1–2 cm.
- Root cause analysis confirmed that the **physical wrist-camera mount had loosened and shifted** between initial calibration and subsequent runs, introducing an uncalibrated coordinate offset into close-range visual features.
- `v1_deprecated/` scripts are retained in this repository for full scientific transparency and engineering failure analysis.

### Validated v2 Recordings:
- The wrist camera was re-seated, rigidly bolted in place, and verified via [`diagnostics/live_camera_check.py`](file:///Users/akshitharsola/Documents/GALWAY/IR_PRoject/Machines/thesis-code/diagnostics/live_camera_check.py).
- 7 new sessions (`record_session_v2_1.sh` through `record_session_v2_7.sh`) were recorded, providing **42 flawless demonstration episodes (33,353 frames)**.

---

## 4. Recording Command Structure

Each recording script executes `lerobot-record` with standard parameters:

```bash
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm \
    --robot.cameras="{
        top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30},
        wrist: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30, rotation: 180}
    }" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=so101_leader_arm \
    --display_data=true \
    --dataset.repo_id="Akshit03/AkshitMajorProjectMIR1_session_v2_1" \
    --dataset.num_episodes=6 \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=25 \
    --dataset.push_to_hub=true \
    --dataset.single_task="Pick up the blue block and place in the yellow bin"
```

> [!IMPORTANT]
> The `--dataset.single_task` string must remain byte-identical across all recording sessions so that LeRobot's downstream aggregation tool registers them under a single unified task ID.
