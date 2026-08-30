#!/bin/bash
set -e

# Re-recording session v2_7 — 6 episodes, pushed to HF.
# Recorded after re-mounting the wrist camera to a new/corrected position (2026-07-06);
# sessions 1-10 (old naming) used a different wrist camera position and are NOT compatible
# with this data for training — do not aggregate old and v2 sessions together.
# IMPORTANT: keep TASK_DESC byte-identical across all _session_v2_* scripts —
# the later aggregate_datasets() step keys task text exactly, and any
# mismatch (extra space, different wording) creates a duplicate task entry.

# --- fix serial permissions (needed each reboot/reconnect) ---
sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1

# --- activate env ---
source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh
conda activate lerobot

REPO_ID="Akshit03/AkshitMajorProjectMIR1_session_v2_7"
TASK_DESC="Pick up the blue block and place in the yellow bin"

lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm \
    --robot.cameras="{
        top: {
            type: opencv,
            index_or_path: /dev/video0,
            width: 640,
            height: 480,
            fps: 30
        },
        wrist: {
            type: opencv,
            index_or_path: /dev/video2,
            width: 640,
            height: 480,
            fps: 30,
            rotation: 180
        }
    }" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=so101_leader_arm \
    --display_data=true \
    --dataset.repo_id="${REPO_ID}" \
    --dataset.num_episodes=6 \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=25 \
    --dataset.push_to_hub=true \
    --dataset.single_task="${TASK_DESC}"
