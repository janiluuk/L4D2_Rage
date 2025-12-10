#if defined _rage_common_included
 #endinput
#endif
#define _rage_common_included

/**
 * Common constants shared across Rage plugins to reduce duplication
 */

// Common explosion sound effects used across multiple plugins
#define SOUND_EXPLODE3		"weapons/hegrenade/explode3.wav"
#define SOUND_EXPLODE4		"weapons/hegrenade/explode4.wav"
#define SOUND_EXPLODE5		"weapons/hegrenade/explode5.wav"

// Special Infected type constants (for plugins that need them)
// Note: For team constants, plugins should include <left4dhooks> and use the L4D2_Team enum
#define SI_SMOKER 	1
#define SI_BOOMER 	2
#define SI_HUNTER 	3
#define SI_SPITTER  4
#define SI_JOCKEY 	5
#define SI_CHARGER  6
#define SI_TANK 	7

/**
 * Common utility functions shared across Rage plugins
 */

/**
 * Trace filter function for ray traces - excludes players
 * 
 * @param entity			Entity being tested
 * @param contentsMask		Contents mask
 * @param client			Client index (passed as filter data, optional)
 * @return					True if entity should be hit, false to skip
 */
stock bool TraceFilter(int entity, int contentsMask, any client = 0)
{
	if (entity <= MaxClients)
		return false;
	return true;
}

/**
 * Finds the nearest entity of the specified classname to the given client
 * 
 * @param client		Client index to find nearest entity relative to
 * @param classname		Entity classname to search for
 * @return				Entity index of nearest entity, or -1 if none found or invalid client
 */
stock int GetNearestEntity(int client, char[] classname)
{
	if (client <= 0 || client > MaxClients)
		return -1;
		
	int nearestEntity = -1;
	float clientVecOrigin[3], entityVecOrigin[3];
	GetClientAbsOrigin(client, clientVecOrigin);
	
	//Get the distance between the first entity and client
	float distance, nearestDistance = -1.0;
	
	//Find all the entity and compare the distances
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVecOrigin);
		distance = GetVectorDistance(clientVecOrigin, entityVecOrigin, true);
		
		if (distance < nearestDistance || nearestDistance == -1.0)
		{
			nearestEntity = entity;
			nearestDistance = distance;
		}
	}
	return nearestEntity;
}

/**
 * Runs L4D2 VScript code
 * 
 * @param sCode		VScript code to execute (supports format specifiers)
 * @param ...		Variable arguments for formatting
 */
stock void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		DispatchSpawn(iScriptLogic);
	}
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}
