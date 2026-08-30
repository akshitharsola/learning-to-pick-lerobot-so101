#!/bin/bash
set -e

# ACT (Action Chunking Transformer) Real-Robot Evaluation (10 Episodes)
# Rollout via lerobot-rollout episodic strategy.
#
# Task: "Pick up the blue block and place in the yellow bin"
#
# NOTE ON CONFIG:
# If loading from Hugging Face Hub encounters a `draccus.utils.DecodingError` due to
# `pretrained_revision`, use a local snapshot directory with `pretrained_revision` stripped
# from config.json.

sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 2>/dev/null || true

source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate lerobot 2>/dev/null || true

REPO_ID="Akshit03/rollout_act_mir1_v2"
POLICY_PATH="Akshit03/act_mir1_v2"
TASK_DESC="Pick up the blue block and place in the yellow bin"

lerobot-rollout \
    --strategy.type=episodic \
    --policy.path="${POLICY_PATH}" \
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
