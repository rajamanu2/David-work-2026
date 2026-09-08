param(
    [Parameter(Mandatory = $true)]
    [string]$AudioPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech

$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$recognizer.LoadGrammar($grammar)
$recognizer.SetInputToWaveFile($AudioPath)

$segments = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$completed = New-Object System.Threading.AutoResetEvent($false)

$speechHandler = [System.EventHandler[System.Speech.Recognition.SpeechRecognizedEventArgs]] {
    param($sender, $eventArgs)
    $result = $eventArgs.Result
    $position = $result.Audio.AudioPosition
    $stamp = '{0:00}:{1:00}' -f [math]::Floor($position.TotalMinutes), $position.Seconds
    $line = '[{0}] confidence={1:N2} {2}' -f $stamp, $result.Confidence, $result.Text
    [void]$segments.Add($line)
}

$completeHandler = [System.EventHandler[System.Speech.Recognition.RecognizeCompletedEventArgs]] {
    param($sender, $eventArgs)
    [void]$completed.Set()
}

$recognizer.add_SpeechRecognized($speechHandler)
$recognizer.add_RecognizeCompleted($completeHandler)

try {
    $recognizer.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
    [void]$completed.WaitOne()
    [System.IO.File]::WriteAllLines($OutputPath, [string[]]$segments, [System.Text.Encoding]::UTF8)
    Write-Output ('Segments=' + $segments.Count)
    Write-Output ('Transcript=' + $OutputPath)
}
finally {
    $recognizer.RecognizeAsyncCancel()
    $recognizer.remove_SpeechRecognized($speechHandler)
    $recognizer.remove_RecognizeCompleted($completeHandler)
    $recognizer.Dispose()
    $completed.Dispose()
}
