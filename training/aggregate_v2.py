from lerobot.datasets.lerobot_dataset import LeRobotDataset
from lerobot.datasets.aggregate import aggregate_datasets

repo_ids = [
    "Akshit03/AkshitMajorProjectMIR1_session_v2_1_20260707_120045",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_2_20260707_121251",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_3_20260707_122734",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_4_20260707_125144",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_5_20260708_123730",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_6_20260708_131229",
    "Akshit03/AkshitMajorProjectMIR1_session_v2_7_20260708_132934",
]

aggr_repo_id = "Akshit03/AkshitMajorProjectMIR1_v2_combined"

print("Pre-downloading source datasets (metadata + data/videos)...")
for repo_id in repo_ids:
    LeRobotDataset(repo_id)
    print("  downloaded", repo_id)

print("Aggregating...")
aggregate_datasets(repo_ids=repo_ids, aggr_repo_id=aggr_repo_id)

print("Pushing aggregated dataset to Hub...")
aggr_ds = LeRobotDataset(aggr_repo_id)
aggr_ds.push_to_hub()

print("DONE. total_episodes:", aggr_ds.meta.total_episodes)
