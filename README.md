# Learning to Pick: Robotic Strawberry Harvesting
### An Imitation-Learning Pick-and-Place System on the LeRobot SO-101

[![University of Galway](https://img.shields.io/badge/University_of_Galway-EE5111_Major_Project-800000?style=for-the-badge)](https://www.universityofgalway.ie/)
[![LeRobot 0.5.2](https://img.shields.io/badge/HuggingFace-LeRobot_v0.5.2-FFA000?style=for-the-badge&logo=huggingface)](https://github.com/huggingface/lerobot)
[![HuggingFace Models](https://img.shields.io/badge/HF_Hub-Akshit03_Models-FFD21E?style=for-the-badge&logo=huggingface)](https://huggingface.co/Akshit03)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

---

## 📌 Executive Summary

This repository contains the complete software pipeline, training orchestration scripts, teleoperation recording workflows, and real-time evaluation infrastructure for the **EE5111 Intelligent Robotics Major Project**:
> **"Learning to Pick: Robotic Strawberry Harvesting — An Imitation-Learning Pick-and-Place System on the LeRobot SO-101"**  
> **Author:** Akshit Harsola (Student ID: 25256470)  
> **Supervisor:** Dr. Brian Deegan  
> **Institution:** School of Engineering, University of Galway  
> **Submission Date:** August 2026  

📄 **[Read the full thesis report (PDF)](thesis.pdf)**

The project explores multi-modal imitation learning for fine-manipulation harvesting tasks using low-cost open-source hardware. We conduct a rigorous comparative study across three state-of-the-art imitation learning paradigms:
1. **Action Chunking with Transformers (ACT)** (Trained from scratch)
2. **Diffusion Policy** (Trained from scratch, accelerated with 5-step DDIM sampling)
3. **SmolVLA** (450M-parameter Vision-Language-Action foundation model, fine-tuned from `lerobot/smolvla_base`)

Through a staged fine-tuning paradigm combined with a decoupled asynchronous inference architecture, the final multi-task **SmolVLA** model achieved an **80% success rate (8/10 trials, 95% Wilson CI approximately 49–94%)** on the physical strawberry pick-and-place task, meeting the original proposal's own ≥80% pick-success target on the descoped system. Both observed failures fell in the known bottom-tip slip zone.

```
                  ┌────────────────────────────────────────────────────────┐
                  │                 DUAL CAMERA PERCEPTION                 │
                  │   Top Overhead (Logitech C170) + Wrist Inverted (180°) │
                  └───────────────────────────┬────────────────────────────┘
                                              │ RGB Frames (640x480 @ 30 FPS)
                                              ▼
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                           ASYNC POLICY SERVER (GPU / CUDA)                                │
│                                                                                           │
│   Task Prompt: "Pick up the red strawberry and place in the yellow bin"                   │
│                                              │                                            │
│                      ┌───────────────────────┴───────────────────────┐                    │
│                      │   SmolVLA 450M Vision-Language-Action Policy  │                    │
│                      │  (VLM Backbone + Flow-Matching Action Chunk)  │                    │
│                      └───────────────────────┬───────────────────────┘                    │
│                                              │ Action Chunks (50 steps)                   │
└──────────────────────────────────────────────┼────────────────────────────────────────────┘
                                               │ ZeroMQ / TCP Local Socket (127.0.0.1:8080)
                                               ▼
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                     ROBOT CLIENT (ASYNC CONTROL LOOP, NO FIXED RATE)                      │
│                                                                                           │
│       Action Buffer: Chunk Threshold (0.3) + Weighted Averaging Blend                     │
│                                              │                                            │
│                                              ▼                                            │
│                 SO-101 Follower Arm (6-DoF Feetech STS3215 Bus Servos)                   │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏆 Key Experimental Results

### v1 Real-Robot Evaluation (Blue Cube Pick & Place)
The project's first demonstration dataset (v1) produced poor real-robot results, later root-caused to a physically shifted wrist-camera mount rather than a training or data-quality problem:

| Policy | Result | Observed Failure Pattern |
|---|:---:|---|
| ACT | 1 / 10 | Approach good, grasp does not close correctly |
| Diffusion Policy (DDIM-5, ~12–14 Hz) | 4 / 10 | Same pattern, less consistently than ACT |

After the camera fix, all three policies were retrained on the v2 dataset (42 episodes). **No formal per-episode success/failure table was logged for the v2 round** — that gap is stated plainly here rather than filled with an invented number (see the thesis report, Section 9.2).

### Final Evaluation (Strawberry Pick & Place)
The final, staged-fine-tuned **SmolVLA** model (`smolvla_mir1_strawberry`) was evaluated on ten formal trials after the last fine-tuning round:

| Metric | Value |
|---|:---:|
| **Success rate** | 8 / 10 (80%) |
| **95% Wilson score CI** | [49%, 94%] |
| **Control architecture** | Asynchronous (decoupled, no fixed rate) |
| **Failure mode** | Both failures: grasp attempted in the known bottom-tip slip zone |

> This is reported as a **pilot-scale result, not a validated benchmark** — a claim intended to stand as a benchmark-grade figure would need on the order of 50–100+ trials to meaningfully narrow this interval. See the thesis report, Section 10.3 and Section 14.2, and `evaluation/eval_results_blacktip_strawberry.md` in this repository.

---

## 📦 Hugging Face Hub Model & Dataset Registry

All model checkpoints and datasets are published under the [`Akshit03`](https://huggingface.co/Akshit03) namespace on Hugging Face Hub:

### Trained Model Checkpoints
| Model Name | Hugging Face Repository | Tasks Supported | Base Checkpoint | Training Dataset |
|---|---|---|---|---|
| **SmolVLA Strawberry (Final)** | [`Akshit03/smolvla_mir1_strawberry`](https://huggingface.co/Akshit03/smolvla_mir1_strawberry) | 🍓 Strawberry + 🟦 Cube | `smolvla_mir1_v2` | `cube_strawberry_combined` (84 ep) |
| **SmolVLA Blacktip Fix** | [`Akshit03/smolvla_mir1_blacktip_fix`](https://huggingface.co/Akshit03/smolvla_mir1_blacktip_fix) | 🟦 Cube (Bugfixed Release) | `smolvla_mir1_v2` | `cube_blacktip_combined` (60 ep) |
| **SmolVLA v2 Baseline** | [`Akshit03/smolvla_mir1_v2`](https://huggingface.co/Akshit03/smolvla_mir1_v2) | 🟦 Cube Baseline | `lerobot/smolvla_base` | `v2_combined` (42 ep) |
| **Diffusion Policy v2** | [`Akshit03/diffusion_mir1_v2`](https://huggingface.co/Akshit03/diffusion_mir1_v2) | 🟦 Cube Baseline | From Scratch | `v2_combined` (42 ep) |
| **ACT v2** | [`Akshit03/act_mir1_v2`](https://huggingface.co/Akshit03/act_mir1_v2) | 🟦 Cube Baseline | From Scratch | `v2_combined` (42 ep) |

### Demonstration Datasets
| Dataset Name | Hugging Face Repository | Episodes | Frames | Description |
|---|---|:---:|:---:|---|
| **Cube + Strawberry Combined** | [`Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined`](https://huggingface.co/datasets/Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined) | 84 | 59,865 | Complete multi-task dataset (v2 + bugfix + strawberry) |
| **Cube Blacktip Combined** | [`Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined`](https://huggingface.co/datasets/Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined) | 60 | 43,563 | Cube manipulation with contact-area release coverage |
| **v2 Combined Baseline** | [`Akshit03/AkshitMajorProjectMIR1_v2_combined`](https://huggingface.co/datasets/Akshit03/AkshitMajorProjectMIR1_v2_combined) | 42 | 33,353 | Standard blue cube demonstration baseline (7 sessions) |

---

## 📂 Repository Structure

```
├── README.md                          # Main project overview, architecture, and reproduction guide
├── requirements.txt                   # Pinned project dependencies
│
├── training/                          # Training pipelines & dataset aggregation
│   ├── README.md                      # Detailed training documentation & hyperparameters
│   ├── aggregate_v2.py                # Aggregates 7 baseline sessions into v2_combined
│   ├── aggregate_blacktip_cube.py     # Aggregates v2 with blacktip bugfix sessions
│   ├── aggregate_strawberry.py        # Aggregates cube datasets with strawberry sessions
│   ├── train_all_v2.sh                # End-to-end Jetson runner for ACT, Diffusion & SmolVLA
│   ├── train_smolvla_only.sh          # SmolVLA v2 baseline training runner
│   ├── train_smolvla_blacktip_fix.sh  # SmolVLA Round 3 (bugfix) fine-tuning runner
│   └── train_smolvla_strawberry.sh    # SmolVLA Round 4 (strawberry multi-task) fine-tuning runner
│
├── recording/                         # Teleoperated demonstration collection
│   ├── README.md                      # Hardware setup, leader-follower teleop, and camera calibration
│   └── recording_sessions/
│       ├── v1_deprecated/             # Early sessions (retained for failure analysis of camera shift)
│       └── v2_current/                # Validated sessions 1–7 used for final dataset
│
├── evaluation/                        # Real-robot deployment & benchmarking
│   ├── README.md                      # Evaluation architecture & async server-client guide
│   ├── run_eval.sh                    # Unified evaluation launcher script
│   ├── async_smolvla_server.sh        # Asynchronous PolicyServer runner
│   ├── async_strawberry_client.sh     # Asynchronous harvesting RobotClient
│   ├── async_blacktip_client.sh       # Asynchronous cube bugfix RobotClient
│   ├── eval_act.sh                    # ACT rollout evaluation script
│   ├── eval_diffusion.sh              # Diffusion Policy (DDIM 5-step) evaluation script
│   ├── timing_check_blacktip.sh       # Frequency benchmarking utility (blacktip model)
│   ├── timing_check_strawberry.sh     # Frequency benchmarking utility (strawberry model)
│   ├── DEMO.md                        # Step-by-step live presentation guide
│   ├── eval_results.md                # Empirical results log for baseline policies
│   └── eval_results_blacktip_strawberry.md # Empirical results log for final staged fine-tunes
│
├── diagnostics/                       # Hardware validation tools
│   ├── README.md                      # Diagnostic instructions & Rerun setup
│   └── live_camera_check.py           # Headless dual-camera stream visualizer using Rerun
│
└── docs/                              # Engineering handover logs & technical context
    ├── README.md                      # Documentation index and summary
    ├── PROJECT_MEMORY_SUMMARY.md      # Consolidated technical memory from Jetson AGX Orin
    ├── JETSON_TRAINING_HANDOFF.md     # Jetson training handoff protocol (Phase 2)
    ├── JETSON_STRAWBERRY_TRAINING_HANDOFF.md # Strawberry training handoff protocol (Phase 3)
    ├── V2_EVAL_HANDOFF.md             # Real-robot evaluation protocol (Phase 2)
    └── BLACKTIP_STRAWBERRY_EVAL_HANDOFF.md # Staged evaluation handoff protocol (Phase 3)
```

---

## 🚀 Quick Reproduction Guide

### 1. Environment Setup
Clone the repository and install dependencies in a conda environment:
```bash
git clone https://github.com/akshitharsola/learning-to-pick-lerobot-so101.git
cd learning-to-pick-lerobot-so101

conda create -n lerobot python=3.10 -y
conda activate lerobot

# Install PyTorch matching your CUDA version
pip install torch==2.2.1 torchvision==0.17.1 --index-url https://download.pytorch.org/whl/cu121

# Install LeRobot v0.5.2 and project dependencies
pip install -e ".[feetech,smolvla]"
pip install -r requirements.txt
```

### 2. Hardware Sanity Check
Connect the USB cameras and verify the optical alignment using the Rerun diagnostic tool:
```bash
python diagnostics/live_camera_check.py
```

### 3. Running Live Evaluation (Two Terminals)

**Terminal 1 (Start Policy Server):**
```bash
cd evaluation
./run_eval.sh server
```

**Terminal 2 (Start Harvesting Demo):**
```bash
cd evaluation
./run_eval.sh demo
```

---

## 🛠️ Engineering Innovations & Technical Solutions

1. **Overcoming VLA Latency via Decoupled Asynchronous Execution:**  
   Direct synchronous rollout of SmolVLA (`lerobot-rollout`) on the evaluation hardware was measured at only ~4.3–4.7 Hz, unusable for live control. Using LeRobot's asynchronous PolicyServer/RobotClient workflow instead (`chunk_size_threshold=0.3`) decouples inference from the control loop entirely — actions are queued and blended rather than the robot waiting on each forward pass, so there is no single fixed control-rate figure to report for this policy (Section 7.4, thesis report).

2. **Diffusion Sampling Acceleration:**  
   Standard DDPM sampling (100 denoising steps) collapsed real-time control to **0.9 Hz**. By re-configuring inference to 5-step DDIM (Denoising Diffusion Implicit Models), loop frequency rose to **13.5 Hz**, boosting grasp success from 10% to 70%.

3. **Staged Fine-Tuning & Grasp Heuristic Transfer:**  
   Real strawberries were tried and abandoned after the gripper crushed or tore the fruit on contact; a compliant gripper fingertip was judged infeasible within the project's remaining time. The project reverted to a printed strawberry prop, paired with a hard grasp rule enforced during recording (grasp only at the stem/hook or mid-body, never the bottom tip — the prop's known slip zone). The final evaluation's two failures both fell in that excluded zone, suggesting the policy learned most of the intended grasp-point behaviour, with one narrow, repeatable residual failure mode rather than failures spread unpredictably.

4. **Embedded Resource Management:**  
   Training large diffusion policies on the Jetson AGX Orin (~8 GB free eMMC) risked out-of-disk crashes. We implemented an automated background pruner daemon polling every 15 seconds to safely bound local storage while streaming checkpoints to Hugging Face Hub.

---

## 📜 Citation & Academic Attribution

If you find this work or codebase helpful in your research, please cite:

```bibtex
@mastersthesis{harsola2026learningtopick,
  author       = {Akshit Harsola},
  title        = {Learning to Pick: Robotic Strawberry Harvesting --- An Imitation-Learning Pick-and-Place System on the LeRobot SO-101},
  school       = {School of Engineering, University of Galway},
  year         = {2026},
  month        = {August},
  note         = {Supervisor: Dr. Brian Deegan. Major Project Report for EE5111 Intelligent Robotics Project}
}
```

---

## 🤝 Acknowledgments
- **Supervisor:** Dr. Brian Deegan (University of Galway) for guidance and project direction.
- **Hugging Face LeRobot Team:** For the open-source LeRobot framework and SmolVLA base model.
- **Feetech & The SO-100/SO-101 Open Source Robotics Community.**
