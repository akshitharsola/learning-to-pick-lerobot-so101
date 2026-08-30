#!/bin/bash
set -e

# Asynchronous Inference — PolicyServer Process
# Run this FIRST in its own terminal and leave it running.
#
# ARCHITECTURE:
# Synchronous inference (standard lerobot-rollout) suffers from high latency for VLM/VLA models
# (~4.5 Hz on SO-101 workstation), causing erratic robot movement.
# LeRobot's async architecture decouples the high-latency GPU policy forward pass (running on PolicyServer)
# from the high-frequency robot control loop (running on RobotClient).
#
# NOTE: The policy weights and device are negotiated during the initial client handshake,
# so the server can remain running across model evaluations without restart.

source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate lerobot 2>/dev/null || true

echo "Starting LeRobot Asynchronous Policy Server on 127.0.0.1:8080..."
python -m lerobot.async_inference.policy_server \
    --host=127.0.0.1 \
    --port=8080
