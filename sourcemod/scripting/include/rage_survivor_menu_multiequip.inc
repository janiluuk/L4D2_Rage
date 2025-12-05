#if defined _RAGE_SURVIVOR_MENU_MULTIEQUIP_INC_
 #endinput
#endif
#define _RAGE_SURVIVOR_MENU_MULTIEQUIP_INC_

// Native declaration for multi-equipment sync
native void MultiEquip_SyncFromCookie(int client);

enum MultiEquipMode
{
    ME_Off = 0,
    ME_SingleTap,
    ME_DoubleTap
};

bool g_bMultiEquipEnabled[MAXPLAYERS + 1];
MultiEquipMode g_MultiEquipMode[MAXPLAYERS + 1];
int g_iEquipmentTapCount[MAXPLAYERS + 1];
int g_iLastEquipmentWeapon[MAXPLAYERS + 1];
float g_fLastEquipmentTapTime[MAXPLAYERS + 1];
Handle g_hMultiEquipCookie = INVALID_HANDLE;

void MultiEquip_OnPluginStart()
{
    g_hMultiEquipCookie = RegClientCookie("rage_multiequip_mode", "Rage multiple equipment mode preference", CookieAccess_Public);
}

void MultiEquip_OnClientPutInServer(int client)
{
    g_bMultiEquipEnabled[client] = false;
    g_MultiEquipMode[client] = ME_Off;
    g_iEquipmentTapCount[client] = 0;
    g_iLastEquipmentWeapon[client] = -1;
    g_fLastEquipmentTapTime[client] = 0.0;
}

void MultiEquip_OnClientDisconnect(int client)
{
    g_bMultiEquipEnabled[client] = false;
    g_MultiEquipMode[client] = ME_Off;
    g_iEquipmentTapCount[client] = 0;
    g_iLastEquipmentWeapon[client] = -1;
    g_fLastEquipmentTapTime[client] = 0.0;
}

void MultiEquip_OnCookiesCached(int client)
{
    if (g_hMultiEquipCookie == INVALID_HANDLE || !IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    char buffer[8];
    GetClientCookie(client, g_hMultiEquipCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0')
    {
        g_MultiEquipMode[client] = view_as<MultiEquipMode>(StringToInt(buffer));
    }
    else
    {
        g_MultiEquipMode[client] = ME_Off;
    }

    MultiEquip_Apply(client);
}

void MultiEquip_SetMode(int client, MultiEquipMode mode)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        return;
    }

    g_MultiEquipMode[client] = mode;
    MultiEquip_Apply(client);

    if (g_hMultiEquipCookie != INVALID_HANDLE)
    {
        char buffer[8];
        IntToString(view_as<int>(mode), buffer, sizeof(buffer));
        SetClientCookie(client, g_hMultiEquipCookie, buffer);
    }
    
    // Sync the plugin's ControlMode immediately if the plugin is loaded
    // The native will be called directly if available
    if (GetFeatureStatus(FeatureType_Native, "MultiEquip_SyncFromCookie") == FeatureStatus_Available)
    {
        MultiEquip_SyncFromCookie(client);
    }
}

void MultiEquip_Apply(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        return;
    }

    // Enable/disable based on mode
    if (g_MultiEquipMode[client] == ME_Off)
    {
        g_bMultiEquipEnabled[client] = false;
        // Unhook if previously hooked
        SDKUnhook(client, SDKHook_WeaponCanUse, MultiEquip_OnWeaponCanUse);
        // Show notification that mode is off
        PrintHintText(client, "Equipment mode: Off");
    }
    else
    {
        g_bMultiEquipEnabled[client] = true;
        // Hook weapon pickup
        SDKHook(client, SDKHook_WeaponCanUse, MultiEquip_OnWeaponCanUse);
        
        // Show hint text summarizing the mode
        if (g_MultiEquipMode[client] == ME_SingleTap)
        {
            PrintHintText(client, "Equipment mode: Single Tap");
        }
        else if (g_MultiEquipMode[client] == ME_DoubleTap)
        {
            PrintHintText(client, "Equipment mode: Double Tap");
        }
    }

    // Reset tap tracking
    g_iEquipmentTapCount[client] = 0;
    g_iLastEquipmentWeapon[client] = -1;
    g_fLastEquipmentTapTime[client] = 0.0;
}

public Action MultiEquip_OnWeaponCanUse(int client, int weapon)
{
    if (!g_bMultiEquipEnabled[client] || g_MultiEquipMode[client] == ME_Off)
    {
        return Plugin_Continue;
    }

    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return Plugin_Continue;
    }

    if (weapon <= 0 || !IsValidEntity(weapon))
    {
        return Plugin_Continue;
    }

    // Only apply to equipment items (slot 3 = throwables, slot 4 = medkits/pills)
    char weaponClass[64];
    GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));

    // Check if this is an equipment item
    bool isEquipment = false;
    if (StrContains(weaponClass, "weapon_pipe_bomb") != -1 ||
        StrContains(weaponClass, "weapon_molotov") != -1 ||
        StrContains(weaponClass, "weapon_vomitjar") != -1 ||
        StrContains(weaponClass, "weapon_first_aid_kit") != -1 ||
        StrContains(weaponClass, "weapon_pain_pills") != -1 ||
        StrContains(weaponClass, "weapon_adrenaline") != -1 ||
        StrContains(weaponClass, "weapon_defibrillator") != -1)
    {
        isEquipment = true;
    }

    if (!isEquipment)
    {
        return Plugin_Continue; // Not equipment, allow normal pickup
    }

    // Check if this is the same weapon as last tap
    float currentTime = GetGameTime();
    bool isSameWeapon = (g_iLastEquipmentWeapon[client] == weapon);
    bool tapExpired = (currentTime - g_fLastEquipmentTapTime[client] > 1.0); // 1 second timeout

    if (!isSameWeapon || tapExpired)
    {
        // New weapon or timeout - reset tap count
        g_iEquipmentTapCount[client] = 1; // Start counting from 1 (this is the first tap)
        g_iLastEquipmentWeapon[client] = weapon;
        g_fLastEquipmentTapTime[client] = currentTime;
    }
    else
    {
        // Same weapon, increment tap count
        g_iEquipmentTapCount[client]++;
        g_fLastEquipmentTapTime[client] = currentTime;
    }

    // Check if enough taps
    int requiredTaps = (g_MultiEquipMode[client] == ME_SingleTap) ? 1 : 2;

    if (g_iEquipmentTapCount[client] < requiredTaps)
    {
        // Not enough taps yet - block pickup and show hint
        int remainingTaps = requiredTaps - g_iEquipmentTapCount[client];
        if (remainingTaps == 1)
        {
            PrintHintText(client, "Tap USE once more");
        }
        else
        {
            PrintHintText(client, "Tap USE %d more times", remainingTaps);
        }
        return Plugin_Handled; // Block the pickup
    }

    // Enough taps - allow pickup and reset
    g_iEquipmentTapCount[client] = 0;
    g_iLastEquipmentWeapon[client] = -1;
    g_fLastEquipmentTapTime[client] = 0.0;
    return Plugin_Continue; // Allow pickup
}

MultiEquipMode MultiEquip_GetMode(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return ME_Off;
    }
    
    // Return the mode stored in cookie (synced with actual plugin)
    return g_MultiEquipMode[client];
}

bool MultiEquip_IsEnabled(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return false;
    }
    return g_bMultiEquipEnabled[client] && g_MultiEquipMode[client] != ME_Off;
}

