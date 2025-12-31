/**
 * =============================================================================
 * Rage Edition - Melee In The Saferoom
 * Spawns a selection of melee weapons in the saferoom at the start of each round
 * 
 * Based on "Melee In The Saferoom" by N3wton
 * Integrated and modernized for L4D2 Rage Edition
 * =============================================================================
 */

#define PLUGIN_NAME "[RAGE] Melee In The Saferoom"
#define PLUGIN_VERSION "2.0.7"
#define PLUGIN_IDENTIFIER "rage_plugin_melee_saferoom"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <rage/validation>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "N3wton / Rage Edition",
	description = "Spawns a selection of melee weapons in the saferoom at the start of each round.",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar g_hEnabled;
ConVar g_hWeaponRandom;
ConVar g_hWeaponRandomAmount;
ConVar g_hWeaponBaseballBat;
ConVar g_hWeaponCricketBat;
ConVar g_hWeaponCrowbar;
ConVar g_hWeaponElecGuitar;
ConVar g_hWeaponFireAxe;
ConVar g_hWeaponFryingPan;
ConVar g_hWeaponGolfClub;
ConVar g_hWeaponKnife;
ConVar g_hWeaponKatana;
ConVar g_hWeaponPitchfork;
ConVar g_hWeaponShovel;
ConVar g_hWeaponMachete;
ConVar g_hWeaponRiotShield;
ConVar g_hWeaponTonfa;

bool g_bSpawnedMelee;
int g_iMeleeClassCount = 0;
int g_iMeleeRandomSpawn[20];
int g_iRound = 2;

char g_sMeleeClass[16][32];

