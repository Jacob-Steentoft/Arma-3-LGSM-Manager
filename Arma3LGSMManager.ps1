#Requires -Version 7
param (
	[Parameter(Mandatory)][string]$RootPath,
	[Parameter(Mandatory)][uint]$ServerPort,
	[ulong]$SteamModCollectionId,
	[ulong[]]$SteamModIds,
	[ulong]$SteamWhitelistCollectionId,
	[ulong[]]$SteamWhitelistModIds,
	[string[]]$DLCs,
	[string]$ServerPassword,
	[byte]$HeadlessCount
)
$ErrorActionPreference = "Stop"
##FUNCTIONS
."$PSScriptRoot/functions/Import-Functions.ps1"

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
Set-HeadlessClients -RootPath $RootPath -GameName $gameName -HeadlessCount $HeadlessCount

Invoke-LGSMScripts -RootPath $RootPath -GameName $gameName -HeadlessCount $HeadlessCount -CMD "stop"

#Get Steam credentials from LGSM config
$steamCredentials = Get-LGSMSteamCredentials -CommonCfgPath "$lgsmConfigPath/common.cfg"

#Get required mods ids from Steam
if ($SteamModCollectionId -ne 0) {
	Write-Host "Using Steam mod collection for required mods"
	[long[]]$requiredSteamModIds = Get-SteamModCollection -ModCollectionSteamId $SteamModCollectionId
}
elseif ($SteamModIds.Length -ne 0) {
	Write-Host "Using Steam mod ids for required mods"
	[long[]]$requiredSteamModIds = $SteamModIds
}
else {
	Write-Host "No required mods were provided"
}

#Get whitelisted mods ids from Steam
if ($SteamWhitelistCollectionId -ne 0) {
	Write-Host "Using Steam mod collection for optional mods"
	[long[]]$optionalSteamModIds = Get-SteamModCollection -ModCollectionSteamId $SteamWhitelistCollectionId
}
elseif ($SteamWhitelistModIds.Length -ne 0) {
	Write-Host "Using Steam mod ids for optional mods"
	[long[]]$optionalSteamModIds = $SteamWhitelistModIds
}
else {
	Write-Host "No optional mods were provided"
}

#Download all mods and confiure the Arma 3 server to accept them
$totalMods = $optionalSteamModIds.Count + $requiredSteamModIds.Count
$steamModIds = New-Object long[] $totalMods

if ($requiredSteamModIds.Count -gt 0) {
	$requiredSteamModIds.CopyTo($steamModIds, 0)
}

if ($optionalSteamModIds.Count -gt 0) {
	$optionalSteamModIds.CopyTo($steamModIds, $requiredSteamModIds.Count)
}

$steamModLookup = Get-SteamModLookup -SteamModIds $steamModIds

Get-SteamMods -SteamPath $steamPath -SteamAppId $arma3ClientSteamAppId -SteamModIds $steamModIds -Username $steamCredentials.Username -Password $steamCredentials.Password -SteamModLookup $steamModLookup

Set-Arma3Mods -SteamPath $steamPath -ServerPath $serverPath -SteamAppId $arma3ClientSteamAppId -RequiredSteamModIds $requiredSteamModIds

Set-Arma3Keys -SteamPath $steamPath -ServerPath $serverPath -SteamAppId $arma3ClientSteamAppId -SteamModIds $steamModIds -StandardKeys $standardKeys

Set-LGSMConfig -ConfigPath $lgsmConfigPath -GameName $gameName -RequiredSteamModIds $requiredSteamModIds -DLC $DLCs -HeadlessCount $HeadlessCount -ServerPassword $ServerPassword -ServerPort $ServerPort

Invoke-LGSMScripts -RootPath $RootPath -GameName $gameName -CMD "update"
Invoke-LGSMScripts -RootPath $RootPath -GameName $gameName -HeadlessCount $HeadlessCount -CMD "start"
