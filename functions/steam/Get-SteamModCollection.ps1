function Get-SteamModCollection {
	[CmdletBinding()]
	[OutputType([long[]])]
	param (
		[Parameter(Mandatory)][ulong]$ModCollectionSteamId
	)
	$response = Invoke-RestMethod "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/" -Method Post -Body @{
		collectioncount       = 1
		"publishedfileids[0]" = $ModCollectionSteamId
	}

	[long[]]$steamModIds = $response.response.collectiondetails.children.publishedfileid

	if ($steamModIds.Count -eq 0) {
		Write-Error "No workshop steam mods found"
	}

	return $steamModIds
}