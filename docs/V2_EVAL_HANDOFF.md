# MajorProject v2 — Real-Robot Evaluation Handoff (2026-07-11)

Written on the Jetson AGX Orin (training machine) for whoever/whatever picks this up on the
recording desktop (`robotics@brian-Vortex-ST-R`, the machine with the physical SO-101 arms
and cameras). Training is done. This file covers **Phase 4: real-robot evaluation** of the
v2 policies. Read `NEXT_STEPS.md` and `EVAL_NEXT_STEPS.md` too for original hardware/camera
setup context — this file only covers what changed for v2 and the eval plan itself.

## What's done (v2 round, as of 2026-07-11 19:03)

Root cause of v1's poor eval results (ACT 1/10, Diffusion 4/10) was a **physically shifted
wrist camera mount**, not a training/data problem — both v1 policies failed identically
(good approach, missed grasp). The camera has since been remounted and confirmed via live
check. 7 new recording sessions (42 episodes, 33,353 frames, 30fps) were captured after the
fix and aggregated into `Akshit03/AkshitMajorProjectMIR1_v2_combined`. All 3 policies below
are trained on this v2 dataset and confirmed live on the Hub:

| Policy | Steps | Final training loss | Wall-clock (Jetson) | Hub repo |
|---|---|---|---|---|
| ACT | 30,000 | 0.099 | 5h08m | `Akshit03/act_mir1_v2` |
| Diffusion Policy | 30,000 | 0.007 | 6h37m | `Akshit03/diffusion_mir1_v2` |
| SmolVLA | 20,000 (fine-tuned from `lerobot/smolvla_base`) | 0.017 | 61h36m | `Akshit03/smolvla_mir1_v2` |

**These loss numbers are NOT comparable to each other** — ACT uses action L1 loss, Diffusion
uses noise-prediction MSE, SmolVLA uses its own flow-matching-style objective. Do not
conclude anything about relative quality from these numbers ("Diffusion's 0.007 beats ACT's
0.099" is meaningless — different scales entirely). **The only meaningful comparison is
real-robot success rate**, which is what this phase produces.

SmolVLA is new this round (v1 only had ACT + Diffusion) — professor's suggestion, fine-tuned
from HF's pretrained SmolVLM2-based checkpoint (450M params, ~10M frames of prior SO100/SO101
community data) rather than trained from scratch, so it should have a head start on
generalization even with only 42 episodes of task-specific data.

## Corrections vs. NEXT_STEPS.md / EVAL_NEXT_STEPS.md

Same fast-moving-repo caveat as before — check the installed LeRobot version's own
`AGENT_GUIDE.md`/`AGENTS.md` before trusting exact flag names here, but as of the version
used for v2 training (0.5.2):

- `lerobot-record` (not `lerobot-eval`, not the old `eval.py`) is used to run a trained
  policy live and record the resulting rollout — same as v1.
- `--policy.path` should point at the **Hub repo directly** (e.g. `Akshit03/act_mir1_v2`),
  not a local checkpoint path — checkpoints only existed transiently on the Jetson and were
  deleted after each push to save disk (checkpoint pruning was aggressive this round due to
  a persistently tight ~5-8GB free disk budget on the Jetson).

### Known gotcha: `pretrained_revision` field mismatch

v1 hit this on the eval machine:
```
draccus.utils.DecodingError: The fields `pretrained_revision` are not valid for ACTConfig
```
Cause: the training-side LeRobot version writes a `pretrained_revision` key into
`config.json` that an eval machine running a different LeRobot version's `ACTConfig`/
`DiffusionConfig`/`SmolVLAConfig` (with a stricter decoder) may reject as unknown. **If this
happens again**: `snapshot_download` the model locally, strip `pretrained_revision` from
`config.json` with a one-line Python fix, then point `--policy.path` at the local directory
instead of the Hub repo ID. Worth checking whether this machine's LeRobot version matches
0.5.2 (what trained these) before starting, to avoid this entirely.

## Suggested eval commands (verify flags against the local install first)

```bash
# On this machine, in the LeRobot venv/conda env
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm \
    --robot.cameras="{
        top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30},
        wrist: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30, rotation: 180}
    }" \
    --policy.path=Akshit03/act_mir1_v2 \
    --dataset.repo_id=Akshit03/eval_act_mir1_v2 \
    --dataset.single_task="Pick up the blue block and place in the yellow bin" \
    --dataset.num_episodes=10
```

Repeat with:
- `--policy.path=Akshit03/diffusion_mir1_v2` → `--dataset.repo_id=Akshit03/eval_diffusion_mir1_v2`
- `--policy.path=Akshit03/smolvla_mir1_v2` → `--dataset.repo_id=Akshit03/eval_smolvla_mir1_v2`

