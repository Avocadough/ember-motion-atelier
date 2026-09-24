$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$revision = 'ccc61c4d8cdc1fb7188a60ba4f51f7a3cac51df9'
$destination = Join-Path $projectRoot 'Assets/Animations/MeleeLib.res'
Invoke-WebRequest "https://raw.githubusercontent.com/catprisbrey/Godot4-OpenAnimationLibraries/$revision/Libraries/Humanoid/MeleeLib.res" -OutFile $destination
if ((Get-FileHash $destination -Algorithm SHA256).Hash -ne '7FA1B8EFB5AFDD962DA46F2B309CB5E4F3BD0886C5650C7C6BB91E04398BE8D6') { throw 'Animation library checksum mismatch.' }
Write-Output 'Melee library verified. Next run Godot --headless --path . --script res://Tools/prepare_animations.gd, then open project.godot.'
