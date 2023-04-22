function Set-LGSMConfig {
	param (
		[Parameter(Mandatory)][string]$ConfigPath,
		[Parameter(Mandatory)][string]$GameName,
		[Parameter(Mandatory)][byte]$HeadlessCount,
		[Parameter(Mandatory)][uint]$ServerPort,
		[ulong[]]$RequiredSteamModIds,
		[string[]]$DLCs,
		[string]$ServerPassword
	)
	#Get and validate paths
	if (!(Test-Path $ConfigPath)) {
		Write-Error "Could not resolve the path: $ConfigPath"
	}
	$serverPath = "$ConfigPath/$GameName.cfg"
	if (!(Test-Path $serverPath)) {
		Write-Error "Could not resolve the path: $serverPath"
	}
	$serverConfigFile = Get-Item $serverPath

	$headlessConfigFiles = New-Object System.Collections.Generic.List[psobject]
	for ($i = 1; $i -le $HeadlessCount; $i++) {
		$path = "$ConfigPath/$GameName-hc$i.cfg"
		if (!(Test-Path $path)) {
			Write-Error "Could not resolve the path: $path"
		}
		$headlessConfigFiles.Add((Get-Item $path))
	}

	$commonPath = "$ConfigPath/common.cfg"
	if (!(Test-Path $commonPath)) {
		Write-Error "Could not resolve the path: $commonPath"
	}
	$commonConfigFile = Get-Item $commonPath

	##Set main server
	$serverConfig = Get-ConfigFile $serverConfigFile
	Set-ConfigKey -Config $serverConfig -Name "startparameters" -Value "-ip=`${ip} -port=$ServerPort -cfg=`${networkcfgfullpath} -config=`${servercfgfullpath} -mod='`${mods}' -servermod=`${servermods} -bepath=`${bepath} -loadmissiontomemory"
	Set-ConfigFile -Config $serverConfig -ConfigFilePath $serverConfigFile.FullName

	##Set common
	$commonConfig = Get-ConfigFile $commonConfigFile
	#Set common mods
	$modList = New-Object System.Collections.Generic.List[string]
	foreach ($dlc in $DLCs) {
		$modList.Add($dlc)
	}
	foreach ($requiredSteamModId in $RequiredSteamModIds) {
		$modList.Add("mods/$requiredSteamModId")
	}
	Set-ConfigKey -Config $commonConfig -Name "mods" -Value ($modList -join ";")
	#Set common branch
	$branchValue = ""
	if ($DLCs.Count -gt 0) {
		$branchValue = "creatordlc"
	}
	Set-ConfigKey -Config $commonConfig -Name "branch" -Value $branchValue
	#Set common querymode
	Set-ConfigKey -Config $commonConfig -Name "querymode" -Value 1
	#Write content back to common.cfg
	Set-ConfigFile -Config $commonConfig -ConfigFilePath $commonConfigFile.FullName

	##Set headless
	foreach ($headlessConfigFile in $headlessConfigFiles) {
		$headlessConfig = Get-ConfigFile $headlessConfigFile
		if ([string]::IsNullOrWhiteSpace($ServerPassword)) {
			Set-ConfigKey -Config $headlessConfig -Name "startparameters" -Value "-client -connect=127.0.0.1:$ServerPort -mod='`${mods}'"
		}
		else {
			Set-ConfigKey -Config $headlessConfig -Name "startparameters" -Value "-client -connect=127.0.0.1:$ServerPort -password=$ServerPassword -mod='`${mods}'"
		}

		Set-ConfigFile -Config $headlessConfig -ConfigFilePath $headlessConfigFile.FullName
	}
	Write-Host "Updated the LGSM configuration"
}