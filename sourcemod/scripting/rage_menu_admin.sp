#define PLUGIN_VERSION "0.1"
#include <sourcemod>
#include <rage_menus/rage_menu_base>
#include <rage/validation>
#include <left4dhooks>

// Note: We use the native RagePerks_ShowMenu instead of including menus.inc
// to avoid circular dependency issues

#pragma semicolon 1
#pragma newdecls required

// Native function declarations for perks system
native bool RagePerks_IsAvailable();
native bool RagePerks_ShowMenu(int client, bool isComboList);

// Native function declarations for overlay system
native bool IsOverlayConnected();

bool g_bExtraMenuLoaded;
int g_iAdminMenuID;
int g_iPendingGrenadeType[MAXPLAYERS+1]; // Store pending grenade base type (1=Pipe, 2=Molotov, 3=Bile)
bool g_bOverlayAvailable;
bool g_bMusicAvailable;

public Plugin myinfo =
{
    name = "[Rage] Admin Menu",
    author = "Yani",
    description = "Provides admin specific menu options for Rage",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_adm", CmdRageAdminMenu, ADMFLAG_ROOT);
    
    // Initialize pending grenade type array
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPendingGrenadeType[i] = 0;
    }
    
    // Check if music plugin is available
    g_bMusicAvailable = LibraryExists("rage_music");
}

public void OnClientDisconnect(int client)
{
    g_iPendingGrenadeType[client] = 0;
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "rage_menu_base") == 0)
    {
        g_bExtraMenuLoaded = true;
        BuildAdminMenu();
    }
    else if (strcmp(name, "rage_overlay") == 0)
    {
        g_bOverlayAvailable = true;
        if (g_bExtraMenuLoaded)
        {
            BuildAdminMenu();
        }
    }
    else if (strcmp(name, "rage_music") == 0)
    {
        g_bMusicAvailable = true;
        if (g_bExtraMenuLoaded)
        {
            BuildAdminMenu();
        }
    }
}


public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "rage_menu_base") == 0)
    {
        DeleteAdminMenu();
        g_bExtraMenuLoaded = false;
    }
    else if (strcmp(name, "rage_overlay") == 0)
    {
        g_bOverlayAvailable = false;
        if (g_bExtraMenuLoaded)
        {
            BuildAdminMenu();
        }
    }
    else if (strcmp(name, "rage_music") == 0)
    {
        g_bMusicAvailable = false;
        if (g_bExtraMenuLoaded)
        {
            BuildAdminMenu();
        }
    }
}

public void OnPluginEnd()
{
    DeleteAdminMenu();
}

