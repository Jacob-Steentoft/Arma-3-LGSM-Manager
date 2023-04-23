function Rename-DirectoryToLowerCase {
	[CmdletBinding()]
	param (
		[System.IO.DirectoryInfo]$Directory
	)

	foreach ($char in $Directory.Name.GetEnumerator()) {
		if ([char]::IsLower($char)) {
			continue
		}

		$tempDir = Rename-Item -LiteralPath $Directory.FullName -NewName "a" -PassThru

		Rename-Item -LiteralPath $tempDir.FullName -NewName $Directory.Name.ToLowerInvariant() -Force
		break
	}
}