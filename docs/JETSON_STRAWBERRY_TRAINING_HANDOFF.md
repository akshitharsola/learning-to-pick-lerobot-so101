# Jetson AGX Orin — Strawberry Fine-Tune Handoff (2026-07-21)

Self-contained handoff for the training machine. Recording is done — this file covers
aggregation + fine-tuning only. Written for the Jetson AGX Orin (JetPack + CUDA, LeRobot
installed via `pip install -e ".[feetech]"`, HF login via `huggingface-cli login`).

## Background — why this dataset looks the way it does

- Real strawberries were tried twice and abandoned: the gripper crushed/tore the fruit
  skin both times. Proper fix (a soft-touch/rounded 3D-printed gripper fingertip) isn't
  feasible under the project's time constraint, per the professor. **Only 2 episodes of
  real-strawberry data exist** (`..._strawberry_real_session1_20260720_102702`, aborted
  early) — **do not include this in the training set**, it's contaminated by the
  crushing failure mode and is a different visual domain (real fruit vs. printed prop).
- Reverted to the original printed prop (marker-painted red body / green cap), scaled up
  from the original single 18-episode batch to **3 new sessions of 8 episodes each (24
  total)** recorded 2026-07-21 in `recording_sessions/strawberry_printed_v2/`.
- **Grasp rule enforced during this recording round (hard rule):** the bottom/tip of the
  strawberry is the slip zone — every episode grasps at the hook/stem area or the middle
  body only, never the bottom tip. This should make the new 24 episodes cleaner/more
  consistent than the original 18-episode batch, which had uncontrolled slippage on the
  bottom (discarded via re-record, but grasp point wasn't a controlled variable then).
- The **black-tip gripper-release bug fix is already done and merged** — do not redo it.
  `Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined` (60 episodes: original 42-ep v2
  cube data + 12 black-tip-fix eps + 6 cube-topup eps) already exists on HF and was
  presumably already used for a fine-tune (`Akshit03/smolvla_mir1_blacktip_fix`, per
  earlier project notes) — **this handoff builds on top of that combined cube dataset**,
  not the raw `v2_combined`.

## What's confirmed done (recording side, on `brian-Vortex-ST-R`)

All 3 new printed-prop strawberry sessions recorded, pushed to HF, verified via
`meta/info.json` — **24 episodes total**, all at 30 fps, single task string:

| Session | Repo | Episodes | Frames |
|---|---|---|---|
| printed_v2_1 | `Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session1_20260721_123935` | 8 | 5502 |
| printed_v2_2 | `Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session2_20260721_125019` | 8 | 5545 |
| printed_v2_3 | `Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session3_20260721_132013` | 8 | 5255 |

**Note the exact repo IDs include a timestamp suffix** (`lerobot-record` auto-appends
`_YYYYMMDD_HHMMSS`) — use the full IDs above in the aggregation step, not the plain
`_strawberry_printed_sessionN` names from the recording scripts.

Task string (byte-identical across all 3, confirmed via `meta/tasks.parquet`):
`"Pick up the red strawberry and place in the yellow bin"`

**Base dataset to combine with:** `Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined`
— 60 episodes, 43563 frames, task string `"Pick up the blue block and place in the yellow
bin"`. This already has the v2 cube data + black-tip-fix + cube-topup baked in.

---

## Step 1: Aggregate into one combined dataset

Run this on whichever machine has HF write access configured (Jetson or recording
desktop — only needs network access to HF, not the robot):

```bash
conda activate lerobot   # or your venv

python - <<'EOF'
from lerobot.common.datasets.aggregate import aggregate_datasets

repo_ids = [
    "Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined",
    "Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session1_20260721_123935",
    "Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session2_20260721_125019",
    "Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session3_20260721_132013",
]

aggregate_datasets(
    repo_ids=repo_ids,
    output_repo_id="Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined",
    push_to_hub=True,
)
EOF
```

Verify afterward in the combined repo's `meta/info.json`:
- `total_episodes` should read **84** (60 cube/blacktip + 24 strawberry)
- `total_frames` should read **59865** (43563 + 5502 + 5545 + 5255)
- `meta/tasks.parquet` should show **exactly 2 tasks** (the cube string and the
  strawberry string) — if it shows only 1 or more than 2, one of the task strings has a
  typo/extra-space mismatch somewhere; check before training.

---

## Step 2: Fine-tune SmolVLA from the existing checkpoint

**Continue from `Akshit03/smolvla_mir1_v2`** (the already-adapted v2 cube checkpoint), NOT
from `lerobot/smolvla_base` — this is a fine-tune-of-a-fine-tune, adding the strawberry
task on top of what's already learned, not starting over. This matches the plan already
recorded in project notes for the black-tip-fix round; same logic applies here.

```bash
cd ~/lerobot
python lerobot/scripts/train.py \
    --policy.path=Akshit03/smolvla_mir1_v2 \
    --dataset.repo_id=Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined \
    --output_dir=outputs/train/smolvla_mir1_strawberry \
    --job_name=smolvla_mir1_strawberry \
    --batch_size=64 \
    --steps=10000 \
    --policy.device=cuda \
    --wandb.enable=false
```

`--steps=10000` (half of the original 20000 v2 run) since this is a fine-tune on top of
an already-adapted checkpoint, matching the black-tip-fix round's reasoning. Adjust up if
loss is still dropping meaningfully at 10k steps.

**Only SmolVLA is planned for this round** — ACT and Diffusion are trained-from-scratch
policies, so "adding" the strawberry task to them isn't a small fine-tune the same way; it
would need a full combined-data retrain to avoid catastrophic forgetting of the cube task.
Not planned unless explicitly decided otherwise.

Push the fine-tuned model to HF when done, e.g. `Akshit03/smolvla_mir1_strawberry`, so the
recording desktop can pull it for real-robot eval without needing local Jetson checkpoints.

---

## Known issues from prior rounds to avoid repeating

### 1. Config field mismatch on policy load (`pretrained_revision`)
Pulling a model trained here straight from the Hub previously crashed on the eval machine
with `draccus.utils.DecodingError: The fields 'pretrained_revision' are not valid for
ACTConfig` — a version-compat quirk between training and eval LeRobot installs (both
should be v0.5.2, per project convention — do not upgrade). If this recurs:
`snapshot_download` the model locally, strip `pretrained_revision` from `config.json`,
point `--policy.path` at the local directory instead of the Hub repo ID.

### 2. Disk space during training
Prior Diffusion training run hit a mid-training disk-full crash on the Jetson (recovered
cleanly from checkpoint). Check free space before starting and periodically during,
clearing old `outputs/train/*` checkpoints from prior runs if tight. Less of a concern for
this SmolVLA-only round (smaller/fewer steps than the original Diffusion run) but still
worth a quick check.

### 3. Task-string exactness for aggregation
`aggregate_datasets` treats task strings as exact-match keys — a single extra space or
typo creates a duplicate task entry instead of merging. All 3 new strawberry sessions were
recorded from copy-pasted scripts (same `TASK_DESC` variable), so this should be fine, but
verify `meta/tasks.parquet` shows exactly 2 entries after aggregation (see Step 1).

---

## After training: send back to recording desktop for eval

Once the model is pushed to HF, hand back to whoever has robot access with:
- The Hub repo ID (e.g. `Akshit03/smolvla_mir1_strawberry`)
- Actual training time and final loss
- Confirmation of LeRobot version used for training, in case eval hits another
  `pretrained_revision`-style mismatch

Real-robot eval should specifically check:
1. Does the printed-prop strawberry get picked reliably (with the hook/middle grasp rule
   in mind — worth checking if the policy learned to avoid the bottom tip, or still
   attempts it and fails)
2. Is the cube task still working (regression check — compare against the
   `cube_blacktip_combined` baseline's own eval results if available)
3. Use the async inference workflow for eval, not `lerobot-rollout`
   (`lerobot-rollout` was confirmed unusable for SmolVLA's inference speed on this
   machine in the prior round) — `eval_results/async_smolvla_server.sh` +
   `async_smolvla_client.sh`, `chunk_size_threshold=0.3`, same as the v2 cube eval.
