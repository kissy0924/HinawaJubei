$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$path = Join-Path $PSScriptRoot 'index.html'
Copy-Item $path ($path + '.bak_titlebgm_only') -Force

$txt = Get-Content $path -Raw -Encoding UTF8

# setupAudio(): titleBgm(opning.mp3)を追加（既にあれば何もしない）
$needle = "this.pupSound = s('pup1.ogg'); // パワーアップ取得音"
if ($txt.Contains($needle) -and (-not $txt.Contains("this.titleBgm = s('opning.mp3');"))) {
  $insert = $needle + "`r`n                this.titleBgm = s('opning.mp3');`r`n                if (this.titleBgm) this.titleBgm.loop = true;"
  $pattern = [regex]::Escape($needle)
  $replacement = [System.Text.RegularExpressions.Regex]::Escape($insert)
  $txt = [regex]::Replace([string]$txt, $pattern, [System.Text.RegularExpressions.Regex]::Unescape($replacement), 1)
}

Set-Content $path -Value $txt -Encoding UTF8
Write-Host 'DONE'
