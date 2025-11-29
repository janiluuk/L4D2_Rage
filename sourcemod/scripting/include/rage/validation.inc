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
 */
stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

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
 * Validates if a client is valid, in-game, alive, and on survivor team.
 * 
 * @param client    Client index to validate
 * @return          True if valid survivor, false otherwise
 */
stock bool IsValidSurvivor(int client)
{
    return IsValidAliveClient(client) && GetClientTeam(client) == 2;
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
