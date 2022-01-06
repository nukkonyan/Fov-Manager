## Fov-Manager
Standalone module taken from Random Commands Plugin (not released yet)
Manage your viewmodel with commands.

### Latest Version: 1.1.0

AlliedModders Post: https://forums.alliedmods.net/showthread.php?p=2736253

## Requirement
[Tk Libraries](https://github.com/Teamkiller324/Tklib) (To compile the plugin)
[Updater](https://github.com/Teamkiller324/Updater) (To compile with Updater support)

## Cvars
```
sm_fovmanager_enable
	- Do you prefer the plugin to be enabled or not?. Default: 1

sm_fovmanager_minimum
	- Minimum fov limit. Default: 10

sm_fovmanager_maximum
	- Maximum fov limit. Default: 360

sm_fovmanager_prefix
	- The prefix of the ingame messages. Default: {lightgreen}[FOV Manager]
```

## Commands
```
sm_fov - Set your preferred fov. Minimum & maximum value restricted by the convar that handles the limit.
sm_randomfov - Sets a random fov number between the minimum & maximum fov limit.
```

## Fov Limitation
```
Minimum: 10
Maximum: 360
```
