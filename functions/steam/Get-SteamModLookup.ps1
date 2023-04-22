function Get-SteamModLookup {
	param(
		[Parameter(Mandatory)][ulong[]]$SteamModIds
	)
	
	$query = @{
		itemcount = $SteamModIds.Length
	}
	for ($i = 0; $i -lt $SteamModIds.Length; $i++) {
		if ($query.ContainsKey($SteamModIds[$i])) {
			Write-Error "Steam Mod Ids cannot contain dublicate: $($SteamModIds[$i])"
		}
		$query.Add("publishedfileids[$i]", $SteamModIds[$i])
	}

	$response = Invoke-RestMethod "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" -Method Post -Body $query

	$lookup = New-Object hashtable
	foreach ($publishedFileDetail in $response.response.publishedfiledetails) {
		if ($lookup.ContainsKey($publishedFileDetail.publishedfileid)) {
			continue
		}
		$lookup.Add($publishedFileDetail.publishedfileid, $publishedFileDetail.title)
	}

	return $lookup
}