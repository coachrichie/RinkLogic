from pathlib import Path
import json
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]


def test_hockey_headline_fields_are_first_in_connect_summary():
    tree = ET.parse(ROOT / "watch-v2" / "resources" / "fitfields.xml")
    summary_fields = [
        field
        for field in tree.findall(".//fitField")
        if field.get("displayInActivitySummary") == "true"
    ]
    ordered_ids = [
        int(field.get("id"))
        for field in sorted(summary_fields, key=lambda field: int(field.get("sortOrder")))
    ]

    assert ordered_ids[:5] == [74, 98, 78, 96, 97]


def test_schema_eight_allocation_keeps_device_and_session_limits():
    registry = json.loads(
        (ROOT / "shared" / "schema" / "hockey-fit-schema.json").read_text(
            encoding="utf-8"
        )
    )
    fields = {field["id"]: field for field in registry["fields"]}
    active_ids = registry["activeFieldIds"]

    assert registry["version"] == 8
    assert registry["deviceAllocationLimit"] == 34
    assert registry["activeAllocationCount"] == 34
    assert len(active_ids) == 34
    assert len(set(active_ids)) == 34
    assert len([field_id for field_id in active_ids if fields[field_id]["scope"] == "session"]) == 16
    assert fields[79]["name"] == "heart_rate_zone_1_time"
    assert fields[85]["name"] == "work_rest_ratio_tenths"
    assert fields[86]["name"] == "shift_density_per_hour"
    assert fields[93]["name"] == "heart_rate_drop_30"
    assert fields[94]["name"] == "heart_rate_drop_60"
    assert fields[99]["scope"] == "lap"
    assert fields[99]["type"] == "float32"
    assert fields[100]["scope"] == "record"
    assert fields[100]["key"] == "rawPushCandidateCountTotal"
