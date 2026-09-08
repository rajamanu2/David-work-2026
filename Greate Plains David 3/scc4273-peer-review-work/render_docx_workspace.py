from __future__ import annotations

import importlib.util
import os
import shutil
import sys
import uuid
from pathlib import Path


SKILL_RENDERER = Path(
    r"C:\Users\LIKKI\.codex\plugins\cache\openai-primary-runtime\documents\26.903.11726\skills\documents\render_docx.py"
)
TEMP_ROOT = Path(__file__).resolve().parent / "libreoffice-temp"


class WorkspaceTempDirectory:
    """TemporaryDirectory replacement for the Windows sandbox ACL boundary."""

    def __init__(self, suffix=None, prefix=None, dir=None, ignore_cleanup_errors=False):
        root = Path(dir) if dir else TEMP_ROOT
        root.mkdir(parents=True, exist_ok=True)
        self.name = str(root / f"{prefix or 'tmp'}{uuid.uuid4().hex}")
        Path(self.name).mkdir(parents=True, exist_ok=False)

    def __enter__(self):
        return self.name

    def __exit__(self, exc_type, exc, tb):
        # LibreOffice can retain Windows handles briefly. QA directories are
        # task-local and intentionally retained instead of risking cleanup errors.
        return False


def main() -> None:
    spec = importlib.util.spec_from_file_location("canonical_render_docx", SKILL_RENDERER)
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load the canonical render_docx.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.tempfile.TemporaryDirectory = WorkspaceTempDirectory
    canonical_convert = module.convert_to_pdf

    def convert_to_pdf(doc_path, user_profile, convert_tmp_dir, stem, verbose):
        if str(doc_path).lower().endswith(".pdf"):
            destination = Path(convert_tmp_dir) / f"{stem}.pdf"
            shutil.copy2(doc_path, destination)
            return str(destination), "PDF supplied by Microsoft Word export"
        return canonical_convert(doc_path, user_profile, convert_tmp_dir, stem, verbose)

    module.convert_to_pdf = convert_to_pdf
    module.main()


if __name__ == "__main__":
    main()
