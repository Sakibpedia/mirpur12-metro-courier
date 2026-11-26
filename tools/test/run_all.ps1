# Runs all 15 courier jobs headlessly.
param([string]$Godot = "godot", [switch]$KeepLogs)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dir = Join-Path $PSScriptRoot "out"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$failed = @()
for ($j = 1; $j -le 15; $j++) {
    $env:JOB = "$j"
    $log = Join-Path $dir "job_$j.log"
    & $Godot --headless --path $root "res://tools/test/JobTest.tscn" *> $log
    $code = $LASTEXITCODE
    $line = (Select-String -Path $log -Pattern '\[JOB\]' | Select-Object -Last 1).Line
    Write-Output "J$j (exit $code): $line"
    if ($code -ne 0 -or $line -notmatch '\[JOB\] PASS') {
        $failed += $j
        Select-String -Path $log -Pattern 'FAIL|SCRIPT ERROR' | Select-Object -First 6 |
            ForEach-Object { Write-Output "    $($_.Line.Trim())" }
    }
    if (-not $KeepLogs) { Remove-Item $log -Force }
}
Remove-Item Env:JOB -ErrorAction SilentlyContinue
if ($failed.Count -gt 0) { throw "Failing jobs: $($failed -join ', ')" }
Write-Output "[JOB] ALL 15 JOBS PASS"
