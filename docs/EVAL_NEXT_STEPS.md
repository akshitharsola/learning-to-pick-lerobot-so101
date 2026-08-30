# MajorProject — Next Steps: Real-Robot Evaluation Phase

## Context for the assisting Claude on this machine

This continues a project handed off from a Claude session on a separate Jetson AGX Orin, which was
used purely as training compute (no robot attached there). This machine (`robotics@brian-Vortex-ST-R`)
has the physical SO-101 arms and cameras and is where recording/eval always happens. The original plan
was in `NEXT_STEPS.md` (Phases 1-3); this file covers **Phase 4: real-robot evaluation**, now that
training is complete. Read `NEXT_STEPS.md` too for the original hardware/camera setup context, but
prefer the details below where they differ — several things changed since that file was written.

## What's Done (as of 2026-07-04)

- Sessions 4-10 (42 episodes) aggregated into `Akshit03/AkshitMajorProjectMIR1_combined` and pushed to HF.
- **Two policies trained on the Jetson AGX Orin, both pushed to the HF Hub, ready to evaluate:**
  - `Akshit03/act_mir1` — ACT, 30,000 steps, ~8.55 epochs, final training loss 0.103, ~7.3 hours to train.
  - `Akshit03/diffusion_mir1` — Diffusion Policy, 30,000 steps, ~8.55 epochs, final training loss 0.008, ~10.5 hours to train (one mid-run disk-full crash recovered from checkpoint, doesn't affect the final model quality).
- **Important**: the two loss values above are NOT comparable to each other — ACT uses action L1 loss, Diffusion uses a noise-prediction MSE loss. Do not conclude "Diffusion is 10x better" from those numbers. **The only meaningful comparison is real-robot success rate**, which is what this phase produces.
- Nothing is trained further right now — this phase is pure evaluation on the physical robot.

## Corrections vs. the original `NEXT_STEPS.md`

The LeRobot version actually installed has moved on since that file was written:
- `python lerobot/scripts/eval.py ...` no longer exists as a path — check whether this machine has a `lerobot-eval` / `lerobot-record` CLI entry point instead (`which lerobot-record`). Recent LeRobot versions use `lerobot-record` with a `--policy.path=<hub_repo_or_local_dir>` argument to run a trained policy live and record the resulting rollout as an eval dataset, rather than a separate `eval.py`.
- `--policy.path` should point at the **Hub repo directly** (e.g. `Akshit03/act_mir1`), not a local `outputs/train/.../checkpoints/last/pretrained_model` path — the checkpoints only exist on the Jetson (and have since been deleted there to save disk, since they're safely on the Hub) and won't exist on this machine, so pull from the Hub.
- Check the installed LeRobot version's own docs/`AGENT_GUIDE.md` (if present in whatever clone is on this machine) before assuming any exact command syntax below — it's a fast-moving repo and flags/paths have drifted before within this same project.

## Suggested Phase 4 command (verify flags against the local install first)

```bash
# On this machine, in the LeRobot conda/venv env
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm \
    --robot.cameras="{
        top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30},
        wrist: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30, rotation: 180}
    }" \
    --policy.path=Akshit03/act_mir1 \
    --dataset.repo_id=Akshit03/eval_act_mir1 \
    --dataset.single_task="Pick up the blue block and place in the yellow bin" \
    --dataset.num_episodes=10
```

Repeat with `--policy.path=Akshit03/diffusion_mir1` and `--dataset.repo_id=Akshit03/eval_diffusion_mir1` for the second policy. Confirm the camera device paths (`/dev/video0`, `/dev/video2`) and serial ports (`/dev/ttyACM1`) still match this machine's current setup — they may have changed since the original recording sessions.

## What "success" means per episode

Manually judge/log whether the arm actually picked up the blue block and placed it in the yellow bin for each of the 10 episodes per policy. `lerobot-record` supports marking episodes success/failure via keyboard during recording in recent versions — check for that, or track it in a simple notes file if not.

## Deliverable

A success-rate comparison: e.g. "ACT: 7/10, Diffusion: 9/10" (illustrative only), plus qualitative notes on failure modes (e.g. missed grasp, dropped block, wrong location) since that's often more useful for deciding which policy to keep than the raw rate alone. This is the actual head-to-head result the project has been building toward — the training loss numbers were never meant to answer that question.

## Checklist

- [x] Hardware setup and wiring
- [x] Calibration (leader + follower)
- [x] Teleop verified
- [x] Sessions 4-10 recorded (42 episodes)
- [x] Aggregate datasets → `combined` repo on HF
- [x] Train ACT on Jetson AGX Orin → `Akshit03/act_mir1`
- [x] Train Diffusion Policy on Jetson AGX Orin → `Akshit03/diffusion_mir1`
- [ ] Evaluate ACT on real robot (10 episodes, record success/fail per episode)
- [ ] Evaluate Diffusion Policy on real robot (10 episodes, record success/fail per episode)
- [ ] Compare ACT vs Diffusion results and write up final conclusion