Confirm camera device paths (`/dev/video0`, `/dev/video2`) and serial port (`/dev/ttyACM1`)
still match this machine's current setup — verify the wrist camera mount is still in its
fixed position before starting (physically check, don't assume).

## Inference speed — measure before comparing, this matters a lot

v1's Diffusion Policy dropped to **0.9 Hz** at rollout time with default settings (DDPM, 100
inference steps) against a 30 Hz target on this desktop's RTX 3060 Ti — unusable. Switching
sampler helped:
- DDIM 10 steps → ~7.8 Hz
- DDIM 5 steps → ~12-14 Hz (this is what v1 evaluated with, got 4/10 — Diffusion's real
  result may partly reflect this Hz handicap, not just policy quality)
- ACT ran at ~25 Hz by comparison — no known slowness issue.

**SmolVLA's inference speed on this machine is completely unmeasured.** It's a 450M-param
VLM doing flow-matching-style action generation — there is real risk it's also slow at
rollout time (possibly slower than Diffusion, given the added VLM forward pass per action
chunk). **Do a quick timing check for all 3 policies before running the full 10-episode
comparison** — a few seconds of rollout is enough to read off the achieved Hz. If SmolVLA
(or any policy) is similarly slow, the same DDIM-style step-reduction approach may not apply
(that was Diffusion-specific) — check if SmolVLA's config exposes an equivalent
inference-step/chunk-size knob, or reduce `n_action_steps`/similar if available.

**When comparing final success rates across all 3 policies, report the actual control Hz
each one ran at alongside the success count** — a policy running at a much lower Hz has a
real, separate disadvantage from raw policy quality, and conflating the two would make for
a misleading write-up.

## What "success" means per episode

Manually judge/log whether the arm actually picked up the blue block and placed it in the
yellow bin, for each of the 10 episodes per policy (30 episodes total across 3 policies).
`lerobot-record` may support marking success/failure via keyboard during recording in recent
versions — check for that; otherwise track it in a simple notes file (episode number,
success/fail, brief failure-mode note if it failed).

## The specific thing to check first, before trusting any of this

Since the last real-robot data point (v1) showed the *same* failure pattern on both ACT and
Diffusion ("approach good, grasp missed") and that was traced to the camera mount, not
training — **if v2 eval shows that exact same failure pattern again**, treat it as a real
signal to look at training/data quality again (the camera fix may not have fully worked, or
there's a different systemic issue). But if v2 shows a **different** failure pattern (e.g.
inconsistent approach trajectories, wrong-object grasps, drops after a successful grasp),
treat that as a new problem to investigate on its own terms — not evidence the camera fix
failed.

## Deliverable

A success-rate comparison across all 3 policies, e.g. "ACT: 7/10 @ 25Hz, Diffusion: 6/10 @
13Hz, SmolVLA: 8/10 @ ??Hz" (illustrative only), plus:
- Qualitative failure-mode notes per policy (missed grasp, dropped block, wrong location,
  didn't approach at all, etc.)
- The achieved control Hz for each policy, explicitly caveated in the comparison
- Whether the v1 "camera mount" failure pattern reappeared or not (see above)

This is the actual head-to-head result the whole project has been building toward — training
loss numbers were never meant to answer this question.

## Checklist

- [x] Hardware setup, wiring, calibration (leader + follower), teleop — carried over from v1
- [x] Wrist camera mount physically fixed (root cause of v1's poor results)
- [x] 7 new sessions recorded (42 episodes) after the camera fix
- [x] Aggregated → `Akshit03/AkshitMajorProjectMIR1_v2_combined`
- [x] Train ACT on Jetson AGX Orin → `Akshit03/act_mir1_v2`
- [x] Train Diffusion Policy on Jetson AGX Orin → `Akshit03/diffusion_mir1_v2`
- [x] Fine-tune SmolVLA on Jetson AGX Orin → `Akshit03/smolvla_mir1_v2`
- [ ] Verify camera mount is still physically correct before eval
- [ ] Measure control-loop Hz for all 3 policies on this machine
- [ ] Evaluate ACT on real robot (10 episodes, success/fail + failure-mode notes)
- [ ] Evaluate Diffusion Policy on real robot (10 episodes, success/fail + failure-mode notes)
- [ ] Evaluate SmolVLA on real robot (10 episodes, success/fail + failure-mode notes)
- [ ] Compare all 3 results (success rate + Hz) and write up final conclusion
- [ ] Check whether the v1 "approach good, grasp missed" failure pattern reappears
