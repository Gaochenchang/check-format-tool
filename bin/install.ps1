#!/usr/bin/env pwsh

# 修改执行策略为 Bypass
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install llvm
clang-format --version
Write-Host ""
Write-Host "Installation done! You can now run:"
Write-Host ""
Write-Host "  . ./export.sh"
Write-Host ""
#New-Alias -Name check-format -Value "$PSScriptRoot\check_commit_format.exe" -Force
