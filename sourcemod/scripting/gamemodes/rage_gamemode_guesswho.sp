#pragma semicolon 1
#pragma newdecls required

#define DEBUG_BOT_MOVE
#define DEBUG_BOT_MOVE_REACH
#define DEBUG
#define DEBUG_SHOW_POINTS
#define DEBUG_BLOCKERS
// #define DEBUG_LOG_MAPSTART
// #define DEBUG_MOVE_ATTEMPTS
// #define DEBUG_SEEKER_PATH_CREATION 1

#define PLUGIN_VERSION "1.0"

#define BOT_MOVE_RANDOM_MIN_TIME 2.0 // The minimum random time for Timer_BotMove to activate (set per bot, per round)
#define BOT_MOVE_RANDOM_MAX_TIME 3.0 // The maximum random time for Timer_BotMove to activate (set per bot, per round)
#define BOT_MOVE_CHANCE 0.96 // The chance the bot will move each Timer_BotMove
#define BOT_MOVE_AVOID_FLOW_DIST 12.0 // The flow range of flow distance that triggers avoid
#define BOT_MOVE_AVOID_SEEKER_CHANCE 0.50 // The chance that if the bot gets too close to the seeker, it runs away
#define BOT_MOVE_AVOID_MIN_DISTANCE 200.0 // The minimum distance for a far away point. (NOT flow)
#define BOT_MOVE_USE_CHANCE 0.001 // Chance the bots will use +USE (used for opening doors, buttons, etc)
#define BOT_MOVE_JUMP_CHANCE 0.001
#define BOT_MOVE_SHOVE_CHANCE 0.0015
#define BOT_MOVE_RUN_CHANCE 0.15
#define BOT_MOVE_NOT_REACHED_DISTANCE 60.0 // The distance that determines if a bot reached a point
#define BOT_MOVE_NOT_REACHED_ATTEMPT_RUNJUMP 6 // The minimum amount of attempts where bot will run or jump to dest
#define BOT_MOVE_NOT_REACHED_ATTEMPT_RETRY 10 // The minimum amount of attempts where bot gives up and picks new
#define DOOR_TOGGLE_INTERVAL 5.0 // Interval that loops throuh all doors to randomly toggle
#define DOOR_TOGGLE_CHANCE 0.01 // Chance that every Timer_DoorToggles triggers a door to toggle state
#define HIDER_SWAP_COOLDOWN 30.0 // Amount of seconds until they can swap
#define HIDER_SWAP_LIMIT 3 // Amount of times a hider can swap per round
#define FLOW_BOUND_BUFFER 200.0 // Amount to add to calculated bounds (Make it very generous)
#define HIDER_MIN_AVG_DISTANCE_AUTO_VOCALIZE 300.0 // The average minimum distance a hider is from the player that triggers auto vocalizating
#define HIDER_AUTO_VOCALIZE_GRACE_TIME 20.0 // Number of seconds between auto vocalizations
#define DEFAULT_MAP_TIME 480
#define SEED_MIN_LOCATIONS 500 // Seed if less than this many locations

#if defined DEBUG
	#define SEED_TIME 1.0
#else
	#define SEED_TIME 15.0 // Time the seeker is blind, used to gather locations for bots
#endif

#define SMOKE_PARTICLE_PATH "particles/smoker_fx.pcf"
#define SOUND_MODEL_SWAP "ui/pickup_secret01.wav"
#define MAX_VALID_LOCATIONS 2000 // The maximum amount of locations to hold, once this limit is reached only MAX_VALID_LOCATIONS_KEEP_PERCENT entries will be kept at random
#define MAX_VALID_LOCATIONS_KEEP_PERCENT 0.30 // The % of locations to be kept when dumping movePoints

float DEBUG_POINT_VIEW_MIN[3] = { -5.0, -5.0, 0.0 }; 
float DEBUG_POINT_VIEW_MAX[3] = { 5.0, 5.0, 2.0 }; 
int SEEKER_GLOW_COLOR[3] = { 128, 0, 0 };
int PLAYER_GLOW_COLOR[3] = { 0, 255, 0 };

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <smlib/effects>
#include <sceneprocessor>
#include <multicolors>
#include <rage/validation>

char SURVIVOR_MODELS[8][] = {
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_biker.mdl",
	"models/survivors/survivor_manager.mdl"
};

// Game settings
enum GameState {
	State_Unknown = 0,
	State_Starting,
	State_Active,
	State_HidersWin,
	State_SeekerWon,
}

// Game state specific
int currentSeeker;
bool hasBeenSeeker[MAXPLAYERS+1];
bool ignoreSeekerBalance;
int hiderSwapTime[MAXPLAYERS+1];
int hiderSwapCount[MAXPLAYERS+1];
bool ignoreDrop[MAXPLAYERS+1];
bool isStarting;

// Temp Ent Materials & Timers
Handle spawningTimer;
Handle hiderCheckTimer;
Handle doorToggleTimer;
Handle recordTimer;
Handle timesUpTimer;
Handle waitTimer;
Handle waitForStartTimer;
Handle acquireLocationsTimer;
Handle moveTimers[MAXPLAYERS+1];

UserMsg g_FadeUserMsgId;
int g_iSmokeParticle;
int g_iTeamNum = -1;

