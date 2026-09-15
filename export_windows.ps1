# 导出 Windows EXE
# 前置：Godot 4.7.2 导出模板已安装到
#   %APPDATA%\Godot\export_templates\4.7.2.stable\
#   需要文件：windows_release_x86_64.exe / windows_debug_x86_64.exe
#
# 安装：编辑器 → 编辑器设置 / 管理导出模板 → 下载并安装
#
# 用法（在项目根目录）：
#   & "D:\lion\godot\Godot_v4.7.2-stable_win64.exe" --headless --path . --export-release "Windows Desktop" "exports\WOW_GodotDemo_最终完整版.exe"

$ErrorActionPreference = "Stop"
$godot = "D:\lion\godot\Godot_v4.7.2-stable_win64.exe"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $proj "exports\WOW_GodotDemo_最终完整版.exe"
New-Item -ItemType Directory -Force -Path (Join-Path $proj "exports") | Out-Null

& $godot --headless --path $proj --export-release "Windows Desktop" $exe
if (Test-Path $exe) {
  Write-Host "OK: $exe ($((Get-Item $exe).Length) bytes)"
} else {
  Write-Host "FAILED - 请确认导出模板已安装"
  exit 1
}
