enum L4D2Infected
{
	L4D2Infected_None = 0,
	L4D2Infected_Smoker = 1,
	L4D2Infected_Boomer = 2,
	L4D2Infected_Hunter = 3,
	L4D2Infected_Spitter = 4,
	L4D2Infected_Jockey = 5,
	L4D2Infected_Charger = 6,
	L4D2Infected_Witch = 7,
	L4D2Infected_Tank = 8
};

GlobalForward g_PlayerMarkedForward;
GlobalForward g_PerkAppliedForward;
GlobalForward g_PerkRemovedForward;
Handle g_hWitchAttack;
int g_iWitchAttackVictim;
Handle hThrowTimer;

ConVar hThrowItemInterval;
ConVar hAutoPunish;
ConVar hMagnetChance;
ConVar hShoveFailChance;
ConVar hAutoPunishExpire;
ConVar hMagnetTargetMode;
ConVar hBadThrowHitSelf;
ConVar hBotReverseFFDefend;
ConVar hSbFriendlyFire;
ConVar hBotDefendChance;

ConVar hSbFixEnabled;
bool wasSbFixEnabled;

int wasAbmAutoHard;
ConVar hAbmAutoHard;

enum playerDataFlags {
	Flag_PendingItemGive = 1,
	Flag_HasSpitTimer = 2,
	Flag_IsTargettingHealer = 4
}

enum struct PlayerData {
	int flags;

	int attackerTargetUid;
	int specialAttackFlags;
	int pendingPerkBan; // Includes ent index of activator

	float lastInSpitTime;

	int shootAtTarget;
	int shootAtLoops;
	int shootAtTargetHealth;

	int smartChargeAttempts;
	int smartChargeMaxAttempts;
	int smartChargeActivator;

	char steamid[32];

	void Reset() {
		this.flags = 0;
		this.attackerTargetUid = 0;
		this.specialAttackFlags = 0;
		this.pendingPerkBan = 0;
		this.lastInSpitTime = 0.0;
		this.shootAtTarget = 0;
		this.shootAtLoops = 0;
		this.smartChargeAttempts = 0;
		this.steamid[0] = '\0';
	}
}

PlayerData pdata[MAXPLAYERS+1];

int lastButtonUser;
int lastCrescendoUser;

bool spIsActive;
enum SpecialSpawnFlags {
	Special_Anywhere = 0,
	Special_OnTarget = 1,
	Special_SpawnDirectOnFailure = 2
}

enum SpecialInternalFlags {
	SPI_KillOnSpawn = 1,
	SPI_AlwaysTarget = 2,
}

int healTargetPlayer;
float healTargetPos[3];
Handle stopHealingTimer;

float entLastHeight[2048];

float fLastAntiRushEvent[MAXPLAYERS+1];
float fAntiRushFrequencyCounter[MAXPLAYERS+1];


#define MODEL_CAR "models/props_vehicles/cara_95sedan.mdl"

// Required includes for rage_perks modules
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks>
// Note: jutils and rage/validation both define IsValidClient as stock with different signatures
// Include jutils first, then rage/validation (which will be skipped due to include guard if jutils included it)
// Actually, jutils doesn't include rage/validation, so we need both but they conflict
// Solution: Include rage/validation, and define jutils functions we need inline
#include <rage/validation>
#tryinclude <basecomm>
// Note: multicolors includes colors/morecolors functionality, use it instead to avoid conflicts
#tryinclude <multicolors>
#tryinclude <sceneprocessor>

// Define jutils functions we need (to avoid conflict with IsValidClient)
#if !defined _jutils_included
stock int GetClientWeaponEntIndex(int client, int slot) {
	if(slot >= 0 && slot <= 4) {
		int wpnRef = GetPlayerWeaponSlot(client, slot);
		if(wpnRef != -1) {
			int wpn = EntRefToEntIndex(wpnRef);
			return (wpn != INVALID_ENT_REFERENCE) ? wpn : -1;
		}
	}
	return -1;
}

stock bool GetClientWeaponName(int client, int slot, char[] name, int nameSize) {
	int wpn = GetClientWeaponEntIndex(client, slot);
	if(wpn > 0) {
		GetEntityClassname(wpn, name, nameSize);
		return true;
	}
	return false;
}

stock void GetHorizontalPositionFromOrigin(const float pos[3], const float ang[3], float units, float finalPosition[3]) {
	float direction[3];
	GetAngleVectors(ang, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	ScaleVector(direction, units);
	AddVectors(pos, direction, finalPosition);
}

stock void GetHorizontalPositionFromClient(int client, float units, float finalPosition[3]) {
	float pos[3], ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, ang);
	GetHorizontalPositionFromOrigin(pos, ang, units, finalPosition);
}

stock void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2) {
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
}

stock void L4D2_RunScript(const char[] sCode, any ...) {
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		DispatchSpawn(iScriptLogic);
	}
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

stock void GiveClientWeapon(int client, const char[] weaponName) {
	int weapon = GivePlayerItem(client, weaponName);
	if(weapon != -1) {
		EquipPlayerWeapon(client, weapon);
	}
}

stock bool IsPlayerFarDistance(int client, float minDistance) {
	if(!IsValidClient(client) || GetClientTeam(client) != 2) return false;
	
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	
	float closestDist = -1.0;
	for(int i = 1; i <= MaxClients; i++) {
		if(i == client || !IsValidClient(i) || GetClientTeam(i) != 2) continue;
		float otherPos[3];
		GetClientAbsOrigin(i, otherPos);
		float dist = GetVectorDistance(clientPos, otherPos);
		if(closestDist < 0.0 || dist < closestDist) {
			closestDist = dist;
		}
	}
	
	return (closestDist >= 0.0 && closestDist >= minDistance);
}

stock void NotifyAllAdmins(const char[] format, any ...) {
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true)) {
			PrintToChat(i, "\x04[Admin]\x01 %s", buffer);
		}
	}
}

stock void StringToLower(char[] str) {
	int len = strlen(str);
	for(int i = 0; i < len; i++) {
		if(str[i] >= 'A' && str[i] <= 'Z') {
			str[i] += 32; // Convert to lowercase
		}
	}
}

stock int GetRealClient(int client) {
	// If client is a bot, try to find the real player controlling them
	if(IsFakeClient(client) && GetClientTeam(client) == 2) {
		int idlePlayer = GetSpectatorClient(client);
		if(idlePlayer > 0) {
			return idlePlayer;
		}
	}
	return client;
}

stock bool DoesClientHaveMelee(int client) {
	int wpnEnt = GetClientWeaponEntIndex(client, 1);
	if(wpnEnt <= 0) return false;
	char wpn[32];
	GetEntityClassname(wpnEnt, wpn, sizeof(wpn));
	return (StrContains(wpn, "melee") != -1 || StrContains(wpn, "knife") != -1);
}
#endif

// Constants
#define MAIN_TIMER_INTERVAL_S 0.1
#define ANTI_RUSH_DEFAULT_FREQUENCY 30.0
#define ANTI_RUSH_FREQ_INC 5.0

// Helper functions
stock void ThrowAllItems(int client) {
	// Implementation needed - placeholder for now
	// This function should throw all items from the client
}

#include <rage_perks/base>
#include <rage_perks/helpers>
#include <rage_perks/classes>
#include <rage_perks/combos>
#include <rage_perks/specials>
#include <rage_perks/misc>
#include <rage_perks/commands>
#include <rage_perks/events>
#include <rage_perks/timers>
#include <rage_perks/menus>
#include <rage_perks/validation>

