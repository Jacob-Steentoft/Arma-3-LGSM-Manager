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