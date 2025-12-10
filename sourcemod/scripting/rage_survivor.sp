/**
* =============================================================================
* Talents Plugin by Rage / Neil / Spirit / panxiaohai / Yaniho
* Incorporates Survivor classes.
*
* (C)2025 Neil / Yani.  All rights reserved.
* =============================================================================
*
*/

#define PLUGIN_NAME "[RAGE] Survivor Classes"
#define PLUGIN_VERSION "1.82b"
#define PLUGIN_IDENTIFIER "rage_survivor"
#define RAGE_SURVIVOR_PLUGIN  // Enable plugin-specific features in rage/timers.inc
#pragma semicolon 1
// DEBUG, DEBUG_LOG, DEBUG_TRACE now handled by rage/debug.inc - use PrintDebug() instead
#define DEPLOY_LOOK_DOWN_ANGLE 45.0  // Minimum pitch angle (degrees) required to look down for deployment
stock int DEBUG_MODE = 0; // Kept for backward compatibility, but use getDebugMode() from rage/debug.inc

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Rage / Ken / Neil / Spirit / panxiaohai / Yani",
	description = "Incorporates Survivor Classes",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=273312"
};

#include <adminmenu>
#include <sdktools>
#include <clientprefs>
#include <l4d2hud>
#include <jutils>
#include <l4d2>
#tryinclude <LMCCore>
#tryinclude <LMCL4D2SetTransmit>
#include <rage/skill_actions>
#include <rage/debug>
#include <rage/cooldown_notify>
#include <rage_menus/rage_menu_base>
#include <rage/validation>

// Global variables - MUST be declared before <talents> which includes <rage/menus>
// Using hardcoded sizes since constants are defined later
char g_ClassDescriptions[8][128];  // MAXCLASSES = 8, CLASS_DESCRIPTION_LENGTH = 128
int g_iQueuedClass[MAXPLAYERS+1];
bool g_bClassSelectionThirdPerson[MAXPLAYERS+1];
Handle g_hClassCookie;
ConVar CLASS_PREVIEW_DURATION;
ConVar ATHLETE_PARACHUTE_ENABLED;
ConVar HEALTH_MODIFIERS_ENABLED;
bool LeftSafeAreaMessageShown;
bool g_bIntroFinished = false;
bool g_bFirstMission = true;
bool g_bWasHoldingShift[MAXPLAYERS+1] = {false, ...};
// Note: g_BeamSprite and g_HaloSprite are declared as stock in rage/effects.inc
// We initialize them in OnMapStart() but don't redeclare them here to avoid duplicates

#include <talents>

#include <rage/admin_commands>
#include <rage/class_commands>

// Define LMC availability flag
#if defined _LMCCore_included
	#define LMC_AVAILABLE 1
#else
	#define LMC_AVAILABLE 0
#endif

#if defined _LMCL4D2SetTransmit_included
	#define LMC_SETTRANSMIT_AVAILABLE 1
#else
	#define LMC_SETTRANSMIT_AVAILABLE 0
#endif

#if !defined MAX_SKILL_NAME_LENGTH
        #define MAX_SKILL_NAME_LENGTH 32
#endif

#define CLASS_SKILL_CONFIG "configs/rage_class_skills.cfg"
#define CLASS_DESCRIPTION_LENGTH 128

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

static const char g_ClassIdentifiers[MAXCLASSES][16] =
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

static const char g_InputIdentifiers[ClassSkill_Count][16] =
{
        "special",
        "secondary",
        "tertiary",
        "deploy"
};

static const char g_DefaultClassDescriptions[MAXCLASSES][CLASS_DESCRIPTION_LENGTH] =
{
        "No class selected yet.",
        "Frontline fighter with faster movement, heavier armor, and brutal melee swings.",
        "Movement expert with high jumps, aerial control, and a parachute for safe drops.",
        "Team sustain lead who heals faster, drops supplies, and throws restorative grenades.",
        "Stealthy scout with cloak, fast crouch movement, and a toolkit of motion-sensitive mines.",
        "Damage specialist with faster reloads, heavier hits, and crowd control during tank fights.",
        "Builder who deploys turrets, ammo packs, and experimental grenades to lock down chokepoints.",
        "Heavy bruiser with a massive health pool built to soak damage for the squad."
};

ClassActionMode g_ClassActionMode[MAXCLASSES][ClassSkill_Count];
BuiltinAction g_ClassActionBuiltin[MAXCLASSES][ClassSkill_Count];
int g_ClassActionSkillIdMap[MAXCLASSES][ClassSkill_Count];
int g_ClassActionTriggerType[MAXCLASSES][ClassSkill_Count];
char g_ClassActionSkillName[MAXCLASSES][ClassSkill_Count][MAX_SKILL_NAME_LENGTH];
const int CLASS_COMMAND_PLUGIN_LEN = 32;
char g_ClassActionCommandPlugin[MAXCLASSES][ClassSkill_Count][CLASS_COMMAND_PLUGIN_LEN];
int g_ClassActionCommandType[MAXCLASSES][ClassSkill_Count];
int g_ClassActionCommandEntity[MAXCLASSES][ClassSkill_Count];

// Variables moved earlier - see declarations above before includes


SkillActionSlot GetSkillActionSlotForInput(ClassSkillInput input)
{
        switch (input)
        {
                case ClassSkill_Special:
                {
                        return SkillAction_Primary;
                }
                case ClassSkill_Secondary:
                {
                        return SkillAction_Secondary;
                }
                case ClassSkill_Tertiary:
                {
                        return SkillAction_Tertiary;
                }
                default:
                {
                        return SkillAction_Deploy;
                }
        }
}

void GetActionBindingLabel(ClassSkillInput input, char[] buffer, int maxlen)
{
        SkillActionSlot slot = GetSkillActionSlotForInput(input);
        GetSkillActionBindingLabel(slot, buffer, maxlen);
}

void ResetClassActionSlot(ClassTypes type, ClassSkillInput input)
{
        g_ClassActionMode[type][input] = ActionMode_None;
        g_ClassActionBuiltin[type][input] = Builtin_None;
        g_ClassActionSkillIdMap[type][input] = -1;
	g_ClassActionTriggerType[type][input] = 0;
	g_ClassActionSkillName[type][input][0] = '\0';
	g_ClassActionCommandPlugin[type][input][0] = '\0';
	g_ClassActionCommandType[type][input] = 0;
	g_ClassActionCommandEntity[type][input] = -1;
}

void ResetClassSkillConfig()
{
        for (int i = 0; i < view_as<int>(MAXCLASSES); i++)
        {
                strcopy(g_ClassDescriptions[i], CLASS_DESCRIPTION_LENGTH, g_DefaultClassDescriptions[i]);
        }

        for (int i = 0; i < view_as<int>(MAXCLASSES); i++)
        {
                for (int j = 0; j < view_as<int>(ClassSkill_Count); j++)
                {
                        ResetClassActionSlot(view_as<ClassTypes>(i), view_as<ClassSkillInput>(j));
		}
	}
}

ClassTypes ClassNameToType(const char[] name)
{
        for (int i = 0; i < view_as<int>(MAXCLASSES); i++)
        {
                if (StrEqual(g_ClassIdentifiers[i], name, false))
		{
			return view_as<ClassTypes>(i);
		}
	}

        return NONE;
}

void SaveClassCookie(int client, ClassTypes classType)
{
        if (g_hClassCookie == INVALID_HANDLE || IsFakeClient(client) || classType == NONE)
        {
                return;
        }

        char identifier[16];
        strcopy(identifier, sizeof(identifier), g_ClassIdentifiers[classType]);
        SetClientCookie(client, g_hClassCookie, identifier);
}

BuiltinAction BuiltinNameToAction(const char[] name)
{
	if (StrEqual(name, "medic_supply", false) || StrEqual(name, "medic", false))
	{
		return Builtin_MedicSupplies;
	}
	if (StrEqual(name, "engineer_supply", false) || StrEqual(name, "engineer", false))
	{
		return Builtin_EngineerSupplies;
	}
	if (StrEqual(name, "saboteur_mines", false) || StrEqual(name, "saboteur", false))
	{
		return Builtin_SaboteurMines;
	}

	return Builtin_None;
}

void ApplyActionDefinition(ClassTypes classType, ClassSkillInput input, const char[] definition)
{
	ResetClassActionSlot(classType, input);

	if (definition[0] == '\0')
	{
		return;
	}

	char buffer[128];
	strcopy(buffer, sizeof(buffer), definition);
	TrimString(buffer);

	if (buffer[0] == '\0' || StrEqual(buffer, "none", false))
	{
		return;
	}

	char tokens[4][64];
	int parts = ExplodeString(buffer, ":", tokens, sizeof(tokens), sizeof(tokens[]));

	if (parts <= 0)
	{
		return;
	}

	if (StrEqual(tokens[0], "skill", false))
	{
		if (parts >= 2)
		{
			TrimString(tokens[1]);
			g_ClassActionMode[classType][input] = ActionMode_Skill;
			strcopy(g_ClassActionSkillName[classType][input], MAX_SKILL_NAME_LENGTH, tokens[1]);
			g_ClassActionSkillIdMap[classType][input] = -1;
			if (parts >= 3)
			{
				g_ClassActionTriggerType[classType][input] = StringToInt(tokens[2]);
			}
		}
	}
	else if (StrEqual(tokens[0], "command", false))
	{
		if (parts >= 3)
		{
			TrimString(tokens[1]);
			g_ClassActionMode[classType][input] = ActionMode_Command;
			strcopy(g_ClassActionCommandPlugin[classType][input], CLASS_COMMAND_PLUGIN_LEN, tokens[1]);
			g_ClassActionCommandType[classType][input] = StringToInt(tokens[2]);
			g_ClassActionCommandEntity[classType][input] = (parts >= 4) ? StringToInt(tokens[3]) : -1;
		}
	}
	else if (StrEqual(tokens[0], "builtin", false))
	{
		if (parts >= 2)
		{
			TrimString(tokens[1]);
			g_ClassActionMode[classType][input] = ActionMode_Builtin;
			g_ClassActionBuiltin[classType][input] = BuiltinNameToAction(tokens[1]);
		}
	}
	else
	{
		g_ClassActionMode[classType][input] = ActionMode_Skill;
		strcopy(g_ClassActionSkillName[classType][input], MAX_SKILL_NAME_LENGTH, buffer);
		g_ClassActionSkillIdMap[classType][input] = -1;
	}
}

void ConfigureDefaultClassSkills()
{
        ApplyActionDefinition(soldier, ClassSkill_Special, "skill:Satellite");
        ApplyActionDefinition(athlete, ClassSkill_Special, "command:Grenades:15");
        ApplyActionDefinition(medic, ClassSkill_Special, "command:Grenades:11");
        ApplyActionDefinition(medic, ClassSkill_Secondary, "skill:HealingOrb");
        ApplyActionDefinition(medic, ClassSkill_Tertiary, "skill:UnVomit");
        ApplyActionDefinition(medic, ClassSkill_Deploy, "builtin:medic_supply");
        ApplyActionDefinition(saboteur, ClassSkill_Special, "skill:cloak:1");
        ApplyActionDefinition(saboteur, ClassSkill_Deploy, "builtin:saboteur_mines");
        ApplyActionDefinition(commando, ClassSkill_Special, "skill:Berzerk");
        ApplyActionDefinition(engineer, ClassSkill_Special, "command:Grenades:7");
        ApplyActionDefinition(engineer, ClassSkill_Secondary, "skill:Multiturret");
        ApplyActionDefinition(engineer, ClassSkill_Deploy, "builtin:engineer_supply");
}

void ResolveClassSkillIds()
{
	for (int i = 0; i < view_as<int>(MAXCLASSES); i++)
	{
		for (int j = 0; j < view_as<int>(ClassSkill_Count); j++)
		{
			if (g_ClassActionMode[i][j] == ActionMode_Skill && g_ClassActionSkillName[i][j][0] != '\0' && g_ClassActionSkillIdMap[i][j] == -1)
			{
				g_ClassActionSkillIdMap[i][j] = FindSkillIdByName(g_ClassActionSkillName[i][j]);
			}
		}
	}
}

void LoadClassSkillConfig()
{
	ResetClassSkillConfig();
	ConfigureDefaultClassSkills();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CLASS_SKILL_CONFIG);
	if (!FileExists(path))
	{
		ResolveClassSkillIds();
		return;
	}

	KeyValues kv = new KeyValues("RageClassSkills");
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		ResolveClassSkillIds();
		return;
	}

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char className[32];
			kv.GetSectionName(className, sizeof(className));
			ClassTypes classType = ClassNameToType(className);
			if (classType == NONE)
			{
				continue;
			}

                        for (int i = 0; i < view_as<int>(ClassSkill_Count); i++)
                        {
                                char value[64];
                                kv.GetString(g_InputIdentifiers[i], value, sizeof(value), "");
                                if (value[0] != '\0')
                                {
                                        ApplyActionDefinition(classType, view_as<ClassSkillInput>(i), value);
                                }
                        }

                        char description[CLASS_DESCRIPTION_LENGTH];
                        kv.GetString("description", description, sizeof(description), "");
                        if (description[0] != '\0')
                        {
                                strcopy(g_ClassDescriptions[classType], CLASS_DESCRIPTION_LENGTH, description);
                        }
                }
                while (kv.GotoNextKey(false));

                kv.GoBack();
        }

	delete kv;
	ResolveClassSkillIds();
}

void RefreshClassSkillAssignments()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2)
		{
			continue;
		}

		if (ClientData[i].ChosenClass == NONE)
		{
			continue;
		}

		AssignSkills(i);
	}
}

int GetClassSkillId(ClassTypes classType, ClassSkillInput input)
{
	if (g_ClassActionMode[classType][input] != ActionMode_Skill)
	{
		return -1;
	}

	if (g_ClassActionSkillIdMap[classType][input] == -1 && g_ClassActionSkillName[classType][input][0] != '\0')
	{
		g_ClassActionSkillIdMap[classType][input] = FindSkillIdByName(g_ClassActionSkillName[classType][input]);
	}

	return g_ClassActionSkillIdMap[classType][input];
}

bool TriggerSkillAction(int client, ClassTypes classType, ClassSkillInput input)
{
	// Validate client before proceeding
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return false;
	}

	int id = GetClassSkillId(classType, input);
	if (id == -1)
	{
		if (g_ClassActionSkillName[classType][input][0] != '\0')
		{
			PrintToServer("[Rage] Unable to find registered skill \"%s\" for class %s (%s input).", g_ClassActionSkillName[classType][input], g_ClassIdentifiers[classType], g_InputIdentifiers[input]);
			PrintHintText(client, "Skill \"%s\" is not available.", g_ClassActionSkillName[classType][input]);
		}
		else
		{
			PrintHintText(client, "Skill action is not properly configured for %s.", g_InputIdentifiers[input]);
		}
		return false;
	}

	Call_StartForward(g_hfwdOnSpecialSkillUsed);
	Call_PushCell(client);
	Call_PushCell(id);
	Call_PushCell(g_ClassActionTriggerType[classType][input]);
	Call_Finish();
	return true;
}

bool ExecuteBuiltinAction(int client, BuiltinAction action, ClassTypes classType = NONE)
{
	switch (action)
	{
		case Builtin_MedicSupplies:
		{
			PrintHintText(client, "✓ Deployment menu opened!");
			return CreatePlayerMedicMenu(client);
		}
		case Builtin_EngineerSupplies:
		{
			// For Engineer, show turret selection menu by triggering Multiturret skill
			if (classType == engineer)
			{
				// Check if secondary skill is available before triggering
				if (g_ClassActionMode[engineer][ClassSkill_Secondary] == ActionMode_None)
				{
					PrintHintText(client, "Turret skill is not available for Engineer.");
					return false;
				}
				// Trigger the secondary skill (Multiturret) which opens the turret menu
				// This will call OnSpecialSkillUsed which opens BuildMachineGunsMainMenu
				PrintHintText(client, "✓ Turret menu opened!");
				return TriggerSkillAction(client, engineer, ClassSkill_Secondary);
			}
			// For other classes (Soldier, Commando), show the supply menu
			PrintHintText(client, "✓ Supply menu opened!");
			return CreatePlayerEngineerMenu(client);
		}
		case Builtin_SaboteurMines:
		{
			PrintHintText(client, "✓ Mines menu opened!");
			return CreatePlayerSaboteurMenu(client);
		}
	}

	return false;
}

