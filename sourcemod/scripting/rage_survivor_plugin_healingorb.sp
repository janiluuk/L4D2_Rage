#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <rage/skills>
#include <rage/validation>

#define PLUGIN_VERSION	"0.2"
#define CVAR_FLAGS		FCVAR_NONE
#define PLUGIN_SKILL_NAME "HealingOrb"
#define PLUGIN_SKILL_DESCRIPTION "Summons a healing orb near the player to patch up allies."
public Plugin myinfo =
{
        name = "Healing orb skill",
	author = "zonde306, Yani",
	description = PLUGIN_SKILL_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};

#define HealingBall_Particle_Effect	"st_elmos_fire_cp0"
#define HealingBall_Sound_Lanuch	"ambient/fire/gascan_ignite1.wav"
#define HealingBall_Sound_Heal		"buttons/bell1.wav"
#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"
#define SPRITE_HALO		"materials/sprites/halo01.vmt"
#define SPRITE_GLOW		"materials/sprites/glow01.vmt"

int BlueColor[4] = {80, 80, 255, 255};
Handle HealingBallTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
int g_BeamSprite, g_HaloSprite, g_GlowSprite;

float HealingBallInterval[MAXPLAYERS+1], HealingBallEffect[MAXPLAYERS+1],
        HealingBallRadius[MAXPLAYERS+1], HealingBallDuration[MAXPLAYERS+1];
ConVar g_hHealingOrbCooldown = null;
float g_fHealingOrbCooldown = 30.0;
float g_fNextHealingOrbUse[MAXPLAYERS+1];

public void OnPluginStart()
{
        g_hHealingOrbCooldown = CreateConVar("healing_orb_cooldown", "30.0", "Cooldown between healing orb uses in seconds.", CVAR_FLAGS, true, 0.0);
        g_fHealingOrbCooldown = GetConVarFloat(g_hHealingOrbCooldown);
        HookConVarChange(g_hHealingOrbCooldown, OnHealingOrbCooldownChanged);

        for (int i = 1; i <= MaxClients; ++i)
        {
                HealingBallTimer[i] = INVALID_HANDLE;
                g_fNextHealingOrbUse[i] = 0.0;
        }
}

public void OnHealingOrbCooldownChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
        g_fHealingOrbCooldown = GetConVarFloat(convar);
}

public int OnSpecialSkillUsed(int client, int skill, int type)
{
        char skillName[32];
        GetPlayerSkillName(client, skillName, sizeof(skillName));
        if(!StrEqual(skillName, PLUGIN_SKILL_NAME, false))
                return 0;

        float now = GetEngineTime();
        float remaining = g_fNextHealingOrbUse[client] - now;

        if (remaining > 0.0)
        {
                PrintHintText(client, "Healing orb ready in %.0f seconds", remaining);
                return 1;
        }

        HealingBallInterval[client] = 1.0;
        HealingBallEffect[client] = 1.5;
        HealingBallRadius[client] = 130.0;
        HealingBallDuration[client] = 8.0;
        g_fNextHealingOrbUse[client] = now + g_fHealingOrbCooldown;
        HealingBallFunction(client);
        PrintHintText(client, "Healing orb now active");

        return 1;
}

public void OnMapStart()
{
	PrecacheSound(HealingBall_Sound_Lanuch, true);
	PrecacheSound(HealingBall_Sound_Heal, true);
	PrecacheParticle(HealingBall_Particle_Effect);
	g_BeamSprite = PrecacheModel(SPRITE_BEAM);
	g_HaloSprite = PrecacheModel(SPRITE_HALO);
	g_GlowSprite = PrecacheModel(SPRITE_GLOW);
}

public void OnMapEnd()
{
        for(int i = 1; i <= MaxClients; ++i)
        {
                if(HealingBallTimer[i] != INVALID_HANDLE)
                        KillTimer(HealingBallTimer[i]);

                HealingBallTimer[i] = INVALID_HANDLE;
                g_fNextHealingOrbUse[i] = 0.0;
        }
}

