param(
	[Parameter(Mandatory)][string]$CMD,
	[string]$InstanceName = "arma3server",
	[int]$HeadlessCount,
	[string]$Dir = "/data/Servers/LinuxGSM/arma3-callousfish"
)
$ErrorActionPreference = "Stop"

if ($HeadlessCount -gt 3) {
	Write-Error "headless count cannot be greater than 3"
}

$headlessScripts = Get-ChildItem $Dir -Filter "$InstanceName-hc*" -Name

switch ($cmd) {
	start {
		bash "$dir/$InstanceName" $CMD
		for ($i = 1; $i -le $HeadlessCount; $i++) {
			bash "$dir/$InstanceName-hc$i" $CMD
		}
		break
	}
	stop {
		bash "$dir/$InstanceName" $CMD
		for ($i = 1; $i -le $HeadlessCount; $i++) {
			bash "$dir/$InstanceName-hc$i" $CMD
		}
	}
	restart {
		bash "$dir/$InstanceName" $CMD
		for ($i = 1; $i -le $HeadlessCount; $i++) {
			bash "$dir/$InstanceName-hc$i" $CMD
		}
		break
	}
	update {
		bash "$dir/$InstanceName" $CMD
		break
	}
	Default {
		Throw "Please use the following commands: start, stop, restart, update"
	}
}