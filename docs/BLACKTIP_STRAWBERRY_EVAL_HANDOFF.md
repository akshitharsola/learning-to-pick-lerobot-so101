# MajorProject — Black-tip-fix + Strawberry Fine-Tunes: Eval Handoff (2026-07-23)

Written on the Jetson AGX Orin (training machine) for whoever/whatever picks this up on the
recording desktop / University Lab machine (`robotics@brian-Vortex-ST-R` or equivalent, with
the physical SO-101 arms and cameras). Training for this round is done. This file covers
**real-robot evaluation** of the two new fine-tunes. Read `V2_EVAL_HANDOFF.md` first for the
original v2 eval context (camera fix, Hz measurement methodology, `pretrained_revision`
gotcha) — this file only covers what's new since then.

## Context: how we got here

- v2 training (ACT, Diffusion, SmolVLA on the original cube task) finished 2026-07-11 and was
  evaluated on the real robot — **SmolVLA came back good** (per informal report — no formal
  written eval doc for this round exists yet; if you have logged numbers from that session,
  add them here for the record). ACT/Diffusion results from that round: see `V2_EVAL_HANDOFF.md`.
- During v2 eval, a **gripper-release bug near white/black-tip contact areas** was found — the
  gripper wasn't releasing cleanly in that grasp region. Two small recording rounds
  (`blacktip_fix`, 12 ep + `cube_topup`, 6 ep) were captured to address it and aggregated with
  the original 42-ep v2 cube data.
- A **strawberry pick-and-place task** was also planned as a project extension. Real
  strawberries were tried for this but abandoned — the gripper crushed/tore the fruit both
  attempts, and a proper fix (soft-touch gripper fingertip) wasn't feasible in the project's
  timeframe. Reverted to a printed prop (marker-painted), recorded 3 clean sessions (24
  episodes) with a **hard grasp rule**: grasp only at the hook/stem area or the middle body,
  never the bottom tip (the original 18-ep batch's bottom-tip grasps were the slippage failure
  mode this rule is designed to avoid).

## What's done (as of 2026-07-23 01:39 BST)

### Datasets (all on HF, verified via `meta/info.json` + `meta/tasks.parquet`)

| Repo | Episodes | Frames | Task string(s) |
|---|---|---|---|
| `Akshit03/AkshitMajorProjectMIR1_v2_combined` | 42 | 33,353 | cube |
| `Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined` | 60 | 43,563 | cube (v2 + blacktip-fix + cube-topup) |
| `Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined` | 84 | 59,865 | cube + strawberry (blacktip-combined + 24 printed-strawberry eps) |

Task strings (byte-identical, confirmed via `meta/tasks.parquet` — exactly 1 entry in the
first two datasets, exactly 2 in the third):
- Cube: `"Pick up the blue block and place in the yellow bin"`
- Strawberry: `"Pick up the red strawberry and place in the yellow bin"`

**Not included anywhere**: the original 18-ep printed-strawberry batch (superseded by the new
24-ep batch with the grasp-point rule) and the 2-ep aborted real-strawberry session
(contaminated by the crushing failure mode, different visual domain). Neither is on HF under
an aggregated repo, only as raw per-session repos if you need to inspect them.

### Models (all pushed to HF, all SmolVLA, all continuing the same fine-tune chain from `smolvla_mir1_v2`)

| Hub repo | Base | Dataset | Steps | Wall-clock | Final loss | Tasks |
|---|---|---|---|---|---|---|
| `Akshit03/smolvla_mir1_v2` | `lerobot/smolvla_base` | v2_combined | 20,000 | 61h36m | 0.017 | cube only |
| `Akshit03/smolvla_mir1_blacktip_fix` | `smolvla_mir1_v2` | cube_blacktip_combined | 8,000 | 24.7h | 0.019 | cube only (bug fixed) |
| `Akshit03/smolvla_mir1_strawberry` | `smolvla_mir1_v2` | cube_strawberry_combined | 10,000 | 30.8h | 0.022 | cube + strawberry |

