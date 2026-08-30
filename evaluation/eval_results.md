# Empirical Evaluation Results — Baseline Comparison (ACT vs Diffusion vs SmolVLA)

**Task:** *"Pick up the blue block and place in the yellow bin"*  
**Platform:** SO-101 6-DoF Follower Robot Arm with Feetech STS3215 Servos  
**Perception:** Dual USB RGB Cameras (Logitech C170 Top Overhead + Generic 180° Inverted Wrist)

---

## 1. Summary Comparison Table

| Metric / Policy | ACT Baseline (`act_mir1_v2`) | Diffusion Policy (`diffusion_mir1_v2`) | SmolVLA Baseline (`smolvla_mir1_v2`) |
|---|---|---|---|
| **Architecture** | Transformer C-VAE Encoder-Decoder | Denoising Diffusion Probabilistic / DDIM | 450M Vision-Language-Action (VLA) |
| **Pretrained Base** | None (Trained from scratch) | None (Trained from scratch) | `lerobot/smolvla_base` (10M real frames) |
| **Training Steps** | 30,000 steps | 30,000 steps | 20,000 steps |
| **Training Hardware** | NVIDIA Jetson AGX Orin | NVIDIA Jetson AGX Orin | NVIDIA Jetson AGX Orin |
| **Control Loop Hz** | ~25 Hz (Synchronous) | ~13–14.5 Hz (DDIM 5 steps) | ~30 Hz (Asynchronous Server/Client) |
| **Success Rate** | **6 / 10 (60%)** | **7 / 10 (70%)** | **9 / 10 (90%)** |
| **Primary Failure Mode** | Final centimeter grasp alignment | Execution speed / slight trajectory lag | Occasional gripper release on black-tip |

---

## 2. Investigation of v1 Hardware Discrepancy

During initial v1 testing, both ACT and Diffusion exhibited low grasp rates (1/10 and 4/10 respectively). Systematic failure analysis revealed that the **wrist camera mount had physically shifted** relative to the gripper assembly after calibration.

- Re-mounting and rigidly securing the camera restored spatial alignment.
- Re-recorded 7 clean sessions (42 episodes, 33,353 frames) in dataset `v2_combined`.
- Re-trained all policies, resulting in the validated v2 outcomes above.

---

## 3. Diffusion Sampling Acceleration Analysis

In standard rollout mode with DDPM (100 denoising steps), the real-robot control loop collapsed to **0.9 Hz** due to forward-pass computation latency, leading to aborted runs. 

Transitioning to DDIM (Denoising Diffusion Implicit Models) sampling yielded:
- **DDIM 10 steps:** ~7.8 Hz
- **DDIM 5 steps:** ~13–14.5 Hz (selected for final benchmark)
