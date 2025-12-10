#pragma semicolon 1
#pragma newdecls required

//#define DEBUG

#define PLUGIN_VERSION "1.0"

#define USER_AGENT "OverlayServer/v1.0.0"

#define MAX_ATTEMPT_TIMEOUT 120.0

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
// TODO: Add required includes for overlay functionality
// #include <ripext>  // TODO: Check if this library exists or needs to be added
// #include <overlay>  // TODO: Check if this library exists or needs to be added
// #include <socket>   // TODO: Check if this library exists or needs to be added

// TODO: WebSocket class needs to be defined or included from a library
// For now, using a placeholder Handle
// When WebSocket library is available, replace this with proper WebSocket type
Handle g_ws = null;

ConVar cvarManagerUrl; 
char managerUrl[128];

ConVar cvarManagerToken; 
char authToken[512];

int connectAttempts;

authState g_authState;

// TODO: JSONObject needs to be defined or included from a library
// For now, using a placeholder Handle
// When JSON library is available, replace this with proper JSONObject type
// Handle g_globalVars = null; // TODO: Initialize when JSON library is available

StringMap actionFallbackHandlers; // namespace -> action name has no handler, falls to this.
StringMap actionNamespaceHandlers; // { namespace: { [action name] -> handler } }

enum authState {
	Auth_Error = -1,
	Auth_None,
	Auth_Success,
}

// TODO: Define ACTION_ARG_LENGTH constant
#define ACTION_ARG_LENGTH 256

// TODO: Define ClientAction structure
enum struct ClientAction {
    char steamid[32];
    char ns[64];
    char instanceId[64];
    char command[64];
    char input[256];
}

// TODO: Define UIActionEvent structure
enum struct UIActionEvent {
    ArrayList args;
    
    void _Delete() {
        if (this.args != null) {
            delete this.args;
        }
    }
}

// TODO: Define Element methodmap properly
// TODO: Define ElementOptions methodmap properly
// TODO: Define PlayerList methodmap properly

public Plugin myinfo = 
{
	name = "[Rage] Overlay System", 
	author = "jackzmc & Yani", 
	description = "WebSocket-based overlay system for player UI elements and actions", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Jackzmc/sourcemod-plugins"
};

enum outRequest {
	Request_PlayerJoin,
	Request_PlayerLeft,
	Request_GameState,
	Request_RequestElement,
	Request_UpdateElement,
	Request_UpdateAudioState,
	Request_Invalid
}

// TODO: Use OUT_REQUEST_IDS when JSON library is available
// char OUT_REQUEST_IDS[view_as<int>(Request_Invalid)][] = {
// 	"player_joined",
// 	"player_left",
// 	"game_state",
// 	"request_element",
// 	"update_element",
// 	"change_audio_state"
// };

char steamidCache[MAXPLAYERS+1][32];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("rage_overlay");
	CreateNative("IsOverlayConnected", Native_IsOverlayConnected);
	CreateNative("RegisterActionAnyHandler", Native_ActionHandler);
	CreateNative("RegisterActionHandler", Native_ActionHandler);
	CreateNative("FindClientBySteamId2", Native_FindClientBySteamId2);
	return APLRes_Success;
}

public void OnPluginStart() {
	EngineVersion g_Game = GetEngineVersion();
	if(g_Game != Engine_Left4Dead && g_Game != Engine_Left4Dead2) {
		SetFailState("This plugin is for L4D/L4D2 only.");	
	}

	actionFallbackHandlers = new StringMap();
	actionNamespaceHandlers = new StringMap();
	
	// TODO: Initialize g_globalVars properly when JSON library is available
	// g_globalVars = new JSONObject();

	cvarManagerUrl = CreateConVar("rage_overlay_manager_url", "ws://100.92.116.2:3011/socket", "WebSocket URL for overlay manager server");
	cvarManagerUrl.AddChangeHook(OnUrlChanged);
	OnUrlChanged(cvarManagerUrl, "", "");

	cvarManagerToken = CreateConVar("rage_overlay_manager_token", "", "The auth token for this server");
	cvarManagerToken.AddChangeHook(OnTokenChanged);
	OnTokenChanged(cvarManagerToken, "", "");

	HookEvent("player_disconnect", Event_PlayerDisconnect);
	RegAdminCmd("sm_overlay", Command_Overlay, ADMFLAG_GENERIC);

	AutoExecConfig(true, "rage_overlay");

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			OnClientAuthorized(i, "");
		}
	}
}

public void OnPluginEnd() {
	if(g_ws != null) {
		// TODO: Properly close WebSocket when library is available
		// g_ws.Close();
		CloseHandle(g_ws);
		g_ws = null;
	}
}

bool isManagerReady() {
	// TODO: Implement proper WebSocket check when library is available
	// return g_ws != null && g_ws.WsOpen() && g_authState == Auth_Success;
	return g_ws != null && g_authState == Auth_Success;
}

