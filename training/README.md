# Policy Training & Dataset Aggregation

This directory contains the Python aggregation scripts and shell automation runners for preparing datasets and training imitation-learning policies (**ACT**, **Diffusion Policy**, and **SmolVLA**) on an embedded **NVIDIA Jetson AGX Orin** workstation.

---

## 1. Overview of Scripts

### A. Dataset Aggregation Scripts
In LeRobot 0.5.2+, multi-session demonstration recordings stored on the Hugging Face Hub must be aggregated into consolidated dataset repositories before training.

| Script | Source Sessions / Datasets | Aggregated Output Dataset | Total Episodes / Frames |
|---|---|---|---|
| `aggregate_v2.py` | 7 v2 sessions (`session_v2_1` through `session_v2_7`) | `Akshit03/AkshitMajorProjectMIR1_v2_combined` | 42 episodes / 33,353 frames |
| `aggregate_blacktip_cube.py` | `v2_combined` + `blacktip_fix_session1` + `cube_topup_session1` | `Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined` | 60 episodes / 43,563 frames |
| `aggregate_strawberry.py` | `cube_blacktip_combined` + 3 printed strawberry sessions | `Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined` | 84 episodes / 59,865 frames |

**Aggregation Workflow in Code:**
1. Pre-downloads source datasets to cache via `LeRobotDataset(repo_id)`.
2. Consolidates episodes, timestamps, parquet tables, and video chunks via `aggregate_datasets()`.
3. Pushes aggregated dataset to Hugging Face Hub via `LeRobotDataset.push_to_hub()`.

---

### B. Training Automation Shell Scripts

| Script | Target Policy | Base Weights | Dataset Used | Steps | Batch Size | Wall Clock (Jetson) |
|---|---|---|---|:---:|:---:|:---:|
| `train_all_v2.sh` | ACT, Diffusion, SmolVLA | Scratch (ACT/Diff) / `lerobot/smolvla_base` | `v2_combined` | 30k / 30k / 20k | 8 / 8 / 64 | ~72h total sequence |
| `train_smolvla_only.sh` | SmolVLA (Baseline) | `lerobot/smolvla_base` | `v2_combined` | 20,000 | 64 | ~61h 36m |
| `train_smolvla_blacktip_fix.sh` | SmolVLA (Bugfix) | `Akshit03/smolvla_mir1_v2` | `cube_blacktip_combined` | 8,000 | 64 | ~24h 42m |
| `train_smolvla_strawberry.sh` | SmolVLA (Harvesting) | `Akshit03/smolvla_mir1_v2` | `cube_strawberry_combined` | 10,000 | 64 | ~30h 48m |

---

## 2. Embedded Resource Constraints & Background Pruner

### Jetson AGX Orin Disk Constraints
- The training Jetson AGX Orin possesses 59 GB of onboard eMMC storage (~5–8 GB free during active development).
- Checkpoint sizes:
  - **ACT:** ~198 MB / checkpoint
  - **SmolVLA:** ~1.5 GB / checkpoint
  - **Diffusion Policy:** ~3.2 GB / checkpoint (~16× ACT)

### Automated Background Pruner Function
To prevent mid-training out-of-disk crashes (encountered during early Diffusion runs), all shell runners integrate a concurrent background pruning daemon `start_pruner()`:

```bash
start_pruner() {
  local ckpt_dir="$1"
  local keep="$2"
  (
    while true; do
      sleep 15
      if [ -d "$ckpt_dir" ]; then
        mapfile -t dirs < <(ls -1 "$ckpt_dir" 2>/dev/null | grep -E "^[0-9]+$" | sort -n)
        count=${#dirs[@]}
        if [ "$count" -gt "$keep" ]; then
          n_remove=$((count - keep))
          for ((i=0; i<n_remove; i++)); do
            rm -rf "${ckpt_dir:?}/${dirs[$i]}"
          done
        fi
      fi
    done
  ) >/dev/null 2>&1 &
  echo $!
}
```
This daemon polls every 15 seconds, keeps only the latest $N$ checkpoints, and is cleanly terminated upon training completion.

---

## 3. How to Run Training

### Prerequisites
Activate the Jetson virtual environment with CUDA 13.2 support:
```bash
source ~/MajorProject-25256470/lerobot-env/bin/activate
hf auth whoami
```

### Run Multi-Task Strawberry Fine-Tuning
```bash
./train_smolvla_strawberry.sh
```
Logs are saved in real time to `logs/smolvla_mir1_strawberry.log` and the final checkpoint is pushed to Hugging Face Hub under `Akshit03/smolvla_mir1_strawberry`.
