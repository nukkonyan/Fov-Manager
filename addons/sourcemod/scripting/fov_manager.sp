#include	<multicolors>
#include	<clientprefs>
#include	<tklib>

public	Plugin	myinfo	=	{
	name		=	"[ANY] Fov Manager",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Manage the viewmodel fov",
	version		=	"1.0.1",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

//Standalone module from Random Commands Plugin, originally called "Tk Unrestricted FOV"

int		PlayerFOV	[MAXPLAYERS+1];

char	fovPrefix[128];

ConVar	fovEnable,
		fovMinimum,
		fovMaximum;
		
Cookie	fovCookie;

public	void	OnPluginStart()	{
	LoadTranslations("fov_manager.phrases");
	LoadTranslations("common.phrases");
	
	FormatEx(fovPrefix,	sizeof(fovPrefix),	"%t{default}",	"fov_prefix",	LANG_SERVER);
	
	RegConsoleCmd("sm_fov",			PlayerSetFov,			"Set a custom fov on yourself");
	RegConsoleCmd("sm_randomfov",	PlayerSetRandomFov,		"Set a random fov on yourself");
	
	fovEnable	=	CreateConVar("sm_fovmanager_enable",		"1",	"Enable / Disable Unrestricted FOV",		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	fovMinimum	=	CreateConVar("sm_fovmanager_minimum",		"10",	"Minimum Unrestricted FOV",					FCVAR_NOTIFY, true, 10.0, true, 360.0);
	fovMaximum	=	CreateConVar("sm_fovmanager_maximum",		"180",	"Maximum Unrestricted FOV",					FCVAR_NOTIFY, true, 10.0, true, 360.0);
	
	fovCookie	=	new Cookie("sm_fovmanager_cookie",			"Fov Manager",		CookieAccess_Private);	//Originally Tk Unrestricted FOV [Random Commands Plugin]
	
	HookEvent("player_spawn",	PlayerFovSpawn,	EventHookMode_Pre);
}

public	void	OnClientCookiesCached(int client)	{
	LoadFovCookies(client);
}

public	void	OnClientPutInServer(int client)	{
	LoadFovCookies(client);
}

void	LoadFovCookies(int client)	{
	if(IsValidClient(client) && IsClientInGame(client))	{
		char	cookie[MAX_TARGET_LENGTH];
		fovCookie.Get(client,	cookie,	sizeof(cookie));
		if(!StrEqual(cookie,	""))
			PlayerFOV[client] = StringToInt(cookie);
	}
}

public	void	OnClientDisconnect(int client)	{
	if(IsValidClient(client) && AreClientCookiesCached(client))	{	
		char cookie[MAX_TARGET_LENGTH];
		IntToString(PlayerFOV[client], cookie, sizeof(cookie));
		fovCookie.Set(client,	cookie);
	}
}


Action	PlayerSetFov(int client, int args)	{	
	if(!fovEnable.BoolValue)
		return	Plugin_Handled;
	
	if(!IsValidClient(client))	{
		ReplyToCommand(client, "%t",	"fov_error");
		return	Plugin_Handled;
	}
	
	char	arg1[512];
	GetCmdArg(1,	arg1,	sizeof(arg1));
	int	fov	=	StringToInt(arg1);
	
	if(args < 1 && PlayerFOV[client] > fovMinimum.IntValue)	{
		CPrintToChat(client,	"%s %t",	fovPrefix,	"fov_disabled");
		SetClientFOV(client, 90);
		SetClientDefaultFOV(client, 90);
		char	buffer[MAX_TARGET_LENGTH];
		PlayerFOV[client] = 0;
		IntToString(0, buffer, sizeof(buffer));
		fovCookie.Set(client,	buffer);
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
	
	SetClientFOV(client,		fov);
	SetClientDefaultFOV(client,	fov);
	PlayerFOV[client] = fov;
	
	char	setvalue[MAX_TARGET_LENGTH];
	IntToString(PlayerFOV[client], setvalue, sizeof(setvalue));
	fovCookie.Set(client, setvalue);
	
	CPrintToChat(client,	"%s %t",	fovPrefix,	"fov_set",	fov);
	
	return	Plugin_Handled;
}

Action	PlayerSetRandomFov(int client, int args)	{
	if(!fovEnable.BoolValue)
		return	Plugin_Handled;
		
	if(!IsValidClient(client))	{
		ReplyToCommand(client,	"%t",	"fov_error");
		return	Plugin_Handled;
	}
	
	int	picker	=	GetRandomInt(fovMinimum.IntValue,	fovMaximum.IntValue);
	SetClientFOV(client,		picker);
	SetClientDefaultFOV(client,	picker);
	
	char	buffer[MAX_TARGET_LENGTH];
	IntToString(picker,	buffer,	sizeof(buffer));
	fovCookie.Set(client,	buffer);
	
	CPrintToChat(client,	"%s %t",	fovPrefix,	"fov_randomized",	picker);
	return	Plugin_Handled;
}

Action	PlayerFovSpawn(Event event, const char[] name, bool dontBroadcast)	{
	int	client	=	GetClientOfUserId(event.GetInt("userid"));
	
	if(!IsValidClient(client))
		return	Plugin_Handled;
	
	if(PlayerFOV[client] != 0)	{
		SetClientFOV(client, PlayerFOV[client]);
		SetClientDefaultFOV(client, PlayerFOV[client]);
	}
	
	return	Plugin_Continue;
}

/**
 * Returns if the client is valid.
 *
 * @pragma client		Client index.
 */
stock bool IsValidClient(int client)	{
	if(client < 1 || client > MaxClients)
		return	false;
	if(IsFakeClient(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	if(IsClientObserver(client))
		return	false;
	return	true;
}
