#define PLUGIN_VERSION "2.1"
#define PLUGIN_SNAME "Lethal Weapon"
#define PLUGIN_SKILL_NAME "LethalWeapon"

#include <sourcemod>
#include <sdktools>
#include <rage/validation>
#include <rage/skills>
#include <rage/skill_actions>
#include <rage/effects>
#include <rage/debug>

#pragma semicolon 1
#pragma newdecls required

// Sound definitions
#define CHARGESOUND 	"ambient/spacial_loops/lights_flicker.wav"
#define CHARGEDUPSOUND	"level/startwam.wav"  // This is the "ready" sound - used for cooldown notifications
#define AWPSHOT			"weapons/awp/gunfire/awp1.wav"
#define EXPLOSIONSOUND	"animation/bombing_run_01.wav"

// Sprite
#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"

// ConVars
ConVar g_cvarLethalWeapon;
ConVar g_cvarLethalDamage;
ConVar g_cvarLethalForce;
ConVar g_cvarChargeTime;
ConVar g_cvarShootOnce;
ConVar g_cvarFF;
ConVar g_cvarScout;
ConVar g_cvarAWP;
ConVar g_cvarHuntingRifle;
ConVar g_cvarG3SG1;
ConVar g_cvarFlash;
ConVar g_cvarChargingSound;
ConVar g_cvarChargedSound;
ConVar g_cvarMoveAndCharge;
ConVar g_cvarChargeParticle;
ConVar g_cvarUseAmmo;
ConVar g_cvarShake;
ConVar g_cvarShakeIntensity;
ConVar g_cvarShakeShooterOnly;
ConVar g_cvarLaserOffset;

// Client data
int g_iChargeEndTime[MAXPLAYERS+1];
int g_iReleaseLock[MAXPLAYERS+1];
int g_iChargeLock[MAXPLAYERS+1];
Handle g_hClientTimer[MAXPLAYERS+1];
int g_iSprite;

// Weapon offsets
int g_iCurrentWeapon;
int g_iClipSize;

// Position tracking
float g_fMyPos[MAXPLAYERS+1][3];
float g_fTrsPos[MAXPLAYERS+1][3];
float g_fTrsPos002[MAXPLAYERS+1][3];

// Rage system
int g_iClassID = -1;
bool g_bRageAvailable = false;
const int CLASS_SABOTEUR = 4;
int g_iHasAbility[MAXPLAYERS+1] = {-1, ...};