// Cvars
ConVar cvar_seekerFailDamageAmount;
Handle cvarStorage;

ConVar cvar_survivorLimit;
ConVar cvar_separationMinRange;
ConVar cvar_separationMaxRange;
ConVar cvar_abmAutoHard;
ConVar cvar_sbFixEnabled;
ConVar cvar_sbPushScale;
ConVar cvar_battlestationGiveUp;
ConVar cvar_sbMaxBattlestationRange;
ConVar cvar_enforceProximityRange;
ConVar cvar_spectatorIdleTime;

// Bot Movement specifics
float flowMin, flowMax;
float seekerPos[3];
float seekerFlow = 0.0;
float vecLastLocation[MAXPLAYERS+1][3]; 

#include <gamemodes/base>

// Declare variables before includes that use them
MovePoints movePoints;
GuessWhoGame Game;

#include <guesswho/gwcore>
#include <guesswho/gwpoints>
#include <guesswho/gwgame>
#include <guesswho/gwcmds>
#include <guesswho/gwents>
#include <guesswho/gwtimers>

public Plugin myinfo = {
	name = "[Rage] Guess Who Gamemode", 
	author = "jackzmc & Yani", 
	description = "Hide and seek gamemode where one seeker hunts hiders disguised as bots", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Jackzmc/sourcemod-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	lateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	EngineVersion g_Game = GetEngineVersion();
	if(g_Game != Engine_Left4Dead2) {
		SetFailState("This plugin is for L4D2 only.");	
	}

	Game.Init("GuessWho");

	g_iTeamNum = FindSendPropInfo("CTerrorPlayerResource", "m_iTeam");
	if (g_iTeamNum == -1)
		SetFailState("CTerrorPlayerResource \"m_iTeam\" offset is invalid");

	g_FadeUserMsgId = GetUserMessageId("Fade");

	cvarStorage = CreateTrie();
	
	cvar_survivorLimit = FindConVar("survivor_limit");
	cvar_separationMinRange = FindConVar("sb_separation_danger_min_range");
	cvar_separationMaxRange = FindConVar("sb_separation_danger_max_range");
	cvar_abmAutoHard = FindConVar("abm_autohard");
	cvar_sbFixEnabled = FindConVar("sb_fix_enabled");
	cvar_sbPushScale = FindConVar("sb_pushscale");
	cvar_battlestationGiveUp = FindConVar("sb_battlestation_give_up_range_from_human");
	cvar_sbMaxBattlestationRange = FindConVar("sb_max_battlestation_range_from_human");
	cvar_enforceProximityRange = FindConVar("enforce_proximity_range");
	cvar_spectatorIdleTime = FindConVar("sv_spectatoridle_time");

	ConVar hGamemode = FindConVar("mp_gamemode"); 
	if (hGamemode != null) {
		hGamemode.AddChangeHook(Event_GamemodeChange);
		char currentMode[64];
		hGamemode.GetString(currentMode, sizeof(currentMode));
		Event_GamemodeChange(hGamemode, currentMode, currentMode);
	}

	cvar_seekerFailDamageAmount = CreateConVar("rage_guesswho_seeker_damage", "20.0", "The amount of damage the seeker takes when they attack a bot.", FCVAR_NONE, true, 1.0);
	
	// Commands are registered in guesswho/gwcmds.inc
	
	AutoExecConfig(true, "rage_gamemode_guesswho");
}

public void OnPluginEnd() {
	Game.Cleanup();
	ResetGamemode();
}

public void Event_GamemodeChange(ConVar cvar, const char[] oldValue, const char[] newValue) {
	bool shouldEnable = StrEqual(newValue, "guesswho", false);
	
	if(isEnabled == shouldEnable) return;
	
	// Clean up timers
	if(spawningTimer != null) {
		KillTimer(spawningTimer);
		spawningTimer = null;
	}
	
	firstCheckDone = false;
	
	if(shouldEnable) {
		ResetGamemode(); // Reset to clean state before starting
		SetCvars();
		Game.Broadcast("Gamemode is starting");
		
		HookEvent("round_start", Event_RoundStart);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_bot_replace", Event_PlayerToBot);
		HookEvent("player_ledge_grab", Event_LedgeGrab);
		AddCommandListener(OnGoAwayFromKeyboard, "go_away_from_keyboard");
		
		InitGamemode();
	} else {
		ResetGamemode();
		RestoreCvars();
		
		UnhookEvent("round_start", Event_RoundStart);
		UnhookEvent("round_end", Event_RoundEnd);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("player_bot_replace", Event_PlayerToBot);
		UnhookEvent("player_ledge_grab", Event_LedgeGrab);
		RemoveCommandListener(OnGoAwayFromKeyboard, "go_away_from_keyboard");
		
		Game.Cleanup();
	}
	
	isEnabled = shouldEnable;
}

