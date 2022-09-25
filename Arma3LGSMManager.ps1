#Requires -Version 7
param (
	[Parameter(Mandatory)][string]$RootPath,
	[ulong]$SteamModCollectionId,
	[ulong[]]$SteamModIds,
	[ulong]$SteamWhitelistCollectionId,
	[ulong[]]$SteamWhitelistModIds,
	[string[]]$DLCs,
	[Parameter(Mandatory)][uint]$ServerPort,
	[string]$ServerPassword,
	[byte]$HeadlessCount,
	[switch]$SkipRestart,
	[switch]$Unattended
)
$ErrorActionPreference = "Stop"
##FUNCTIONS
function Set-ConfigKey {
	param(
		[Parameter(Mandatory)][hashtable]$Config,
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)]$Value
	)
	if ([string]::IsNullOrEmpty($Name)) {
		Write-Error "Name cannot be empty"
	}

	if ($Config[$Name] -ne $Value) {
		if (!$Config.ContainsKey($Name)) {
			$Config.Add($Name, $Value)
		}
		else {
			$Config[$Name] = $Value
		}
		Write-Host "Updated the key $Name"
	}
}
function Set-ConfigFile {
	param(
		[Parameter(Mandatory)][hashtable]$Config,
		[Parameter(Mandatory)][string]$ConfigFilePath
	)
	if (!(Test-Path $ConfigFilePath)) {
		Write-Error "Unable to resolve the path: $ConfigFilePath"
	}
	$content = New-Object System.Collections.Generic.List[string]
	foreach ($pair in $Config.GetEnumerator()) {
		$content.Add("$($pair.Key)=`"$($pair.Value)`"")
	}
	Set-Content -Value $content -Path $ConfigFilePath
}
function Get-ConfigFile {
	param(
		[Parameter(Mandatory)][string]$ConfigPath
	)
	if (!(Test-Path $ConfigPath)) {
		Write-Error "Unable to resolve the config path: $ConfigPath"
	}
	$regexExpression = "(?<=[`"']).*(?=[`"'])"
	$regex = New-Object regex -ArgumentList @($regexExpression)

	$configRaw = Get-Content $ConfigPath -Raw | ConvertFrom-StringData

	$configContent = New-Object hashtable
	foreach ($pair in $configRaw.GetEnumerator()) {
		if ($configContent.ContainsKey($pair.Key)) {
			Write-Error "Found dublicate key for: $($pair.Key)"
		}

		$result = $regex.Match($pair.Value)
		if (!$result.Success) {
			Write-Error "Content did not match the expression: $regexExpression"
		}
		if ($result.Captures.Count -ne 1) {
			Write-Error "Found too much data. Please validate : $($result.ValueSpan)"
		}

		$configContent.Add($pair.Key, $result.Captures[0].Value)
	}

	return $configContent
}
function Install-LGSM {
	param(
		[Parameter(Mandatory)][string]$RootPath,
		[Parameter(Mandatory)][string]$GameName,
		[Parameter(Mandatory)][string]$ServerPath
	)
	$fileName = "linuxgsm.sh"
	$linuxgsmPath = "$RootPath/$fileName"

	if (Test-Path "$ServerPath/arma3server") {
		Write-Host "Base instance has already been configured"
		return
	}

	if (!(Test-Path $linuxgsmPath)) {
		Write-Host "Downloading linuxgsm.sh"
		Invoke-RestMethod "https://$fileName" -OutFile $linuxgsmPath
		if (!(Test-Path $linuxgsmPath)) {
			Write-Error "LGSM script was not downloaded. Please refer to above error"
		}
	}

	$currectPath = Get-Location
	Set-Location $RootPath
	Invoke-Expression "chmod +x $linuxgsmPath"

	$gamePath = "$RootPath/$GameName"
	if (!(Test-Path $gamePath)) {
		Invoke-Expression "bash $fileName $GameName"
		Start-Sleep -Seconds 1
		if (!(Test-Path $gamePath)) {
			Set-Location $currectPath
			Write-Error "LGSM server script was not created. Please refer to above error"
		}
	}

	Invoke-Expression "chmod +x $gamePath"
	Invoke-Expression "$gamePath install" | Tee-Object linuxgsmLog
	if ($linuxgsmLog -clike "*FAIL*") {
		Set-Location $currectPath
		Write-Error "Failed to install Arma 3 Server. Please refer to the error and try again"
	}
	Set-Location $currectPath
	Write-Host "Installed Arma 3 through LGSM"
}
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
function Invoke-LGSMScripts {
	param(
		[Parameter(Mandatory)][string]$RootPath,
		[Parameter(Mandatory)][string]$GameName,
		[byte]$HeadlessCount,
		[Parameter(Mandatory)][string]$CMD
	)
	$serverInstancePath = "$RootPath/$GameName"
	if (!(Test-Path $serverInstancePath)) {
		Write-Error "Unable to resolve the path: $RootPath"
	}

	if ($HeadlessCount -ne 0) {
		$headlessFiles = New-Object System.Collections.Generic.List[string]
		for ($i = 1; $i -le $HeadlessCount; $i++) {
			$path = "$RootPath/$GameName-hc$i"
			if (!(Test-Path $path)) {
				Write-Error "Could not resolve the path: $path"
			}
			$headlessFiles.Add($path)
		}
	}
	
	switch ($CMD) {
		start {
			Invoke-Expression "bash $serverInstancePath $CMD"
			foreach ($headlessFile in $headlessFiles) {
				Invoke-Expression "bash $headlessFile $CMD"
			}
			break
		}
		stop {
			Invoke-Expression "bash $serverInstancePath $CMD"
			foreach ($headlessFile in $headlessFiles) {
				Invoke-Expression "bash $headlessFile $CMD"
			}
			break
		}
		restart {
			Invoke-Expression "bash $serverInstancePath $CMD"
			foreach ($headlessFile in $headlessFiles) {
				Invoke-Expression "bash $headlessFile $CMD"
			}
			break
		}
		update {
			bash $serverInstancePath $CMD
			break
		}
		Default {
			Write-Error "Please use one of the following commands: start, stop, restart, update"
		}
	}
}
function Get-SteamModCollection {
	param (
		[Parameter(Mandatory)][ulong]$ModCollectionSteamId
	)
	$response = Invoke-RestMethod "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/" -Method Post -Body @{
		collectioncount       = 1
		"publishedfileids[0]" = $ModCollectionSteamId
	}

	$steamModIds = $response.response.collectiondetails.children.publishedfileid

	if ($steamModIds.Count -eq 0) {
		Write-Error "No workshop steam mods found"
	}

	return $steamModIds
}
function Get-SteamModLookup {
	param(
		[Parameter(Mandatory)][ulong[]]$SteamModIds
	)
	$query = @{
		itemcount = $SteamModIds.Length
	}
	for ($i = 0; $i -lt $SteamModIds.Length; $i++) {
		if ($query.ContainsKey($SteamModIds[$i])) {
			Write-Error "Steam Mod Ids cannot contain dublicate: $($SteamModIds[$i])"
		}
		$query.Add("publishedfileids[$i]", $SteamModIds[$i])
	}

	$response = Invoke-RestMethod "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" -Method Post -Body $query

	$lookup = New-Object hashtable
	foreach ($publishedFileDetail in $response.response.publishedfiledetails) {
		if ($lookup.ContainsKey($publishedFileDetail.publishedfileid)) {
			continue
		}
		$lookup.Add($publishedFileDetail.publishedfileid, $publishedFileDetail.title)
	}

	return $lookup
}
function Get-LGSMSteamCredentials {
	param(
		[Parameter(Mandatory)][string]$CommonCfgPath
	)
	if (!(Test-Path $CommonCfgPath)) {
		Write-Error "Did not find config path at $CommonCfgPath"
	}
	$commonCfg = Get-ConfigFile -ConfigPath $CommonCfgPath

	#Validate
	$keys = @("steamuser", "steampass")
	foreach ($key in $keys) {
		if (!$commonCfg.ContainsKey($key)) {
			Write-Error "Cannot find the key '$key' in: $CommonCfgPath"
		}
		if ([string]::IsNullOrWhiteSpace($commonCfg[$key])) {
			Write-Error "$key cannot be empty"
		}
		
	}

	return @{
		Username = $commonCfg["steamuser"]
		Password = $commonCfg["steampass"]
	}
}
function Get-SteamMods {
	param (
		[Parameter(Mandatory)][ulong]$SteamAppId,
		[Parameter(Mandatory)][string]$SteamPath,
		[Parameter(Mandatory)][string]$Username,
		[Parameter(Mandatory)][string]$Password,
		[Parameter()][ulong[]]$SteamModIds,
		[hashtable]$SteamModLookup
	)
	$steamCMDScriptName = "steamcmdlist"
	$steamCMDScriptPath = "$SteamPath/$steamCMDScriptName"
	if (!(Test-Path $steamCMDScriptPath)) {
		New-Item -Path $SteamPath -ItemType File -Name $steamCMDScriptName > $null
	}

	[string[]]$stringArray = @("@ShutdownOnFailedCommand 1", "@NoPromptForPassword 1", "force_install_dir $SteamPath", "login $Username $Password")
	$scriptContent = New-Object System.Collections.Generic.List[string] -ArgumentList (, $stringArray)

	foreach ($SteamModId in $SteamModIds) {
		$scriptContent.Add("workshop_download_item $SteamAppId $SteamModId validate")
	}
	$scriptContent.Add("quit")

	Set-Content -Value $scriptContent -Path $steamCMDScriptPath

	$downloadRegex = New-Object regex -ArgumentList @("workshop_download_item \d* (?<modId>\d*) validate")
	$successRegex = New-Object regex -ArgumentList @("Success\.")
	Write-Host "Downloading or validating Steam mods..."

	$steamlogs = Invoke-Expression "steamcmd +runscript $steamCMDScriptPath"
	for ($i = 0; $i -lt $steamlogs.Count; $i++) {
		if ($steamlogs[$i] -clike "*FAILED*" -or $steamlogs[$i] -like "*error*") {
			$steamlogs
			Remove-Item $steamCMDScriptPath -Force
			Write-Error "Steam failed to get mods"
		}

		$match = $downloadRegex.Match($steamlogs[$i])
		if ($match.Success) {
			$i += 2
			$mod = $SteamModLookup[($match.Groups["modId"].value)]
			if (!$successRegex.IsMatch($steamlogs[$i])) {
				$steamlogs
				Remove-Item $steamCMDScriptPath -Force
				Write-Error "Failed to download mod: $mod"
			}
			Write-Host "Successfully downloaded mod: $mod"
		}
	}
	Write-Host "Successfully updated Steam mods"

	Remove-Item $steamCMDScriptPath -Force
}
function Set-Arma3Mods {
	param (
		[Parameter(Mandatory)][string]$ServerPath,
		[Parameter(Mandatory)][ulong]$SteamAppId,
		[Parameter(Mandatory)][string]$SteamPath,
		[ulong[]]$RequiredSteamModIds
	)
	#Create mods folder if it's not there
	if (!(Test-Path $ServerPath)) {
		Write-Error "Unable to find the server path at: $ServerPath"
	}
	if (!(Test-Path "$ServerPath/mods")) {
		New-Item -Path $ServerPath -ItemType Directory -Name "mods"
	}
	#Validate mod path and get children
	$steamModsPath = "$SteamPath/steamapps/workshop/content/$SteamAppId"
	if (!(Test-Path $steamModsPath)) {
		Write-Error "Unable to find the steam mod content at: $steamModsPath"
	}
	$currentSymlinks = Get-ChildItem -Path "$ServerPath/mods"
	#Setup each required mod
	$currentMods = Get-ChildItem -Path $steamModsPath
	foreach ($requiredSteamModId in $RequiredSteamModIds) {
		$currentMod = $currentMods | Where-Object Name -EQ $requiredSteamModId
		if ($null -eq $currentMod) {
			Write-Error "The required mod was not found in the steam download folder"
		}
		#Lowering case for directories to make readable by server
		$uppercaseDirs = Get-ChildItem -Path $currentMod -Directory -Include @("addons", "keys") | Where-Object { $_.Name -cne $_.Name.ToLower() }
		foreach ($uppercaseDir in $uppercaseDirs) {
			Rename-Item $uppercaseDir -NewName { $_.Name.ToLower() } -Force
		}
		#Lowering case for .pbo files to make readable by server
		$uppercaseFiles = Get-ChildItem -Directory -Filter "addons" | Get-ChildItem -Filter "*.pbo" -Recurse | Where-Object { $_.Name -cne $_.Name.ToLower() }
		foreach ($uppercaseFile in $uppercaseFiles) {
			Rename-Item $uppercaseFile -NewName { $_.Name.ToLower() } -Force
		}
		#Create or update symlink if necessary
		$currentSymlink = $currentSymlinks | Where-Object Name -EQ $currentMod.Name
		$symlinkPath = "$ServerPath/mods/$($currentMod.Name)"
		if ($null -eq $currentSymlink) {
			$null = New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $currentMod.FullName
			Write-Host "Created symlink for Steam mod id: $($currentMod.Name)"
			continue
		}

		if ($currentSymlink.Target -ne $currentMod.FullName) {
			Remove-Item $symlinkPath -Force
			$null = New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $currentMod.FullName
			Write-Host "Updated symlink for Steam mod id: $($currentMod.Name)"
		}
	}
	#Remove uncessary mods
	foreach ($currentSymlink in $currentSymlinks) {
		if ($RequiredSteamModIds -contains $currentSymlink.Name) {
			continue
		}
		Remove-Item $currentSymlink -Force
		Write-Host "Removed symlink for Steam mod id: $($currentSymlink.Name)"
	}
	Write-Host "Created symlinks for all mods"
}
function Set-Arma3Keys {
	param (
		[Parameter(Mandatory)][string]$ServerPath,
		[Parameter(Mandatory)][string]$SteamPath,
		[Parameter(Mandatory)][string[]]$StandardKeys,
		[Parameter(Mandatory)][ulong]$SteamAppId,
		[ulong[]]$SteamModIds
	)
	#Validate paths
	$steamModsPath = "$SteamPath/steamapps/workshop/content/$SteamAppId"
	if (!(Test-Path $steamModsPath)) {
		Write-Error "Unable to find the steam mod content at: $steamModsPath"
	}
	$armaKeyPath = "$ServerPath/keys"
	if (!(Test-Path $armaKeyPath)) {
		New-Item -Path $ServerPath -ItemType Directory -Name "keys"
	}
	#Delete all keys to add new ones
	$armaKeys = Get-ChildItem -Path $armaKeyPath
	foreach ($armaKey in $armaKeys) {
		if ($StandardKeys -contains $armaKey.Name) {
			continue
		}
		Remove-Item $armaKey -Force
	}
	#Copy mod steam mod keys to the Arma 3 server keys folder
	Get-ChildItem -Path $steamModsPath | Where-Object { $_.Name -in $SteamModIds } | Get-ChildItem -Directory -Filter "key*" | Get-ChildItem -Filter "*.bikey" -Recurse | Copy-Item -Destination "$ServerPath/keys" -Force
	Write-Host "Updated all Arma 3 keys"
}
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
##VARIABLES
#Standard keys that are necessary for arma 3
$standardKeys = @("a3.bikey", "a3c.bikey", "csla.bikey", "gm.bikey", "vm.bikey", "vn.bikey", "ws.bikey")
#SteamId for the client for download of mods
$arma3ClientSteamAppId = 107410
#LGSM game name
$gameName = "arma3server"

#Directory references
$serverPath = "$RootPath/serverfiles"
$steamPath = "$RootPath/.steam/steam"
$lgsmConfigPath = "$RootPath/lgsm/config-lgsm/$gameName"

##RUN
if (!$Unattended) {
	Install-LGSM -RootPath $RootPath -GameName $gameName -ServerPath $serverPath
}

Set-HeadlessClients -RootPath $RootPath -GameName $gameName -HeadlessCount $HeadlessCount

If (!$SkipRestart) {
	Invoke-LGSMScripts -RootPath $RootPath -GameName $gameName -HeadlessCount $HeadlessCount -CMD "stop"
}

#Get Steam credentials from LGSM config
$steamCredentials = Get-LGSMSteamCredentials -CommonCfgPath "$lgsmConfigPath/common.cfg"

#Get required mods ids from Steam
if ($SteamModCollectionId -ne 0) {
	Write-Host "Using Steam mod collection for required mods"
	$requiredSteamModIds = Get-SteamModCollection -ModCollectionSteamId $SteamModCollectionId
}
elseif ($SteamModIds.Length -ne 0) {
	Write-Host "Using Steam mod ids for required mods"
	$requiredSteamModIds = $SteamModIds
}
else {
	Write-Host "No required mods were provided"
}

#Get whitelisted mods ids from Steam
if ($SteamWhitelistCollectionId -ne 0) {
	Write-Host "Using Steam mod collection for optional mods"
	$optionalSteamModIds = Get-SteamModCollection -ModCollectionSteamId $SteamWhitelistCollectionId
}
elseif ($SteamWhitelistModIds.Length -ne 0) {
	Write-Host "Using Steam mod ids for optional mods"
	$optionalSteamModIds = $SteamWhitelistModIds
}
else {
	Write-Host "No optional mods were provided"
}

#Download all mods and confiure the Arma 3 server to accept them
$steamModIds = $requiredSteamModIds + $optionalSteamModIds | Where-Object { $_ -ne 0 }

$steamModLookup = Get-SteamModLookup -SteamModIds $steamModIds

Get-SteamMods -SteamPath $steamPath -SteamAppId $arma3ClientSteamAppId -SteamModIds $steamModIds -Username $steamCredentials.Username -Password $steamCredentials.Password -SteamModLookup $steamModLookup

Set-Arma3Mods -SteamPath $steamPath -ServerPath $serverPath -SteamAppId $arma3ClientSteamAppId -RequiredSteamModIds $requiredSteamModIds

Set-Arma3Keys -SteamPath $steamPath -ServerPath $serverPath -SteamAppId $arma3ClientSteamAppId -SteamModIds $steamModIds -StandardKeys $standardKeys

Set-LGSMConfig -ConfigPath $lgsmConfigPath -GameName $gameName -RequiredSteamModIds $requiredSteamModIds -DLC $DLCs -HeadlessCount $HeadlessCount -ServerPassword $ServerPassword -ServerPort $ServerPort

If (!$SkipRestart) {
	Invoke-LGSMScripts -RootPath $RootPath -GameName $gameName -CMD "update"
	Invoke-LGSMScripts -RootPath $RootPath -GameName $gameName -HeadlessCount $HeadlessCount -CMD "start"
}