Action CmdRageAdminMenu(int client, int args)
{
    if (!IsValidClient(client) || !g_bExtraMenuLoaded || g_iAdminMenuID == 0)
    {
        return Plugin_Handled;
    }

    PrintHintText(client, "Use W/S to move and A/D to select options.");
    ExtraMenu_Display(client, g_iAdminMenuID, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public void ExtraMenu_OnSelect(int client, int menu_id, int option, int value)
{
    if (!IsValidClient(client) || menu_id != g_iAdminMenuID)
    {
        return;
    }

    // Menu option handling based on option index
    // Options are 1-indexed based on the menu creation order
    switch(option)
    {
        case 1: // Spawn Items
        {
            HandleSpawnItems(client, value);
        }
        case 2: // Reload options
        {
            HandleReloadOption(client, value);
        }
        case 3: // Manage skills
        {
            PrintToChat(client, "\x04[Admin]\x01 Skill management coming soon");
        }
        case 4: // Manage perks (only if perks system available)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleManagePerks(client);
            }
            else
            {
                // If perks not available, this might be "Apply effect" instead
                PrintToChat(client, "\x04[Admin]\x01 Effect application coming soon");
            }
        }
        case 5: // Apply effect (or Throw grenade if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                PrintToChat(client, "\x04[Admin]\x01 Effect application coming soon");
            }
            else
            {
                // If no perks, this becomes Throw grenade
                HandleThrowGrenade(client, value);
            }
        }
        case 6: // Throw grenade (or debug mode if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleThrowGrenade(client, value);
            }
            else
            {
                HandleDebugMode(client, value);
            }
        }
        case 7: // Debug mode (or Halt game if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleDebugMode(client, value);
            }
            else
            {
                HandleHaltGame(client, value);
            }
        }
        case 8: // Halt game (or Infected spawn if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleHaltGame(client, value);
            }
            else
            {
                HandleInfectedSpawn(client, value);
            }
        }
        case 9: // Infected spawn toggle (or God mode if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleInfectedSpawn(client, value);
            }
            else
            {
                HandleGodMode(client, value);
            }
        }
        case 10: // God mode toggle (or Remove weapons if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleGodMode(client, value);
            }
            else
            {
                HandleRemoveWeapons(client);
            }
        }
        case 11: // Remove weapons (or Game speed if no perks)
        {
            if (LibraryExists("rage_perks"))
            {
                HandleRemoveWeapons(client);
            }
            else
            {
                HandleGameSpeed(client, value);
            }
        }
        case 12: // Game speed
        {
            HandleGameSpeed(client, value);
        }
        case 13: // Overlay status or Music management
        {
            if (g_bOverlayAvailable)
            {
                HandleOverlayStatus(client);
            }
            else if (g_bMusicAvailable)
            {
                HandleMusicManagement(client, value);
            }
        }
        case 14: // Overlay actions or Music track selection
        {
            if (g_bOverlayAvailable)
            {
                HandleOverlayAction(client, value);
            }
            else if (g_bMusicAvailable)
            {
                HandleMusicTrackSelect(client, value);
            }
        }
        case 15: // Music management (only if overlay is available, otherwise handled in 13)
        {
            if (g_bMusicAvailable && g_bOverlayAvailable)
            {
                HandleMusicManagement(client, value);
            }
        }
        case 16: // Music track selection (only if overlay is available, otherwise handled in 14)
        {
            if (g_bMusicAvailable && g_bOverlayAvailable)
            {
                HandleMusicTrackSelect(client, value);
            }
        }
    }
}

void HandleManagePerks(int client)
{
    if (!LibraryExists("rage_perks"))
    {
        PrintToChat(client, "\x04[Admin]\x01 Perks system is not available.");
        return;
    }
    
    // Check if perks are enabled
    if (GetFeatureStatus(FeatureType_Native, "RagePerks_IsAvailable") == FeatureStatus_Available)
    {
        if (!RagePerks_IsAvailable())
        {
            PrintToChat(client, "\x04[Admin]\x01 Perks system is disabled.");
            return;
        }
    }
    
    // Use native to show menu if available
    if (GetFeatureStatus(FeatureType_Native, "RagePerks_ShowMenu") == FeatureStatus_Available)
    {
        RagePerks_ShowMenu(client, false);
    }
    #if defined _rage_perks_menus_included
    else
    {
        // Fallback: use menu function directly if include is available
        ShowPerkMenu(client, false);
    }
    #else
    else
    {
        // Final fallback: use command
        FakeClientCommand(client, "sm_perks_apply");
    }
    #endif
}

