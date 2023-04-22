$functions = Get-ChildItem $PSScriptRoot -Recurse -Filter "*.ps1" -Exclude "Import-Functions.ps1"

foreach ($function in $functions) {
	.$function.FullName
}
