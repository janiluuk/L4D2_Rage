#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "[Rage] Poison Melee"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <rage/validation>
#include <rage/skills>
#include <rage/effects>

#pragma semicolon 1
#pragma newdecls required

// ConVars
ConVar g_cvarEnable;
ConVar g_cvarDamage;
ConVar g_cvarDuration;
ConVar g_cvarTickInterval;
ConVar g_cvarChance;

// Rage system
int g_iClassID = -1;
bool g_bRageAvailable = false;
const int CLASS_SABOTEUR = 4;

// Client data
bool g_bHasAbility[MAXPLAYERS+1] = {false, ...};
bool g_bPoisonActive[MAXPLAYERS+1] = {false, ...};

// Poison tracking
Handle g_hPoisonTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
float g_fPoisonDamage[MAXPLAYERS+1] = {0.0, ...};
float g_fPoisonEndTime[MAXPLAYERS+1] = {0.0, ...};
int g_iPoisonAttacker[MAXPLAYERS+1] = {0, ...};

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Rage Team",
	description = "Saboteur skill: Melee weapons apply poison/toxic damage over time",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("rage_survivor_poisonmelee");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("rage_poisonmelee_enable", "1", "Enable Poison Melee skill", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDamage = CreateConVar("rage_poisonmelee_damage", "2.0", "Poison damage per tick", FCVAR_NOTIFY, true, 0.1);
	g_cvarDuration = CreateConVar("rage_poisonmelee_duration", "10.0", "Poison duration in seconds", FCVAR_NOTIFY, true, 1.0);
	g_cvarTickInterval = CreateConVar("rage_poisonmelee_tick", "1.0", "Time between poison ticks", FCVAR_NOTIFY, true, 0.1);
	g_cvarChance = CreateConVar("rage_poisonmelee_chance", "100", "Chance to apply poison (0-100)", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	AutoExecConfig(true, "rage_poisonmelee");
}

public void OnAllPluginsLoaded()
{
	RageSkills_Refresh("PoisonMelee", 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryAdded(const char[] name)
{
	RageSkills_OnLibraryAdded(name, "PoisonMelee", 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, RAGE_PLUGIN_NAME, false))
	{
		g_iClassID = -1;
	}

	RageSkills_OnLibraryRemoved(name, g_bRageAvailable);
}

public void Rage_OnPluginState(char[] plugin, int state)
{
	if (!StrEqual(plugin, RAGE_PLUGIN_NAME, false))
		return;

	if (state == 1)
	{
		g_bRageAvailable = true;
		if (g_iClassID == -1)
		{
			g_iClassID = RegisterRageSkill("PoisonMelee", 0);
		}
	}
	else if (state == 0)
	{
		g_bRageAvailable = false;
		g_iClassID = -1;
	}
}

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
	g_bHasAbility[client] = (newClass == CLASS_SABOTEUR);
	
	// Hook SDKHooks for melee damage
	if (g_bHasAbility[client] && IsClientInGame(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	else if (IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	return g_bHasAbility[client] ? 1 : 0;
}

public void OnClientPutInServer(int client)
{
	g_bHasAbility[client] = false;
	g_bPoisonActive[client] = false;
	
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientDisconnect(int client)
{
	StopPoison(client);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_bPoisonActive[i] = false;
			g_fPoisonDamage[i] = 0.0;
			g_fPoisonEndTime[i] = 0.0;
			g_iPoisonAttacker[i] = 0;
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bRageAvailable || !g_cvarEnable.BoolValue)
		return Plugin_Continue;

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (!g_bHasAbility[attacker])
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) == 2)
		return Plugin_Continue;

	// Check if damage is from melee
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (weapon <= 0 || !IsValidEntity(weapon))
		return Plugin_Continue;

	char weaponName[64];
	GetEntityClassname(weapon, weaponName, sizeof(weaponName));
	
	// Check if it's a melee weapon
	if (StrContains(weaponName, "melee", false) == -1 && StrContains(weaponName, "weapon_", false) != 0)
		return Plugin_Continue;

	// Check chance
	int chance = g_cvarChance.IntValue;
	if (GetRandomInt(1, 100) > chance)
		return Plugin_Continue;

	// Apply poison
	ApplyPoison(victim, attacker);
	
	return Plugin_Continue;
}

void ApplyPoison(int victim, int attacker)
{
	if (!IsValidClient(victim) || !IsPlayerAlive(victim))
		return;

	// Stop existing poison
	StopPoison(victim);

	// Start new poison
	g_bPoisonActive[victim] = true;
	g_fPoisonDamage[victim] = g_cvarDamage.FloatValue;
	g_fPoisonEndTime[victim] = GetGameTime() + g_cvarDuration.FloatValue;
	g_iPoisonAttacker[victim] = attacker;

	// Create poison tick timer
	float tickInterval = g_cvarTickInterval.FloatValue;
	g_hPoisonTimers[victim] = CreateTimer(tickInterval, Timer_PoisonTick, GetClientUserId(victim), TIMER_REPEAT);

	// Visual effect - green glow
	SetEntProp(victim, Prop_Send, "m_glowColorOverride", 0x00FF00); // Green
	SetEntProp(victim, Prop_Send, "m_iGlowType", 3);
	SetEntProp(victim, Prop_Send, "m_nGlowRange", 500);
	SetEntProp(victim, Prop_Send, "m_nGlowRangeMin", 0);

	// Sound effect
	EmitSoundToClient(victim, "player/survivor/heal/bandaging_1.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
}

public Action Timer_PoisonTick(Handle timer, int userid)
{
	int victim = GetClientOfUserId(userid);
	if (victim <= 0 || !IsClientInGame(victim) || !IsPlayerAlive(victim))
	{
		return Plugin_Stop;
	}

	if (!g_bPoisonActive[victim])
	{
		return Plugin_Stop;
	}

	float gameTime = GetGameTime();
	if (gameTime >= g_fPoisonEndTime[victim])
	{
		StopPoison(victim);
		return Plugin_Stop;
	}

	int attacker = g_iPoisonAttacker[victim];
	if (attacker <= 0 || !IsClientInGame(attacker))
	{
		StopPoison(victim);
		return Plugin_Stop;
	}

	// Deal poison damage
	SDKHooks_TakeDamage(victim, attacker, attacker, g_fPoisonDamage[victim], DMG_POISON);

	// Screen effect
	ScreenFade(victim, 200, 0, 255, 0, 50, 0x0001); // Green flash

	return Plugin_Continue;
}

void StopPoison(int client)
{
	if (client <= 0 || client > MaxClients)
		return;

	g_bPoisonActive[client] = false;
	g_fPoisonDamage[client] = 0.0;
	g_fPoisonEndTime[client] = 0.0;
	g_iPoisonAttacker[client] = 0;

	if (g_hPoisonTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPoisonTimers[client]);
		g_hPoisonTimers[client] = INVALID_HANDLE;
	}

	// Remove glow
	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	}
}

void ScreenFade(int client, int r, int g, int b, int a, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", client);
	if (msg != INVALID_HANDLE)
	{
		BfWriteShort(msg, duration);
		BfWriteShort(msg, 0);
		BfWriteShort(msg, type);
		BfWriteByte(msg, r);
		BfWriteByte(msg, g);
		BfWriteByte(msg, b);
		BfWriteByte(msg, a);
		EndMessage();
	}
}

