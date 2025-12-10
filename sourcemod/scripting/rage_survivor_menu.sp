
#define PLUGIN_VERSION "0.3"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <admin>
#include <clientprefs>
#include <left4dhooks>
#include <rage_menus/rage_menu_base>
#include <rage_survivor_guide>
#include <jutils>
#include <rage_menus/rage_survivor_menu_kits>
#include <rage_menus/rage_survivor_menu_keybinds>
#include <rage_menus/rage_survivor_menu_thirdperson>
#include <rage_menus/rage_survivor_menu_multiequip>
#include <rage/const>
#include <RageCore>

// Define PRINT_PREFIX since we're not including talents.inc
#define PRINT_PREFIX 	"\x04[RAGE]\x01"

// Forward declarations for functions from rage_survivor.sp that we need
// These are implemented in rage_survivor.sp and available at runtime
// Note: We use FakeClientCommand to trigger class selection instead of calling functions directly

// ClientData is not accessible from this plugin, so we'll use GetSavedClassIndex instead
// which reads from cookies and is available

#define GAMEMODE_OPTION_COUNT 13
#define CLASS_OPTION_COUNT 8
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
    "Realism",
    "GuessWho",
    "Race Mod"
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
    "rage_gamemode_realism",
    "rage_gamemode_guesswho",
    "rage_gamemode_race"
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
    "realism",
    "guesswho",
    "coop"
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
    "mp_gamemode value for Realism.",
    "mp_gamemode value for GuessWho (Hide & Seek).",
    "mp_gamemode value for Race Mod (race to safe room)."
};

static const char g_sClassOptions[CLASS_OPTION_COUNT][] =
{
    "No class selected",
    "Soldier",
    "Athlete",
    "Medic",
    "Saboteur",
    "Commando",
    "Engineer",
    "Brawler"
};

static const char g_sClassIdentifiers[CLASS_OPTION_COUNT][] =
{
    "none",
    "soldier",
    "athlete",
    "medic",
    "saboteur",
    "commando",
    "engineer",
    "brawler"
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
int g_iLastButtons[MAXPLAYERS + 1];
int g_iLastSelectedOption[MAXPLAYERS + 1] = {-1, ...};
int g_iLastSelectedMenuId[MAXPLAYERS + 1] = {-1, ...};
bool g_bQuickActionMenuOpen[MAXPLAYERS + 1] = {false, ...};
float g_fQuickActionHoldStart[MAXPLAYERS + 1] = {0.0, ...};
Handle g_hQuickActionMenu[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
ArrayList g_hMenuOptionsSurvivor = null;
ArrayList g_hMenuOptionsInfected = null;
int g_iAdminMenuOptionIndexSurvivor = -1;  // Index of admin menu option in survivor menu
int g_iAdminMenuOptionIndexInfected = -1;   // Index of admin menu option in infected menu

Handle g_hClassCookie = INVALID_HANDLE;

// Team switch tracking
int g_iTeamSwitchCount[MAXPLAYERS + 1] = {0, ...};
int g_iVoteSelection[MAXPLAYERS + 1] = {-1, ...};  // -1 = none, 0 = map, 1+ = gamemode index
bool g_bVoteTypeIsMap[MAXPLAYERS + 1] = {false, ...};

ConVar g_hCvarMPGameMode;
ConVar g_hGameModeCvars[GAMEMODE_OPTION_COUNT];

enum RageMenuOption
{
    Menu_GetKit = 0,
    Menu_SetAway,
    Menu_SelectTeam,
    Menu_ChangeClass,
    Menu_DeployAction,
    Menu_ViewRank,
    Menu_VoteOptions,  // Combined voting menu (map + gamemode)
    Menu_VoteAction,   // Action button to initiate vote
    Menu_ThirdPerson,
    Menu_MultiEquip,
    Menu_MusicToggle,
    Menu_MusicVolume,
    Menu_AdminMenu,  // Link to admin menu (only shown for admins)
    Menu_Guide
};

// Forward declarations for types and functions from rage_survivor.sp
// These enums must match the definitions in rage_survivor.sp
enum ClassSkillInput
{
        ClassSkill_Special = 0,
        ClassSkill_Secondary,
        ClassSkill_Tertiary,
        ClassSkill_Deploy,
        ClassSkill_Count
};

enum ClassActionMode
{
	ActionMode_None = 0,
	ActionMode_Skill,
	ActionMode_Command,
	ActionMode_Builtin
};

enum BuiltinAction
{
	Builtin_None = 0,
	Builtin_MedicSupplies,
	Builtin_EngineerSupplies,
	Builtin_SaboteurMines
};

// Forward declarations for functions (these are implemented in rage_survivor.sp)
// Note: These need to be available at compile time, so we'll use stock functions
// that call the actual implementations if available, or provide fallbacks
stock bool TryExecuteSkillInput(int client, ClassSkillInput input)
{
    // This will be resolved at runtime - the actual function is in rage_survivor.sp
    // For now, we'll use FakeClientCommand as a workaround
    switch (input)
    {
        case ClassSkill_Special:
        {
            FakeClientCommand(client, "skill_action_1");
        }
        case ClassSkill_Secondary:
        {
            FakeClientCommand(client, "skill_action_2");
        }
        case ClassSkill_Tertiary:
        {
            FakeClientCommand(client, "skill_action_3");
        }
        case ClassSkill_Deploy:
        {
            FakeClientCommand(client, "deployment_action");
        }
    }
    return true;
}

// These functions are available through rage/menus include
// They're implemented in rage_survivor.sp but accessible via the include
// Forward declarations for functions that may not be available
forward int GetMaxWithClass(int classIndex);
forward int CountPlayersWithClass(int classIndex);

void AddGameModeOptions(int menu_id);
void AddClassOptions(int menu_id);
void RefreshGuideLibraryStatus();
bool TryShowGuideMenu(int client);
bool DisplayRageMenu(int client, bool showHint);
bool HasRageMenuAccess(int client);
void ApplyThirdPersonMode(int client);
int GetSavedClassIndex(int client);
int ClassIdentifierToIndex(const char[] ident);
void SyncMenuSelections(int client, int menuId, ArrayList optionMap);
void SyncMenuSelection(int client, int menuId, ArrayList optionMap, RageMenuOption option, int value);

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
    g_hClassCookie = FindClientCookie("rage_class_choice");

    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        g_hGameModeCvars[i] = CreateConVar(g_sGameModeCvarNames[i], g_sGameModeDefaults[i], g_sGameModeDescriptions[i], FCVAR_NONE);
    }

    ThirdPerson_OnPluginStart();
    MultiEquip_OnPluginStart();
    Keybinds_OnPluginStart();
    Kits_OnPluginStart();
    AutoExecConfig(true, "rage_survivor_menu");

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

    RefreshGuideLibraryStatus();
}

