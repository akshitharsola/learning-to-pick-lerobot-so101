# Empirical Evaluation Results — Staged Fine-Tuning (Black-Tip Bugfix & Strawberry Multi-Task)

**Platform:** SO-101 Follower Arm running LeRobot Asynchronous Inference (`chunk_size_threshold=0.3`, `weighted_average`)  
**Evaluated Models:** `Akshit03/smolvla_mir1_blacktip_fix` and `Akshit03/smolvla_mir1_strawberry`

---

## 1. Executive Summary

Across **30 independent test episodes** spanning both fine-tuned models and tasks, the system achieved a **100% success rate (30/30)**.

| Model Under Test | Evaluated Task | Episodes Tested | Successes | Success Rate | 95% Wilson Score CI |
|---|---|:---:|:---:|:---:|:---:|
| `smolvla_mir1_blacktip_fix` | Blue Cube Pick & Place (with targeted contact grasps) | 10 | 10 | **100% (10/10)** | [72.2%, 100.0%] |
| `smolvla_mir1_strawberry` | Strawberry Harvesting (printed prop) | 10 | 10 | **100% (10/10)** | [72.2%, 100.0%] |
| `smolvla_mir1_strawberry` | Blue Cube Pick & Place (Regression Check) | 10 | 10 | **100% (10/10)** | [72.2%, 100.0%] |
| **Total Staged Evaluation** | **Multi-Task & Bugfix Total** | **30** | **30** | **100% (30/30)** | **[88.6%, 100.0%]** |

---

## 2. Qualitative Observations & Analysis

### A. Gripper-Release Anomaly Resolution (Round 3)
- In earlier v2 baseline trials, the gripper failed to release cleanly when contacting specific high-friction black/white boundary regions.
- The 8k-step fine-tune on `cube_blacktip_combined` (60 episodes) fully resolved this issue: 0 release failures observed across 10 deliberate test contacts.

### B. Strawberry Grasp Rule Transfer (Round 4)
- Real strawberries were initially tested but crushed due to rigid 3D-printed gripper fingers.
- Switching to a rigid printed prop with a strict teleoperation heuristic (grasping at the stem/hook or mid-body, avoiding the slippery bottom apex) successfully transferred to policy behavior.
- All 10 harvesting trials completed cleanly without dropping or slipping.

### C. Multi-Task Retention (No Catastrophic Forgetting)
- Evaluating the strawberry-fine-tuned model on the original blue cube task yielded a flawless 10/10 success rate, proving that the VLA architecture successfully retained prior skills while acquiring novel manipulation primitives.

### D. Hardware Vibration Diagnosis
- During evaluations, a minor visible mechanical shake was noted during arm motion.
- Queue-health profiling confirmed consistent action chunk buffering without pipeline starvation.
- Diagnostic tracing pinpointed a slightly loose structural joint screw on the follower arm, confirming the shake was mechanical rather than algorithmic.
