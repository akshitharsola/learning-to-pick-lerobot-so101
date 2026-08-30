# Real-Robot Policy Evaluation & Deployment

This directory contains evaluation shell scripts, real-time asynchronous inference pipelines, frequency benchmarking utilities, and empirical result logs for evaluating trained policies on the physical **SO-101** robot arm.

---

## 1. Directory Structure

```
evaluation/
├── run_eval.sh                        # Unified entry point for running server and clients
├── async_smolvla_server.sh            # Asynchronous LeRobot PolicyServer (host 127.0.0.1:8080)
├── async_strawberry_client.sh         # RobotClient for multi-task strawberry harvesting
├── async_blacktip_client.sh           # RobotClient for bugfixed blue cube manipulation
├── eval_act.sh                        # ACT v2 policy evaluation script (lerobot-rollout)
├── eval_diffusion.sh                  # Diffusion Policy evaluation script (DDIM 5-step)
├── timing_check_blacktip.sh           # Sync control-loop Hz benchmark (blacktip model)
├── timing_check_strawberry.sh         # Sync control-loop Hz benchmark (strawberry model)
├── DEMO.md                            # Complete presentation walkthrough and talking points
├── eval_results.md                    # Baseline evaluation empirical results (ACT vs Diffusion)
└── eval_results_blacktip_strawberry.md # Final policy evaluation results (8/10 trials, 95% CI 49-94%)
```

---

## 2. Asynchronous Decoupled Inference Architecture

### Why Asynchronous Inference is Essential
When deploying Vision-Language-Action models such as **SmolVLA** (450M parameters), running standard synchronous rollout (`lerobot-rollout`) results in:
- Forward-pass inference latency of ~220 ms per step.
- Control loop throughput dropping to **~4.3–4.7 Hz**.
- Jerky, intermittent physical movement and high grasp failure rates.

### The LeRobot PolicyServer / RobotClient Solution
To decouple inference latency from the robot's control loop:
1. **`async_smolvla_server.sh`**: Runs in the background, computing action chunks asynchronously on the GPU.
2. **`async_strawberry_client.sh`**: Runs the robot control loop, pulling already-computed action chunks from the server queue as they become available rather than waiting on each inference call.
3. **Queue Thresholding**: Configured with `--chunk_size_threshold=0.3` and `--aggregate_fn_name=weighted_average` to smoothly blend successive overlapping action chunks without stalling the arm.

This architecture has no single fixed control-rate figure to report — that's the point: it isn't locked to one fixed rate the way the synchronous ACT (~25 Hz) and Diffusion Policy (~13 Hz) loops are (Section 7.4, thesis report).

---

## 3. Quick Start Guide

### Step 1: Start the Async Server (Terminal 1)
```bash
cd evaluation
./run_eval.sh server
```

### Step 2: Launch the Robot Client (Terminal 2)
```bash
cd evaluation
./run_eval.sh demo
```

To evaluate other models or tasks:
- `./run_eval.sh strawberry` — Strawberry harvesting task on `smolvla_mir1_strawberry`
- `./run_eval.sh strawberry-cube` — Cube regression check on `smolvla_mir1_strawberry`
- `./run_eval.sh blacktip` — Cube task on `smolvla_mir1_blacktip_fix`
- `./run_eval.sh act` — Baseline ACT v2 rollout
- `./run_eval.sh diffusion` — Accelerated Diffusion Policy rollout

---

## 4. Known Technical Gotchas & Solutions

### A. Hugging Face Config `pretrained_revision` Error
If loading a model straight from Hugging Face Hub produces:
```
draccus.utils.DecodingError: The fields 'pretrained_revision' are not valid for SmolVLAConfig
```
**Fix:** Download a local snapshot with `huggingface_hub.snapshot_download`, remove the `pretrained_revision` key from `config.json`, and pass the local directory path to `--pretrained_name_or_path`.

### B. USB Serial Port Permissions
If the robot fails to connect to `/dev/ttyACM0` or `/dev/ttyACM1`:
```bash
sudo chmod 666 /dev/ttyACM*
```
