# Major Project — Consolidated Memory Summary

Generated 2026-08-14 from Claude's persistent memory on the Jetson AGX Orin, for collating with notes from other machines into the final project report.

---

## 1. Project Goal

Train and compare **ACT vs Diffusion Policy vs SmolVLA** on a SO-101 robot arm performing pick-and-place: "Pick up the blue block and place in the yellow bin" (later extended to a strawberry pick task).

---

## 2. Environment (Jetson AGX Orin)

- Bare-metal JetPack/L4T R39, CUDA 13.2 toolkit pre-installed. No conda/pip/LeRobot on arrival despite `NEXT_STEPS.md` assuming conda — chose **venv** instead (lighter).
- Venv path: `/home/jetson-agx/MajorProject-25256470/lerobot-env` (activate with `source .../lerobot-env/bin/activate`).
- Key versions: `torch==2.11.0+cu130` (pinned — LeRobot requires `<2.12.0`, torchcodec needs `>=2.11`), `torchvision==0.26.0+cu130`, `torchcodec==0.11.1` (needs apt `ffmpeg` 7:8.0.1-nvidia).
- PyPI now ships official aarch64+CUDA wheels for torch — no need for NVIDIA's jetson-ai-lab index.
- GPU: Orin, compute capability 8.7 (benign PyTorch warning, works fine).

## 3. LeRobot Version Drift (installed 0.5.2, vs stale `NEXT_STEPS.md`)

