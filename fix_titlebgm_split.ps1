$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$path = Join-Path $PSScriptRoot 'index.html'
Copy-Item $path ($path + '.bak_titlebgm_split') -Force

$txt = Get-Content $path -Raw -Encoding UTF8

# 1) hyoutan03: 中ボスでも分裂
$patternSplit = "if \(inv\.type\.splitInto && !inv\.isMidBoss\)"
$replacementSplit = "if (inv.type.splitInto && (!inv.isMidBoss || inv.typeName === 'hyoutan03'))"
if ($txt -match $patternSplit) {
  $txt = [regex]::Replace($txt, $patternSplit, $replacementSplit, 1)
}

# 2) setupAudio(): タイトルBGM(opning.mp3)追加
$patternAudio = "this\.pupSound\s*=\s*s\('pup1\.ogg'\);\s*\/\/ パワーアップ取得音"
$insAudio = "this.pupSound = s('pup1.ogg'); // パワーアップ取得音`r`n                this.titleBgm = s('opning.mp3');`r`n                if (this.titleBgm) this.titleBgm.loop = true;"
if (($txt -match $patternAudio) -and (-not $txt.Contains("this.titleBgm = s('opning.mp3');"))) {
  $txt = [regex]::Replace($txt, $patternAudio, [System.Text.RegularExpressions.Regex]::Escape($insAudio), 1)
  $txt = [System.Text.RegularExpressions.Regex]::Unescape($txt)
}

# 3) safePlay直後に playTitleBGM/stopTitleBGM 追加
$needleSafe = "safePlay(sound) { if (sound) { sound.currentTime = 0; sound.play().catch(()=>{}); } }"
if ($txt.Contains($needleSafe) -and -not $txt.Contains('playTitleBGM()')) {
  $insSafe = $needleSafe + @"

            playTitleBGM() {
                if (!this.titleBgm) return;
                try { this.titleBgm.play().catch(()=>{}); } catch(e) {}
            }
            stopTitleBGM() {
                if (!this.titleBgm) return;
                try { this.titleBgm.pause(); } catch(e) {}
            }
"@
  $txt = $txt.Replace($needleSafe, $insSafe)
}

# 4) init(): loadSecretUnlocks()の後に playTitleBGM()
$needleInit = 'this.loadSecretUnlocks();'
if ($txt.Contains($needleInit) -and -not $txt.Contains('this.playTitleBGM();')) {
  $txt = $txt.Replace($needleInit, "this.loadSecretUnlocks();`r`n                this.playTitleBGM();")
}

# 5) start(): ゲーム開始でタイトルBGM停止
$needleStart = "this.gameStartedInitiated = true; this.safePlay(this.startSound); this.ui.startScreen.classList.add('hidden'); this.ui.highScoreBoard.classList.add('hidden');"
if ($txt.Contains($needleStart) -and -not $txt.Contains('this.stopTitleBGM();')) {
  $txt = $txt.Replace($needleStart, $needleStart + "`r`n                this.stopTitleBGM();")
}

Set-Content $path -Value $txt -Encoding UTF8
Write-Host 'DONE'
