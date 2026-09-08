from __future__ import annotations

import hashlib
import sys
import zipfile
from pathlib import Path

from lxml import etree


reference = Path(sys.argv[1])
final = Path(sys.argv[2])
ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


with zipfile.ZipFile(reference) as rz, zipfile.ZipFile(final) as fz:
    print(f"reference_sha256={sha256(reference)}")
    print(f"final_sha256={sha256(final)}")
    print(f"reference_members={len(rz.namelist())}")
    print(f"final_members={len(fz.namelist())}")
    print(f"final_zip_test={fz.testzip()}")

    xml_parts = [
        name
        for name in fz.namelist()
        if name.endswith((".xml", ".rels"))
    ]
    for name in xml_parts:
        etree.fromstring(fz.read(name))
    print(f"parsed_xml_parts={len(xml_parts)}")

    visible_parts = [
        name
        for name in fz.namelist()
        if name == "word/document.xml"
        or name.startswith("word/header")
        or name.startswith("word/footer")
    ]
    visible_text = " ".join(
        " ".join(etree.fromstring(fz.read(name)).xpath("//w:t/text()", namespaces=ns))
        for name in visible_parts
    )
    for stale in ("SCC-4179", "GreatPlains", "CPNI"):
        print(f"visible_stale_{stale}={stale in visible_text}")
    for required in ("SALDEV-1415", "FlywirePartial", "Changes Requested"):
        print(f"visible_required_{required}={required in visible_text}")

    document = etree.fromstring(fz.read("word/document.xml"))
    print(f"tables={len(document.xpath('//w:tbl', namespaces=ns))}")
    print(f"heading1={len(document.xpath('//w:pStyle[@w:val=\"Heading1\"]', namespaces=ns))}")
    print(f"heading2={len(document.xpath('//w:pStyle[@w:val=\"Heading2\"]', namespaces=ns))}")
    print(f"page_breaks={len(document.xpath('//w:br[@w:type=\"page\"]', namespaces=ns))}")
    print(f"hyperlinks={len(document.xpath('//w:hyperlink', namespaces=ns))}")

    footer_text = " ".join(
        " ".join(etree.fromstring(fz.read(name)).xpath("//w:t/text()", namespaces=ns))
        for name in fz.namelist()
        if name.startswith("word/footer") and name.endswith(".xml")
    )
    footer_fields = " ".join(
        " ".join(etree.fromstring(fz.read(name)).xpath("//w:instrText/text()", namespaces=ns))
        for name in fz.namelist()
        if name.startswith("word/footer") and name.endswith(".xml")
    )
    print(f"footer_has_flywire={('FlywirePartial' in footer_text)}")
    print(f"footer_has_page_field={('PAGE' in footer_fields.upper())}")

    preserve_parts = [
        "word/settings.xml",
        "word/webSettings.xml",
        "word/fontTable.xml",
        "word/theme/theme1.xml",
        "word/numbering.xml",
    ]
    for name in preserve_parts:
        same = name in rz.namelist() and name in fz.namelist() and rz.read(name) == fz.read(name)
        print(f"preserved_{name}={same}")

