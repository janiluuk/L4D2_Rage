#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <rage/skill_actions>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "[Rage] Tutorial Guide",
    author = "Yani",
    description = "Interactive tutorial that explains Rage classes, skills and commands.",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/groups/RageGaming"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_ragetutorial", CmdGuideMenu, "Open the Rage tutorial guide");

    CreateNative("RageGuide_ShowMainMenu", Native_ShowGuideMenu);
    RegPluginLibrary("rage_survivor_guide");

    LoadSkillActionBindings();
}

public void OnConfigsExecuted()
{
    LoadSkillActionBindings();
}

public int Native_ShowGuideMenu(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (IsValidPlayer(client))
    {
        DisplayGuideMainMenu(client);
    }
    return 0;
}

public Action CmdGuideMenu(int client, int args)
{
    if (!IsValidPlayer(client))
    {
        PrintToServer("[Rage] This command can only be used in-game.");
        return Plugin_Handled;
    }

    DisplayGuideMainMenu(client);
    return Plugin_Handled;
}

bool IsValidPlayer(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

void PrintGuideLine(int client, const char[] message)
{
    PrintToChat(client, "\x04[Rage]\x01 %s", message);
}

void GetBindingStrings(char[] action1, int len1, char[] action2, int len2, char[] action3, int len3, char[] deploy, int len4)
{
    GetSkillActionBindingLabel(SkillAction_Primary, action1, len1);
    GetSkillActionBindingLabel(SkillAction_Secondary, action2, len2);
    GetSkillActionBindingLabel(SkillAction_Tertiary, action3, len3);
    GetSkillActionBindingLabel(SkillAction_Deploy, deploy, len4);
}

void DisplayGuideMainMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_GuideMain);
    SetMenuTitle(menu, "Rage Tutorial Guide");
    AddMenuItem(menu, "overview", "Quick start & how to open this guide");
    AddMenuItem(menu, "classes", "Survivor class guides");
    AddMenuItem(menu, "controls", "Controls & core features");
    AddMenuItem(menu, "skills", "Skills & deployables");
    AddMenuItem(menu, "gamemodes", "Game modes overview");
    AddMenuItem(menu, "tips", "Gameplay tips");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GuideMain(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Rage Edition is a modular class overhaul with perk-driven abilities.");
                PrintGuideLine(param1, "Open this tutorial anytime with !guide or the Rage admin menu.");
                PrintGuideLine(param1, "Pick a class, bind the four actions, and coordinate before leaving the saferoom.");
                PrintGuideLine(param1, "Defaults: middle mouse, Use+Fire, Crouch+Use+Fire, look down + Shift.");
                DisplayGuideMainMenu(param1);
            }
            else if (StrEqual(info, "classes"))
            {
                DisplayClassListMenu(param1);
            }
            else if (StrEqual(info, "controls"))
            {
                DisplayControlsMenu(param1);
            }
            else if (StrEqual(info, "skills"))
            {
                DisplaySkillMenu(param1);
            }
            else if (StrEqual(info, "gamemodes"))
            {
                DisplayGameModeMenu(param1);
            }
            else if (StrEqual(info, "tips"))
            {
                DisplayTipsMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayClassListMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_ClassList);
    SetMenuTitle(menu, "Survivor Classes");
    AddMenuItem(menu, "soldier", "Soldier (frontline tank)");
    AddMenuItem(menu, "athlete", "Athlete (movement expert)");
    AddMenuItem(menu, "commando", "Commando (damage specialist)");
    AddMenuItem(menu, "medic", "Medic (team sustain)");
    AddMenuItem(menu, "engineer", "Engineer (builder)");
    AddMenuItem(menu, "saboteur", "Saboteur (stealth scout)");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void DisplayControlsMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Controls);
    SetMenuTitle(menu, "Controls & Core Features");
    AddMenuItem(menu, "skillkeys", "Skill & deploy buttons");
    AddMenuItem(menu, "thirdperson", "Third-person camera");
    AddMenuItem(menu, "hudmusic", "HUD & music toggles");
    AddMenuItem(menu, "binds", "Quick binds & chat commands");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Controls(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "skillkeys"))
            {
                PrintGuideLine(param1, "Bind skill_action_1/2/3 + deployment_action so you can react without typing.");
                PrintGuideLine(param1, "Defaults: middle mouse, Use+Fire, Crouch+Use+Fire, look down + Shift.");
                DisplayControlsMenu(param1);
            }
            else if (StrEqual(info, "thirdperson"))
            {
                PrintGuideLine(param1, "Open !rage > Third person to pick Off, Melee only, or Always. Choice saves between rounds.");
                DisplayControlsMenu(param1);
            }
            else if (StrEqual(info, "hudmusic"))
            {
                PrintGuideLine(param1, "Use the admin menu to toggle the HUD overlay and enable/disable custom music.");
                DisplayControlsMenu(param1);
            }
            else if (StrEqual(info, "binds"))
            {
                PrintGuideLine(param1, "Handy binds: skill_action_1/2/3, deployment_action, !music, !unvomit, !extendedsight.");
                DisplayControlsMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

public int MenuHandler_ClassList(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "soldier"))
            {
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "athlete"))
            {
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "commando"))
            {
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "medic"))
            {
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "engineer"))
            {
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "saboteur"))
            {
                DisplaySaboteurMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayFeaturesMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Features);
    SetMenuTitle(menu, "Controls & Features");
    AddMenuItem(menu, "access", "Open the tutorial & binds");
    AddMenuItem(menu, "skill", "Skill / deploy buttons");
    AddMenuItem(menu, "thirdperson", "Third person camera");
    AddMenuItem(menu, "grenades", "Prototype grenade types");
    AddMenuItem(menu, "gamemodes", "Game mode voting");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Features(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "access"))
            {
                PrintGuideLine(param1, "Use !guide or !ragetutorial, or open the Rage menu and pick \"Open Rage tutorial guide\" any time.");
            }
            else if (StrEqual(info, "skill"))
            {
                char action1[64], action2[64], action3[64], deploy[64];
                char skillLine[192];
                GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
                Format(skillLine, sizeof(skillLine), "Bind %s, %s and %s for class abilities and use %s to place turrets, shields and mines.", action1, action2, action3, deploy);
                PrintGuideLine(param1, skillLine);
            }
            else if (StrEqual(info, "thirdperson"))
            {
                PrintGuideLine(param1, "In the Rage menu set camera to Off, Melee only or Always to toggle third person shoulder view.");
            }
            else if (StrEqual(info, "grenades"))
            {
                PrintGuideLine(param1, "Hold FIRE and tap SHOVE with any grenade to cycle prototypes like fire, freeze, weapon drop or airstrike payloads.");
            }
            else if (StrEqual(info, "gamemodes"))
            {
                PrintGuideLine(param1, "Admins open !rage, choose Vote for gamemode, then pick Versus, Scavenge, Survival or custom Rage modes.");
            }
            DisplayFeaturesMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplaySoldierMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Soldier);
    SetMenuTitle(menu, "Soldier Guide");
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "airstrike", "Active skill: Airstrike");
    AddMenuItem(menu, "weapons", "Passives: Weapons & toughness");
    AddMenuItem(menu, "nightvision", "Utility: Night vision");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Soldier(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Soldiers run faster, shrug off damage and anchor the front so others can push objectives.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "skill"))
            {
                PrintGuideLine(param1, "Aim at a target and press skill_action_1 (default: middle mouse) to call the F-18 barrage. Warn teammates before painting and keep sight on the mark.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "utility"))
            {
                PrintGuideLine(param1, "Faster weapon handling and melee stagger let you bully commons while absorbing chip damage for the team.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "tips"))
            {
                PrintGuideLine(param1, "Toggle night vision with N (or sm_nightvision) to scout storms, spot spawns and watch flanks.");
                DisplaySoldierMenu(param1);
            }
            DisplaySoldierMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayAthleteMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Athlete);
    SetMenuTitle(menu, "Athlete Guide");
    AddMenuItem(menu, "mobility", "Role & mobility perks");
    AddMenuItem(menu, "parachute", "Air control & parachute");
    AddMenuItem(menu, "ninja", "Active skill: Ninja kick");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Athlete(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Athletes sprint faster with bunnyhop, double jump, long jump and high jump tools for objective play.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "mobility"))
            {
                PrintGuideLine(param1, "Hold USE in mid-air to pop the parachute, glide safely and chain long jumps without fall damage.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "skill"))
            {
                PrintGuideLine(param1, "Sprint + JUMP together to launch a ninja kick that knocks infected down and opens a gap.");
                DisplayAthleteMenu(param1);
            }
            DisplayAthleteMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayCommandoMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Commando);
    SetMenuTitle(menu, "Commando Guide");
    AddMenuItem(menu, "damage", "Role & damage tuning");
    AddMenuItem(menu, "satellite", "Active skill: Satellite cannon");
    AddMenuItem(menu, "berserk", "Berserk meter");
    AddMenuItem(menu, "reload", "Passives: Reload & finishers");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Commando(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Commandos flex between rifles, shotguns and SMGs with baked-in damage bonuses for each slot.");
            }
            else if (StrEqual(info, "berserk"))
            {
                PrintGuideLine(param1, "Use skill_action_1 (default: middle mouse) for the satellite strike instead of the F-18. Berserk stays on secondary, so warn teammates before painting the zone.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "satellite"))
            {
                PrintGuideLine(param1, "Build rage by dealing damage, then press skill_action_1 or !berserker to enter Berserk for huge speed and tank immunity.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "finishers"))
            {
                PrintGuideLine(param1, "Faster reloads and ground finishers reward aggression. Sprint forward to execute specials before they recover.");
                DisplayCommandoMenu(param1);
            }
            DisplayCommandoMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayMedicMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Medic);
    SetMenuTitle(menu, "Medic Guide");
    AddMenuItem(menu, "aura", "Role & healing aura");
    AddMenuItem(menu, "orbs", "Active skill: Healing orbs");
    AddMenuItem(menu, "support", "Utility: Revive & cleanse");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Medic(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Medics pulse heals to nearby survivors and move faster while healing - stay near the front line.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "orbs"))
            {
                PrintGuideLine(param1, "Use your secondary skill_action_2 (default: Use+Fire) to toss glowing healing orbs and drop med items between fights.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "support"))
            {
                PrintGuideLine(param1, "Faster revive and heal speeds plus the !unvomit cleanse make you the antidote to bile or chip damage.");
            }
            DisplayMedicMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayEngineerMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Engineer);
    SetMenuTitle(menu, "Engineer Guide");
    AddMenuItem(menu, "kits", "Role & upgrade kits");
    AddMenuItem(menu, "turrets", "Active skill: Turret workshop");
    AddMenuItem(menu, "defense", "Utility: Defenses & pickups");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Engineer(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Engineers fortify pushes with build kits, deployables and turrets that hold choke points.");
            }
            else if (StrEqual(info, "deploy"))
            {
                PrintGuideLine(param1, "Use skill_action_1 (default: middle mouse) to open the turret menu, pick a gun and ammo, left-click to deploy and press USE to pick it up.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "defense"))
            {
                PrintGuideLine(param1, "Deploy shields, laser grids and barricades. Turrets are non-blocking but can be detonated if infected overrun them.");
            }
            DisplayEngineerMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplaySaboteurMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Saboteur);
    SetMenuTitle(menu, "Saboteur Guide");
    AddMenuItem(menu, "stealth", "Active skill: Cloak & stealth");
    AddMenuItem(menu, "sight", "Utility: Extended sight");
    AddMenuItem(menu, "mines", "Gadgets & mines");
    AddMenuItem(menu, "damage", "Damage profile");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Saboteur(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Use skill_action_1 (default: middle mouse) to vanish with the Dead Ringer, drop a fake corpse and sprint past ambushes.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "sight"))
            {
                PrintGuideLine(param1, "!extendedsight highlights special infected for 20 seconds every two minutes - call targets for your team.");
            }
            else if (StrEqual(info, "mines"))
            {
                char minesLine[192];
                Format(minesLine, sizeof(minesLine), "Use %s to plant up to twenty mine types ranging from freeze traps to airstrikes. Mines glow to warn teammates.", deploy);
                PrintGuideLine(param1, minesLine);
            }
            else if (StrEqual(info, "tips"))
            {
                PrintGuideLine(param1, "Paint sight lines, bait specials with a fake death, then mine their retreat for pick-offs.");
            }
            DisplaySaboteurMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayClassListMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplaySkillMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Skills);
    SetMenuTitle(menu, "Skills & Deployables");
    AddMenuItem(menu, "sheet", "Skill quick sheet (all classes)");
    AddMenuItem(menu, "grenades", "Prototype grenade wheel");
    AddMenuItem(menu, "healingorb", "Medic healing orb");
    AddMenuItem(menu, "turrets", "Engineer turrets");
    AddMenuItem(menu, "mines", "Saboteur mines");
    AddMenuItem(menu, "recon", "Recon tools (cloak & sight)");
    AddMenuItem(menu, "airsupport", "Airstrike & satellite");
    AddMenuItem(menu, "support", "Support commands");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Skills(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "sheet"))
            {
                PrintGuideLine(param1, "Quick skill sheet:");
                PrintGuideLine(param1, "Soldier: skill_action_1 (middle mouse by default) marks an F-18 airstrike where you aim. Hold sight until jets finish.");
                PrintGuideLine(param1, "Commando: build rage with damage, then press skill_action_1 for the satellite cannon or !berserker for a speed burst.");
                PrintGuideLine(param1, "Athlete: sprint + jump together for the ninja kick gap opener; hold USE mid-air to deploy the parachute.");
                PrintGuideLine(param1, "Medic: tap skill_action_2 (Use+Fire) to throw a healing orb; stay near teammates for the healing aura.");
                PrintGuideLine(param1, "Engineer: press skill_action_1 (middle mouse) to pick a turret and ammo, left-click to place, USE to pack it up.");
                PrintGuideLine(param1, "Saboteur: skill_action_1 drops a fake corpse and cloaks you; hold SHIFT to plant mines, and !extendedsight pings specials for 20s.");
            }
            else if (StrEqual(info, "grenades"))
            {
                PrintGuideLine(param1, "Equip any grenade, hold FIRE and tap SHOVE (or use sm_grenade) to cycle through experimental prototypes before throwing.");
            }
            else if (StrEqual(info, "healingorb"))
            {
                PrintGuideLine(param1, "Medics use their secondary skill_action_2 (Use+Fire) to toss glowing healing orbs that top off teammates between fights.");
            }
            else if (StrEqual(info, "turrets"))
            {
                PrintGuideLine(param1, "Engineers open the turret picker with skill_action_1 (middle mouse), choose turret + ammo, left-click to place and USE to pack it up.");
            }
            else if (StrEqual(info, "mines"))
            {
                PrintGuideLine(param1, "Saboteurs hold SHIFT to plant up to twenty mine types ranging from freeze traps to airstrikes. Mines glow to warn teammates.");
            }
            else if (StrEqual(info, "recon"))
            {
                PrintGuideLine(param1, "Saboteurs use skill_action_1 for the decoy cloak and !extendedsight to ping specials through walls for 20 seconds.");
            }
            else if (StrEqual(info, "airsupport"))
            {
                PrintGuideLine(param1, "Soldiers press skill_action_1 to mark an F-18 airstrike, while Commandos use skill_action_1 for the satellite cannon once rage is ready.");
            }
            else if (StrEqual(info, "support"))
            {
                PrintGuideLine(param1, "Quick helpers: !music to manage custom tracks, !unvomit for Medic bile cleanse, and !berserker for the Commando rage burst.");
            }
            DisplaySkillMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayGameModeMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_GameModes);
    SetMenuTitle(menu, "Game Modes");
    AddMenuItem(menu, "versus", "Versus variants");
    AddMenuItem(menu, "objective", "Objective modes");
    AddMenuItem(menu, "rage", "Rage customs");
    AddMenuItem(menu, "switch", "How to switch modes");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GameModes(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "versus"))
            {
                PrintGuideLine(param1, "Versus, Team Versus and Competitive variants keep the classic flow with extra perks and balance tweaks.");
            }
            else if (StrEqual(info, "objective"))
            {
                PrintGuideLine(param1, "Scavenge, Team Scavenge, Survival, Co-op and Realism are all playable through the game menu.");
            }
            else if (StrEqual(info, "rage"))
            {
                PrintGuideLine(param1, "Escort Run, Deathmatch and Race Jockey are custom Rage chaos modes - experiment when you want a break from Versus.");
            }
            else if (StrEqual(info, "switch"))
            {
                PrintGuideLine(param1, "Admins open !rage then pick \"Vote for gamemode\" to swap modes and can return to Versus at any time.");
            }
            DisplayGameModeMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}

void DisplayTipsMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Tips);
    SetMenuTitle(menu, "Gameplay Tips");
    AddMenuItem(menu, "team", "Team composition");
    AddMenuItem(menu, "resources", "Resource flow");
    AddMenuItem(menu, "hud", "HUD & music");
    AddMenuItem(menu, "shortcuts", "Command shortcuts");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Tips(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "team"))
            {
                PrintGuideLine(param1, "Mix roles - Soldier tanks, Medic heals, Engineer builds cover, Saboteur scouts and Athlete runs objectives.");
            }
            else if (StrEqual(info, "resources"))
            {
                PrintGuideLine(param1, "Medics drop orbs, Engineers deploy kits and Saboteurs plant mines. Communicate so nothing goes to waste.");
            }
            else if (StrEqual(info, "hud"))
            {
                PrintGuideLine(param1, "Toggle the HUD or music player from the admin menu to match your focus for each round.");
            }
            else if (StrEqual(info, "shortcuts"))
            {
                PrintGuideLine(param1, "Bind skill_action_1/2/3 plus deployment_action, and add shortcuts for !music, !unvomit, !extendedsight and !ragetutorial for instant access mid-fight.");
            }
            DisplayTipsMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGuideMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
    return 0;
}