bool ExecuteClassAction(int client, ClassTypes classType, ClassSkillInput input)
{
	switch (g_ClassActionMode[classType][input])
	{
		case ActionMode_Skill:
		{
			// Show activation hint before triggering (skill-specific notifications come from OnSpecialSkillSuccess)
			char skillName[32];
			strcopy(skillName, sizeof(skillName), g_ClassActionSkillName[classType][input]);
			if (skillName[0] != '\0')
			{
				PrintHintText(client, "✓ Activating %s...", skillName);
			}
			bool result = TriggerSkillAction(client, classType, input);
			// Note: Skill success/failure notifications are handled by OnSpecialSkillSuccess/OnSpecialSkillFail
			return result;
		}
		case ActionMode_Command:
		{
			if (g_ClassActionCommandPlugin[classType][input][0] == '\0')
			{
				PrintHintText(client, "Command action is not configured for this input.");
				return false;
			}

			// Validate client before calling command
			if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
			{
				return false;
			}

			useCustomCommand(g_ClassActionCommandPlugin[classType][input], client, g_ClassActionCommandEntity[classType][input], g_ClassActionCommandType[classType][input]);
			// Notify player that command skill was activated
			PrintHintText(client, "✓ %s activated!", g_ClassActionCommandPlugin[classType][input]);
			ClientData[client].LastDropTime = GetGameTime();
			return true;
		}
		case ActionMode_Builtin:
		{
			bool result = ExecuteBuiltinAction(client, g_ClassActionBuiltin[classType][input], classType);
			// Builtin actions (menus) don't need activation notifications as they show menus
			return result;
		}
	}

	return false;
}

void GetActionCooldownMessage(ClassTypes classType, ClassSkillInput input, char[] buffer, int maxlen)
{
	switch (classType)
	{
		case soldier:
		{
			if (input == ClassSkill_Special)
			{
				strcopy(buffer, maxlen, "Wait %i seconds to order new airstrike.");
			}
			else if (input == ClassSkill_Secondary || input == ClassSkill_Tertiary)
			{
				strcopy(buffer, maxlen, "Wait %i seconds to fire another missile.");
			}
			else
			{
				strcopy(buffer, maxlen, "Wait %i seconds to use that ability again.");
			}
			return;
		}
		case medic:
		{
			strcopy(buffer, maxlen, "Wait %i seconds to use a healing orb again.");
			return;
		}
		case saboteur:
		{
			strcopy(buffer, maxlen, "Wait %i seconds to activate cloak again.");
			return;
		}
		case commando:
		{
			strcopy(buffer, maxlen, "Wait %i seconds to activate berzerk mode again.");
			return;
		}
		case engineer:
		{
			if (input == ClassSkill_Secondary)
			{
				strcopy(buffer, maxlen, "Wait %i seconds to throw a shield again.");
			}
			else
			{
				strcopy(buffer, maxlen, "Wait %i seconds to deploy a turret again.");
			}
			return;
		}
		case athlete:
		{
			strcopy(buffer, maxlen, "Wait %i seconds to use anti-gravity again.");
			return;
		}
	}

	strcopy(buffer, maxlen, "Wait %i seconds to use that ability again.");
}

bool TryTriggerClassSkillAction(int client, ClassTypes classType, ClassSkillInput input)
{
	if (g_ClassActionMode[classType][input] == ActionMode_None)
	{
		return false;
	}

	char message[128];
	GetActionCooldownMessage(classType, input, message, sizeof(message));

	// Check if skill can be used and show hints if not
	if (!canUseSpecialSkill(client, message))
	{
		return false;
	}

	return ExecuteClassAction(client, classType, input);
}

// Track deployment menu state per client
static bool g_bDeployMenuOpen[MAXPLAYERS+1] = {false, ...};

void HandleDeployInput(int client, ClassTypes classType, bool holdingDeploy, bool pressedPlant, bool onGround, bool canDrop, int elapsed)
{
	// Check if deployment is configured for this class
	if (g_ClassActionMode[classType][ClassSkill_Deploy] == ActionMode_None)
	{
		// Close menu if it was open
		if (g_bDeployMenuOpen[client])
		{
			ExtraMenu_Close(client);
			g_bDeployMenuOpen[client] = false;
		}
		return;
	}

	// Show deployment menu when holding CTRL (IN_DUCK)
	if (holdingDeploy)
	{
		// Only show menu if not already open
		if (!g_bDeployMenuOpen[client])
		{
			// For builtin actions (menus), show them immediately
			if (g_ClassActionMode[classType][ClassSkill_Deploy] == ActionMode_Builtin)
			{
				if (ExecuteClassAction(client, classType, ClassSkill_Deploy))
				{
					g_bDeployMenuOpen[client] = true;
				}
			}
			else
			{
				// For other actions, check restrictions first
		if (IsPlayerInSaferoom(client) || IsInEndingSaferoom(client))
		{
			PrintHintText(client, "Cannot deploy here");
			return;
		}

		if (!onGround)
		{
			PrintHintText(client, "You must stand on solid ground to deploy");
			return;
		}

		if (!canDrop)
		{
			int wait = ClientData[client].SpecialDropInterval - elapsed;
			if (wait < 0)
			{
				wait = 0;
			}
			PrintHintText(client, "Wait %i seconds to deploy again", wait);
			return;
		}

		if (ClientData[client].SpecialLimit > 0 && ClientData[client].SpecialsUsed >= ClientData[client].SpecialLimit)
		{
			PrintHintText(client, "You're out of supplies (Max %d)", ClientData[client].SpecialLimit);
			return;
		}

				if (ExecuteClassAction(client, classType, ClassSkill_Deploy))
				{
					g_bDeployMenuOpen[client] = true;
				}
			}
		}
	}
	else
	{
		// CTRL released - close deploymen menu if it was open
		if (g_bDeployMenuOpen[client])
		{
			ExtraMenu_Close(client);
			g_bDeployMenuOpen[client] = false;
		}
	}
}

/**
* PLUGIN LOGIC
*/

