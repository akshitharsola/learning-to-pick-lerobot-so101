#!/bin/bash
set -e

# Benchmark synchronous control-loop frequency (Hz) for smolvla_mir1_blacktip_fix
# Short 30s single-episode rollout without pushing to Hub.
#
# Baseline expectation: ~4.5-4.7 Hz (demonstrating why async inference server is required).

sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 2>/dev/null || true

source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate lerobot 2>/dev/null || true

POLICY_PATH="Akshit03/smolvla_mir1_blacktip_fix"

lerobot-rollout \
    --strategy.type=episodic \
    --policy.path="${POLICY_PATH}" \
    --policy.chunk_size=100 \
    --policy.n_action_steps=100 \
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
    --display_data=false \
    --dataset.repo_id="Akshit03/rollout_timing_check_blacktip" \
    --dataset.num_episodes=1 \
    --dataset.episode_time_s=30 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=false \
    --dataset.single_task="Pick up the blue block and place in the yellow bin"
