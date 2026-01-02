#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "Blink"
#define PLUGIN_NAME "[Rage] Blink Teleport"

#include <sourcemod>
#include <sdktools>
#include <rage/validation>
#include <rage/skills>
#include <rage/cooldown_notify>
#include <rage/effects>

#pragma semicolon 1
#pragma newdecls required

// Configuration
ConVar g_cvarEnable;
ConVar g_cvarDistance;
ConVar g_cvarCooldown;
ConVar g_cvarMaxDistance;
ConVar g_cvarRequireLOS;

// Rage system integration
int g_iClassID = -1;
bool g_bRageAvailable = false;
const int CLASS_ATHLETE = 2;

// Client tracking
float g_fNextUse[MAXPLAYERS+1] = {0.0, ...};
bool g_bHasAbility[MAXPLAYERS+1] = {false, ...};

// Visual effects
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Rage Team",
	description = "Athlete skill: Short range teleport (blink)",
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

	RegPluginLibrary("rage_survivor_blink");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("rage_blink_enable", "1", 
		"Enable Blink skill", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarDistance = CreateConVar("rage_blink_distance", "300.0", 
		"Default blink distance", FCVAR_NOTIFY, true, 50.0, true, 1000.0);
	g_cvarMaxDistance = CreateConVar("rage_blink_maxdistance", "500.0", 
		"Maximum blink distance", FCVAR_NOTIFY, true, 100.0, true, 2000.0);
	g_cvarCooldown = CreateConVar("rage_blink_cooldown", "8.0", 
		"Cooldown in seconds", FCVAR_NOTIFY, true, 1.0);
	g_cvarRequireLOS = CreateConVar("rage_blink_requirelos", "1", 
		"Require line of sight for blink", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "rage_blink");
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
	g_bHasAbility[client] = (newClass == CLASS_ATHLETE);
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

	if (!IsValidSurvivor(client, true))
	{
		PrintHintText(client, "Blink requires a valid survivor.");
		return 0;
	}

	if (!g_bHasAbility[client])
	{
		PrintHintText(client, "Blink is only available to Athletes.");
		return 0;
	}

	// Check cooldown
	float gameTime = GetGameTime();
	if (g_fNextUse[client] > gameTime)
	{
		float wait = g_fNextUse[client] - gameTime;
		PrintHintText(client, "Blink ready in %.1f seconds", wait);
		return 0;
	}

	// Perform blink
	if (PerformBlink(client))
	{
		g_fNextUse[client] = gameTime + g_cvarCooldown.FloatValue;
		CooldownNotify_Register(client, g_fNextUse[client], PLUGIN_SKILL_NAME);
		return 1;
	}
	
	return 0;
}

/**
 * Performs the blink teleport for a client.
 * Calculates destination, validates position, and teleports the player.
 * 
 * @param client   Client index
 * @return         True if blink succeeded, false otherwise
 */
bool PerformBlink(int client)
{
	float clientPos[3], clientAng[3], endPos[3];
	GetClientAbsOrigin(client, clientPos);
	GetClientEyeAngles(client, clientAng);
	
	float distance = g_cvarDistance.FloatValue;
	float maxDistance = g_cvarMaxDistance.FloatValue;
	
	// Calculate target position
	float direction[3];
	GetAngleVectors(clientAng, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	ScaleVector(direction, distance);
	AddVectors(clientPos, direction, endPos);
	
	// Trace to find valid position
	Handle trace = TR_TraceRayFilterEx(clientPos, clientAng, MASK_PLAYERSOLID, 
		RayType_Infinite, TraceFilter_Blink, client);
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		
		// Clamp to max distance
		float actualDistance = GetVectorDistance(clientPos, endPos);
		if (actualDistance > maxDistance)
		{
			float direction2[3];
			SubtractVectors(endPos, clientPos, direction2);
			NormalizeVector(direction2, direction2);
			ScaleVector(direction2, maxDistance);
			AddVectors(clientPos, direction2, endPos);
		}
		
		// Check if position is valid (not in solid)
		TR_TraceRayFilter(clientPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, 
			TraceFilter_Blink, client);
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(endPos, trace);
			// Move back slightly from wall to avoid getting stuck
			float direction3[3];
			SubtractVectors(clientPos, endPos, direction3);
			NormalizeVector(direction3, direction3);
			ScaleVector(direction3, 10.0);
			AddVectors(endPos, direction3, endPos);
		}
	}
	
	CloseHandle(trace);
	
	// Check line of sight if required
	if (g_cvarRequireLOS.BoolValue)
	{
		Handle losTrace = TR_TraceRayFilterEx(clientPos, endPos, MASK_PLAYERSOLID, 
			RayType_EndPoint, TraceFilter_Blink, client);
		if (TR_DidHit(losTrace))
		{
			CloseHandle(losTrace);
			PrintHintText(client, "Cannot blink - no line of sight!");
			return false;
		}
		CloseHandle(losTrace);
	}
	
	// Teleport player
	TeleportEntity(client, endPos, NULL_VECTOR, NULL_VECTOR);
	
	// Visual and audio effects
	CreateBlinkEffect(clientPos, endPos);
	EmitSoundToAll("ambient/atmosphere/teleport1.wav", client, SNDCHAN_AUTO, 
		SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	PrintHintText(client, "Blink!");
	return true;
}

/**
 * Trace filter for blink ray traces.
 * Excludes the blinking player and other players.
 */
public bool TraceFilter_Blink(int entity, int contentsMask, int client)
{
	return (entity != client && (entity <= 0 || entity > MaxClients));
}

/**
 * Creates visual effects for the blink ability.
 * Shows beam between start and end positions with glow sprites.
 * 
 * @param start   Start position (origin)
 * @param end     End position (destination)
 */
void CreateBlinkEffect(float start[3], float end[3])
{
	// Beam effect showing teleport path
	TE_SetupBeamPoints(start, end, g_iBeamSprite, g_iHaloSprite, 
		0, 15, 0.3, 3.0, 3.0, 5, 0.0, {100, 200, 255, 255}, 10);
	TE_SendToAll();
	
	// Glow sprites at start and end points
	TE_SetupGlowSprite(start, g_iHaloSprite, 0.5, 2.0, 200);
	TE_SendToAll();
	TE_SetupGlowSprite(end, g_iHaloSprite, 0.5, 2.0, 200);
	TE_SendToAll();
}