void SendAllPlayers() {
	if(!isManagerReady()) return;

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			Send_PlayerJoined(steamidCache[i]);
		}
	}
}

Action Command_Overlay(int client, int args) {
	char arg[32];
	if (args > 0) {
		GetCmdArg(1, arg, sizeof(arg));
	}

	if(StrEqual(arg, "info")) {
		ReplyToCommand(client, "[Overlay] URL: %s", managerUrl);
		// TODO: Show proper connection status when WebSocket library is available
		ReplyToCommand(client, "[Overlay] Socket: %b", g_ws != null);
		ReplyToCommand(client, "[Overlay] Auth State: %d", g_authState);
	} else if(StrEqual(arg, "players")) {
		SendAllPlayers();
		ReplyToCommand(client, "[Overlay] Sent all players to manager");
	} else if(StrEqual(arg, "test")) {
		SendAllPlayers();
		// TODO: Implement test element sending when JSON library is available
		// JSONObject state = new JSONObject();
		// state.SetString("test", "yes");
		// Element elem = new Element("overlay:test", "overlay:generic_text", state, new ElementOptions());
		// elem.SetTarget(client);
		// elem.SendRequest();
		ReplyToCommand(client, "[Overlay] Test mode - sent players (element sending TODO)");
	} else if(StrEqual(arg, "trigger_login")) {
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i)) {
				GetClientAuthId(i, AuthId_Steam2, steamidCache[i], 32);
				Send_PlayerJoined(steamidCache[i]);
			}
		}
		ReplyToCommand(client, "[Overlay] Triggered login for all players");
	} else if(StrEqual(arg, "connect")) {
		if(ConnectManager()) {
			ReplyToCommand(client, "[Overlay] Connection initiated");
		} else {
			ReplyToCommand(client, "[Overlay] Failed to connect (check token)");
		}
	} else {
		ReplyToCommand(client, "[Overlay] Usage: sm_overlay <info|players|test|trigger_login|connect>");
		ReplyToCommand(client, "[Overlay] Status: Connected=%b, Auth=%d", isManagerReady(), g_authState);
	}

	return Plugin_Handled;
}

void OnUrlChanged(ConVar cvar, const char[] oldValue, const char[] newValue) {
	cvarManagerUrl.GetString(managerUrl, sizeof(managerUrl));

	if(g_ws != null) {
		DisconnectManager();
		CloseHandle(g_ws);
		g_ws = null;
	}

	// TODO: Initialize WebSocket properly when library is available
	// g_ws = new WebSocket(managerUrl);
	// g_ws.SetHeader("User-Agent", USER_AGENT);
	// g_ws.SetConnectCallback(OnWSConnect);
	// g_ws.SetDisconnectCallback(OnWSDisconnect);
	// g_ws.SetReadCallback(WebSocket_JSON, OnWSJson);

	PrintToServer("[Overlay] Changed url to: %s", managerUrl);
}

void OnTokenChanged(ConVar cvar, const char[] oldValue, const char[] newValue) {
	cvarManagerToken.GetString(authToken, sizeof(authToken));
}

public void OnClientAuthorized(int client, const char[] auth) {
	// TODO: Check WebSocket connection when library is available
	// if(g_ws != null && !g_ws.SocketOpen()) {
	//     ConnectManager();
	// }
	if(g_ws == null) {
		ConnectManager();
	}

	if(!IsFakeClient(client)) {
		GetClientAuthId(client, AuthId_Steam2, steamidCache[client], 32);
		Send_PlayerJoined(steamidCache[client]);
	}
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		Send_PlayerLeft(steamidCache[client]);
	}

	if(GetClientCount(false) == 0) {
		DisconnectManager();
	}

	steamidCache[client][0] = '\0';
}

// TODO: Implement WebSocket callbacks when library is available
// These will be registered as callbacks when WebSocket library is integrated
/*
void OnWSConnect(Handle ws, any arg) {
	connectAttempts = 0;
	g_authState = Auth_None;
	PrintToServer("[Overlay] Connected, authenticating");
	
	// TODO: Send authentication when JSON library is available
	// JSONObject obj = new JSONObject();
	// obj.SetString("type", "server");
	// obj.SetString("auth_token", authToken);
	// ws.Write(obj);
	// delete obj;
}

void OnWSDisconnect(Handle ws, int attempt) {
	if(g_authState == Auth_Error) {
		return;
	}

	connectAttempts++;
	// Simple exponential backoff: x^2
	float backoff = float(connectAttempts) / 2.0;
	float nextAttempt = (backoff * backoff) + 2.0;
	if(nextAttempt > MAX_ATTEMPT_TIMEOUT) nextAttempt = MAX_ATTEMPT_TIMEOUT;

	PrintToServer("[Overlay] Disconnected, retrying in %.0f seconds", nextAttempt);
	CreateTimer(nextAttempt, Timer_Reconnect);
}
*/

Action Timer_Reconnect(Handle h) {
	ConnectManager();
	return Plugin_Handled;
}

