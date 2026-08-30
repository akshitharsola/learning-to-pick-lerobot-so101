# Empirical Evaluation Results — v1 Failure and v2 Root-Cause Analysis

**Task:** *"Pick up the blue block and place in the yellow bin"*
**Platform:** SO-101 6-DoF Follower Robot Arm with Feetech STS3215 Servos
**Perception:** Dual USB RGB Cameras (Logitech C170 Top Overhead + Generic 180° Inverted Wrist)

---

## 1. v1 Real-Robot Evaluation Results

Two policies, ACT and Diffusion Policy, were trained on the original 42-episode v1 dataset and evaluated on the real robot. Both produced poor results:

| Policy | Result | Observed Failure Pattern |
|---|---|---|
| ACT | 1 / 10 | Approach good, gripper reaches the target, grasp does not close correctly: nine consecutive failures with the identical pattern |
| Diffusion Policy (DDIM-5, ~12–14 Hz) | 4 / 10 | Same "approach good, grasp missed" pattern, though less consistently than ACT |

The root cause was traced to a physically shifted wrist-camera mount (Section 9.1 of the thesis report), not a training or data-quality problem. v1's data and models were discarded and are not reused in any later round.

---

## 2. v2 Round: Three-Policy Training

Following the camera fix, all three policies were trained/fine-tuned on the 42-episode v2 dataset. Training configuration:

| Policy | Steps | Wall-Clock Time |
|---|:---:|:---:|
| ACT | 30,000 | 5h 08m |
| Diffusion Policy | 30,000 | 6h 37m |
| SmolVLA | 20,000 (fine-tuned from `lerobot/smolvla_base`) | 61h 36m |

The v2-round real-robot evaluation was reported informally at the time as favourable for SmolVLA, but **no formal, per-episode success/failure table was logged for this round** — the evaluation-results document template prepared for this purpose was left blank. That gap is stated here plainly rather than filled with an invented number. What the evaluation did surface, informally but concretely, was the gripper-release fault near light- and dark-contact areas that motivated Round 3 of data collection.

---

## 3. Diffusion Sampling Acceleration Analysis

In standard rollout mode with DDPM (100 denoising steps), the real-robot control loop dropped to an unusable **0.9 Hz**. Switching to DDIM sampling improved this substantially:
- **DDIM 10 steps:** ~7.8 Hz
- **DDIM 5 steps:** ~12–14 Hz (selected for evaluation)

This is roughly half of ACT's ~25 Hz control rate, reflecting the trade-off between Diffusion Policy's representational flexibility and its inference cost.
