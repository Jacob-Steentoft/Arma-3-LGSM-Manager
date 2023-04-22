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
if (!$Unattended) {
	Install-LGSM -RootPath $RootPath -GameName $gameName
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
