function Set-Arma3Mods {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)][string]$ServerPath,
		[Parameter(Mandatory)][ulong]$SteamAppId,
		[Parameter(Mandatory)][string]$SteamPath,
		[ulong[]]$RequiredSteamModIds
	)
	#Create mods folder if it's not there
	$serverModsPath = "$ServerPath/mods"
	if (!(Test-Path $ServerPath)) {
		Write-Error "Unable to find the server path at: $ServerPath"
	}

	if (!(Test-Path $serverModsPath)) {
		New-Item -Path $ServerPath -ItemType Directory -Name "mods"
	}

	#Validate mod path and get children
	$steamModsPath = "$SteamPath/steamapps/workshop/content/$SteamAppId"
	if (!(Test-Path $steamModsPath)) {
		Write-Error "Unable to find the steam mod content at: $steamModsPath"
	}

	#Setup each required mod
	$steamModDirectories = Get-ChildItem -Path $steamModsPath -Directory
	$steamModsDictionary = [System.Collections.Generic.Dictionary[long, System.IO.DirectoryInfo]]::New()

	[long]$modId = 0
	foreach ($steamModDirectory in $steamModDirectories) {
		if (![long]::TryParse($steamModDirectory.Name, [ref]$modId)) {
			Write-Error "Directory '$($steamModDirectory.Name)' is not a mod ID"
		}
		
		$steamModsDictionary.Add($modId, $steamModDirectory)
	}

	$currentSymlinks = Get-ChildItem -Path $serverModsPath -Directory
	[System.IO.DirectoryInfo]$steamModDirectory = $null
	foreach ($requiredSteamModId in $RequiredSteamModIds) {
		if (!$steamModsDictionary.TryGetValue($requiredSteamModId, [ref]$steamModDirectory)) {
			Write-Error "The required mod was not found in the steam download folder"
		}

		#Lowering case for directories to make readable by server
		$directories = Get-ChildItem -Path $steamModDirectory -Directory -Recurse

		foreach ($directory in $directories) {
			Rename-DirectoryToLowerCase -Directory $directory
		}

		#Lowering case for .pbo files to make readable by server
		$files = Get-ChildItem -Path $steamModDirectory -File -Filter "*.pbo" -Recurse
		foreach ($file in $files) {
			Rename-FileToLowerCase -File $file
		}
		
		#Create or update symlink if necessary
		$foundSymlink = $false
		foreach ($currentSymlink in $currentSymlinks) {
			if ($currentSymlink.Name -ne $steamModDirectory.Name) {
				continue
			}

			$foundSymlink = $true

			if ($currentSymlink.Target -ne $steamModDirectory.FullName) {
				$symlinkPath = Join-Path -Path $serverModsPath -ChildPath $steamModDirectory.Name
				Remove-Item $symlinkPath -Force

				$null = New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $steamModDirectory.FullName -Force

				Write-Host "Updated symlink for Steam mod id: $($currentMod.Name)"
				break
			}
		}

		if (!$foundSymlink) {
			$null = New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $steamModDirectory.FullName

			Write-Host "Created symlink for Steam mod id: $($currentMod.Name)"
			continue
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