- `lerobot.common.datasets.aggregate` → now `lerobot.datasets.aggregate` (no `common`).
- `aggregate_datasets(...)`: param renamed to `aggr_repo_id`; `push_to_hub` arg removed — push separately via `LeRobotDataset(repo_id=...).push_to_hub()`.
- CLI is now proper entry points: `lerobot-train`, `lerobot-eval`, `lerobot-record`, `lerobot-teleoperate` (not `python lerobot/scripts/train.py`).
- `huggingface-cli login` → `hf auth login`.
- ACT config has no `scheduler_decay_steps` (SmolVLA-only field).
- `lerobot-train` needs `--policy.repo_id=<hub-repo>` when pushing (default `push_to_hub=True`).
- `aggregate_datasets` only fetches metadata automatically — must pre-download full datasets first via `LeRobotDataset(repo_id)` per source (populates `~/.cache/huggingface/lerobot/hub`, a different cache from standard `huggingface_hub`).
- Dataset metadata format: no longer `meta/tasks.jsonl` — now `meta/tasks.parquet` (read with `pandas.read_parquet`).
- SmolVLA fine-tune flags: `--policy.type=smolvla --policy.pretrained_path=<hub-repo>` (NOT `--policy.path`, which doesn't exist). Requires `pip install -e "<lerobot-repo>[smolvla]"` for `transformers`.
- **Lesson**: always check the repo's own `AGENT_GUIDE.md`/`AGENTS.md`/`pyproject.toml` and installed version rather than trusting stale notes.

## 4. Disk Space Constraint

- 59GB eMMC, only ~5-8GB free during active work after OS/JetPack/CUDA.
- 28.7GB USB drive attached as overflow: `/media/jetson-agx/SANDISK` (mount name can shift to `SANDISK1` etc. across reboots — always check `mount | grep -i sandisk`). Must be **ext4** — APFS unusable on Linux, exFAT unusable (no symlink support, breaks HF cache + checkpoint pruner symlinks).
- Biggest space costs: `pip install torch` (~4.5GB incl. bundled CUDA libs), pip download cache (2-3GB/install — always `pip cache purge` after), training checkpoints.
- Checkpoint sizes: ACT ~198MB, SmolVLA ~1.5GB, Diffusion ~3.2GB (~16x ACT) per checkpoint.
- Datasets themselves are tiny (~120MB total for all sessions) — never the bottleneck.
- **Diffusion training crashed** once (disk full at step 15,000/30,000) — recovered by resuming from checkpoint 10,000 (`lerobot-train --config_path=.../010000/pretrained_model/train_config.json --resume=true`), losing 5,000 steps.
- **Prevention**: run a keep-1 checkpoint pruner script alongside any large-policy training (deletes all but the newest checkpoint dir, 15-30s poll interval) — free space must exceed one checkpoint's size at all times; keep-2 still crashes.

## 5. Dataset Naming / Source of Truth

- `NEXT_STEPS.md`'s dataset names (`..._session4` through `_session10`, no suffix) don't exist — real repos have `_YYYYMMDD_HHMMSS` suffixes.
- Source of truth: HF Collection **"LeRobot-Major-Project"** (`Akshit03/lerobot-major-project-6a3bbd3bd24b3e3989fa42c3`) lists the correct 7 session repos.
- All confirmed sessions share task string `"Pick up the blue block and place in the yellow bin"`.

## 6. Training Results

### v1 round (sessions 1-10, completed 2026-07-04)
- ACT: 30k steps, final loss 0.103, ~7.3h → `Akshit03/act_mir1`
- Diffusion: 30k steps, final loss 0.008, ~10.5h (one disk-full crash, recovered) → `Akshit03/diffusion_mir1`
- **Real-robot eval poor**: ACT 1/10, Diffusion 4/10 — traced to a **physically shifted wrist camera mount** (not a training/data problem — both policies showed "good approach, missed grasp"). Camera remounted afterward.

### v2 round (completed 2026-07-11, after camera fix)
- Recorded 7 new sessions (42 episodes, 30fps, 33353 frames), aggregated into `Akshit03/AkshitMajorProjectMIR1_v2_combined`.

| Policy | Steps | Final loss | Wall clock | Hub repo |
|---|---|---|---|---|
| ACT | 30,000 | 0.099 | 5h08m | `Akshit03/act_mir1_v2` |
| Diffusion | 30,000 | 0.007 | 6h37m | `Akshit03/diffusion_mir1_v2` |
| SmolVLA | 20,000 | 0.017 | 61h36m | `Akshit03/smolvla_mir1_v2` |

- Loss values not comparable across policy types — only real-robot success rate is a fair comparison.
- SmolVLA took ~61.6h (batch_size=64, professor-specified) — compute-bound on Orin GPU (99% util throughout), not RAM-bound.
- v2 real-robot eval: informally reported as "SmolVLA results are good", but surfaced a **gripper-release bug near white/black-tip contact areas** → triggered two more fine-tune rounds.

### SmolVLA blacktip-fix fine-tune (completed 2026-07-21)
- Aggregated dataset `Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined`: v2_combined (42 ep) + blacktip_fix_session1 (12 ep) + cube_topup_session1 (6 ep) = **60 episodes, 43,563 frames**.
- Continued from `smolvla_mir1_v2` checkpoint, 8,000 steps, batch 64, 24.7h wall-clock, final loss 0.019 → `Akshit03/smolvla_mir1_blacktip_fix`.
- Disk handling: output routed to USB, keep-1 pruner, eMMC held flat ~6.3-7.7GB free.

### SmolVLA strawberry fine-tune (completed 2026-07-23)
- Real strawberries tried and abandoned (gripper crushed the fruit) — reverted to printed prop, 3 clean sessions (24 episodes) recorded with new hard grasp rule (hook/middle only, never bottom tip).
- Aggregated dataset `Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined`: cube_blacktip_combined (60 ep) + 3 strawberry sessions (24 ep) = **84 episodes, 59,865 frames**, 2 task entries.
- Continued from `smolvla_mir1_v2` (not blacktip_fix — parallel branch, but does include blacktip-fix episodes via the dataset). 10,000 steps, batch 64, 30.8h wall-clock, final loss 0.022 → `Akshit03/smolvla_mir1_strawberry`.

### Model lineage on Hub
- `smolvla_mir1_v2` — baseline, cube only
- `smolvla_mir1_blacktip_fix` — v2 + black-tip fix + cube top-up, cube only (60 ep)
- `smolvla_mir1_strawberry` — v2 + black-tip fix + cube top-up + strawberry (84 ep)

ACT and Diffusion were **not** re-fine-tuned for either later round (both trained-from-scratch, would need full retrain to add data without catastrophic forgetting — only if explicitly decided otherwise).

**Do not aggregate v2 with v1 session1-10 data** — different camera geometry, would corrupt the training set.

## 7. Outstanding / Next Steps (as of last update)

- **Real-robot eval not yet done** for `smolvla_mir1_blacktip_fix` and `smolvla_mir1_strawberry`. Full plan in `BLACKTIP_STRAWBERRY_EVAL_HANDOFF.md` (project root).
- Eval checklist per handoff docs:
  1. Blacktip-fix: verify black-tip/white-area grasp bug is fixed + normal-grasp regression check against v2 9/10 baseline.
  2. Strawberry: printed-prop pick reliability (esp. bottom-tip slip-zone avoidance per new grasp rule), cube-task regression check against blacktip_fix baseline.
  3. Use async inference workflow (`eval_results/async_smolvla_server.sh` + `async_smolvla_client.sh`, `chunk_size_threshold=0.3`), not `lerobot-rollout`.
  4. Watch for `pretrained_revision` config-field crash pulling from Hub on eval machine (train/eval LeRobot version-compat quirk) — fix: `snapshot_download` locally + strip that field from `config.json`.
- **Measure each policy's actual control-loop Hz on the eval machine** before final comparison — v1 Diffusion ran only ~12-14Hz vs ACT's ~25Hz, a real disadvantage to caveat in the write-up.
- If eval shows the same "good approach, missed grasp" pattern as v1, that's a real signal to revisit training; a *different* failure pattern is a new problem, not evidence the camera fix failed.

## 8. Misc Notes

- HF auth: `hf auth login` (no `--force`) only checks for a stored token file, doesn't validate against server — if token expired, need `hf auth login --force` with a fresh Write-scope token.
- `!`-prefixed input is a Claude Code chat shortcut to run a command in-session, not something to paste into a real terminal.

---
*Source: Claude Code persistent memory files under `~/.claude/projects/-home-jetson-agx-MajorProject-25256470/memory/`. Cross-reference with `NEXT_STEPS.md`, `JETSON_TRAINING_HANDOFF.md`, `JETSON_STRAWBERRY_TRAINING_HANDOFF.md`, `BLACKTIP_STRAWBERRY_EVAL_HANDOFF.md`, `V2_EVAL_HANDOFF.md`, `EVAL_NEXT_STEPS.md` in the project root for full detail.*