public void OnAllPluginsLoaded()
{
    RefreshGuideLibraryStatus();
}

public void OnClientPutInServer(int client)
{
    g_bMenuHeld[client] = false;
    g_iLastButtons[client] = 0;
    g_iLastSelectedOption[client] = -1;
    g_iLastSelectedMenuId[client] = -1;
    g_iTeamSwitchCount[client] = 0;
    g_iVoteSelection[client] = -1;
    g_bVoteTypeIsMap[client] = false;
    g_bQuickActionMenuOpen[client] = false;
    g_fQuickActionHoldStart[client] = 0.0;
    if (g_hQuickActionMenu[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hQuickActionMenu[client]);
        g_hQuickActionMenu[client] = INVALID_HANDLE;
    }
    ThirdPerson_OnClientPutInServer(client);
    MultiEquip_OnClientPutInServer(client);
    Kits_OnClientPutInServer(client);
    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect(int client)
{
    g_bMenuHeld[client] = false;
    g_iTeamSwitchCount[client] = 0;
    g_iVoteSelection[client] = -1;
    g_bVoteTypeIsMap[client] = false;
    g_bQuickActionMenuOpen[client] = false;
    g_fQuickActionHoldStart[client] = 0.0;
    if (g_hQuickActionMenu[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hQuickActionMenu[client]);
        g_hQuickActionMenu[client] = INVALID_HANDLE;
    }
    ThirdPerson_OnClientDisconnect(client);
    MultiEquip_OnClientDisconnect(client);
    Kits_OnClientDisconnect(client);
}

public void OnMapStart()
{
    // Reset team switch counts on new map
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iTeamSwitchCount[i] = 0;
        g_iVoteSelection[i] = -1;
        g_bVoteTypeIsMap[i] = false;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    // Check for SHOVE+USE held for 1 second to open quick action menu
    if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        bool holdingShove = (buttons & IN_ATTACK2) != 0;
        bool holdingUse = (buttons & IN_USE) != 0;
        bool holdingBoth = holdingShove && holdingUse;
        
        if (holdingBoth && !g_bQuickActionMenuOpen[client])
        {
            if (g_fQuickActionHoldStart[client] == 0.0)
            {
                g_fQuickActionHoldStart[client] = GetGameTime();
            }
            else
            {
                float holdTime = GetGameTime() - g_fQuickActionHoldStart[client];
                if (holdTime >= 1.0)
                {
                    DisplayQuickActionMenu(client);
                    g_fQuickActionHoldStart[client] = 0.0;
                }
            }
        }
        else if (!holdingBoth)
        {
            g_fQuickActionHoldStart[client] = 0.0;
            if (g_bQuickActionMenuOpen[client])
            {
                CloseQuickActionMenu(client);
            }
        }
    }
    else
    {
        g_fQuickActionHoldStart[client] = 0.0;
        if (g_bQuickActionMenuOpen[client])
        {
            CloseQuickActionMenu(client);
        }
    }

    // Removed redundant SHIFT button detection - console commands (+rage_menu) handle this now
    // Menu opening/closing is handled via +rage_menu and -rage_menu console commands
    
    // Check for USE (E) button to execute action when menu is open
    if (g_bMenuHeld[client])
    {
        bool pressingUse = (buttons & IN_USE) != 0;
        bool wasPressingUse = (g_iLastButtons[client] & IN_USE) != 0;
        
        if (pressingUse && !wasPressingUse)
        {
            // USE button just pressed - trigger the last selected action if it's an action type
            int menu_id = g_iLastSelectedMenuId[client];
            int option = g_iLastSelectedOption[client];
            
            if (menu_id >= 0 && option >= 0)
            {
                ArrayList map = null;
                if (menu_id == g_iMenuIDSurvivor)
                {
                    map = g_hMenuOptionsSurvivor;
                }
                else if (menu_id == g_iMenuIDInfected)
                {
                    map = g_hMenuOptionsInfected;
                }
                
                if (map != null && option < map.Length)
                {
                    RageMenuOption menuOption = view_as<RageMenuOption>(map.Get(option));
                    
                    // Check if this is an action that should be triggered by E
                    if (menuOption == Menu_DeployAction)
                    {
                        // Close menu and execute action
                        ExtraMenu_Close(client);
                        g_bMenuHeld[client] = false;
                        
                        // Execute the deployment action - it will handle its own feedback/menus
                        FakeClientCommand(client, "deployment_action");
                        
                        // Don't show generic message - let the deployment action show its own menu/feedback
                    }
                }
            }
        }
    }
    
    g_iLastButtons[client] = buttons;
    return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
    ThirdPerson_OnCookiesCached(client);
    MultiEquip_OnCookiesCached(client);
    Keybinds_OnClientCookiesCached(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    Kits_OnPlayerSpawn(client);
    ThirdPerson_OnPlayerSpawn(client);
}

public Action OnWeaponSwitchPost(int client, int weapon)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    ThirdPerson_OnWeaponSwitch(client);
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
    // This function handles both sm_rage (regular menu) and sm_ragem (admin menu)
    // Check if user has admin access - if so, they might be calling sm_ragem
    // For now, always show the main menu - admin menu is accessed via CreateRageMenu directly
    // The admin command registration in admin_commands.inc will call this, but we'll
    // show the main menu for consistency. Admins can use CreateRageMenu directly if needed.
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
    PrintToChat(client, "\x01Example: \x03bind g +rage_menu");
    PrintToChat(client, "\x01Suggested keys: \x03g, k, mouse4, mouse5");
    PrintToChat(client, "\x01Hold the key to open menu, release to close.");
    PrintToChat(client, "\x01Note: SHIFT is already bound by default. Avoid X and V (voice commands).");

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
    // Store the last selected option for E button detection
    g_iLastSelectedOption[client] = option;
    g_iLastSelectedMenuId[client] = menu_id;
    
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

    // Check admin access for admin menu
    if (menuOption == Menu_AdminMenu)
    {
        if (!CheckCommandAccess(client, "sm_adm", ADMFLAG_ROOT))
        {
            PrintHintText(client, "This option is only available to admins.");
            return;
        }
        
        // Open admin menu via command
        FakeClientCommand(client, "sm_adm");
        return;
    }

    if (menuOption == Menu_GetKit)
    {
        if (!Kits_CanUseKit(client))
        {
            PrintHintText(client, "You're out of kits. Please wait for more to become available.");
            return;
        }

        int kitsRemaining = Kits_ConsumeKit(client);
        FakeClientCommand(client, "sm_kit");

        PrintHintText(client, "Kit delivered (%d remaining).", kitsRemaining);
        return;
    }
    else if (menuOption == Menu_SetAway)
    {
        FakeClientCommand(client, "sm_afk");
        return;
    }
    else if (menuOption == Menu_SelectTeam)
    {
        PrintHintText(client, "Team selection is not available here. Use the main menu instead.");
        return;
    }
    else if (menuOption == Menu_ChangeClass)
    {
        if (value < 0 || value >= CLASS_OPTION_COUNT)
        {
            PrintHintText(client, "Please select a class using the left/right arrows.");
            return;
        }

        if (value == 0)
        {
            PrintHintText(client, "No class selected. Please choose one first.");
            return;
        }

        int classIndex = value; // options align with actual class index
        FakeClientCommand(client, "sm_class_set %d", classIndex);
        PrintHintText(client, "Switching to %s", g_sClassOptions[value]);
        return;
    }
    else if (menuOption == Menu_DeployAction)
    {
        // Close menu and execute deployment action
        ExtraMenu_Close(client);
        g_bMenuHeld[client] = false;
        
        // Execute the deployment action - it will handle its own feedback/menus
        FakeClientCommand(client, "deployment_action");
        
        // Don't show generic message - let the deployment action show its own menu/feedback
        return;
    }
    else if (menuOption == Menu_ViewRank)
    {
        FakeClientCommand(client, "sm_stats");
        return;
    }
    else if (menuOption == Menu_VoteOptions)
    {
        // value: 0 = Change Map, 1+ = Gamemode index (1 = Versus, 2 = Competitive, etc.)
        if (value < 0)
        {
            PrintHintText(client, "Something went wrong. Please try again.");
            return;
        }
        
        if (value == 0)
        {
            // Map vote selected
            g_iVoteSelection[client] = 0;
            g_bVoteTypeIsMap[client] = true;
            PrintHintText(client, "Selected: Change Map. Press 'Initiate Vote' to start.");
        }
        else
        {
            // Gamemode vote selected (value is 1-based index into gamemode array)
            int modeIndex = value - 1; // Convert to 0-based
            if (modeIndex >= 0 && modeIndex < GAMEMODE_OPTION_COUNT)
            {
                g_iVoteSelection[client] = modeIndex;
                g_bVoteTypeIsMap[client] = false;
                PrintHintText(client, "Selected: %s. Press 'Initiate Vote' to start.", g_sGameModeNames[modeIndex]);
            }
            else
            {
                PrintHintText(client, "Something went wrong. Please try again.");
            }
        }
        return;
    }
    else if (menuOption == Menu_VoteAction)
    {
        // Initiate the selected vote
        if (g_iVoteSelection[client] == -1)
        {
            PrintHintText(client, "Please select a vote option first.");
            return;
        }
        
        if (g_bVoteTypeIsMap[client])
        {
            // Initiate map vote
            FakeClientCommand(client, "sm_chmap");
            g_iVoteSelection[client] = -1;
            g_bVoteTypeIsMap[client] = false;
        }
        else
        {
            // Initiate gamemode vote
            ChangeGameModeByIndex(client, g_iVoteSelection[client]);
            g_iVoteSelection[client] = -1;
            g_bVoteTypeIsMap[client] = false;
        }
        return;
    }
    else if (menuOption == Menu_ThirdPerson)
    {
        if (value < 0 || value > 2)
        {
            PrintHintText(client, "Something went wrong. Please try again.");
            return;
        }

        ThirdPersonMode newMode = view_as<ThirdPersonMode>(value);
        ThirdPerson_SetMode(client, newMode);
        PrintHintText(client, "Camera mode set to %s.", (newMode == TP_Always) ? "Always" : (newMode == TP_MeleeOnly) ? "Melee only" : "Off");
        
        // Update menu to show the new active mode immediately
        if (g_bMenuHeld[client])
        {
            int menuId = (GetClientTeam(client) == 2) ? g_iMenuIDSurvivor : g_iMenuIDInfected;
            ArrayList optionMap = (GetClientTeam(client) == 2) ? g_hMenuOptionsSurvivor : g_hMenuOptionsInfected;
            if (menuId > 0 && optionMap != null)
            {
                SyncMenuSelection(client, menuId, optionMap, Menu_ThirdPerson, view_as<int>(newMode));
                // Redisplay the menu to show updated value
                ExtraMenu_Display(client, menuId, MENU_TIME_FOREVER);
            }
        }
        return;
    }
    else if (menuOption == Menu_MultiEquip)
    {
        if (value < 0 || value > 2)
        {
            PrintHintText(client, "Something went wrong. Please try again.");
            return;
        }

        MultiEquipMode newMode = view_as<MultiEquipMode>(value);
        MultiEquip_SetMode(client, newMode);

        // Show hint text with tap count information
        char modeName[32];
        int tapCount = 0;
        switch (newMode)
        {
            case ME_Off:
            {
                strcopy(modeName, sizeof(modeName), "Off");
                PrintHintText(client, "Quick switch disabled - normal item pickup");
            }
            case ME_SingleTap:
            {
                strcopy(modeName, sizeof(modeName), "Single Tap");
                tapCount = 1;
                PrintHintText(client, "Quick switch enabled - tap once to swap items");
            }
            case ME_DoubleTap:
            {
                strcopy(modeName, sizeof(modeName), "Double Tap");
                tapCount = 2;
                PrintHintText(client, "Double tap enabled - tap twice to swap items");
            }
        }

        // Update menu to show the new active mode immediately
        if (g_bMenuHeld[client])
        {
            int menuId = (GetClientTeam(client) == 2) ? g_iMenuIDSurvivor : g_iMenuIDInfected;
            ArrayList optionMap = (GetClientTeam(client) == 2) ? g_hMenuOptionsSurvivor : g_hMenuOptionsInfected;
            if (menuId > 0 && optionMap != null)
            {
                SyncMenuSelection(client, menuId, optionMap, Menu_MultiEquip, view_as<int>(newMode));
                // Redisplay the menu to show updated value
                ExtraMenu_Display(client, menuId, MENU_TIME_FOREVER);
            }
        }
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

public int GetSavedClassIndex(int client)
{
    if (client <= 0 || client > MaxClients || g_hClassCookie == INVALID_HANDLE || !IsClientInGame(client))
    {
        return 0;
    }

    char stored[32];
    GetClientCookie(client, g_hClassCookie, stored, sizeof(stored));
    TrimString(stored);

    if (stored[0] == '\0')
    {
        return 0;
    }

    int classIndex = ClassIdentifierToIndex(stored);
    if (classIndex <= 0 || classIndex >= CLASS_OPTION_COUNT)
    {
        return 0;
    }

    return classIndex;
}

public int ClassIdentifierToIndex(const char[] ident)
{
    for (int i = 1; i < CLASS_OPTION_COUNT; i++)
    {
        if (StrEqual(ident, g_sClassIdentifiers[i], false))
        {
            return i;
        }
    }

    return 0;
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
    ExtraMenu_AddEntry(menu_id, "1. Deploy class ability", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_DeployAction));

    if (includeChangeClass)
    {
        ExtraMenu_AddEntry(menu_id, "2. Choose class: _OPT_", MENU_SELECT_LIST);
        optionMap.Push(view_as<int>(Menu_ChangeClass));
        AddClassOptions(menu_id);
    }

    ExtraMenu_AddEntry(menu_id, "3. 3rd person mode: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_ThirdPerson));
    ExtraMenu_AddOptions(menu_id, "Off|Melee Only|Always");

    int guideIndex = optionMap.Length;
    ExtraMenu_AddEntry(menu_id, "4. Guide", MENU_SELECT_ONLY, true);
    optionMap.Push(view_as<int>(Menu_Guide));

    ExtraMenu_NewPage(menu_id);

    ExtraMenu_AddEntry(menu_id, "TEAM & VOTING:", MENU_ENTRY);
    if (!buttons_nums)
    {
        ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    }

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    
    // Team selection as slider (AFK/Infected/Survivors)
    ExtraMenu_AddEntry(menu_id, "1. Team: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_SelectTeam));
    ExtraMenu_AddOptions(menu_id, "AFK|Infected|Survivors");
    
    ExtraMenu_AddEntry(menu_id, "2. Set yourself away", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_SetAway));
    
    // Combined voting options (scrollable)
    ExtraMenu_AddEntry(menu_id, "3. Vote Options: _OPT_", MENU_SELECT_ADD, false, 250, 10, 100, 300);
    optionMap.Push(view_as<int>(Menu_VoteOptions));
    // Build vote options string: "Change Map|Gamemode1|Gamemode2|..."
    char voteOptions[512] = "Change Map|";
    for (int i = 0; i < GAMEMODE_OPTION_COUNT; i++)
    {
        if (i > 0)
            StrCat(voteOptions, sizeof(voteOptions), "|");
        StrCat(voteOptions, sizeof(voteOptions), g_sGameModeNames[i]);
    }
    ExtraMenu_AddOptions(menu_id, voteOptions);
    
    // Action button to initiate vote
    ExtraMenu_AddEntry(menu_id, "4. Initiate Vote", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_VoteAction));
    
    ExtraMenu_NewPage(menu_id);

    ExtraMenu_AddEntry(menu_id, "EQUIPMENT & STATS:", MENU_ENTRY);
    if (!buttons_nums)
    {
        ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    }

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. Get Kit", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_GetKit));
    ExtraMenu_AddOptions(menu_id, "Medic kit|Rambo kit|Counter-terrorist kit|Ninja kit");
    ExtraMenu_AddEntry(menu_id, "2. See your ranking", MENU_SELECT_ONLY);
    optionMap.Push(view_as<int>(Menu_ViewRank));
    ExtraMenu_NewPage(menu_id);

    ExtraMenu_AddEntry(menu_id, "GAME OPTIONS:", MENU_ENTRY);
    if (!buttons_nums)
    {
        ExtraMenu_AddEntry(menu_id, "Use W/S to move row and A/D to select", MENU_ENTRY);
    }

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    ExtraMenu_AddEntry(menu_id, "1. Multiple Equipment Mode: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_MultiEquip));
    ExtraMenu_AddOptions(menu_id, "Off|Single Tap|Double tap");
    ExtraMenu_AddEntry(menu_id, "3. Music player: _OPT_", MENU_SELECT_ONOFF);
    optionMap.Push(view_as<int>(Menu_MusicToggle));
    ExtraMenu_AddEntry(menu_id, "4. Music Volume: _OPT_", MENU_SELECT_LIST);
    optionMap.Push(view_as<int>(Menu_MusicVolume));
    ExtraMenu_AddOptions(menu_id, "----------|#---------|##--------|###-------|####------|#####-----|######----|#######---|########--|#########-|##########");

    ExtraMenu_AddEntry(menu_id, " ", MENU_ENTRY);
    
    // Admin menu link (only shown for admins, checked at display time)
    // Store the index so we can hide it for non-admins
    int adminMenuIndex = optionMap.Length;
    ExtraMenu_AddEntry(menu_id, "Admin Menu", MENU_SELECT_ONLY, true);
    optionMap.Push(view_as<int>(Menu_AdminMenu));
    
    // Store admin menu option index for this menu
    if (includeChangeClass)
    {
        g_iAdminMenuOptionIndexSurvivor = adminMenuIndex;
    }
    else
    {
        g_iAdminMenuOptionIndexInfected = adminMenuIndex;
    }

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

public void SyncMenuSelections(int client, int menuId, ArrayList optionMap)
{
    if (optionMap == null)
    {
        return;
    }

    SyncMenuSelection(client, menuId, optionMap, Menu_ThirdPerson, view_as<int>(g_ThirdPersonMode[client]));
    SyncMenuSelection(client, menuId, optionMap, Menu_ChangeClass, GetSavedClassIndex(client));
    SyncMenuSelection(client, menuId, optionMap, Menu_MultiEquip, view_as<int>(MultiEquip_GetMode(client)));
    
    // Sync team selection (0=AFK, 1=Infected, 2=Survivors)
    int currentTeam = GetClientTeam(client);
    int teamValue = (currentTeam == 0) ? 0 : (currentTeam == 3) ? 1 : 2;
    SyncMenuSelection(client, menuId, optionMap, Menu_SelectTeam, teamValue);
    
    // Sync vote selection
    if (g_iVoteSelection[client] >= 0)
    {
        int voteValue = g_bVoteTypeIsMap[client] ? 0 : (g_iVoteSelection[client] + 1);
        SyncMenuSelection(client, menuId, optionMap, Menu_VoteOptions, voteValue);
    }
}

public void SyncMenuSelection(int client, int menuId, ArrayList optionMap, RageMenuOption option, int value)
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

    // Check if survivor player has selected a class - if not, show class selection menu
    if (GetClientTeam(client) == 2)
    {
        // Get class from saved cookie since we can't access ClientData from this plugin
        int savedClassIndex = GetSavedClassIndex(client);
        ClassTypes currentClass = (savedClassIndex > 0) ? view_as<ClassTypes>(savedClassIndex) : NONE;
        
        // If no class selected, show class selection menu
        if (currentClass == NONE && savedClassIndex == 0)
        {
            FakeClientCommand(client, "sm_class");
            return true;
        }
        
        // If player has a saved class but current class is NONE, try to auto-select it
        if (currentClass == NONE && savedClassIndex > 0)
        {
            ClassTypes savedClass = view_as<ClassTypes>(savedClassIndex);
            // Auto-select the saved class - trigger the class selection command
            // This will use the standard class selection system which will check if class is full
            char cmd[32];
            Format(cmd, sizeof(cmd), "sm_class %d", savedClassIndex);
            FakeClientCommand(client, cmd);
            PrintToChat(client, "%s✓ Your previous \x04%s\x01 class was auto-selected.", 
                       PRINT_PREFIX, MENU_OPTIONS[savedClass]);
        }
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
        PrintHintText(client, "Hold SHIFT to open menu; type !rage_bind for key binding help; use W/S/A/D to navigate.");
    }

    ExtraMenu_Display(client, menuId, MENU_TIME_FOREVER);
    return true;
}

public void DisplayQuickActionMenu(int client)
{
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
    {
        return;
    }

    // Get class from saved cookie since we can't access ClientData from this plugin
    int savedClassIndex = GetSavedClassIndex(client);
    ClassTypes classType = (savedClassIndex > 0) ? view_as<ClassTypes>(savedClassIndex) : NONE;
    if (classType == NONE)
    {
        PrintHintText(client, "Select a class first!");
        return;
    }

    // Close any existing menu
    if (g_hQuickActionMenu[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hQuickActionMenu[client]);
        g_hQuickActionMenu[client] = INVALID_HANDLE;
    }

    Menu menu = CreateMenu(MenuHandler_QuickAction);
    char title[128];
    Format(title, sizeof(title), "Quick Actions - %s", MENU_OPTIONS[classType]);
    SetMenuTitle(menu, title);
    
    // Add menu items - use generic names since we can't access private variables from rage_survivor.sp
    // The actual skill names will be shown when the skill is used
    AddMenuItem(menu, "deploy", "1. Deploy");
    AddMenuItem(menu, "skill1", "2. Skill Action 1");
    AddMenuItem(menu, "skill2", "3. Skill Action 2");
    AddMenuItem(menu, "skill3", "4. Skill Action 3");
    
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 10);
    g_hQuickActionMenu[client] = menu;
    g_bQuickActionMenuOpen[client] = true;
}

public int MenuHandler_QuickAction(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            
            // Get class from saved cookie since we can't access ClientData from this plugin
            int savedClassIndex = GetSavedClassIndex(param1);
            ClassTypes classType = (savedClassIndex > 0) ? view_as<ClassTypes>(savedClassIndex) : NONE;
            if (classType == NONE)
            {
                CloseQuickActionMenu(param1);
                return 0;
            }
            
            if (StrEqual(info, "deploy"))
            {
                TryExecuteSkillInput(param1, ClassSkill_Deploy);
            }
            else if (StrEqual(info, "skill1"))
            {
                TryExecuteSkillInput(param1, ClassSkill_Special);
            }
            else if (StrEqual(info, "skill2"))
            {
                TryExecuteSkillInput(param1, ClassSkill_Secondary);
            }
            else if (StrEqual(info, "skill3"))
            {
                TryExecuteSkillInput(param1, ClassSkill_Tertiary);
            }
            
            CloseQuickActionMenu(param1);
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

public void CloseQuickActionMenu(int client)
{
    if (g_hQuickActionMenu[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hQuickActionMenu[client]);
        g_hQuickActionMenu[client] = INVALID_HANDLE;
    }
    g_bQuickActionMenuOpen[client] = false;
}

// GetActionDisplayName removed - cannot access private variables from rage_survivor.sp
// Using generic menu item names instead

