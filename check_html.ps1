Write-Host "Checking index.html using PowerShell..."
$filePath = "C:\Users\Bogdan\.gemini\antigravity\scratch\teritorii-franta\index.html"
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Check if world-data script exists
$worldDataStart = $content.IndexOf("<script id=""world-data"" type=""application/json"">")
if ($worldDataStart -eq -1) {
    Write-Host "ERROR: <script id=""world-data""> not found!" -ForegroundColor Red
} else {
    Write-Host "Found <script id=""world-data""> at index $worldDataStart"
    $jsonStart = $worldDataStart + "<script id=""world-data"" type=""application/json"">".Length
    $worldDataEnd = $content.IndexOf("</script>", $jsonStart)
    if ($worldDataEnd -eq -1) {
        Write-Host "ERROR: </script> for world-data not found!" -ForegroundColor Red
    } else {
        $jsonLength = $worldDataEnd - $jsonStart
        $jsonStr = $content.Substring($jsonStart, $jsonLength)
        Write-Host "Found world-data JSON of length: $($jsonStr.Length) characters."
        try {
            $obj = $jsonStr | ConvertFrom-Json
            Write-Host "SUCCESS: world-data JSON is perfectly valid!" -ForegroundColor Green
            Write-Host "JSON keys: $(($obj | Get-Member -MemberType NoteProperty).Name -join ', ')" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: world-data JSON parsing failed!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            # Print the end of the JSON to see if it is truncated
            $endLength = [System.Math]::Min(200, $jsonStr.Length)
            $startPos = $jsonStr.Length - $endLength
            Write-Host "Ending characters of JSON string:" -ForegroundColor Yellow
            Write-Host $jsonStr.Substring($startPos, $endLength) -ForegroundColor Yellow
        }
    }
}

# Find all <script> blocks
$offset = 0
$idx = 0
while ($true) {
    $scriptStart = $content.IndexOf("<script>", $offset)
    if ($scriptStart -eq -1) { break }
    $codeStart = $scriptStart + 8
    $scriptEnd = $content.IndexOf("</script>", $codeStart)
    if ($scriptEnd -eq -1) {
        Write-Host "ERROR: Script block starting at $scriptStart is not closed!" -ForegroundColor Red
        break
    }
    
    $codeLength = $scriptEnd - $codeStart
    $jsCode = $content.Substring($codeStart, $codeLength)
    Write-Host "Found <script> block #$idx of length: $($jsCode.Length) characters."
    
    # Check matching brackets/braces/parentheses in this JS code
    $stack = New-Object System.Collections.Generic.Stack[string]
    $mismatched = $false
    for ($i = 0; $i -lt $jsCode.Length; $i++) {
        $char = $jsCode[$i].ToString()
        if ($char -eq "(" -or $char -eq "{" -or $char -eq "[") {
            $stack.Push("$char,$i")
        } elseif ($char -eq ")" -or $char -eq "}" -or $char -eq "]") {
            if ($stack.Count -eq 0) {
                Write-Host "  Mismatched closing character '$char' at position $i" -ForegroundColor Red
                $mismatched = $true
            } else {
                $topVal = $stack.Pop()
                $parts = $topVal.Split(',')
                $topChar = $parts[0]
                $topPos = $parts[1]
                if (($char -eq ")" -and $topChar -ne "(") -or
                    ($char -eq "}" -and $topChar -ne "{") -or
                    ($char -eq "]" -and $topChar -ne "[")) {
                    Write-Host "  Mismatched opening/closing: '$topChar' at $topPos does not match '$char' at $i" -ForegroundColor Red
                    $mismatched = $true
                }
            }
        }
    }
    if ($stack.Count -gt 0) {
        Write-Host "  Unmatched opening characters left in stack: $($stack.Count)" -ForegroundColor Red
        $mismatched = $true
        # Print top 5 unmatched
        $count = 0
        while ($stack.Count -gt 0 -and $count -lt 5) {
            $topVal = $stack.Pop()
            Write-Host "    $topVal" -ForegroundColor Red
            $count++
        }
    }
    
    if (-not $mismatched) {
        $msg = "  Script block #" + $idx + ": bracket matching check passed!"
        Write-Host $msg -ForegroundColor Green
    }
    
    $offset = $scriptEnd + 9
    $idx++
}