public void OnPluginStart()
{
	char GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead2"))
	{
		SetFailState("Melee In The Saferoom is only supported on left 4 dead 2.");
		return;
	}

	CreateConVar("rage_survivor_melee_saferoom_version", PLUGIN_VERSION, "The version of Melee In The Saferoom", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("rage_survivor_melee_saferoom_enabled", "1", "Should the plugin be enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hWeaponRandom = CreateConVar("rage_survivor_melee_saferoom_random", "1", "Spawn Random Weapons (1) or custom list (0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hWeaponRandomAmount = CreateConVar("rage_survivor_melee_saferoom_amount", "4", "Number of weapons to spawn if random mode is enabled", FCVAR_PLUGIN, true, 1.0, true, 20.0);
	g_hWeaponBaseballBat = CreateConVar("rage_survivor_melee_saferoom_baseball_bat", "1", "Number of baseball bats to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponCricketBat = CreateConVar("rage_survivor_melee_saferoom_cricket_bat", "1", "Number of cricket bats to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponCrowbar = CreateConVar("rage_survivor_melee_saferoom_crowbar", "1", "Number of crowbars to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponElecGuitar = CreateConVar("rage_survivor_melee_saferoom_electric_guitar", "1", "Number of electric guitars to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponFireAxe = CreateConVar("rage_survivor_melee_saferoom_fireaxe", "1", "Number of fireaxes to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponFryingPan = CreateConVar("rage_survivor_melee_saferoom_frying_pan", "1", "Number of frying pans to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponGolfClub = CreateConVar("rage_survivor_melee_saferoom_golfclub", "1", "Number of golf clubs to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponKnife = CreateConVar("rage_survivor_melee_saferoom_knife", "1", "Number of knives to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponKatana = CreateConVar("rage_survivor_melee_saferoom_katana", "1", "Number of katanas to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponPitchfork = CreateConVar("rage_survivor_melee_saferoom_pitchfork", "1", "Number of pitchforks to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponShovel = CreateConVar("rage_survivor_melee_saferoom_shovel", "1", "Number of shovels to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponMachete = CreateConVar("rage_survivor_melee_saferoom_machete", "1", "Number of machetes to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponRiotShield = CreateConVar("rage_survivor_melee_saferoom_riotshield", "1", "Number of riot shields to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hWeaponTonfa = CreateConVar("rage_survivor_melee_saferoom_tonfa", "1", "Number of tonfas to spawn (random mode must be 0)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	
	AutoExecConfig(true, "rage_plugin_melee_saferoom");
	
	RegPluginLibrary("rage_plugin_melee_saferoom");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	RegAdminCmd("sm_melee", Command_SMMelee, ADMFLAG_KICK, "Lists all melee weapons spawnable in current campaign");
}

public void OnMapStart()
{
	PrecacheModel("models/weapons/melee/v_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/v_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/v_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/v_katana.mdl", true);
	PrecacheModel("models/weapons/melee/v_pitchfork.mdl", true);
	PrecacheModel("models/weapons/melee/v_shovel.mdl", true);
	PrecacheModel("models/weapons/melee/v_machete.mdl", true);
	PrecacheModel("models/weapons/melee/v_tonfa.mdl", true);

	PrecacheModel("models/weapons/melee/w_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/w_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/w_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/w_katana.mdl", true);
	PrecacheModel("models/weapons/melee/w_pitchfork.mdl", true);
	PrecacheModel("models/weapons/melee/w_shovel.mdl", true);
	PrecacheModel("models/weapons/melee/w_machete.mdl", true);
	PrecacheModel("models/weapons/melee/w_tonfa.mdl", true);

	PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
	PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
	PrecacheGeneric("scripts/melee/crowbar.txt", true);
	PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
	PrecacheGeneric("scripts/melee/fireaxe.txt", true);
	PrecacheGeneric("scripts/melee/frying_pan.txt", true);
	PrecacheGeneric("scripts/melee/golfclub.txt", true);
	PrecacheGeneric("scripts/melee/katana.txt", true);
	PrecacheGeneric("scripts/melee/pitchfork.txt", true);
	PrecacheGeneric("scripts/melee/shovel.txt", true);
	PrecacheGeneric("scripts/melee/machete.txt", true);
	PrecacheGeneric("scripts/melee/tonfa.txt", true);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_hEnabled))
	{
		return Plugin_Continue;
	}

	g_bSpawnedMelee = false;

	if (g_iRound == 2 && IsVersus())
	{
		g_iRound = 1;
	}
	else
	{
		g_iRound = 2;
	}

	GetMeleeClasses();

	CreateTimer(1.0, Timer_SpawnMelee, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bSpawnedMelee = false;
	return Plugin_Continue;
}

public Action Timer_SpawnMelee(Handle timer)
{
	if (g_bSpawnedMelee)
	{
		return Plugin_Stop;
	}

	int client = GetInGameClient();

	if (client > 0 && IsValidClient(client))
	{
		float SpawnPosition[3];
		float SpawnAngle[3] = {90.0, 0.0, 0.0};
		
		GetClientAbsOrigin(client, SpawnPosition);
		SpawnPosition[2] += 20.0;

		if (GetConVarBool(g_hWeaponRandom))
		{
			int amount = GetConVarInt(g_hWeaponRandomAmount);
			if (amount > 0 && g_iMeleeClassCount > 0)
			{
				for (int i = 0; i < amount; i++)
				{
					int RandomMelee = GetRandomInt(0, g_iMeleeClassCount - 1);
					if (IsVersus() && g_iRound == 2)
					{
						if (IsValidArrayIndex(i, sizeof(g_iMeleeRandomSpawn)))
						{
							RandomMelee = g_iMeleeRandomSpawn[i];
						}
					}
					
					if (IsValidArrayIndex(RandomMelee, sizeof(g_sMeleeClass)))
					{
						SpawnMelee(g_sMeleeClass[RandomMelee], SpawnPosition, SpawnAngle);
					}
					
					if (IsVersus() && g_iRound == 1)
					{
						if (IsValidArrayIndex(i, sizeof(g_iMeleeRandomSpawn)))
						{
							g_iMeleeRandomSpawn[i] = RandomMelee;
						}
					}
				}
			}
			g_bSpawnedMelee = true;
		}
		else
		{
			SpawnCustomList(SpawnPosition, SpawnAngle);
			g_bSpawnedMelee = true;
		}
	}
	else
	{
		// Retry if no client found yet
		CreateTimer(1.0, Timer_SpawnMelee, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

void SpawnCustomList(float Position[3], float Angle[3])
{
	char ScriptName[32];

	// Spawn Baseball Bats
	int count = GetConVarInt(g_hWeaponBaseballBat);
	if (count > 0)
	{
		GetScriptName("baseball_bat", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Cricket Bats
	count = GetConVarInt(g_hWeaponCricketBat);
	if (count > 0)
	{
		GetScriptName("cricket_bat", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Crowbars
	count = GetConVarInt(g_hWeaponCrowbar);
	if (count > 0)
	{
		GetScriptName("crowbar", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Electric Guitars
	count = GetConVarInt(g_hWeaponElecGuitar);
	if (count > 0)
	{
		GetScriptName("electric_guitar", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Fireaxes
	count = GetConVarInt(g_hWeaponFireAxe);
	if (count > 0)
	{
		GetScriptName("fireaxe", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Frying Pans
	count = GetConVarInt(g_hWeaponFryingPan);
	if (count > 0)
	{
		GetScriptName("frying_pan", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Golfclubs
	count = GetConVarInt(g_hWeaponGolfClub);
	if (count > 0)
	{
		GetScriptName("golfclub", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Knifes
	count = GetConVarInt(g_hWeaponKnife);
	if (count > 0)
	{
		GetScriptName("hunting_knife", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Katanas
	count = GetConVarInt(g_hWeaponKatana);
	if (count > 0)
	{
		GetScriptName("katana", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Pitchforks
	count = GetConVarInt(g_hWeaponPitchfork);
	if (count > 0)
	{
		GetScriptName("pitchfork", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Shovels
	count = GetConVarInt(g_hWeaponShovel);
	if (count > 0)
	{
		GetScriptName("shovel", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Machetes
	count = GetConVarInt(g_hWeaponMachete);
	if (count > 0)
	{
		GetScriptName("machete", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn RiotShields
	count = GetConVarInt(g_hWeaponRiotShield);
	if (count > 0)
	{
		GetScriptName("riotshield", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}

	// Spawn Tonfas
	count = GetConVarInt(g_hWeaponTonfa);
	if (count > 0)
	{
		GetScriptName("tonfa", ScriptName, sizeof(ScriptName));
		for (int i = 0; i < count; i++)
		{
			SpawnMelee(ScriptName, Position, Angle);
		}
	}
}

void SpawnMelee(const char[] Class, float Position[3], float Angle[3])
{
	float SpawnPosition[3];
	float SpawnAngle[3];
	
	SpawnPosition = Position;
	SpawnAngle = Angle;

	SpawnPosition[0] += (-10.0 + GetRandomFloat(0.0, 20.0));
	SpawnPosition[1] += (-10.0 + GetRandomFloat(0.0, 20.0));
	SpawnPosition[2] += GetRandomFloat(0.0, 10.0);
	SpawnAngle[1] = GetRandomFloat(0.0, 360.0);

	int MeleeSpawn = CreateEntityByName("weapon_melee");
	if (IsValidEntity(MeleeSpawn))
	{
		DispatchKeyValue(MeleeSpawn, "melee_script_name", Class);
		DispatchSpawn(MeleeSpawn);
		TeleportEntity(MeleeSpawn, SpawnPosition, SpawnAngle, NULL_VECTOR);
	}
}

void GetMeleeClasses()
{
	int MeleeStringTable = FindStringTable("MeleeWeapons");
	if (MeleeStringTable == INVALID_STRING_TABLE)
	{
		g_iMeleeClassCount = 0;
		return;
	}

	g_iMeleeClassCount = GetStringTableNumStrings(MeleeStringTable);
	if (g_iMeleeClassCount > sizeof(g_sMeleeClass))
	{
		g_iMeleeClassCount = sizeof(g_sMeleeClass);
	}

	for (int i = 0; i < g_iMeleeClassCount; i++)
	{
		ReadStringTable(MeleeStringTable, i, g_sMeleeClass[i], sizeof(g_sMeleeClass[]));
	}
}

void GetScriptName(const char[] Class, char[] ScriptName, int maxlen)
{
	for (int i = 0; i < g_iMeleeClassCount; i++)
	{
		if (StrContains(g_sMeleeClass[i], Class, false) == 0)
		{
			strcopy(ScriptName, maxlen, g_sMeleeClass[i]);
			return;
		}
	}
	
	// Fallback to first available melee if not found
	if (g_iMeleeClassCount > 0)
	{
		strcopy(ScriptName, maxlen, g_sMeleeClass[0]);
	}
	else
	{
		strcopy(ScriptName, maxlen, "baseball_bat");
	}
}

int GetInGameClient()
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x) && GetClientTeam(x) == 2 && IsPlayerAlive(x))
		{
			return x;
		}
	}
	return 0;
}

bool IsVersus()
{
	char GameMode[32];
	ConVar cvar = FindConVar("mp_gamemode");
	if (cvar != null)
	{
		cvar.GetString(GameMode, sizeof(GameMode));
		return (StrContains(GameMode, "versus", false) != -1);
	}
	return false;
}

public Action Command_SMMelee(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	PrintToChat(client, "[Melee] Available melee weapons in current campaign:");
	for (int i = 0; i < g_iMeleeClassCount; i++)
	{
		PrintToChat(client, "  %d: %s", i, g_sMeleeClass[i]);
	}
	
	return Plugin_Handled;
}

