#include <tklib>
#include <multicolors>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

public Plugin myinfo = {
	name = "[ANY] FOV Manager",
	author = _tklib_author,
	description = "Manage the viewmodel fov.",
	version = "1.2.0",
	url = _tklib_author_url
}

//Standalone module from Random Commands Plugin, originally called "Tk Unrestricted FOV"

StringMap Inventory;
int AccountID[MAXCLIENTS];
char Prefix[128];
ConVar fovEnable, fovMinimum, fovMaximum, fovPrefix;
Cookie fovCookie;

#define PluginUrl "https://raw.githubusercontent.com/Teamkiller324/Fov-Manager/main/FovManagerUpdater.txt"

public void OnPluginStart() {
	LoadTranslations("fov_manager.phrases");
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_fov", FovCmd, "FOV Manager - Set a custom fov on yourself");
	RegConsoleCmd("sm_randomfov", RandomFovCmd, "FOV Manager - Set a random fov on yourself");
	
	fovEnable = CreateConVar("sm_fovmanager_enable",	"1", "FOV Manager - Enable / Disable Unrestricted FOV", _, true, 0.0, true, 1.0);
	fovMinimum = CreateConVar("sm_fovmanager_minimum",	"10", "FOV Manager - Minimum Unrestricted FOV", _, true, 10.0, true, 360.0);
	fovMaximum = CreateConVar("sm_fovmanager_maximum",	"180", "FOV Manager - Maximum Unrestricted FOV", _, true, 10.0, true, 360.0);
	fovPrefix = CreateConVar("sm_fovmanager_prefix", "{lightgreen}[Fov Manager]", "FOV Manager - Chat prefix");
	fovPrefix.AddChangeHook(PrefixCallback);
	fovPrefix.GetString(Prefix, sizeof(Prefix));
	Format(Prefix, sizeof(Prefix), "%s{default}", Prefix);
	
	Inventory = new StringMap();
	fovCookie = new Cookie("sm_fovmanager_cookie", "Fov Manager", CookieAccess_Private);
	
	HookEvent(EVENT_PLAYER_SPAWN, Player_Spawn);
	
	#if defined _updater_included
	Updater_AddPlugin(PluginUrl);
	#endif
}

#if defined _updater_included
public void Updater_OnPluginUpdated()	{
	PrintToServer("[FOV Manager] Update has been installed, restarting..");
	Updater_ReloadPlugin();
}
#endif

void PrefixCallback(ConVar cvar, const char[] oldvalue, const char[] newvalue)	{
	cvar.GetString(Prefix, sizeof(Prefix));
	Format(Prefix, sizeof(Prefix), "%s{default}", Prefix);
}

public void OnClientPostAdminCheck(int client)	{
	LoadFovCookies(client);
}

void LoadFovCookies(int client)	{
	if(!Tklib_IsValidClient(client, true))
		return;
	
	char cookie[8];
	fovCookie.Get(client, cookie, sizeof(cookie));
	if(!StrEqual(cookie, ""))
		SetPlayerFovValue(client, StringToInt(cookie));
}

public void OnClientDisconnect(int client)	{
	if(!Tklib_IsValidClient(client, true))
		return;
	
	int value = GetPlayerFovValue(client);
	if(value > -1) {
		char cookie[8];
		IntToString(value, cookie, sizeof(cookie));
		fovCookie.Set(client, cookie);
	}
	
	ClearPlayer(client);
}

Action FovCmd(int client, int args) {	
	if(!fovEnable.BoolValue)
		return Plugin_Handled;
	
	if(!Tklib_IsValidClient(client, true)) {
		ReplyToCommand(client, "[FOV Manager] %t", "Fov Error Ingame Only");
		return Plugin_Handled;
	}
	
	int	fov	= GetCmdInt(1);
	
	if(args < 1 && GetPlayerFovValue(client) > fovMinimum.IntValue) {
		CPrintToChat(client, "%s %t", Prefix, "Fov Disabled");
		SetClientFOV(client, 90);
		SetClientDefaultFOV(client, 90);
		SetPlayerFovValue(client, 90);
		char buffer[1];
		IntToString(0, buffer, sizeof(buffer));
		fovCookie.Set(client, buffer);
		return Plugin_Handled;
	}
	else if(args < 1) {
		CPrintToChat(client, "%s %t", Prefix, "Fov Usage", fovMinimum.IntValue, fovMaximum.IntValue);
		return Plugin_Handled;
	}
	
	if(fov > fovMaximum.IntValue) {
		CPrintToChat(client, "%s %t", Prefix, "Fov Error Maximum", fovMaximum.IntValue);
		return Plugin_Handled;
	}
	if(fov < fovMinimum.IntValue) {
		CPrintToChat(client, "%s %t", Prefix, "Fov Error Minimum", fovMinimum.IntValue);
		return Plugin_Handled;
	}
	
	SetClientFOV(client, fov);
	SetClientDefaultFOV(client, fov);
	SetPlayerFovValue(client, fov);
	
	char val[8];
	IntToString(fov, val, sizeof(val));
	fovCookie.Set(client, val);
	CPrintToChat(client, "%s %t", Prefix, "Fov Set", fov);
	
	return	Plugin_Handled;
}

Action RandomFovCmd(int client, int args) {
	if(!fovEnable.BoolValue)
		return Plugin_Handled;
		
	if(!Tklib_IsValidClient(client, true)) {
		ReplyToCommand(client, "[FOV Manager] %t", "Fov Error Ingame Only");
		return Plugin_Handled;
	}
	
	int	picker = GetRandomInt(fovMinimum.IntValue, fovMaximum.IntValue);
	SetClientFOV(client, picker);
	SetClientDefaultFOV(client, picker);
	SetPlayerFovValue(client, picker);
	
	CPrintToChat(client, "%s %t", Prefix, "Fov Randomized", picker);
	return Plugin_Handled;
}

void Player_Spawn(Event event, const char[] event_name, bool dontBroadcast)	{
	int	client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!Tklib_IsValidClient(client, true, true))
		return;
	
	int value = GetPlayerFovValue(client);
	if(value > -1) {
		SetClientFOV(client, value);
		SetClientDefaultFOV(client, value);
	}
}

int GetPlayerFovValue(int client) {
	char dummy[16], val[8];
	Format(dummy, sizeof(dummy), "%i_fov", AccountID[client]);
	Inventory.GetString(dummy, val, sizeof(val));
	return StrEmpty(val) ? -1:StringToInt(val);
}

bool SetPlayerFovValue(int client, int fov) {
	char dummy[16], val[8];
	Format(dummy, sizeof(dummy), "%i_fov", AccountID[client]);
	IntToString(fov, val, sizeof(val));
	return Inventory.SetString(dummy, val);
}

int ClearPlayer(int client) {
	StringMapSnapshot snapshot = Inventory.Snapshot();
	
	for(int i = 0; i < snapshot.Length; i++) {
		char dummy[16], id[16];
		Format(dummy, sizeof(dummy), "%i_fov", AccountID[client]);
		snapshot.GetKey(i, dummy, sizeof(dummy));
		IntToString(AccountID[client], id, sizeof(id));
		if(StrContainsEx(dummy, id))
			Inventory.Remove(dummy);
	}
	
	AccountID[client] = 0;
}