public void OnClientDisconnect(int client)
{
        if (HealingBallTimer[client] != INVALID_HANDLE)
        {
                KillTimer(HealingBallTimer[client]);
                HealingBallTimer[client] = INVALID_HANDLE;
        }

        g_fNextHealingOrbUse[client] = 0.0;
}

public Action HealingBallFunction(int Client)
{
	float Radius = HealingBallRadius[Client];
	float pos[3];
	GetTracePosition(Client, pos);
	pos[2] += 50.0;
	EmitAmbientSound(HealingBall_Sound_Lanuch, pos);
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 1.0, 5.0, 5.0, BlueColor, 5, 0);
	TE_SendToAll();
	
	for(int i = 1; i<5; i++)
	{
		TE_SetupGlowSprite(pos, g_GlowSprite, 1.0, 2.5, 1000);
		TE_SendToAll();
	}

	if(HealingBallTimer[Client] != INVALID_HANDLE)
		KillTimer(HealingBallTimer[Client]);
	
	HealingBallTimer[Client] = INVALID_HANDLE;
	
	Handle pack;
	HealingBallTimer[Client] = CreateDataTimer(HealingBallInterval[Client], HealingBallTimerFunction, pack, TIMER_REPEAT);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);
	WritePackFloat(pack, GetEngineTime());

	return Plugin_Handled;
}

public Action HealingBallTimerFunction(Handle timer, Handle pack)
{
	float pos[3], entpos[3], distance[3];
	
	ResetPack(pack);
	int Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	float time = ReadPackFloat(pack);
	
	EmitAmbientSound(HealingBall_Sound_Heal, pos);
	for(int i = 1; i<5; i++)
	{
		TE_SetupGlowSprite(pos, g_GlowSprite, 1.0, 2.5, 1000);
		TE_SendToAll();
	}
	
	float Radius = HealingBallRadius[Client];
	
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 1.0, 10.0, 5.0, BlueColor, 5, 0);
	TE_SendToAll();

	int team = GetClientTeam(Client);
	if(GetEngineTime() - time < HealingBallDuration[Client])
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(GetClientTeam(i) == team && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						int HP = GetClientHealth(i);
						
						if(IsPlayerIncapped(i))
						{
							SetEntProp(i, Prop_Data, "m_iHealth", HP+RoundToCeil(HealingBallEffect[Client]));
						}
						else
						{
							int MaxHP = GetEntProp(i, Prop_Data, "m_iMaxHealth");
							HP += RoundToCeil(HealingBallEffect[Client]);
							if(HP > MaxHP)
								HP = MaxHP;
							
							SetEntProp(i, Prop_Data, "m_iHealth", HP);
						}
						
						ShowParticle(entpos, HealingBall_Particle_Effect, 0.5);
						TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 0.5, BlueColor, 0);
						TE_SendToAll();
					}
				}
			}
		}
	}
	else
	{
		KillTimer(HealingBallTimer[Client]);
		HealingBallTimer[Client] = INVALID_HANDLE;
	}
}

/* Read crosshair position */
public void GetTracePosition(int client, float TracePos[3])
{
	float clientPos[3], clientAng[3];

	GetClientEyePosition(client, clientPos);
	GetClientEyeAngles(client, clientAng);
	Handle trace = TR_TraceRayFilterEx(clientPos, clientAng, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(TracePos, trace);
	}
	delete trace;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

public void ShowParticle(float pos[3], char[] particlename, float time)
{
	/* Show particle effect you like */
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public void AttachParticle(int ent, char[] particleType, float time)
{
	char tName[64];
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle) && IsValidEdict(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName); 
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
	/* Delete particle */
    if(IsValidEdict(particle) && IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}

public void PrecacheParticle(char[] particlename)
{
	/* Precache particle */
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}
}

