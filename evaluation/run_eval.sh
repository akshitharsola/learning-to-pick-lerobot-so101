#!/bin/bash
set -e

# Unified entry point for real-robot policy evaluation and demo rollouts.
#
# USAGE:
#   1. Start the policy server (in Terminal 1, leave running):
#      ./run_eval.sh server
#
#   2. Run the policy client (in Terminal 2):
#      ./run_eval.sh demo             # Alias for strawberry task on SmolVLA
#      ./run_eval.sh strawberry       # Strawberry pick & place (smolvla_mir1_strawberry)
#      ./run_eval.sh strawberry-cube  # Cube regression check on smolvla_mir1_strawberry
#      ./run_eval.sh blacktip         # Cube task on bug-fixed smolvla_mir1_blacktip_fix
#      ./run_eval.sh act              # ACT v2 policy evaluation (lerobot-rollout)
#      ./run_eval.sh diffusion        # Diffusion Policy v2 evaluation (DDIM 5-step)
#
# NOTES:
# - For SmolVLA policies, async inference (server + client) is required to maintain real-time Hz.
# - The policy is negotiated at client handshake; the server does not need restarting between tests.
# - See DEMO.md for presentation guide and README.md for technical details.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
    server)
        exec "$DIR/async_smolvla_server.sh"
        ;;
    demo|strawberry)
        exec "$DIR/async_strawberry_client.sh"
        ;;
    blacktip)
        exec "$DIR/async_blacktip_client.sh"
        ;;
    strawberry-cube)
        sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 2>/dev/null || true
        source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/anaconda3/etc/profile.d/conda.sh 2>/dev/null || true
        conda activate lerobot 2>/dev/null || true
        exec python -m lerobot.async_inference.robot_client \
            --server_address=127.0.0.1:8080 \
            --robot.type=so101_follower \
            --robot.port=/dev/ttyACM1 \
            --robot.id=so101_follower_arm \
            --robot.cameras="{
                top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30},
                wrist: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30, rotation: 180}
            }" \
            --task="Pick up the blue block and place in the yellow bin" \
            --policy_type=smolvla \
            --pretrained_name_or_path="Akshit03/smolvla_mir1_strawberry" \
            --policy_device=cuda \
            --actions_per_chunk=50 \
            --chunk_size_threshold=0.3 \
            --aggregate_fn_name=weighted_average \
            --debug_visualize_queue_size=True
        ;;
    act)
        exec "$DIR/eval_act.sh"
        ;;
    diffusion)
        exec "$DIR/eval_diffusion.sh"
        ;;
    *)
        echo "Usage: $0 {server|demo|strawberry|strawberry-cube|blacktip|act|diffusion}"
        echo "  server           Start async policy server (run in Terminal 1)"
        echo "  demo             Run strawberry pick & place demo on SmolVLA"
        echo "  strawberry       Run strawberry task on smolvla_mir1_strawberry"
        echo "  strawberry-cube  Run cube regression on smolvla_mir1_strawberry"
        echo "  blacktip         Run cube task on smolvla_mir1_blacktip_fix"
        echo "  act              Run ACT v2 episodic rollout (lerobot-rollout)"
        echo "  diffusion        Run Diffusion Policy v2 rollout (DDIM 5-step)"
        exit 1
        ;;
esac