void HandleThrowGrenade(int client, int value)
{
    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "\x04[Admin]\x01 You must be alive to throw grenades.");
        return;
    }
    
    // Store the selected base grenade type
    g_iPendingGrenadeType[client] = value + 1; // 1=Pipe, 2=Molotov, 3=Bile
    
    // Give the player the selected grenade weapon
    char weaponClass[32];
    switch(value)
    {
        case 0: // Pipe Bomb
        {
            strcopy(weaponClass, sizeof(weaponClass), "weapon_pipe_bomb");
        }
        case 1: // Molotov
        {
            strcopy(weaponClass, sizeof(weaponClass), "weapon_molotov");
        }
        case 2: // Bile Jar (L4D2 only)
        {
            if (GetFeatureStatus(FeatureType_Native, "L4D2_VomitJarPrj") == FeatureStatus_Available)
            {
                strcopy(weaponClass, sizeof(weaponClass), "weapon_vomitjar");
            }
            else
            {
                PrintToChat(client, "\x04[Admin]\x01 Bile jar not available (L4D2 only).");
                return;
            }
        }
        default:
        {
            PrintToChat(client, "\x04[Admin]\x01 Invalid grenade type.");
            return;
        }
    }
    
    // Remove existing grenade if any
    int existingGrenade = GetPlayerWeaponSlot(client, 2);
    if (existingGrenade > MaxClients && IsValidEntity(existingGrenade))
    {
        RemovePlayerItem(client, existingGrenade);
        RemoveEntity(existingGrenade);
    }
    
    // Give the new grenade weapon
    int weapon = GivePlayerItem(client, weaponClass);
    if (weapon > MaxClients && IsValidEntity(weapon))
    {
        EquipPlayerWeapon(client, weapon);
        
        // Show the grenades plugin menu after a short delay to ensure weapon is equipped
        CreateTimer(0.2, Timer_ShowGrenadeMenu, GetClientUserId(client));
        
        char grenadeName[32];
        switch(value)
        {
            case 0: strcopy(grenadeName, sizeof(grenadeName), "Pipe Bomb");
            case 1: strcopy(grenadeName, sizeof(grenadeName), "Molotov");
            case 2: strcopy(grenadeName, sizeof(grenadeName), "Bile Jar");
        }
        PrintToChat(client, "\x04[Admin]\x01 Equipped %s. Select grenade type from menu...", grenadeName);
        LogAction(client, -1, "\"%L\" equipped %s via admin menu", client, grenadeName);
    }
    else
    {
        PrintToChat(client, "\x04[Admin]\x01 Failed to give grenade weapon.");
        g_iPendingGrenadeType[client] = 0;
    }
}

public Action Timer_ShowGrenadeMenu(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return Plugin_Stop;
    }
    
    // Check if grenades plugin command is available
    if (GetCommandFlags("sm_grenade") != INVALID_FCVAR_FLAGS)
    {
        // Use the grenades plugin's menu system
        FakeClientCommand(client, "sm_grenade");
    }
    else
    {
        PrintToChat(client, "\x04[Admin]\x01 Grenades plugin not available. Use the grenade normally.");
    }
    
    return Plugin_Stop;
}

void HandleSpawnItems(int client, int value)
{
    switch(value)
    {
        case 0: PrintToChat(client, "\x04[Admin]\x01 Cabinet spawn not yet implemented");
        case 1: PrintToChat(client, "\x04[Admin]\x01 Weapon spawn not yet implemented");
        case 2: PrintToChat(client, "\x04[Admin]\x01 Special Infected spawn not yet implemented");
        case 3: PrintToChat(client, "\x04[Admin]\x01 Tank spawn not yet implemented");
    }
}

void HandleReloadOption(int client, int value)
{
    char mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    
    switch(value)
    {
        case 0:
        {
            PrintToChat(client, "\x04[Admin]\x01 Reloading map...");
            ForceChangeLevel(mapname, "Map reloaded by admin");
        }
        case 1, 2:  // Both reload all plugins (SourceMod doesn't support wildcard reload)
        {
            char message[64];
            Format(message, sizeof(message), "\x04[Admin]\x01 Reloading %s plugins...", 
                   (value == 1) ? "Rage" : "all");
            PrintToChat(client, message);
            ServerCommand("sm plugins reload");
        }
        case 3:
        {
            PrintToChat(client, "\x04[Admin]\x01 Restarting server...");
            ServerCommand("_restart");
        }
    }
}

void HandleDebugMode(int client, int value)
{
    // Explicitly sized array for clarity - 4 debug modes
    char modes[4][] = {"Off", "Log to file", "Log to chat", "Tracelog"};
    if(value >= 0 && value < sizeof(modes))
    {
        PrintToChat(client, "\x04[Admin]\x01 Debug mode: %s", modes[value]);
        // TODO: Actually set debug mode when debug system is implemented
    }
}