void ResetGamemode() {
	// Reset all game state to ready-to-start
	currentSeeker = 0;
	isStarting = false;
	
	// Kill all timers
	if(spawningTimer != null) {
		KillTimer(spawningTimer);
		spawningTimer = null;
	}
	if(hiderCheckTimer != null) {
		KillTimer(hiderCheckTimer);
		hiderCheckTimer = null;
	}
	if(doorToggleTimer != null) {
		KillTimer(doorToggleTimer);
		doorToggleTimer = null;
	}
	if(recordTimer != null) {
		KillTimer(recordTimer);
		recordTimer = null;
	}
	if(timesUpTimer != null) {
		KillTimer(timesUpTimer);
		timesUpTimer = null;
	}
	if(waitTimer != null) {
		KillTimer(waitTimer);
		waitTimer = null;
	}
	if(waitForStartTimer != null) {
		KillTimer(waitForStartTimer);
		waitForStartTimer = null;
	}
	if(acquireLocationsTimer != null) {
		KillTimer(acquireLocationsTimer);
		acquireLocationsTimer = null;
	}
	
	for(int i = 1; i <= MaxClients; i++) {
		if(moveTimers[i] != null) {
			KillTimer(moveTimers[i]);
			moveTimers[i] = null;
		}
		hasBeenSeeker[i] = false;
		hiderSwapTime[i] = 0;
		hiderSwapCount[i] = 0;
		ignoreDrop[i] = false;
		vecLastLocation[i][0] = 0.0;
		vecLastLocation[i][1] = 0.0;
		vecLastLocation[i][2] = 0.0;
	}
	
	ignoreSeekerBalance = false;
	
	PrintToServer("[Guess Who] Gamemode reset to ready state");
}

public Action OnGoAwayFromKeyboard(int client, const char[] command, int argc) {
	return Plugin_Handled;
}

void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) {
		L4D_ReviveSurvivor(client);
	}
}

void Event_PlayerToBot(Event event, const char[] name, bool dontBroadcast) {
	int userid = event.GetInt("player");
	int player = GetClientOfUserId(userid);
	int bot    = GetClientOfUserId(event.GetInt("bot")); 
	
	// Do not kick bots being spawned in
	if(spawningTimer == null && !IsFakeClient(player)) {
		// TODO: Game.Debug("possible idle bot:  %d (player: %d)", bot, player);
		CreateTimer(0.1, Timer_ResumeFromIdle, userid);
	}
}

Action Timer_ResumeFromIdle(Handle h, int userid) {
	int player = GetClientOfUserId(userid);
	if(player > 0)
		L4D_TakeOverBot(player);
	return Plugin_Handled;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(client > 0 && Game.State == State_Active) {
		if(client == currentSeeker) {
			Game.Broadcast("The seeker, %N, has died. Hiders win!", currentSeeker);
			Game.End(State_HidersWin);
		} else if(!IsFakeClient(client)) {
			if(attacker == currentSeeker) {
				Game.Broadcast("%N was killed", client);
			} else {
				Game.Broadcast("%N died", client);
			}
		} else {
			ClearInventory(client);
			KickClient(client);
			Game.Debug("Bot(%d) was killed", client);
		}
	}
	
	if(Game.AlivePlayers == 0) {
		if(Game.State == State_Active) {
			Game.Broadcast("Everyone has died. %N wins!", currentSeeker);
			Game.End(State_SeekerWon);
		}
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	waitTimer = CreateTimer(firstCheckDone ? 2.5 : 6.0, Timer_WaitForPlayers, _, TIMER_REPEAT);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	firstCheckDone = true;
	ResetGamemode();
}

public void OnMapStart() {
	isStarting = false;
	if(!isEnabled) return;
	
	int entity = FindEntityByClassname(0, "terror_player_manager");
	if(entity > 0) {
		SDKHook(entity, SDKHook_ThinkPost, ThinkPost);
	}
	
	char map[128];
	GetCurrentMap(map, sizeof(map));
	
	if(!StrEqual(g_currentMap, map)) {
		firstCheckDone = false;
		strcopy(g_currentSet, sizeof(g_currentSet), "default");
		if(!StrEqual(g_currentMap, "")) { 
			if(!movePoints.SaveMap(g_currentMap, g_currentSet)) {
				LogError("Could not save map data to disk");
			}
		}
		ReloadMapDB();
		strcopy(g_currentMap, sizeof(g_currentMap), map);
		Game.SetPoints(MovePoints.LoadMap(map, g_currentSet));
	}
	
	g_iLaserIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iSmokeParticle = GetParticleIndex(SMOKE_PARTICLE_PATH);
	
	if(g_iSmokeParticle == INVALID_STRING_INDEX) {
		LogError("g_iSmokeParticle (%s) is invalid", SMOKE_PARTICLE_PATH);
	}
	
	PrecacheSound(SOUND_MODEL_SWAP);
	SetCvars();
	
	if(lateLoaded) {
		int seeker = Game.Seeker;
		if(seeker > -1) {
			currentSeeker = seeker;
			Game.Debug("-Late load- Seeker: %N", currentSeeker);
		}
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i)) {
				Game.SetupPlayer(i);
			}
		}
		InitGamemode();
	}
	
	Game.State = State_Unknown;
	ResetGamemode();
}

public void OnMapEnd() {
	ResetGamemode();
	Game.Cleanup();
}

