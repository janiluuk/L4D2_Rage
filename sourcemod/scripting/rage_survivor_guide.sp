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
    AddMenuItem(menu, "overview", "What is Rage Edition?");
    AddMenuItem(menu, "classes", "Survivor class guides");
    AddMenuItem(menu, "features", "Controls & features");
    AddMenuItem(menu, "skills", "Special skills & commands");
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
                PrintGuideLine(param1, "Rage Edition is a modular class overhaul for Left 4 Dead 2 with perk-driven gameplay.");
                char action1[64], action2[64], action3[64], deploy[64];
                char overviewLine[192];
                GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
                Format(overviewLine, sizeof(overviewLine), "Every survivor picks a class with unique passives plus abilities bound to %s, %s, and %s, so coordinate before leaving the saferoom.", action1, action2, action3);
                PrintGuideLine(param1, overviewLine);
                DisplayGuideMainMenu(param1);
            }
            else if (StrEqual(info, "classes"))
            {
                DisplayClassListMenu(param1);
            }
            else if (StrEqual(info, "features"))
            {
                DisplayFeaturesMenu(param1);
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
    AddMenuItem(menu, "soldier", "Soldier");
    AddMenuItem(menu, "athlete", "Athlete");
    AddMenuItem(menu, "commando", "Commando");
    AddMenuItem(menu, "medic", "Medic");
    AddMenuItem(menu, "engineer", "Engineer");
    AddMenuItem(menu, "saboteur", "Saboteur");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
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
    AddMenuItem(menu, "skill", "Signature skill");
    AddMenuItem(menu, "utility", "Utility tools");
    AddMenuItem(menu, "tips", "Simple play tips");
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
                PrintGuideLine(param1, "Soldiers run faster, shrug off damage and excel as the frontline tank for the squad.");
            }
            else if (StrEqual(info, "skill"))
            {
                char skillLine[160];
                Format(skillLine, sizeof(skillLine), "Aim at a target and press %s to call in the F-18 missile barrage. Give teammates a warning before painting.", action1);
                PrintGuideLine(param1, skillLine);
            }
            else if (StrEqual(info, "utility"))
            {
                PrintGuideLine(param1, "Rapid weapon swaps, sturdy armor and night vision make Soldiers steady anchors when the horde spikes.");
            }
            else if (StrEqual(info, "tips"))
            {
                PrintGuideLine(param1, "Ping your strike zone, then cover the splash with shotguns or melee while rockets land.");
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
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "mobility", "Mobility perks");
    AddMenuItem(menu, "skill", "Ninja kick skill");
    AddMenuItem(menu, "tips", "Simple play tips");
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
                PrintGuideLine(param1, "Athletes are objective runners with the fastest sprint, long jumps and extra stamina.");
            }
            else if (StrEqual(info, "mobility"))
            {
                PrintGuideLine(param1, "Bunnyhop, double jump, long jump and parachute glide keep you ahead of chokepoints and hazards.");
            }
            else if (StrEqual(info, "skill"))
            {
                PrintGuideLine(param1, "Sprint + JUMP together to launch a ninja kick that clears commons and staggers specials.");
            }
            else if (StrEqual(info, "tips"))
            {
                PrintGuideLine(param1, "Scout ahead, drop a parachute when ambushed and kick back toward teammates to regroup.");
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
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "berserk", "Berserk mode");
    AddMenuItem(menu, "satellite", "Signature skill");
    AddMenuItem(menu, "finishers", "Reload & finishers");
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
                char berserkLine[192];
                Format(berserkLine, sizeof(berserkLine), "Build rage by dealing damage, then press %s (or the berserker shortcut) to enter Berserk for huge speed and tank immunity.", action2);
                PrintGuideLine(param1, berserkLine);
            }
            else if (StrEqual(info, "satellite"))
            {
                char satelliteLine[192];
                Format(satelliteLine, sizeof(satelliteLine), "Use %s for a satellite strike instead of the F-18 barrage. Call targets and clear the circle.", action1);
                PrintGuideLine(param1, satelliteLine);
            }
            else if (StrEqual(info, "finishers"))
            {
                PrintGuideLine(param1, "Fast reloads and execution kicks finish specials quickly—stay aggressive while Berserk is ready.");
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
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "skill", "Healing skill");
    AddMenuItem(menu, "orbs", "Healing orbs & drops");
    AddMenuItem(menu, "support", "Revive & cleanse");
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
                PrintGuideLine(param1, "Medics pulse heals to nearby survivors and thrive when glued to the front line.");
            }
            else if (StrEqual(info, "skill"))
            {
                char boostLine[192];
                Format(boostLine, sizeof(boostLine), "Your %s boosts every heal—kits and pills restore more and you move faster while supporting.", action1);
                PrintGuideLine(param1, boostLine);
            }
            else if (StrEqual(info, "orbs"))
            {
                char orbLine[192];
                Format(orbLine, sizeof(orbLine), "Use %s to toss healing orbs that glow and ping the team. You can also drop med items for others.", action2);
                PrintGuideLine(param1, orbLine);
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
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "deploy", "Deploy tools");
    AddMenuItem(menu, "skill", "Turret workshop");
    AddMenuItem(menu, "defense", "Defensive tools");
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
                char deployLine[192];
                Format(deployLine, sizeof(deployLine), "%s opens the build wheel: choose deployable types, place them, then reclaim with USE when safe.", action1);
                PrintGuideLine(param1, deployLine);
            }
            else if (StrEqual(info, "skill"))
            {
                char turretLine[192];
                Format(turretLine, sizeof(turretLine), "Use %s to open the turret menu, pick a gun and ammo, left-click to deploy and press USE to pick it up.", action1);
                PrintGuideLine(param1, turretLine);
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
    AddMenuItem(menu, "overview", "Role overview");
    AddMenuItem(menu, "stealth", "Cloak skill");
    AddMenuItem(menu, "sight", "Extended sight");
    AddMenuItem(menu, "mines", "Mines & gadgets");
    AddMenuItem(menu, "tips", "Simple play tips");
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
                PrintGuideLine(param1, "Saboteurs scout ahead with lower gun damage but brutal gadgets that control space.");
            }
            else if (StrEqual(info, "stealth"))
            {
                char stealthLine[192];
                Format(stealthLine, sizeof(stealthLine), "Use the Dead Ringer %s trigger to vanish, drop a fake corpse and sprint past ambushes.", action1);
                PrintGuideLine(param1, stealthLine);
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
    SetMenuTitle(menu, "Special Skills & Commands");
    AddMenuItem(menu, "skill", "Class skill command");
    AddMenuItem(menu, "grenades", "Grenades");
    AddMenuItem(menu, "healingorb", "Healing orb toss");
    AddMenuItem(menu, "deadringer", "Dead Ringer");
    AddMenuItem(menu, "sight", "Extended sight");
    AddMenuItem(menu, "multiturret", "Multiturret controls");
    AddMenuItem(menu, "music", "Music player");
    AddMenuItem(menu, "unvomit", "Unvomit cleanse");
    AddMenuItem(menu, "berserk", "Berserk reminders");
    AddMenuItem(menu, "satellite", "Satellite cannon");
    AddMenuItem(menu, "airstrike", "Airstrike reminders");
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
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "skill"))
            {
                char bindLine[192];
                Format(bindLine, sizeof(bindLine), "Bind keys to %s, %s and %s to trigger your class abilities consistently every round.", action1, action2, action3);
                PrintGuideLine(param1, bindLine);
            }
            else if (StrEqual(info, "grenades"))
            {
                PrintGuideLine(param1, "Equip any grenade, hold FIRE and tap SHOVE (or use sm_grenade) to cycle through grenade types.");
            }
            else if (StrEqual(info, "healingorb"))
            {
                char orbLine[192];
                Format(orbLine, sizeof(orbLine), "Medics use %s to throw a glowing healing orb from the main skills plugin. Toss it between fights to top the team off.", action2);
                PrintGuideLine(param1, orbLine);
            }
            else if (StrEqual(info, "deadringer"))
            {
                PrintGuideLine(param1, "Saboteurs can type !fd or !cloak to drop a fake corpse, gain invisibility and reset aggro.");
            }
            else if (StrEqual(info, "sight"))
            {
                PrintGuideLine(param1, "!extendedsight paints special infected through walls for 20 seconds with a two-minute cooldown.");
            }
            else if (StrEqual(info, "multiturret"))
            {
                char turretLine[192];
                Format(turretLine, sizeof(turretLine), "Engineers open the turret picker with %s, choose turret + ammo, left-click to place and USE to pick up.", action1);
                PrintGuideLine(param1, turretLine);
            }
            else if (StrEqual(info, "music"))
            {
                PrintGuideLine(param1, "Type !music to opt into custom tracks, adjust volume or disable songs per map.");
            }
            else if (StrEqual(info, "unvomit"))
            {
                PrintGuideLine(param1, "Medics can cleanse Boomer bile with !unvomit to keep survivors firing.");
            }
            else if (StrEqual(info, "berserk"))
            {
                char berserkLine[192];
                Format(berserkLine, sizeof(berserkLine), "Commandos hit !berserker or %s once rage is full. Berserk grants burst damage and immunity to tank knockdowns.", action2);
                PrintGuideLine(param1, berserkLine);
            }
            else if (StrEqual(info, "satellite"))
            {
                PrintGuideLine(param1, "Commandos call the satellite cannon with their class skill while Berserk stays on secondary. Expect a short startup before the orbital blast lands.");
            }
            else if (StrEqual(info, "airstrike"))
            {
                char airstrikeLine[192];
                Format(airstrikeLine, sizeof(airstrikeLine), "Soldiers aim and press %s to mark a strike zone; warn teammates before raining missiles.", action1);
                PrintGuideLine(param1, airstrikeLine);
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
                char shortcutLine[192];
                Format(shortcutLine, sizeof(shortcutLine), "Bind %s, %s and %s alongside music, unvomit, extended sight and tutorial shortcuts for instant access mid-fight.", action1, action2, action3);
                PrintGuideLine(param1, shortcutLine);
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
