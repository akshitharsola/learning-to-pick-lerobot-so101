#!/bin/bash
set -uo pipefail
cd /home/jetson-agx/MajorProject-25256470
source lerobot-env/bin/activate

DATASET=Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined
LOG_DIR=logs
mkdir -p "$LOG_DIR"
OUT_ROOT=/media/jetson-agx/SANDISK1/outputs/train/smolvla_mir1_blacktip_fix

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

ckpt_dir="$OUT_ROOT/checkpoints"
logfile="$LOG_DIR/smolvla_mir1_blacktip_fix.log"

echo ">>> Starting smolvla_mir1_blacktip_fix at $(date)"
df -h / /media/jetson-agx/SANDISK1 | tail -2

pruner_pid=$(start_pruner "$ckpt_dir" 1)
echo "  pruner pid=$pruner_pid keep=1 dir=$ckpt_dir"

t0=$(date +%s)
lerobot-train \
    --policy.type=smolvla \
    --policy.pretrained_path=Akshit03/smolvla_mir1_v2 \
    --dataset.repo_id="$DATASET" \
    --policy.device=cuda \
    --policy.repo_id=Akshit03/smolvla_mir1_blacktip_fix \
    --output_dir="$OUT_ROOT" \
    --job_name=smolvla_mir1_blacktip_fix \
    --batch_size=64 \
    --steps=8000 \
    --save_freq=500 \
    --policy.push_to_hub=true \
    --wandb.enable=false > "$logfile" 2>&1
rc=$?
t1=$(date +%s)

kill "$pruner_pid" 2>/dev/null
wait "$pruner_pid" 2>/dev/null

mins=$(( (t1 - t0) / 60 ))
echo ">>> Finished smolvla_mir1_blacktip_fix rc=$rc in ${mins}m at $(date)"
df -h / /media/jetson-agx/SANDISK1 | tail -2

final_loss=$(grep -oE "loss:[0-9.]+" "$logfile" | tail -1)
echo "SMOLVLA_BLACKTIP_FIX DONE rc=$rc mins=$mins final_loss=${final_loss:-n/a}"