// TODO: Implement JSON message handling when library is available
/*
void OnWSJson(Handle ws, any message, any data) {
	// TODO: Parse JSON message and handle actions
	// JSONObject obj = view_as<JSONObject>(message);
	// 
	// if(g_authState == Auth_None) {
	//     // Handle authentication response
	// } else {
	//     // Handle action messages
	//     if(obj.HasKey("type")) {
	//         char type[32];
	//         obj.GetString("type", type, sizeof(type));
	//         if(StrEqual(type, "action")) {
	//             OnAction(obj);
	//         }
	//     }
	// }
}
*/

// TODO: Implement action handler when JSON library is available
/*
void OnAction(Handle obj) {
	// ClientAction action;
	// obj.GetString("steamid", action.steamid, sizeof(action.steamid));
	// obj.GetString("namespace", action.ns, sizeof(action.ns));
	// obj.GetString("instance_id", action.instanceId, sizeof(action.instanceId));
	// obj.GetString("command", action.command, sizeof(action.command));
	// if(obj.HasKey("input"))
	//     obj.GetString("input", action.input, sizeof(action.input));
	// 
	// int client = FindClientBySteamId2(action.steamid);
	// if(client <= 0) return;
	// 
	// // Handle action through registered handlers
	// // ...
}
*/

int _FindClientBySteamId2(const char[] steamid) {
	for(int i = 1; i <= MaxClients; i++) {
		if(StrEqual(steamidCache[i], steamid)) {
			return i;
		}
	}
	return -1;
}

bool ConnectManager() {
	DisconnectManager();
	if(authToken[0] == '\0') {
		PrintToServer("[Overlay] Cannot connect: auth token not set");
		return false;
	}

	PrintToServer("[Overlay] Connecting to \"%s\"", managerUrl);
	
	// TODO: Implement actual WebSocket connection when library is available
	// if(g_ws.Connect()) {
	//     PrintToServer("[Overlay] Connected");
	//     return true;
	// }
	
	PrintToServer("[Overlay] Connection not implemented yet (library TODO)");
	return false;
}

void DisconnectManager() {
	// TODO: Properly close WebSocket when library is available
	// if(g_ws != null && g_ws.WsOpen()) {
	//     g_ws.Close();
	// }
	if(g_ws != null) {
		CloseHandle(g_ws);
		g_ws = null;
	}
}

bool Send_PlayerJoined(const char[] steamid) {
	if(!isManagerReady()) return false;
	#pragma unused steamid  // TODO: Use when JSON library is available

	// TODO: Send player joined message when JSON library is available
	// JSONObject obj = new JSONObject();
	// obj.SetString("type", OUT_REQUEST_IDS[Request_PlayerJoin]);
	// obj.SetString("steamid", steamid);
	// g_ws.Write(obj);
	// obj.Clear();
	// delete obj;
	
	return true;
}

bool Send_PlayerLeft(const char[] steamid) {
	if(!isManagerReady()) return false;
	#pragma unused steamid  // TODO: Use when JSON library is available

	// TODO: Send player left message when JSON library is available
	// JSONObject obj = new JSONObject();
	// obj.SetString("type", OUT_REQUEST_IDS[Request_PlayerLeft]);
	// obj.SetString("steamid", steamid);
	// g_ws.Write(obj);
	// obj.Clear();
	// delete obj;
	
	return true;
}

// Native implementations
any Native_IsOverlayConnected(Handle plugin, int numParams) {
	return isManagerReady();
}

any Native_ActionHandler(Handle plugin, int numParams) {
	char ns[64];
	GetNativeString(1, ns, sizeof(ns));
	
	if(numParams == 3) {
		// RegisterActionHandler
		StringMap nsHandlers;
		if(!actionNamespaceHandlers.GetValue(ns, nsHandlers)) {
			nsHandlers = new StringMap();
			actionNamespaceHandlers.SetValue(ns, nsHandlers);
		}
		
		char actionId[64];
		GetNativeString(2, actionId, sizeof(actionId));
		
		PrivateForward fwd;
		if(!nsHandlers.GetValue(actionId, fwd)) {
			fwd = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell);
		}
		fwd.AddFunction(INVALID_HANDLE, GetNativeFunction(3));
		nsHandlers.SetValue(actionId, fwd);
	} else {
		// RegisterActionAnyHandler
		PrivateForward fwd;
		if(!actionFallbackHandlers.GetValue(ns, fwd)) {
			fwd = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell);
		}
		fwd.AddFunction(INVALID_HANDLE, GetNativeFunction(2));
		actionFallbackHandlers.SetValue(ns, fwd);
	}
	
	return 1;
}

any Native_FindClientBySteamId2(Handle plugin, int numParams) {
	char steamid[32];
	GetNativeString(1, steamid, sizeof(steamid));
	return _FindClientBySteamId2(steamid);
}

// Exponential backoff is calculated inline in OnWSDisconnect

