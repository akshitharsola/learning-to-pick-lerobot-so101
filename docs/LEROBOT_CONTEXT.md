# LeRobot Project — Context File

**Share this file at the start of any new Claude session to get full context instantly.**

---

## Who I am

- Akshit Harsola — robotics engineer/student
- Email: harsolaakshit@gmail.com
- Comfortable with hardware, ROS, Linux. No need to over-explain basics.
- Primary machine: Mac (Apple Silicon). Also uses Ubuntu VM and university lab machines.

---

## Project History (quick version)

1. Started with **Lynxmotion AL5D** arm + OAK-D Lite camera on Ubuntu VM (ROS 2 Jazzy). Built a full pick-and-place pipeline: HSV ball detector, IK solver, SSC-32U serial driver, ZMQ camera bridge. Got the full cycle working.
2. Considered migrating to **Wlkata** arm.
3. Professor offered a choice: **Wlkata or LeRobot**. Chose **LeRobot** — it was already set up in the lab with cameras.
4. AL5D project deleted from disk (2026-06-17) to free storage.

---

## Current Project: LeRobot

### Hardware (in university lab)

| Component | Details |
|---|---|
| Arm | LeRobot (confirm exact model on first lab visit) |
| Gripper camera | Mounted on top of gripper — eye-in-hand view |
| Overhead camera | Top-view, fixed mount above workspace |

### Where we are

**Status: Calibration needed — this is the next step.**

LeRobot requires per-joint calibration before anything else:
- Each joint needs: min pulse, max pulse, and possibly homing/zero position
- Calibration is done via LeRobot's built-in calibration routine
- Has NOT been done yet

### Environment

- University lab machine (Linux, likely Ubuntu)
- Claude Code installed on lab machine for in-lab sessions
- LeRobot installed via HuggingFace's standard install (pip / conda)

---

## What to do in this session

Tell Claude what you're working on today. Likely starting points:
- Run LeRobot calibration for all joints
- Verify camera feeds from both cameras
- Test basic arm teleoperation

---

## Useful references

- LeRobot repo: https://github.com/huggingface/lerobot
- LeRobot docs / calibration: check `lerobot/` folder or HuggingFace docs

---

## Other active projects (background context)

### OpenClaw / Localis (on Ubuntu VM at home)

Local LLM setup on Ubuntu VM:
- OpenClaw (npm) orchestrates Qwen3 models
- Localis app on phone (192.168.0.200:8080) serves inference
- Memory proxy (Flask + ChromaDB) at `~/projects/localis-memory/` enriches prompts
- Systemd service: `localis-memory-proxy`
- Telegram bot on phone for model switching (`/model 1.7b`, `/model 4b`)
- This is a separate hobby project, not related to LeRobot

---

*Last updated: 2026-06-17*
