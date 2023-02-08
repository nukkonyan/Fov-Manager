#include <multicolors>
#include <clientprefs>
#define Tag "{grey}[Fov Manager]{default}"
#define MaxPlayers 33

public Plugin myinfo = {
	name = "[ANY] FOV Manager",
	author = "Tk /id/Teamkiller324",
	description = "Manage the viewmodel fov.",
	version = "1.2.3",
	url = "https://steamcommunity.com/id/Teamkiller324"
}

//Standalone module from Random Commands Plugin, originally called "Tk Unrestricted FOV"

int g_FOV[MaxPlayers+1] = {-1, ...};
char Prefix[128];
ConVar fovEnable, fovMinimum, fovMaximum, fovPrefix;
Cookie fovCookie;

public void OnPluginStart() {
	LoadTranslations("fov_manager.phrases");
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_fov", FovCmd, "FOV Manager - Set a custom fov on yourself");
	RegConsoleCmd("sm_randomfov", RandomFovCmd, "FOV Manager - Set a random fov on yourself");
	
	fovEnable = CreateConVar("sm_fovmanager_enable", "1", "FOV Manager - Enable / Disable Unrestricted FOV", _, true, _, true, 1.0);
	fovMinimum = CreateConVar("sm_fovmanager_minimum", "10", "FOV Manager - Minimum Unrestricted FOV", _, true, 10.0, true, 360.0);
	fovMaximum = CreateConVar("sm_fovmanager_maximum", "180", "FOV Manager - Maximum Unrestricted FOV", _, true, 10.0, true, 360.0);
	fovPrefix = CreateConVar("sm_fovmanager_prefix", "{lightgreen}[Fov Manager]", "FOV Manager - Chat prefix");
	fovPrefix.AddChangeHook(view_as<ConVarChanged>(PrefixCallback));
	fovPrefix.GetString(Prefix, sizeof(Prefix));
	Format(Prefix, sizeof(Prefix), "%s{default}", Prefix);
	
	fovCookie = new Cookie("sm_fovmanager_cookie", "Fov Manager", CookieAccess_Private);
	
	HookEvent("player_spawn", view_as<EventHook>(Player_Spawn));
}

void PrefixCallback(ConVar cvar) {
	cvar.GetString(Prefix, sizeof(Prefix));
	Format(Prefix, sizeof(Prefix), "%s{default}", Prefix);
}

public void OnClientPostAdminCheck(int client) {
	if(!IsValidClient(client)) return;
	char cookie[8];
	fovCookie.Get(client, cookie, sizeof(cookie));
	if(strlen(cookie) > 0) g_FOV[client] = StringToInt(cookie);
}

public void OnClientDisconnect(int client) {
	if(IsValidClient(client)) {
		if(g_FOV[client] > -1) {
			char cookie[8];
			IntToString(g_FOV[client], cookie, sizeof(cookie));
			fovCookie.Set(client, cookie);
		}
	}
	
	g_FOV[client] = -1;
}

Action FovCmd(int client, int args) {	
	if(!fovEnable.BoolValue) return;
	
	if(client == 0) {
		CReplyToCommand(client, "[FOV Manager] This command may only be used ingame");
		return;
	}
	
	int	fov	= GetCmdInt(1);
	
	if(args < 1 && g_FOV[client] > fovMinimum.IntValue) {
		CPrintToChat(client, "%s %t", Prefix, "#FOV_Disabled");
		SetFOV(client, 90);
		g_FOV[client] = -1;
		char buffer[16];
		IntToString(0, buffer, sizeof(buffer));
		fovCookie.Set(client, buffer);
		return;
	}
	else if(args < 1) {
		CPrintToChat(client, "%s %t", Prefix, "#FOV_Usage", fovMinimum.IntValue, fovMaximum.IntValue);
		return;
	}
	
	if(fov < fovMinimum.IntValue) {
		CPrintToChat(client, "%s %t", Prefix, "#FOV_Error_Minimum", fovMinimum.IntValue);
		return;
	}
	else if(fov > fovMaximum.IntValue) {
		CPrintToChat(client, "%s %t", Prefix, "#FOV_Error_Maximum", fovMaximum.IntValue);
		return;
	}
	
	SetFOV(client, fov);
	g_FOV[client] = fov;
	
	char val[16];
	IntToString(fov, val, sizeof(val));
	fovCookie.Set(client, val);
	CPrintToChat(client, "%s %t", Prefix, "#FOV_Set", fov);
}

Action RandomFovCmd(int client, int args) {
	if(!fovEnable.BoolValue) return;
		
	if(client == 0) {
		CReplyToCommand(client, "[FOV Manager] This command may only be used ingame");
		return;
	}
	
	int	picker = GetRandomInt(fovMinimum.IntValue, fovMaximum.IntValue);
	SetFOV(client, picker);
	g_FOV[client] = picker;
	
	CPrintToChat(client, "%s %t", Prefix, "#FOV_Randomized", picker);
}

void Player_Spawn(Event event) {
	int	userid = event.GetInt("userid");
	if(userid < 1) return;
	CreateTimer(0.1, Timer_Spawn, userid, TIMER_DATA_HNDL_CLOSE);
}

Action Timer_Spawn(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client)) return;
	if(g_FOV[client] > -1) SetFOV(client, g_FOV[client]);
}

bool IsValidClient(int client) {
	if(client < 1 || client > MaxPlayers) return false;
	if(!IsClientConnected(client)) return false;
	if(IsClientReplay(client)) return false;
	if(IsClientSourceTV(client)) return false;
	if(IsFakeClient(client)) return false;
	return true;
}

int GetCmdInt(int argnum) {
	char dummy[16];
	GetCmdArg(argnum, dummy, sizeof(dummy));
	return StringToInt(dummy);
}

void SetFOV(int client, int value) {
	SetEntProp(client, Prop_Send, "m_iFOV", value);
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", value);
}