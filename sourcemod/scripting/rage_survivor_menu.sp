
#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <admin>
#include <clientprefs>
#include <rage_menu_base>
#include <rage_survivor_guide>
#include <l4d2hud>
#include <rage/hud>

#define GAMEMODE_OPTION_COUNT 11
#define CLASS_OPTION_COUNT 7
#define MENU_OPTION_EXIT -1
#define MENU_OPTION_BACK_ON_FIRST_PAGE -2

static const char g_sGameModeNames[GAMEMODE_OPTION_COUNT][] =
{
    "Versus",
    "Competitive",
    "Escort run",
    "Deathmatch",
    "Race Jockey",
    "Team Versus",
    "Scavenge",
    "Team Scavenge",
    "Survival",
    "Co-op",
    "Realism"
};

static const char g_sGameModeCvarNames[GAMEMODE_OPTION_COUNT][] =
{
    "rage_gamemode_versus",
    "rage_gamemode_competitive",
    "rage_gamemode_escort",
    "rage_gamemode_deathmatch",
    "rage_gamemode_racejockey",
    "rage_gamemode_teamversus",
    "rage_gamemode_scavenge",
    "rage_gamemode_teamscavenge",
    "rage_gamemode_survival",
    "rage_gamemode_coop",
    "rage_gamemode_realism"
};

static const char g_sGameModeDefaults[GAMEMODE_OPTION_COUNT][] =
{
    "versus",
    "rage_competitive",
    "rage_escortrun",
    "rage_deathmatch",
    "rage_racejockey",
    "teamversus",
    "scavenge",
    "teamscavenge",
    "survival",
    "coop",
    "realism"
};

static const char g_sGameModeDescriptions[GAMEMODE_OPTION_COUNT][] =
{
    "mp_gamemode value for standard Versus.",
    "mp_gamemode value for competitive Versus.",
    "mp_gamemode value for escort run mode.",
    "mp_gamemode value for deathmatch mode.",
    "mp_gamemode value for race jockey mode.",
    "mp_gamemode value for team-based Versus.",
    "mp_gamemode value for standard Scavenge.",
    "mp_gamemode value for team-based Scavenge.",
    "mp_gamemode value for Survival.",
    "mp_gamemode value for Co-op.",
    "mp_gamemode value for Realism."
};

static const char g_sClassOptions[CLASS_OPTION_COUNT][] =
{
    "Soldier",
    "Athlete",
    "Medic",
    "Saboteur",
    "Commando",
    "Engineer",
    "Brawler"
};

#pragma semicolon 1
#pragma newdecls required

int g_iMenuIDSurvivor;
int g_iMenuIDInfected;
int g_iGuideOptionIndexSurvivor = -1;
int g_iGuideOptionIndexInfected = -1;
bool g_bGuideNativeAvailable = false;
bool g_bExtraMenuLoaded = false;
bool g_bMenuHeld[MAXPLAYERS + 1];
int g_iKitsUsed[MAXPLAYERS + 1];
bool g_bHudEnabled = true;
bool g_bThirdPersonPluginAvailable = false;
ArrayList g_hMenuOptionsSurvivor = null;
ArrayList g_hMenuOptionsInfected = null;

enum ThirdPersonMode
{
    TP_Off = 0,
    TP_MeleeOnly,
    TP_Always
};

ThirdPersonMode g_ThirdPersonMode[MAXPLAYERS + 1];
bool g_ThirdPersonActive[MAXPLAYERS + 1];
Handle g_hThirdPersonCookie = INVALID_HANDLE;

ConVar g_hCvarMPGameMode;
ConVar g_hGameModeCvars[GAMEMODE_OPTION_COUNT];
ConVar g_hKitSlots;
ConVar g_hDefaultMenuKey;
Handle g_hMenuKeyCookie = INVALID_HANDLE;

enum RageMenuOption
{
    Menu_GetKit = 0,
    Menu_SetAway,
    Menu_SelectTeam,
    Menu_ChangeClass,
    Menu_DeployAction,
    Menu_ViewRank,
    Menu_VoteCustomMap,
    Menu_VoteGameMode,
    Menu_ThirdPerson,
    Menu_MultiEquip,
    Menu_HudToggle,
    Menu_MusicToggle,
    Menu_MusicVolume,
    Menu_SpawnItems,
    Menu_Reload,
    Menu_ManageSkills,
    Menu_ManagePerks,
    Menu_ApplyEffect,
    Menu_DebugMode,
    Menu_HaltGame,
    Menu_InfectedSpawn,
    Menu_GodMode,
    Menu_RemoveWeapons,
    Menu_GameSpeed,
    Menu_Guide
};

