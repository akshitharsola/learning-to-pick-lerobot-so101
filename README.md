# Learning to Pick: Robotic Strawberry Harvesting — Code

Support code for the University of Galway EE5111 major project *"Learning to Pick: Robotic Strawberry Harvesting — An Imitation-Learning Pick-and-Place System on the LeRobot SO-101"* (Akshit Harsola, Student ID 25256470, Supervisor: Dr. Brian Deegan).

This repository holds the project's own scripts and handoff documentation. It does not include the vendored [LeRobot](https://github.com/huggingface/lerobot) framework, recorded datasets, video, or trained model checkpoints — those are tracked separately (datasets and checkpoints are published on the Hugging Face Hub under the `Akshit03/` namespace; see the thesis report, Appendix B, for exact repository names and reproduction commands).

## Layout

- `training/` — dataset aggregation scripts and training-launch shell scripts for ACT, Diffusion Policy, and SmolVLA (including the staged SmolVLA fine-tuning rounds: blacktip-fix, strawberry).
- `recording/recording_sessions/` — teleoperated demonstration-recording scripts, split into `v1_deprecated` (original cube sessions, later discarded after the wrist-camera-mount fault was diagnosed) and `v2_current` (post camera-fix recordings that fed the final dataset).
- `diagnostics/` — camera sanity-check script used to verify camera feeds during hardware diagnosis.
- `docs/` — project handoff notes and memory summaries written during the project (training handoffs, evaluation handoffs, next-steps notes from each project phase).

## Reproducing training

See `docs/` for phase-specific handoff notes, and Appendix B of the thesis report for the canonical, minimal reproduction commands (calibration, camera config, training invocation, and evaluation invocation).
