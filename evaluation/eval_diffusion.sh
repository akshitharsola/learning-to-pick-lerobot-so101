#!/bin/bash
set -e

# Diffusion Policy Real-Robot Evaluation (10 Episodes)
# Rollout via lerobot-rollout episodic strategy.
#
# Task: "Pick up the blue block and place in the yellow bin"
#
# INFERENCE ACCELERATION:
# Default DDPM (100 inference steps) yielded ~0.9 Hz control rate (unusable for real-time control).
# DDIM with 5 inference steps is configured below to achieve ~13-14.5 Hz real-time control.

sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 2>/dev/null || true

source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate lerobot 2>/dev/null || true

REPO_ID="Akshit03/rollout_diffusion_mir1_ddim_v2"
POLICY_PATH="Akshit03/diffusion_mir1_v2"
TASK_DESC="Pick up the blue block and place in the yellow bin"

lerobot-rollout \
    --strategy.type=episodic \
    --policy.path="${POLICY_PATH}" \
    --policy.noise_scheduler_type=DDIM \
    --policy.num_inference_steps=5 \
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
    --display_data=true \
    --dataset.repo_id="${REPO_ID}" \
    --dataset.num_episodes=10 \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=25 \
    --dataset.push_to_hub=true \
    --dataset.single_task="${TASK_DESC}"
