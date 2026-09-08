from __future__ import annotations

import json
import re
import sys
import zipfile
from pathlib import Path

from lxml import etree


W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W}


def qn(local: str) -> str:
    return f"{{{W}}}{local}"


def text_of(node: etree._Element) -> str:
    parts: list[str] = []
    for child in node.iter():
        if child.tag == qn("t") or child.tag == qn("delText"):
            parts.append(child.text or "")
        elif child.tag == qn("tab"):
            parts.append("\t")
        elif child.tag in {qn("br"), qn("cr")}:
            parts.append("\n")
    return "".join(parts)


def paragraph_style(p: etree._Element) -> str:
    value = p.xpath("./w:pPr/w:pStyle/@w:val", namespaces=NS)
    return value[0] if value else ""


def ordered_blocks(root: etree._Element) -> list[dict[str, object]]:
    blocks: list[dict[str, object]] = []
    body = root.find("w:body", NS)
    if body is None:
        return blocks
    p_index = 0
    table_index = 0
    for child in body:
        if child.tag == qn("p"):
            p_index += 1
            blocks.append(
                {
                    "type": "paragraph",
                    "index": p_index,
                    "style": paragraph_style(child),
                    "text": text_of(child),
                }
            )
        elif child.tag == qn("tbl"):
            table_index += 1
            rows = []
            for tr in child.xpath("./w:tr", namespaces=NS):
                rows.append([text_of(tc) for tc in tr.xpath("./w:tc", namespaces=NS)])
            blocks.append({"type": "table", "index": table_index, "rows": rows})
    return blocks


def main() -> None:
    path = Path(sys.argv[1])
    with zipfile.ZipFile(path) as zf:
        names = set(zf.namelist())
        root = etree.fromstring(zf.read("word/document.xml"))
        comments = []
        if "word/comments.xml" in names:
            croot = etree.fromstring(zf.read("word/comments.xml"))
            for c in croot.xpath("//w:comment", namespaces=NS):
                comments.append(
                    {
                        "id": c.get(qn("id")),
                        "author": c.get(qn("author")),
                        "date": c.get(qn("date")),
                        "text": text_of(c),
                    }
                )

        deleted = [text_of(x) for x in root.xpath("//w:del", namespaces=NS)]
        inserted = [text_of(x) for x in root.xpath("//w:ins", namespaces=NS)]
        content_controls = []
        for sdt in root.xpath("//w:sdt", namespaces=NS):
            tag = sdt.xpath("./w:sdtPr/w:tag/@w:val", namespaces=NS)
            alias = sdt.xpath("./w:sdtPr/w:alias/@w:val", namespaces=NS)
            content_controls.append(
                {
                    "tag": tag[0] if tag else "",
                    "alias": alias[0] if alias else "",
                    "text": text_of(sdt),
                }
            )

        all_text = text_of(root)
        placeholders = sorted(
            set(
                re.findall(
                    r"(?im)^.*(?:todo|tbd|remaining|pending|not started|placeholder|insert |fill in|to be completed|\[.{0,80}\]|_{3,}).*$",
                    all_text,
                )
            )
        )

        result = {
            "path": str(path),
            "files": len(names),
            "blocks": ordered_blocks(root),
            "comments": comments,
            "tracked_deletions": deleted,
            "tracked_insertions": inserted,
            "content_controls": content_controls,
            "placeholder_candidates": placeholders,
            "headers_footers": {
                name: text_of(etree.fromstring(zf.read(name)))
                for name in sorted(names)
                if re.fullmatch(r"word/(?:header|footer)\d+\.xml", name)
            },
            "document_properties": {
                name: zf.read(name).decode("utf-8", errors="replace")
                for name in ("docProps/core.xml", "docProps/app.xml")
                if name in names
            },
        }
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
