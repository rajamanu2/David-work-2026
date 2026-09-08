$ErrorActionPreference = 'Stop'
$renderTemp = 'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3386-render-temp'
New-Item -ItemType Directory -Path $renderTemp -Force | Out-Null
$env:TEMP = $renderTemp
$env:TMP = $renderTemp

& 'C:\Users\LIKKI\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  'C:\Users\LIKKI\.codex\plugins\cache\openai-primary-runtime\documents\26.813.12317\skills\documents\render_docx.py' `
  'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3386-architect-review.docx' `
  --output_dir 'C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3386-docx-qa' `
  --emit_pdf
