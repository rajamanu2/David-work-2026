import runpy
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
TMP = ROOT / "renderer-temp"
TMP.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(TMP)

RENDERER = Path(r"C:\Users\LIKKI\.codex\plugins\cache\openai-primary-runtime\documents\26.826.12353\skills\documents\render_docx.py")
sys.argv = [str(RENDERER), *sys.argv[1:]]
runpy.run_path(str(RENDERER), run_name="__main__")
