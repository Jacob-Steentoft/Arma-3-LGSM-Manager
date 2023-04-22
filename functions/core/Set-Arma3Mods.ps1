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