void AddGameModeOptions(int menu_id);
void AddClassOptions(int menu_id);
void RefreshGuideLibraryStatus();
bool TryShowGuideMenu(int client);
bool DisplayRageMenu(int client, bool showHint);
bool HasRageMenuAccess(int client);
void ApplyThirdPersonMode(int client);
void PersistThirdPersonMode(int client);
void SetThirdPersonActive(int client, bool enable);
bool IsMeleeWeapon(int weapon);
void SetHudEnabled(bool enabled, int activator);
bool IsValidKeyString(const char[] key);
void SyncMenuSelections(int client, int menuId, ArrayList optionMap);
void SyncMenuSelection(int client, int menuId, ArrayList optionMap, RageMenuOption option, int value);
public void OnKitSlotsChanged(ConVar convar, const char[] oldValue, const char[] newValue);

// ====================================================================================================
//					PLUGIN INFO
// ====================================================================================================
public Plugin myinfo =
{
    name = "[Rage] Game Menu",
    author = "Yani",
    description = "Contains guide / game control menus for Rage",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_rage", CmdRageMenu, "Open the Rage game menu");
    RegConsoleCmd("sm_guide", CmdRageGuideMenu, "Open the Rage tutorial guide");
    RegConsoleCmd("sm_rage_bind", CmdRageMenuBind, "Show instructions to bind the Rage menu to a key");
    RegConsoleCmd("+rage_menu", CmdRageMenuHoldStart, "Hold to open Rage menu");
    RegConsoleCmd("-rage_menu", CmdRageMenuHoldEnd, "Release to close Rage menu");
    AddCommandListener(Command_QuickRageMenu, "voice_menu_2");
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    g_hCvarMPGameMode = FindConVar("mp_gamemode");

    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        g_hGameModeCvars[i] = CreateConVar(g_sGameModeCvarNames[i], g_sGameModeDefaults[i], g_sGameModeDescriptions[i], FCVAR_NONE);
    }

    g_hThirdPersonCookie = RegClientCookie("rage_tp_mode", "Rage third person preference", CookieAccess_Public);
    g_hMenuKeyCookie = RegClientCookie("rage_menu_key_bound", "Rage menu key auto-bind status", CookieAccess_Private);

    g_hKitSlots = CreateConVar("rage_menu_kit_slots", "1", "How many kits a player can request from the Rage menu per life.");
    g_hKitSlots.AddChangeHook(OnKitSlotsChanged);

    g_hDefaultMenuKey = CreateConVar("rage_menu_default_key", "v", "Default key to bind the Rage menu to. Set to empty string to disable auto-binding.", FCVAR_NONE);
    AutoExecConfig(true, "rage_survivor_menu");

    g_bThirdPersonPluginAvailable = true; // Bundled third-person helper plugin is shipped alongside this menu.

    g_bExtraMenuLoaded = LibraryExists("rage_menu_base") || LibraryExists("extra_menu");
    if (g_bExtraMenuLoaded)
    {
        if (LibraryExists("rage_menu_base"))
        {
            OnLibraryAdded("rage_menu_base");
        }
        else
        {
            OnLibraryAdded("extra_menu");
        }
    }

    // Note: HUD initialization is delayed until OnMapStart to avoid entity creation before map is running
    g_bHudEnabled = true;

    RefreshGuideLibraryStatus();
}

public void OnAllPluginsLoaded()
{
    RefreshGuideLibraryStatus();
}

public void OnMapStart()
{
    // Initialize HUD now that a map is running
    if (g_bHudEnabled)
    {
        hudPosition currentPos = view_as<hudPosition>(getCurrentHud());
        if (currentPos < HUD_POSITION_FAR_LEFT || currentPos > HUD_POSITION_SCORE_4)
        {
            currentPos = HUD_POSITION_MID_TOP;
        }

        SetupMessageHud(currentPos, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS);
    }
}

