#!/bin/bash
set -e

# Asynchronous Inference — RobotClient for smolvla_mir1_strawberry (Strawberry + Cube Task)
# Run async_smolvla_server.sh FIRST in Terminal 1, then run this script in Terminal 2.
#
# Tasks supported:
#   1. Strawberry Pick & Place: "Pick up the red strawberry and place in the yellow bin"
#   2. Cube Pick & Place: "Pick up the blue block and place in the yellow bin"
#
# Configured parameters:
#   - chunk_size_threshold: 0.3
#   - aggregate_fn_name: weighted_average
#   - actions_per_chunk: 50

sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 2>/dev/null || true

source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate lerobot 2>/dev/null || true

# Determine model directory or fallback to Hub repo ID
MODEL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/smolvla_mir1_strawberry"
if [ ! -d "$MODEL_PATH" ]; then
    MODEL_PATH="Akshit03/smolvla_mir1_strawberry"
fi

python -m lerobot.async_inference.robot_client \
    --server_address=127.0.0.1:8080 \
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
    --task="Pick up the red strawberry and place in the yellow bin" \
    --policy_type=smolvla \
    --pretrained_name_or_path="$MODEL_PATH" \
    --policy_device=cuda \
    --actions_per_chunk=50 \
    --chunk_size_threshold=0.3 \
    --aggregate_fn_name=weighted_average \
    --debug_visualize_queue_size=True
