from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from lxml import etree


DOCX = Path(r"C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3655-architect-review.docx")


def mark_all_table_headers(path: Path) -> None:
    document = Document(path)
    for table in document.tables:
        row = table.rows[0]
        tr_pr = row._tr.get_or_add_trPr()
        existing = tr_pr.find(qn("w:tblHeader"))
        if existing is None:
            header = OxmlElement("w:tblHeader")
            header.set(qn("w:val"), "true")
            tr_pr.append(header)
    document.save(path)


def remove_unreferenced_images(path: Path) -> None:
    with ZipFile(path, "r") as source:
        members = {info.filename: source.read(info.filename) for info in source.infolist()}

    document_root = etree.fromstring(members["word/document.xml"])
    rels_root = etree.fromstring(members["word/_rels/document.xml.rels"])
    rel_ns = "http://schemas.openxmlformats.org/package/2006/relationships"
    office_rel_ns = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    referenced_ids = set(document_root.xpath("//@r:embed", namespaces={"r": office_rel_ns}))

    removed_targets = []
    for relationship in list(rels_root):
        rel_id = relationship.get("Id")
        rel_type = relationship.get("Type", "")
        target = relationship.get("Target", "")
        if rel_type.endswith("/image") and rel_id not in referenced_ids:
            rels_root.remove(relationship)
            removed_targets.append(target)

    members["word/_rels/document.xml.rels"] = etree.tostring(
        rels_root, xml_declaration=True, encoding="UTF-8", standalone="yes"
    )
    for target in removed_targets:
        normalized = str((Path("word") / target).as_posix())
        members.pop(normalized, None)

    with NamedTemporaryFile(suffix=".docx", delete=False, dir=path.parent) as temp_file:
        temp_path = Path(temp_file.name)
    try:
        with ZipFile(temp_path, "w", compression=ZIP_DEFLATED) as output:
            for name, data in members.items():
                output.writestr(name, data)
        temp_path.replace(path)
    finally:
        if temp_path.exists():
            temp_path.unlink()


mark_all_table_headers(DOCX)
remove_unreferenced_images(DOCX)
print(DOCX)