public void ThinkPost(int entity) {  
	static int iTeamNum[MAXPLAYERS+1];
	GetEntDataArray(entity, g_iTeamNum, iTeamNum, sizeof(iTeamNum));
	
	for(int i = 1 ; i<= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i)) {
			iTeamNum[i] = 1;
		}
	}
	
	SetEntDataArray(entity, g_iTeamNum, iTeamNum, sizeof(iTeamNum));
}

public void OnClientPutInServer(int client) {
	if(!isEnabled) return;
	
	if(IsFakeClient(client)) {
		if(GetClientTeam(client) == 3) {
			KickClient(client, "GW: Remove Special Infected");
		}
	} else {
		ChangeClientTeam(client, 1);
		isPendingPlay[client] = true;
		Game.Broadcast("%N will play next round", client);
		Game.TeleportToSpawn(client);
	}
}

public void OnClientDisconnect(int client) {
	if(!isEnabled) return;
	
	if(client == currentSeeker) {
		Game.Broadcast("The seeker has disconnected");
		Game.End(State_HidersWin);
	} else if(!IsFakeClient(client) && Game.State == State_Active) {
		Game.Broadcast("A hider has left (%N)", client);
		if(Game.AlivePlayers == 0 && Game.State == State_Active) {
			Game.Broadcast("Game Over. %N wins!", currentSeeker);
			Game.End(State_SeekerWon);
		}
	}
}

