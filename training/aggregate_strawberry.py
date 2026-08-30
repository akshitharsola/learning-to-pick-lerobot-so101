from lerobot.datasets.lerobot_dataset import LeRobotDataset
from lerobot.datasets.aggregate import aggregate_datasets

repo_ids = [
    "Akshit03/AkshitMajorProjectMIR1_cube_blacktip_combined",
    "Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session1_20260721_123935",
    "Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session2_20260721_125019",
    "Akshit03/AkshitMajorProjectMIR1_strawberry_printed_session3_20260721_132013",
]

aggr_repo_id = "Akshit03/AkshitMajorProjectMIR1_cube_strawberry_combined"

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
print("DONE. total_frames:", aggr_ds.meta.total_frames)
