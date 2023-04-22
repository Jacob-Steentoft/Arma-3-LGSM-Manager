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