public void OnClientPutInServer(int client)
{
    g_bMenuHeld[client] = false;
    g_ThirdPersonActive[client] = false;
    g_ThirdPersonMode[client] = TP_Off;
    g_iKitsUsed[client] = 0;
    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect(int client)
{
    g_bMenuHeld[client] = false;
    g_ThirdPersonActive[client] = false;
    g_ThirdPersonMode[client] = TP_Off;
    g_iKitsUsed[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) || !g_bExtraMenuLoaded)
    {
        return Plugin_Continue;
    }

    bool holdingShift = (buttons & IN_SPEED) != 0;

    if (holdingShift)
    {
        if (!g_bMenuHeld[client])
        {
            StartRageMenuHold(client);
        }
    }
    else if (g_bMenuHeld[client])
    {
        StopRageMenuHold(client);
    }

    return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }
    
    // Handle third person cookie
    if (g_hThirdPersonCookie != INVALID_HANDLE)
    {
        char buffer[8];
        GetClientCookie(client, g_hThirdPersonCookie, buffer, sizeof(buffer));
        if (buffer[0] != '\0')
        {
            g_ThirdPersonMode[client] = view_as<ThirdPersonMode>(StringToInt(buffer));
        }
        ApplyThirdPersonMode(client);
    }
    
    // Auto-bind menu key if not already done
    if (g_hMenuKeyCookie != INVALID_HANDLE && g_hDefaultMenuKey != null)
    {
        char boundStatus[8];
        GetClientCookie(client, g_hMenuKeyCookie, boundStatus, sizeof(boundStatus));
        
        // If cookie is empty or "0", the key hasn't been bound yet
        if (boundStatus[0] == '\0' || StringToInt(boundStatus) == 0)
        {
            char defaultKey[32];
            g_hDefaultMenuKey.GetString(defaultKey, sizeof(defaultKey));
            
            // Only bind if a default key is configured and valid
            if (defaultKey[0] != '\0' && IsValidKeyString(defaultKey))
            {
                // Execute bind command for the client
                ClientCommand(client, "bind %s +rage_menu", defaultKey);
                
                // Mark as bound in cookie
                SetClientCookie(client, g_hMenuKeyCookie, "1");
                
                // Notify the player
                CreateTimer(2.0, Timer_NotifyMenuKey, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public void OnKitSlotsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == null)
    {
        return;
    }

    if (convar.IntValue < 0)
    {
        convar.SetInt(0);
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    g_iKitsUsed[client] = 0;
    ApplyThirdPersonMode(client);
}

public Action OnWeaponSwitchPost(int client, int weapon)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    ApplyThirdPersonMode(client);
    return Plugin_Continue;
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "rage_menu_base") == 0 || strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = true;
        BuildRageMenus();
    }

    if (strcmp(name, "rage_survivor_guide") == 0)
    {
        RefreshGuideLibraryStatus();
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "rage_menu_base") == 0 || strcmp(name, "extra_menu") == 0)
    {
        g_bExtraMenuLoaded = false;
        OnPluginEnd();
    }

    if (strcmp(name, "rage_survivor_guide") == 0)
    {
        RefreshGuideLibraryStatus();
    }
}

public void OnPluginEnd()
{
    if (g_iMenuIDSurvivor != 0)
    {
        ExtraMenu_Delete(g_iMenuIDSurvivor);
        g_iMenuIDSurvivor = 0;
    }

    if (g_iMenuIDInfected != 0)
    {
        ExtraMenu_Delete(g_iMenuIDInfected);
        g_iMenuIDInfected = 0;
    }

    if (g_hMenuOptionsSurvivor != null)
    {
        delete g_hMenuOptionsSurvivor;
        g_hMenuOptionsSurvivor = null;
    }

    if (g_hMenuOptionsInfected != null)
    {
        delete g_hMenuOptionsInfected;
        g_hMenuOptionsInfected = null;
    }
}

Action CmdRageMenu(int client, int args)
{
    DisplayRageMenu(client, true);
    return Plugin_Handled;
}

Action CmdRageGuideMenu(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        PrintToServer("[Rage] This command can only be used in-game.");
        return Plugin_Handled;
    }

    if (!TryShowGuideMenu(client))
    {
        PrintToChat(client, "[Rage] Tutorial plugin is not available right now.");
    }

    return Plugin_Handled;
}

Action CmdRageMenuBind(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        PrintToServer("[Rage] This command can only be used in-game.");
        return Plugin_Handled;
    }

    PrintToChat(client, "\x04[Rage]\x01 To bind the menu to a key, open your console and type:");
    PrintToChat(client, "\x03bind <key> +rage_menu");
    PrintToChat(client, "\x01Example: \x03bind v +rage_menu");
    PrintToChat(client, "\x01Suggested keys: \x03v, g, k, mouse4, mouse5");
    PrintToChat(client, "\x01Hold the key to open menu, release to close.");

    return Plugin_Handled;
}

Action CmdRageMenuHoldStart(int client, int args)
{
    StartRageMenuHold(client);
    return Plugin_Handled;
}

