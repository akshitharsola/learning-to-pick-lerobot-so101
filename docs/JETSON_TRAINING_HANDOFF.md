# Jetson AGX Orin — Training Handoff (v2 dataset, 2026-07-08)

Self-contained handoff for the training machine. Recording is done — this file covers
aggregation + training only. Written for the Jetson AGX Orin (JetPack + CUDA, LeRobot
installed via `pip install -e ".[feetech]"`, HF login via `huggingface-cli login`).

## What's confirmed done (recording side, on `brian-Vortex-ST-R`)

All 7 v2 sessions recorded, pushed to HF, verified via `meta/info.json` — **42 episodes total**,
all at 30 fps, consistent with plan:

| Session | Repo | Episodes | Frames |
|---|---|---|---|
| v2_1 | `Akshit03/AkshitMajorProjectMIR1_session_v2_1_20260707_120045` | 6 | 5257 |
| v2_2 | `Akshit03/AkshitMajorProjectMIR1_session_v2_2_20260707_121251` | 6 | 5541 |
| v2_3 | `Akshit03/AkshitMajorProjectMIR1_session_v2_3_20260707_122734` | 6 | 5071 |
| v2_4 | `Akshit03/AkshitMajorProjectMIR1_session_v2_4_20260707_125144` | 6 | 4646 |
| v2_5 | `Akshit03/AkshitMajorProjectMIR1_session_v2_5_20260708_123730` | 6 | 5112 |
| v2_6 | `Akshit03/AkshitMajorProjectMIR1_session_v2_6_20260708_131229` | 6 | 3804 |
| v2_7 | `Akshit03/AkshitMajorProjectMIR1_session_v2_7_20260708_132934` | 6 | 3922 |

**Note the exact repo IDs include a timestamp suffix** (`lerobot-record` auto-appends
`_YYYYMMDD_HHMMSS`) — use the full IDs above in the aggregation step, not the plain
`_session_v2_N` names from the recording scripts.

**Why this is v2 and not a continuation of the old sessions 1-10:** the wrist camera
mount had physically shifted sometime after the original session 4-10 recordings,
which silently broke the close-range depth cue used for the final grasp. Both policies
trained on the old data failed on real-robot eval in the exact same way (see below).
The camera has since been remounted to a new position and confirmed via live check —
**do not aggregate v2 data with old session1-10 data**, the camera geometry is genuinely
different and mixing them would corrupt the training set.

---

## Step 1: Aggregate the 7 sessions into one dataset

Run this on whichever machine has HF write access configured (can be done on the
Jetson or the recording desktop — it only needs network access to HF, not the robot):

```bash
conda activate lerobot   # or your venv

python - <<'EOF'
from lerobot.common.datasets.aggregate import aggregate_datasets

repo_ids = [
    "Akshit03/AkshitMajorProjectMIR1_session_v2_1_20260707_120045",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_2_20260707_121251",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_3_20260707_122734",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_4_20260707_125144",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_5_20260708_123730",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_6_20260708_131229",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_7_20260708_132934",
]

aggregate_datasets(
    repo_ids=repo_ids,
    output_repo_id="Akshit03/AkshitMajorProjectMIR1_v2_combined",
    push_to_hub=True,
)
EOF
```

Verify afterward: `total_episodes` should read 42 in the combined repo's `meta/info.json`,
and there should be exactly **one** task entry (not two/three) — if `aggregate_datasets`
created duplicate task entries, one of the 7 scripts had a non-identical task string
(extra space, typo). Check `meta/tasks.jsonl` if in doubt.

---

## Step 2: Train — three policies, in this order

Use `--dataset.repo_id=Akshit03/AkshitMajorProjectMIR1_v2_combined` for all three below.

### A) ACT (fast baseline, train first)
```bash
cd ~/lerobot
python lerobot/scripts/train.py \
    --dataset.repo_id=Akshit03/AkshitMajorProjectMIR1_v2_combined \
    --policy.type=act \
    --output_dir=outputs/train/act_mir1_v2 \
    --job_name=act_mir1_v2 \
    --policy.device=cuda \
    --wandb.enable=false
```
Expect ~3-6h on the Orin (was ~7.3h at 30k steps last time — similar dataset size).

### B) Diffusion Policy
```bash
python lerobot/scripts/train.py \
    --dataset.repo_id=Akshit03/AkshitMajorProjectMIR1_v2_combined \
    --policy.type=diffusion \
    --output_dir=outputs/train/diffusion_mir1_v2 \
    --job_name=diffusion_mir1_v2 \
    --policy.device=cuda \
    --wandb.enable=false
```
Expect ~8-16h (was ~10.5h last time). **Watch disk space** — last run hit a mid-training
disk-full crash on the Jetson (recovered fine from checkpoint, but check free space
before starting and periodically during, since checkpoints accumulate).

