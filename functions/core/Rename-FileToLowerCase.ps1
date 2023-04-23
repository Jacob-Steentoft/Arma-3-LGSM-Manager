function Rename-FileToLowerCase {
	[CmdletBinding()]
	param (
		[System.IO.FileInfo]$File
	)

	foreach ($char in $File.Name.GetEnumerator()) {
		if ([char]::IsLower($char)) {
			continue
		}

		Rename-Item $File -NewName $File.Name.ToLower() -Force
		break
	}
}