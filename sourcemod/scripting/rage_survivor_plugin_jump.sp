#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <rage/common>
#include <rage/skills>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_SKILL_NAME "AthleteJump"

bool g_bRageAvailable;
bool g_bLeft4Dead2;
int g_iClassID = -1;

bool g_bJumpReleased[MAXPLAYERS + 1];
bool g_bUsedDouble[MAXPLAYERS + 1];
float g_fLastGround[MAXPLAYERS + 1];

ConVar g_hVerticalBoost;
ConVar g_hForwardBoost;
ConVar g_hResetWindow;

public Plugin myinfo =
{
    name = "[Rage] Athlete Jump Pack",
    author = "L4D2 Rage",
    description = "Adds double/long jump mobility for athletes",
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

    g_bLeft4Dead2 = (engine == Engine_Left4Dead2);

    RegPluginLibrary("rage_survivor_jump");
    RageSkills_MarkNativesOptional();
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hVerticalBoost = CreateConVar("rage_athlete_doublejump_height", "220.0", "Upward speed to apply when performing a double jump.", FCVAR_NOTIFY, true, 0.0, true, 400.0);
    g_hForwardBoost = CreateConVar("rage_athlete_doublejump_forward", "40.0", "Additional forward speed when double jumping.", FCVAR_NOTIFY, true, 0.0, true, 200.0);
    g_hResetWindow = CreateConVar("rage_athlete_jump_reset", "0.3", "Time after leaving ground before double jump becomes available (seconds).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    AutoExecConfig(true, "rage_athlete_jump");
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
    ResetJumpState(client);
}

public void OnClientDisconnect(int client)
{
    ResetJumpState(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!g_bRageAvailable)
    {
        return Plugin_Continue;
    }

    if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
    {
        return Plugin_Continue;
    }

    if (!IsAthlete(client))
    {
        return Plugin_Continue;
    }

    int flags = GetEntityFlags(client);
    float now = GetGameTime();
    bool onGround = (flags & FL_ONGROUND) != 0;

    if (onGround)
    {
        g_bUsedDouble[client] = false;
        g_bJumpReleased[client] = !(buttons & IN_JUMP);
        g_fLastGround[client] = now;
        return Plugin_Continue;
    }

    if (!(buttons & IN_JUMP))
    {
        g_bJumpReleased[client] = true;
        return Plugin_Continue;
    }

    if (g_bUsedDouble[client] || !g_bJumpReleased[client] || (now - g_fLastGround[client]) < g_hResetWindow.FloatValue)
    {
        return Plugin_Continue;
    }

    PerformDoubleJump(client);
    return Plugin_Continue;
}

void PerformDoubleJump(int client)
{
    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

    float vertical = g_hVerticalBoost.FloatValue;
    if (!g_bLeft4Dead2)
    {
        vertical *= 0.9; // keep L4D1 jumps closer to original feel
    }

    float forwardBoost = g_hForwardBoost.FloatValue;
    float eyeAngles[3];
    GetClientEyeAngles(client, eyeAngles);

    float forward[3];
    GetAngleVectors(eyeAngles, forward, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(forward, forwardBoost);

    velocity[0] += forward[0];
    velocity[1] += forward[1];
    velocity[2] = vertical;

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

    g_bUsedDouble[client] = true;
    g_bJumpReleased[client] = false;
}

bool IsAthlete(int client)
{
    char className[32];
    GetPlayerClassName(client, className, sizeof(className));
    return StrEqual(className, "Athlete", false);
}

void ResetJumpState(int client)
{
    g_bJumpReleased[client] = false;
    g_bUsedDouble[client] = false;
    g_fLastGround[client] = 0.0;
}
