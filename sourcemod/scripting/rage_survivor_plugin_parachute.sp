#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <rage/common>
#include <rage/skills>
#include <rage/movement>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "Parachute"

bool g_bLeft4Dead2;
bool g_bRageAvailable;
int g_iClassID = -1;
ParachuteAbility g_Parachute;
ConVar g_hParachuteEnabled;
const int CLASS_ATHLETE = 2;
bool g_bHasAbility[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[Rage] Athlete Parachute",
    author = "L4D2 Rage",
    description = "Gives athletes a hold-USE parachute glide",
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

    RegPluginLibrary("rage_survivor_parachute");
    RageSkills_MarkNativesOptional();
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_Parachute.Initialize();

    g_hParachuteEnabled = FindConVar("talents_athlete_enable_parachute");
    if (g_hParachuteEnabled == null)
    {
        g_hParachuteEnabled = CreateConVar("talents_athlete_enable_parachute", "1.0", "Enable parachute for athlete. Hold USE in air to use it. 0 = OFF, 1 = ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    }

    AutoExecConfig(true, "rage_parachute");
}

public void OnAllPluginsLoaded()
{
    RageSkills_Refresh(PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
    RefreshAthleteStates();
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
        RefreshAthleteStates();
    }
    else
    {
        g_bRageAvailable = false;
        g_iClassID = -1;
    }
}

public void OnClientDisconnect(int client)
{
    g_Parachute.ResetClient(client);
    g_bHasAbility[client] = false;
}

public void OnClientPutInServer(int client)
{
    g_bHasAbility[client] = false;
}

public void OnMapStart()
{
    PrecacheModel(PARACHUTE, true);
    PrecacheModel(FAN_BLADE, true);
    PrecacheSound(SOUND_HELICOPTER, true);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!g_bRageAvailable || g_hParachuteEnabled == null)
    {
        return Plugin_Continue;
    }

    if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
    {
        return Plugin_Continue;
    }

    if (!g_bHasAbility[client])
    {
        return Plugin_Continue;
    }

    g_Parachute.HandleRunCmd(client, buttons, GetEntityFlags(client), g_hParachuteEnabled, g_bLeft4Dead2);
    return Plugin_Continue;
}

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
    g_bHasAbility[client] = (newClass == CLASS_ATHLETE);
    if (!g_bHasAbility[client])
    {
        g_Parachute.ResetClient(client);
    }
    return g_bHasAbility[client] ? 1 : 0;
}

void RefreshAthleteStates()
{
    if (!g_bRageAvailable)
    {
        return;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            UpdateAthleteState(i);
        }
    }
}

void UpdateAthleteState(int client)
{
    g_bHasAbility[client] = false;
    if (!g_bRageAvailable)
    {
        return;
    }

    char className[32];
    if (GetPlayerClassName(client, className, sizeof(className)) > 0)
    {
        g_bHasAbility[client] = StrEqual(className, "Athlete", false);
    }
}