Action CmdRageMenuHoldEnd(int client, int args)
{
    StopRageMenuHold(client);
    return Plugin_Handled;
}

Action Command_QuickRageMenu(int client, const char[] command, int argc)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    DisplayRageMenu(client, true);
    return Plugin_Handled;
}

void StartRageMenuHold(int client)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    if (g_bMenuHeld[client])
    {
        return;
    }

    if (DisplayRageMenu(client, false))
    {
        g_bMenuHeld[client] = true;
    }
}

void StopRageMenuHold(int client)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    if (g_bMenuHeld[client])
    {
        ExtraMenu_Close(client);
        g_bMenuHeld[client] = false;
    }
}

public void RageMenu_OnSelect(int client, int menu_id, int option, int value)
{
    ArrayList map = null;
    int guideIndex = -1;

    if (menu_id == g_iMenuIDSurvivor)
    {
        map = g_hMenuOptionsSurvivor;
        guideIndex = g_iGuideOptionIndexSurvivor;
    }
    else if (menu_id == g_iMenuIDInfected)
    {
        map = g_hMenuOptionsInfected;
        guideIndex = g_iGuideOptionIndexInfected;
    }

    // Handle special menu actions
    if (option == MENU_OPTION_EXIT)
    {
        // Exit button pressed - just close the menu gracefully
        g_bMenuHeld[client] = false;
        return;
    }
    else if (option == MENU_OPTION_BACK_ON_FIRST_PAGE)
    {
        // Back button pressed on first page - close the menu
        g_bMenuHeld[client] = false;
        return;
    }

    if (map == null || option < 0 || option >= map.Length)
    {
        return;
    }

    RageMenuOption menuOption = view_as<RageMenuOption>(map.Get(option));

    if (option == guideIndex && guideIndex != -1)
    {
        if (!TryShowGuideMenu(client))
        {
            PrintToChat(client, "[Rage] Tutorial plugin is not available right now.");
        }
        return;
    }

    bool adminSelection = (menuOption >= Menu_SpawnItems && menuOption <= Menu_GameSpeed);
    if (adminSelection && !CheckCommandAccess(client, "sm_rage_admin", ADMFLAG_ROOT))
    {
        PrintHintText(client, "Admin-only option.");
        return;
    }

    if (menuOption == Menu_GetKit)
    {
        int maxKits = (g_hKitSlots != null) ? g_hKitSlots.IntValue : 1;
        if (maxKits <= 0 || g_iKitsUsed[client] >= maxKits)
        {
            PrintHintText(client, "out of kits");
            return;
        }

        g_iKitsUsed[client]++;
        FakeClientCommand(client, "sm_kit");

        int kitsRemaining = maxKits - g_iKitsUsed[client];
        if (kitsRemaining < 0)
        {
            kitsRemaining = 0;
        }

        PrintHintText(client, "Kit delivered (%d remaining).", kitsRemaining);
        return;
    }
    else if (menuOption == Menu_SetAway)
    {
        PrintHintText(client, "Away mode is not available here.");
        return;
    }
    else if (menuOption == Menu_SelectTeam)
    {
        PrintHintText(client, "Team selection is not available in this menu.");
        return;
    }
    else if (menuOption == Menu_ChangeClass)
    {
        if (value < 0 || value >= CLASS_OPTION_COUNT)
        {
            PrintHintText(client, "Choose a class with left/right to apply it.");
            return;
        }

        int classIndex = value + 1; // class options skip the NONE slot
        FakeClientCommand(client, "sm_class_set %d", classIndex);
        PrintHintText(client, "Switching to %s", g_sClassOptions[value]);
        return;
    }
    else if (menuOption == Menu_DeployAction)
    {
        FakeClientCommand(client, "deployment_action");
        return;
    }
    else if (menuOption == Menu_ViewRank)
    {
        FakeClientCommand(client, "sm_stats");
        return;
    }
    else if (menuOption == Menu_VoteCustomMap)
    {
        PrintHintText(client, "Custom map voting is not configured.");
        return;
    }
    else if (menuOption == Menu_VoteGameMode)
    {
        ChangeGameModeByIndex(client, value);
        return;
    }
    else if (menuOption == Menu_ThirdPerson)
    {
        if (value < 0 || value > 2)
        {
            PrintHintText(client, "Invalid camera selection.");
            return;
        }

        ThirdPersonMode newMode = view_as<ThirdPersonMode>(value);
        g_ThirdPersonMode[client] = newMode;
        PersistThirdPersonMode(client);
        ApplyThirdPersonMode(client);
        PrintHintText(client, "Camera mode set to %s.", (newMode == TP_Always) ? "Always" : (newMode == TP_MeleeOnly) ? "Melee only" : "Off");
        return;
    }
    else if (menuOption == Menu_MultiEquip)
    {
        PrintHintText(client, "Multiple equipment mode is not configured.");
        return;
    }
    else if (menuOption == Menu_HudToggle)
    {
        bool enableHud = value != 0;
        SetHudEnabled(enableHud, client);
        return;
    }
    else if (menuOption == Menu_MusicToggle)
    {
        if (value == 0)
        {
            FakeClientCommand(client, "sm_music_pause");
            PrintHintText(client, "Music paused.");
        }
        else
        {
            FakeClientCommand(client, "sm_music_play");
            FakeClientCommand(client, "sm_music"); // open menu for quick control
            PrintHintText(client, "Music playing. Use menu to change track.");
        }
        return;
    }
    else if (menuOption == Menu_MusicVolume)
    {
        // Value from ExtraMenu list index (0-10). Clamp defensively.
        int vol = value;
        if (vol < 0)
        {
            vol = 0;
        }
        else if (vol > 10)
        {
            vol = 10;
        }

        FakeClientCommand(client, "sm_music_volume %d", vol);
        PrintHintText(client, "Music volume set to %d%%", vol * 10);
        return;
    }
    else if (menuOption == Menu_SpawnItems)
    {
        PrintHintText(client, "Item spawning is not available.");
        return;
    }
    else if (menuOption == Menu_Reload)
    {
        PrintHintText(client, "Reload options are not available.");
        return;
    }
    else if (menuOption == Menu_ManageSkills)
    {
        PrintHintText(client, "Manage skills menu is not available.");
        return;
    }
    else if (menuOption == Menu_ManagePerks)
    {
        PrintHintText(client, "Perk management is not available.");
        return;
    }
    else if (menuOption == Menu_ApplyEffect)
    {
        PrintHintText(client, "Apply-effect option is not available.");
        return;
    }
    else if (menuOption == Menu_DebugMode)
    {
        PrintHintText(client, "Debug mode toggle is not wired here.");
        return;
    }
    else if (menuOption == Menu_HaltGame)
    {
        PrintHintText(client, "Halt game is not available.");
        return;
    }
    else if (menuOption == Menu_InfectedSpawn)
    {
        PrintHintText(client, "Infected spawn toggle is not available.");
        return;
    }
    else if (menuOption == Menu_GodMode)
    {
        PrintHintText(client, "God mode toggle is not available.");
        return;
    }
    else if (menuOption == Menu_RemoveWeapons)
    {
        PrintHintText(client, "Remove weapons option is not available.");
        return;
    }
    else if (menuOption == Menu_GameSpeed)
    {
        PrintHintText(client, "Game speed control is not available.");
        return;
    }
    else if (menuOption == Menu_Guide)
    {
        if (!TryShowGuideMenu(client))
        {
            PrintToChat(client, "[Rage] Tutorial plugin is not available right now.");
        }
        return;
    }

    PrintHintText(client, "This menu option is not configured.");

}