void SetCvars() {
	Game.Debug("Setting convars");
	
	if(cvar_survivorLimit != null) {
		cvar_survivorLimit.SetBounds(ConVarBound_Upper, true, 64.0);
		char key[64], value[32];
		Format(key, sizeof(key), "survivor_limit");
		IntToString(cvar_survivorLimit.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_survivorLimit.IntValue = MaxClients;
	}
	
	if(cvar_separationMinRange != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sb_separation_danger_min_range");
		IntToString(cvar_separationMinRange.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_separationMinRange.IntValue = 1000;
	}
	
	if(cvar_separationMaxRange != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sb_separation_danger_max_range");
		IntToString(cvar_separationMaxRange.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_separationMaxRange.IntValue = 1000;
	}
	
	if(cvar_abmAutoHard != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "abm_autohard");
		IntToString(cvar_abmAutoHard.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_abmAutoHard.IntValue = 0;
	}
	
	if(cvar_sbFixEnabled != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sb_fix_enabled");
		IntToString(cvar_sbFixEnabled.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_sbFixEnabled.IntValue = 0;
	}
	
	if(cvar_sbPushScale != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sb_pushscale");
		IntToString(cvar_sbPushScale.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_sbPushScale.IntValue = 0;
	}
	
	if(cvar_battlestationGiveUp != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sb_battlestation_give_up_range_from_human");
		FloatToString(cvar_battlestationGiveUp.FloatValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_battlestationGiveUp.FloatValue = 5000.0;
	}
	
	if(cvar_sbMaxBattlestationRange != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sb_max_battlestation_range_from_human");
		FloatToString(cvar_sbMaxBattlestationRange.FloatValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_sbMaxBattlestationRange.FloatValue = 5000.0;
	}
	
	if(cvar_enforceProximityRange != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "enforce_proximity_range");
		IntToString(cvar_enforceProximityRange.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_enforceProximityRange.IntValue = 10000;
	}
	
	if(cvar_spectatorIdleTime != null) {
		char key[64], value[32];
		Format(key, sizeof(key), "sv_spectatoridle_time");
		IntToString(cvar_spectatorIdleTime.IntValue, value, sizeof(value));
		SetTrieString(cvarStorage, key, value);
		cvar_spectatorIdleTime.IntValue = 120;
	}
}

void RestoreCvars() {
	if(cvarStorage == null) return;
	
	char key[64], value[32];
	
	if(cvar_survivorLimit != null) {
		Format(key, sizeof(key), "survivor_limit");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_survivorLimit.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_separationMinRange != null) {
		Format(key, sizeof(key), "sb_separation_danger_min_range");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_separationMinRange.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_separationMaxRange != null) {
		Format(key, sizeof(key), "sb_separation_danger_max_range");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_separationMaxRange.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_abmAutoHard != null) {
		Format(key, sizeof(key), "abm_autohard");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_abmAutoHard.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_sbFixEnabled != null) {
		Format(key, sizeof(key), "sb_fix_enabled");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_sbFixEnabled.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_sbPushScale != null) {
		Format(key, sizeof(key), "sb_pushscale");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_sbPushScale.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_battlestationGiveUp != null) {
		Format(key, sizeof(key), "sb_battlestation_give_up_range_from_human");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_battlestationGiveUp.FloatValue = StringToFloat(value);
		}
	}
	
	if(cvar_sbMaxBattlestationRange != null) {
		Format(key, sizeof(key), "sb_max_battlestation_range_from_human");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_sbMaxBattlestationRange.FloatValue = StringToFloat(value);
		}
	}
	
	if(cvar_enforceProximityRange != null) {
		Format(key, sizeof(key), "enforce_proximity_range");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_enforceProximityRange.IntValue = StringToInt(value);
		}
	}
	
	if(cvar_spectatorIdleTime != null) {
		Format(key, sizeof(key), "sv_spectatoridle_time");
		if(GetTrieString(cvarStorage, key, value, sizeof(value))) {
			cvar_spectatorIdleTime.IntValue = StringToInt(value);
		}
	}
}

void InitGamemode() {
	if(isStarting && Game.State != State_Unknown) {
		Game.Warn("InitGamemode() called in an incorrect state (%d)", Game.State);
		return;
	}
	
	SetupEntities();
	Game.DebugConsole("InitGamemode(): activating");
	
	ArrayList validPlayerIds = new ArrayList();
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i)) {
			L4D2_SetPlayerSurvivorGlowState(i, false);
			L4D2_RemoveEntityGlow(i);
			
			activeBotLocations[i].attempts = 0;
			hiderSwapCount[i] = 0;
			distQueue[i].Clear();
			
			ClearInventory(i);
			
			if(IsFakeClient(i)) {
				KickClient(i);
			} else {
				ChangeClientTeam(i, 2);
				if(!IsPlayerAlive(i)) {
					L4D_RespawnPlayer(i);
				}
				if(!hasBeenSeeker[i] || ignoreSeekerBalance)
					validPlayerIds.Push(GetClientUserId(i));
			}
		}
	}
	
	if(validPlayerIds.Length == 0) {
		Game.Warn("Ignoring InitGamemode() with no valid survivors");
		delete validPlayerIds;
		return;
	}
	
	ignoreSeekerBalance = false;
	int newSeeker = GetClientOfUserId(validPlayerIds.Get(GetURandomInt() % validPlayerIds.Length));
	delete validPlayerIds;
	
	if(newSeeker > 0) {
		hasBeenSeeker[newSeeker] = true;
		Game.Broadcast("%N is the seeker", newSeeker);
		Game.Seeker = newSeeker;
		currentSeeker = newSeeker;
		SetPlayerBlind(newSeeker, 255);
		SetEntPropFloat(newSeeker, Prop_Send, "m_flLaggedMovementValue", 0.0);
	}
	
	Game.TeleportAllToStart();
	spawningTimer = CreateTimer(0.2, Timer_SpawnBots, 16, TIMER_REPEAT);
}

Action Timer_SpawnBots(Handle h, int max) {
	static int count;
	if(count < max) {
		if(AddSurvivor()) {
			count++;
			return Plugin_Continue;
		} else if(count < 0) {
			PrintToChatAll("GUESS WHO: FATAL ERROR: AddSurvivor() failed");
			LogError("Guess Who: Fatal Error: AddSurvivor() failed");
			count = 0;
			return Plugin_Stop;
		}
	}
	count = 0;
	CreateTimer(1.0, Timer_SpawnPost);
	return Plugin_Stop;
}

Action Timer_SpawnPost(Handle h) {
	spawningTimer = null;
	
	bool isL4D1 = L4D2_GetSurvivorSetMap() == 1;
	int remainingSeekers;
	int survivorMaxIndex = isL4D1 ? 3 : 7;
	int survivorIndexBot;
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) {
			int survivor;
			if(IsFakeClient(i)) {
				survivor = survivorIndexBot;
				if(++survivorIndexBot > survivorMaxIndex) {
					survivorIndexBot = 0;
				}
			} else {
				survivor = GetURandomInt() % survivorMaxIndex;
				if(i != currentSeeker) {
					if(!hasBeenSeeker[i]) {
						remainingSeekers++;
					}
					PrintToChat(i, "\x04[Guess Who]\x01 You can change your model %d times by looking at a player and pressing RELOAD", HIDER_SWAP_LIMIT);
				}
			}
			
			Game.SetupPlayer(i);
			SetEntityModel(i, SURVIVOR_MODELS[survivor]);
			SetEntProp(i, Prop_Send, "m_survivorCharacter", survivor);
		}
	}
	
	if(remainingSeekers == 0) {
		Game.Broadcast("All players have been seekers once");
		for(int i = 0; i <= MaxClients; i++) { 
			hasBeenSeeker[i] = false;
		}
	}
	
	Game.Debug("waiting for safe area leave", BaseDebug_Server | BaseDebug_ChatAll);
	waitForStartTimer = CreateTimer(1.0, Timer_WaitForStart, _, TIMER_REPEAT);
	return Plugin_Handled;
}

