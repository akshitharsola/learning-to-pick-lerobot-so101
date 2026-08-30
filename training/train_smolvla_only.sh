#!/bin/bash
set -uo pipefail
cd /home/jetson-agx/MajorProject-25256470
source lerobot-env/bin/activate

DATASET=Akshit03/AkshitMajorProjectMIR1_v2_combined
LOG_DIR=logs
SUMMARY="$LOG_DIR/SUMMARY.md"

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

ckpt_dir="outputs/train/smolvla_mir1_v2/checkpoints"
logfile="$LOG_DIR/smolvla_mir1_v2.log"

echo ">>> Starting smolvla_mir1_v2 (retry) at $(date)"
df -h / | tail -1

pruner_pid=$(start_pruner "$ckpt_dir" 1)
echo "  pruner pid=$pruner_pid keep=1 dir=$ckpt_dir"

t0=$(date +%s)
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
    --wandb.enable=false > "$logfile" 2>&1
rc=$?
t1=$(date +%s)

kill "$pruner_pid" 2>/dev/null
wait "$pruner_pid" 2>/dev/null

mins=$(( (t1 - t0) / 60 ))
echo ">>> Finished smolvla_mir1_v2 rc=$rc in ${mins}m at $(date)"

rm -rf outputs/train/smolvla_mir1_v2/checkpoints
df -h / | tail -1

final_loss=$(grep -oE "loss:[0-9.]+" "$logfile" | tail -1)

# Replace the smolvla section in SUMMARY.md
python3 - "$SUMMARY" "$rc" "$mins" "${final_loss:-n/a}" "$logfile" <<'PYEOF'
import sys
summary_path, rc, mins, loss, logfile = sys.argv[1:6]
with open(summary_path) as f:
    content = f.read()

marker = "## smolvla_mir1_v2"
idx = content.find(marker)
new_section = f"""## smolvla_mir1_v2
- exit code: {rc}
- wall clock: {mins} min
- last logged loss: {loss}
- log: {logfile}
"""
if idx != -1:
    # find end of this section (next "## " or end of "All stages done" line or EOF)
    end_markers = ["\n## ", "\nAll stages done"]
    end = len(content)
    for m in end_markers:
        pos = content.find(m, idx + len(marker))
        if pos != -1:
            end = min(end, pos)
    content = content[:idx] + new_section + content[end:]
else:
    content += "\n" + new_section

with open(summary_path, "w") as f:
    f.write(content)
PYEOF

echo "SMOLVLA RETRY DONE rc=$rc"