void HandleHaltGame(int client, int value)
{
    switch(value)
    {
        case 0: PrintToChat(client, "\x04[Admin]\x01 Game speed normal");
        case 1: PrintToChat(client, "\x04[Admin]\x01 Halting survivors only (not yet implemented)");
        case 2: PrintToChat(client, "\x04[Admin]\x01 Halting all players (not yet implemented)");
    }
}

void HandleInfectedSpawn(int client, int value)
{
    PrintToChat(client, "\x04[Admin]\x01 Infected spawn: %s", value ? "Enabled" : "Disabled");
    // TODO: Implement infected spawn control
}

void HandleGodMode(int client, int value)
{
    PrintToChat(client, "\x04[Admin]\x01 God mode: %s", value ? "Enabled" : "Disabled");
    // TODO: Implement god mode toggle
}

void HandleRemoveWeapons(int client)
{
    PrintToChat(client, "\x04[Admin]\x01 Removing all weapons from map...");
    // TODO: Implement weapon removal
}

void HandleGameSpeed(int client, int value)
{
    float speed = 0.1 + (value * 0.1); // 0.1 to 1.0 based on slider position
    PrintToChat(client, "\x04[Admin]\x01 Game speed set to %.1f", speed);
    ServerCommand("host_timescale %.2f", speed);
}

void BuildAdminMenu()
{
    DeleteAdminMenu();

    g_iAdminMenuID = ExtraMenu_Create();

    ExtraMenu_AddEntry(g_iAdminMenuID, "ADMIN MENU:", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "Use W/S to move row and A/D to select", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);

    ExtraMenu_AddEntry(g_iAdminMenuID, "1. Spawn Items: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "New cabinet|New weapon|Special Infected|Special tank");
    ExtraMenu_AddEntry(g_iAdminMenuID, "2. Reload _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Map|Rage Plugins|All plugins|Restart server");
    ExtraMenu_AddEntry(g_iAdminMenuID, "3. Manage skills", MENU_SELECT_ONLY, true);
    
    // Only show perks entry if perks system is available
    bool perksAvailable = LibraryExists("rage_perks");
    if (perksAvailable)
    {
        ExtraMenu_AddEntry(g_iAdminMenuID, "4. Manage perks", MENU_SELECT_ONLY, true);
        ExtraMenu_AddEntry(g_iAdminMenuID, "5. Apply effect on player", MENU_SELECT_ONLY, true);
        ExtraMenu_AddEntry(g_iAdminMenuID, "6. Throw grenade: _OPT_", MENU_SELECT_LIST);
        ExtraMenu_AddOptions(g_iAdminMenuID, "Pipe Bomb|Molotov|Bile Jar");
    }
    else
    {
        ExtraMenu_AddEntry(g_iAdminMenuID, "4. Apply effect on player", MENU_SELECT_ONLY, true);
        ExtraMenu_AddEntry(g_iAdminMenuID, "5. Throw grenade: _OPT_", MENU_SELECT_LIST);
        ExtraMenu_AddOptions(g_iAdminMenuID, "Pipe Bomb|Molotov|Bile Jar");
    }

    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "DEBUG COMMANDS:", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "7. Debug mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Off|Log to file|Log to chat|Tracelog to chat");
    ExtraMenu_AddEntry(g_iAdminMenuID, "8. Halt game: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Off|Only survivors|All");
    ExtraMenu_AddEntry(g_iAdminMenuID, "9. Infected spawn: _OPT_", MENU_SELECT_ONOFF, false, 1);
    ExtraMenu_AddEntry(g_iAdminMenuID, "10. God mode: _OPT_", MENU_SELECT_ONOFF, false, 1);
    ExtraMenu_AddEntry(g_iAdminMenuID, "11. Remove weapons from map", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "12. Game speed: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");
    
    // Overlay system entry (if available)
    g_bOverlayAvailable = LibraryExists("rage_overlay");
    if (g_bOverlayAvailable)
    {
        ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
        ExtraMenu_AddEntry(g_iAdminMenuID, "OVERLAY SYSTEM:", MENU_ENTRY);
        ExtraMenu_AddEntry(g_iAdminMenuID, "13. Overlay status", MENU_SELECT_ONLY, true);
        ExtraMenu_AddEntry(g_iAdminMenuID, "14. Overlay: _OPT_", MENU_SELECT_LIST);
        ExtraMenu_AddOptions(g_iAdminMenuID, "Info|Send Players|Test|Trigger Login|Connect");
    }
    
    // Music management entry (if music plugin is available)
    g_bMusicAvailable = LibraryExists("rage_music");
    if (g_bMusicAvailable)
    {
        ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
        ExtraMenu_AddEntry(g_iAdminMenuID, "MUSIC MANAGEMENT:", MENU_ENTRY);
        
        // Calculate option number: 12 (game speed) + 1 = 13, then overlay takes 13-14 if available
        int musicOptionNum = 13;
        if (g_bOverlayAvailable) 
        {
            musicOptionNum = 15; // Overlay takes 13-14
        }
        
        char musicOption[64];
        Format(musicOption, sizeof(musicOption), "%d. Music: _OPT_", musicOptionNum);
        ExtraMenu_AddEntry(g_iAdminMenuID, musicOption, MENU_SELECT_LIST);
        ExtraMenu_AddOptions(g_iAdminMenuID, "List tracks|Current track|Reload list|Play/Pause|Next track");
        
        Format(musicOption, sizeof(musicOption), "%d. Select track: _OPT_", musicOptionNum + 1);
        ExtraMenu_AddEntry(g_iAdminMenuID, musicOption, MENU_SELECT_LIST);
        // Build track list dynamically
        BuildMusicTrackOptions();
    }
    
    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
}

