# Live Demonstration Walkthrough — Strawberry Pick & Place (SmolVLA)

This guide provides a rapid, two-terminal procedure for running a live demonstration of the trained **SmolVLA** robotic harvesting policy on the physical SO-101 arm.

---

## 1. Pre-Flight Checklist (2 minutes)

- [ ] **Power & USB**: SO-101 follower arm powered on; USB serial connected (`/dev/ttyACM1` follower, `/dev/ttyACM0` leader if present).
- [ ] **Cameras**: Top camera (`/dev/video0`) and wrist camera (`/dev/video2`) connected.
- [ ] **Hardware Sanity**: Check follower arm joint screws (specifically elbow/wrist) to prevent mechanical vibration.
- [ ] **Workspace Setup**: Place the printed/prop strawberry and the blue cube on the workspace mat; place the yellow receptacle bin within reach.
- [ ] **Environment**: Verify conda environment:
  ```bash
  conda activate lerobot
  ```

---

## 2. Launching the Demonstration

### Terminal 1 — Start the Asynchronous Policy Server
Start the server and leave it running in its own terminal window:
```bash
cd evaluation
./run_eval.sh server
```
*Wait until the terminal outputs that it is listening on `127.0.0.1:8080`.*

### Terminal 2 — Run the Strawberry Harvesting Client
In a second terminal window, run the client:
```bash
cd evaluation
./run_eval.sh demo
```
*The robot will fetch policy parameters, initialize the camera feeds, and begin autonomous pick-and-place operation for the task:*
> **"Pick up the red strawberry and place in the yellow bin"**

- **Continuous Operation**: After a successful pick-and-place, simply place the strawberry back into the workspace; the client runs continuously.
- **Stopping**: Press `Ctrl+C` in Terminal 2 (client), then `Ctrl+C` in Terminal 1 (server).

---

## 3. Demonstration Modes & Commands

| Command | Policy Loaded | Task Executed | Purpose |
|---|---|---|---|
| `./run_eval.sh demo` | `Akshit03/smolvla_mir1_strawberry` | Strawberry Pick & Place | Primary live harvesting demo |
| `./run_eval.sh strawberry-cube` | `Akshit03/smolvla_mir1_strawberry` | Blue Cube Pick & Place | Proves multi-task capability (no catastrophic forgetting) |
| `./run_eval.sh blacktip` | `Akshit03/smolvla_mir1_blacktip_fix` | Blue Cube Pick & Place | Demonstrates fix for white/black-tip release anomaly |
| `./run_eval.sh act` | `Akshit03/act_mir1_v2` | Blue Cube Pick & Place | Baseline ACT episodic rollout |
| `./run_eval.sh diffusion` | `Akshit03/diffusion_mir1_v2` | Blue Cube Pick & Place | Baseline Diffusion Policy (DDIM 5-step) rollout |

---

## 4. Key Talking Points for Evaluators

1. **Vision-Language-Action Architecture**:
   - SmolVLA is a 450M parameter VLA model fine-tuned from `lerobot/smolvla_base`.
   - Incorporates language grounding, dual RGB camera perception (top overhead + wrist close-up), and flow-matching action chunk generation.

2. **Asynchronous Decoupled Inference**:
   - Synchronous execution on VLM architectures drops the control loop to ~4.5 Hz (unusable for real-time robotic grasping).
   - The decoupled PolicyServer / RobotClient architecture buffers action chunks with a sliding window threshold (`chunk_size_threshold=0.3`) and weighted averaging, enabling smooth, uninterrupted 30 Hz motor execution.

3. **Staged Fine-Tuning Strategy**:
   - Initial cube policy fine-tuning (Round 2: 20k steps).
   - Targeted bugfix fine-tuning for gripper surface release (Round 3: 8k steps).
   - Multi-task strawberry harvesting fine-tuning (Round 4: 10k steps) enforcing a hook/middle-body grasp rule to prevent fruit bruising and slippage.

4. **Experimental Outcomes**:
   - **30/30 (100%)** successful pick-and-place episodes across all final evaluation campaigns.