public void ExtraMenu_OnSelect(int client, int menu_id, int option, int value)
{
    RageMenu_OnSelect(client, menu_id, option, value);
}

public void RefreshGuideLibraryStatus()
{
    g_bGuideNativeAvailable = (GetFeatureStatus(FeatureType_Native, "RageGuide_ShowMainMenu") == FeatureStatus_Available);
}

public bool TryShowGuideMenu(int client)
{
    if (!g_bGuideNativeAvailable || client <= 0 || !IsClientInGame(client))
    {
        return false;
    }

    RageGuide_ShowMainMenu(client);
    return true;
}

public void AddGameModeOptions(int menu_id)
{
    char options[512];
    options[0] = '\0';

    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        if (options[0] != '\0')
        {
            StrCat(options, sizeof(options), "|");
        }

        StrCat(options, sizeof(options), g_sGameModeNames[i]);
    }

    ExtraMenu_AddOptions(menu_id, options);
}

public void AddClassOptions(int menu_id)
{
    char options[256];
    options[0] = '\0';

    for (int i = 0; i < CLASS_OPTION_COUNT; i++)
    {
        if (options[0] != '\0')
        {
            StrCat(options, sizeof(options), "|");
        }

        StrCat(options, sizeof(options), g_sClassOptions[i]);
    }

    ExtraMenu_AddOptions(menu_id, options);
}

