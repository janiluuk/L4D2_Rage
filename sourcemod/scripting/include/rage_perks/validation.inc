// Validation and testing utilities for perks system

#if defined _PERKS_VALIDATION_INC_
 #endinput
#endif
#define _PERKS_VALIDATION_INC_

/**
 * Validates a perk index is within bounds and valid
 * @param index The perk index to validate
 * @return true if valid, false otherwise
 */
bool ValidatePerkIndex(int index) {
    if(index < 0 || index > MAX_PERKS) {
        return false;
    }
    if(Perks[index].id != index) {
        return false;
    }
    if(Perks[index].name[0] == '\0') {
        return false;
    }
    return true;
}

/**
 * Validates a client index is valid and in-game
 * @param client The client index to validate
 * @return true if valid, false otherwise
 */
bool ValidatePerkClient(int client) {
    if(client <= 0 || client > MaxClients) {
        return false;
    }
    if(!IsClientInGame(client)) {
        return false;
    }
    return true;
}

/**
 * Validates flags are within the valid range for a perk
 * @param flags The flags to validate
 * @param perk The perk to validate against
 * @return true if valid, false otherwise
 */
bool ValidatePerkFlags(int flags, Perk perk) {
    // If perk has no flags, only 0 is valid
    if(perk.flagNames == null || perk.flagNames.Length == 0) {
        return flags == 0;
    }
    
    // Check if flags exceed available flag bits
    int maxFlagBit = perk.flagNames.Length;
    if(maxFlagBit > 32) maxFlagBit = 32; // Safety limit
    
    // Create mask for valid flags
    int maxFlagValue = (1 << maxFlagBit) - 1;
    
    // Check if any bits beyond valid range are set
    return (flags & ~maxFlagValue) == 0;
}

/**
 * Validates a perk name exists
 * @param name The perk name to check
 * @return true if exists, false otherwise
 */
bool ValidatePerkName(const char[] name) {
    if(name[0] == '\0') {
        return false;
    }
    int index = GetPerkID(name);
    return index >= 0 && ValidatePerkIndex(index);
}

/**
 * Test function to validate perk system integrity
 * Call this during plugin load or via admin command
 * @param client The client to report results to (0 = server console)
 */
