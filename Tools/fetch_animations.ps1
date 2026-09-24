$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$revision = 'ccc61c4d8cdc1fb7188a60ba4f51f7a3cac51df9'
$destination = Join-Path $projectRoot 'Assets/Animations/MeleeLib.res'
Invoke-WebRequest "https://raw.githubusercontent.com/catprisbrey/Godot4-OpenAnimationLibraries/$revision/Libraries/Humanoid/MeleeLib.res" -OutFile $destination
Write-Output 'Melee library downloaded from the assignment reference. Open project.godot in Godot 4.7.2.'
