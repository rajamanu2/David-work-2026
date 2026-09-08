from hashlib import sha256
from pathlib import Path
import zipfile

root = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david")
reference = root / ".codex-work" / "SALDEV-1440-architect-review" / "SCC-3385-architect-review.docx"
final = root / "output" / "documents" / "SALDEV-1467-architect-review.docx"
expected_reference_hash = "A63491D6161B45ACC1C082B240AD46B7900D0506EFDE5A311F1C0504DB60E88C"
allowed = {
    "word/document.xml",
    "word/footer1.xml",
    "word/footer2.xml",
    "word/footer3.xml",
    "word/media/image3.png",
    "word/media/image4.png",
}

assert sha256(reference.read_bytes()).hexdigest().upper() == expected_reference_hash
with zipfile.ZipFile(reference) as a, zipfile.ZipFile(final) as b:
    assert a.namelist() == b.namelist(), "Package part inventory changed"
    changed = {name for name in a.namelist() if a.read(name) != b.read(name)}
    unexplained = changed - allowed
    missing_expected = {"word/document.xml", "word/media/image3.png", "word/media/image4.png"} - changed
    assert not unexplained, f"Unexpected changed parts: {sorted(unexplained)}"
    assert not missing_expected, f"Expected changed parts missing: {sorted(missing_expected)}"
    print("changed_parts=" + ",".join(sorted(changed)))
    print("unexplained_parts=0")