void ChangeGameModeByIndex(int client, int modeIndex)
{
    if (modeIndex < 0 || modeIndex >= GAMEMODE_OPTION_COUNT)
    {
        PrintToChat(client, "[Rage] Unknown game mode option.");
        return;
    }

    if (g_hCvarMPGameMode == null)
    {
        PrintToChat(client, "[Rage] Unable to change game mode right now.");
        return;
    }

    ConVar cvar = g_hGameModeCvars[modeIndex];
    if (cvar == null)
    {
        PrintToChat(client, "[Rage] Game mode option is not configured.");
        return;
    }

    char targetMode[64];
    cvar.GetString(targetMode, sizeof(targetMode));
    TrimString(targetMode);

    if (targetMode[0] == '\0')
    {
        PrintToChat(client, "[Rage] Game mode value is empty.");
        return;
    }

    char currentMode[64];
    g_hCvarMPGameMode.GetString(currentMode, sizeof(currentMode));

    if (StrEqual(currentMode, targetMode, false))
    {
        PrintToChat(client, "[Rage] %s is already active.", g_sGameModeNames[modeIndex]);
        return;
    }

    g_hCvarMPGameMode.SetString(targetMode);
    LogAction(client, -1, "\"%L\" changed game mode to \"%s\"", client, targetMode);
    ShowActivity2(client, "[Rage] ", "changed game mode to %s.", g_sGameModeNames[modeIndex]);
    PrintToChatAll("[Rage] %N switched the game mode to %s (\"%s\").", client, g_sGameModeNames[modeIndex], targetMode);
}

void BuildRageMenus()
{
    if (!g_bExtraMenuLoaded)
    {
        return;
    }

    BuildSingleMenu(true);
    BuildSingleMenu(false);
}

