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