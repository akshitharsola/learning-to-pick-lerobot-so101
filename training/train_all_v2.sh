#!/bin/bash
# Full v2 training pipeline: ACT -> Diffusion -> SmolVLA
# Runs unattended. Prunes checkpoints aggressively (disk-constrained Jetson, ~8GB free).
set -uo pipefail

cd /home/jetson-agx/MajorProject-25256470
source lerobot-env/bin/activate

DATASET=Akshit03/AkshitMajorProjectMIR1_v2_combined
LOG_DIR=logs
mkdir -p "$LOG_DIR"
SUMMARY="$LOG_DIR/SUMMARY.md"
echo "# v2 Training Summary" > "$SUMMARY"
echo "" >> "$SUMMARY"

start_pruner() {
  # $1 = checkpoints dir, $2 = keep count
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

run_stage() {
  local name="$1"; shift
  local ckpt_dir="$1"; shift
  local keep="$1"; shift
  local logfile="$LOG_DIR/${name}.log"

  echo ">>> Starting $name at $(date)"
  df -h / | tail -1

  pruner_pid=$(start_pruner "$ckpt_dir" "$keep")
  echo "  pruner pid=$pruner_pid keep=$keep dir=$ckpt_dir"

  t0=$(date +%s)
  "$@" > "$logfile" 2>&1
  rc=$?
  t1=$(date +%s)

  kill "$pruner_pid" 2>/dev/null
  wait "$pruner_pid" 2>/dev/null

  mins=$(( (t1 - t0) / 60 ))
  echo ">>> Finished $name rc=$rc in ${mins}m at $(date)"
  echo "## $name" >> "$SUMMARY"
  echo "- exit code: $rc" >> "$SUMMARY"
  echo "- wall clock: ${mins} min" >> "$SUMMARY"
  final_loss=$(grep -oE "loss:[0-9.]+" "$logfile" | tail -1)
  echo "- last logged loss: ${final_loss:-n/a}" >> "$SUMMARY"
  echo "- log: $logfile" >> "$SUMMARY"
  echo "" >> "$SUMMARY"

  return $rc
}

# ---------- A) ACT ----------
run_stage "act_mir1_v2" "outputs/train/act_mir1_v2/checkpoints" 2 \
  lerobot-train \
    --dataset.repo_id="$DATASET" \
    --policy.type=act \
    --policy.device=cuda \
    --policy.repo_id=Akshit03/act_mir1_v2 \
    --output_dir=outputs/train/act_mir1_v2 \
    --job_name=act_mir1_v2 \
    --batch_size=8 \
    --steps=30000 \
    --save_freq=5000 \
    --wandb.enable=false
act_rc=$?
rm -rf outputs/train/act_mir1_v2/checkpoints
df -h / | tail -1

# ---------- B) Diffusion ----------
run_stage "diffusion_mir1_v2" "outputs/train/diffusion_mir1_v2/checkpoints" 1 \
  lerobot-train \
    --dataset.repo_id="$DATASET" \
    --policy.type=diffusion \
    --policy.device=cuda \
    --policy.repo_id=Akshit03/diffusion_mir1_v2 \
    --output_dir=outputs/train/diffusion_mir1_v2 \
    --job_name=diffusion_mir1_v2 \
    --batch_size=8 \
    --steps=30000 \
    --save_freq=2000 \
    --wandb.enable=false
diffusion_rc=$?
rm -rf outputs/train/diffusion_mir1_v2/checkpoints
df -h / | tail -1

# ---------- C) SmolVLA ----------
run_stage "smolvla_mir1_v2" "outputs/train/smolvla_mir1_v2/checkpoints" 1 \
  lerobot-train \
    --policy.type=smolvla \
    --policy.pretrained_path=lerobot/smolvla_base \
    --dataset.repo_id="$DATASET" \
    --policy.device=cuda \
    --policy.repo_id=Akshit03/smolvla_mir1_v2 \
    --output_dir=outputs/train/smolvla_mir1_v2 \
    --job_name=smolvla_mir1_v2 \
    --batch_size=64 \
    --steps=20000 \
    --save_freq=1000 \
    --wandb.enable=false
smolvla_rc=$?
rm -rf outputs/train/smolvla_mir1_v2/checkpoints
df -h / | tail -1

echo "" >> "$SUMMARY"
echo "All stages done. rcs: act=$act_rc diffusion=$diffusion_rc smolvla=$smolvla_rc" >> "$SUMMARY"
echo "ALL DONE rcs: act=$act_rc diffusion=$diffusion_rc smolvla=$smolvla_rc"
