Option Explicit
Dim word, document, docx, pdf

docx = "C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4166-architect-review-final.docx"
pdf = "C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc4166-docx-qa\SCC-4166-architect-review-final.pdf"

On Error Resume Next
Set word = GetObject(, "Word.Application")
If Err.Number <> 0 Then
  Err.Clear
  Set word = CreateObject("Word.Application")
End If
If Err.Number <> 0 Then
  WScript.Echo "WORD_ERROR " & Err.Number & " " & Err.Description
  WScript.Quit 1
End If

word.DisplayAlerts = 0
Set document = word.Documents.Open(docx, False, True)
If Err.Number <> 0 Then
  WScript.Echo "OPEN_ERROR " & Err.Number & " " & Err.Description
  WScript.Quit 2
End If

document.ExportAsFixedFormat pdf, 17
If Err.Number <> 0 Then
  WScript.Echo "EXPORT_ERROR " & Err.Number & " " & Err.Description
  document.Close 0
  WScript.Quit 3
End If

document.Close 0
WScript.Echo pdf
