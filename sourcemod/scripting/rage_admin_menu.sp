#define PLUGIN_VERSION "0.1"
#include <sourcemod>
#include <extra_menu>
#include <rage/validation>

#pragma semicolon 1
#pragma newdecls required

bool g_bExtraMenuLoaded;
int g_iAdminMenuID;

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
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = true;
        BuildAdminMenu();
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "extra_menu") == 0)
    {
        DeleteAdminMenu();
        g_bExtraMenuLoaded = false;
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
        case 4: // Spawn Items
        {
            HandleSpawnItems(client, value);
        }
        case 5: // Reload options
        {
            HandleReloadOption(client, value);
        }
        case 6: // Manage skills
        {
            PrintToChat(client, "\x04[Admin]\x01 Skill management coming soon");
        }
        case 7: // Manage perks
        {
            PrintToChat(client, "\x04[Admin]\x01 Perk management coming soon");
        }
        case 8: // Apply effect
        {
            PrintToChat(client, "\x04[Admin]\x01 Effect application coming soon");
        }
        case 11: // Debug mode
        {
            HandleDebugMode(client, value);
        }
        case 12: // Halt game
        {
            HandleHaltGame(client, value);
        }
        case 13: // Infected spawn toggle
        {
            HandleInfectedSpawn(client, value);
        }
        case 14: // God mode toggle
        {
            HandleGodMode(client, value);
        }
        case 15: // Remove weapons
        {
            HandleRemoveWeapons(client);
        }
        case 16: // Game speed
        {
            HandleGameSpeed(client, value);
        }
    }
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
        case 1:
        {
            PrintToChat(client, "\x04[Admin]\x01 Reloading Rage plugins...");
            // Reload all plugins - SourceMod doesn't support wildcard reloading
            ServerCommand("sm plugins reload");
        }
        case 2:
        {
            PrintToChat(client, "\x04[Admin]\x01 Reloading all plugins...");
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
    ExtraMenu_AddEntry(g_iAdminMenuID, "4. Manage perks", MENU_SELECT_ONLY, true);
    ExtraMenu_AddEntry(g_iAdminMenuID, "5. Apply effect on player", MENU_SELECT_ONLY, true);

    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "DEBUG COMMANDS:", MENU_ENTRY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "1. Debug mode: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Off|Log to file|Log to chat|Tracelog to chat");
    ExtraMenu_AddEntry(g_iAdminMenuID, "2. Halt game: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "Off|Only survivors|All");
    ExtraMenu_AddEntry(g_iAdminMenuID, "3. Infected spawn: _OPT_", MENU_SELECT_ONOFF, false, 1);
    ExtraMenu_AddEntry(g_iAdminMenuID, "4. God mode: _OPT_", MENU_SELECT_ONOFF, false, 1);
    ExtraMenu_AddEntry(g_iAdminMenuID, "5. Remove weapons from map", MENU_SELECT_ONLY);
    ExtraMenu_AddEntry(g_iAdminMenuID, "6. Game speed: _OPT_", MENU_SELECT_LIST);
    ExtraMenu_AddOptions(g_iAdminMenuID, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");
    ExtraMenu_AddEntry(g_iAdminMenuID, " ", MENU_ENTRY);
}

void DeleteAdminMenu()
{
    if (g_iAdminMenuID != 0 && LibraryExists("extra_menu"))
    {
        ExtraMenu_Delete(g_iAdminMenuID);
        g_iAdminMenuID = 0;
    }
    else if (g_iAdminMenuID != 0)
    {
        g_iAdminMenuID = 0;
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}