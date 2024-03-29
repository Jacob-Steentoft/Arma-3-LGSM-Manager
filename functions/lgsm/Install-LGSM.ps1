function Install-LGSM {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$RootPath,
		[Parameter(Mandatory)][string]$GameName
	)

	$fileName = "linuxgsm.sh"
	$linuxgsmPath = Join-Path -Path -ChildPath $fileName

	if (Test-Path $linuxgsmPath) {
		Write-Host "Found linuxgsm.sh"
		return
	}

	Invoke-RestMethod "https://$fileName" -OutFile $linuxgsmPath

	Invoke-Expression "chmod +x $linuxgsmPath"
	Invoke-Expression "bash $linuxgsmPath $GameName"

	Invoke-Expression "$linuxgsmPath/$GameName install"
	Write-Host "Installed Arma 3 through LGSM"
}