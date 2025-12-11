#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <rage/common>
#include <rage/skills>
#include <rage/skill_actions>
#include <rage/cooldown_notify>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "UnVomit"

bool g_bRageAvailable;
int g_iClassID = -1;
float g_fLastCleanse[MAXPLAYERS + 1];
bool g_bVomitCovered[MAXPLAYERS + 1];

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
    g_hCooldown = CreateConVar("rage_medic_unvomit_cooldown", "120.0", "Cooldown before a medic can clear bile again (seconds).", FCVAR_NOTIFY, true, 1.0, true, 300.0);
    g_fCooldown = g_hCooldown.FloatValue;
    g_hCooldown.AddChangeHook(OnCooldownChanged);

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
    {
        return 0;
    }

    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    if (!StrEqual(skillName, PLUGIN_SKILL_NAME))
    {
        return 0;
    }

    if (!IsMedic(client))
    {
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "not_medic");
        PrintHintText(client, "Unvomit is available to medics only.");
        return 1;
    }

    if (!g_bVomitCovered[client])
    {
        PrintHintText(client, "No bile to clear right now.");
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "not_vomited");
        return 1;
    }

    float now = GetGameTime();
    float sinceUse = now - g_fLastCleanse[client];
    if (sinceUse < g_fCooldown)
    {
        int wait = RoundToCeil(g_fCooldown - sinceUse);
        PrintHintText(client, "Unvomit ready in %d seconds", wait);
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "cooldown");
        return 1;
    }

    ClearVomit(client, false);
    g_fLastCleanse[client] = now;
    // Register cooldown for notification
    CooldownNotify_Register(client, now + g_fCooldown, PLUGIN_SKILL_NAME);
    OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    return 1;
}

public Action Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
    {
        return Plugin_Continue;
    }

    g_bVomitCovered[client] = true;
    if (!g_bRageAvailable || !IsMedic(client))
    {
        return Plugin_Continue;
    }

    CreateTimer(20.0, Timer_ClearVomitFlag, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    char binding[64];
    GetSkillActionBindingLabel(SkillAction_Tertiary, binding, sizeof(binding));
    PrintHintText(client, "Press %s to clear vomit", binding);
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

void ClearVomit(int client, bool fromEvent)
{
    if (!IsClientInGame(client) || GetClientTeam(client) != 2)
    {
        return;
    }

    if (LibraryExists("left4dhooks"))
    {
        L4D_OnITExpired(client);
    }

    g_bVomitCovered[client] = false;

    if (!fromEvent)
    {
        PrintHintText(client, "Bile cleared. Stay sharp, Medic!");
    }
}

bool IsMedic(int client)
{
    if (!g_bRageAvailable)
    {
        return false;
    }

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
