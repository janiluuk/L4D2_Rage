#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "ChainLightning"
#define PLUGIN_NAME "[Rage] Chain Lightning"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <rage/validation>
#include <rage/skills>
#include <rage/cooldown_notify>
#include <rage/effects>

#pragma semicolon 1
#pragma newdecls required

// ConVars
ConVar g_cvarEnable;
ConVar g_cvarDamage;
ConVar g_cvarMaxChains;
ConVar g_cvarChainRange;
ConVar g_cvarCooldown;
ConVar g_cvarDamageFalloff;

// Rage system
int g_iClassID = -1;
bool g_bRageAvailable = false;
const int CLASS_SOLDIER = 1;

// Client data
float g_fNextUse[MAXPLAYERS+1] = {0.0, ...};
bool g_bHasAbility[MAXPLAYERS+1] = {false, ...};

// Effects
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Rage Team",
	description = "Soldier skill: Chain lightning that jumps between enemies",
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

	RegPluginLibrary("rage_survivor_chainlightning");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("rage_chainlightning_enable", "1", "Enable Chain Lightning skill", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDamage = CreateConVar("rage_chainlightning_damage", "50.0", "Base damage per chain", FCVAR_NOTIFY, true, 1.0);
	g_cvarMaxChains = CreateConVar("rage_chainlightning_maxchains", "5", "Maximum number of chains", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	g_cvarChainRange = CreateConVar("rage_chainlightning_range", "300.0", "Maximum range for chain jumps", FCVAR_NOTIFY, true, 50.0, true, 1000.0);
	g_cvarCooldown = CreateConVar("rage_chainlightning_cooldown", "30.0", "Cooldown in seconds", FCVAR_NOTIFY, true, 1.0);
	g_cvarDamageFalloff = CreateConVar("rage_chainlightning_falloff", "0.8", "Damage multiplier per chain (0.8 = 20% less each chain)", FCVAR_NOTIFY, true, 0.1, true, 1.0);

	AutoExecConfig(true, "rage_chainlightning");
	
	HookEvent("weapon_fire", Event_WeaponFire);
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
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	
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
		PrintHintText(client, "Chain Lightning ready in %.1f seconds", wait);
		return 0;
	}

	// Get target from crosshair
	int target = GetClientAimTarget(client, true);
	if (target <= 0 || !IsValidEntity(target))
	{
		PrintHintText(client, "Aim at an enemy to chain lightning!");
		return 0;
	}

	// Check if target is valid enemy
	int targetTeam = GetClientTeam(target);
	if (targetTeam == 2 || targetTeam == 0) // Survivor or spectator
	{
		PrintHintText(client, "Aim at an enemy!");
		return 0;
	}

	// Perform chain lightning
	PerformChainLightning(client, target);
	
	g_fNextUse[client] = gameTime + g_cvarCooldown.FloatValue;
	CooldownNotify_Register(client, g_fNextUse[client], PLUGIN_SKILL_NAME);
	
	return 1;
}

void PerformChainLightning(int client, int firstTarget)
{
	float damage = g_cvarDamage.FloatValue;
	float range = g_cvarChainRange.FloatValue;
	int maxChains = g_cvarMaxChains.IntValue;
	float falloff = g_cvarDamageFalloff.FloatValue;
	
	float startPos[3], targetPos[3];
	GetClientAbsOrigin(client, startPos);
	startPos[2] += 40.0; // Eye level
	
	int currentTarget = firstTarget;
	int chainCount = 0;
	int hitTargets[MAXPLAYERS+1];
	int hitCount = 0;
	
	// Track hit targets to avoid hitting same target twice
	hitTargets[hitCount++] = currentTarget;
	
	while (chainCount < maxChains && IsValidEntity(currentTarget))
	{
		GetClientAbsOrigin(currentTarget, targetPos);
		targetPos[2] += 30.0;
		
		// Deal damage
		SDKHooks_TakeDamage(currentTarget, client, client, damage, DMG_SHOCK);
		
		// Create visual effect
		CreateLightningBeam(startPos, targetPos);
		
		// Find next target
		int nextTarget = FindNextChainTarget(currentTarget, hitTargets, hitCount, range);
		if (nextTarget <= 0)
			break;
		
		hitTargets[hitCount++] = nextTarget;
		currentTarget = nextTarget;
		startPos = targetPos;
		damage *= falloff; // Reduce damage for next chain
		chainCount++;
	}
	
	// Sound effect
	EmitSoundToAll("ambient/energy/spark4.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
	
	PrintHintText(client, "Chain Lightning: %d chains!", chainCount + 1);
}

int FindNextChainTarget(int fromTarget, int[] hitTargets, int hitCount, float maxRange)
{
	float fromPos[3], targetPos[3];
	GetClientAbsOrigin(fromTarget, fromPos);
	fromPos[2] += 30.0;
	
	int bestTarget = -1;
	float bestDistance = maxRange;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (GetClientTeam(i) == 2 || GetClientTeam(i) == 0)
			continue;
		
		// Check if already hit
		bool alreadyHit = false;
		for (int j = 0; j < hitCount; j++)
		{
			if (hitTargets[j] == i)
			{
				alreadyHit = true;
				break;
			}
		}
		if (alreadyHit)
			continue;
		
		GetClientAbsOrigin(i, targetPos);
		targetPos[2] += 30.0;
		
		float distance = GetVectorDistance(fromPos, targetPos);
		if (distance < bestDistance && distance <= maxRange)
		{
			bestTarget = i;
			bestDistance = distance;
		}
	}
	
	// Also check common infected
	int common = -1;
	while ((common = FindEntityByClassname(common, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(common))
			continue;
		
		GetEntPropVector(common, Prop_Send, "m_vecOrigin", targetPos);
		targetPos[2] += 30.0;
		
		float distance = GetVectorDistance(fromPos, targetPos);
		if (distance < bestDistance && distance <= maxRange)
		{
			bestTarget = common;
			bestDistance = distance;
		}
	}
	
	return bestTarget;
}

void CreateLightningBeam(float start[3], float end[3])
{
	TE_SetupBeamPoints(start, end, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.3, 2.0, 2.0, 5, 0.0, {100, 150, 255, 255}, 10);
	TE_SendToAll();
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	// Chain lightning can be triggered on weapon fire if configured
	return Plugin_Continue;
}

