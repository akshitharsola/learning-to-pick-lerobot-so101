# MajorProject — Next Steps (v2 campaign)

## Project Status (as of 2026-07-07)

### Why v2 exists
Sessions 1–10 (old data) and the two policies trained on them (`act_mir1` 1/10,
`diffusion_mir1` 4/10 real-robot success) are **invalid** — both showed the same
"approach good, grasp misses" failure. Root cause: the wrist camera mount had
physically shifted since sessions 4–10 were recorded. It's since been remounted to
a new position, confirmed via `diagnostics/live_camera_check.py` (Rerun viewer).
Since the geometry is genuinely different (not just re-aligned), old data/models
cannot be reused — full re-recording + re-training required. See
`eval_results/eval_results.md` for the full v1 failure log.

### What's done
- Wrist camera remounted + confirmed via live Rerun check (2026-07-06)
- v2 recording scripts ready: `recording_sessions/v2_current/record_session_v2_1.sh`
  through `_v2_7.sh` (6 episodes each, same task string, same device paths —
  `/dev/ttyACM0`=leader, `/dev/ttyACM1`=follower, `/dev/video0`=top, `/dev/video2`=wrist)
- Folder reorganized (2026-07-07): scripts/docs grouped by purpose — see repo root

- All 7 v2 sessions recorded and confirmed pushed to HF (2026-07-08), 42 episodes
  total — see `docs/JETSON_TRAINING_HANDOFF.md` for exact repo IDs and episode counts

### What's NOT done yet
- [ ] Aggregate v2 sessions into one combined HF dataset
- [ ] Train ACT, Diffusion, **and SmolVLA** on the v2 dataset (see
  `docs/JETSON_TRAINING_HANDOFF.md` — self-contained handoff for the Jetson,
  includes known issues from last round: Diffusion Policy real-time inference
  speed, the `pretrained_revision` config quirk, and disk space)
- [ ] Re-evaluate on real robot, confirm grasp failure is actually fixed
- [ ] Compare all three policies, pick one

---

## Phase 1: Record v2 sessions

Run each script in `recording_sessions/v2_current/` in order (v2_1 → v2_7) directly
in your own terminal (they need interactive `sudo` for serial permissions — don't
run via the assistant's Bash tool). Task string must stay byte-identical:
`"Pick up the blue block and place in the yellow bin"`.

---

## Phase 2: Aggregate v2 datasets

```bash
conda activate lerobot

python - <<'EOF'
from lerobot.common.datasets.aggregate import aggregate_datasets

repo_ids = [
    "Akshit03/AkshitMajorProjectMIR1_session_v2_1",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_2",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_3",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_4",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_5",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_6",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_7",
]

aggregate_datasets(
    repo_ids=repo_ids,
    output_repo_id="Akshit03/AkshitMajorProjectMIR1_v2_combined",
    push_to_hub=True,
)
EOF
```

**Do not mix with old session1-10 data** — different wrist camera geometry, would
corrupt the training set.

---

## Phase 3: Training on Jetson AGX Orin

### Option A: ACT (baseline, as before)
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

### Option B: Diffusion Policy (as before)
```bash
python lerobot/scripts/train.py \
    --dataset.repo_id=Akshit03/AkshitMajorProjectMIR1_v2_combined \
    --policy.type=diffusion \
    --output_dir=outputs/train/diffusion_mir1_v2 \
    --job_name=diffusion_mir1_v2 \
    --policy.device=cuda \
    --wandb.enable=false
```

### Option C: SmolVLA (new — professor's suggestion, worth trying this round)

SmolVLA (Hugging Face, 450M params) is pretrained on ~10M frames from real SO100/SO101
community datasets — same robot as ours. Instead of training from scratch on our ~42
episodes, it fine-tunes from that pretrained checkpoint, which tends to work much
better on small datasets than ACT/Diffusion-from-scratch. Reported ~78% success rate
on comparable SO101 pick-and-place tasks.

```bash
cd ~/lerobot
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

**Important:** use `--policy.path=lerobot/smolvla_base` (loads the pretrained
checkpoint), not `--policy.type=smolvla` alone (trains from scratch, loses the
pretraining benefit). Try this on the currently-installed LeRobot v0.5.2 first —
SmolVLA support should already be present since the checkpoint predates the v0.6.0
release. Only consider upgrading to v0.6.0 if this errors out (see note below).

### Note on LeRobot v0.6.0
Checked the v0.6.0 release blog (https://huggingface.co/blog/lerobot-release-v060).
It doesn't fix the `pretrained_revision` config bug we hit before (see
`eval_results` / phase4 eval memory), and mentions unspecified breaking changes.
**Not upgrading for now** — no clear benefit for this project, and risk of breaking
the working `lerobot-record`/`lerobot-rollout` scripts. Revisit only if SmolVLA
training fails on v0.5.2.

---

## Phase 4: Evaluation on real robot

Same process as before — see `eval_results/eval_act.sh` / `eval_diffusion.sh` as
templates (copy for a `eval_smolvla.sh`), using `lerobot-rollout --strategy.type=episodic`.
Remember the `pretrained_revision` field strip may be needed again for fresh
`snapshot_download`s — see phase4 eval notes.

Log per-episode success/fail in `eval_results/eval_results.md` (start a fresh v2
results table). This time, since the camera is fixed, watch specifically for whether
the "approach good, grasp misses" pattern is actually gone — that's the real signal
the fix worked, not just an overall success-rate bump.

---

## Checklist

- [x] Wrist camera remounted + confirmed
- [x] v2 recording scripts written
- [ ] Record v2 sessions 1–7 (42 episodes)
- [ ] Aggregate → `v2_combined`
- [ ] Train ACT v2
- [ ] Train Diffusion v2
- [ ] Train SmolVLA v2
- [ ] Evaluate all three on real robot
- [ ] Confirm grasp-failure pattern is resolved
- [ ] Compare and pick final policy