public OnPluginStart( )
{
        // Concommands
        RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
        RegConsoleCmd("sm_class_set", CmdClassSet, "Select a class directly");
        RegConsoleCmd("sm_classinfo", CmdClassInfo, "Shows class descriptions");
        RegConsoleCmd("sm_classes", CmdClasses, "Shows class descriptions");
        RegConsoleCmd("skill_action_1", CmdSkillAction1, "Trigger your primary class action (default: Satellite Strike for Soldier)");
        RegConsoleCmd("+skill_action_1", CmdSkillAction1, "Trigger your primary class action (press version)");
        RegConsoleCmd("-skill_action_1", CmdSkillAction1Release, "Release version (does nothing)");
        RegConsoleCmd("skill_action_2", CmdSkillAction2, "Trigger your secondary class action");
        RegConsoleCmd("+skill_action_2", CmdSkillAction2, "Trigger your secondary class action (press version)");
        RegConsoleCmd("-skill_action_2", CmdSkillAction2Release, "Release version (does nothing)");
        RegConsoleCmd("skill_action_3", CmdSkillAction3, "Trigger your tertiary class action");
        RegConsoleCmd("+skill_action_3", CmdSkillAction3, "Trigger your tertiary class action (press version)");
        RegConsoleCmd("-skill_action_3", CmdSkillAction3Release, "Release version (does nothing)");
        RegConsoleCmd("deployment_action", CmdDeploymentAction, "Trigger your deployment action (SHIFT by default)");
        RegConsoleCmd("sm_skill", CmdUseSkill, "Use your class special skill");
        g_hClassCookie = RegClientCookie("rage_class_choice", "Rage preferred class", CookieAccess_Public);
        RegisterAdminCommands();

        // Api

	g_hfwdOnPlayerClassChange = CreateGlobalForward("OnPlayerClassChange", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hfwdOnSpecialSkillUsed = CreateGlobalForward("OnSpecialSkillUsed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hfwdOnCustomCommand = CreateGlobalForward("OnCustomCommand", ET_Ignore, Param_String, Param_Cell, Param_Cell, Param_Cell);
	//Create a Class Selection forward
	g_hOnSkillSelected = CreateGlobalForward("OnSkillSelected", ET_Event, Param_Cell, Param_Cell);	
	g_hForwardPluginState = CreateGlobalForward("Rage_OnPluginState", ET_Ignore, Param_String, Param_Cell);
	g_hForwardRoundState = CreateGlobalForward("Rage_OnRoundState", ET_Ignore, Param_Cell);
	g_fwPerkPre = CreateGlobalForward("Rage_OnPerkPre", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_fwPerkPost = CreateGlobalForward("Rage_OnPerkPost", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_fwCanAccessPerk = CreateGlobalForward("Rage_CanAccessPerk", ET_Event, Param_Cell, Param_Cell, Param_String, Param_CellByRef);
	g_fwSlotName = CreateGlobalForward("Rage_OnGetSlotName", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);

	// void Rage_OnLoad(int client);
	//Create menu and set properties
        g_hSkillMenu = CreateMenu(RageSkillMenuHandler);
	SetMenuTitle(g_hSkillMenu, "Registered plugins");
	SetMenuExitButton(g_hSkillMenu, true);
	//Create a Class Selection forward

	if (g_hSkillArray == INVALID_HANDLE)
		g_hSkillArray = CreateArray(16);
	
	if (g_hSkillTypeArray == INVALID_HANDLE)
		g_hSkillTypeArray = CreateArray(16);

	// Offsets
	g_iNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_iActiveWeapon = FindSendPropInfo("CBaseCombatCharacter", "m_hActiveWeapon");
	g_flLaggedMovementValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_iPlaybackRate = FindSendPropInfo("CBaseCombatWeapon", "m_flPlaybackRate");
	g_iNextAttack = FindSendPropInfo("CTerrorPlayer", "m_flNextAttack");
	g_iTimeWeaponIdle = FindSendPropInfo("CTerrorGun", "m_flTimeWeaponIdle");
	g_reloadStartDuration = FindSendPropInfo("CBaseShotgun", "m_reloadStartDuration");
	g_reloadInsertDuration = FindSendPropInfo("CBaseShotgun", "m_reloadInsertDuration");
	g_reloadEndDuration = FindSendPropInfo("CBaseShotgun", "m_reloadEndDuration");
	g_iReloadState = FindSendPropInfo("CBaseShotgun", "m_reloadState");
	g_iVMStartTimeO = FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO = FindSendPropInfo("CTerrorPlayer","m_hViewModel");
	g_iActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_iNextSecondaryAttack	= FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
        g_iShovePenalty = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
	g_flMeleeRate = 0.45;	
	g_flAttackRate = 0.666;
	g_flReloadRate = 0.5;

	// Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundChange);
	HookEvent("round_start_post_nav", Event_RoundChange);
	HookEvent("round_start", Event_RoundStart,	EventHookMode_PostNoCopy);	
	HookEvent("mission_lost", Event_RoundChange);
	HookEvent("weapon_reload", Event_RelCommandoClass);
	HookEvent("player_entered_checkpoint", Event_EnterSaferoom);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_left_start_area",Event_LeftStartArea);
	HookEvent("heal_begin", Event_HealBegin, EventHookMode_Pre);
        HookEvent("revive_begin", Event_ReviveBegin, EventHookMode_Pre);
        HookEvent("weapon_fire", Event_WeaponFire);
        HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);

        LoadSkillActionBindings();
        LoadClassSkillConfig();

	LoadClassSkillConfig();

	// Convars
	new Handle:hVersion = CreateConVar("talents_version", PLUGIN_VERSION, "Version of this release", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	// Convars
	g_hPluginEnabled = CreateConVar("talents_enabled","1","Enables/Disables Plugin 0 = OFF, 1 = ON.", FCVAR_NOTIFY);

	CLASS_PREVIEW_DURATION = CreateConVar("talents_class_preview_time", "8.0", "How long (in seconds) to show third-person view when selecting a class", FCVAR_NOTIFY, true, 1.0, true, 30.0);

	MAX_SOLDIER = CreateConVar("talents_soldier_max", "1", "Max number of soldiers");
	MAX_ATHLETE = CreateConVar("talents_athelete_max", "1", "Max number of athletes");
	MAX_MEDIC = CreateConVar("talents_medic_max", "1", "Max number of medics");
	MAX_SABOTEUR = CreateConVar("talents_saboteur_max", "1", "Max number of saboteurs");
	MAX_COMMANDO = CreateConVar("talents_commando_max", "1", "Max number of commandos");
	MAX_ENGINEER = CreateConVar("talents_engineer_max", "1", "Max number of engineers");
	MAX_BRAWLER = CreateConVar("talents_brawler_max", "1", "Max number of brawlers");
	
	NONE_HEALTH = CreateConVar("talents_none_health", "150", "How much health a default player should have");
	SOLDIER_HEALTH = CreateConVar("talents_soldier_health", "300", "How much health a soldier should have");
	ATHLETE_HEALTH = CreateConVar("talents_athelete_health", "150", "How much health an athlete should have");
	MEDIC_HEALTH = CreateConVar("talents_medic_health_start", "150", "How much health a medic should have");
	SABOTEUR_HEALTH = CreateConVar("talents_saboteur_health", "150", "How much health a saboteur should have");
	COMMANDO_HEALTH = CreateConVar("talents_commando_health", "300", "How much health a commando should have");
	ENGINEER_HEALTH = CreateConVar("talents_engineer_health", "150", "How much health a engineer should have");
	BRAWLER_HEALTH = CreateConVar("talents_brawler_health", "600", "How much health a brawler should have");

	SPECIAL_SKILL_LIMIT = CreateConVar("talents_skill_amount", "5", "How many times special skills can be used per round by default");
	SOLDIER_MELEE_ATTACK_RATE = CreateConVar("talents_soldier_melee_rate", "0.45", "The interval for soldier swinging melee weapon (clamped between 0.3 < 0.9)", FCVAR_NOTIFY, true, 0.3, true, 0.9);
	HookConVarChange(SOLDIER_MELEE_ATTACK_RATE, Convar_Melee_Rate);	
	SOLDIER_ATTACK_RATE = CreateConVar("talents_soldier_attack_rate", "0.6666", "How fast the soldier should shoot with guns. Lower values = faster. Between 0.2 and 0.9", FCVAR_NONE|FCVAR_NOTIFY, true, 0.2, true, 0.9);
	HookConVarChange(SOLDIER_ATTACK_RATE, Convar_Attack_Rate);	
	SOLDIER_SPEED = CreateConVar("talents_soldier_speed", "1.15", "How fast soldier should run. A value of 1.0 = normal speed");
	SOLDIER_DAMAGE_REDUCE_RATIO = CreateConVar("talents_soldier_damage_reduce_ratio", "0.75", "Ratio for how much armor reduces damage for soldier");
	SOLDIER_SHOVE_PENALTY = CreateConVar("talents_soldier_shove_penalty_enabled","0.0","Enables/Disables shove penalty for soldier. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	SOLDIER_MAX_AIRSTRIKES = CreateConVar("talents_soldier_max_airstrikes","3.0","Number of tactical airstrikes per round. 0 = OFF", FCVAR_NOTIFY, true, 0.0, true, 16.0);

	ATHLETE_JUMP_VEL = CreateConVar("talents_athlete_jump", "450.0", "How high a soldier should be able to jump. Make this higher to make them jump higher, or 0.0 for normal height");
	ATHLETE_SPEED = CreateConVar("talents_athlete_speed", "1.20", "How fast athlete should run. A value of 1.0 = normal speed");
        ATHLETE_PARACHUTE_ENABLED = CreateConVar("talents_athlete_enable_parachute","1.0","Enable parachute for athlete. Hold E in air to use it. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	MEDIC_HEAL_DIST = CreateConVar("talents_medic_heal_dist", "256.0", "How close other survivors have to be to heal. Larger values = larger radius");
	MEDIC_HEALTH_VALUE = CreateConVar("talents_medic_health", "10", "How much health to restore");
	MEDIC_MAX_ITEMS = CreateConVar("talents_medic_max_items", "3", "How many items the medic can drop");
	MEDIC_HEALTH_INTERVAL = CreateConVar("talents_medic_health_interval", "2.0", "How often to heal players within range");
	MEDIC_REVIVE_RATIO = CreateConVar("talents_medic_revive_ratio", "0.5", "How much faster medic revives. lower is faster");
	MEDIC_HEAL_RATIO = CreateConVar("talents_medic_heal_ratio", "0.5", "How much faster medic heals, lower is faster");
	MEDIC_MAX_BUILD_RANGE = CreateConVar("talents_medic_build_range", "120.0", "Maximum distance away an object can be dropped by medic");

	SABOTEUR_INVISIBLE_TIME = CreateConVar("talents_saboteur_invis_time", "5.0", "How long it takes for the saboteur to become invisible");
	SABOTEUR_BOMB_ACTIVATE = CreateConVar("talents_saboteur_bomb_activate", "5.0", "How long before the dropped bomb becomes sensitive to motion");
	SABOTEUR_BOMB_RADIUS = CreateConVar("talents_saboteur_bomb_radius", "128.0", "Radius of bomb motion detection");
	SABOTEUR_MAX_BOMBS = CreateConVar("talents_saboteur_max_bombs", "5", "How many bombs a saboteur can drop per round");
	SABOTEUR_BOMB_TYPES = CreateConVar("talents_saboteur_bomb_types", "2,10,5,15,12,16,9", "Define max 7 mine types to use. (2,10,5,15,12,16,9 are nice combo) 1=Bomb, 2=Cluster, 3=Firework, 4=Smoke, 5=Black Hole, 6=Flashbang, 7=Shield, 8=Tesla, 9=Chemical, 10=Freeze, 11=Medic, 12=Vaporizer, 13=Extinguisher, 14=Glow, 15=Anti-Gravity, 16=Fire Cluster, 17=Bullets, 18=Flak, 19=Airstrike, 20=Weapon");
	SABOTEUR_BOMB_DAMAGE_SURV = CreateConVar("talents_saboteur_bomb_dmg_surv", "0", "How much damage a bomb does to survivors");
	SABOTEUR_BOMB_DAMAGE_INF = CreateConVar("talents_saboteur_bomb_dmg_inf", "1500", "How much damage a bomb does to infected");
	SABOTEUR_BOMB_POWER = CreateConVar("talents_saboteur_bomb_power", "2.0", "How much blast power a bomb has. Higher values will throw survivors farther away");
	SABOTEUR_ACTIVE_BOMB_COLOR = CreateConVar("talents_bomb_active_glow_color","255 0 0", "Glow color for active bombs (Default Red)");
	SABOTEUR_ENABLE_NIGHT_VISION = CreateConVar( "talents_saboteur_enable_nightvision", "1", "1 - Enable Night Vision for Saboteur; 0 - Disable");

	COMMANDO_DAMAGE = CreateConVar("talents_commando_dmg", "5.0", "How much bonus damage a Commando does by default");
	COMMANDO_DAMAGE_RIFLE = CreateConVar("talents_commando_dmg_rifle", "10.0", "How much bonus damage a Commando does with rifle");
	COMMANDO_DAMAGE_GRENADE = CreateConVar("talents_commando_dmg_grenade", "20.0", "How much bonus damage a Commando does with grenade");
	COMMANDO_DAMAGE_SHOTGUN = CreateConVar("talents_commando_dmg_shotfun", "5.0", "How much bonus damage a Commando does with shotgun");
	COMMANDO_DAMAGE_SNIPER = CreateConVar("talents_commando_dmg_sniper", "15.0", "How much bonus damage a Commando does with sniper");
	COMMANDO_DAMAGE_HUNTING = CreateConVar("talents_commando_dmg_hunting", "15.0", "How much bonus damage a Commando does with hunting rifle");
	COMMANDO_DAMAGE_PISTOL = CreateConVar("talents_commando_dmg_pistol", "25.0", "How much bonus damage a Commando does with pistol");
	COMMANDO_DAMAGE_SMG = CreateConVar("talents_commando_dmg_smg", "7.0", "How much bonus damage a Commando does with smg");
	COMMANDO_RELOAD_RATIO = CreateConVar("talents_commando_reload_ratio", "0.5", "Ratio for how fast a Commando should be able to reload. Between 0.3 and 0.9",FCVAR_NONE|FCVAR_NOTIFY, true, 0.3, true, 0.9);
	HookConVarChange(COMMANDO_RELOAD_RATIO, Convar_Reload_Rate);
	COMMANDO_ENABLE_STUMBLE_BLOCK = CreateConVar("talents_commando_enable_stumble_block", "1", "Enable blocking tank knockdowns for Commando. 0 = Disable, 1 = Enable");
	COMMANDO_ENABLE_STOMPING = CreateConVar("talents_commando_enable_stomping", "1", "Enable stomping of downed infected  0 = Disable, 1 = Enable");
	COMMANDO_STOMPING_SLOWDOWN = CreateConVar("talents_commando_stomping_slowdown", "0", "Should movement slow down after stomping: 0 = Disable, 1 = Enable");

	ENGINEER_MAX_BUILDS = CreateConVar("talents_engineer_max_builds", "5", "How many times an engineer can build per round");
	ENGINEER_MAX_BUILD_RANGE = CreateConVar("talents_engineer_build_range", "120.0", "Maximum distance away an object can be built by the engineer");
	
	MINIMUM_DROP_INTERVAL = CreateConVar("talents_drop_interval", "30.0", "Time before an engineer, medic, or saboteur can drop another item");
	MINIMUM_AIRSTRIKE_INTERVAL = CreateConVar("talents_airstrike_interval", "180.0", "Time before soldier can order airstrikes again.");

	// Revive & health modifiers
	HEALTH_MODIFIERS_ENABLED = CreateConVar("talents_health_modifiers_enabled","0.0","Enables/Disables health modifiers. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	REVIVE_DURATION = CreateConVar("talents_revive_duration", "4.0", "Default reviving duration in seconds");
	HEAL_DURATION = CreateConVar("talents_heal_duration", "4.0", "Default healing duration in seconds");
	REVIVE_HEALTH =  CreateConVar("talents_revive_health", "100.0", "Default health given 0n revive");
	PILLS_HEALTH_BUFFER =  CreateConVar("talents_pills_health_buffer", "75.0", "Default health given on pills");	
	ADRENALINE_DURATION =  CreateConVar("talents_adrenaline_duration", "30.0", "Default adrenaline duration");
	ADRENALINE_HEALTH_BUFFER =  CreateConVar("talents_adrenaline_health_buffer", "75.0", "Default health given on adrenaline");

	AutoExecConfig(true, "talents");
	ApplyHealthModifiers();
	parseAvailableBombs();
	
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
}

public ResetClientVariables(client)
{
	ClientData[client].SpecialsUsed = 0;	
	ClientData[client].HideStartTime= GetGameTime();
	ClientData[client].HealStartTime= GetGameTime();
	ClientData[client].LastButtons = 0;
	ClientData[client].SpecialDropInterval = 0;
	ClientData[client].ChosenClass = NONE;
	ClientData[client].SpecialSkill = SpecialSkill:No_Skill;
	ClientData[client].LastDropTime = 0.0;
	g_bInSaferoom[client] = false;
	g_bHide[client] = false;
	g_bClassSelectionThirdPerson[client] = false;
	g_bDeployMenuOpen[client] = false;
	
	// Properly clean up timer
	KillTimerSafe(g_ReadyTimer[client]);
}

public ClearCache()
{
	g_iSoldierCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iSoldierIndex[i]= -1;
		g_iEntityIndex[i] = -1;
		g_fNextAttackTime[i]= -1.0;
	}
}

public RebuildCache()
{
	ClearCache();

	if (!IsServerProcessing())
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (GetClientTeam(i) == 2 && ClientData[i].ChosenClass == soldier)
		{
			g_iSoldierCount++;
			g_iSoldierIndex[g_iSoldierCount] = i;
			PrintDebugAll("\x03-registering \x01%N as Soldier",i);
		}
	}
}

public void GetPlayerSkillReadyHint(client) {
        if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return;
        }

        // Only show hints after intro finishes on first mission
        if (g_bFirstMission && !g_bIntroFinished)
        {
                return;
        }

        ClassTypes classType = ClientData[client].ChosenClass;
        if (classType == NONE)
        {
                return;
        }

        int classId = view_as<int>(classType);
        // Always show class in HUD, and show skill ready status if applicable
        if (ClientData[client].SpecialLimit > ClientData[client].SpecialsUsed && classId > 0 && classId < sizeof(SpecialReadyTips)) {
                ShowClassHud(client, true, SpecialReadyTips[classId]);
        }
        else
        {
                // Show class even when skill is not ready
                ShowClassHud(client, false);
        }
}

public void SetupClasses(client, class)
{
        if (!client
                || !IsValidEntity(client)
                || !IsClientInGame(client)
                || !IsPlayerAlive(client)
                || GetClientTeam(client) != 2)
        return;

        char primaryBind[64];
        char deployBind[64];
        char secondaryBind[64];
        GetActionBindingLabel(ClassSkill_Special, primaryBind, sizeof(primaryBind));
        GetActionBindingLabel(ClassSkill_Deploy, deployBind, sizeof(deployBind));
        GetActionBindingLabel(ClassSkill_Secondary, secondaryBind, sizeof(secondaryBind));

        ClientData[client].ChosenClass = view_as<ClassTypes>(class);
ClientData[client].SpecialDropInterval = GetConVarInt(MINIMUM_DROP_INTERVAL);
ClientData[client].SpecialLimit = GetConVarInt(SPECIAL_SKILL_LIMIT);
new MaxPossibleHP = GetConVarInt(NONE_HEALTH);
DisableAllUpgrades(client);

// Apply class-specific model
ApplyClassModel(client, view_as<ClassTypes>(class));

switch (view_as<ClassTypes>(class))
{

                case soldier:
                {
                        char text[64];
                        text[0] = '\0';
                        if (g_bAirstrike == true) {
                                Format(text, sizeof(text), "Press %s for Satellite Strike!", primaryBind);
                        }

                        PrintHintText(client,"You have armor, fast attack rate and movement %s", text );
                        ClientData[client].SpecialDropInterval = GetConVarInt(MINIMUM_AIRSTRIKE_INTERVAL);
                        ClientData[client].SpecialLimit = GetConVarInt(SOLDIER_MAX_AIRSTRIKES);
                        MaxPossibleHP = GetConVarInt(SOLDIER_HEALTH);
                }
		
                case medic:
                {
                        PrintHintText(client,"Hold CROUCH to heal others. Look down and press %s to drop medkits & supplies.\nPress %s to throw a healing grenade!", deployBind, primaryBind);
                        CreateTimer(GetConVarFloat(MEDIC_HEALTH_INTERVAL), TimerDetectHealthChanges, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                        ClientData[client].SpecialLimit = GetConVarInt(MEDIC_MAX_ITEMS);
                        MaxPossibleHP = GetConVarInt(MEDIC_HEALTH);
                }
		
		case athlete:
		{
			if (GetConVarBool(ATHLETE_PARACHUTE_ENABLED))
			{
				PrintHintText(client, "You move faster, Hold JUMP to bunny hop! Hold USE mid-air for a parachute glide. Sprint + JUMP to throw a ninja kick.");
			}
			else
			{
				PrintHintText(client, "You move faster, Hold JUMP to bunny hop! Sprint + JUMP to throw a ninja kick.");
			}
			MaxPossibleHP = GetConVarInt(ATHLETE_HEALTH);
		}
		
		case commando:
		{
                        char text[64];

                        ClientData[client].SpecialDropInterval = 120;
                        ClientData[client].SpecialLimit = 3;

                        if (GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK)) {
                                text = ", You can knock down tanks!";
                        }

                        PrintHintText(client,"You have faster reload & increased damage%s!\nPress %s to activate Berzerk mode!", text, primaryBind);
                        MaxPossibleHP = GetConVarInt(COMMANDO_HEALTH);
                }

                case engineer:
                {
                        PrintHintText(client,"Press %s to launch experimental grenades. Use %s to deploy turrets. Use %s to drop ammo supplies!", primaryBind, secondaryBind, deployBind);
                        MaxPossibleHP = GetConVarInt(ENGINEER_HEALTH);
                        ClientData[client].SpecialLimit = GetConVarInt(ENGINEER_MAX_BUILDS);
                }

                case saboteur:
		{
                        PrintHintText(client,"Use %s to drop mines! Hold CROUCH 3 sec to go invisible.\nPress %s to summon a Decoy. Toggle extended sight from your menu for wallhack support", deployBind, primaryBind);
			MaxPossibleHP = GetConVarInt(SABOTEUR_HEALTH);
			ClientData[client].SpecialLimit = GetConVarInt(SABOTEUR_MAX_BOMBS);
                }

                case brawler:
                {
                        PrintHintText(client,"You've got lots of health! No special skill—just tank the damage for your team.");
                        MaxPossibleHP = GetConVarInt(BRAWLER_HEALTH);
                }
        }

	AssignSkills(client);
	setPlayerHealth(client, MaxPossibleHP);
}

/* Temporarily hardcoded until get config right */

public AssignSkills(int client)
{	
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	ClassTypes classType = ClientData[client].ChosenClass;
	g_iPlayerSkill[client] = GetClassSkillId(classType, ClassSkill_Special);

	if (g_iPlayerSkill[client] >= 0)
	{
		char skillName[32];
		int skillSize = sizeof(skillName);

		PlayerIdToSkillName(client, skillName, skillSize);
		PrintDebugAll("Assigned skill %s to client", skillName);
		Call_StartForward(g_hOnSkillSelected);
		Call_PushCell(client);
		Call_PushCell(g_iPlayerSkill[client]);
		Call_Finish();		
	}
}
// ====================================================================================================
//					Register plugins
// ====================================================================================================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_AllPerks = CreateTrie();
	g_SlotPerks = CreateTrie();
	g_SlotIndexes = CreateArray();
	g_bLateLoad = late;

	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	RegPluginLibrary(PLUGIN_IDENTIFIER);
	CreateNative("GetPlayerClassName", Native_GetPlayerClassName);
	CreateNative("RegisterRageSkill", Native_RegisterSkill);
	CreateNative("UnregisterRageSkill", Native_UnregisterSkill);	
	CreateNative("OnSpecialSkillSuccess", Native_OnSpecialSkillSuccess);
	CreateNative("OnSpecialSkillFail", Native_OnSpecialSkillFail);
	CreateNative("GetPlayerSkillID", Native_GetPlayerSkillID);
	CreateNative("FindSkillNameById", Native_FindSkillNameById);
	CreateNative("FindSkillIdByName", Native_FindSkillIdByName);
	CreateNative("GetPlayerSkillName", Native_GetPlayerSkillName);
	
	CreateNative("Rage_GetAllPerks", Native_GetAllPerks);
	CreateNative("Rage_GetPlayerPerk", Native_GetPlayerPerk);
	CreateNative("Rage_RegPerk", Native_RegPerk);
	CreateNative("Rage_FindPerk", Native_FindPerk);

MarkNativeAsOptional("OnCustomCommand");

	return APLRes_Success;
}

public void OnPluginEnd()
{
	ResetPlugin();
	char plugin[32];
    plugin = "rage_survivor";
	
	Call_StartForward(g_hForwardPluginState);
	Call_PushString(plugin);
	Call_PushCell(0);
	Call_Finish();	
}

public InitSkillArray()
{
    g_hSkillArray = CreateArray(8, 32);
    
    char cIndexValid;
    char cIndexUserid;
    int cSkillId;
    bool bUserAlive;
    char cSkillName;    
    int cSkillType;
    char cSkillParameter;
    int iPerkID;

    for(new i = 1; i <= MAXPLAYERS; i++)
    {
		if(!IsClientInGame(i))
		continue;
		//
		SetArrayCell(g_hSkillArray, (i - 1), false, cIndexValid);
		SetArrayCell(g_hSkillArray, (i - 1), GetClientUserId(i), cIndexUserid);
		SetArrayCell(g_hSkillArray, (i - 1), IsPlayerAlive(i), bUserAlive);
		SetArrayCell(g_hSkillArray, (i - 1), -1, cSkillId);
		SetArrayCell(g_hSkillArray, (i - 1), false, cSkillName);
		SetArrayCell(g_hSkillArray, (i - 1), -1, cSkillType);
		SetArrayCell(g_hSkillArray, (i - 1), -1, cSkillParameter);
		SetArrayCell(g_hSkillArray, (i - 1), -1, iPerkID);
    }
}

public Native_RegisterSkill(Handle:plugin, numParams)
{
	if (g_hPluginEnabled == INVALID_HANDLE) 
	{
		PrintDebugAll("Rage plugin is not yet loading, queueing");
	}
	char szItemInfo[3];
	int type;
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return -1;
	}
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);
	if (g_hSkillArray == INVALID_HANDLE) {
		return -1;
	}

	if(++g_iSkillCounter <= view_as<int>(MAXCLASSES))
	{
		IntToString(g_iSkillCounter, szItemInfo, sizeof(szItemInfo));
		int index = FindStringInArray(g_hSkillArray, szSkillName);		
		if (index >= 0) {
			//PrintDebugAll("Skill %s already exists on index %i", szSkillName, index);
			return index;
		}
		index = PushArrayString(g_hSkillArray, szSkillName);
		type = GetNativeCell(2);
		PushArrayCell(g_hSkillTypeArray, type);
		AddMenuItem(g_hSkillMenu, szItemInfo, szSkillName);

		PrintDebugAll("Registered skill %s with type %i and index %i", szSkillName, type, index);
		return index;
	}
	
	return -1;
}

public Native_UnregisterSkill(Handle:plugin, numParams)
{
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return -1;
	}
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);
	if (g_hSkillArray == INVALID_HANDLE) {
		return -1;
	}

	int index = FindStringInArray(g_hSkillArray, szSkillName);	
	if (index > -1) {
		RemoveFromArray(g_hSkillArray, index);
		ShiftArrayUp(g_hSkillArray, index);
		return 1;
	}
	return 0;
}

