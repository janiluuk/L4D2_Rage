#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <RageCore>
#include <rage/skills>
#include <rage/validation>
#include <rage/timers>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_NAME "Missile"
#define PLUGIN_SKILL_NAME "Missile"
#define MISSILE_MODEL "models/weapons/w_missile_closed.mdl"

#define MISSILE_SPEED_DEFAULT 950.0
#define HOMING_TURN_STRENGTH_DEFAULT 0.65
#define HOMING_RANGE_DEFAULT 1200.0
#define MAX_ENTITY_LIMIT 4096

public Plugin myinfo =
{
    name = "[RAGE] Missile",
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

bool g_bHomingMissile[MAX_ENTITY_LIMIT];
Handle g_hHomingTimer[MAX_ENTITY_LIMIT];
int g_iMissileOwner[MAX_ENTITY_LIMIT];
int g_iClassID = -1;
bool g_bRageAvailable = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("RageMissile_ShowCount", Native_ShowMissileCount);
    RageSkills_MarkNativesOptional();
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hMissileSpeed = CreateConVar("l4d2_missile_speed", "950.0", "Initial speed for fired missiles.");
    g_hHomingStrength = CreateConVar("l4d2_missile_homing_strength", "0.65", "Turn strength for homing missiles (0-1 range).");
    g_hHomingRange = CreateConVar("l4d2_missile_homing_range", "1200.0", "Maximum search distance for homing targets.");

    g_hMissileSpeed.AddChangeHook(OnMissileSettingsChanged);
    g_hHomingStrength.AddChangeHook(OnMissileSettingsChanged);
    g_hHomingRange.AddChangeHook(OnMissileSettingsChanged);

    UpdateSettings();
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
        return;

    if (state == 1)
    {
        g_bRageAvailable = true;
        if (g_iClassID == -1)
        {
            g_iClassID = RegisterRageSkill(PLUGIN_SKILL_NAME, 0);
        }
    }
    else if (state == 0)
    {
        g_bRageAvailable = false;
        g_iClassID = -1;
    }
}

public int OnSpecialSkillUsed(int client, int skill, int type)
{
    if (!g_bRageAvailable)
    {
        return 0;
    }

    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    if (!StrEqual(skillName, PLUGIN_SKILL_NAME, false))
    {
        return 0;
    }

    if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
    {
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "invalid_client");
        return 1;
    }

    // type 0 or 1 = dummy missile, type 2 = homing missile
    // Default to dummy if type is 0 or 1, homing if type is 2
    bool homing = (type == 2);
    int missile = LaunchMissile(client, homing);

    if (missile == -1)
    {
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "failed_to_launch");
        return 1;
    }

    if (homing)
    {
        PrintHintText(client, "✓ Homing missile launched!");
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    }
    else
    {
        PrintHintText(client, "✓ Dummy missile launched!");
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    }

    return 1;
}

public void OnMapStart()
{
    PrecacheModel(MISSILE_MODEL, true);
}

public void OnMapEnd()
{
    for (int i = 0; i < MAX_ENTITY_LIMIT; i++)
    {
        if (g_hHomingTimer[i] != null)
        {
            delete g_hHomingTimer[i];
        }
        g_bHomingMissile[i] = false;
        g_iMissileOwner[i] = 0;
    }
}

public void OnClientDisconnect(int client)
{
    if (!IsValidClient(client))
        return;
    
    // Clean up any missiles owned by this client
    for (int i = 0; i < MAX_ENTITY_LIMIT; i++)
    {
        if (g_iMissileOwner[i] == client)
        {
            CleanupMissile(i);
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if (entity <= 0 || entity >= MAX_ENTITY_LIMIT)
    {
        return;
    }

    if (g_hHomingTimer[entity] != null)
    {
        delete g_hHomingTimer[entity];
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

    bool homing = (type == 2);  // type 1 = dummy missile, type 2 = homing missile
    int missile = LaunchMissile(client, homing);

    if (missile == -1)
    {
        OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "failed_to_launch");
        return -1;
    }

    if (homing)
    {
        PrintHintText(client, "✓ Homing missile launched!");
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    }
    else
    {
        PrintHintText(client, "✓ Dummy missile launched!");
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);
    }
    
    return 1;
}

public void OnMissileSettingsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdateSettings();
}

public any Native_ShowMissileCount(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int missiles = GetNativeCell(2);
    PrintMissileCountHint(client, missiles);
    return 0;
}

void UpdateSettings()
{
    g_fMissileSpeed = g_hMissileSpeed.FloatValue;
    g_fHomingStrength = g_hHomingStrength.FloatValue;
    g_fHomingRange = g_hHomingRange.FloatValue;
}

void PrintMissileCountHint(int client, int missiles)
{
    if (client <= 0 || !IsClientInGame(client) || missiles < 0)
    {
        return;
    }

    PrintHintText(client, "You have now %d missiles", missiles);
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

    // Track missile data if within array bounds
    if (IsValidArrayIndex(projectile, MAX_ENTITY_LIMIT))
    {
        g_bHomingMissile[projectile] = homing;
        g_iMissileOwner[projectile] = client;
        
        if (homing)
        {
            g_hHomingTimer[projectile] = CreateTimer(0.05, Timer_UpdateHoming, EntIndexToEntRef(projectile), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        LogError("Missile entity %d exceeds MAX_ENTITY_LIMIT (%d). Missile tracking disabled for this entity.", projectile, MAX_ENTITY_LIMIT);
        // Clean up the entity we just created since we can't track it
        if (IsValidEntity(projectile))
        {
            AcceptEntityInput(projectile, "Kill");
        }
        return -1;
    }

    SDKHook(projectile, SDKHook_Touch, MissileTouch);

    return projectile;
}

public Action MissileTouch(int entity, int other)
{
    CleanupMissile(entity);
    return Plugin_Continue;
}

void CleanupMissile(int entity)
{
    if (!IsValidArrayIndex(entity, MAX_ENTITY_LIMIT))
    {
        return;
    }

    KillTimerSafe(g_hHomingTimer[entity]);

    g_bHomingMissile[entity] = false;
    g_iMissileOwner[entity] = 0;
}

public Action Timer_UpdateHoming(Handle timer, any ref)
{
    int missile = EntRefToEntIndex(ref);
    if (missile == INVALID_ENT_REFERENCE || !IsValidArrayIndex(missile, MAX_ENTITY_LIMIT))
    {
        return Plugin_Stop;
    }

    if (!IsValidEntity(missile))
    {
        CleanupMissile(missile);
        return Plugin_Stop;
    }

    int owner = g_iMissileOwner[missile];
    if (!IsValidClient(owner))
    {
        CleanupMissile(missile);
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
