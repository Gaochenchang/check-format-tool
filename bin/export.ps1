New-Alias -Name check-format -Value "$PSScriptRoot\check_commit_format.exe" -Force
setx CHECK_TOOLS_PATH "$PSScripRoot"
set CHECK_TOOLS_PATH "$PSScripRoot"
if (-not $env:CHECK_REPO_PATH) {
	if ($env:ADF_PATH) {
		$env:CHECK_REPO_PATH = $env:ADF_PATH
	} else {
		Write-Host "Please run command: "
		Write-Host '       $env:CHECK_REPO_PATH = "your_repo_path"' -ForegroundColor DarkYellow
		Write-Host '       . ./export.sh' -ForegroundColor DarkYellow
		return 1
	}
} elseif (Test-Path $env:CHECK_REPO_PATH -PathType Container) {
	Set-Location -Path $env:CHECK_REPO_PATH
	$env:CHECK_REPO_PATH = Get-Location
	Set-Location -Path $PSScriptRoot
} else {
	Write-Host 'Path does not exist.' -ForegroundColor Red
	return 1
}

Write-Host "Notes: If you want to use this tool in other repositories, please use the following command to export CHECK_REPO_PATH"
Write-Host '       $env:CHECK_REPO_PATH = "your_repo_path"' -ForegroundColor DarkYellow
Write-Host '       . ./export.sh' -ForegroundColor DarkYellow
Write-Host ""
Write-Host "All done! You can now run:"
Write-Host ""
Write-Host "  check-format --help"  -ForegroundColor Green
Write-Host ""