void DeleteAdminMenu()
{
    if (g_iAdminMenuID != 0 && LibraryExists("rage_menu_base"))
    {
        ExtraMenu_Delete(g_iAdminMenuID);
        g_iAdminMenuID = 0;
    }
    else if (g_iAdminMenuID != 0)
    {
        g_iAdminMenuID = 0;
    }
}

void HandleOverlayStatus(int client)
{
    if (!LibraryExists("rage_overlay"))
    {
        PrintToChat(client, "\x04[Admin]\x01 Overlay system is not available.");
        return;
    }
    
    if (GetFeatureStatus(FeatureType_Native, "IsOverlayConnected") == FeatureStatus_Available)
    {
        bool connected = IsOverlayConnected();
        PrintToChat(client, "\x04[Overlay]\x01 Status: %s", connected ? "Connected" : "Disconnected");
        PrintToChat(client, "\x04[Overlay]\x01 Use 'sm_overlay info' for detailed status");
    }
    else
    {
        PrintToChat(client, "\x04[Overlay]\x01 System loaded but native not available");
    }
}

void HandleOverlayAction(int client, int value)
{
    if (!LibraryExists("rage_overlay"))
    {
        PrintToChat(client, "\x04[Admin]\x01 Overlay system is not available.");
        return;
    }
    
    char command[64];
    switch(value)
    {
        case 0: strcopy(command, sizeof(command), "info");
        case 1: strcopy(command, sizeof(command), "players");
        case 2: strcopy(command, sizeof(command), "test");
        case 3: strcopy(command, sizeof(command), "trigger_login");
        case 4: strcopy(command, sizeof(command), "connect");
        default: return;
    }
    
    FakeClientCommand(client, "sm_overlay %s", command);
}