// ====================================================================================================
//					Native events
// ====================================================================================================

any Native_OnSpecialSkillSuccess(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	int len;
	GetNativeStringLength(2, len);
 
	if (len <= 0)
	{
		return 0;
	}
 
	char[] str = new char[len + 1];
	GetNativeString(2, str, len + 1);
	
	// Notify player that skill was activated
	PrintHintText(client, "✓ %s activated!", str);
	
	ClientData[client].SpecialsUsed++;
	ClientData[client].LastDropTime = GetGameTime();

	int interval = ClientData[client].SpecialDropInterval;

	if (interval >= 0 && (ClientData[client].SpecialsUsed < ClientData[client].SpecialLimit))
	{ 
		g_ReadyTimer[client] = CreateTimer(float(ClientData[client].SpecialDropInterval), Timer_Ready, client); 
	}

	return 1;
}

any Native_OnSpecialSkillFail(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	int len;
	GetNativeStringLength(2, len);
	if (len <= 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Empty plugin name!");
	} 
	char[] name = new char[len + 1];
	GetNativeString(2, name, len + 1);
	GetNativeStringLength(3, len);
	if (len <= 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Empty reason!");
	}
	char[] reason = new char[len + 1];
	GetNativeString(3, reason, len + 1);
	PrintToChat(client, "%s failed due to: %s", name, reason);
	return 0;
}

// ====================================================================================================
//		Events & Timers
// ====================================================================================================

public OnMapStart()
{
	// Enable HUD system (required for custom HUD elements to be visible)
	GameRules_SetProp("m_bChallengeModeActive", true, _, _, true);
	
	// Initialize cooldown notification system
	CooldownNotify_Init();
	
	// Precache cooldown ready sound
	PrecacheSound(COOLDOWN_READY_SOUND, true);
	
	// Sounds
	PrecacheSound(SOUND_CLASS_SELECTED);
	PrecacheSound(SOUND_DROP_BOMB);
	PrecacheModel(MODEL_INCEN, true);
	PrecacheModel(MODEL_EXPLO, true);
	PrecacheModel(MODEL_SPRITE, true);
	PrecacheModel(SPRITE_GLOW, true);
	PrecacheModel(MODEL_MINE, true);
	PrecacheSound(SOUND_SQUEAK, true);
	PrecacheSound(SOUND_TUNNEL, true);
	PrecacheSound(SOUND_NOISE, true);
	PrecacheSound(SOUND_BUTTON2, true);

	// Sprites
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	PrecacheModel(ENGINEER_MACHINE_GUN);
	PrecacheModel(AMMO_PILE);
	PrecacheModel(FAN_BLADE);
	PrecacheModel(PARACHUTE);

	// Precache all class models to avoid runtime frame drops
	PrecacheClassModels();
	
	// Validate LMC availability and log status
#if LMC_AVAILABLE
	PrintDebugAll("LMC (Lux Model Changer) support compiled in - will use LMC for model overlays if available at runtime");
#else
	PrintDebugAll("LMC (Lux Model Changer) not available at compile time - will use standard SetEntityModel");
#endif

	// Particles
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(EFIRE_PARTICLE);
	PrecacheParticle(MEDIC_GLOW);
	PrecacheParticle(BOMB_GLOW);

	// Cache
	ClearCache();
	RoundStarted = false;
	LeftSafeAreaMessageShown = false;
	ClassHint = false;
	// Shake

	// Pre-cache env_shake -_- WTF
	int shake = CreateEntityByName("env_shake");
	if( shake != -1 )
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		DispatchKeyValue(shake, "radius", "50");
		TeleportEntity(shake, view_as<float>({ 0.0, 0.0, -1000.0 }), NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");
		AcceptEntityInput(shake, "StartShake");
		RemoveEdict(shake);
	}
}

public void OnMapEnd()
{
	CooldownNotify_OnMapEnd();
	// Cache
	RoundStarted=false;
	LeftSafeAreaMessageShown = false;
	ClearCache();
	OnRoundState(0);
}

public void OnConfigsExecuted()
{
        LoadSkillActionBindings();
        LoadClassSkillConfig();
        RefreshClassSkillAssignments();
        OnPluginReady();
}

public OnPluginReady() {
	
	if(g_bPluginLoaded == false && GetConVarBool(g_hPluginEnabled) == true) {
	
		PrintDebugAll("Talents plugin is now ready");
		Call_StartForward(g_hForwardPluginState);

            Call_PushString("rage_survivor");
		Call_PushCell(1);
		Call_Finish();
		g_bPluginLoaded = true;

		if( g_bLateLoad == true )
		{
			g_bLateLoad = false;
			OnRoundState(1);
		}
	} else if(g_bPluginLoaded == true && GetConVarBool(g_hPluginEnabled) == false) {
		PrintDebugAll("Talents plugin is disabled");
		g_bPluginLoaded = false;
		ResetPlugin();
		Call_StartForward(g_hForwardPluginState);
            Call_PushString("rage_survivor");
		Call_PushCell(0);
		Call_Finish();
	}
}

void ResetPlugin()
{
	RoundStarted=false;
	LeftSafeAreaMessageShown = false;
	g_iPlayerSpawn = false;
}

public OnClientPutInServer(client)
{
        if (!client || !IsValidEntity(client) || !IsClientInGame(client) || g_bPluginLoaded == false)
        return;

        g_iQueuedClass[client] = 0;
        g_bWasHoldingShift[client] = false;
        ResetClientVariables(client);
        RebuildCache();
        HookPlayer(client);
        
        // Auto-bind skill action keys for convenience
        if (!IsFakeClient(client))
        {
                ClientCommand(client, "bind mouse3 +skill_action_1");
                ClientCommand(client, "bind mouse4 +skill_action_2");
                ClientCommand(client, "bind mouse5 +skill_action_3");
                // Deployment now uses mouse3 (middle mouse button) instead of Z
        }
}

public void OnClientCookiesCached(int client)
{
        if (g_hClassCookie == INVALID_HANDLE || IsFakeClient(client) || !IsClientInGame(client))
        {
                return;
        }

        char stored[32];
        GetClientCookie(client, g_hClassCookie, stored, sizeof(stored));
        TrimString(stored);

        if (stored[0] == '\0')
        {
                return;
        }

        ClassTypes storedClass = ClassNameToType(stored);
        if (storedClass == NONE)
        {
                return;
        }

        LastClassConfirmed[client] = view_as<int>(storedClass);
        g_iQueuedClass[client] = 0;

        // Apply the class immediately if player is on survivor team
        if (GetClientTeam(client) == 2)
        {
                ClassTypes oldClass = ClientData[client].ChosenClass;
                
                // Only apply if not already set or if it's different
                if (oldClass != storedClass)
                {
                        // Check if class is available (not full)
                        bool classFull = (GetMaxWithClass(view_as<int>(storedClass)) >= 0 && 
                                        CountPlayersWithClass(view_as<int>(storedClass)) >= GetMaxWithClass(view_as<int>(storedClass)));
                        
                        if (!classFull || oldClass == storedClass)
                        {
                                ClientData[client].ChosenClass = storedClass;
                                
                                // Inform other plugins (only if forward is valid)
                                if (g_hfwdOnPlayerClassChange != INVALID_HANDLE)
                                {
                                        Call_StartForward(g_hfwdOnPlayerClassChange);
                                        Call_PushCell(client);
                                        Call_PushCell(ClientData[client].ChosenClass);
                                        Call_PushCell(LastClassConfirmed[client]);
                                        Call_Finish();
                                }
                                
                                // Setup the class (defer heavy operations to avoid timeout)
                                DataPack pack;
                                CreateDataTimer(0.1, TimerSetupClassOnCookieCached, pack, TIMER_FLAG_NO_MAPCHANGE);
                                pack.WriteCell(GetClientUserId(client));
                                pack.WriteCell(view_as<int>(storedClass));
                                
                                // Show notification
                                PrintToChat(client, "%s✓ Your previous \x04%s\x01 class was auto-selected. Use the Rage menu to change it.", 
                                           PRINT_PREFIX, MENU_OPTIONS[storedClass]);
                                PrintHintText(client, "✓ %s class auto-selected", MENU_OPTIONS[storedClass]);
                        }
                        else
                        {
                                // Class is full, show menu instead
                                PrintToChat(client, "%sYour previous \x04%s\x01 class is full. Please choose another class.", 
                                           PRINT_PREFIX, MENU_OPTIONS[storedClass]);
                                CreateTimer(1.0, CreatePlayerClassMenuDelay, client, TIMER_FLAG_NO_MAPCHANGE);
                        }
                }
                else
                {
                        // Class already set, just notify
                        PrintToChat(client, "%s✓ Your \x04%s\x01 class is active. Use the Rage menu to change it.", 
                                   PRINT_PREFIX, MENU_OPTIONS[storedClass]);
                }
        }
        else
        {
                // Not on survivor team yet, just store it
                PrintToChat(client, "%s✓ Your previous \x04%s\x01 class will be auto-selected when you join survivors.", 
                           PRINT_PREFIX, MENU_OPTIONS[storedClass]);
        }
}

void NotifySelectedClassHint(int client)
{
        if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return;
        }

        ClassTypes classType = ClientData[client].ChosenClass;

        if (classType == NONE && LastClassConfirmed[client] != 0)
        {
                classType = view_as<ClassTypes>(LastClassConfirmed[client]);
        }

        if (classType == NONE)
        {
                return;
        }

        PrintHintText(client, "Class selected: %s", MENU_OPTIONS[classType]);
}

public Action TimerAnnounceSelectedClass(Handle timer, any data)
{
        // Only show hints after intro finishes on first mission
        if (g_bFirstMission && !g_bIntroFinished)
        {
                // Wait a bit and check again
                CreateTimer(1.0, TimerAnnounceSelectedClass, _, TIMER_FLAG_NO_MAPCHANGE);
                return Plugin_Stop;
        }
        
        for (int i = 1; i <= MaxClients; i++)
        {
                NotifySelectedClassHint(i);
        }

        return Plugin_Stop;
}

void DmgHookUnhook(bool enabled)
{
        if( !enabled && g_bDmgHooked )
	{
		g_bDmgHooked = false;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				UnhookPlayer(i);
			}
		}
	}

	if( enabled && !g_bDmgHooked )
	{
		g_bDmgHooked = true;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				HookPlayer(i);
			}
		}
	}
}
public Action:OnWeaponDrop(client, weapon)
{
//	RebuildCache();
}

public Action:OnWeaponSwitch(client, weapon)
{
//	RebuildCache();
}

public Action:OnWeaponEquip(client, weapon)
{
//	RebuildCache();
}

public OnClientDisconnect(client)
{
	CooldownNotify_OnClientDisconnect(client);
        // Close menu if client was holding shift
        if (g_bWasHoldingShift[client])
        {
                FakeClientCommand(client, "-rage_menu");
                g_bWasHoldingShift[client] = false;
        }
        UnhookPlayer(false);
        RebuildCache();
        ResetClientVariables(client);
        g_iQueuedClass[client] = 0;
}

// Inform other plugins.

public void useCustomCommand(char[] pluginName, int client, int entity, int type )
{
	char szPluginName[32];
	Format(szPluginName, sizeof(szPluginName), "%s", pluginName);
	Call_StartForward(g_hfwdOnCustomCommand);

	Call_PushString(szPluginName);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushCell(type);	
	Call_Finish();
}

public Action CmdUseSkill(int client, int args)
{
        useSpecialSkill(client, 0);
        return Plugin_Handled;
}

public Action CmdClassSet(int client, int args)
{
        if (client <= 0 || !IsClientInGame(client))
        {
                return Plugin_Handled;
        }

        if (args < 1)
        {
                PrintToChat(client, "[Rage] Usage: sm_class_set <class_index>");
                PrintToChat(client, "[Rage] 1=Soldier, 2=Athlete, 3=Medic, 4=Saboteur, 5=Commando, 6=Engineer, 7=Brawler");
                return Plugin_Handled;
        }

        char arg[8];
        GetCmdArg(1, arg, sizeof(arg));
        int classIndex = StringToInt(arg);

        if (classIndex < 1 || classIndex >= view_as<int>(MAXCLASSES))
        {
                PrintToChat(client, "[Rage] Invalid class index. Use 1-7.");
                return Plugin_Handled;
        }

        // Get configured preview duration
        float previewDuration = GetConVarFloat(CLASS_PREVIEW_DURATION);

        // Enable third person view for class preview
        ForceThirdPersonView(client, previewDuration);
        g_bClassSelectionThirdPerson[client] = true;

        // Change to the selected class
        SetupClasses(client, classIndex);
        LastClassConfirmed[client] = classIndex;
        g_iQueuedClass[client] = 0;
        SaveClassCookie(client, view_as<ClassTypes>(classIndex));

        // Schedule return to normal view
        CreateTimer(previewDuration, Timer_ReturnFromThirdPerson, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

        return Plugin_Handled;
}

public Action CmdClassMenu(int client, int args)
{
        if (client <= 0 || !IsClientInGame(client))
        {
                return Plugin_Handled;
        }

        if (GetClientTeam(client) != 2)
        {
                PrintToChat(client, "[Rage] Class selection is only available for survivors.");
                return Plugin_Handled;
        }

        if (!CreatePlayerClassMenu(client))
        {
                PrintToChat(client, "[Rage] Class menu is unavailable right now. Try again in a moment.");
        }

        return Plugin_Handled;
}

public Action CmdClassInfo(int client, int args)
{
        if (client <= 0 || !IsClientInGame(client))
        {
                return Plugin_Handled;
        }

        PrintToChat(client, "[Rage] === Class Descriptions ===");
        for (int i = 1; i < view_as<int>(MAXCLASSES); i++)
        {
                PrintToChat(client, "[Rage] %s: %s", MENU_OPTIONS[i], g_ClassDescriptions[i]);
        }
        return Plugin_Handled;
}

public Action CmdClasses(int client, int args)
{
        return CmdClassInfo(client, args);
}

// Timer to return player from third person after class selection
public Action Timer_ReturnFromThirdPerson(Handle timer, int userid)
{
        int client = GetClientOfUserId(userid);
        if (client <= 0 || !IsClientInGame(client))
        {
                return Plugin_Stop;
        }

        if (g_bClassSelectionThirdPerson[client])
        {
                // Reset third person view by setting the time to 0
                SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
                g_bClassSelectionThirdPerson[client] = false;
        }

        return Plugin_Stop;
}

// Force third person view for specified duration
void ForceThirdPersonView(int client, float duration)
{
        if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
                return;
        }

        float gameTime = GetGameTime();
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", gameTime + duration);
}