public Plugin myinfo = 
{
	name = "[Rage] Lethal Weapon",
	author = "ztar, M249-M4A1, Rage Integration by Yani",
	description = "Saboteur skill: Charge sniper rifles to create massive explosions",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1121995"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("rage_survivor_lethalweapon");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ConVars
	g_cvarLethalWeapon = CreateConVar("l4d2_lw_lethalweapon", "1", "Enable Lethal Weapon (0:OFF 1:ON 2:SIMPLE)", FCVAR_NOTIFY);
	g_cvarLethalDamage = CreateConVar("l4d2_lw_lethaldamage", "3000.0", "Lethal Weapon base damage", FCVAR_NOTIFY);
	g_cvarLethalForce = CreateConVar("l4d2_lw_lethalforce", "500.0", "Lethal Weapon force", FCVAR_NOTIFY);
	g_cvarChargeTime = CreateConVar("l4d2_lw_chargetime", "7", "Lethal Weapon charge time", FCVAR_NOTIFY);
	g_cvarShootOnce = CreateConVar("l4d2_lw_shootonce", "0", "Survivor can use Lethal Weapon once per round", FCVAR_NOTIFY);
	g_cvarFF = CreateConVar("l4d2_lw_ff", "0", "Lethal Weapon can deal direct damage to other survivors", FCVAR_NOTIFY);
	g_cvarScout = CreateConVar("l4d2_lw_scout", "1", "Enable Lethal Weapon for Scout", FCVAR_NOTIFY);
	g_cvarAWP = CreateConVar("l4d2_lw_awp", "1", "Enable Lethal Weapon for AWP", FCVAR_NOTIFY);
	g_cvarHuntingRifle = CreateConVar("l4d2_lw_huntingrifle", "1", "Enable Lethal Weapon for Hunting Rifle", FCVAR_NOTIFY);
	g_cvarG3SG1 = CreateConVar("l4d2_lw_g3sg1", "1", "Enable Lethal Weapon for G3SG1", FCVAR_NOTIFY);
	g_cvarLaserOffset = CreateConVar("l4d2_lw_laseroffset", "36", "Tracker offset", FCVAR_NOTIFY);
	g_cvarFlash = CreateConVar("l4d2_lw_flash", "1", "Enable screen flash");
	g_cvarChargingSound = CreateConVar("l4d2_lw_chargingsound", "1", "Enable charging sound");
	g_cvarChargedSound = CreateConVar("l4d2_lw_chargedsound", "1", "Enable charged up sound");
	g_cvarMoveAndCharge = CreateConVar("l4d2_lw_moveandcharge", "1", "Enable charging while crouched and moving");
	g_cvarChargeParticle = CreateConVar("l4d2_lw_chargeparticle", "1", "Enable showing electric particles when charged");
	g_cvarUseAmmo = CreateConVar("l4d2_lw_useammo", "1", "Enable and require use of additional ammunition");
	g_cvarShake = CreateConVar("l4d2_lw_shake", "1", "Enable screen shake during explosion");
	g_cvarShakeIntensity = CreateConVar("l4d2_lw_shake_intensity", "50.0", "Intensity of screen shake");
	g_cvarShakeShooterOnly = CreateConVar("l4d2_lw_shake_shooteronly", "0", "Only the shooter experiences screen shake");

	// Events
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("bullet_impact", Event_Bullet_Impact);
	HookEvent("player_incapacitated", Event_Player_Incap, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("player_death", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("infected_death", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("infected_hurt", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("round_end", Event_Round_End, EventHookMode_Pre);

	// Weapon offsets
	g_iCurrentWeapon = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	g_iClipSize = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");

	InitCharge();

	AutoExecConfig(true, "l4d2_lethal_weapon");
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
	else if (state == 0)
	{
		g_bRageAvailable = false;
		g_iClassID = -1;
	}
}

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
	g_iHasAbility[client] = (newClass == CLASS_SABOTEUR) ? 1 : 0;
	return g_iHasAbility[client];
}

public void OnMapStart()
{
	InitPrecache();
}

public void OnMapEnd()
{
	// Reset client arrays
	for (int i = 1; i <= MaxClients; i++)
	{
		KillTimerSafe(g_hClientTimer[i]);
	}
	ResetClientArray(g_iChargeEndTime);
	ResetClientArray(g_iReleaseLock);
	ResetClientArray(g_iChargeLock);
}

public void OnClientDisconnect(int client)
{
	if (client > 0 && client <= MaxClients)
	{
		KillTimerSafe(g_hClientTimer[client]);
		g_iChargeEndTime[client] = 0;
		g_iReleaseLock[client] = 0;
		g_iChargeLock[client] = 0;
		g_iHasAbility[client] = -1;
	}
}

void InitCharge()
{
	// Reset client arrays
	ResetClientArray(g_iChargeEndTime);
	ResetClientArray(g_iReleaseLock);
	ResetClientArray(g_iChargeLock);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_hClientTimer[i] = INVALID_HANDLE;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i))
			continue;
		
		KillTimerSafe(g_hClientTimer[i]);
		g_hClientTimer[i] = CreateTimer(0.5, ChargeTimer, i, TIMER_REPEAT);
	}
}

void InitPrecache()
{
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	
	PrecacheSound(CHARGESOUND, true);
	PrecacheSound(CHARGEDUPSOUND, true);
	PrecacheSound(AWPSHOT, true);
	PrecacheSound(EXPLOSIONSOUND, true);
	
	PrecacheParticle("gas_explosion_main");
	PrecacheParticle("electrical_arc_01_cp0");
	PrecacheParticle("electrical_arc_01_system");
	
	g_iSprite = PrecacheModel(SPRITE_BEAM);
}

public Action Event_Round_End(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillTimerSafe(g_hClientTimer[i]);
		if (IsValidClient(i))
		{
			g_iChargeEndTime[i] = 0;
			g_iReleaseLock[i] = 0;
			g_iChargeLock[i] = 0;
		}
	}
	return Plugin_Continue;
}

