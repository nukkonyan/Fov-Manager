#include	<clientprefs>
#include	<tklib>
#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

public	Plugin	myinfo	=	{
	name		=	"[ANY] Fov Manager",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Manage the viewmodel fov",
	version		=	"1.1.0",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

//Standalone module from Random Commands Plugin, originally called "Tk Unrestricted FOV"

int		PlayerFOV[MAXPLAYERS];
char	Prefix[128];
ConVar	fovEnable, fovMinimum, fovMaximum, fovPrefix;
Cookie	fovCookie;

#define PluginUrl "https://raw.githubusercontent.com/Teamkiller324/Fov-Manager/main/FovManagerUpdater.txt"

public void OnPluginStart()	{
	LoadTranslations("fov_manager.phrases");
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_fov",			PlayerSetFov,		"Set a custom fov on yourself");
	RegConsoleCmd("sm_randomfov",	PlayerSetRandomFov,	"Set a random fov on yourself");
	
	fovEnable	= CreateConVar("sm_fovmanager_enable",	"1",	"Enable / Disable Unrestricted FOV", _, true, 0.0, true, 1.0);
	fovMinimum	= CreateConVar("sm_fovmanager_minimum",	"10",	"Minimum Unrestricted FOV", _, true, 10.0, true, 360.0);
	fovMaximum	= CreateConVar("sm_fovmanager_maximum",	"180",	"Maximum Unrestricted FOV", _, true, 10.0, true, 360.0);
	fovPrefix	= CreateConVar("sm_fovmanager_prefix", "{lightgreen}[Fov Manager]");
	fovPrefix.AddChangeHook(PrefixCallback);
	fovPrefix.GetString(Prefix, sizeof(Prefix));
	Format(Prefix, sizeof(Prefix), "%s{default}", Prefix);
	
	fovCookie = new Cookie("sm_fovmanager_cookie", "Fov Manager", CookieAccess_Private);
	
	HookEvent(EVENT_PLAYER_SPAWN, PlayerFovSpawn, EventHookMode_Pre);
	
	#if defined _updater_included
	Updater_AddPlugin(PluginUrl);
	#endif
}

#if defined _updater_included
public void Updater_OnPluginUpdated()	{
	PrintToServer("[Fov Manager] Update has been installed, restarting..");
	ReloadPlugin();
}
#endif

void PrefixCallback(ConVar cvar, const char[] oldvalue, const char[] newvalue)	{
	cvar.GetString(Prefix, sizeof(Prefix));
	Format(Prefix, sizeof(Prefix), "%s{default}", Prefix);
}

public void OnClientPutInServer(int client)	{
	LoadFovCookies(client);
}

void LoadFovCookies(int client)	{
	if(Tklib_IsValidClient(client, true, false, false))	{
		char cookie[64];
		fovCookie.Get(client, cookie, sizeof(cookie));
		if(!StrEqual(cookie, ""))
			PlayerFOV[client] = StringToInt(cookie);
	}
}

public void OnClientDisconnect(int client)	{
	if(Tklib_IsValidClient(client, true))	{
		char cookie[64];
		IntToString(PlayerFOV[client], cookie, sizeof(cookie));
		fovCookie.Set(client, cookie);
	}
}


Action PlayerSetFov(int client, int args)	{	
	if(!fovEnable.BoolValue)
		return	Plugin_Handled;
	
	if(!Tklib_IsValidClient(client, true))	{
		ReplyToCommand(client, "%t", "fov_error");
		return	Plugin_Handled;
	}
	
	int	fov	= GetCmdInt(1);
	
	if(args < 1 && PlayerFOV[client] > fovMinimum.IntValue)	{
		CPrintToChat(client, "%s %t", fovPrefix, "fov_disabled");
		SetClientFOV(client, 90);
		SetClientDefaultFOV(client, 90);
		char buffer[64];
		PlayerFOV[client] = 0;
		IntToString(0, buffer, sizeof(buffer));
		fovCookie.Set(client, buffer);
		return	Plugin_Handled;
	}
	else if(args < 1)	{
		CPrintToChat(client, "%s %t", fovPrefix, "fov_usage", fovMinimum.IntValue, fovMaximum.IntValue);
		return	Plugin_Handled;
	}
	
	if(fov > fovMaximum.IntValue)	{
		CPrintToChat(client, "%s %t", fovPrefix, "fov_error_maximum", fovMaximum.IntValue);
		return	Plugin_Handled;
	}
	if(fov < fovMinimum.IntValue)	{
		CPrintToChat(client, "%s %t", fovPrefix, "fov_error_minimum", fovMinimum.IntValue);
		return	Plugin_Handled;
	}
	
	SetClientFOV(client, fov);
	SetClientDefaultFOV(client, fov);
	PlayerFOV[client] = fov;
	
	char setvalue[MAX_TARGET_LENGTH];
	IntToString(PlayerFOV[client], setvalue, sizeof(setvalue));
	fovCookie.Set(client, setvalue);
	
	CPrintToChat(client, "%s %t", fovPrefix, "fov_set", fov);
	
	return	Plugin_Handled;
}

Action PlayerSetRandomFov(int client, int args)	{
	if(!fovEnable.BoolValue)
		return	Plugin_Handled;
		
	if(!Tklib_IsValidClient(client, true))	{
		ReplyToCommand(client, "%t", "fov_error");
		return	Plugin_Handled;
	}
	
	int	picker = GetRandomInt(fovMinimum.IntValue, fovMaximum.IntValue);
	SetClientFOV(client, picker);
	SetClientDefaultFOV(client, picker);
	
	char buffer[64];
	IntToString(picker,	buffer,	sizeof(buffer));
	fovCookie.Set(client, buffer);
	
	CPrintToChat(client, "%s %t", Prefix, "fov_randomized", picker);
	return	Plugin_Handled;
}

void PlayerFovSpawn(Event event, const char[] event_name, bool dontBroadcast)	{
	int	client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!Tklib_IsValidClient(client, true, true))
		return;
	
	if(PlayerFOV[client] != 0)	{
		SetClientFOV(client, PlayerFOV[client]);
		SetClientDefaultFOV(client, PlayerFOV[client]);
	}
}