// Precache all class models during map start to avoid runtime frame drops
void PrecacheClassModels()
{
        for (int i = 0; i < sizeof(ClassCustomModels); i++)
        {
                char model[PLATFORM_MAX_PATH];
                strcopy(model, sizeof(model), ClassCustomModels[i]);
                
                // Validate model path is not empty
                if (strlen(model) == 0)
                {
                        LogError("Empty model path at index %d in ClassCustomModels array", i);
                        continue;
                }
                
                if (!IsModelPrecached(model))
                {
                        PrecacheModel(model, true);
                        PrintDebugAll("Precached class model: %s (index: %d)", model, i);
                }
                else
                {
                        PrintDebugAll("Model %s already precached (index: %d)", model, i);
                }
        }
}

// Apply class-specific character model using LMC (if available)
void ApplyClassModel(int client, ClassTypes classType)
{
        if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
                return;
        }

        // Get model from ClassCustomModels array
        int classIndex = view_as<int>(classType);
        if (classIndex < 0 || classIndex >= sizeof(ClassCustomModels))
        {
                LogError("Invalid class index %d for model assignment (max: %d)", classIndex, sizeof(ClassCustomModels) - 1);
                return;
        }

        char model[PLATFORM_MAX_PATH];
        strcopy(model, sizeof(model), ClassCustomModels[classIndex]);
        
        // Validate model path
        if (strlen(model) == 0)
        {
                LogError("Empty model path for class %d (%s)", classIndex, MENU_OPTIONS[classIndex]);
                return;
        }
        
        // Models should already be precached in OnMapStart - verify and warn
        if (!IsModelPrecached(model))
        {
                LogError("Model %s not precached for class %d (%s)! This should have been done in OnMapStart().", model, classIndex, MENU_OPTIONS[classIndex]);
                // Don't attempt to precache here - it won't work during gameplay
                // Still try to apply with SetEntityModel as fallback
        }
        
#if LMC_AVAILABLE
        // Check if LMC library is actually loaded at runtime (not just available at compile time)
        if (LibraryExists("LMCCore"))
        {
                // Verify client is still valid before LMC call
                if (!IsClientInGame(client) || !IsPlayerAlive(client))
                {
                        LogError("Client %d became invalid before LMC model application", client);
                        return;
                }
                
                // Use LMC to apply the model overlay
                int overlayIndex = LMC_SetClientOverlayModel(client, model);
                if (overlayIndex > 0)
                {
                        // Verify client is still valid after LMC call
                        if (!IsClientInGame(client) || !IsPlayerAlive(client))
                        {
                                LogError("Client %d became invalid after LMC_SetClientOverlayModel", client);
                                return;
                        }
                        
#if LMC_SETTRANSMIT_AVAILABLE
                        // Check if SetTransmit module is loaded at runtime
                        if (LibraryExists("LMCL4D2SetTransmit"))
                        {
                                // Enable SetTransmit for L4D2 compatibility
                                if (!LMC_L4D2_SetTransmit(client, overlayIndex, true))
                                {
                                        LogError("Failed to set LMC SetTransmit for client %d, overlay %d", client, overlayIndex);
                                }
                                else
                                {
                                        PrintDebugAll("LMC SetTransmit enabled for client %d, overlay %d", client, overlayIndex);
                                }
                        }
                        else
                        {
                                PrintDebugAll("LMCL4D2SetTransmit library not loaded - SetTransmit not configured for client %d", client);
                        }
#endif
                        PrintDebugAll("Applied LMC model %s to client %d (class: %d, overlay: %d)", model, client, classType, overlayIndex);
                        return;
                }
                else
                {
                        LogError("LMC_SetClientOverlayModel failed for client %d, model: %s (returned: %d). Falling back to SetEntityModel.", client, model, overlayIndex);
                }
        }
        else
        {
                PrintDebugAll("LMCCore library not loaded at runtime - using fallback SetEntityModel for client %d", client);
        }
#else
        PrintDebugAll("LMC not available at compile time - using fallback SetEntityModel for client %d", client);
#endif
        
        // Fallback to standard SetEntityModel if LMC is unavailable or failed
        // Verify client is still valid before applying model
        if (!IsClientInGame(client) || !IsPlayerAlive(client))
        {
                LogError("Client %d became invalid before SetEntityModel fallback", client);
                return;
        }
        
        SetEntityModel(client, model);
        PrintDebugAll("Using fallback SetEntityModel for client %d (class: %d, model: %s) - LMC unavailable or failed", client, classType, model);
}

bool TryExecuteSkillInput(int client, ClassSkillInput input)
{
        if (client < 1 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return false;
        }

        ClassTypes classType = ClientData[client].ChosenClass;
        if (classType == NONE)
        {
                PrintHintText(client, "Select a class from the Rage menu first.");
                return false;
        }

        if (!TryTriggerClassSkillAction(client, classType, input))
        {
                // Don't show generic message - canUseSpecialSkill already shows specific hints
                // Only show this if the action mode is None (no action bound)
                if (g_ClassActionMode[classType][input] != ActionMode_None)
                {
                        // Skill exists but can't be used - canUseSpecialSkill already showed the reason
                        return false;
                }
                PrintHintText(client, "No action is bound to that input for %s.", MENU_OPTIONS[classType]);
                return false;
        }

        return true;
}

public Action CmdSkillAction1(int client, int args)
{
        if (client < 1 || !IsClientInGame(client))
        {
                return Plugin_Handled;
        }
        
        TryExecuteSkillInput(client, ClassSkill_Special);
        return Plugin_Handled;
}

public Action CmdSkillAction2(int client, int args)
{
        if (client < 1 || !IsClientInGame(client))
        {
                return Plugin_Handled;
        }
        
        TryExecuteSkillInput(client, ClassSkill_Secondary);
        return Plugin_Handled;
}

public Action CmdSkillAction3(int client, int args)
{
        if (client < 1 || !IsClientInGame(client))
        {
                return Plugin_Handled;
        }
        
        TryExecuteSkillInput(client, ClassSkill_Tertiary);
        return Plugin_Handled;
}

public Action CmdSkillAction1Release(int client, int args)
{
        // Release version - do nothing, skill already triggered on press
        return Plugin_Handled;
}

public Action CmdSkillAction2Release(int client, int args)
{
        // Release version - do nothing, skill already triggered on press
        return Plugin_Handled;
}

public Action CmdSkillAction3Release(int client, int args)
{
        // Release version - do nothing, skill already triggered on press
        return Plugin_Handled;
}

public Action CmdDeploymentAction(int client, int args)
{
        if (client < 1 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return Plugin_Handled;
        }

        ClassTypes classType = ClientData[client].ChosenClass;
        if (classType == NONE)
        {
                PrintHintText(client, "Select a class from the Rage menu first.");
                return Plugin_Handled;
        }

        // Check if deployment is configured
        if (g_ClassActionMode[classType][ClassSkill_Deploy] == ActionMode_None)
        {
                PrintHintText(client, "No deployment action configured for %s.", MENU_OPTIONS[classType]);
                return Plugin_Handled;
        }

        // For builtin actions (menus), skip cooldown check - let the menu handle its own restrictions
        if (g_ClassActionMode[classType][ClassSkill_Deploy] == ActionMode_Builtin)
        {
                ExecuteClassAction(client, classType, ClassSkill_Deploy);
                return Plugin_Handled;
        }

        // For other actions, check cooldown and limits normally
        TryExecuteSkillInput(client, ClassSkill_Deploy);
        return Plugin_Handled;
}

public void useSpecialSkill(int client, int type)
{
	int skill = g_iPlayerSkill[client];

	if (g_iPlayerSkill[client] >= 0) {
		Call_StartForward(g_hfwdOnSpecialSkillUsed);
		Call_PushCell(client);
		Call_PushCell(skill); 
		Call_PushCell(type);		
		Call_Finish();
	}

}	

bool canUseSpecialSkill(client, char[] pendingMessage, bool ignorePinned = false)
{	
	// Validate client first
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return false;
	}

	new Float:fCanDropTime = (GetGameTime() - ClientData[client].LastDropTime);
	if (ClientData[client].LastDropTime == 0) {
		fCanDropTime+=ClientData[client].SpecialDropInterval;
	}
	new bool:CanDrop = (fCanDropTime >= ClientData[client].SpecialDropInterval);
	char pendMsg[128];
	char outOfMsg[128];

	int iDropTime = RoundToFloor(fCanDropTime);

	if (IsPlayerInSaferoom(client) || IsInEndingSaferoom(client)) {
		PrintHintText(client, "Cannot deploy here");
		return false;
	}
	
	// Check if player is pinned or incapacitated (removed duplicate check)
	if ((FindAttacker(client) > 0 || IsIncapacitated(client)) && ignorePinned == false) {
		PrintHintText(client, "You're too screwed to use special skills");
		return false;
	}
	
	if (CanDrop == false)
	{
		Format(pendMsg, sizeof(pendMsg), pendingMessage, (ClientData[client].SpecialDropInterval-iDropTime));
		// Always show cooldown message when skill can't be used
		PrintHintText(client, pendMsg);
		return false;
	} 
	else if (ClientData[client].SpecialsUsed >= ClientData[client].SpecialLimit) {
		int limit = ClientData[client].SpecialLimit;
		if (limit > 0) {
			Format(outOfMsg, sizeof(outOfMsg), "You're out of supplies! (Max %d / round)", ClientData[client].SpecialLimit);
			PrintHintText(client, outOfMsg);
		}
		return false;
	} 

	return true;
}

stock SetupProgressBar(client, Float:time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock KillProgressBar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

public ShowBar(client, String:msg[], Float:pos, Float:max)
{
	char Gauge1[2] = "-";
	char Gauge3[2] = "#";
	new i;
	char ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
	
	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
	GaugeNum = 100.0;
	if(GaugeNum<0.0)
	GaugeNum = 0.0;
	for(i=0; i<100; i++)
	ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0]; 
	/* Display gauge */
	PrintHintText(client, "%s  %3.0f / 100% %\n<< %s >>", msg, GaugeNum, ChargeBar);
}

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
        for (new i = 1; i < MAXPLAYERS; i++)
        {
                ResetClientVariables(i);
                if (g_iQueuedClass[i] != 0)
                {
                        LastClassConfirmed[i] = g_iQueuedClass[i];
                }
                g_iQueuedClass[i] = 0;
                DisableAllUpgrades(i);
        }

	DmgHookUnhook(false);
	
	RndSession++;
	RoundStarted = false;
	LeftSafeAreaMessageShown = false;
	g_bIntroFinished = false;
	g_bFirstMission = false; // Will be recalculated on next round_start
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
        if( g_iPlayerSpawn == true && RoundStarted == true )
                CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);

        RoundStarted = true;
        
        // Check if this is the first mission (campaign start)
        char mapname[64];
        GetCurrentMap(mapname, sizeof(mapname));
        // First mission maps typically start with "c1m1", "c2m1", etc.
        g_bFirstMission = (StrContains(mapname, "m1_", false) != -1 || StrContains(mapname, "_01_", false) != -1);
        
        // Reset intro finished flag for new round
        g_bIntroFinished = false;
        
        // Only show hints after intro finishes (for first mission) or immediately (for other maps)
        if (g_bFirstMission)
        {
                // Wait for intro to finish before showing hints
                // L4D_OnFinishIntro forward will handle this
        }
        else
        {
                // Not first mission - show hints immediately
                CreateTimer(2.0, TimerAnnounceSelectedClass, _, TIMER_FLAG_NO_MAPCHANGE);
        }
}

public void L4D_OnFinishIntro()
{
        // Intro cutscene finished - safe to show hints now
        g_bIntroFinished = true;
        if (RoundStarted)
        {
                CreateTimer(1.0, TimerAnnounceSelectedClass, _, TIMER_FLAG_NO_MAPCHANGE);
        }
}

public void OnRoundState(int roundstate)
{
        static int rageState;

        if( roundstate == 1 && rageState == 0 )
        {
                rageState = 1;
                Call_StartForward(g_hForwardRoundState);
                Call_PushCell(1);
                Call_Finish();
        }
        else if( roundstate == 0 && rageState == 1 )
        {
                rageState = 0;
                Call_StartForward(g_hForwardRoundState);
                Call_PushCell(0);
                Call_Finish();
        }
}

