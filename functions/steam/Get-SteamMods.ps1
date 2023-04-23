function Get-SteamMods {
	param (
		[Parameter(Mandatory)][ulong]$SteamAppId,
		[Parameter(Mandatory)][string]$SteamPath,
		[Parameter(Mandatory)][string]$Username,
		[Parameter(Mandatory)][string]$Password,
		[Parameter()][ulong[]]$SteamModIds,
		[hashtable]$SteamModLookup
	)

	[string[]]$stringArray = @("+@ShutdownOnFailedCommand 1", "+@NoPromptForPassword 1", "+force_install_dir $SteamPath", "+login $Username '$Password'")
	$stringBuilder = New-Object System.Text.StringBuilder
	$stringBuilder.AppendJoin([char]" ", $stringArray)

	foreach ($SteamModId in $SteamModIds) {
		$stringBuilder.Append("+workshop_download_item $SteamAppId $SteamModId ")
	}
	$stringBuilder.Append("+quit")

	$downloadRegex = New-Object regex -ArgumentList @("workshop_download_item \d* (?<modId>\d*) validate")
	$successRegex = New-Object regex -ArgumentList @("Success\.")
	Write-Host "Downloading or validating Steam mods..."

	$steamCommand = $stringBuilder.ToString()

	Invoke-Expression "steamcmd $steamCommand"
	
	<#
	for ($i = 0; $i -lt $steamlogs.Count; $i++) {
		if ($steamlogs[$i] -clike "*FAILED*" -or $steamlogs[$i] -like "*error*") {
			$steamlogs
			Write-Error "Steam failed to get mods"
		}

		$match = $downloadRegex.Match($steamlogs[$i])
		if ($match.Success) {
			$i += 2
			$mod = $SteamModLookup[($match.Groups["modId"].value)]
			if (!$successRegex.IsMatch($steamlogs[$i])) {
				$steamlogs
				Write-Error "Failed to download mod: $mod"
			}
			Write-Host "Successfully downloaded mod: $mod"
		}
	}
	#>
	Write-Host "Successfully updated Steam mods"
}