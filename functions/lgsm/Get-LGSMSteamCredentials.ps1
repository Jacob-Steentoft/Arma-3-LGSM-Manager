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