public Event_PlayerSpawn(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

        if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		GetClientAbsOrigin(client, g_SpawnPos[client]);
		
		if (GetClientTeam(client) == 2)
		{
                        int userid = GetClientUserId(client);
                        CreateTimer(0.3, TimerLoadClient, client, TIMER_FLAG_NO_MAPCHANGE);
                        CreateTimer(0.1, TimerThink, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

                        if (LastClassConfirmed[client] != 0)
                        {
                                ClassTypes restoredClass = view_as<ClassTypes>(LastClassConfirmed[client]);
                                
                                // Check if class is available (not full)
                                bool classFull = (GetMaxWithClass(LastClassConfirmed[client]) >= 0 && 
                                                CountPlayersWithClass(LastClassConfirmed[client]) >= GetMaxWithClass(LastClassConfirmed[client]));
                                
                                if (!classFull || ClientData[client].ChosenClass == restoredClass)
                                {
                                        ClassTypes oldClass = ClientData[client].ChosenClass;
                                        ClientData[client].ChosenClass = restoredClass;
                                        
                                        // Inform other plugins if class changed
                                        if (oldClass != restoredClass)
                                        {
                                                Call_StartForward(g_hfwdOnPlayerClassChange);
                                                Call_PushCell(client);
                                                Call_PushCell(ClientData[client].ChosenClass);
                                                Call_PushCell(LastClassConfirmed[client]);
                                                Call_Finish();
                                        }
                                        
                                SetupClasses(client, LastClassConfirmed[client]);
                                        
                                        // Apply model to ensure it persists
                                        ApplyClassModel(client, restoredClass);
                                        
                                        // Show notification that class was auto-selected (only after intro on first mission)
                                        if (oldClass == NONE)
                                        {
                                                if (!g_bFirstMission || g_bIntroFinished)
                                                {
                                                        PrintToChat(client, "%s✓ Your previous \x04%s\x01 class was auto-selected.", 
                                                                   PRINT_PREFIX, MENU_OPTIONS[restoredClass]);
                                                        PrintHintText(client, "✓ %s class auto-selected", MENU_OPTIONS[restoredClass]);
                                                }
                                        }
                                        
                                        // Show class info (only after intro on first mission)
                                        if (!g_bFirstMission || g_bIntroFinished)
                                        {
                                                ShowClassHud(client, false);
                                                ShowClassSelectionInfo(client, restoredClass);
                                        }
                        }
                        else
                        {
                                // Class is full, show menu instead
                                PrintToChat(client, "%sYour previous \x04%s\x01 class is full. Please choose another class.", 
                                           PRINT_PREFIX, MENU_OPTIONS[restoredClass]);
                                CreateTimer(1.0, CreatePlayerClassMenuDelay, client, TIMER_FLAG_NO_MAPCHANGE);
                        }
                }
                else
                {
                        // No class selected - show class selection menu
                        if (ClientData[client].ChosenClass == NONE)
                        {
                                CreateTimer(1.0, CreatePlayerClassMenuDelay, client, TIMER_FLAG_NO_MAPCHANGE);
                        }
                }

                        CreateTimer(2.0, TimerAnnounceSelectedClassHint, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        ShowAthleteAbilityHint(client);
                        
                        // Re-bind skill action keys on spawn to ensure they work
                        if (!IsFakeClient(client))
                        {
                                CreateTimer(1.0, TimerBindSkillActions, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                }

                g_iPlayerSpawn = true;
        }
}

public Action TimerSetupClassOnCookieCached(Handle timer, DataPack pack)
{
        pack.Reset();
        int userid = pack.ReadCell();
        int classIndex = pack.ReadCell();
        delete pack;
        
        int client = GetClientOfUserId(userid);
        if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return Plugin_Stop;
        }
        
        // Verify the class is still valid
        ClassTypes classType = view_as<ClassTypes>(classIndex);
        if (ClientData[client].ChosenClass != classType)
        {
                return Plugin_Stop;
        }
        
        // Setup the class
        SetupClasses(client, classIndex);
        RebuildCache();
        
        // Show class info
        ShowClassHud(client, false);
        ShowClassSelectionInfo(client, classType);
        
        return Plugin_Stop;
}

void ShowSelectedClassHint(int client)
{
        if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return;
        }

        ClassTypes classType = ClientData[client].ChosenClass;
        if (classType == NONE)
        {
                PrintHintText(client, "Select a class from the Rage menu first.");
                return;
        }

        PrintHintText(client, "You are playing as %s. Use your skill binds to activate abilities.", MENU_OPTIONS[classType]);
}

public void ShowClassSelectionInfo(int client, ClassTypes classType)
{
        if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || classType == NONE)
        {
                return;
        }

        // Show class description first
        char classDesc[128];
        strcopy(classDesc, sizeof(classDesc), g_DefaultClassDescriptions[classType]);
        
        PrintHintText(client, "%s: %s", MENU_OPTIONS[classType], classDesc);
        
        // Then show skill bindings after a short delay
        CreateTimer(0.5, Timer_ShowClassSkillBindings, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ShowClassSkillBindings(Handle timer, any userid)
{
        int client = GetClientOfUserId(userid);
        if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        {
                return Plugin_Stop;
        }
        
        ClassTypes classType = ClientData[client].ChosenClass;
        if (classType == NONE)
        {
                return Plugin_Stop;
        }
        
        ShowClassSkillBindings(client, classType);
        return Plugin_Stop;
}

public void ShowClassSkillBindings(int client, ClassTypes classType)
{
        if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || classType == NONE)
        {
                return;
        }

        char hintText[512];
        char binding[64];
        char skillName[64];
        int partCount = 0;

        // Check Special skill (Primary)
        if (g_ClassActionMode[classType][ClassSkill_Special] != ActionMode_None)
        {
                GetActionBindingLabel(ClassSkill_Special, binding, sizeof(binding));
                
                if (g_ClassActionMode[classType][ClassSkill_Special] == ActionMode_Skill && g_ClassActionSkillName[classType][ClassSkill_Special][0] != '\0')
                {
                        strcopy(skillName, sizeof(skillName), g_ClassActionSkillName[classType][ClassSkill_Special]);
                }
                else if (g_ClassActionMode[classType][ClassSkill_Special] == ActionMode_Builtin)
                {
                        // Builtin actions don't have skill names, skip them
                        skillName[0] = '\0';
                }
                else
                {
                        skillName[0] = '\0';
                }
                
                if (skillName[0] != '\0')
                {
                        if (partCount > 0)
                        {
                                StrCat(hintText, sizeof(hintText), ", ");
                        }
                        Format(hintText, sizeof(hintText), "%s%s for %s", hintText, binding, skillName);
                        partCount++;
                }
        }

        // Check Secondary skill
        if (g_ClassActionMode[classType][ClassSkill_Secondary] != ActionMode_None)
        {
                GetActionBindingLabel(ClassSkill_Secondary, binding, sizeof(binding));
                
                if (g_ClassActionMode[classType][ClassSkill_Secondary] == ActionMode_Skill && g_ClassActionSkillName[classType][ClassSkill_Secondary][0] != '\0')
                {
                        strcopy(skillName, sizeof(skillName), g_ClassActionSkillName[classType][ClassSkill_Secondary]);
                }
                else
                {
                        skillName[0] = '\0';
                }
                
                if (skillName[0] != '\0')
                {
                        if (partCount > 0)
                        {
                                StrCat(hintText, sizeof(hintText), ", ");
                        }
                        Format(hintText, sizeof(hintText), "%s%s for %s", hintText, binding, skillName);
                        partCount++;
                }
        }

        // Check Tertiary skill
        if (g_ClassActionMode[classType][ClassSkill_Tertiary] != ActionMode_None)
        {
                GetActionBindingLabel(ClassSkill_Tertiary, binding, sizeof(binding));
                
                if (g_ClassActionMode[classType][ClassSkill_Tertiary] == ActionMode_Skill && g_ClassActionSkillName[classType][ClassSkill_Tertiary][0] != '\0')
                {
                        strcopy(skillName, sizeof(skillName), g_ClassActionSkillName[classType][ClassSkill_Tertiary]);
                }
                else
                {
                        skillName[0] = '\0';
                }
                
                if (skillName[0] != '\0')
                {
                        if (partCount > 0)
                        {
                                StrCat(hintText, sizeof(hintText), ", ");
                        }
                        Format(hintText, sizeof(hintText), "%s%s for %s", hintText, binding, skillName);
                        partCount++;
                }
        }

        // Check Deployment action
        if (g_ClassActionMode[classType][ClassSkill_Deploy] != ActionMode_None)
        {
                GetActionBindingLabel(ClassSkill_Deploy, binding, sizeof(binding));
                
                // Get deployment action name
                if (g_ClassActionMode[classType][ClassSkill_Deploy] == ActionMode_Builtin)
                {
                        switch (g_ClassActionBuiltin[classType][ClassSkill_Deploy])
                        {
                                case Builtin_MedicSupplies:
                                {
                                        strcopy(skillName, sizeof(skillName), "Medic Supplies Menu");
                                }
                                case Builtin_EngineerSupplies:
                                {
                                        if (classType == engineer)
                                        {
                                                strcopy(skillName, sizeof(skillName), "Turret Selection Menu");
                                        }
                                        else
                                        {
                                                strcopy(skillName, sizeof(skillName), "Engineer Supplies Menu");
                                        }
                                }
                                case Builtin_SaboteurMines:
                                {
                                        strcopy(skillName, sizeof(skillName), "Saboteur Mines Menu");
                                }
                                default:
                                {
                                        strcopy(skillName, sizeof(skillName), "Deploy");
                                }
                        }
                }
                else if (g_ClassActionMode[classType][ClassSkill_Deploy] == ActionMode_Skill && g_ClassActionSkillName[classType][ClassSkill_Deploy][0] != '\0')
                {
                        strcopy(skillName, sizeof(skillName), g_ClassActionSkillName[classType][ClassSkill_Deploy]);
                }
                else
                {
                        strcopy(skillName, sizeof(skillName), "Deploy");
                }
                
                if (partCount > 0)
                {
                        StrCat(hintText, sizeof(hintText), ", ");
                }
                Format(hintText, sizeof(hintText), "%s%s to deploy %s", hintText, binding, skillName);
                partCount++;
        }

        if (hintText[0] != '\0')
        {
                PrintHintText(client, "%s", hintText);
        }
}

public Action TimerAnnounceSelectedClassHint(Handle timer, any userid)
{
        int client = GetClientOfUserId(userid);
        if (client <= 0 || client > MaxClients)
        {
                return Plugin_Stop;
        }

        ShowSelectedClassHint(client);
        return Plugin_Stop;
}

public Action TimerBindSkillActions(Handle timer, any userid)
{
        int client = GetClientOfUserId(userid);
        if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        {
                return Plugin_Stop;
        }
        
        // Bind skill action keys
        ClientCommand(client, "bind mouse3 +skill_action_1");
        ClientCommand(client, "bind mouse4 +skill_action_2");
        ClientCommand(client, "bind mouse5 +skill_action_3");
        
        return Plugin_Stop;
}

void ShowAthleteAbilityHint(int client)
{
        if (ClientData[client].ChosenClass != athlete || GetClientTeam(client) != 2)
        {
                return;
        }

        if (GetConVarBool(ATHLETE_PARACHUTE_ENABLED))
        {
                PrintHintText(client, "Hold USE mid-air to glide with your parachute. Sprint + JUMP to throw a ninja kick.");
        }
        else
        {
                PrintHintText(client, "Sprint + JUMP to throw a ninja kick.");
        }
}

public Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new isFake = GetEventInt(hEvent, "isfakedeath",0);
	if (isFake == 1) return;

	RebuildCache();
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2) DisableAllUpgrades(client);

	ResetClientVariables(client);
}

public Event_EnterSaferoom(Handle:event, String:Event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = true;
}

public Event_LeftSaferoom(Handle:event, String:Event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = false;
}

public Action:Event_LeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = true;
	if (!LeftSafeAreaMessageShown)
	{
		LeftSafeAreaMessageShown = true;
		PrintToChatAll("%s Players left safe area, classes now locked!",PRINT_PREFIX);
	}
}

public Event_PlayerTeam(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new team = GetEventInt(hEvent, "team");
	
        if (team == 2 && LastClassConfirmed[client] != 0)
        {
                ClientData[client].ChosenClass = view_as<ClassTypes>(LastClassConfirmed[client]);
                PrintToChat(client, "\x01You are currently a \x04%s\x01. Mid-round changes apply next round.", MENU_OPTIONS[LastClassConfirmed[client]]);
                NotifySelectedClassHint(client);
        }
}

///////////////////////////////////////////////////////////////////////////////////
// Class selections
///////////////////////////////////////////////////////////////////////////////////

public int GetMaxWithClass( class ) {

	switch(view_as<ClassTypes>(class)) {
		case soldier:
		return GetConVarInt( MAX_SOLDIER );
		case athlete:
		return GetConVarInt( MAX_ATHLETE );
		case medic:
		return GetConVarInt( MAX_MEDIC );
		case saboteur:
		return GetConVarInt( MAX_SABOTEUR );
		case commando:
		return GetConVarInt( MAX_COMMANDO );
		case engineer:
		return GetConVarInt( MAX_ENGINEER );
		case brawler:
		return GetConVarInt( MAX_BRAWLER );
		default:
		return -1;
	}
}

public int FindSkillIdByName(char[] name)
{
	int index = FindStringInArray(g_hSkillArray, name);
	return index;
}

public Native_FindSkillNameById(Handle:plugin, numParams)
{
	new skillId = GetNativeCell(1);

	if (skillId < 0 || skillId > 32)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid skill index (%d)", skillId);
	}
	int iSize = 32;
	char buffer[32];

	GetArrayString(g_hSkillArray, skillId, buffer, iSize);
	SetNativeString(2, buffer, iSize);	
	return;
}

public Native_FindSkillIdByName(Handle:plugin, numParams)
{
	int len;
	GetNativeStringLength(1, len);
 
	if (len <= 0)
	{
		return -1;
	}
 
	char[] szSkillName = new char[len + 1];
	GetNativeString(1, szSkillName, len + 1);	
	if(strlen(szSkillName) > 0)
	{
		return FindSkillIdByName(szSkillName);
		
	} else {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid skill name (%s)", szSkillName);
	}	
}

public Native_GetPlayerClassName(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	new iSize = GetNativeCell(3);
	char szSkillName[32];
	Format(szSkillName, iSize, "%s", MENU_OPTIONS[ClientData[client].ChosenClass]);
	SetNativeString(2, szSkillName, iSize);	
	return;
}

public PlayerIdToSkillName(int client, char[] name, int size)
{
	char szSkillName[32] = "None";
	int iSize = 32;
	char buffer[32];

	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		Format(name, size, "%s", szSkillName);
	}
	if (g_iPlayerSkill[client] > -1) {
		GetArrayString(g_hSkillArray, g_iPlayerSkill[client], buffer, iSize);
	}
	Format(name, iSize, "%s", buffer);
}

public PlayerIdToClassName(int client, char[] name, int size)
{
	if (!client ||  !IsClientInGame(client) || GetClientTeam(client) != 2) {
		return;
	}
	Format(name, size, "%s", MENU_OPTIONS[ClientData[client].ChosenClass]);
}

////////////////////
/// Skill register 
////////////////////

public Native_GetPlayerSkillID(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
    return g_iPlayerSkill[client];
}

public Native_GetPlayerSkillName(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}

	int iSize = GetNativeCell(3);
	char szSkillName[32];
	int index = g_iPlayerSkill[client];
	if (index >= 0) {
		GetArrayString(g_hSkillArray, index, szSkillName, iSize);
		PrintDebugAll("Found player skillname %s, %i", szSkillName, index);
		SetNativeString(2, szSkillName, iSize);
		return true;
	}
	return false;
} 

public UpgradeQuickHeal(client)
{
	if(ClientData[client].ChosenClass == medic)
	SetConVarFloat(g_flFirstAidDuration, FirstAidDuration * GetConVarFloat(MEDIC_HEAL_RATIO), false, false);
	else
	SetConVarFloat(g_flFirstAidDuration, FirstAidDuration * 1.0, false, false);
}

public UpgradeQuickRevive(client)
{
	if(ClientData[client].ChosenClass == medic)
	SetConVarFloat(g_flReviveDuration, ReviveDuration * GetConVarFloat(MEDIC_REVIVE_RATIO), false, false);
	else
	SetConVarFloat(g_flReviveDuration, ReviveDuration * 1.0, false, false);
}

public setPlayerHealth(client, MaxPossibleHP)
{
	if (!client) return;
	new OldMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	new OldHealth = GetClientHealth(client);
	new OldTempHealth = GetClientTempHealth(client);
	if (MaxPossibleHP == OldMaxHealth) return;

	SetEntProp(client, Prop_Send, "m_iMaxHealth", MaxPossibleHP);
	SetEntityHealth(client, MaxPossibleHP - (OldMaxHealth - OldHealth));
	SetClientTempHealth(client, OldTempHealth);
	
	if ((GetClientHealth(client) + GetClientTempHealth(client)) > MaxPossibleHP)
	{
		SetEntityHealth(client, MaxPossibleHP);
		SetClientTempHealth(client, 0);
	}
}

public setPlayerDefaultHealth(client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2)
	return;
	
	new MaxPossibleHP = GetConVarInt(NONE_HEALTH);
	setPlayerHealth(client, MaxPossibleHP);
}

stock GetClientTempHealth(client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	{
		return -1;
	}
	
	new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	
	new Float:TempHealth;
	
	if (buffer <= 0.0)
	TempHealth = 0.0;
	else
	{
		new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		new Float:constant = 1.0/decay;
		TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	TempHealth = 0.0;
	
	return RoundToFloor(TempHealth);
}

stock SetClientTempHealth(client, iValue)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, iValue);
	
	CreateTimer(0.1, TimerSetClientTempHealth, hPack, TIMER_FLAG_NO_MAPCHANGE);
}

//////////////////////////////////////////7
// Health 
///////////////////////////////////////////

public void Event_ServerCvar( Event hEvent, const char[] sNamel, bool bDontBroadcast ) 
{
	if (GetConVarBool(HEALTH_MODIFIERS_ENABLED) == false) return;
	
	InitHealthModifiers();
}

public Event_HealBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickHeal(client);
}

public Event_ReviveBegin(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpgradeQuickRevive(client);
}
public ApplyHealthModifiers()
{
	FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
	ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));
	g_flFirstAidDuration = FindConVar("first_aid_kit_use_duration");
	g_flReviveDuration = FindConVar("survivor_revive_duration");
}

public InitHealthModifiers()
{
	FindConVar("first_aid_heal_percent").FloatValue = 1.0; 	
	FindConVar("first_aid_kit_use_duration").IntValue = GetConVarInt(HEAL_DURATION); 
	FindConVar("survivor_revive_duration").IntValue = GetConVarInt(REVIVE_DURATION);
	FindConVar("survivor_revive_health").IntValue = GetConVarInt(REVIVE_HEALTH);
	FindConVar("pain_pills_health_value").IntValue = GetConVarInt(PILLS_HEALTH_BUFFER);
	FindConVar("adrenaline_duration").IntValue = GetConVarInt(ADRENALINE_DURATION); 
	FindConVar("adrenaline_health_buffer").IntValue = GetConVarInt(ADRENALINE_HEALTH_BUFFER);
	SetConVarFloat(FindConVar("first_aid_kit_use_duration"), GetConVarFloat(HEAL_DURATION), false, false);
	SetConVarFloat(FindConVar("survivor_revive_duration"), GetConVarFloat(REVIVE_DURATION), false, false);	
	ApplyHealthModifiers();	
}

