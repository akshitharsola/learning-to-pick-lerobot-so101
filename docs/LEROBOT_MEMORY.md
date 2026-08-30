---
name: project-lerobot
description: "LeRobot arm project — switched from AL5D/Wlkata, lab setup with cameras, calibration needed"
metadata: 
  node_type: memory
  type: project
  originSessionId: e635d132-87c2-4cff-8bc2-9b5cf97f81d1
---

# LeRobot Project (started 2026-06-17)

Switched from AL5D → considered Wlkata → **chose LeRobot** (professor's lab already has it set up).

**Why LeRobot over Wlkata:** Lab already had LeRobot hardware ready with cameras mounted. Professor offered the choice and Akshit picked LeRobot.

**How to apply:** All new robotics work is LeRobot-based. AL5D project has been deleted from disk to free space. Do not reference AL5D hardware/code.

## Lab Hardware Setup

- LeRobot arm (exact model TBD — confirm in lab)
- Camera 1: mounted on top of gripper (wrist camera / eye-in-hand)
- Camera 2: top-view / overhead camera

## Current Status

**Calibration is the immediate next step.**

LeRobot requires per-joint calibration: min/max pulse widths and any other joint-specific parameters. This has NOT been done yet — needs to be performed on the lab machine.

## Key Notes

- Akshit may work on the **university lab machine** (not his personal Ubuntu VM)
- Will install Claude Code on the lab machine for sessions there
- This context file (`LEROBOT_CONTEXT.md` in home dir) is meant to be shared to new Claude sessions on any machine

## Links / References

- LeRobot GitHub: https://github.com/huggingface/lerobot
- Calibration docs: https://github.com/huggingface/lerobot/blob/main/docs/calibration.md (verify URL)

## Previous Project (AL5D) — archived

AL5D pick-and-place with ROS 2 Jazzy on Ubuntu VM was the prior project. Fully deleted from disk (2026-06-17). Key things built: HSV ball detector, IK solver, SSC-32U serial driver, ZMQ camera bridge. Not needed anymore.
