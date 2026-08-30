#!/bin/bash
set -e

# Quick 2-episode trial recording, pushed to HF.
# Use this as a "smoke test" before real sessions to confirm wiring/cameras/HF auth are all good.

# --- fix serial permissions (needed each reboot/reconnect) ---
sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1

# --- activate env ---
source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh
conda activate lerobot

# --- repo id for this trial (change suffix per trial run if you want to keep history) ---
REPO_ID="Akshit03/AkshitMajorProjectMIR1_trial"
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
    --dataset.num_episodes=1 \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=25 \
    --dataset.push_to_hub=true \
    --dataset.single_task="${TASK_DESC}"
