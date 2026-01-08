/**
 * rage/skill_plugin_base.inc
 * 
 * Base template for Rage skill plugins to reduce boilerplate code.
 * This include provides common structure and utilities that all skill plugins need.
 */

#if defined _rage_skill_plugin_base_included
  #endinput
#endif
#define _rage_skill_plugin_base_included

#include <sourcemod>
#include <sdktools>
#include <rage/validation>
#include <rage/skills>
#include <rage/cooldown_notify>

/**
 * Macro to define skill plugin globals with standard naming.
 * Usage: RAGE_SKILL_PLUGIN_GLOBALS("SkillName", CLASS_TYPE_ID)
 */
#define RAGE_SKILL_PLUGIN_GLOBALS(%1,%2) \
	int g_iClassID = -1; \
	bool g_bRageAvailable = false; \
	const int TARGET_CLASS = %2; \
	bool g_bHasAbility[MAXPLAYERS+1] = {false, ...}; \
	const char SKILL_NAME[] = %1

/**
 * Macro to implement standard AskPluginLoad2 for skill plugins.
 * Usage: RAGE_SKILL_PLUGIN_LOAD("library_name")
 */
#define RAGE_SKILL_PLUGIN_LOAD(%1) \
	public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) \
	{ \
		if(GetEngineVersion() != Engine_Left4Dead2) \
		{ \
			strcopy(error, err_max, "Plugin only supports Left 4 Dead 2"); \
			return APLRes_SilentFailure; \
		} \
		RegPluginLibrary(%1); \
		RageSkills_MarkNativesOptional(); \
		return APLRes_Success; \
	}

/**
 * Macro to implement standard Rage system callbacks.
 * Usage: RAGE_SKILL_PLUGIN_CALLBACKS("SkillName")
 */
#define RAGE_SKILL_PLUGIN_CALLBACKS(%1) \
	public void OnAllPluginsLoaded() \
	{ \
		RageSkills_Refresh(%1, 0, g_iClassID, g_bRageAvailable); \
	} \
	public void OnLibraryAdded(const char[] name) \
	{ \
		RageSkills_OnLibraryAdded(name, %1, 0, g_iClassID, g_bRageAvailable); \
	} \
	public void OnLibraryRemoved(const char[] name) \
	{ \
		if (StrEqual(name, RAGE_PLUGIN_NAME, false)) \
		{ \
			g_iClassID = -1; \
		} \
		RageSkills_OnLibraryRemoved(name, g_bRageAvailable); \
	} \
	public void Rage_OnPluginState(char[] plugin, int state) \
	{ \
		if (!StrEqual(plugin, RAGE_PLUGIN_NAME, false)) \
			return; \
		if (state == 1) \
		{ \
			g_bRageAvailable = true; \
			if (g_iClassID == -1) \
			{ \
				g_iClassID = RegisterRageSkill(%1, 0); \
			} \
		} \
		else if (state == 0) \
		{ \
			g_bRageAvailable = false; \
			g_iClassID = -1; \
		} \
	} \
	public int OnPlayerClassChange(int client, int newClass, int previousClass) \
	{ \
		g_bHasAbility[client] = (newClass == TARGET_CLASS); \
		return g_bHasAbility[client] ? 1 : 0; \
	}

/**
 * Standard cooldown management for skills.
 * Checks if skill is on cooldown and displays remaining time to client.
 * 
 * @param client       Client index
 * @param nextUse      Next use time for this client
 * @param skillName    Name of skill for display
 * @return             True if ready to use, false if on cooldown
 */
stock bool Rage_CheckSkillCooldown(int client, float nextUse, const char[] skillName)
{
	float gameTime = GetGameTime();
	if (nextUse > gameTime)
	{
		float wait = nextUse - gameTime;
		PrintHintText(client, "%s ready in %.1f seconds", skillName, wait);
		return false;
	}
	return true;
}

/**
 * Standard skill validation checks before activation.
 * Validates client, Rage availability, skill name match, and ability status.
 * 
 * @param client       Client index
 * @param skillName    Expected skill name
 * @param hasAbility   Whether client has this ability
 * @return             True if all checks pass, false otherwise
 */
stock bool Rage_ValidateSkillUse(int client, const char[] skillName, bool hasAbility)
{
	if (!g_bRageAvailable)
		return false;

	char clientSkillName[32];
	GetPlayerSkillName(client, clientSkillName, sizeof(clientSkillName));
	
	if (!StrEqual(clientSkillName, skillName))
		return false;

	if (!IsValidSurvivor(client, true))
		return false;

	if (!hasAbility)
		return false;

	return true;
}

/**
 * Reset client cooldowns for all players.
 * Useful in OnMapStart.
 * 
 * @param cooldownArray   Array of cooldown times (must be size MAXPLAYERS+1)
 */
stock void Rage_ResetClientCooldowns(float[] cooldownArray)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		cooldownArray[i] = 0.0;
	}
}

/**
 * Initialize client data on connect.
 * 
 * @param client          Client index
 * @param cooldownArray   Array of cooldown times
 * @param hasAbility      Array tracking ability ownership
 */
stock void Rage_InitClientData(int client, float[] cooldownArray, bool[] hasAbility)
{
	cooldownArray[client] = 0.0;
	hasAbility[client] = false;
}
