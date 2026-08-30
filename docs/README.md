# Project Engineering Handover & Technical Documentation

This directory contains the chronological engineering logs, technical handoff notes, and persistent memory summaries generated across multiple physical and embedded machines throughout the major project lifecycle.

---

## Document Index & Summary

| Document | Phase / Topic | Machine Origin | Key Highlights & Description |
|---|---|---|---|
| `PROJECT_MEMORY_SUMMARY.md` | Project Overview | Jetson AGX Orin | Consolidated project memory summarizing goals, environment quirks, LeRobot v0.5.2 API drift, disk constraints, model lineage, and eval findings. |
| `JETSON_TRAINING_HANDOFF.md` | Phase 2 Training | Recording Desktop → Jetson | Handoff instructions for aggregating 7 v2 sessions into `v2_combined` and training ACT, Diffusion, and SmolVLA baselines. |
| `JETSON_STRAWBERRY_TRAINING_HANDOFF.md` | Phase 3 Training | Recording Desktop → Jetson | Detailed procedure for aggregating printed strawberry sessions with cube datasets and fine-tuning `smolvla_mir1_strawberry`. |
| `V2_EVAL_HANDOFF.md` | Phase 2 Eval | Jetson → Eval Desktop | Evaluation guide for v2 models, detailing wrist camera fix, control-loop Hz benchmarking, and `pretrained_revision` workaround. |
| `BLACKTIP_STRAWBERRY_EVAL_HANDOFF.md` | Phase 3 Eval | Jetson → Eval Desktop | Comprehensive evaluation protocol for testing `smolvla_mir1_blacktip_fix` and `smolvla_mir1_strawberry` on physical robot. |
| `EVAL_NEXT_STEPS.md` | Evaluation Strategy | University Lab | Outlines evaluation plan comparing ACT vs Diffusion, rollout logging, and failure mode criteria. |
| `NEXT_STEPS_v2.md` | Campaign Roadmap | Project Root | Step-by-step roadmap for re-recording v2 demonstrations, aggregation, multi-policy training, and rollout. |
| `NEXT_STEPS_v1.md` | Early Roadmap (v1) | Project Root | Initial project campaign roadmap for sessions 1–10 (superseded by v2 after camera realignment). |
| `LEROBOT_CONTEXT.md` | Setup & Architecture | Project Root | Hardware layout, serial ports, camera bindings, and calibration commands for LeRobot SO-101. |
| `LEROBOT_MEMORY.md` | Environment Memory | Project Root | Environment notes, conda setup, and quick-lookup CLI flags. |
| `INSTRUCTIONS_original_proposal.md` | Initial Proposal Guide | Project Root | Original project manual and proposal guidelines for robotic harvesting system setup. |