///////////////////////////////////////////////////////////////////////////////////
// Commando
///////////////////////////////////////////////////////////////////////////////////

public Action L4D_OnKnockedDown(int client, int reason)
{
	if( GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK) && ClientData[client].ChosenClass == commando && reason == 2 )
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
	if( GetConVarBool(COMMANDO_ENABLE_STUMBLE_BLOCK) && ClientData[player].ChosenClass == commando)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Event_RelCommandoClass(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (ClientData[client].ChosenClass != commando)
	return;
	
	int weapon = GetEntDataEnt2(client, g_iActiveWeapon);

	if (!IsValidEntity(weapon))
	return;
	PrintDebugAll("\x03Client \x01%i\x03; start of reload detected",client );
	float flGameTime = GetGameTime();
	float flNextTime_calc;
	decl String:bNetCl[64];
	decl String:stClass[32];
	float flStartTime_calc;
	GetEntityNetClass(weapon, bNetCl, sizeof(bNetCl));
	GetEntityNetClass(weapon,stClass,32);
	PrintDebugAll("\x03-class of gun: \x01%s",stClass );

	if (StrContains(bNetCl, "shotgun", false) == -1)
	{

		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, client);
		float flNextPrimaryAttack = GetEntDataFloat(weapon, g_iNextPrimaryAttack);		
		PrintDebugAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextPrimaryAttack,
		GetEntDataFloat(weapon,g_iNextPrimaryAttack),
		g_iTimeWeaponIdle,
		GetEntDataFloat(weapon,g_iTimeWeaponIdle)
		);

		new Float:fReloadRatio = g_flReloadRate;
		flNextTime_calc = (flNextPrimaryAttack - flGameTime) * fReloadRatio;

		SetEntDataFloat(weapon, g_iPlaybackRate, 1.0 / fReloadRatio, true);
		CreateTimer( flNextTime_calc, CommandoRelFireEnd, weapon);

		flStartTime_calc = flGameTime - ( flNextPrimaryAttack - flGameTime ) * ( 1 - fReloadRatio ) ;
		WritePackFloat(hPack, flStartTime_calc);
		if ( (flNextTime_calc - 0.4) > 0 )
			CreateTimer( flNextTime_calc - 0.4 , CommandoRelFireEnd2, hPack);
		
		flNextTime_calc += flGameTime;
		SetEntDataFloat(weapon, g_iTimeWeaponIdle, flNextTime_calc, true);
		SetEntDataFloat(weapon, g_iNextPrimaryAttack, flNextTime_calc, true);
		SetEntDataFloat(client, g_iNextAttack, flNextTime_calc, true);
		PrintDebugAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextPrimaryAttack,
		GetEntDataFloat(weapon,g_iNextPrimaryAttack),
		g_iTimeWeaponIdle,
		GetEntDataFloat(weapon,g_iTimeWeaponIdle)
		);
	}
	else
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);
		WritePackCell(hPack, client);		

		if (StrContains(bNetCl, "CShotgun_SPAS", false) != -1)
		{
				PrintDebugAll("Shotgun Class: %s", stClass);
			WritePackFloat(hPack, g_flShotgunSpasS);
			WritePackFloat(hPack, g_flShotgunSpasI);
			WritePackFloat(hPack, g_flShotgunSpasE);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "pumpshotgun", false) != -1)
		{

			WritePackFloat(hPack, g_flPumpShotgunS);
			WritePackFloat(hPack, g_flPumpShotgunI);
			WritePackFloat(hPack, g_flPumpShotgunE);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "autoshotgun", false) != -1)
		{
			WritePackFloat(hPack, g_flAutoShotgunS);
			WritePackFloat(hPack, g_flAutoShotgunI);
			WritePackFloat(hPack, g_flAutoShotgunE);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else {
			PrintDebugAll("\x03 did not find: \x01%s",stClass );
			CloseHandle(hPack);

		}
	}
}

public Action:CommandoRelFireEnd(Handle:timer, any:weapon)
{
	if (weapon <= 0 || !IsValidEntity(weapon))
	return Plugin_Stop;
	
	SetEntDataFloat(weapon, g_iPlaybackRate, 1.0, true);
	KillTimer(timer);

	return Plugin_Stop;
}

public Action:CommandoRelFireEnd2(Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	ResetPack(hPack);

	new client = ReadPackCell(hPack);
	new Float:flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);

	if (client <= 0
		|| IsValidEntity(client)==false
		|| IsClientInGame(client)==false)
		return Plugin_Stop;

	new iVMid = GetEntDataEnt2(client,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);
	return Plugin_Stop;
}

public Action:CommandoPumpShotReload(Handle:timer, Handle:hOldPack)
{
	ResetPack(hOldPack);
	new weapon = ReadPackCell(hOldPack);
	new client = ReadPackCell(hOldPack);	
	new Float:fReloadRatio = g_flReloadRate;
	new Float:start = ReadPackFloat(hOldPack);
	new Float:insert = ReadPackFloat(hOldPack);
	new Float:end = ReadPackFloat(hOldPack);
	CloseHandle(hOldPack);
		PrintDebugAll("Starting reload");

	if (client <= 0
		|| weapon <= 0
		|| IsValidEntity(weapon)==false
		|| IsValidEntity(client)==false
		|| IsClientInGame(client)==false)
		return Plugin_Stop;

	SetEntDataFloat(weapon,	g_reloadStartDuration,	start * fReloadRatio,	true);
	SetEntDataFloat(weapon,	g_reloadInsertDuration,	insert * fReloadRatio,	true);
	SetEntDataFloat(weapon,	g_reloadEndDuration, end * fReloadRatio,	true);
	SetEntDataFloat(weapon, g_iPlaybackRate, 1.0 / fReloadRatio, true);
		PrintDebugAll("\x03-spas shotgun detected, ratio \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i", fReloadRatio, g_reloadStartDuration, g_reloadInsertDuration, g_reloadEndDuration);

	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, weapon);
	WritePackCell(hPack, client);

	if (GetEntData(weapon, g_iReloadState) != 2)
	{
		WritePackFloat(hPack, 0.2);
		CreateTimer(0.3, CommandoShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		WritePackFloat(hPack, 1.0);
		CreateTimer(0.3, CommandoShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action:CommandoShotCalculate(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);
	new weapon = ReadPackCell(hPack);
	new client  = ReadPackCell(hPack);

	new Float:addMod = ReadPackFloat(hPack);
	
	if (IsServerProcessing()==false
		|| client <= 0
		|| weapon <= 0
		|| IsValidEntity(client)==false
		|| IsValidEntity(weapon)==false
		|| IsClientInGame(client)==false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}
	PrintDebugAll("Shotgun finished reloading");

	if (GetEntData(weapon, g_iReloadState) == 0 || GetEntData(weapon, g_iReloadState) == 2 )
	{

		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_iPlaybackRate, 1.0, true);
		SetEntDataFloat(client, g_iNextAttack, flNextTime, true);
		SetEntDataFloat(weapon,	g_iTimeWeaponIdle, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNextPrimaryAttack, flNextTime, true);
		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(ClientData[client].ChosenClass == NONE && GetClientTeam(client) == 2 && client > 0 && client <= MaxClients && IsClientInGame( client ) && ClassHint == false)
	{
		if (RoundStarted == true) {
			ClassHint = true;
		}
		
		// Only show hints after intro finishes on first mission, or immediately on other maps
		if (!g_bFirstMission || g_bIntroFinished)
		{
			PrintHintText(client,"You really should pick a class. Soldier, Medic, or Engineer are good for beginners.");
			CreatePlayerClassMenu(client);
		}
	}


	if(ClientData[client].ChosenClass == commando)
	{
		GetEventString(event, "weapon", ClientData[client].EquippedGun, 64);
		//PrintToChat(client,"weapon shot fired");	
	}
	return Plugin_Continue;
}

public getCommandoDamageBonus(client)
{
	if (StrContains(ClientData[client].EquippedGun,"grenade", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_GRENADE);
	}
	if (StrContains(ClientData[client].EquippedGun,"shotgun", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_SHOTGUN);
	}
	if (StrContains(ClientData[client].EquippedGun, "sniper", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_SNIPER);
	}
	if (StrContains(ClientData[client].EquippedGun, "hunting", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_HUNTING);
	}
	if (StrContains(ClientData[client].EquippedGun, "pistol", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_PISTOL);
	}
	if (StrContains(ClientData[client].EquippedGun, "smg", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_SMG);
	}
	if (StrContains(ClientData[client].EquippedGun,"rifle", false)!=-1)
	{
		return GetConVarInt(COMMANDO_DAMAGE_RIFLE);
	}
	// default
	return GetConVarInt(COMMANDO_DAMAGE);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_StartTouch, _MF_Touch);
	SDKHook(client, SDKHook_Touch, 		_MF_Touch);
}

stock Action _MF_Touch(int entity, int other)
{
	if (!GetConVarBool(COMMANDO_ENABLE_STOMPING)) return Plugin_Continue;
 	if (ClientData[entity].ChosenClass != commando || other < 32 || !IsValidEntity(other)) return Plugin_Continue;
	
	static char classname[12];
	GetEntityClassname(other, classname, sizeof(classname));	
	if (strcmp(classname, "infected") == 0)
	{
		int i = GetEntProp(other, Prop_Data, ENTPROP_ANIM_SEQUENCE);
		float f = GetEntPropFloat(other, Prop_Data, ENTPROP_ANIM_CYCLE);
		//PrintDebugAll("Touch fired on Infected, Sequence %i, Cycle %f", i, f);
		
		if ((i >= ANIM_SEQUENCES_DOWNED_BEGIN && i <= ANIM_SEQUENCES_DOWNED_END) || i == ANIM_SEQUENCE_WALLED)
		{
			if (f >= DOWNED_ANIM_MIN_CYCLE && f <= DOWNED_ANIM_MAX_CYCLE)
			{
				PrintDebugAll("Infected found downed. STOMPING HIM!!!");
				SmashInfected(other, entity);
				
				if (GetConVarBool(COMMANDO_STOMPING_SLOWDOWN))
				{
					SetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP, GetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP) - STOMP_MOVE_PENALTY);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock void SmashInfected(int zombie, int client)
{
	EmitSoundToAll(STOMP_SOUND_PATH, zombie, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	AcceptEntityInput(zombie, "BecomeRagdoll");
	SetEntProp(zombie, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(zombie, Prop_Data, "m_iHealth", 1);
	SDKHooks_TakeDamage(zombie, client, client, 10000.0, DMG_GENERIC);
}

///////////////////////////////////////////////////////////////////////////////////
// Saboteur
///////////////////////////////////////////////////////////////////////////////////

public parseAvailableBombs()
{
	char buffers[MAX_BOMBS][3];

	char bombs[128];
	GetConVarString(SABOTEUR_BOMB_TYPES, bombs, sizeof(bombs));

	int amount = ExplodeString(bombs, ",", buffers, sizeof(buffers), 3);
	PrintDebugAll("Found %i amount of mines from bombs: %s ",amount, bombs);

	if (amount == 1) {

		g_AvailableBombs[0].setItem(0, StringToInt(buffers[0]));
		PrintDebugAll("Added single bombtype to inventory: %s", g_AvailableBombs[0].getItem());
		return;
	}

	for( int i = 0; i < MAX_BOMBS; i++ )
	{	
		int item = StringToInt(buffers[i]);
		if (item < 1) {
			continue;
		}

		g_AvailableBombs[i].setItem(i, item);
		PrintDebugAll("Added %i bombtype to inventory: %s", item, g_AvailableBombs[i].getItem());
	}
}

public void CalculateSaboteurPlacePos(client, int value)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);
	
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);
	if (TR_DidHit(trace)) {
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(ENGINEER_MAX_BUILD_RANGE)) {
			vAng[0] = 0.1;
			vAng[2] = 0.1;
			DropBomb(client, value);
			PrintDebugAll("%N dropped a mine with index of %i to %f %f %f" , client, value, vPos[0], vPos[1], vPos[2]);			
			ClientData[client].SpecialsUsed++;
			ClientData[client].LastDropTime = GetGameTime();				
		} else {
			PrintToChat(client, "%s Could not place the item because you were looking too far away.", PRINT_PREFIX);
		}
		
	} else
		CloseHandle(trace);
}

public void OnClientWeaponEquip(int client, int weapon)
{
	if (ClientData[client].ChosenClass == saboteur && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2) {
		
		ToggleNightVision(client);
	}
}

public void ToggleNightVision(client)
{
	if (GetConVarBool(SABOTEUR_ENABLE_NIGHT_VISION) && ClientData[client].ChosenClass == saboteur && client < MaxClients && client > 0 && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
			int iWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
			if(iWeapon > 0 && IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
			{					
				char netclass[128];
				GetEntityNetClass(iWeapon, netclass, sizeof(netclass));
				PrintDebug(client, "Toggling nightvision!");
				SetEntProp(client, Prop_Send, "m_bNightVisionOn", !GetEntProp(client, Prop_Send, "m_bNightVisionOn"));
				SetEntProp(client, Prop_Send, "m_bHasNightVision", !GetEntProp(client, Prop_Send, "m_bHasNightVision"));
				if (!GetEntProp(client, Prop_Send, "m_bHasNightVision"))
				return;
				if(FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
				return; // This weapon does not support laser upgrade

				new cl_upgrades = GetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec");
				if (cl_upgrades > 4194304) {
					return; // already has nightvision
				} else {
					SetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec", cl_upgrades + 4194304, 4);
				}
		}
	}
}

public Action L4D2_OnChooseVictim(int attacker, int &curTarget) {
	// =========================
	// OVERRIDE VICTIM
	// =========================
	L4D2Infected class = view_as<L4D2Infected>(GetEntProp(attacker, Prop_Send, "m_zombieClass"));
	if(class != L4D2Infected_Tank) {
		int existingTarget = GetClientOfUserId(b_attackerTarget[attacker]);
		if(existingTarget > 0) {
			return Plugin_Changed;
		}

		float closestDistance, survPos[3], spPos[3];
		GetClientAbsOrigin(attacker, spPos); 
		int closestClient = -1;
		for(int i = 1; i <= MaxClients; i++) {
			if(g_bIsVictim[i] && IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) {
				GetClientAbsOrigin(i, survPos);
				float dist = GetVectorDistance(survPos, spPos, true);
				if(closestClient == -1 || dist < closestDistance) {
					closestDistance = dist;
					closestClient = i;
				}
			}
		}
		
		if(closestClient > 0) {
			PrintToConsoleAll("Attacker %N new target: %N", attacker, closestClient);
			b_attackerTarget[attacker] = GetClientUserId(closestClient);
			curTarget = closestClient;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/*
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	b_attackerTarget[client] = 0;
}

public void OnClientDisconnect(int client) {
	b_attackerTarget[client] = 0;
}
*/

stock DisableAllUpgrades(client)
{
	if (client > 0 && client <= 16 && IsValidEntity(client) && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2) {

		SetEntDataFloat(client, g_flLaggedMovementValue, 1.0, true);

		int iWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
		if(iWeapon > 0 && IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
		{	
			char netclass[128];
			GetEntityNetClass(iWeapon, netclass, sizeof(netclass));
			if(FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
			return; // This weapon does not support laser upgrade
			SetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec", 0, 4);
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		}
	}

}

stock UnhookPlayer(client)
{
	if (client > 0 && client <= 16 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2) {
		
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);	
		SDKUnhook(client, SDKHook_StartTouch, _MF_Touch);
		SDKUnhook(client, SDKHook_Touch, _MF_Touch);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);

	}
}

stock HookPlayer(client) 
{
	if (client > 0 && client <= 16 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2) {

		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	}
}
///////////////////////////////////////////////////////////////////////////////////
// Soldier
///////////////////////////////////////////////////////////////////////////////////

void Convar_Reload_Rate (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>0.9)
		flF=0.9;
	g_flReloadRate = flF;
}
void Convar_Attack_Rate (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>0.9)
		flF=0.9;
	g_flAttackRate = flF;
}
void Convar_Melee_Rate (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>0.9)
		flF=0.9;
	g_flMeleeRate = flF;
}

public OnGameFrame()
{
	if (!IsServerProcessing())  { return; } // RoundStarted
	else
	{
		MA_OnGameFrame();
		DT_OnGameFrame();
	}
}

void DT_OnGameFrame()
{
	if (g_iSoldierCount <= 0) {return;}

	decl client;
	decl iActiveWeapon;

	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	decl Float:flNextPrimaryAttack;
	//and this tracks next melee attack times
	decl Float:flNextSecondaryAttack;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	for (new i = 1; i <= g_iSoldierCount; i++)
	{
		client = g_iSoldierIndex[i];

		if (client <= 0) return;
		if(ClientData[client].ChosenClass != soldier) continue;

		iActiveWeapon = GetEntDataEnt2(client, g_iActiveWeapon);

		if(iActiveWeapon <= 0) 
		continue;

		//and here is the retrieved next attack time
		flNextPrimaryAttack = GetEntDataFloat(iActiveWeapon, g_iNextPrimaryAttack);
		//and for retrieved next melee time
		flNextSecondaryAttack = GetEntDataFloat(iActiveWeapon,g_iNextSecondaryAttack);

		if (g_iEntityIndex[client] == iActiveWeapon && g_fNextAttackTime[client] >= flNextPrimaryAttack)
			continue;
		
		if (flNextSecondaryAttack > flGameTime)
		{
			//----RSDEBUG----
			PrintDebugAll("\x03DT client \x01%i\x03; melee attack inferred",client );
			continue;
		}

		if (g_iEntityIndex[client] == iActiveWeapon && g_fNextAttackTime[client] < flNextPrimaryAttack)
		{
			PrintDebugAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",client,iActiveWeapon,flGameTime,flNextPrimaryAttack, flNextPrimaryAttack-flGameTime );

			flNextTime_calc = ( flNextPrimaryAttack - flGameTime ) * g_flAttackRate + flGameTime;
			g_fNextAttackTime[client] = flNextTime_calc;
			SetEntDataFloat(iActiveWeapon, g_iNextPrimaryAttack, flNextTime_calc, true);
			PrintDebugAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iActiveWeapon,g_iNextPrimaryAttack), GetEntDataFloat(iActiveWeapon,g_iNextPrimaryAttack)-flGameTime );
			continue;
		}
		
		if (g_iEntityIndex[client] != iActiveWeapon)
		{
			g_iEntityIndex[client] = iActiveWeapon;
			g_fNextAttackTime[client] = flNextPrimaryAttack;
			continue;
		}
	}
}

/* ***************************************************************************/
//Since this is called EVERY game frame, we need to be careful not to run too many functions
//kinda hard, though, considering how many things we have to check for =.=

int MA_OnGameFrame()
{
	if (g_iSoldierCount <= 0) {return 0;}

	int iCid;
	//this tracks the player's ability id
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextPrimaryAttack;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	//theoretically, to get on the MA registry, all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new i = 1; i <= g_iSoldierCount; i++)
	{
		iCid = g_iSoldierIndex[i];
		if(ClientData[iCid].ChosenClass != soldier) {continue;}

		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------

		//stop on this client when the next client id is null
		if (iCid <= 0) continue;
		if(!IsClientInGame(iCid)) continue;
		if(!IsClientConnected(iCid)) continue; 
		if (!IsPlayerAlive(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		if(ClientData[iCid].ChosenClass != soldier) { continue;}

		iEntid = GetEntDataEnt2(iCid, g_iActiveWeaponOffset);

		if (GetConVarBool(SOLDIER_SHOVE_PENALTY) == false )
		{
			//If the player is pressing the right click of the mouse, proceed
			if(GetClientButtons(iCid) & IN_ATTACK2)
			{
				//This will reset the penalty, so it doesnt even get applied.
				SetEntData(iCid, g_iShovePenalty, 0, 4);
			}
		}
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextPrimaryAttack = GetEntDataFloat(iEntid, g_iNextPrimaryAttack);

		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iNotMeleeEntityIndex[iCid])
		{
			continue;
		}

		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//---------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes, and then paused long enough, 
		//we should reset his strike count so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 1.5s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (g_iMeleeEntityIndex[iCid] == iEntid && g_iMeleeAttackCount[iCid] != 0 && (flGameTime - flNextPrimaryAttack) > 1.0)
		{
			g_iMeleeAttackCount[iCid] = 0;
		}

		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (g_iMeleeEntityIndex[iCid] == iEntid && g_flNextMeleeAttackTime[iCid] >= flNextPrimaryAttack)
		{
			continue;
		}

		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		//        and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_iMeleeEntityIndex[iCid] == iEntid && g_flNextMeleeAttackTime[iCid] < flNextPrimaryAttack)
		{
			//this is a calculation of when the next primary attack will be after applying double tap values
			//flNextTime_calc = ( flNextPrimaryAttack - flGameTime ) * g_flMeleeRate + flGameTime;
			flNextTime_calc = flGameTime + g_flMeleeRate;
			// flNextTime_calc = flGameTime + melee_speed[iCid] ;

			//then we store the value
			g_flNextMeleeAttackTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPrimaryAttack, flNextTime_calc, true);
			PrintDebugAll("\x03-melee attack, original: \x01 %f\x03; new \x01%f",flNextPrimaryAttack, GetEntDataFloat(iEntid,g_iNextPrimaryAttack) - flGameTime);
			continue;
		}

		//CHECK 4: CHECK THE WEAdPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact, using a melee weapon =P
		//we check if the current weapon is the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is, store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		//         the known-melee or known-non-melee variable

		//check if the weapon is a melee
		char stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			//if yes, then store in known-melee var
			g_iMeleeEntityIndex[iCid]=iEntid;
			g_flNextMeleeAttackTime[iCid]=flNextPrimaryAttack;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iNotMeleeEntityIndex[iCid]=iEntid;
			continue;
		}
	}
	return 0;
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsServerProcessing())
	return Plugin_Continue;
	
	if (victim && attacker && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
	{
		if( damagetype & DMG_BLAST && GetEntProp(inflictor, Prop_Data,  "m_iHammerID") == 1078682)
		{
			if(GetClientTeam(victim) == 2 )
				damage = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_SURV);
			else if(GetClientTeam(victim) == 3 ) {

				damage = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_INF);
			}
			PrintDebugAll("%N caused damage to %N for %i points", attacker, victim, damage);
			return Plugin_Changed;
		}

		//PrintToChatAll("%s", m_attacker);
		if(ClientData[victim].ChosenClass == soldier && GetClientTeam(victim) == 2)
		{
			//PrintToChat(victim, "Damage: %f, New: %f", damage, damage*0.5);
			damage = damage * GetConVarFloat(SOLDIER_DAMAGE_REDUCE_RATIO);
			return Plugin_Changed;
		}
		if (ClientData[attacker].ChosenClass == commando && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			damage = damage + getCommandoDamageBonus(attacker);
			//PrintToChat(attacker,"%f",damage);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////
// Mines & Airstrikes
///////////////////////////////////////////////////////////////////////////////////

public void DropBomb(client, bombType)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	int index = ClientData[client].SpecialsUsed;		
	char bombName[32];

	bombName = getBombName(bombType);
	PrintDebugAll("Planting #%i %s (index %d)", index, bombName, bombType);

	new Handle:hPack = CreateDataPack();

	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, GetClientUserId(client));
	WritePackCell(hPack, RndSession);
	WritePackCell(hPack, index);
	WritePackCell(hPack, bombType);	


	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	BombActive = true;
	BombIndex[index] = true;


	int entity = CreateBombParticleInPos(pos, BOMB_GLOW, index);
	WritePackCell(hPack, entity);	
	CreateTimer(GetConVarFloat(SABOTEUR_BOMB_ACTIVATE), TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	EmitSoundToAll(SOUND_DROP_BOMB);
	PrintHintTextToAll("%N planted a %s mine! (%i/%i)", client, bombName, (1+ ClientData[client].SpecialsUsed), GetConVarInt(SABOTEUR_MAX_BOMBS));
}

#define DROP_MINE_ENTITY_DEFINED
public DropMineEntity(Float:pos[3], int index)
{
	char mineName[32];
	Format(mineName, sizeof(mineName), "mineExplosive%d", index);
	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "model", MODEL_MINE);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);	
	SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor("255 0 0"));
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 520);
	SetEntProp(entity, Prop_Data, "m_iHammerID", 1078682);
	SetEntProp(entity, Prop_Data, "m_usSolidFlags", 152);
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
	SetEntityMoveType(entity, MOVETYPE_NONE);
	SetEntProp(entity, Prop_Data, "m_MoveCollide", 0);
	SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
	DispatchKeyValue(entity, "targetname", mineName);

	return entity;
}