void BuildMusicTrackOptions()
{
    if (!g_bMusicAvailable)
    {
        ExtraMenu_AddOptions(g_iAdminMenuID, "Music plugin not loaded");
        return;
    }
    
    // Read music list from file to build menu options
    char listPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, listPath, sizeof(listPath), "data/music_mapstart.txt");
    
    File hFile = OpenFile(listPath, "r");
    if (hFile == null)
    {
        ExtraMenu_AddOptions(g_iAdminMenuID, "No music list found");
        return;
    }
    
    char trackOptions[1024] = "";
    char sLine[PLATFORM_MAX_PATH];
    int trackCount = 0;
    int maxTracks = 15; // Limit menu size
    
    while (!hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)) && trackCount < maxTracks)
    {
        TrimString(sLine);
        
        // Skip comments and empty lines
        if (sLine[0] == '/' && sLine[1] == '/')
            continue;
        if (strlen(sLine) == 0)
            continue;
        
        // Extract display name (after "TAG-")
        char displayName[64];
        int tagPos = StrContains(sLine, "TAG-", false);
        if (tagPos != -1)
        {
            strcopy(displayName, sizeof(displayName), sLine[tagPos + 5]);
            TrimString(displayName);
        }
        else
        {
            // Use filename as fallback
            char fileName[64];
            GetFileBasename(sLine, fileName, sizeof(fileName));
            strcopy(displayName, sizeof(displayName), fileName);
        }
        
        // Truncate long names
        if (strlen(displayName) > 20)
        {
            displayName[20] = '\0';
            StrCat(displayName, sizeof(displayName), "...");
        }
        
        if (trackCount > 0)
            StrCat(trackOptions, sizeof(trackOptions), "|");
        
        StrCat(trackOptions, sizeof(trackOptions), displayName);
        trackCount++;
    }
    
    CloseHandle(hFile);
    
    if (strlen(trackOptions) > 0)
    {
        ExtraMenu_AddOptions(g_iAdminMenuID, trackOptions);
    }
    else
    {
        ExtraMenu_AddOptions(g_iAdminMenuID, "No tracks available");
    }
}

stock void GetFileBasename(const char[] path, char[] basename, int maxlen)
{
    int len = strlen(path);
    int lastSlash = -1;
    int lastDot = -1;
    
    for (int i = len - 1; i >= 0; i--)
    {
        if (path[i] == '/' || path[i] == '\\')
        {
            lastSlash = i;
            break;
        }
        if (lastDot == -1 && path[i] == '.')
        {
            lastDot = i;
        }
    }
    
    int start = (lastSlash != -1) ? lastSlash + 1 : 0;
    int end = (lastDot != -1) ? lastDot : len;
    int copyLen = end - start;
    
    if (copyLen > maxlen - 1)
        copyLen = maxlen - 1;
    
    strcopy(basename, maxlen, path[start]);
    if (lastDot != -1 && copyLen < maxlen)
        basename[copyLen] = '\0';
}

void HandleMusicManagement(int client, int value)
{
    if (!g_bMusicAvailable)
    {
        PrintToChat(client, "\x04[Admin]\x01 Music plugin is not available.");
        return;
    }
    
    switch(value)
    {
        case 0: // List tracks
        {
            FakeClientCommand(client, "sm_music");
            PrintToChat(client, "\x04[Admin]\x01 Opening music menu...");
        }
        case 1: // Current track
        {
            FakeClientCommand(client, "sm_music_current");
        }
        case 2: // Reload list
        {
            FakeClientCommand(client, "sm_music_update");
            PrintToChat(client, "\x04[Admin]\x01 Music list reloaded. Menu will update on next build.");
            // Rebuild menu to refresh track list
            CreateTimer(1.0, Timer_RebuildAdminMenu);
        }
        case 3: // Play/Pause
        {
            // Toggle play/pause
            FakeClientCommand(client, "sm_music_play");
            PrintToChat(client, "\x04[Admin]\x01 Toggling music playback...");
        }
        case 4: // Next track
        {
            FakeClientCommand(client, "sm_music_next");
            PrintToChat(client, "\x04[Admin]\x01 Skipping to next track...");
        }
    }
}

void HandleMusicTrackSelect(int client, int value)
{
    if (!g_bMusicAvailable)
    {
        PrintToChat(client, "\x04[Admin]\x01 Music plugin is not available.");
        return;
    }
    
    // Play specific track by index
    char command[64];
    Format(command, sizeof(command), "sm_music %d", value);
    FakeClientCommand(client, command);
    PrintToChat(client, "\x04[Admin]\x01 Playing track %d...", value + 1);
}

Action Timer_RebuildAdminMenu(Handle timer)
{
    if (g_bExtraMenuLoaded)
    {
        BuildAdminMenu();
    }
    return Plugin_Stop;
}