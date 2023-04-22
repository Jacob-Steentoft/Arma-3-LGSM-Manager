function Set-ConfigKey {
	param(
		[Parameter(Mandatory)][hashtable]$Config,
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)]$Value
	)
	
	if ([string]::IsNullOrEmpty($Name)) {
		Write-Error "Name cannot be empty"
	}

	if ($Config[$Name] -ne $Value) {
		if (!$Config.ContainsKey($Name)) {
			$Config.Add($Name, $Value)
		}
		else {
			$Config[$Name] = $Value
		}
		Write-Host "Updated the key $Name"
	}
}