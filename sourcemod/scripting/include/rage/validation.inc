/**
 * rage/validation.inc
 * 
 * Shared validation and utility functions for L4D2 Rage Edition plugins.
 * Consolidates common client validation, team checks, and entity utilities
 * to reduce code duplication across plugins.
 */

#if defined _rage_validation_included
  #endinput
#endif
#define _rage_validation_included

/**
 * Validates if a client index is valid and in-game.
 * 
 * @param client    Client index to validate
 * @return          True if valid client in-game, false otherwise
 * 
 * Note: jutils.inc also defines IsValidClient with a different signature.
 * We only define our version if jutils.inc is not included.
 */
#if !defined _jutils_included
stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
#endif

/**
 * Validates if a client is valid, in-game, and alive.
 * 
 * @param client    Client index to validate
 * @return          True if valid client in-game and alive, false otherwise
 */
stock bool IsValidAliveClient(int client)
{
    return IsValidClient(client) && IsPlayerAlive(client);
}

/**
 * Validates if a client is valid, in-game, and on survivor team.
 * Optionally checks if the client is alive.
 * 
 * @param client    Client index to validate
 * @param isAlive   If true, also requires client to be alive (default: true)
 * @return          True if valid survivor, false otherwise
 */
stock bool IsValidSurvivor(int client, bool isAlive = true)
{
    if (isAlive)
    {
        return IsValidAliveClient(client) && GetClientTeam(client) == 2;
    }
    else
    {
        return IsValidClient(client) && GetClientTeam(client) == 2;
    }
}

/**
 * Checks if a client is on the survivor team (does not require alive status).
 * This is a simpler check than IsValidSurvivor which also requires the client to be alive.
 * 
 * @param client    Client index to check
 * @return          True if client is on survivor team, false otherwise
 */
stock bool IsSurvivor(int client)
{
    if (!IsValidClient(client))
        return false;
    
    return (GetClientTeam(client) == 2);
}

/**
 * Validates if a client is valid, in-game, alive, and on infected team.
 * 
 * @param client    Client index to validate
 * @return          True if valid infected, false otherwise
 */
stock bool IsValidInfected(int client)
{
    return IsValidAliveClient(client) && GetClientTeam(client) == 3;
}

/**
 * Checks if a player is in ghost mode (infected spawning).
 * 
 * @param client    Client index to check
 * @return          True if player is ghost, false otherwise
 */
stock bool IsPlayerGhost(int client)
{
    if (!IsValidClient(client))
        return false;
    
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

/**
 * Checks if a player is incapacitated.
 * 
 * @param client    Client index to check
 * @return          True if player is incapacitated, false otherwise
 */
stock bool IsPlayerIncapped(int client)
{
    if (!IsValidAliveClient(client))
        return false;
    
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

/**
 * Checks if a player is hanging from a ledge.
 * 
 * @param client    Client index to check
 * @return          True if player is hanging, false otherwise
 */
stock bool IsPlayerHanging(int client)
{
    if (!IsValidAliveClient(client))
        return false;
    
    return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1);
}

/**
 * Checks if a client has admin access with the specified flag.
 * 
 * @param client    Client index to check
 * @param flag      Admin flag to check (default: ADMFLAG_ROOT)
 * @return          True if client has admin access, false otherwise
 */
stock bool IsClientValidAdmin(int client, AdminFlag flag = view_as<AdminFlag>(ADMFLAG_ROOT))
{
    if (!IsValidClient(client))
        return false;
    
    if (IsFakeClient(client))
        return false;
    
    AdminId admin = GetUserAdmin(client);
    if (admin == INVALID_ADMIN_ID)
        return false;
    
    return GetAdminFlag(admin, flag);
}

/**
 * Checks if an entity index is valid. Note that this only verifies the
 * entity slot is valid, not that the entity actually exists in the world.
 * Use IsValidEntityEx() if you need to verify the entity exists.
 * 
 * @param entity    Entity index to validate
 * @return          True if entity slot is valid, false otherwise
 */
stock bool IsValidEntityIndex(int entity)
{
    return (entity > 0 && IsValidEdict(entity));
}

/**
 * Checks if an entity is valid and actually exists in the world.
 * This is a stricter check than IsValidEntityIndex.
 * 
 * @param entity    Entity index to validate
 * @return          True if entity exists, false otherwise
 */
stock bool IsValidEntityEx(int entity)
{
    if (entity <= 0 || !IsValidEdict(entity))
        return false;
    
    // Verify the entity actually exists by checking if we can get its classname
    // GetEdictClassname returns number of bytes written, > 0 means valid
    char classname[64];
    int result = GetEdictClassname(entity, classname, sizeof(classname));
    return (result > 0);
}

/**
 * Gets a player's name safely.
 * 
 * @param client    Client index
 * @param buffer    Buffer to store name
 * @param maxlen    Maximum length of buffer
 * @return          True if name retrieved, false otherwise
 */
stock bool GetClientNameSafe(int client, char[] buffer, int maxlen)
{
    if (!IsValidClient(client))
    {
        buffer[0] = '\0';
        return false;
    }
    
    GetClientName(client, buffer, maxlen);
    return true;
}

/**
 * Gets the survivor character model for a client.
 * 
 * @param client    Client index
 * @return          Character index (0-7) or -1 if not survivor
 */
stock int GetSurvivorCharacter(int client)
{
    if (!IsValidClient(client) || GetClientTeam(client) != 2)
        return -1;
    
    return GetEntProp(client, Prop_Send, "m_survivorCharacter");
}

/**
 * Gets the zombie class for an infected player.
 * 
 * @param client    Client index
 * @return          Zombie class index or 0 if not infected
 */
stock int GetInfectedClass(int client)
{
    if (!IsValidInfected(client))
        return 0;
    
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

/**
 * Checks if a player has any items pinning them (Smoker tongue, Charger pummel, etc).
 * 
 * @param client    Client index
 * @return          True if player is pinned, false otherwise
 */
stock bool IsPlayerPinned(int client)
{
    if (!IsValidAliveClient(client))
        return false;
    
    // Check for various pin states
    if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0) return true;
    if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) return true;
    if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) return true;
    if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) return true;
    if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0) return true;
    
    return false;
}