**Loss values are not comparable across rows** — same objective (SmolVLA flow-matching-style
loss) so *within* this table it's more meaningful than the cross-policy-type case in
`V2_EVAL_HANDOFF.md`, but still don't read too much into small differences; only real-robot
success rate is the real comparison. Note `smolvla_mir1_strawberry` was fine-tuned from
`smolvla_mir1_v2` directly (not chained through `smolvla_mir1_blacktip_fix`), but it still
*includes* the black-tip-fix + cube-topup episodes because they're baked into the
`cube_strawberry_combined` dataset it trained on — just not via the intermediate model
weights. Only ACT/Diffusion were skipped this round (deliberately — see rationale in the
original `JETSON_STRAWBERRY_TRAINING_HANDOFF.md` if present on this machine, or ask: adding a
new task to a from-scratch policy isn't a small fine-tune, it needs a full retrain, which
wasn't done).

## Next steps: real-robot eval

This is the actual deliverable — nothing above has been robot-validated yet for this round.

### 1. Cube regression check — `smolvla_mir1_blacktip_fix`

- 10 episodes, normal cube grasps, compare against the v2 baseline success rate.
- **Deliberately include some white-area/black-tip-contact grasp attempts** — don't just run
  normal episodes and hope the original bug doesn't recur. That's the actual thing this
  fine-tune was supposed to fix.

### 2. Strawberry + cube check — `smolvla_mir1_strawberry`

- Test strawberry pick-and-place specifically watching whether the policy learned the
  hook/middle grasp rule, or still attempts (and fails at) the bottom tip.
- Also re-run cube episodes on this same model as a second regression check (it's a different
  fine-tune branch than `blacktip_fix`, trained on a superset dataset, so it needs its own
  cube-task validation, not just an assumption it inherits `blacktip_fix`'s behavior).

### 3. Inference workflow

Use the **async inference workflow**, not `lerobot-rollout` (confirmed unusable for SmolVLA's
inference speed on this machine in the v2 round — see `V2_EVAL_HANDOFF.md`):
`eval_results/async_smolvla_server.sh` + `async_smolvla_client.sh`, `chunk_size_threshold=0.3`.
Point `--policy.path` at whichever of the two new Hub repos you're testing.

### 4. Known gotcha: `pretrained_revision` field mismatch

Same as prior rounds (see `V2_EVAL_HANDOFF.md` for full detail) — if pulling a model straight
from the Hub crashes on `draccus.utils.DecodingError: The fields 'pretrained_revision' are not
valid for SmolVLAConfig`, fix is: `snapshot_download` the model locally, strip
`pretrained_revision` from `config.json`, point `--policy.path` at the local directory instead.
Check this machine's LeRobot version matches the training version (0.5.2) first to avoid it
entirely.

### 5. HF auth note

If `hf auth whoami` fails here, note that `hf auth login` (no `--force`) only checks whether a
token file *exists*, not whether it's still valid server-side — use
`hf auth login --force` and paste a fresh **Write**-scope token if you hit an "Invalid user
token" error despite a token being present.

## What "success" means per episode

Same as prior rounds: manually judge/log pick-and-place success per episode. For strawberry
episodes specifically, also log *how* it failed if it does (missed grasp entirely vs. grasped
at the bottom tip and slipped vs. grasped correctly but dropped elsewhere) — that's the
diagnostic signal for whether the new grasp rule actually transferred to the policy.

## Deliverable

- Cube success rate for `smolvla_mir1_blacktip_fix` (10 eps, some deliberately at the
  previously-buggy contact area) vs. the v2 baseline.
- Cube success rate for `smolvla_mir1_strawberry` (regression check).
- Strawberry success rate for `smolvla_mir1_strawberry`, with grasp-point failure-mode notes.
- Achieved control Hz for both models (per `V2_EVAL_HANDOFF.md` methodology — measure before
  trusting the comparison).

## Checklist

- [x] Black-tip-fix + cube-topup recorded and aggregated → `cube_blacktip_combined` (60 ep)
- [x] Fine-tune SmolVLA on `cube_blacktip_combined` → `smolvla_mir1_blacktip_fix`
- [x] Strawberry (printed prop, hook/middle grasp rule) recorded, real-strawberry attempt
      abandoned
- [x] Aggregated → `cube_strawberry_combined` (84 ep)
- [x] Fine-tune SmolVLA on `cube_strawberry_combined` → `smolvla_mir1_strawberry`
- [ ] Verify camera mount / hardware setup still matches `V2_EVAL_HANDOFF.md`'s state
- [ ] Eval `smolvla_mir1_blacktip_fix`: cube regression + targeted black-tip-area grasps
- [ ] Eval `smolvla_mir1_strawberry`: strawberry grasp-rule adherence + cube regression
- [ ] Measure control Hz for both
- [ ] Write up final success-rate comparison + failure-mode notes