public void CreateAirStrike(int client) {
	
	float vPos[3];

	if (SetClientLocation(client, vPos)) {
		char color[12];

		int entity = CreateEntityByName("info_particle_system");
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(entity, "effect_name", BOMB_GLOW);
		DispatchSpawn(entity);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		CreateBeamRing(entity, { 255, 0, 255, 255 },0.1, 180.0, 3);		
		PrintHintTextToAll("%N ordered airstrike, take cover!", client);
		GetConVarString(SABOTEUR_ACTIVE_BOMB_COLOR, color, sizeof(color));
		SetupPrjEffects(entity, vPos, color); // Red

		EmitSoundToAll(SOUND_DROP_BOMB);

		new Handle:pack = CreateDataPack();
		WritePackCell(pack, GetClientUserId(client));
		WritePackFloat(pack, vPos[0]);
		WritePackFloat(pack, vPos[1]);
		WritePackFloat(pack, vPos[2]);
		WritePackFloat(pack, GetGameTime());
		WritePackCell(pack, entity);									
		CreateTimer(1.0, TimerAirstrike, pack, TIMER_FLAG_NO_MAPCHANGE ); 	
 		CreateTimer(10.0, DeleteParticles, entity, TIMER_FLAG_NO_MAPCHANGE ); 													
	} 
}
/**
* STOCK FUNCTIONS
*/

stock bool:IsWitch(client)
{
	if(client > 0 && IsValidEntity(client) && IsValidEdict(client))
	{
		decl String:strClassName[64];
		GetEdictClassname(client, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost",1);
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock bool:IsHanging(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

stock FindAttacker(iClient)
{
	//Pummel
	new iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker");
	if (iAttacker > 0)
	return iAttacker;
	
	//Pounce
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker");
	if (iAttacker > 0)
	return iAttacker;
	
	//Jockey
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker");
	if (iAttacker > 0)
	return iAttacker;
	
	//Smoker
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_tongueOwner");
	if (iAttacker > 0)
	return iAttacker;
	
	iAttacker = 0;
	return iAttacker;
}

// IsValidSurvivor is now provided by rage/validation.inc
// This version has an optional isAlive parameter for backward compatibility
stock bool:IsValidSurvivorCompat(client, bool:isAlive = false) {
	if(client >= 1 && client <= MaxClients && GetClientTeam(client) == 2 && IsClientConnected(client) && IsClientInGame(client) && (isAlive == false || IsPlayerAlive(client)))
	{	 
		return true;
	} 
	return false;
}

stock int CountPlayersWithClass( class ) {
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		continue;

		if(ClientData[i].ChosenClass == view_as<ClassTypes>(class))
		count++;
	}

	return count;
}

stock bool:IsInEndingSaferoom(client)
{
	decl String:class[128], Float:pos[3], Float:dpos[3];
	GetClientAbsOrigin(client, pos);
	for (new i = MaxClients+1; i < 2048; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_door_rotating_checkpoint"))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", class, sizeof(class));
				if (StrContains(class, "checkpoint_door_02") != -1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", dpos);
					if (GetVectorDistance(pos, dpos) <= 600.0)
					return true;
				}
			}
		}
	}
	return false;
}

stock bool:IsPlayerInSaferoom(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	return g_bInSaferoom[client] || GetVectorDistance(g_SpawnPos[client], pos) <= 600.0;
}

stock Water_Level:GetClientWaterLevel(client)
{	
	return Water_Level:GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

stock bool:IsClientOnLadder(client)
{	
	new MoveType:movetype = GetEntityMoveType(client);
	
	if (movetype == MOVETYPE_LADDER)
	return true;
	
	return false;
}

public int getDebugMode() {
	return DEBUG_MODE;
}

public setDebugMode(int mode) {
	DEBUG_MODE=mode;
}

///////////////////////////////////////////////////////////////////////////////////
// Player command handling
///////////////////////////////////////////////////////////////////////////////////

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
        if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
        {
                // Reset shift state if client is not valid
                if (g_bWasHoldingShift[client])
                {
                        FakeClientCommand(client, "-rage_menu");
                        g_bWasHoldingShift[client] = false;
                }
                return Plugin_Continue;
        }

        new flags = GetEntityFlags(client);

        // Removed redundant IN_ATTACK3 skill action detection - console commands handle this now

        if (!(buttons & IN_DUCK) || !(flags & FL_ONGROUND)) {
                ClientData[client].HideStartTime= GetGameTime();
                ClientData[client].HealStartTime= GetGameTime();
        }

        // SHIFT (IN_SPEED) shows RAGE menu - check this before early returns
        bool holdingShift = (buttons & IN_SPEED) != 0;
        if (holdingShift && !g_bWasHoldingShift[client])
        {
                // SHIFT just pressed - show RAGE menu
                FakeClientCommand(client, "+rage_menu");
                g_bWasHoldingShift[client] = true;
        }
        else if (!holdingShift && g_bWasHoldingShift[client])
        {
                // SHIFT released - close RAGE menu
                FakeClientCommand(client, "-rage_menu");
                g_bWasHoldingShift[client] = false;
        }

        if (IsFakeClient(client) || IsHanging(client) || IsIncapacitated(client) || FindAttacker(client) > 0 || IsClientOnLadder(client) || GetClientWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
        return Plugin_Continue;

        // Ensure IN_USE (T key) is not blocked for voice chat
        // Don't interfere with IN_USE - let it work normally for voice chat

        if (ClientData[client].ChosenClass == athlete)
        {
                if (buttons & IN_JUMP && flags & FL_ONGROUND )
                {
                        PushEntity(client, Float:{-90.0,0.0,0.0}, GetConVarFloat(ATHLETE_JUMP_VEL));
                        flags &= ~FL_ONGROUND;
                        SetEntityFlags(client,flags);

                }
        }

        // Skill actions are now handled via console commands - no need for duplicate detection here
        ClientData[client].LastButtons = buttons;

        return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////
// Invisibility
///////////////////////////////////////////////////////////////////////////////////

public bool:IsPlayerHidden(client) 
{
	if (ClientData[client].ChosenClass == saboteur && (GetGameTime() - ClientData[client].HideStartTime) >= (GetConVarFloat(SABOTEUR_INVISIBLE_TIME))) 
	{
		return true;
	}
	return false;
}

public Action:Hook_SetTransmit(entity, client) 
{ 
	if (DEBUG_MODE) {
		//	PrintToChatAll("client %i entity %i, client is %s", client, entity, g_bHide[client] ? "hidden" : "not hidden");
	}
	return !(entity < MAXPLAYERS && g_bHide[entity] == true && client != entity) ? Plugin_Continue : Plugin_Handled; 
}

public bool IsPlayerVisible(client) {
	return g_bHide[client] ? true:false;
}

public Action:HidePlayer(client)
{
	g_bHide[client] = !g_bHide[client];
	PrintHintText(client, "You are %s", g_bHide[client] ? "invisible" : "visible again");
	return Plugin_Handled;
}

public Action:UnhidePlayer(client)
{
	if (g_bHide[client] == true) HidePlayer(client);
	g_bHide[client] = false;
}
