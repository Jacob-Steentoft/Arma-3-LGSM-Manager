function Get-ConfigFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$ConfigPath
	)

	if (!(Test-Path $ConfigPath)) {
		Write-Error "Unable to resolve the config path: $ConfigPath"
	}

	$regexExpression = "(?<=[`"']).*(?=[`"'])"
	$regex = New-Object regex -ArgumentList @($regexExpression)

	$configRaw = Get-Content $ConfigPath -Raw | ConvertFrom-StringData

	$configContent = New-Object hashtable
	foreach ($pair in $configRaw.GetEnumerator()) {
		if ($configContent.ContainsKey($pair.Key)) {
			Write-Error "Found dublicate key for: $($pair.Key)"
		}

		$result = $regex.Match($pair.Value)
		if (!$result.Success) {
			Write-Error "Content did not match the expression: $regexExpression"
		}
		
		if ($result.Captures.Count -ne 1) {
			Write-Error "Found too much data. Please validate : $($result.ValueSpan)"
		}

		$configContent.Add($pair.Key, $result.Captures[0].Value)
	}

	return $configContent
}