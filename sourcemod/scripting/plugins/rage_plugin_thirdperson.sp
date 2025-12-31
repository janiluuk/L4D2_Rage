/**
 * Survivor Thirdperson (integrated for Rage menu support)
 * Original author: SilverShot
 */

#define PLUGIN_VERSION "1.9"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS          FCVAR_NOTIFY
#define CHAT_TAG            "\x04[\x05Thirdperson\x04] \x01"

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bMapStarted, g_bThirdView[MAXPLAYERS+1], g_bMountedGun[MAXPLAYERS+1];
Handle g_hTimerReset[MAXPLAYERS+1], g_hTimerGun;

public Plugin myinfo =
{
    name = "[RAGE] Third Person",
    author = "SilverShot",
    description = "Creates a command for survivors to use thirdperson view.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=185664"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();
    if (test != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }
    RegPluginLibrary("rage_plugin_thirdperson");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    g_hCvarAllow = CreateConVar("l4d2_third_allow", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
    g_hCvarModes = CreateConVar("l4d2_third_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
    g_hCvarModesOff = CreateConVar("l4d2_third_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
    g_hCvarModesTog = CreateConVar("l4d2_third_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
    CreateConVar("l4d2_third_version", PLUGIN_VERSION, "Survivor Thirdperson plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    AutoExecConfig(true, "l4d2_third");

    RegConsoleCmd("sm_3rdoff", CmdTP_Off, "Turns thirdperson view off.");
    RegConsoleCmd("sm_3rdon", CmdTP_On, "Turns thirdperson view on.");
    RegConsoleCmd("sm_3rd", CmdThird, "Toggles thirdperson view.");
    RegConsoleCmd("sm_tp", CmdThird, "Toggles thirdperson view.");
    RegConsoleCmd("sm_third", CmdThird, "Toggles thirdperson view.");

    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
    g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
}

public void OnPluginEnd()
{
    ResetPlugin();
}

public void OnMapStart()
{
    g_bMapStarted = true;
}

public void OnMapEnd()
{
    g_bMapStarted = false;
    ResetPlugin();
}

void ResetPlugin()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            g_bMountedGun[i] = false;
            g_bThirdView[i] = false;
            SetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView", 0.0);
        }
    }
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
    if (g_hCvarMPGameMode == null)
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if (iCvarModesTog != 0)
    {
        if (g_bMapStarted == false)
            return false;

        g_iCurrentMode = 0;

        int entity = CreateEntityByName("info_gamemode");
        if (IsValidEntity(entity))
        {
            DispatchSpawn(entity);
            HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
            ActivateEntity(entity);
            AcceptEntityInput(entity, "PostSpawnActivate");
            if (IsValidEntity(entity))
                RemoveEdict(entity);
        }

        if (g_iCurrentMode == 0)
            return false;

        if (!(iCvarModesTog & g_iCurrentMode))
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
    if (strcmp(output, "OnCoop") == 0)
        g_iCurrentMode = 1;
    else if (strcmp(output, "OnSurvival") == 0)
        g_iCurrentMode = 2;
    else if (strcmp(output, "OnVersus") == 0)
        g_iCurrentMode = 4;
    else if (strcmp(output, "OnScavenge") == 0)
        g_iCurrentMode = 8;
}

void IsAllowed()
{
    bool bCvarAllow = g_hCvarAllow.BoolValue;
    bool bAllowMode = IsAllowedGameMode();

    if (!g_bCvarAllow && bCvarAllow && bAllowMode)
    {
        g_bCvarAllow = true;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
        HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("mounted_gun_start", Event_MountedGun);
        HookEvent("charger_impact", Event_ChargerImpact);
    }
    else if (g_bCvarAllow && (!bCvarAllow || !bAllowMode))
    {
        ResetPlugin();
        g_bCvarAllow = false;

        delete g_hTimerGun;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
        UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("mounted_gun_start", Event_MountedGun);
        UnhookEvent("charger_impact", Event_ChargerImpact);
    }
}

public void OnClientPutInServer(int client)
{
    g_bThirdView[client] = false;
    g_bMountedGun[client] = false;
}

public void OnClientDisconnect(int client)
{
    delete g_hTimerReset[client];
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client)
    {
        g_bThirdView[client] = false;
        g_bMountedGun[client] = false;

        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    delete g_hTimerGun;

    for (int i = 1; i <= MaxClients; i++)
    {
        g_bThirdView[i] = false;
        g_bMountedGun[i] = false;
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    delete g_hTimerGun;
}

public void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("victim");
    int client = GetClientOfUserId(userid);
    if (client && g_bThirdView[client])
    {
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
    }
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (g_bThirdView[victim] && damagetype == DMG_CLUB && victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3)
    {
        delete g_hTimerReset[victim];
        g_hTimerReset[victim] = CreateTimer(1.0, TimerReset, GetClientUserId(victim), TIMER_REPEAT);
        SetEntPropFloat(victim, Prop_Send, "m_TimeForceExternalView", 99999.3);
    }

    return Plugin_Continue;
}

Action TimerReset(Handle timer, any client)
{
    client = GetClientOfUserId(client);
    if (client && g_bThirdView[client])
    {
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
    }

    g_hTimerReset[client] = null;
    return Plugin_Stop;
}

public void Event_MountedGun(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (g_bThirdView[client])
    {
        g_bMountedGun[client] = true;
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);

        if (g_hTimerGun == null)
        {
            g_hTimerGun = CreateTimer(0.5, TimerCheck, _, TIMER_REPEAT);
        }
    }
}

Action TimerCheck(Handle timer)
{
    int count;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bMountedGun[i] && IsClientInGame(i) && IsPlayerAlive(i))
        {
            if (GetEntProp(i, Prop_Send, "m_usingMountedWeapon"))
            {
                count++;
            }
            else
            {
                SetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView", 99999.3);
                g_bMountedGun[i] = false;
            }
        }
    }

    if (count)
        return Plugin_Continue;

    g_hTimerGun = null;
    return Plugin_Stop;
}

Action CmdTP_Off(int client, int args)
{
    if (g_bCvarAllow && client && IsPlayerAlive(client))
    {
        g_bThirdView[client] = false;
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
        PrintToChat(client, "%s%t", CHAT_TAG, "Off");
    }

    return Plugin_Handled;
}

Action CmdTP_On(int client, int args)
{
    if (g_bCvarAllow && client && IsPlayerAlive(client))
    {
        g_bThirdView[client] = true;
        SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
        PrintToChat(client, "%s%t", CHAT_TAG, "On");
    }

    return Plugin_Handled;
}

Action CmdThird(int client, int args)
{
    if (g_bCvarAllow && client && IsPlayerAlive(client))
    {
        if (!g_bThirdView[client])
        {
            g_bThirdView[client] = true;
            SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
            PrintToChat(client, "%s%t", CHAT_TAG, "On");
        }
        else
        {
            g_bThirdView[client] = false;
            SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
            PrintToChat(client, "%s%t", CHAT_TAG, "Off");
        }
    }

    return Plugin_Handled;
}
