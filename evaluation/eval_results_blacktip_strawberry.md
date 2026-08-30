# Empirical Evaluation Results — Final Policy (Staged Fine-Tuning)

**Platform:** SO-101 Follower Arm running LeRobot Asynchronous Inference (`chunk_size_threshold=0.3`, weighted-average blending)
**Evaluated Model:** `Akshit03/smolvla_mir1_strawberry` (Round 4 of the staged fine-tuning process)

---

## 1. Final Evaluation Results

The final policy was evaluated on the physical SO-101 robot performing the strawberry pick-and-place task: picking up the printed strawberry prop and placing it in the target bin. Ten trials were run, each independently set up and scored by direct observation.

Success was defined as a clean pick: the gripper closes on the strawberry prop without crushing or dropping it, lifts it clear, and places it in the target bin.

| Model Under Test | Evaluated Task | Trials | Successes | Success Rate | 95% Wilson Score CI |
|---|---|:---:|:---:|:---:|:---:|
| `smolvla_mir1_strawberry` | Strawberry Harvesting (printed prop) | 10 | 8 | **80%** | **[49%, 94%]** |

**This is a pilot-scale result, not a validated benchmark.** A 95% Wilson confidence interval spanning roughly 49–94% is wide, and a benchmark-grade claim would need on the order of 50 to 100 or more trials to meaningfully narrow it (see the thesis report, Section 10.3 and Section 14.2).

Both observed failures shared a single, specific cause: the arm attempted to grasp the strawberry prop near its bottom tip — the known slip zone identified during Round 4 data collection and explicitly excluded by the hard grasp rule enforced when recording that round's demonstrations. All other grasp attempts, at the hook/stem area or the middle body, succeeded reliably.

---

## 2. Context: What This Number Does and Doesn't Represent

These ten trials are the final, formal evaluation batch, run after the last fine-tuning round concluded — the clean, controlled number the thesis report is willing to quote as a defensible before/after comparison point. They are not the sum of all testing performed over the course of the project: informal rollouts were run after essentially every training and fine-tuning round throughout the project, with the arm's behaviour watched live and any anomalous behaviour flagged for investigation. That informal testing — not the formal ten-trial batch — is how the project's two biggest diagnostic findings were caught: the wrist-camera-mount shift (Round 1) and the gripper-release fault near light/dark contact areas (motivating Round 3). Neither appeared in any log; both were caught only by watching the physical robot.

---

## 3. Qualitative Observations & Analysis

### A. Gripper-Release Anomaly Resolution (Round 3)
- Real-robot evaluation of the v2-round SmolVLA model surfaced a gripper-release fault occurring specifically near light- or dark-coloured contact areas on the target object, where the gripper failed to open cleanly after a grasp.
- Twelve episodes specifically targeting the fault, plus six general cube-task top-up episodes, were recorded and used to fine-tune the affected model (Round 3, 8,000 steps).

### B. Strawberry Grasp Rule Transfer (Round 4)
- Real strawberries were used for two initial recording attempts and abandoned both times: the gripper crushed or tore the fruit's skin on contact. A mechanical fix (a compliant or soft-touch gripper fingertip) was judged infeasible within the project's remaining time budget.
- The project reverted to the printed strawberry prop, with a hard grasp rule enforced during recording: every episode grasps the prop only at the hook/stem area or the middle body, never the bottom tip.

### C. Multi-Task Retention
- The final policy was fine-tuned on a combined dataset containing both cube and strawberry task episodes (84 episodes total), continuing from the v2-round checkpoint. It is the single model evaluated as the project's final result — no separate cube-only regression check was logged as part of the formal ten-trial evaluation.

### D. Statistical Interpretation
- An 80% success rate computed from only ten trials should not be presented as a precisely known figure. The Wilson score interval (rather than the simpler normal-approximation interval) is used because it behaves sensibly under exactly the conditions this evaluation involves: a small sample size, and an observed proportion (80%) reasonably close to the upper bound of 100%.