/**
 * Checks if coordinates are within a radius of another point.
 * 
 * @param pos1      First position
 * @param pos2      Second position
 * @param radius    Radius to check
 * @return          True if within radius, false otherwise
 */
stock bool IsWithinRadius(const float pos1[3], const float pos2[3], float radius)
{
    return (GetVectorDistance(pos1, pos2) <= radius);
}

/**
 * Safely kills a timer handle and sets it to null.
 * Prevents memory leaks and double-kill errors.
 * 
 * @param timer     Timer handle to kill (passed by reference)
 * @return          True if timer was killed, false if already null/invalid
 */
stock bool KillTimerSafe(Handle &timer)
{
    if (timer != null && timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = null;
        return true;
    }
    return false;
}

/**
 * Cleans up an array of timer handles for a client.
 * Useful in OnClientDisconnect to prevent memory leaks.
 * 
 * @param timers    Array of timer handles
 * @param client    Client index
 * @param size      Size of the timer array
 * @return          Number of timers cleaned up
 */
stock int CleanupClientTimers(Handle[] timers, int client, int size = MAXPLAYERS+1)
{
    if (client <= 0 || client >= size)
        return 0;
    
    int cleaned = 0;
    if (KillTimerSafe(timers[client]))
    {
        cleaned++;
    }
    return cleaned;
}

/**
 * Validates an entity index is within safe bounds for array access.
 * 
 * @param entity    Entity index to validate
 * @param maxLimit  Maximum allowed entity index (default: 2048)
 * @return          True if entity is within bounds, false otherwise
 */
stock bool IsValidEntityIndexSafe(int entity, int maxLimit = 2048)
{
    return (entity > 0 && entity <= maxLimit && IsValidEdict(entity));
}

/**
 * Validates array bounds before access.
 * 
 * @param index     Array index to check
 * @param arraySize Size of the array
 * @return          True if index is valid, false otherwise
 */
stock bool IsValidArrayIndex(int index, int arraySize)
{
    return (index >= 0 && index < arraySize);
}

/**
 * Gets a client's active weapon entity.
 * 
 * @param client    Client index
 * @return          Entity index of active weapon, or -1 if invalid
 */
stock int GetClientActiveWeapon(int client)
{
    if (!IsValidClient(client))
        return -1;
    
    return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

/**
 * Resets an array to a default value for all client indices.
 * Useful in OnMapEnd/OnClientDisconnect cleanup.
 * 
 * @param array     Array to reset (must be declared with [MAXPLAYERS+1] or similar)
 * @param value     Value to set (default: 0)
 * @param size      Size of array (default: MAXPLAYERS+1)
 */
stock void ResetClientArray(int array[], int value = 0, int size = MAXPLAYERS+1)
{
    for (int i = 0; i < size; i++)
    {
        array[i] = value;
    }
}

/**
 * Resets a float array to a default value for all client indices.
 * 
 * @param array     Array to reset (must be declared with [MAXPLAYERS+1] or similar)
 * @param value     Value to set (default: 0.0)
 * @param size      Size of array (default: MAXPLAYERS+1)
 */
stock void ResetClientArrayFloat(float array[], float value = 0.0, int size = MAXPLAYERS+1)
{
    for (int i = 0; i < size; i++)
    {
        array[i] = value;
    }
}

/**
 * Resets a bool array to a default value for all client indices.
 * 
 * @param array     Array to reset (must be declared with [MAXPLAYERS+1] or similar)
 * @param value     Value to set (default: false)
 * @param size      Size of array (default: MAXPLAYERS+1)
 */
stock void ResetClientArrayBool(bool array[], bool value = false, int size = MAXPLAYERS+1)
{
    for (int i = 0; i < size; i++)
    {
        array[i] = value;
    }
}