public Action Event_Player_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsSurvivor(client))
	{
		KillTimerSafe(g_hClientTimer[client]);
		g_iChargeLock[client] = 0;
		g_hClientTimer[client] = CreateTimer(0.5, ChargeTimer, client, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

public Action Event_Player_Incap(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iReleaseLock[client] = 0;
	g_iChargeEndTime[client] = RoundToCeil(GetGameTime()) + g_cvarChargeTime.IntValue;
	return Plugin_Continue;
}

public Action Event_Bullet_Impact(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_iReleaseLock[client] && g_iHasAbility[client] == 1)
	{
		float targetPos[3];
		targetPos[0] = GetEventFloat(event, "x");
		targetPos[1] = GetEventFloat(event, "y");
		targetPos[2] = GetEventFloat(event, "z");
		
		ExplodeMain(targetPos);
	}
	return Plugin_Continue;
}

public Action Event_Infected_Hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (g_iReleaseLock[client] && g_iHasAbility[client] == 1)
	{
		float targetPos[3];
		int target = GetClientAimTarget(client, false);
		if (target < 0)
			return Plugin_Continue;
		
		// Get entity origin - use GetClientAbsOrigin for clients, GetEntPropVector for other entities
		if (target > 0 && target <= MaxClients && IsClientInGame(target))
		{
			GetClientAbsOrigin(target, targetPos);
		}
		else if (IsValidEntity(target))
		{
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", targetPos);
		}
		else
		{
			return Plugin_Continue;
		}
		
		EmitSoundToAll(EXPLOSIONSOUND, target);
		ExplodeMain(targetPos);
		
		g_iReleaseLock[client] = 0;
	}
	return Plugin_Continue;
}

public Action Event_Player_Hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	int dtype = GetEventInt(event, "type");
	
	if (client && target && g_iReleaseLock[client] && g_iHasAbility[client] == 1 && dtype != 268435464)
	{
		float attackPos[3], targetPos[3];
		GetClientAbsOrigin(client, attackPos);
		GetClientAbsOrigin(target, targetPos);
		
		EmitSoundToAll(EXPLOSIONSOUND, target);
		ExplodeMain(targetPos);
		
		if (g_cvarLethalWeapon.IntValue != 2)
			Smash(client, target, g_cvarLethalForce.FloatValue, 1.5, 2.0);
		
		if ((GetClientTeam(client) != GetClientTeam(target)) || g_cvarFF.BoolValue)
			CreateTimer(0.01, Timer_Damage, target);
		
		g_iReleaseLock[client] = 0;
	}
	return Plugin_Continue;
}

public Action Timer_Damage(Handle timer, any target)
{
	if (IsValidAliveClient(target))
	{
		int health = GetClientHealth(target);
		int damage = g_cvarLethalDamage.IntValue;
		SetEntProp(target, Prop_Data, "m_iHealth", health - damage);
	}
	return Plugin_Stop;
}

public Action Event_Weapon_Fire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iChargeEndTime[client] = RoundToCeil(GetGameTime()) + g_cvarChargeTime.IntValue;
	
	if (g_iReleaseLock[client] && g_iHasAbility[client] == 1)
	{
		if (g_cvarFlash.BoolValue)
		{
			ScreenFade(client, 200, 200, 255, 255, 100, 1);
		}
		if (g_cvarShake.BoolValue)
		{
			ScreenShake(client);
		}
		
		GetTracePosition(client);
		CreateLaserEffect(client, 0, 0, 200, 230, 2.0, 1.00);
		
		EmitSoundToAll(AWPSHOT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 125, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		CreateTimer(0.2, Timer_Release, client);
		if (g_cvarShootOnce.BoolValue)
		{
			g_iChargeLock[client] = 1;
			PrintHintText(client, "Lethal Weapon can only be fired once per round");
		}
		else
		{
			g_iChargeLock[client] = 0;
		}
	}
	return Plugin_Continue;
}

