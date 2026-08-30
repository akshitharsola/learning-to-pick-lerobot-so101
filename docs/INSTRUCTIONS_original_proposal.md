# LeRobot SO-101 Setup, Calibration, and Data Collection Guide

## Overview

This guide explains how to:

1. Install and configure LeRobot
2. Set up SO-101 leader/follower robot arms
3. Configure motor IDs and baud rates
4. Calibrate the robots
5. Teleoperate the system
6. Record datasets
7. Upload datasets to Hugging Face
8. Troubleshoot common issues

Official documentation:

* [LeRobot SO-101 Documentation](https://huggingface.co/docs/lerobot/so101?utm_source=chatgpt.com)
* [LeRobot Teleoperation Guide](https://huggingface.co/docs/lerobot/il_robots?teleoperate_so101=Command&utm_source=chatgpt.com)
* [LeRobot GitHub Repository](https://github.com/huggingface/lerobot?utm_source=chatgpt.com)

LeRobot is designed as an open-source robotics framework supporting imitation learning, teleoperation, dataset collection, and policy training for low-cost robot platforms such as the SO-101. ([OpenReview][1])

---

# 1. System Requirements

Recommended:

* Ubuntu 22.04+
* Python 3.10+
* Conda or Miniconda
* CUDA-compatible GPU (recommended for training)
* Two SO-101 arms:

  * Leader arm (teleoperation)
  * Follower arm (executing motions)
* USB cameras

---

# 2. Install LeRobot

Clone the repository:

```bash
git clone https://github.com/huggingface/lerobot.git
cd lerobot
```

Create and activate a Conda environment:

```bash
conda create -n lerobot python=3.10 -y
conda activate lerobot
```

Install dependencies:

```bash
pip install -e .
```

---

# 3. Connect the Hardware

## USB Devices

Connect:

* Leader arm
* Follower arm
* Cameras

Check connected serial devices:

```bash
ls /dev/ttyACM*
```

Typical mapping:

| Device       | Port           |
| ------------ | -------------- |
| Leader Arm   | `/dev/ttyACM0` |
| Follower Arm | `/dev/ttyACM1` |

Check available cameras:

```bash
ls /dev/video*
```

Typical mapping:

| Camera       | Device        |
| ------------ | ------------- |
| Top Camera   | `/dev/video0` |
| Wrist Camera | `/dev/video2` |

---

# 4. Grant Serial Permissions

Allow access to serial devices:

```bash
sudo chmod 666 /dev/ttyACM*
```

This step is required every reboot unless persistent udev rules are configured.

---

# 5. Configure Motor IDs and Baud Rates

Run the motor setup utility:

```bash
lerobot-setup-motors \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1
```

```bash
lerobot-setup-motors \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0
```

You will see the prompt:

```text
Connect the controller board to the 'gripper' motor only and press enter.
```

Important setup rules:

* Connect ONLY the requested motor
* Do NOT daisy-chain motors during setup
* Press Enter after connecting the motor
* The utility automatically configures:

  * Motor ID
  * Baud rate

Repeat for each motor as instructed.

---

# 6. Calibrate the Robot Arms

LeRobot requires calibration before teleoperation or recording.

## Calibrate the Follower Arm

```bash
lerobot-calibrate \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm
```

During calibration:

1. Move the arm to the center of each joint range
2. Press Enter
3. Slowly move joints through their full range of motion

The system records:

* Minimum joint values
* Maximum joint values
* Joint offsets

---

## Calibrate the Leader Arm

```bash
lerobot-calibrate \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=so101_leader_arm
```

---

## Recalibration

If calibration becomes corrupted, delete calibration files:

```bash
rm -rf ~/.cache/huggingface/lerobot/calibration/robots/*
rm -rf ~/.cache/huggingface/lerobot/calibration/teleoperators/*
```

Then rerun calibration.

Calibration details are consistent with official SO-101 setup procedures and community tutorials. ([Amazon Media][2])

---

# 7. Test Teleoperation

Before collecting data, verify teleoperation works correctly.

Run:

```bash
lerobot-teleoperate \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=so101_leader_arm
```

Expected behavior:

* Moving the leader arm moves the follower arm in real time
* Gripper actions are mirrored
* Motion should be smooth and responsive

Safety recommendations from the LeRobot ecosystem:

* Clamp both arms securely to a table
* Keep cables clear of joints
* Start with slow movements
* Ensure adequate power supply stability

([Amazon Media][2])

---

# 8. Hugging Face Authentication

Login before dataset recording:

```bash
hf auth login
```

You will be prompted to enter your Huggingface token...

Verify login:

```bash
hf auth whoami
```

Datasets are uploaded directly to the Hugging Face Hub.

---

# 9. Record a Dataset

Use the following command to record demonstrations:

```bash
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=so101_follower_arm \
    --robot.cameras="{
        top: {
            type: opencv,
            index_or_path: /dev/video0,
            width: 640,
            height: 480,
            fps: 30
        },
        wrist: {
            type: opencv,
            index_or_path: /dev/video2,
            width: 640,
            height: 480,
            fps: 30,
            rotation: 180
        }
    }" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=so101_leader_arm \
    --display_data=true \
    --dataset.repo_id="BrianMIR1/so101_wristcam_dataset_v2" \
    --dataset.num_episodes=80 \
    --dataset.episode_time_s=25 \
    --dataset.reset_time_s=5 \
    --policy.temporal_ensemble_coeff=0.01 \
    --dataset.single_task="Pick up the blue block and place in the yellow bin"
```

### note:
If you want to store locally and avoid pushing to hub, use:
```bash
--dataset.push_to_hub=false
```

This records:

* Joint states
* Actions
* Camera images
* Task metadata
* Teleoperation demonstrations

The LeRobot dataset format is widely used for imitation learning and VLA training pipelines. ([Reddit][3])

---

# 10. Dataset Storage

## Local Cache

Datasets are stored locally at:

```bash
/home/<user-id>/.cache/huggingface/lerobot/<hf-id>
```

---

## Hugging Face Dataset

Example dataset location:

[Example Dataset Repository](https://huggingface.co/roshan-george/EE5108_Group1_Capture_YourName?utm_source=chatgpt.com)

---

# 11. Training Policies
ACT sample training command:
```bash
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
lerobot-train \
  --dataset.repo_id=BrianMIR1/so101_wristcam_dataset_v2 \
  --policy.type=act \
  --policy.n_action_steps=1 \
  --policy.temporal_ensemble_coeff=0.01 \
  --output_dir=outputs/train/act_so101_test_v2 \
  --job_name=act_so101_test_v2 \
  --policy.device=cuda \
  --wandb.enable=true \
  --batch_size=32 \
  --steps=500000 \
  --policy.repo_id=BrianMIR1/act_so101_v2


```


smolvla example training command:

```bash
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=BrianMIR1/so101_wristcam_dataset_v2 \
  --batch_size=8 \
  --steps=20000 \
  --output_dir=outputs/train/my_smolvla \
  --job_name=my_smolvla_training \
  --policy.device=cuda \
  --wandb.enable=true \
  --policy.push_to_hub=true \
  --policy.repo_id=BrianMIR1/smol_so101_v2 \
  --policy.empty_cameras=1 \
  --rename_map='{"observation.images.top": "observation.images.camera1", "observation.images.wrist": "observation.images.camera2"}'
```

LeRobot supports multiple policy architectures including:

* ACT
* Diffusion Policy
* SmolVLA
* OpenVLA-compatible pipelines

([OpenReview][1])

---

# 12. Deploy your trained model
```bash
lerobot-rollout \
  --strategy.type=base \
  --policy.path=BrianMIR1/my_policy \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyACM1 \
  --robot.id=so101_follower_arm \
  --robot.cameras='{
    "top": {
      "type": "opencv",
      "index_or_path": "/dev/video0",
      "width": 640,
      "height": 480,
      "fps": 30
    },
    "wrist": {
      "type": "opencv",
      "index_or_path": "/dev/video2",
      "width": 640,
      "height": 480,
      "fps": 30,
      "rotation": 180
    }
  }' \
  --display_data=true \
  --task="Grab the blue block and place in the yellow bin" \
  --duration=60
```
 
Change --policy-path to match your trained policy

```bash
lerobot-rollout \
  --strategy.type=base \
  --policy.path=BrianMIR1/smol_so101_v2 \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyACM1 \
  --robot.id=so101_follower_arm \
  --robot.cameras='{
    "camera1": {
      "type": "opencv",
      "index_or_path": "/dev/video0",
      "width": 640,
      "height": 480,
      "fps": 30
    },
    "camera2": {
      "type": "opencv",
      "index_or_path": "/dev/video2",
      "width": 640,
      "height": 480,
      "fps": 30,
      "rotation": 180
    }
  }' \
  --display_data=true \
  --task="Grab the blue block and place in the yellow bin" \
  --duration=60
  ```

# 13. Useful Commands

## upload local trained model
First login:

hf auth login

Then create/upload the repo in one command:

hf upload BrianMIR1/act_so101_test_v2 \
  outputs/train/act_so101_test_v2/checkpoints/last/pretrained_model \
  .

That means:

hf upload <repo_id> <local_folder> <path_in_repo>

So:

repo = BrianMIR1/act_so101_test_v2
local folder = your trained checkpoint
. = upload to repo root

If the repo does not exist yet, create it first:

hf repo create act_so101_test_v2 --type model

Then run the upload command again.


## Activate Environment

```bash
conda activate lerobot
```

## Check Serial Devices

```bash
ls /dev/ttyACM*
```

## Check Cameras

```bash
ls /dev/video*
```

## Reset Rerun Visualization

```bash
rerun reset
```

## Verify Hugging Face Login

```bash
huggingface-cli whoami
```

---

# 14. Troubleshooting

## Permission Denied

```bash
sudo chmod 666 /dev/ttyACM*
```

---

## Cameras Not Detected

```bash
v4l2-ctl --list-devices
```

---

## Teleoperation Lag or Jitter

Possible causes:

* USB bandwidth issues
* Insufficient power supply
* Loose cables
* Camera frame rate overload

Reduce camera FPS if needed.

---

## Calibration Errors

Delete cached calibration files and recalibrate.

---

# 14. Recommended Workflow

1. Activate environment
2. Connect hardware
3. Verify USB devices
4. Grant permissions
5. Calibrate robots
6. Test teleoperation
7. Record demonstrations
8. Train policies
9. Evaluate policies

---

# 15. Additional Notes

The SO-101 platform is widely used because it provides:

* Low-cost imitation learning hardware
* Native LeRobot integration
* Open-source tooling
* Standardized dataset pipelines
* Compatibility with modern robot learning methods

The LeRobot ecosystem is increasingly becoming a standard format for open-source robot learning datasets and teleoperation workflows. ([Reddit][3])

---

[1]: https://openreview.net/pdf?id=CiZMMAFQR3&utm_source=chatgpt.com "Published as a conference paper at ICLR 2026"
[2]: https://m.media-amazon.com/images/I/A1I6FlZ6Y9L.pdf?utm_source=chatgpt.com "SO- SO-ARM100 ARM100 No-3DP Parts 3DP Part Kit Kit"
[3]: https://www.reddit.com/r/AskRobotics/comments/1sy4zop/help_picking_a_robot_arm_to_play_connect_four/?utm_source=chatgpt.com "Help picking a robot arm to play Connect Four"

