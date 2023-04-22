function Set-HeadlessClients {
	param(
		[Parameter(Mandatory)][string]$RootPath,
		[Parameter(Mandatory)][string]$GameName,
		[Parameter(Mandatory)][sbyte]$HeadlessCount
	)
	$fileName = "linuxgsm.sh"
	$linuxgsmPath = "$RootPath/$fileName"
	$newInstancePath = "$RootPath/$GameName-2"
	$rootContent = Get-ChildItem $RootPath

	for ($i = 1; $i -le $HeadlessCount; $i++) {
		$instanceName = "$GameName-hc$i"
		if ($rootContent.Name -contains $instanceName) {
			continue
		}
		Invoke-Expression "bash $linuxgsmPath $GameName"

		if (!(Test-Path $newInstancePath)) {
			Write-Error "New instance was not created"
		}

		Rename-Item -Path $newInstancePath -NewName $instanceName

		$null = Invoke-Expression "$instanceName details"
		Write-Host "Created $instanceName"
	}
	
	Write-Host "All headless clients are ready"
}