#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <RageCore>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_NAME "Missile"
#define MISSILE_MODEL "models/weapons/w_missile_closed.mdl"

#define MISSILE_SPEED_DEFAULT 950.0
#define HOMING_TURN_STRENGTH_DEFAULT 0.65
#define HOMING_RANGE_DEFAULT 1200.0

public Plugin myinfo =
{
    name = "Missile skill plugin",
    author = "Yani, adapted from L4D2_Missile",
    description = "Adds soldier-controlled homing and dummy missiles.",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_hMissileSpeed = null;
ConVar g_hHomingStrength = null;
ConVar g_hHomingRange = null;

float g_fMissileSpeed = MISSILE_SPEED_DEFAULT;
float g_fHomingStrength = HOMING_TURN_STRENGTH_DEFAULT;
float g_fHomingRange = HOMING_RANGE_DEFAULT;

bool g_bHomingMissile[2049];
Handle g_hHomingTimer[2049];
int g_iMissileOwner[2049];

public void OnPluginStart()
{
    g_hMissileSpeed = CreateConVar("l4d2_missile_speed", "950.0", "Initial speed for fired missiles.");
    g_hHomingStrength = CreateConVar("l4d2_missile_homing_strength", "0.65", "Turn strength for homing missiles (0-1 range).");
    g_hHomingRange = CreateConVar("l4d2_missile_homing_range", "1200.0", "Maximum search distance for homing targets.");

    HookConVarChange(g_hMissileSpeed, OnMissileSettingsChanged);
    HookConVarChange(g_hHomingStrength, OnMissileSettingsChanged);
    HookConVarChange(g_hHomingRange, OnMissileSettingsChanged);

    UpdateSettings();
}

public void OnMapStart()
{
    PrecacheModel(MISSILE_MODEL, true);
}

public void OnMapEnd()
{
    for (int i = 0; i < sizeof(g_hHomingTimer); i++)
    {
        if (g_hHomingTimer[i] != null)
        {
            CloseHandle(g_hHomingTimer[i]);
            g_hHomingTimer[i] = null;
        }
        g_bHomingMissile[i] = false;
        g_iMissileOwner[i] = 0;
    }
}

public void OnEntityDestroyed(int entity)
{
    if (entity <= 0 || entity >= sizeof(g_hHomingTimer))
    {
        return;
    }

    if (g_hHomingTimer[entity] != null)
    {
        CloseHandle(g_hHomingTimer[entity]);
        g_hHomingTimer[entity] = null;
    }

    g_bHomingMissile[entity] = false;
    g_iMissileOwner[entity] = 0;
}

public int OnCustomCommand(char[] name, int client, int entity, int type)
{
    if (!StrEqual(name, PLUGIN_NAME, false))
    {
        return -1;
    }

    if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
    {
        return -1;
    }

    bool homing = (type == 1);
    int missile = LaunchMissile(client, homing);

    if (missile == -1)
    {
        return -1;
    }

    if (homing)
    {
        PrintHintText(client, "Homing missile launched!");
    }
    else
    {
        PrintHintText(client, "Dummy missile away!");
    }

    return 1;
}

public void OnMissileSettingsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    UpdateSettings();
}

void UpdateSettings()
{
    g_fMissileSpeed = GetConVarFloat(g_hMissileSpeed);
    g_fHomingStrength = GetConVarFloat(g_hHomingStrength);
    g_fHomingRange = GetConVarFloat(g_hHomingRange);
}