### C) SmolVLA — new this round, professor's suggestion
```bash
python lerobot/scripts/train.py \
    --policy.path=lerobot/smolvla_base \
    --dataset.repo_id=Akshit03/AkshitMajorProjectMIR1_v2_combined \
    --output_dir=outputs/train/smolvla_mir1_v2 \
    --job_name=smolvla_mir1_v2 \
    --batch_size=64 \
    --steps=20000 \
    --policy.device=cuda \
    --wandb.enable=false
```
**Use `--policy.path=lerobot/smolvla_base`, not `--policy.type=smolvla`** — the former
loads HF's pretrained checkpoint (450M params, pretrained on ~10M frames from real
SO100/SO101 community datasets) and fine-tunes it on our 42 episodes; the latter trains
from scratch and throws away the pretraining benefit, defeating the point. This should
work on the currently-installed LeRobot v0.5.2 — no need to upgrade for SmolVLA support.
If `--policy.path=lerobot/smolvla_base` errors out on this install, that's the one
scenario where upgrading LeRobot might be worth revisiting (checked v0.6.0's release
notes already — nothing else in it looked worth the upgrade risk for this project).

Push all three trained models to HF when done (e.g. `Akshit03/act_mir1_v2`,
`Akshit03/diffusion_mir1_v2`, `Akshit03/smolvla_mir1_v2`) so the recording desktop can
pull them for real-robot eval without needing the Jetson's local checkpoints.

---

## Known issues from last round to avoid repeating

### 1. Diffusion Policy real-time control rate (the main one)
On the recording desktop (RTX 3060 Ti), running Diffusion Policy inference for real-robot
rollout with default settings (DDPM, 100 inference steps) dropped the control loop to
**0.9 Hz** against a 30 Hz target — nowhere near usable for real-time control, had to
abort. Switching to DDIM sampling helped a lot but not fully:
- DDIM 10 steps → ~7.8 Hz
- DDIM 5 steps → ~12-14 Hz (this is what we evaluated with — got 4/10 success)

This is an **inference-time / rollout-time** issue, not a training bug, so nothing to
fix in the training commands above. But it's worth doing differently this round since
it affects how fairly Diffusion can be judged against ACT (~25 Hz) and SmolVLA (unknown
yet, should be measured on the Jetson/eval machine before the real comparison):
- Consider training/exporting the Diffusion policy with fewer default inference steps
  baked into `train_config.json`/`policy_preprocessor.json` if there's a config knob for
  it, rather than only tuning DDIM steps at rollout time.
- If SmolVLA also turns out to have a slow inference path (flow-matching action expert —
  check this before eval day), the same DDIM-style step-reduction approach may need
  revisiting for it too. Worth a quick timing check on whatever machine will run the
  real-robot rollout, before committing to a full 10-episode eval run.
- **When comparing final success rates across all 3 policies, note the actual control
  Hz each one ran at** — a policy at a lower Hz has a real disadvantage and that should
  be caveated in the final write-up, not just the raw success count.

### 2. Config field mismatch on policy load (`pretrained_revision`)
Pulling a model trained here straight from the Hub (`--policy.path=Akshit03/act_mir1`)
previously crashed on the eval machine with:
```
draccus.utils.DecodingError: The fields `pretrained_revision` are not valid for ACTConfig
```
Cause: whatever LeRobot version does the training writes a `pretrained_revision` key into
`config.json` that the eval machine's installed `ACTConfig`/`DiffusionConfig` (v0.5.2)
doesn't declare, and its strict decoder rejects unknown fields.
**If this happens again on the eval side:** `snapshot_download` the model locally, strip
`pretrained_revision` from `config.json` with a one-line Python fix, then point
`--policy.path` at the local directory instead of the Hub repo ID. This has nothing to
do with training quality — purely a version-compat quirk between the training and eval
LeRobot installs. Worth checking whether Jetson and eval-machine LeRobot versions match
before training, if there's an easy way to sync them — would avoid this step entirely.

### 3. Disk space during Diffusion training
Noted above — last Diffusion run had a mid-training disk-full crash on the Jetson.
Recovered cleanly from checkpoint that time, but worth checking free space on the Jetson
before kicking off Diffusion/SmolVLA training this round, and clearing old
`outputs/train/*` checkpoints from prior runs if space is tight.

### 4. The actual root cause of last round's poor results — NOT a training issue
Worth stating clearly so it isn't re-investigated as a training problem: last round's
poor real-robot results (ACT 1/10, Diffusion 4/10) were traced to a **physically shifted
wrist camera mount**, not insufficient data or a training/hyperparameter problem. Both
policies failed in the identical way — good approach, missed grasp — which pointed at
the shared close-range visual input (wrist cam) rather than either policy's training.
The camera has been remounted and this v2 dataset was recorded after that fix. If v2
eval results are still poor in the same "approach good, grasp misses" pattern, that
would be a real signal to look at training/data again — but if it's a *different*
failure pattern this time, treat it as a new problem, not evidence the camera fix failed.

---

## After training: send back to recording desktop for eval

Once all 3 models are pushed to HF, hand back to whoever has robot access with:
- The 3 Hub repo IDs (e.g. `Akshit03/act_mir1_v2`, `_diffusion_mir1_v2`, `_smolvla_mir1_v2`)
- Actual training time and final loss for each (loss values are not comparable
  across policy types — ACT uses action L1, Diffusion uses noise-prediction MSE,
  SmolVLA likely something else again — don't rank policies by loss, only by
  real-robot success rate)
- Confirmation of which LeRobot version (and any config quirks) was used for training,
  in case eval hits another `pretrained_revision`-style mismatch

Real-robot eval process itself is unchanged: `lerobot-rollout --strategy.type=episodic`
(NOT `lerobot-record` — no `--policy.path` flag on that in v0.5.2), 10 episodes per
policy, manual success/fail logging since there's no built-in keyboard marking for it.