public Action Timer_Release(Handle timer, any client)
{
	if (g_cvarUseAmmo.BoolValue)
	{
		int weapon = GetEntDataEnt2(client, g_iCurrentWeapon);
		int iAmmo = FindDataMapInfo(client, "m_iAmmo");
		SetEntData(weapon, g_iClipSize, 0);
		SetEntData(client, iAmmo+8, RoundToFloor(GetEntData(client, iAmmo+8) / 2.0));
		SetEntData(client, iAmmo+36, RoundToFloor(GetEntData(client, iAmmo+36) / 2.0));
		SetEntData(client, iAmmo+40, RoundToFloor(GetEntData(client, iAmmo+40) / 2.0));
	}
	
	g_iReleaseLock[client] = 0;
	g_iChargeEndTime[client] = RoundToCeil(GetGameTime()) + g_cvarChargeTime.IntValue;
	return Plugin_Stop;
}

public Action ChargeTimer(Handle timer, any client)
{
	if (g_cvarShootOnce.IntValue < 1)
	{
		g_iChargeLock[client] = 0;
	}
	
	StopSound(client, SNDCHAN_AUTO, CHARGESOUND);
	
	if (!g_cvarLethalWeapon.BoolValue || g_iChargeLock[client] || g_iHasAbility[client] != 1)
		return Plugin_Continue;
	
	if (!IsValidClient(client))
	{
		g_hClientTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	int gt = RoundToCeil(GetGameTime());
	int ct = g_cvarChargeTime.IntValue;
	int buttons = GetClientButtons(client);
	int weaponClass = GetEntDataEnt2(client, g_iCurrentWeapon);
	char weapon[32];
	GetClientWeapon(client, weapon, sizeof(weapon));
	
	if (!(StrEqual(weapon, "weapon_sniper_military") && g_cvarG3SG1.BoolValue) &&
		!(StrEqual(weapon, "weapon_sniper_awp") && g_cvarAWP.BoolValue) &&
		!(StrEqual(weapon, "weapon_sniper_scout") && g_cvarScout.BoolValue) &&
		!(StrEqual(weapon, "weapon_hunting_rifle") && g_cvarHuntingRifle.BoolValue))
	{
		StopSound(client, SNDCHAN_AUTO, CHARGESOUND);
		g_iReleaseLock[client] = 0;
		g_iChargeEndTime[client] = gt + ct;
		return Plugin_Continue;
	}
	
	bool inCharge = ((GetEntityFlags(client) & FL_DUCKING) &&
					(GetEntityFlags(client) & FL_ONGROUND) &&
					!(buttons & IN_ATTACK) &&
					!(buttons & IN_ATTACK2));
	
	if (g_cvarMoveAndCharge.IntValue < 1)
	{
		inCharge = ((GetEntityFlags(client) & FL_DUCKING) &&
					(GetEntityFlags(client) & FL_ONGROUND) &&
					!(buttons & IN_FORWARD) &&
					!(buttons & IN_MOVERIGHT) &&
					!(buttons & IN_MOVELEFT) &&
					!(buttons & IN_BACK) &&
					!(buttons & IN_ATTACK) &&
					!(buttons & IN_ATTACK2));
	}
	
	if (inCharge && GetEntData(weaponClass, g_iClipSize))
	{
		if (g_iChargeEndTime[client] < gt)
		{
			PrintCenterText(client, "***************** CHARGED *****************");
			if (g_iReleaseLock[client] != 1)
			{
				float pos[3];
				GetClientAbsOrigin(client, pos);
				if (g_cvarChargedSound.BoolValue)
				{
					EmitSoundToAll(CHARGEDUPSOUND, client);
				}
				if (g_cvarChargeParticle.BoolValue)
				{
					float nullAng[3] = {0.0, 0.0, 0.0};
					ShowParticle(pos, nullAng, "electrical_arc_01_system", 5.0);
				}
			}
			g_iReleaseLock[client] = 1;
		}
		else
		{
			int i, j;
			char chargeBar[50];
			char gauge1[2] = "|";
			char gauge2[2] = " ";
			float gaugeNum = (float(ct) - (float(g_iChargeEndTime[client] - gt))) * (100.0/float(ct))/2.0;
			g_iReleaseLock[client] = 0;
			if(gaugeNum > 50.0)
				gaugeNum = 50.0;
			
			for(i=0; i<gaugeNum; i++)
				chargeBar[i] = gauge1[0];
			for(j=i; j<50; j++)
				chargeBar[j] = gauge2[0];
			if (gaugeNum >= 15)
			{
				float pos[3];
				GetClientAbsOrigin(client, pos);
				pos[2] += 45;
				if (g_cvarChargeParticle.BoolValue)
				{
					float nullAng[3] = {0.0, 0.0, 0.0};
					ShowParticle(pos, nullAng, "electrical_arc_01_cp0", 5.0);
				}
				if (g_cvarChargingSound.BoolValue)
				{
					EmitSoundToAll(CHARGESOUND, client);
				}
			}
			PrintCenterText(client, "           << CHARGE IN PROGRESS >>\n0%% %s %3.0f%%", chargeBar, gaugeNum*2);
		}
	}
	else
	{
		StopSound(client, SNDCHAN_AUTO, CHARGESOUND);
		g_iReleaseLock[client] = 0;
		g_iChargeEndTime[client] = gt + ct;
	}
	
	return Plugin_Continue;
}

void ExplodeMain(float pos[3])
{
	float nullAng[3] = {0.0, 0.0, 0.0};
	if (g_cvarChargeParticle.BoolValue)
	{
		ShowParticle(pos, nullAng, "electrical_arc_01_system", 5.0);
	}
	LittleFlower(pos, 1);
	
	if (g_cvarLethalWeapon.IntValue == 1)
	{
		ShowParticle(pos, nullAng, "gas_explosion_main", 5.0);
		LittleFlower(pos, 0);
	}
}

void LittleFlower(float pos[3], int type)
{
	int entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
			DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
		else
			DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

void Smash(int client, int target, float power, float powHor, float powVec)
{
	if (g_cvarFF.BoolValue || GetClientTeam(target) != 2)
	{
		float headingVector[3], aimVector[3];
		GetClientEyeAngles(client, headingVector);
	
		aimVector[0] = Cosine(DegToRad(headingVector[1])) * power * powHor;
		aimVector[1] = Sine(DegToRad(headingVector[1])) * power * powHor;
	
		float current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
		float resulting[3];
		resulting[0] = current[0] + aimVector[0];
		resulting[1] = current[1] + aimVector[1];
		resulting[2] = power * powVec;
	
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
	}
}

void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
	{
		BfWriteShort(msg, (0x0002 | 0x0008));
	}
	else
	{
		BfWriteShort(msg, (0x0001 | 0x0010));
	}
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

void ScreenShake(int target)
{
	Handle msg;
	if (g_cvarShakeShooterOnly.BoolValue)
	{
		msg = StartMessageAll("Shake");
	}
	else
	{
		msg = StartMessageOne("Shake", target);
	}
	BfWriteByte(msg, 0);
	BfWriteFloat(msg, g_cvarShakeIntensity.FloatValue);
	BfWriteFloat(msg, 10.0);
	BfWriteFloat(msg, 3.0);
	EndMessage();
}

void GetTracePosition(int client)
{
	float myAng[3];
	GetClientEyePosition(client, g_fMyPos[client]);
	GetClientEyeAngles(client, myAng);
	Handle trace = TR_TraceRayFilterEx(g_fMyPos[client], myAng, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayer, client);
	if(TR_DidHit(trace))
		TR_GetEndPosition(g_fTrsPos[client], trace);
	CloseHandle(trace);
	for(int i = 0; i < 3; i++)
		g_fTrsPos002[client][i] = g_fTrsPos[client][i];
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

void CreateLaserEffect(int client, int colRed, int colGre, int colBlu, int alpha, float width, float duration)
{
	float tmpVec[3];
	SubtractVectors(g_fMyPos[client], g_fTrsPos[client], tmpVec);
	NormalizeVector(tmpVec, tmpVec);
	ScaleVector(tmpVec, g_cvarLaserOffset.FloatValue);
	SubtractVectors(g_fMyPos[client], tmpVec, g_fTrsPos[client]);
	
	int color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	TE_SetupBeamPoints(g_fMyPos[client], g_fTrsPos002[client], g_iSprite, 0, 0, 0, duration, width, width, 1, 0.0, color, 0);
	TE_SendToAll();
}

