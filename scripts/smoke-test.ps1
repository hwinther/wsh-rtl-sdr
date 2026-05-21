<#
.SYNOPSIS
  Build + smoke-test one (or all) wsh-rtl-sdr image(s) in isolation, with no
  RTL-SDR hardware, via docker-compose.test.yml. Guarantees teardown.

.EXAMPLE
  pwsh scripts/smoke-test.ps1 dump1090-fa
  pwsh scripts/smoke-test.ps1 all

  Exits non-zero if any image fails its pass condition.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string] $Image
)

$ErrorActionPreference = 'Stop'
$RepoRoot     = Split-Path -Parent $PSScriptRoot
$ComposeFile  = Join-Path $RepoRoot 'docker-compose.test.yml'
$WaitTimeout  = if ($env:SMOKE_WAIT_TIMEOUT) { $env:SMOKE_WAIT_TIMEOUT } else { '300' }

# image -> pass condition: 'wait' (healthy/running via compose --wait) or
# 'runonce' (container must exit 0).
$Mode = [ordered]@{
  'dump1090-fa'  = 'wait'
  'ais-catcher'  = 'wait'
  'tar1090'      = 'wait'
  'piaware'      = 'wait'
  'fr24'         = 'wait'
  'adsbexchange' = 'wait'
  'opensky'      = 'wait'
  'gsm-tools'    = 'runonce'
}

function Invoke-Compose {
  param([string] $Profile, [string[]] $Args)
  & docker compose -f $ComposeFile --profile $Profile @Args
  return $LASTEXITCODE
}

function Remove-Stack {
  param([string] $Img)
  Write-Host "--- teardown: $Img"
  & docker compose -f $ComposeFile --profile $Img down -v --remove-orphans 2>&1 | Out-Null
}

function Test-Image {
  param([string] $Img)

  $mode = $Mode[$Img]
  if (-not $mode) { Write-Host "FAIL ${Img}: unknown image"; return $false }

  Write-Host "=== smoke: $Img (mode=$mode)"
  try {
    # Build first so a build failure (apt 404, disk full, etc.) is reported
    # distinctly from a runtime/health failure.
    if ((Invoke-Compose $Img @('build')) -ne 0) {
      Write-Host "FAIL ${Img}: BUILD FAILED (see output above)"; return $false
    }
    if ($mode -eq 'runonce') {
      if ((Invoke-Compose $Img @('up', '-d')) -ne 0) {
        Write-Host "FAIL ${Img}: up failed"; return $false
      }
      $cid = (& docker compose -f $ComposeFile --profile $Img ps -aq $Img | Select-Object -First 1)
      if (-not $cid) { Write-Host "FAIL ${Img}: no container created"; return $false }

      $waited = 0
      while ($true) {
        $status = (& docker inspect -f '{{.State.Status}}' $cid 2>$null)
        if (-not $status -or $status -eq 'exited') { break }
        if ($waited -ge 120) { Write-Host "FAIL ${Img}: did not exit within 120s"; return $false }
        Start-Sleep -Seconds 2; $waited += 2
      }
      $code = (& docker inspect -f '{{.State.ExitCode}}' $cid 2>$null)
      if ("$code" -ne '0') {
        Write-Host "FAIL ${Img}: binary-exists check exited $code"
        & docker logs $cid 2>&1 | Select-Object -Last 20
        return $false
      }
      Write-Host "PASS ${Img}: binaries present"
      return $true
    }

    # mode == wait: compose --wait blocks until every started container is
    # healthy (if it has a HEALTHCHECK) or running past its start period, and
    # returns non-zero if any becomes unhealthy or exits.
    if ((Invoke-Compose $Img @('up', '-d', '--wait', '--wait-timeout', $WaitTimeout)) -ne 0) {
      Write-Host "FAIL ${Img}: did not become healthy/stable within ${WaitTimeout}s"
      Invoke-Compose $Img @('ps') | Out-Null
      Invoke-Compose $Img @('logs', '--tail', '30', $Img) | Out-Null
      return $false
    }

    $cid = (& docker compose -f $ComposeFile --profile $Img ps -q $Img | Select-Object -First 1)
    if (-not $cid) { Write-Host "FAIL ${Img}: target container not found after up"; return $false }

    $running    = (& docker inspect -f '{{.State.Running}}' $cid)
    $restarting = (& docker inspect -f '{{.State.Restarting}}' $cid)
    $health     = (& docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' $cid)
    if ($running -ne 'true' -or $restarting -eq 'true') {
      Write-Host "FAIL ${Img}: container not stably running (running=$running restarting=$restarting)"
      & docker logs $cid 2>&1 | Select-Object -Last 30
      return $false
    }
    if ($health -ne 'none' -and $health -ne 'healthy') {
      Write-Host "FAIL ${Img}: healthcheck=$health"
      & docker logs $cid 2>&1 | Select-Object -Last 30
      return $false
    }
    Write-Host "PASS ${Img}: running (health=$health)"
    return $true
  }
  finally {
    Remove-Stack $Img
  }
}

$images = if ($Image -eq 'all') { @($Mode.Keys) } else { @($Image) }

$summary = @()
$rc = 0
foreach ($img in $images) {
  if (Test-Image $img) { $summary += "PASS $img" } else { $summary += "FAIL $img"; $rc = 1 }
}

Write-Host ''
Write-Host '===== smoke summary ====='
$summary | ForEach-Object { Write-Host $_ }
exit $rc
