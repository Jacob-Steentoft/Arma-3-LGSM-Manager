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