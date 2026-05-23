$filePath = "C:\Users\Bogdan\.gemini\antigravity\scratch\teritorii-marea-britanie\index.html"

# Read double-encoded file as bytes
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$corruptedString = [System.Text.Encoding]::UTF8.GetString($bytes)

# Convert using Windows-1252 to raw bytes, then decode as UTF-8
try {
    $rawBytes = [System.Text.Encoding]::GetEncoding("Windows-1252").GetBytes($corruptedString)
    $restoredString = [System.Text.Encoding]::UTF8.GetString($rawBytes)
    
    # Save back as clean UTF-8 (without BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($filePath, $restoredString, $utf8NoBom)
    
    Write-Host "SUCCESS: Double-encoding successfully reversed and file saved as clean UTF-8!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Encoding conversion failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
