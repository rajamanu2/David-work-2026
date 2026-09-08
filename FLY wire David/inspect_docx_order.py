from pathlib import Path
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph
from docx.oxml.table import CT_Tbl
from docx.oxml.text.paragraph import CT_P
import sys


def blocks(doc):
    for child in doc.element.body.iterchildren():
        if isinstance(child, CT_P):
            yield Paragraph(child, doc)
        elif isinstance(child, CT_Tbl):
            yield Table(child, doc)


doc = Document(Path(sys.argv[1]))
for i, block in enumerate(blocks(doc), 1):
    if isinstance(block, Paragraph):
        print(f"{i:02d} P [{block.style.name}] {block.text!r}")
    else:
        print(f"{i:02d} TABLE {len(block.rows)}x{len(block.columns)}")
        for row in block.rows:
            print("   " + " | ".join(" ".join(c.text.split()) for c in row.cells))
