import csv
import json
from pathlib import Path

ROOT = Path("research_artifacts")
OUT = ROOT / "analysis"
MODEL = "deepseek__deepseek-flash"

runs = ["baseline25", "enhanced25"]

# Overall comparison
summary = []

for run in runs:
    path = ROOT / "evaluation" / f"{MODEL}.{run}.json"
    data = json.loads(path.read_text())

    summary.append({
        "run": run,
        "total_evaluated": data.get("total_instances"),
        "resolved": data.get("resolved_instances"),
        "unresolved": data.get("unresolved_instances"),
        "errors": data.get("error_instances"),
        "mean_coverage": data.get("Mean coverage"),
        "mean_coverage_delta": data.get("Mean coverage delta"),
        "generation_cost_usd": 0.24,
    })

with (OUT / "results_comparison.csv").open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=summary[0].keys())
    writer.writeheader()
    writer.writerows(summary)

# Per-instance evaluation outcomes
all_ids = [
    line.strip()
    for line in (ROOT / "configs" / "pilot25_ids.txt").read_text().splitlines()
    if line.strip()
]

rows = []

for instance_id in all_ids:
    row = {"instance_id": instance_id}

    for run in runs:
        report_path = (
            ROOT / "instance_logs" / run / MODEL /
            instance_id / "report.json"
        )

        if not report_path.exists():
            row[f"{run}_evaluated"] = False
            row[f"{run}_patch_applied"] = False
            row[f"{run}_resolved"] = False
            row[f"{run}_coverage"] = ""
            row[f"{run}_coverage_delta"] = ""
            continue

        data = json.loads(report_path.read_text())
        report = next(iter(data.values()))

        row[f"{run}_evaluated"] = True
        row[f"{run}_patch_applied"] = report.get(
            "patch_successfully_applied", ""
        )
        row[f"{run}_resolved"] = report.get("resolved", "")
        row[f"{run}_coverage"] = report.get("coverage_pred", "")
        row[f"{run}_coverage_delta"] = report.get(
            "coverage_delta_pred", ""
        )

    rows.append(row)

with (OUT / "instance_outcomes.csv").open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)

print("Created:")
print(OUT / "results_comparison.csv")
print(OUT / "instance_outcomes.csv")
print("Instances included:", len(rows))
