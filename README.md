# Arma 3 LGSM Manager

Scripts for managing an Arma 3 server through LGSM that can install, update, and configure mods for both server and headless clients.

This script relies on the wonderful project at: <https://github.com/GameServerManagers/LinuxGSM>

Further information about the installtion of the Arma 3 server can be found at: <https://linuxgsm.com/servers/arma3server/>

## :exclamation: Important Notes

Running this script can and will overwrite files, so please make sure to set the root path to a place where it will not overwrite anything important.

This script has only been tested using Debian 11. There should however not be any problems running this using other distros, as the functionaly relies on PowerShell, SteamCMD, and the LinuxGSM script.

This script should be not be used by a sudo user. It has been designed and tested without any sudo commands or priviliges.

## :police_car: Requirements

### Applications

* Curl
* SteamCMD

### Ports

#### Ingoing

The server port set in the script and the next 4 ports. All ingoing ports are UDP.

Example: Using port 2302 you need to open from 2302 to 2306

#### Outgoing

The server port set in the script and the next 4 ports. These ports are UDP.

Example: using port 2302 you need to open from 2302 to 2306

Port 2344 as UDP + TPC and 2345 as TPC for BattleEye.

### The Rest

* Linux as the operating system
* PowerShell Version 7
* Access to the internet

## :bullettrain_front: How to use

1. Download Arma3LGSMManager.ps1.

2. Run Arma3LGSMManager.ps1 using PowerShell 7 and provide the required parameters.

**OBS**: -ServerPassword doesn't set the server password, but what password the headless clients will use to connect to your server.

### PowerShell Example

```PowerShell
./Arma3LGSMManager.ps1 -RootPath "/data/Servers/LinuxGSM/myarma3server" -SteamModCollectionId 1337 -SteamWhitelistModIds @(1105511475, 861133494) -ServerPort 2302 -ServerPassword "bingo" -HeadlessCount 3
```

The above will:

* Download the LGSM script (If it doesn't exist)
* Install the Arma 3 server using LinuxGSM (If it doesn't exist)
* Create 3 headless clients (If they don't exist)
* Download or update (if necessary) all the mods
* Configure mods to require all mods under the collection id 1337
* Allow users to use the Steam mods 1105511475 and 861133494 without them being required by all users. (Note that all mods will not work if not installed on the server)
* Make the headless clients connecting using the password "bingo"
