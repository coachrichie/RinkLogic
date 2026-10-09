from pathlib import Path
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

    assert ordered_ids[:3] == [74, 77, 78]
