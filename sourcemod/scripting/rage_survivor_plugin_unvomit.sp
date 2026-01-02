#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <rage/common>
#include <rage/skills>
#include <rage/skill_actions>
#include <rage/cooldown_notify>
#include <rage/validation>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "UnVomit"
#define VOMIT_DURATION 20.0  // Bile naturally expires after 20 seconds

// Rage system integration
bool g_bRageAvailable;
int g_iClassID = -1;

// Client tracking
float g_fLastCleanse[MAXPLAYERS + 1];
bool g_bVomitCovered[MAXPLAYERS + 1];

// Configuration
ConVar g_hCooldown;
float g_fCooldown;

public Plugin myinfo =
{
    name = "[Rage] Medic Unvomit",
    author = "L4D2 Rage",
    description = "Medic skill to clear boomer bile on demand",
    version = PLUGIN_VERSION,
    url = "https://github.com/yojimbo87"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead series");
        return APLRes_SilentFailure;
    }

    RegPluginLibrary("rage_survivor_unvomit");
    RageSkills_MarkNativesOptional();
    MarkNativeAsOptional("L4D_OnITExpired");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hCooldown = CreateConVar("rage_medic_unvomit_cooldown", "120.0", 
        "Cooldown before a medic can clear bile again (seconds).", 
        FCVAR_NOTIFY, true, 1.0, true, 300.0);
    g_fCooldown = g_hCooldown.FloatValue;
    g_hCooldown.AddChangeHook(OnCooldownChanged);

    AutoExecConfig(true, "rage_unvomit");
    LoadSkillActionBindings();
    HookEvent("player_now_it", Event_PlayerNowIt, EventHookMode_Post);
}

public void OnAllPluginsLoaded()
{
    RageSkills_Refresh(PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryAdded(const char[] name)
{
    RageSkills_OnLibraryAdded(name, PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, RAGE_PLUGIN_NAME, false))
    {
        g_iClassID = -1;
    }

    RageSkills_OnLibraryRemoved(name, g_bRageAvailable);
}

public void Rage_OnPluginState(char[] plugin, int state)
{
    if (!StrEqual(plugin, RAGE_PLUGIN_NAME, false))
    {
        return;
    }

    if (state == 1)
    {
        g_bRageAvailable = true;
        if (g_iClassID == -1)
        {
            g_iClassID = RegisterRageSkill(PLUGIN_SKILL_NAME, 0);
        }
    }
    else
    {
        g_bRageAvailable = false;
        g_iClassID = -1;
    }
}

public void OnClientPutInServer(int client)
{
    ResetClient(client);
}

public void OnClientDisconnect(int client)
{
    ResetClient(client);
}

public int OnSpecialSkillUsed(int client, int skill, int type)
{
    if (!g_bRageAvailable)
        return 0;

    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    if (!StrEqual(skillName, PLUGIN_SKILL_NAME))
        return 0;

    // Validate client and class requirements
    if (!IsValidSurvivor(client, true))
        return 0;

    if (!IsMedic(client))
    {
        PrintHintText(client, "Unvomit is available to medics only.");
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "not_medic");
        return 1;
    }

    // Check if covered in bile
    if (!g_bVomitCovered[client])
    {
        PrintHintText(client, "No bile to clear right now.");
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "not_vomited");
        return 1;
    }

    // Check cooldown
    float now = GetGameTime();
    float sinceUse = now - g_fLastCleanse[client];
    if (sinceUse < g_fCooldown)
    {
        float wait = g_fCooldown - sinceUse;
        PrintHintText(client, "Unvomit ready in %.1f seconds", wait);
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "cooldown");
        return 1;
    }

    // Execute skill
    ClearVomit(client, false);
    g_fLastCleanse[client] = now;
    CooldownNotify_Register(client, now + g_fCooldown, PLUGIN_SKILL_NAME);
    OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    return 1;
}

public Action Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidSurvivor(client, false))
        return Plugin_Continue;

    g_bVomitCovered[client] = true;
    
    // Auto-clear flag after bile expires naturally
    CreateTimer(VOMIT_DURATION, Timer_ClearVomitFlag, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    // Show hint to medics about cleanse ability
    if (g_bRageAvailable && IsMedic(client))
    {
        char binding[64];
        GetSkillActionBindingLabel(SkillAction_Tertiary, binding, sizeof(binding));
        PrintHintText(client, "Press %s to clear vomit", binding);
    }
    
    return Plugin_Continue;
}

public Action Timer_ClearVomitFlag(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0)
    {
        g_bVomitCovered[client] = false;
    }

    return Plugin_Stop;
}

/**
 * Clears vomit/bile effect from a survivor.
 * 
 * @param client      Client index
 * @param fromEvent   If true, message is suppressed (auto-clear)
 */
void ClearVomit(int client, bool fromEvent)
{
    if (!IsValidSurvivor(client, false))
        return;

    // Use Left4DHooks to expire the IT effect
    if (LibraryExists("left4dhooks"))
        L4D_OnITExpired(client);

    g_bVomitCovered[client] = false;

    if (!fromEvent)
        PrintHintText(client, "Bile cleared. Stay sharp, Medic!");
}

/**
 * Checks if a client is the Medic class.
 * 
 * @param client   Client index
 * @return         True if client is Medic, false otherwise
 */
bool IsMedic(int client)
{
    if (!g_bRageAvailable || !IsValidClient(client))
        return false;

    char className[32];
    GetPlayerClassName(client, className, sizeof(className));
    return StrEqual(className, "Medic", false);
}

void ResetClient(int client)
{
    g_fLastCleanse[client] = 0.0;
    g_bVomitCovered[client] = false;
}

public void OnCooldownChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fCooldown = g_hCooldown.FloatValue;
}
