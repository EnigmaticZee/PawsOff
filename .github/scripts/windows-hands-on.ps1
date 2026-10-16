# Hands-on test of the Windows app on a clean machine, like a person would use it: start it, lock with
# the button and with the shortcut, prove typing is blocked, unlock with a click, the shortcut and the
# unlock word, and check it stays healthy. A screenshot of every step goes to hands-on/.
param([string]$Exe = "out\PawsOff.exe")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, UIAutomationClient, UIAutomationTypes
New-Item -ItemType Directory -Force hands-on | Out-Null
$script:n = 0
$failures = @()

function Shot($name) {
  $script:n++
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  [System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save(("hands-on\{0:D2}-{1}.png" -f $script:n, $name))
}
function Pump($ms) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.ElapsedMilliseconds -lt $ms) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 20 }
}
function Check($what, $ok) {
  if ($ok) { Write-Host "PASS  $what" } else { Write-Host "FAIL  $what"; $script:failures += $what }
}

# A text box to type into: whatever reaches it got past Paws Off.
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Typing test'; $form.Width = 520; $form.Height = 160; $form.StartPosition = 'Manual'; $form.Location = '40,40'; $form.TopMost = $true
$box = New-Object System.Windows.Forms.TextBox
$box.Dock = 'Fill'; $box.Multiline = $true; $box.Font = New-Object System.Drawing.Font('Segoe UI', 18)
$form.Controls.Add($box); $form.Show(); Pump 500

function Focus-Box { $form.Activate(); $box.Focus() | Out-Null; Pump 300 }
function Type-Text($keys) { Focus-Box; [System.Windows.Forms.SendKeys]::SendWait($keys); Pump 800 }
function Typed { $t = $box.Text; $box.Text = ''; Pump 100; return $t }
function Shortcut { Focus-Box; [System.Windows.Forms.SendKeys]::SendWait('^%+l'); Pump 1000 }

function Start-App {
  $p = Start-Process -FilePath $Exe -PassThru
  Pump 5000
  if ($p.HasExited) { throw "Paws Off exited right after starting (code $($p.ExitCode))" }
  return $p
}
function Big-Button($p) {
  $root = [Windows.Automation.AutomationElement]::RootElement
  $byPid = New-Object Windows.Automation.PropertyCondition ([Windows.Automation.AutomationElement]::ProcessIdProperty), $p.Id
  foreach ($w in $root.FindAll([Windows.Automation.TreeScope]::Children, $byPid)) {
    $byId = New-Object Windows.Automation.PropertyCondition ([Windows.Automation.AutomationElement]::AutomationIdProperty), 'BigButton'
    $b = $w.FindFirst([Windows.Automation.TreeScope]::Descendants, $byId)
    if ($b) { return $b }
  }
  throw "Couldn't find the big button"
}
function Click-Big($p) { (Big-Button $p).GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke(); Pump 1200 }

# ---- Clean mode, a fresh install (first run opens the window) ----
Remove-Item 'HKCU:\Software\PawsOff' -Recurse -ErrorAction SilentlyContinue
$app = Start-App
Shot 'started'
Type-Text 'abc'; Check 'typing works before locking' ((Typed) -eq 'abc')

Click-Big $app; Shot 'locked-with-the-button'
Type-Text 'secret'; Check 'locked (button): typing is blocked' ((Typed) -eq '')
Shot 'typing-blocked'
Click-Big $app
Type-Text 'def'; Check 'unlocked (button): typing works again' ((Typed) -eq 'def')

Shortcut; Shot 'locked-with-the-shortcut'
Type-Text 'xyz'; Check 'locked (shortcut): typing is blocked' ((Typed) -eq '')
Shortcut
Type-Text 'ghi'; $t = Typed; Check 'unlocked (shortcut): typing works again' ($t -eq 'ghi')
if ($t -ne 'ghi') { Click-Big $app; Pump 500; $null = Typed } # don't leave it locked for the next steps

# ---- Away mode: unlock with the word ----
Stop-Process -Id $app.Id -Force; Pump 1500
New-Item 'HKCU:\Software\PawsOff' -Force | Out-Null
Set-ItemProperty 'HKCU:\Software\PawsOff' -Name Mode -Value 'Away'
$app = Start-App
Shot 'away-mode'
Click-Big $app; Shot 'away-locked'
Type-Text 'hello'; Check 'Away locked: typing is blocked' ((Typed) -eq '')
Type-Text 'unlock'; Pump 600; Shot 'after-typing-unlock'
Type-Text 'jkl'; Check 'Away: typing "unlock" unlocks' ((Typed) -eq 'jkl')

# ---- Health ----
$cpu0 = (Get-Process -Id $app.Id).TotalProcessorTime; Pump 10000
$proc = Get-Process -Id $app.Id
$idleCpu = ($proc.TotalProcessorTime - $cpu0).TotalSeconds
$mem = [math]::Round($proc.WorkingSet64 / 1MB)
Write-Host "Idle for 10 s: $([math]::Round($idleCpu, 2)) s of CPU, $mem MB of memory"
Check 'still running' (-not $proc.HasExited)
Check 'quiet when idle (under 0.5 s CPU in 10 s)' ($idleCpu -lt 0.5)
Check 'reasonable memory (under 250 MB)' ($mem -lt 250)
$errors = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = (Get-Date).AddMinutes(-10) } -ErrorAction SilentlyContinue |
  Where-Object { $_.ProviderName -in '.NET Runtime', 'Application Error' -and $_.Message -match 'PawsOff' }
Check 'no crashes or .NET errors in the event log' (-not $errors)
if ($errors) { $errors | Select-Object -First 3 | Format-List TimeCreated, ProviderName, Message }

Shot 'end'
Stop-Process -Id $app.Id -Force -ErrorAction SilentlyContinue
$form.Close()
if ($failures.Count) { throw "Failed: $($failures -join '; ')" }
Write-Host 'All hands-on checks passed'