void RunPerkSystemValidation(int client = 0) {
    int errors = 0;
    int warnings = 0;
    
    // Test 1: Validate all registered perks
    for(int i = 0; i <= MAX_PERKS; i++) {
        if(Perks[i].name[0] != '\0') {
            if(!ValidatePerkIndex(i)) {
                errors++;
                if(client > 0) {
                    PrintToChat(client, "[TEST] ERROR: Perk at index %d has invalid ID", i);
                } else {
                    PrintToServer("[TEST] ERROR: Perk at index %d has invalid ID", i);
                }
            }
            
            // Check for duplicate names
            int foundCount = 0;
            for(int j = 0; j <= MAX_PERKS; j++) {
                if(i != j && StrEqual(Perks[i].name, Perks[j].name)) {
                    foundCount++;
                }
            }
            if(foundCount > 0) {
                warnings++;
                if(client > 0) {
                    PrintToChat(client, "[TEST] WARNING: Perk \"%s\" appears %d times", Perks[i].name, foundCount + 1);
                } else {
                    PrintToServer("[TEST] WARNING: Perk \"%s\" appears %d times", Perks[i].name, foundCount + 1);
                }
            }
            
            // Validate modifiers
            if(Perks[i].mods == 0) {
                errors++;
                if(client > 0) {
                    PrintToChat(client, "[TEST] ERROR: Perk \"%s\" has no modifiers", Perks[i].name);
                } else {
                    PrintToServer("[TEST] ERROR: Perk \"%s\" has no modifiers", Perks[i].name);
                }
            }
        }
    }
    
    // Test 2: Validate perk KV mapping
    int kvCount = 0;
    StringMapSnapshot snapshot = perkKV.Snapshot();
    for(int i = 0; i < snapshot.Length; i++) {
        int keyLen = snapshot.KeyBufferSize(i);
        char[] key = new char[keyLen];
        snapshot.GetKey(i, key, keyLen);
        
        int value;
        if(perkKV.GetValue(key, value)) {
            kvCount++;
            if(!ValidatePerkIndex(value)) {
                errors++;
                if(client > 0) {
                    PrintToChat(client, "[TEST] ERROR: KV maps \"%s\" to invalid index %d", key, value);
                } else {
                    PrintToServer("[TEST] ERROR: KV maps \"%s\" to invalid index %d", key, value);
                }
            }
        }
    }
    delete snapshot;
    
    // Test 3: Validate combos
    if(combos != null) {
        for(int i = 0; i < combos.Length; i++) {
            PerkCombo combo;
            combos.GetArray(i, combo, sizeof(combo));
            
            if(combo.name[0] == '\0') {
                warnings++;
                if(client > 0) {
                    PrintToChat(client, "[TEST] WARNING: Combo at index %d has no name", i);
                } else {
                    PrintToServer("[TEST] WARNING: Combo at index %d has no name", i);
                }
            }
            
            if(combo.perks == null || combo.perks.Length == 0) {
                warnings++;
                if(client > 0) {
                    PrintToChat(client, "[TEST] WARNING: Combo \"%s\" has no perks", combo.name);
                } else {
                    PrintToServer("[TEST] WARNING: Combo \"%s\" has no perks", combo.name);
                }
            } else {
                for(int j = 0; j < combo.perks.Length; j++) {
                    SpecifiedPerk specPerk;
                    combo.perks.GetArray(j, specPerk, sizeof(specPerk));
                    
                    if(!ValidatePerkIndex(specPerk.id)) {
                        errors++;
                        if(client > 0) {
                            PrintToChat(client, "[TEST] ERROR: Combo \"%s\" contains invalid perk ID %d", combo.name, specPerk.id);
                        } else {
                            PrintToServer("[TEST] ERROR: Combo \"%s\" contains invalid perk ID %d", combo.name, specPerk.id);
                        }
                    } else {
                        if(!ValidatePerkFlags(specPerk.flags, Perks[specPerk.id])) {
                            warnings++;
                            if(client > 0) {
                                PrintToChat(client, "[TEST] WARNING: Combo \"%s\" perk \"%s\" has invalid flags %d", combo.name, Perks[specPerk.id].name, specPerk.flags);
                            } else {
                                PrintToServer("[TEST] WARNING: Combo \"%s\" perk \"%s\" has invalid flags %d", combo.name, Perks[specPerk.id].name, specPerk.flags);
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Report results
    if(client > 0) {
        PrintToChat(client, "[TEST] Validation complete: %d errors, %d warnings", errors, warnings);
    } else {
        PrintToServer("[TEST] Validation complete: %d errors, %d warnings", errors, warnings);
    }
}

/**
 * Test perk activation/deactivation cycle
 * @param client The client to test on
 * @param perkName The perk name to test
 * @return true if test passed, false otherwise
 */
bool TestPerkActivation(int client, const char[] perkName) {
    if(!ValidatePerkClient(client)) {
        return false;
    }
    
    if(!ValidatePerkName(perkName)) {
        return false;
    }
    
    // Test activation
    int perkID = GetPerkID(perkName);
    bool wasActive = Perks[perkID].IsActive(client);
    
    ApplyPerk(client, perkName, 0, PerkMod_Constant, 0, true);
    
    bool isActive = Perks[perkID].IsActive(client);
    
    // Should toggle state
    if(wasActive == isActive) {
        return false;
    }
    
    // Test deactivation
    ApplyPerk(client, perkName, 0, PerkMod_Constant, 0, true);
    bool isActiveAfter = Perks[perkID].IsActive(client);
    
    // Should be back to original state
    if(wasActive != isActiveAfter) {
        return false;
    }
    
    return true;
}

