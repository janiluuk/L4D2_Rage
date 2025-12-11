// Helper functions and macros for perks system optimization

#if defined _PERKS_HELPERS_INC_
 #endinput
#endif
#define _PERKS_HELPERS_INC_

/**
 * Gets perk ID with lazy initialization and validation
 * Use this instead of static int + GetPerkID pattern
 * @param perkName The name of the perk
 * @param cachedID Static variable to cache the ID (initialize to 0)
 * @return Perk index, or -1 if not found
 */
int GetPerkIDCached(const char[] perkName, int &cachedID) {
    if(cachedID == 0) {
        cachedID = GetPerkID(perkName);
        if(cachedID < 0) {
            LogError("[Perks] Perk \"%s\" not found during lazy initialization", perkName);
        }
    }
    return cachedID;
}

/**
 * Gets perk ID with validation - returns -1 if invalid
 * @param perkName The name of the perk
 * @return Valid perk index, or -1 if not found
 */
int GetPerkIDSafe(const char[] perkName) {
    int id = GetPerkID(perkName);
    if(id < 0 || id > MAX_PERKS) {
        return -1;
    }
    if(Perks[id].id != id || Perks[id].name[0] == '\0') {
        return -1;
    }
    return id;
}

/**
 * Calculates chance based on flag pattern (1.0, 0.5, 0.1)
 * Common pattern: flag & 2 = 0.5, flag & 4 = 0.1, else 1.0
 * @param flags The flags value
 * @return Chance value (1.0, 0.5, or 0.1)
 */
float GetFlagChance(int flags) {
    if(flags & 2) return PERK_CHANCE_MEDIUM;
    if(flags & 4) return PERK_CHANCE_LOW;
    return PERK_CHANCE_DEFAULT;
}

/**
 * Validates client is valid and in-game
 * @param client Client index
 * @return true if valid, false otherwise
 */
bool IsValidPerkClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

/**
 * Gets flag name for a single flag (power of 2)
 * @param perk The perk struct
 * @param flags The flags value (must be power of 2)
 * @param buffer Buffer to store flag name
 * @param maxlength Maximum buffer length
 * @return true if flag name found, false otherwise
 */
bool GetSingleFlagName(Perk perk, int flags, char[] buffer, int maxlength) {
    if(flags <= 0 || (flags & (flags - 1)) != 0) {
        return false; // Not a power of 2
    }
    int index = GetIndexFromPower(flags);
    if(index < 0) {
        return false;
    }
    return perk.GetFlagName(index, buffer, maxlength);
}

/**
 * Formats perk activation message with flag information
 * @param perk The perk struct
 * @param flags The flags value
 * @param flagName Buffer to store flag name (will be modified)
 * @param flagNameLen Length of flagName buffer
 * @param hasFlagName Output: true if flag name was found
 */
void FormatPerkFlagName(Perk perk, int flags, char[] flagName, int flagNameLen, bool &hasFlagName) {
    flagName[0] = '\0';
    hasFlagName = false;
    
    if(flags <= 0) {
        return;
    }
    
    // Check if single flag (power of 2)
    if((flags & (flags - 1)) == 0) {
        hasFlagName = GetSingleFlagName(perk, flags, flagName, flagNameLen);
        return;
    }
    
    // Multiple flags - try to get first flag name
    for(int i = 0; i < 32; i++) {
        if(flags & (1 << i)) {
            if(perk.GetFlagName(i, flagName, flagNameLen)) {
                hasFlagName = true;
            }
            // Only show name if exactly one flag, otherwise show number
            if((flags & ~(1 << i)) != 0) {
                flagName[0] = '\0';
                hasFlagName = false;
            }
            break;
        }
    }
}

