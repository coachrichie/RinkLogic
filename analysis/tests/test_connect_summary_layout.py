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

    assert ordered_ids[:5] == [74, 98, 78, 97, 96]


def test_schema_ten_allocation_keeps_device_and_session_limits():
    registry = json.loads(
        (ROOT / "shared" / "schema" / "hockey-fit-schema.json").read_text(
            encoding="utf-8"
        )
    )
    fields = {field["id"]: field for field in registry["fields"]}
    active_ids = registry["activeFieldIds"]

    assert registry["version"] == 10
    assert registry["fieldIdRange"] == [1, 112]
    assert registry["deviceAllocationLimit"] == 34
    assert registry["activeAllocationCount"] == len(active_ids)
    assert len(active_ids) == 33
    assert len(active_ids) <= registry["deviceAllocationLimit"]
    assert len(set(active_ids)) == len(active_ids)
    assert len([field_id for field_id in active_ids if fields[field_id]["scope"] == "session"]) == 16
    assert registry["activeFieldIds"] == [
        44, 45, 51, 52, 55, 56, 62, 65, 71, 72, 73, 74,
        78, 85, 86, 95, 96, 97, 98, 99, 100, 101, 102, 103,
        104, 105, 106, 107, 108, 109, 110, 111, 112,
    ]
    for field_id in [75, 76, 79, 80, 81, 82, 83, 84, 89]:
        assert fields[field_id]["status"] == "retired_after_schema_8"
        assert field_id not in active_ids
    expected_minute_names = {
        101: "time_on_ice_minutes",
        102: "bench_time_minutes",
        103: "heart_rate_zone_1_minutes",
        104: "heart_rate_zone_2_minutes",
        105: "heart_rate_zone_3_minutes",
        106: "heart_rate_zone_4_minutes",
        107: "heart_rate_zone_5_minutes",
        108: "time_above_90_percent_hrmax_minutes",
        109: "median_shift_minutes",
    }
    for field_id, name in expected_minute_names.items():
        assert fields[field_id]["name"] == name
        assert fields[field_id]["type"] == "float32"
        assert fields[field_id]["unit"] == "min"
    assert fields[85]["name"] == "work_rest_ratio_tenths"
    assert fields[86]["name"] == "shift_density_per_hour"
    assert fields[93]["name"] == "heart_rate_drop_30"
    assert fields[94]["name"] == "heart_rate_drop_60"
    for field_id in [63, 66, 93, 94]:
        assert fields[field_id]["status"] == "retired_after_schema_9"
        assert field_id not in active_ids
    assert fields[97]["scope"] == "session"
    assert fields[97]["type"] == "float32"
    assert fields[97]["unit"] == "m"
    assert fields[97]["nativeNum"] == 9
    assert fields[99]["scope"] == "lap"
    assert fields[99]["type"] == "float32"
    assert fields[100]["scope"] == "record"
    assert fields[100]["key"] == "rawPushCandidateCountTotal"
    assert fields[110]["name"] == "estimated_distance_m_total"
    assert fields[110]["scope"] == "record"
    assert fields[110]["type"] == "float32"
    assert fields[110]["unit"] == "m"
    assert fields[111]["name"] == "shift_estimated_distance_m"
    assert fields[111]["scope"] == "lap"
    assert fields[111]["type"] == "float32"
    assert fields[111]["unit"] == "m"
    assert fields[112]["name"] == "phase"
    assert fields[112]["scope"] == "lap"
    assert fields[112]["type"] == "string"
    assert fields[112]["count"] == 8
    assert len({field["id"] for field in registry["fields"]}) == len(registry["fields"])
    assert max(field["id"] for field in registry["fields"]) == 112
    active_contracts = [
        (fields[field_id].get("name"), fields[field_id]["scope"])
        for field_id in active_ids
    ]
    assert len(set(active_contracts)) == len(active_contracts)


def _strings(path):
    return {
        element.get("id"): (element.text or "")
        for element in ET.parse(path).findall(".//string")
    }


def test_schema_ten_contributions_are_localized_and_keep_lap_duration():
    tree = ET.parse(ROOT / "watch-v2" / "resources" / "fitfields.xml")
    contributions = {
        int(field.get("id")): field for field in tree.findall(".//fitField")
    }
    minute_ids = list(range(101, 110))
    assert all(contributions[field_id].get("unitLabel") == "@Strings.ConnectMinutesUnit"
               for field_id in minute_ids)
    assert all(contributions[field_id].get("precision") == "1"
               for field_id in range(101, 109))
    assert contributions[109].get("precision") == "2"
    assert contributions[99].get("displayInActivityLaps") == "true"
    assert contributions[99].get("unitLabel") == "@Strings.ConnectMinutesUnit"
    assert not any(field_id in contributions for field_id in [63, 66, 75, 76, 79, 80, 81, 82, 83, 84, 89, 93, 94])
    assert contributions[110].get("displayInChart") == "true"
    assert contributions[110].get("unitLabel") == "@Strings.ConnectMetresUnit"
    assert int(contributions[110].get("precision")) >= 1
    assert contributions[111].get("displayInActivityLaps") == "true"
    assert contributions[111].get("unitLabel") == "@Strings.ConnectMetresUnit"
    assert int(contributions[111].get("precision")) >= 1
    assert contributions[112].get("displayInActivityLaps") == "true"
    assert contributions[112].get("dataLabel") == "@Strings.ConnectPhase"

    label_ids = {
        contributions[field_id].get("dataLabel").split(".")[-1]
        for field_id in minute_ids
    } | {"ConnectMinutesUnit", "ConnectMetresUnit", "ConnectEstimatedDistance", "ConnectPhase", "ConnectOnIce", "ConnectBench"}
    for relative in [
        Path("watch-v2/resources/strings/strings.xml"),
        Path("watch-v2/resources-deu/strings/strings.xml"),
    ]:
        localized = _strings(ROOT / relative)
        assert label_ids <= localized.keys()
        assert localized["ConnectMinutesUnit"] == "min"
        assert localized["ConnectMetresUnit"] == "m"
        assert localized["ConnectPhase"] == "Phase"
        assert localized["ConnectOnIce"] == "On-Ice"
        assert localized["ConnectBench"] == "Bench"
        assert "≈" in localized["ConnectEstimatedDistance"]
        assert "≈" in localized["ConnectShiftEstimatedDistance"]
    english = _strings(ROOT / "watch-v2/resources/strings/strings.xml")
    german = _strings(ROOT / "watch-v2/resources-deu/strings/strings.xml")
    assert "Estimated distance" in english["ConnectEstimatedDistance"]
    assert "Geschätzte Distanz" in german["ConnectEstimatedDistance"]