void BuildSingleMenu(bool includeChangeClass)
{
    ArrayList optionMap = new ArrayList();
    int menu_id = ExtraMenu_Create();
    bool buttons_nums = false;

    ExtraMenu_AddEntry(menu_id, "GAME MENU:", MENU_ENTRY);
    if (!buttons_nums)
    {
        ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    }

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. Get Kit", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_GetKit));
    ExtraMenu_AddOptions(menu_id, "Medic kit|Rambo kit|Counter-terrorist kit|Ninja kit");

    ExtraMenu_AddEntry(menu_id, "2. Set yourself away", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_SetAway));
    ExtraMenu_AddEntry(menu_id, "3. Select team", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_SelectTeam));

    if (includeChangeClass)
    {
        ExtraMenu_AddEntry(menu_id, "4. Change class: _OPT_", MENU_SELECT_LIST);
        optionMap.Push(view_as<int>(Menu_ChangeClass));
        AddClassOptions(menu_id);
    }

    ExtraMenu_AddEntry(menu_id, "5. Deploy class ability", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_DeployAction));

    ExtraMenu_AddEntry(menu_id, "6. See your ranking", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_ViewRank));
    ExtraMenu_AddEntry(menu_id, "7. Vote for custom map", MENU_SELECT_ADD, false, 250, 10, 100, 300);
    optionMap.Push(view_as<int>(Menu_VoteCustomMap));
    ExtraMenu_AddEntry(menu_id, "8. Vote for gamemode", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_VoteGameMode));
    AddGameModeOptions(menu_id);
    ExtraMenu_NewPage(menu_id);

    ExtraMenu_AddEntry(menu_id, "GAME OPTIONS:", MENU_ENTRY);
    if (!buttons_nums)
    {
        ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    }

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. 3rd person mode: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_ThirdPerson));
    ExtraMenu_AddOptions(menu_id, "Off|Melee Only|Always");
    ExtraMenu_AddEntry(menu_id, "2. Multiple Equipment Mode: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_MultiEquip));
    ExtraMenu_AddOptions(menu_id, "Off|Single Tap|Double tap");
    ExtraMenu_AddEntry(menu_id, "3. HUD: _OPT_", MENU_SELECT_ONOFF, false, g_bHudEnabled ? 1 : 0);
    optionMap.Push(view_as<int>(Menu_HudToggle));
    ExtraMenu_AddEntry(menu_id, "4. Music player: _OPT_", MENU_SELECT_ONOFF);
    optionMap.Push(view_as<int>(Menu_MusicToggle));
    ExtraMenu_AddEntry(menu_id, "5. Music Volume: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_MusicVolume));
    ExtraMenu_AddOptions(menu_id, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

    ExtraMenu_NewPage(menu_id);

    ExtraMenu_AddEntry(menu_id, "ADMIN MENU:", MENU_ENTRY);

    ExtraMenu_AddEntry(menu_id, "1. Spawn Items: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_SpawnItems));
    ExtraMenu_AddOptions(menu_id, "New cabinet|New weapon|Special Infected|Special tank");
    ExtraMenu_AddEntry(menu_id, "2. Reload _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_Reload));
    ExtraMenu_AddOptions(menu_id, "Map|Rage Plugins|All plugins|Restart server");
    ExtraMenu_AddEntry(menu_id, "3. Manage skills", MENU_SELECT_ONLY, true);
    optionMap.Push(view_as<int>(Menu_ManageSkills));
    ExtraMenu_AddEntry(menu_id, "4. Manage perks", MENU_SELECT_ONLY, true);
    optionMap.Push(view_as<int>(Menu_ManagePerks));
    ExtraMenu_AddEntry(menu_id, "5. Apply effect on player", MENU_SELECT_ONLY, true);
    optionMap.Push(view_as<int>(Menu_ApplyEffect));

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "DEBUG COMMANDS:", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. Debug mode: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_DebugMode));
    ExtraMenu_AddOptions(menu_id, "Off|Log to file|Log to chat|Tracelog to chat");
    ExtraMenu_AddEntry(menu_id, "2. Halt game: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_HaltGame));
    ExtraMenu_AddOptions(menu_id, "Off|Only survivors|All");
    ExtraMenu_AddEntry(menu_id, "3. Infected spawn: _OPT_", MENU_SELECT_ONOFF, false, 1);
    optionMap.Push(view_as<int>(Menu_InfectedSpawn));
    ExtraMenu_AddEntry(menu_id, "4. God mode: _OPT_", MENU_SELECT_ONOFF, false, 1);
    optionMap.Push(view_as<int>(Menu_GodMode));
    ExtraMenu_AddEntry(menu_id, "5. Remove weapons from map", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_RemoveWeapons));
    ExtraMenu_AddEntry(menu_id, "6. Game speed: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_GameSpeed));
    ExtraMenu_AddOptions(menu_id, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");

    int guideIndex = optionMap.Length;
    ExtraMenu_AddEntry(menu_id, "Open Rage tutorial guide", MENU_SELECT_ONLY, true);
    optionMap.Push(view_as<int>(Menu_Guide));
    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);

    if (includeChangeClass)
    {
        if (g_iMenuIDSurvivor != 0)
        {
            ExtraMenu_Delete(g_iMenuIDSurvivor);
        }

        if (g_hMenuOptionsSurvivor != null)
        {
            delete g_hMenuOptionsSurvivor;
        }

        g_iMenuIDSurvivor = menu_id;
        g_iGuideOptionIndexSurvivor = guideIndex;
        g_hMenuOptionsSurvivor = optionMap;
    }
    else
    {
        if (g_iMenuIDInfected != 0)
        {
            ExtraMenu_Delete(g_iMenuIDInfected);
        }

        if (g_hMenuOptionsInfected != null)
        {
            delete g_hMenuOptionsInfected;
        }

        g_iMenuIDInfected = menu_id;
        g_iGuideOptionIndexInfected = guideIndex;
        g_hMenuOptionsInfected = optionMap;
    }
}

void SyncMenuSelections(int client, int menuId, ArrayList optionMap)
{
    if (optionMap == null)
    {
        return;
    }

    SyncMenuSelection(client, menuId, optionMap, Menu_ThirdPerson, view_as<int>(g_ThirdPersonMode[client]));
    SyncMenuSelection(client, menuId, optionMap, Menu_HudToggle, g_bHudEnabled ? 1 : 0);
}

void SyncMenuSelection(int client, int menuId, ArrayList optionMap, RageMenuOption option, int value)
{
    int index = optionMap.FindValue(view_as<int>(option));
    if (index != -1)
    {
        ExtraMenu_SetClientValue(menuId, client, index, value);
    }
}

public bool HasRageMenuAccess(int client)
{
    return client > 0 && IsClientInGame(client) && CheckCommandAccess(client, "sm_rage", 0);
}

public bool DisplayRageMenu(int client, bool showHint)
{
    if (!HasRageMenuAccess(client))
    {
        PrintToChat(client, "[Rage] You do not have access to this menu.");
        return false;
    }

    int menuId = (GetClientTeam(client) == 2) ? g_iMenuIDSurvivor : g_iMenuIDInfected;
    if (!g_bExtraMenuLoaded || menuId == 0)
    {
        PrintToChat(client, "[Rage] Menu system is not ready yet.");
        return false;
    }

    ArrayList optionMap = (GetClientTeam(client) == 2) ? g_hMenuOptionsSurvivor : g_hMenuOptionsInfected;
    SyncMenuSelections(client, menuId, optionMap);

    if (showHint)
    {
        PrintHintText(client, "Press X (voice menu) or type !rage_bind to bind a key; use W/S/A/D to navigate.");
    }

    ExtraMenu_Display(client, menuId, MENU_TIME_FOREVER);
    return true;
}

public void SetHudEnabled(bool enabled, int activator)
{
    if (activator > 0 && IsClientInGame(activator))
    {
        if (g_bHudEnabled == enabled)
        {
            PrintHintText(activator, "HUD is already %s.", enabled ? "on" : "off");
            return;
        }
    }

    g_bHudEnabled = enabled;

    BuildRageMenus();

    if (!enabled)
    {
        DeleteAllHUD();

        if (activator > 0 && IsClientInGame(activator))
        {
            PrintHintText(activator, "HUD disabled.");
        }

        return;
    }

    // Only setup HUD if a map is running (entities can be created)
    char mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    if (mapname[0] == '\0')
    {
        // Map not loaded yet, HUD will be initialized in OnMapStart
        return;
    }

    hudPosition currentPos = view_as<hudPosition>(getCurrentHud());
    if (currentPos < HUD_POSITION_FAR_LEFT || currentPos > HUD_POSITION_SCORE_4)
    {
        currentPos = HUD_POSITION_MID_TOP;
    }

    SetupMessageHud(currentPos, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS);

    if (activator > 0 && IsClientInGame(activator))
    {
        PrintHintText(activator, "HUD enabled.");
    }
}

public bool IsMeleeWeapon(int weapon)
{
    if (weapon <= 0 || !IsValidEntity(weapon))
    {
        return false;
    }

    char cls[64];
    GetEntityClassname(weapon, cls, sizeof(cls));
    return StrContains(cls, "melee", false) != -1 || StrEqual(cls, "weapon_chainsaw", false);
}

public void PersistThirdPersonMode(int client)
{
    if (g_hThirdPersonCookie == INVALID_HANDLE || IsFakeClient(client))
    {
        return;
    }

    char buffer[8];
    IntToString(view_as<int>(g_ThirdPersonMode[client]), buffer, sizeof(buffer));
    SetClientCookie(client, g_hThirdPersonCookie, buffer);
}

public void ApplyThirdPersonMode(int client)
{
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return;
    }

    bool shouldThird = false;
    switch (g_ThirdPersonMode[client])
    {
        case TP_MeleeOnly:
        {
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            shouldThird = IsMeleeWeapon(weapon);
        }
        case TP_Always:
        {
            shouldThird = true;
        }
    }

    if (shouldThird == g_ThirdPersonActive[client])
    {
        return;
    }

    g_ThirdPersonActive[client] = shouldThird;

    SetThirdPersonActive(client, shouldThird);
}

void SetThirdPersonActive(int client, bool enable)
{
    if (!g_bThirdPersonPluginAvailable || client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    if (enable)
    {
        FakeClientCommand(client, "sm_3rdon");
    }
    else
    {
        FakeClientCommand(client, "sm_3rdoff");
    }
}

bool IsValidKeyString(const char[] key)
{
    // Validate that the key string only contains safe characters
    // Valid keys are alphanumeric, mouse buttons, or common special keys
    int len = strlen(key);
    if (len == 0 || len > 31)
    {
        return false;
    }
    
    // Check each character - allow alphanumeric, underscore, and digits
    for (int i = 0; i < len; i++)
    {
        char c = key[i];
        // Allow: a-z, A-Z, 0-9, underscore
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'))
        {
            return false;
        }
    }
    
    return true;
}

public Action Timer_NotifyMenuKey(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Stop;
    }
    
    char defaultKey[32];
    if (g_hDefaultMenuKey != null)
    {
        g_hDefaultMenuKey.GetString(defaultKey, sizeof(defaultKey));
        if (defaultKey[0] != '\0')
        {
            PrintToChat(client, "\x04[Rage]\x01 Menu bound to \x03%s\x01 key. Hold to open, release to close.", defaultKey);
            PrintToChat(client, "\x01Or press \x03X\x01 (voice menu) for quick access. Type \x03!rage_bind\x01 to change key.");
        }
    }
    
    return Plugin_Stop;
}