Action Timer_WaitForStart(Handle h) {
	if(mapConfig.hasSpawnpoint || L4D_HasAnySurvivorLeftSafeArea()) {
		int targetPlayer = L4D_GetHighestFlowSurvivor(); 
		if(targetPlayer > 0) {
			GetClientAbsOrigin(targetPlayer, seekerPos);
		}
		
		int seeker = currentSeeker;
		if(seeker <= 0) {
			PrintToChatAll("\x04[Guess Who]\x01 Error: No seeker found, game in bugged state, restarting");
			for(int i = 1; i <= MaxClients; i++) {
				if(IsClientConnected(i) && IsClientInGame(i)) {
					ForcePlayerSuicide(i);
				}
			}
			return Plugin_Stop;
		}
		
		seekerFlow = L4D2Direct_GetFlowDistance(seeker);
		acquireLocationsTimer = CreateTimer(0.5, Timer_AcquireLocations, _, TIMER_REPEAT);
		hiderCheckTimer = CreateTimer(5.0, Timer_CheckHiders, _, TIMER_REPEAT);
		doorToggleTimer = CreateTimer(DOOR_TOGGLE_INTERVAL, Timer_DoorToggles, _, TIMER_REPEAT);
		
		for(int i = 1; i <= MaxClients; i++) {
			if(i != currentSeeker && IsClientConnected(i) && IsClientInGame(i)) {
				if(IsFakeClient(i)) {
					if(movePoints.Length > 0) {
						moveTimers[i] = CreateTimer(GetRandomFloat(BOT_MOVE_RANDOM_MIN_TIME, BOT_MOVE_RANDOM_MAX_TIME), Timer_BotMove, GetClientUserId(i), TIMER_REPEAT);
						movePoints.GetRandomPoint(activeBotLocations[i]);
					}
					if(targetPlayer > 0)
						TeleportEntity(i, activeBotLocations[i].pos, activeBotLocations[i].ang, NULL_VECTOR);
				} else if(targetPlayer > 0) {
					TeleportEntity(i, seekerPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		
		float seedTime = movePoints.Length > SEED_MIN_LOCATIONS ? 5.0 : SEED_TIME;
		Game.Broadcast("The Seeker (%N) will start in %.0f seconds", Game.Seeker, seedTime);
		
		Game.State = State_Starting;
		Game.Tick = 0;
		Game.MapTime = RoundFloat(seedTime);
		// Game.PopulateCoins(); // TODO: Implement coin population if needed
		
		CreateTimer(seedTime, Timer_StartSeeker);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action Timer_StartSeeker(Handle h) {
	CPrintToChatAll("{blue}%N{default} :  Here I come", currentSeeker);
	Game.TeleportToSpawn(currentSeeker);
	SetPlayerBlind(currentSeeker, 0);
	Game.State = State_Active;
	Game.Tick = 0;
	SetEntPropFloat(currentSeeker, Prop_Send, "m_flLaggedMovementValue", 1.0);
	
	if(mapConfig.mapTime == 0) {
		mapConfig.mapTime = DEFAULT_MAP_TIME;
	}
	Game.MapTime = mapConfig.mapTime;
	timesUpTimer = CreateTimer(float(mapConfig.mapTime), Timer_TimesUp);
	return Plugin_Continue;
}

Action Timer_TimesUp(Handle h) {
	Game.Broadcast("The seeker ran out of time. Hiders win!");
	Game.End(State_HidersWin);
	timesUpTimer = null;
	return Plugin_Handled;
}

Action OnWeaponEquip(int client, int weapon) {
	if(weapon <= 0 || ignoreDrop[client]) return Plugin_Continue;
	if(currentSeeker == client) 
		return Plugin_Handled;
	return Plugin_Continue;
}

Action OnTakeDamageAlive(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {
	if(attacker == currentSeeker) {
		damage = 100.0;
		ClearInventory(victim);
		if(attacker > 0 && attacker <= MaxClients && IsFakeClient(victim)) {
			PrintToChat(attacker, "\x04[Guess Who]\x01 That was a bot! -%.0f health", cvar_seekerFailDamageAmount.FloatValue);
			SDKHooks_TakeDamage(attacker, 0, 0, cvar_seekerFailDamageAmount.FloatValue, DMG_DIRECT);
		}
		return Plugin_Changed;
	} else if(attacker > 0 && attacker <= MaxClients) {
		damage = 0.0;
		return Plugin_Changed;
	} else {
		return Plugin_Continue;
	}
}

Action Timer_DoorToggles(Handle h) {
	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE) {
		if(GetURandomFloat() < DOOR_TOGGLE_CHANCE)
			AcceptEntityInput(entity, "Toggle");
	}
	return Plugin_Handled;
}

Action Timer_AcquireLocations(Handle h) {
	bool ignoreSeeker = true;
	#if defined DEBUG_SEEKER_PATH_CREATION
		ignoreSeeker = false;
	#endif

	seekerFlow = L4D2Direct_GetFlowDistance(currentSeeker);
	GetClientAbsOrigin(currentSeeker, seekerPos);

	for(int i = 1; i <= MaxClients; i++) {
		if((!ignoreSeeker || i != currentSeeker) && IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && GetEntityFlags(i) & FL_ONGROUND ) {
			LocationMeta meta;
			GetClientAbsOrigin(i, meta.pos);
			GetClientEyeAngles(i, meta.ang);

			if(meta.pos[0] != vecLastLocation[i][0] || meta.pos[1] != vecLastLocation[i][1] || meta.pos[2] != vecLastLocation[i][2]) {
				movePoints.AddPoint(meta);

				if(movePoints.Length > MAX_VALID_LOCATIONS) {
					Game.Warn("Hit MAX_VALID_LOCATIONS (%d), clearing some locations", MAX_VALID_LOCATIONS);
					movePoints.Sort(Sort_Random, Sort_Float);
					movePoints.Erase(RoundFloat(MAX_VALID_LOCATIONS * MAX_VALID_LOCATIONS_KEEP_PERCENT));
				}

				#if defined DEBUG_SHOW_POINTS
				Effect_DrawBeamBoxRotatableToClient(i, meta.pos, DEBUG_POINT_VIEW_MIN, DEBUG_POINT_VIEW_MAX, NULL_VECTOR, g_iLaserIndex, 0, 0, 0, 150.0, 0.1, 0.1, 0, 0.0, {0, 0, 255, 64}, 0);
				#endif

				vecLastLocation[i] = meta.pos;
			}
		}
	}

	return Plugin_Continue;
}

Action Timer_BotMove(Handle h, int userid) {
	int i = GetClientOfUserId(userid);
	if(i == 0) return Plugin_Stop;

	if(GetURandomFloat() > BOT_MOVE_CHANCE) {
		L4D2_RunScript("CommandABot({cmd=1,bot=GetPlayerFromUserID(%i),pos=Vector(%f,%f,%f)})", 
			GetClientUserId(i), 
			activeBotLocations[i].pos[0], activeBotLocations[i].pos[1], activeBotLocations[i].pos[2]
		);

		#if defined DEBUG_SHOW_POINTS
			Effect_DrawBeamBoxRotatableToAll(activeBotLocations[i].pos, DEBUG_POINT_VIEW_MIN, DEBUG_POINT_VIEW_MAX, NULL_VECTOR, g_iLaserIndex, 0, 0, 0, 150.0, 0.1, 0.1, 0, 0.0, {157, 0, 255, 255}, 0);
		#endif

		return Plugin_Continue;
	}

	float botFlow = L4D2Direct_GetFlowDistance(i);
	static float pos[3];

	if(botFlow > 0.0 && (botFlow < flowMin || botFlow > flowMax)) {
		activeBotLocations[i].runto = GetURandomFloat() > 0.90;
		L4D2_RunScript("CommandABot({cmd=1,bot=GetPlayerFromUserID(%i),pos=Vector(%f,%f,%f)})", GetClientUserId(i), seekerPos[0], seekerPos[1], seekerPos[2]);

		#if defined DEBUG_BOT_MOVE
		TE_SetupBeamLaser(i, currentSeeker, g_iLaserIndex, 0, 0, 0, 8.0, 0.5, 0.1, 0, 1.0, {255, 255, 0, 125}, 1);
		TE_SendToAll();
		Game.DebugConsole("BOT %N TOO FAR (%f) BOUNDS (%f, %f)-> Moving to seeker (%f %f %f)", i, botFlow, flowMin, flowMax, seekerPos[0], seekerPos[1], seekerPos[2]);
		#endif

		activeBotLocations[i].attempts = 0;
	} else if(movePoints.Length > 0) {
		GetAbsOrigin(i, pos);
		float distanceToPoint = GetVectorDistance(pos, activeBotLocations[i].pos);

		if(distanceToPoint < BOT_MOVE_NOT_REACHED_DISTANCE || GetURandomFloat() < 0.20) {
			activeBotLocations[i].attempts = 0;

			#if defined DEBUG_BOT_MOVE
			L4D2_SetPlayerSurvivorGlowState(i, false);
			L4D2_RemoveEntityGlow(i);
			#endif

			// Has reached destination
			if(mapConfig.hasSpawnpoint && FloatAbs(botFlow - seekerFlow) < BOT_MOVE_AVOID_FLOW_DIST && GetURandomFloat() < BOT_MOVE_AVOID_SEEKER_CHANCE) {
				if(!movePoints.GetRandomPointFar(seekerPos, activeBotLocations[i].pos, BOT_MOVE_AVOID_MIN_DISTANCE)) {
					activeBotLocations[i].pos = mapConfig.spawnpoint;
				} else {
					activeBotLocations[i].runto = GetURandomFloat() < 0.75;
				}

				#if defined DEBUG_SHOW_POINTS
				Effect_DrawBeamBoxRotatableToAll(activeBotLocations[i].pos, DEBUG_POINT_VIEW_MIN, DEBUG_POINT_VIEW_MAX, NULL_VECTOR, g_iLaserIndex, 0, 0, 0, 150.0, 0.2, 0.1, 0, 0.0, {255, 255, 255, 255}, 0);
				#endif
			} else {
				movePoints.GetRandomPoint(activeBotLocations[i]);
			}

			if(!L4D2_IsReachable(i, activeBotLocations[i].pos)) {
				#if defined DEBUG_BOT_MOVE
				Game.Warn("Point is unreachable at (%f, %f, %f) for %L", activeBotLocations[i].pos[0], activeBotLocations[i].pos[1], activeBotLocations[i].pos[2], i);
				Effect_DrawBeamBoxRotatableToAll(activeBotLocations[i].pos, DEBUG_POINT_VIEW_MIN, view_as<float>({ 10.0, 10.0, 100.0 }), NULL_VECTOR, g_iLaserIndex, 0, 0, 0, 400.0, 2.0, 3.0, 0, 0.0, {255, 0, 0, 255}, 0);
				#endif

				movePoints.GetRandomPoint(activeBotLocations[i]);
			}
		} else {
			// Has not reached dest
			activeBotLocations[i].attempts++;

			#if defined DEBUG_MOVE_ATTEMPTS
			PrintToConsoleAll("[gw/debug] Bot %d - move attempt %d - dist: %f", i, activeBotLocations[i].attempts, distanceToPoint);
			#endif

			if(activeBotLocations[i].attempts == BOT_MOVE_NOT_REACHED_ATTEMPT_RUNJUMP) {
				if(distanceToPoint <= (BOT_MOVE_NOT_REACHED_DISTANCE * 2)) {
					activeBotLocations[i].jump = true;
				} else {
					activeBotLocations[i].runto = true;
				}
			} else if(activeBotLocations[i].attempts > BOT_MOVE_NOT_REACHED_ATTEMPT_RETRY) {
				movePoints.GetRandomPoint(activeBotLocations[i]);
			} 

			#if defined DEBUG_SHOW_POINTS
			int color[4];
			color[0] = 255;
			color[2] = 255;
			color[3] = 120 + activeBotLocations[i].attempts * 45;
			Effect_DrawBeamBoxRotatableToAll(activeBotLocations[i].pos, DEBUG_POINT_VIEW_MIN, DEBUG_POINT_VIEW_MAX, NULL_VECTOR, g_iLaserIndex, 0, 0, 0, 150.0, 0.1, 0.1, 0, 0.0, color, 0);
			#endif
		}

		LookAtPoint(i, activeBotLocations[i].pos);
		L4D2_RunScript("CommandABot({cmd=1,bot=GetPlayerFromUserID(%i),pos=Vector(%f,%f,%f)})", 
			GetClientUserId(i), 
			activeBotLocations[i].pos[0], activeBotLocations[i].pos[1], activeBotLocations[i].pos[2]
		);
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	if(!isEnabled) return Plugin_Continue;
	
	if(IsFakeClient(client)) {
		if(activeBotLocations[client].jump) {
			activeBotLocations[client].jump = false;
			buttons |= (IN_WALK | IN_JUMP | IN_FORWARD);
			return Plugin_Changed;
		}
		buttons |= (activeBotLocations[client].runto ? IN_WALK : IN_SPEED);
		if(GetURandomFloat() < BOT_MOVE_USE_CHANCE) {
			buttons |= IN_USE;
		}
		float random = GetURandomFloat();
		if(random < BOT_MOVE_JUMP_CHANCE) {
			buttons |= IN_JUMP;
		} else if(random < BOT_MOVE_SHOVE_CHANCE) {
			buttons |= IN_ATTACK2;
		}
		return Plugin_Changed;
	} else if(client != currentSeeker && buttons & IN_RELOAD) {
		if(hiderSwapCount[client] >= HIDER_SWAP_LIMIT) {
			PrintHintText(client, "Swap limit reached");
		} else {
			int target = GetClientAimTarget(client, true);
			if(target > 0) {
				int time = GetTime();
				float diff = float(time - hiderSwapTime[client]);
				if(diff > HIDER_SWAP_COOLDOWN) {
					hiderSwapTime[client] = GetTime();
					hiderSwapCount[client]++;
					
					ClearInventory(target);
					char modelName[64];
					GetClientModel(target, modelName, sizeof(modelName));
					int type = GetEntProp(target, Prop_Send, "m_survivorCharacter");
					SetEntityModel(client, modelName);
					SetEntProp(client, Prop_Send, "m_survivorCharacter", type);
					
					float pos[3];
					GetClientAbsOrigin(client, pos);
					EmitSoundToAll("ui/pickup_secret01.wav", client, SNDCHAN_STATIC, .origin = pos);
					PrintHintText(client, "You have %d swaps remaining", HIDER_SWAP_LIMIT - hiderSwapCount[client]);
					CreateTimer(0.1, Timer_ReGnome, client);
				} else {
					PrintHintText(client, "You can swap in %.0f seconds", HIDER_SWAP_COOLDOWN - diff);
				}
			}
		}
	}
	return Plugin_Continue;
}

Action Timer_ReGnome(Handle h, int client) {
	GivePlayerItem(client, "weapon_gnome");
	return Plugin_Handled;
}

void ClearInventory(int client) {
	for(int i = 0; i <= 5; i++) {
		int item = GetPlayerWeaponSlot(client, i);
		if(item > 0) {
			RemovePlayerItem(client, item);
			AcceptEntityInput(item, "kill");
		}
	}
}

bool AddSurvivor() {
	if (GetClientCount(false) >= MaxClients - 1) {
		return false;
	}
	int i = CreateFakeClient("GuessWhoBot");
	bool result;
	if (i > 0) {
		if (DispatchKeyValue(i, "classname", "SurvivorBot")) {
			ChangeClientTeam(i, 2);
			if (DispatchSpawn(i)) {
				result = true;
			}
		}
		CreateTimer(0.2, Timer_Kick, GetClientUserId(i));
	}
	return result;
}

Action Timer_Kick(Handle h, int u) {
	int i = GetClientOfUserId(u);
	if(i > 0) KickClient(i);
	return Plugin_Handled;
}

stock void L4D2_RunScript(const char[] sCode, any ...) {
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE|| !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		DispatchSpawn(iScriptLogic);
	}
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

public void OnSceneStageChanged(int scene, SceneStages stage) {
	if(isEnabled && stage == SceneStage_Started) {
		int activator = GetSceneInitiator(scene);
		if(activator == 0) {
			CancelScene(scene);
		}
	}
}

// Command handlers are in guesswho/gwcmds.inc

// Helper functions are in guesswho includes

