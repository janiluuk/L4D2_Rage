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
    AddMenuItem(menu, "predicaments", "Predicaments: Survival mechanics");
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
                PrintGuideLine(param1, "Open this tutorial anytime with !guide, !ragetutorial or the Rage menu.");
                PrintGuideLine(param1, "Hold SHIFT to show the quick menu and use WASD to select.");
                PrintGuideLine(param1, "Pick a class, bind the four actions, and coordinate before leaving the saferoom.");
                PrintGuideLine(param1, "Defaults: middle mouse, Use+Fire, Crouch+Use+Fire, Hold CTRL.");
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
            else if (StrEqual(info, "predicaments"))
            {
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "gamemodes"))
            {
                DisplayGameModesMenu(param1);
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
    AddMenuItem(menu, "menu", "Quick menu (SHIFT + WASD)");
    AddMenuItem(menu, "skillkeys", "Skill & deploy buttons");
    AddMenuItem(menu, "thirdperson", "Third-person camera");
    AddMenuItem(menu, "hudmusic", "HUD & music toggles");
    AddMenuItem(menu, "afkmode", "AFK/away toggle");
    AddMenuItem(menu, "equipment", "Multiple equipment mode");
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
            if (StrEqual(info, "menu"))
            {
                PrintGuideLine(param1, "Hold SHIFT to show the quick menu and navigate with WASD.");
                PrintGuideLine(param1, "Release SHIFT to exit the menu. You can trigger class actions from the menu too.");
                DisplayControlsMenu(param1);
            }
            else if (StrEqual(info, "skillkeys"))
            {
                PrintGuideLine(param1, "Bind skill_action_1/2/3 + deployment_action so you can react without typing.");
                PrintGuideLine(param1, "Defaults: middle mouse, Use+Fire, Crouch+Use+Fire, Hold CTRL.");
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
            else if (StrEqual(info, "afkmode"))
            {
                PrintGuideLine(param1, "Mark yourself AFK directly from the Rage menu when you need a break.");
                PrintGuideLine(param1, "Your status will be visible to teammates and you can toggle back when ready.");
                DisplayControlsMenu(param1);
            }
            else if (StrEqual(info, "equipment"))
            {
                PrintGuideLine(param1, "Multiple equipment mode lets you pick how forgiving pickups are.");
                PrintGuideLine(param1, "Choose between classic single-use kits or double-tap weapon swaps from the settings.");
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
    AddMenuItem(menu, "satellite", "Skill 1: Satellite Strike");
    AddMenuItem(menu, "chainlightning", "Skill 2: Chain Lightning");
    AddMenuItem(menu, "zedtime", "Skill 3: Zed Time");
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
                PrintGuideLine(param1, "Increased health pool makes you the team tank. Lead the charge and draw fire.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "satellite"))
            {
                char line[256];
                Format(line, sizeof(line), "Aim at a target and press %s to call the Satellite Strike. Warn teammates before painting.", action1);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Massive orbital strike with devastating area damage. Works best in outdoor areas.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "chainlightning"))
            {
                char line[256];
                Format(line, sizeof(line), "Aim at an enemy and press %s to unleash chain lightning that jumps between targets.", action2);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Lightning chains up to 5 times, dealing damage with falloff. Perfect for clearing groups!");
                PrintGuideLine(param1, "Each chain jumps to the nearest enemy within range, creating devastating area damage.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "zedtime"))
            {
                char line[256];
                Format(line, sizeof(line), "Press %s to activate Zed Time - slow motion that affects all players.", action3);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Time slows to 30% speed for 5 seconds, giving you and your team a tactical advantage.");
                PrintGuideLine(param1, "Perfect for clutch moments, escaping tight situations, or landing precise shots.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "weapons"))
            {
                PrintGuideLine(param1, "Faster weapon handling and melee attacks let you bully commons while absorbing chip damage.");
                PrintGuideLine(param1, "Your movement speed boost (15% faster than normal) helps you reposition and protect vulnerable teammates.");
                PrintGuideLine(param1, "Enhanced armor reduces incoming damage, making you tough as nails on the front line.");
                DisplaySoldierMenu(param1);
            }
            else if (StrEqual(info, "nightvision"))
            {
                PrintGuideLine(param1, "Toggle night vision with N (or !nightvision) to scout in darkness, spot spawns and watch flanks.");
                PrintGuideLine(param1, "Essential for dark maps and indoor sections where visibility is low.");
                DisplaySoldierMenu(param1);
            }
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
    AddMenuItem(menu, "ninja", "Active skill: Ninja kick");
    AddMenuItem(menu, "blink", "Skill: Blink teleport");
    AddMenuItem(menu, "parachute", "Passive: Parachute");
    AddMenuItem(menu, "grenades", "Antigravity grenades");
    AddMenuItem(menu, "movement", "Advanced movement: jumps & parkour");
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
            char action1[64], action2[64], action3[64], deploy[64];
            GetBindingStrings(action1, sizeof(action1), action2, sizeof(action2), action3, sizeof(action3), deploy, sizeof(deploy));
            if (StrEqual(info, "mobility"))
            {
                PrintGuideLine(param1, "Athletes sprint faster with bunnyhop, double jump, long jump and high jump tools for objective play.");
                PrintGuideLine(param1, "Built for motion - use your speed to scout ahead, grab supplies and reach objectives first.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "ninja"))
            {
                PrintGuideLine(param1, "Sprint + JUMP together to launch a ninja kick that knocks infected down and opens a gap.");
                PrintGuideLine(param1, "Perfect for crowd control and creating space for your team to push through hordes.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "blink"))
            {
                char line[256];
                Format(line, sizeof(line), "Press %s to blink teleport forward - perfect for quick escapes and repositioning.", action2);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Aim where you want to go and blink instantly. Great for dodging special infected or repositioning during fights.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "parachute"))
            {
                PrintGuideLine(param1, "Hold USE in mid-air to pop the parachute, glide safely and chain long jumps without fall damage.");
                PrintGuideLine(param1, "This is a passive ability - always available when falling, no cooldown. Essential for escaping bad situations.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "grenades"))
            {
                PrintGuideLine(param1, "Throw antigravity grenades that lift and suspend infected, giving your team time to reposition.");
                PrintGuideLine(param1, "Excellent for controlling choke points and disrupting infected swarms.");
                DisplayAthleteMenu(param1);
            }
            else if (StrEqual(info, "movement"))
            {
                PrintGuideLine(param1, "Athletes excel at parkour with double jump, long jump, high jump, and bunnyhop capabilities.");
                PrintGuideLine(param1, "Wall run automatically activates when you jump near walls - run along them with W/S, climb with JUMP.");
                PrintGuideLine(param1, "Your superior mobility makes you perfect for objective runs and scouting ahead safely.");
                DisplayAthleteMenu(param1);
            }
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
    AddMenuItem(menu, "berserk", "Berserk meter & rage mode");
    AddMenuItem(menu, "missiles", "Dummy & Homing Missiles");
    AddMenuItem(menu, "reload", "Passives: Reload & finishers");
    AddMenuItem(menu, "tank", "Tank knockdowns");
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
            if (StrEqual(info, "damage"))
            {
                PrintGuideLine(param1, "Commandos flex between rifles, shotguns and SMGs with baked-in damage bonuses for each slot.");
                PrintGuideLine(param1, "Increased damage per weapon makes you the team's primary damage dealer. Lots of health too!");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "berserk"))
            {
                char line[256];
                Format(line, sizeof(line), "Build rage by dealing damage, then press %s or !berserker to enter Berserk mode.", action1);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Berserk grants huge speed boost and tank immunity - use it to melt specials and tanks.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "missiles"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s for Dummy Missile (decoy) and %s for Homing Missile (tracking).", action2, action3);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Dummy Missiles distract enemies while Homing Missiles track and eliminate threats.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "reload"))
            {
                PrintGuideLine(param1, "Faster reloads and ground finishers reward aggression. Sprint forward to execute specials before they recover.");
                PrintGuideLine(param1, "Your reload speed lets you maintain pressure without exposing the team to counterattacks.");
                DisplayCommandoMenu(param1);
            }
            else if (StrEqual(info, "tank"))
            {
                PrintGuideLine(param1, "Commandos can perform tank knockdowns with melee attacks when the tank is vulnerable.");
                PrintGuideLine(param1, "Time your melees during tank recovery frames to knock it down and give your team breathing room.");
                DisplayCommandoMenu(param1);
            }
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
    AddMenuItem(menu, "grenades", "Skill 1: Healing grenades");
    AddMenuItem(menu, "orbs", "Skill 2: Healing orbs");
    AddMenuItem(menu, "cleanse", "Skill 3: Bile cleanse");
    AddMenuItem(menu, "support", "Utility: Revive & deployment");
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
            if (StrEqual(info, "aura"))
            {
                PrintGuideLine(param1, "Medics pulse heals to nearby survivors and move faster while healing - stay near the front line.");
                PrintGuideLine(param1, "Players you heal are notified and gain a special glow effect. Great for team sustain.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "grenades"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s to throw healing grenades that create a healing cloud for your team.", action1);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Perfect for healing multiple teammates at once during intense firefights.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "orbs"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s to toss glowing healing orbs that announce to others and provide healing.", action2);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Ideal for topping off teammates between fights or during defensive holds.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "cleanse"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s or !unvomit to cleanse bile from yourself and nearby teammates.", action3);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Essential for removing the Boomer's bile effect and maintaining team mobility.");
                DisplayMedicMenu(param1);
            }
            else if (StrEqual(info, "support"))
            {
                char line[256];
                Format(line, sizeof(line), "Faster revive and heal speeds make you the lifeline. Use %s to drop medkits/defibs.", deploy);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Can deploy medkits and defibrillators for the team. Movement boost while healing keeps you safe.");
                DisplayMedicMenu(param1);
            }
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
    AddMenuItem(menu, "grenades", "Skill 1: Experimental grenades");
    AddMenuItem(menu, "turrets", "Turret workshop & deployment");
    AddMenuItem(menu, "defense", "Shields, barricades & laser grids");
    AddMenuItem(menu, "pickups", "Carrying turrets & supplies");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void DisplayGameModesMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_GameModes);
    SetMenuTitle(menu, "Game Modes Guide");
    AddMenuItem(menu, "overview", "Overview");
    AddMenuItem(menu, "guesswho", "GuessWho (Hide & Seek)");
    AddMenuItem(menu, "race", "Race Mod");
    SetMenuExitButton(menu, true);
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
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Rage Edition includes custom game modes that change how you play.");
                PrintGuideLine(param1, "Access game modes from the main menu: Vote Options -> Select Game Mode.");
                PrintGuideLine(param1, "Each mode has unique rules and objectives. Try them all!");
                DisplayGameModesMenu(param1);
            }
            else if (StrEqual(info, "guesswho"))
            {
                PrintGuideLine(param1, "GuessWho (Hide & Seek): One player is the Seeker, others are Hiders.");
                PrintGuideLine(param1, "Hiders must blend in with props and avoid detection.");
                PrintGuideLine(param1, "Seeker must find and eliminate all hiders before time runs out.");
                PrintGuideLine(param1, "Hiders can use special abilities to escape and confuse the seeker.");
                PrintGuideLine(param1, "Activate via menu: Select 'GuessWho' from game mode options.");
                DisplayGameModesMenu(param1);
            }
            else if (StrEqual(info, "race"))
            {
                PrintGuideLine(param1, "Race Mod: Compete to be first to the safe room!");
                PrintGuideLine(param1, "Players race through the campaign, earning points based on finish position.");
                PrintGuideLine(param1, "Points: 1st=10, 2nd=8, 3rd=6, 4th=4. Bonus points for killing Tanks/Witches.");
                PrintGuideLine(param1, "Friendly fire is disabled (except molotovs). Special infected delay you but won't kill.");
                PrintGuideLine(param1, "Type !scores to check current standings. Admins can use !startrace to force start.");
                PrintGuideLine(param1, "Activate via menu: Select 'Race Mod' from game mode options.");
                DisplayGameModesMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
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
            if (StrEqual(info, "kits"))
            {
                PrintGuideLine(param1, "Engineers fortify pushes with upgrade kits and deployables that hold choke points.");
                PrintGuideLine(param1, "Spawn ready-to-use upgrade packs that enhance team capabilities during holds.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "grenades"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s to throw experimental grenades: Black Hole vortex, Tesla lightning, healing clouds, or airstrike markers.", action1);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "20 different grenade types - each with unique tactical applications for area denial and support.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "turrets"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s to open turret menu, pick a gun and ammo type from 20 shooting modes, then left-click to deploy.", action1);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Press USE on placed turrets to pick them up and relocate. Turrets are non-blocking and notify nearby players.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "defense"))
            {
                PrintGuideLine(param1, "Deploy protective shields, laser grids, and barricade doors/windows to control infected flow.");
                PrintGuideLine(param1, "Barricades block entry points to create safe zones and funnel infected into kill zones.");
                PrintGuideLine(param1, "Turrets can be blown up by infected if overrun - maintain defensive lines and reposition as needed.");
                DisplayEngineerMenu(param1);
            }
            else if (StrEqual(info, "pickups"))
            {
                char line[256];
                Format(line, sizeof(line), "Press USE on your turrets to pick them up and carry them to new positions. Use %s to drop ammo supplies.", deploy);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "You can relocate turrets as the team moves forward, maintaining defensive coverage throughout the map.");
                DisplayEngineerMenu(param1);
            }
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
    AddMenuItem(menu, "damage", "Damage profile & combat style");
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
            if (StrEqual(info, "stealth"))
            {
                char line[256];
                Format(line, sizeof(line), "Use %s (default: middle mouse) to vanish with the Dead Ringer, drop a fake corpse and sprint past ambushes.", action1);
                PrintGuideLine(param1, line);
                PrintGuideLine(param1, "Cloak grants invisibility and faster crouch movement to sneak past infected or reposition unseen.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "sight"))
            {
                PrintGuideLine(param1, "!extendedsight highlights special infected for 20 seconds every two minutes - call targets for your team.");
                PrintGuideLine(param1, "Perfect for scouting ahead and identifying threats before they ambush your team.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "mines"))
            {
                char minesLine[192];
                Format(minesLine, sizeof(minesLine), "Use %s to plant up to twenty mine types ranging from freeze traps to airstrikes. Mines glow to warn teammates.", deploy);
                PrintGuideLine(param1, minesLine);
                PrintGuideLine(param1, "Lay traps at choke points, doorways, and retreat paths to control the battlefield.");
                DisplaySaboteurMenu(param1);
            }
            else if (StrEqual(info, "damage"))
            {
                PrintGuideLine(param1, "Saboteurs deal bonus damage with melee weapons and can finish off downed infected quickly.");
                PrintGuideLine(param1, "Your melee attacks automatically apply poison damage over time - enemies glow green and take continuous damage.");
                PrintGuideLine(param1, "Poison ticks every second, making your melee hits incredibly effective against special infected.");
                PrintGuideLine(param1, "Perfect for hit-and-run tactics: strike, cloak away, and let the poison finish them off.");
                DisplaySaboteurMenu(param1);
            }
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
                PrintGuideLine(param1, "Soldier: skill_action_1 (middle mouse by default) calls a Satellite Strike where you aim. Massive orbital bombardment.");
                PrintGuideLine(param1, "Commando: build rage with damage, then press skill_action_1 or !berserker to activate Berserk mode for speed and damage boost.");
                PrintGuideLine(param1, "Athlete: sprint + jump together for the ninja kick gap opener; hold USE mid-air to deploy the parachute.");
                PrintGuideLine(param1, "Medic: tap skill_action_2 (Use+Fire) to throw a healing orb; stay near teammates for the healing aura.");
                PrintGuideLine(param1, "Engineer: press skill_action_1 (middle mouse) to pick a turret and ammo, left-click to place, USE to pack it up.");
                PrintGuideLine(param1, "Saboteur: skill_action_1 drops a fake corpse and cloaks you; Hold CTRL to plant mines, and !extendedsight pings specials for 20s.");
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
                PrintGuideLine(param1, "Saboteurs Hold CTRL to plant up to twenty mine types ranging from freeze traps to airstrikes. Mines glow to warn teammates.");
            }
            else if (StrEqual(info, "recon"))
            {
                PrintGuideLine(param1, "Saboteurs use skill_action_1 for the decoy cloak and !extendedsight to ping specials through walls for 20 seconds.");
            }
            else if (StrEqual(info, "airsupport"))
            {
                PrintGuideLine(param1, "Soldiers press skill_action_1 to call a Satellite Strike, while Commandos use skill_action_1 to activate Berserk mode once rage is ready.");
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
    Menu menu = CreateMenu(MenuHandler_GameModeDetails);
    SetMenuTitle(menu, "Game Modes");
    AddMenuItem(menu, "versus", "Versus variants");
    AddMenuItem(menu, "objective", "Objective modes");
    AddMenuItem(menu, "rage", "Rage customs");
    AddMenuItem(menu, "switch", "How to switch modes");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GameModeDetails(Menu menu, MenuAction action, int param1, int param2)
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

void DisplayPredicamentsMenu(int client)
{
    Menu menu = CreateMenu(MenuHandler_Predicaments);
    SetMenuTitle(menu, "Predicaments: Survival Mechanics");
    AddMenuItem(menu, "overview", "Predicaments system overview");
    AddMenuItem(menu, "selfrevive", "Self-revival from incapacitation");
    AddMenuItem(menu, "ledge", "Ledge rescue mechanics");
    AddMenuItem(menu, "pin_escape", "Pin escape & struggle system");
    AddMenuItem(menu, "crawl", "Incapped crawling");
    AddMenuItem(menu, "teammate", "Teammate revival while down");
    AddMenuItem(menu, "pickup", "Item pickup while incapacitated");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Predicaments(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, info, sizeof(info));
            if (StrEqual(info, "overview"))
            {
                PrintGuideLine(param1, "Predicaments enhances survivor gameplay with self-help mechanics and struggle systems.");
                PrintGuideLine(param1, "You can now revive yourself, escape pins, crawl while down, and help teammates in new ways.");
                PrintGuideLine(param1, "These mechanics give you more control during critical moments and reduce helplessness.");
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "selfrevive"))
            {
                PrintGuideLine(param1, "Hold CROUCH while incapacitated and consume pills, adrenaline, or first-aid kits to revive yourself.");
                PrintGuideLine(param1, "Great for recovering when teammates are busy fighting or you're separated from the group.");
                PrintGuideLine(param1, "Bots can also self-revive with configurable settings - check server convars.");
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "ledge"))
            {
                PrintGuideLine(param1, "Pull yourself up from ledges by consuming available medical items (pills, adrenaline, or medkits).");
                PrintGuideLine(param1, "No more waiting helplessly on ledges - if you have supplies, you can save yourself!");
                PrintGuideLine(param1, "Prioritize saving items for ledge situations when pushing aggressive positions.");
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "pin_escape"))
            {
                PrintGuideLine(param1, "Break free from Special Infected (Smoker, Hunter, Jockey, Charger) by struggling or using items.");
                PrintGuideLine(param1, "Mash CROUCH to build struggle progress and escape. Infected can counter by pressing SPRINT.");
                PrintGuideLine(param1, "Alternatively, consume medical items to instantly break free from pins when teammates can't help.");
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "crawl"))
            {
                PrintGuideLine(param1, "Move while incapacitated using your movement keys - crawl towards cover or teammates.");
                PrintGuideLine(param1, "Crawling speed is configurable but slower than normal movement. Use it to reach safer positions.");
                PrintGuideLine(param1, "You can crawl to supplies, better defensive positions, or closer to teammates for revival.");
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "teammate"))
            {
                PrintGuideLine(param1, "Incapacitated survivors can revive other incapacitated teammates by pressing RELOAD.");
                PrintGuideLine(param1, "When both of you are down, crawl to each other and use this mechanic to get back in the fight.");
                PrintGuideLine(param1, "This creates clutch comeback moments when the whole team goes down but can still recover.");
                DisplayPredicamentsMenu(param1);
            }
            else if (StrEqual(info, "pickup"))
            {
                PrintGuideLine(param1, "Grab nearby medical supplies (pills, adrenaline, medkits) while incapacitated.");
                PrintGuideLine(param1, "Look for items close to where you fell - you might find what you need to self-revive.");
                PrintGuideLine(param1, "This adds a survival element: falling near supplies gives you a second chance.");
                DisplayPredicamentsMenu(param1);
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
