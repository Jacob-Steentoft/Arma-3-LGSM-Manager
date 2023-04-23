function Set-ConfigFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][hashtable]$Config,
		[Parameter(Mandatory)][string]$ConfigFilePath
	)
	
	if (!(Test-Path $ConfigFilePath)) {
		Write-Error "Unable to resolve the path: $ConfigFilePath"
	}

	$stringBuilder = New-Object System.Text.StringBuilder
	foreach ($pair in $Config.GetEnumerator()) {
		$stringBuilder.AppendLine("$($pair.Key)=`"$($pair.Value)`"")
	}

	Set-Content -Value ($stringBuilder.ToString()) -Path $ConfigFilePath
}