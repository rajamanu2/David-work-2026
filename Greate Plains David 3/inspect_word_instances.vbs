On Error Resume Next
Set word = GetObject(, "Word.Application")
If Err.Number <> 0 Then
  WScript.Echo "NO_ACTIVE_WORD"
  WScript.Quit 1
End If
WScript.Echo "Visible=" & word.Visible & " Documents=" & word.Documents.Count
For i = 1 To word.Documents.Count
  Set document = word.Documents.Item(i)
  WScript.Echo "Doc[" & i & "]=" & document.FullName & " Saved=" & document.Saved
Next