int LaunchMissile(int client, bool homing)
{
    float eyePos[3], eyeAng[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);

    float vecForward[3];
    GetAngleVectors(eyeAng, vecForward, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(vecForward, vecForward);

    float spawnPos[3];
    spawnPos[0] = eyePos[0] + (vecForward[0] * 32.0);
    spawnPos[1] = eyePos[1] + (vecForward[1] * 32.0);
    spawnPos[2] = eyePos[2] + (vecForward[2] * 16.0);

    int projectile = CreateEntityByName("grenade_launcher_projectile");
    if (projectile == -1)
    {
        return -1;
    }

    DispatchSpawn(projectile);
    ActivateEntity(projectile);

    SetEntityModel(projectile, MISSILE_MODEL);
    SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(projectile, Prop_Send, "m_iTeamNum", GetClientTeam(client));

    float velocity[3];
    velocity[0] = vecForward[0] * g_fMissileSpeed;
    velocity[1] = vecForward[1] * g_fMissileSpeed;
    velocity[2] = vecForward[2] * g_fMissileSpeed;

    TeleportEntity(projectile, spawnPos, eyeAng, velocity);

    if (projectile < sizeof(g_bHomingMissile))
    {
        g_bHomingMissile[projectile] = homing;
        g_iMissileOwner[projectile] = client;
    }

    SDKHook(projectile, SDKHook_Touch, MissileTouch);

    if (homing && projectile < sizeof(g_hHomingTimer))
    {
        g_hHomingTimer[projectile] = CreateTimer(0.05, Timer_UpdateHoming, EntIndexToEntRef(projectile), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }

    return projectile;
}

public Action MissileTouch(int entity, int other)
{
    CleanupMissile(entity);
    return Plugin_Continue;
}

void CleanupMissile(int entity)
{
    if (entity <= 0 || entity >= sizeof(g_hHomingTimer))
    {
        return;
    }

    if (g_hHomingTimer[entity] != null)
    {
        CloseHandle(g_hHomingTimer[entity]);
        g_hHomingTimer[entity] = null;
    }

    g_bHomingMissile[entity] = false;
    g_iMissileOwner[entity] = 0;
}

public Action Timer_UpdateHoming(Handle timer, any ref)
{
    int missile = EntRefToEntIndex(ref);
    if (missile == INVALID_ENT_REFERENCE || missile <= 0 || missile >= sizeof(g_bHomingMissile))
    {
        return Plugin_Stop;
    }

    if (!IsValidEntity(missile))
    {
        return Plugin_Stop;
    }

    int owner = g_iMissileOwner[missile];
    if (!owner || !IsClientInGame(owner))
    {
        return Plugin_Stop;
    }

    int target = FindClosestInfectedTarget(owner, missile);
    if (!target)
    {
        return Plugin_Continue;
    }

    float missilePos[3];
    GetEntPropVector(missile, Prop_Send, "m_vecOrigin", missilePos);

    float targetPos[3];
    GetClientAbsOrigin(target, targetPos);
    targetPos[2] += 45.0;

    float desired[3];
    MakeVectorFromPoints(missilePos, targetPos, desired);

    float length = GetVectorLength(desired);
    if (length > g_fHomingRange)
    {
        return Plugin_Continue;
    }

    NormalizeVector(desired, desired);

    float currentVel[3];
    GetEntPropVector(missile, Prop_Data, "m_vecVelocity", currentVel);

    ScaleVector(desired, g_fMissileSpeed);

    float adjusted[3];
    adjusted[0] = (desired[0] * g_fHomingStrength) + (currentVel[0] * (1.0 - g_fHomingStrength));
    adjusted[1] = (desired[1] * g_fHomingStrength) + (currentVel[1] * (1.0 - g_fHomingStrength));
    adjusted[2] = (desired[2] * g_fHomingStrength) + (currentVel[2] * (1.0 - g_fHomingStrength));

    TeleportEntity(missile, NULL_VECTOR, NULL_VECTOR, adjusted);
    return Plugin_Continue;
}

int FindClosestInfectedTarget(int owner, int missile)
{
#pragma unused owner
float missilePos[3];
    GetEntPropVector(missile, Prop_Send, "m_vecOrigin", missilePos);

    float bestDistance = g_fHomingRange;
    int bestTarget = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i))
        {
            continue;
        }

        if (GetClientTeam(i) != 3)
        {
            continue;
        }

        float targetPos[3];
        GetClientAbsOrigin(i, targetPos);
        targetPos[2] += 45.0;

        float distance = GetVectorDistance(missilePos, targetPos);
        if (distance < bestDistance)
        {
            bestDistance = distance;
            bestTarget = i;
        }
    }

    return bestTarget;
}
