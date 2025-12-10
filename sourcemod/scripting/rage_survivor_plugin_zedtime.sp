#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "ZedTime"
#define PLUGIN_NAME "[Rage] Zed Time"

#include <sourcemod>
#include <sdktools>
#include <rage/validation>
#include <rage/skills>
#include <rage/cooldown_notify>

#pragma semicolon 1
#pragma newdecls required

// ConVars
ConVar g_cvarEnable;
ConVar g_cvarDuration;
ConVar g_cvarSlowFactor;
ConVar g_cvarCooldown;
ConVar g_cvarAffectAll;

// Rage system
int g_iClassID = -1;
bool g_bRageAvailable = false;
const int CLASS_SOLDIER = 1;

// Client data
float g_fNextUse[MAXPLAYERS+1] = {0.0, ...};
bool g_bHasAbility[MAXPLAYERS+1] = {false, ...};
bool g_bZedTimeActive = false;
Handle g_hZedTimeTimer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Rage Team",
	description = "Soldier skill: Slow motion (Zed Time) effect",
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

	RegPluginLibrary("rage_survivor_zedtime");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("rage_zedtime_enable", "1", "Enable Zed Time skill", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDuration = CreateConVar("rage_zedtime_duration", "5.0", "Zed Time duration in seconds", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	g_cvarSlowFactor = CreateConVar("rage_zedtime_slowfactor", "0.3", "Time scale (0.3 = 30% speed, 0.5 = 50% speed)", FCVAR_NOTIFY, true, 0.1, true, 0.9);
	g_cvarCooldown = CreateConVar("rage_zedtime_cooldown", "60.0", "Cooldown in seconds", FCVAR_NOTIFY, true, 10.0);
	g_cvarAffectAll = CreateConVar("rage_zedtime_affectall", "1", "Affect all players (1) or only enemies (0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "rage_zedtime");
}

public void OnAllPluginsLoaded()
{
	RageSkills_Refresh(PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryAdded(const char[] name)
{
	RageSkills_OnLibraryAdded(name, PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
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
			g_iClassID = RegisterRageSkill(PLUGIN_SKILL_NAME, 0);
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
	g_bHasAbility[client] = (newClass == CLASS_SOLDIER);
	return g_bHasAbility[client] ? 1 : 0;
}

public void OnMapStart()
{
	g_bZedTimeActive = false;
	
	if (g_hZedTimeTimer != INVALID_HANDLE)
	{
		KillTimer(g_hZedTimeTimer);
		g_hZedTimeTimer = INVALID_HANDLE;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fNextUse[i] = 0.0;
	}
}

public void OnClientPutInServer(int client)
{
	g_fNextUse[client] = 0.0;
	g_bHasAbility[client] = false;
}

public int OnSpecialSkillUsed(int client, int skill, int type)
{
	if (!g_bRageAvailable || !g_cvarEnable.BoolValue)
		return 0;

	char skillName[32];
	GetPlayerSkillName(client, skillName, sizeof(skillName));
	
	if (!StrEqual(skillName, PLUGIN_SKILL_NAME))
		return 0;

	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return 0;

	if (!g_bHasAbility[client])
		return 0;

	float gameTime = GetGameTime();
	if (g_fNextUse[client] > gameTime)
	{
		float wait = g_fNextUse[client] - gameTime;
		PrintHintText(client, "Zed Time ready in %.1f seconds", wait);
		return 0;
	}

	if (g_bZedTimeActive)
	{
		PrintHintText(client, "Zed Time is already active!");
		return 0;
	}

	// Activate Zed Time
	ActivateZedTime(client);
	
	g_fNextUse[client] = gameTime + g_cvarCooldown.FloatValue;
	CooldownNotify_Register(client, g_fNextUse[client], PLUGIN_SKILL_NAME);
	
	return 1;
}

void ActivateZedTime(int client)
{
	// client parameter kept for API consistency but not used in this implementation
	#pragma unused client
	float duration = g_cvarDuration.FloatValue;
	float slowFactor = g_cvarSlowFactor.FloatValue;
	
	g_bZedTimeActive = true;

	// Apply slow motion to all players
	bool affectAll = g_cvarAffectAll.BoolValue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		int team = GetClientTeam(i);
		if (!affectAll && team == 2) // Don't affect survivors if not set
			continue;
		
		// Set player speed multiplier
		SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", slowFactor);
		
		// Screen effect
		ScreenFade(i, 150, 150, 255, 50, RoundToCeil(duration * 1000.0), 0x0001);
	}

	// Sound effect
	EmitSoundToAll("player/survivor/heal/bandaging_1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	// Create timer to end Zed Time
	g_hZedTimeTimer = CreateTimer(duration, Timer_EndZedTime, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Notify all players
	PrintHintTextToAll("ZED TIME ACTIVATED!");
	PrintToChatAll("\x04[Zed Time]\x01 Time slows down for %.1f seconds!", duration);
}

public Action Timer_EndZedTime(Handle timer)
{
	EndZedTime();
	g_hZedTimeTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

void EndZedTime()
{
	if (!g_bZedTimeActive)
		return;

	g_bZedTimeActive = false;

	// Restore normal speed for all players
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}

	PrintHintTextToAll("Zed Time ended");
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

