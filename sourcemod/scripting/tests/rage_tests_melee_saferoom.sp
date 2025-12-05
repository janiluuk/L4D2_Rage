/**
 * =============================================================================
 * Rage Edition - Melee Saferoom Tests
 * Tests for the melee in saferoom plugin
 * =============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <rage/validation>

public Plugin myinfo =
{
	name = "[Tests] Melee Saferoom",
	author = "Rage Edition",
	description = "Tests for melee saferoom plugin",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	RegServerCmd("test_melee_saferoom", Command_TestMeleeSaferoom);
	RegServerCmd("test_melee_models", Command_TestMeleeModels);
	RegServerCmd("test_melee_config", Command_TestMeleeConfig);
}

public Action Command_TestMeleeSaferoom(int args)
{
	PrintToServer("[Melee Test] Starting melee saferoom tests...");
	
	bool allPassed = true;
	
	// Test 1: Check if plugin is loaded
	if (!LibraryExists("rage_survivor_melee_saferoom"))
	{
		PrintToServer("[Melee Test] ✗ FAILED: Plugin not loaded");
		allPassed = false;
	}
	else
	{
		PrintToServer("[Melee Test] ✓ PASSED: Plugin is loaded");
	}
	
	// Test 2: Check ConVars exist
	ConVar cvar = FindConVar("rage_survivor_melee_saferoom_enabled");
	if (cvar == null)
	{
		PrintToServer("[Melee Test] ✗ FAILED: ConVar 'rage_survivor_melee_saferoom_enabled' not found");
		allPassed = false;
	}
	else
	{
		PrintToServer("[Melee Test] ✓ PASSED: ConVar 'rage_survivor_melee_saferoom_enabled' exists");
	}
	
	// Test 3: Check naming conventions
	char cvarNames[][] = {
		"rage_survivor_melee_saferoom_enabled",
		"rage_survivor_melee_saferoom_random",
		"rage_survivor_melee_saferoom_amount",
		"rage_survivor_melee_saferoom_baseball_bat"
	};
	
	for (int i = 0; i < sizeof(cvarNames); i++)
	{
		cvar = FindConVar(cvarNames[i]);
		if (cvar == null)
		{
			PrintToServer("[Melee Test] ✗ FAILED: ConVar '%s' not found", cvarNames[i]);
			allPassed = false;
		}
		else
		{
			PrintToServer("[Melee Test] ✓ PASSED: ConVar '%s' exists", cvarNames[i]);
		}
	}
	
	if (allPassed)
	{
		PrintToServer("[Melee Test] ✓ All tests passed!");
	}
	else
	{
		PrintToServer("[Melee Test] ✗ Some tests failed");
	}
	
	return Plugin_Handled;
}

public Action Command_TestMeleeModels(int args)
{
	PrintToServer("[Melee Test] Testing melee model availability...");
	
	char models[][] = {
		"models/weapons/melee/v_bat.mdl",
		"models/weapons/melee/v_cricket_bat.mdl",
		"models/weapons/melee/v_crowbar.mdl",
		"models/weapons/melee/v_electric_guitar.mdl",
		"models/weapons/melee/v_fireaxe.mdl",
		"models/weapons/melee/v_frying_pan.mdl",
		"models/weapons/melee/v_golfclub.mdl",
		"models/weapons/melee/v_katana.mdl",
		"models/weapons/melee/v_pitchfork.mdl",
		"models/weapons/melee/v_shovel.mdl",
		"models/weapons/melee/v_machete.mdl",
		"models/weapons/melee/v_tonfa.mdl",
		"models/weapons/melee/w_bat.mdl",
		"models/weapons/melee/w_cricket_bat.mdl",
		"models/weapons/melee/w_crowbar.mdl",
		"models/weapons/melee/w_electric_guitar.mdl",
		"models/weapons/melee/w_fireaxe.mdl",
		"models/weapons/melee/w_frying_pan.mdl",
		"models/weapons/melee/w_golfclub.mdl",
		"models/weapons/melee/w_katana.mdl",
		"models/weapons/melee/w_pitchfork.mdl",
		"models/weapons/melee/w_shovel.mdl",
		"models/weapons/melee/w_machete.mdl",
		"models/weapons/melee/w_tonfa.mdl"
	};
	
	bool allFound = true;
	int foundCount = 0;
	
	for (int i = 0; i < sizeof(models); i++)
	{
		if (IsModelPrecached(models[i]))
		{
			foundCount++;
			PrintToServer("[Melee Test] ✓ Model precached: %s", models[i]);
		}
		else
		{
			PrintToServer("[Melee Test] ✗ Model not precached: %s", models[i]);
			allFound = false;
		}
	}
	
	PrintToServer("[Melee Test] Found %d/%d models precached", foundCount, sizeof(models));
	
	if (allFound)
	{
		PrintToServer("[Melee Test] ✓ All models are precached!");
	}
	else
	{
		PrintToServer("[Melee Test] ⚠ Some models are not precached (this may be normal if plugin hasn't run OnMapStart yet)");
	}
	
	return Plugin_Handled;
}

public Action Command_TestMeleeConfig(int args)
{
	PrintToServer("[Melee Test] Testing melee configuration...");
	
	// Check if config file exists
	char configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/rage_survivor_melee_saferoom.cfg");
	
	if (FileExists(configPath))
	{
		PrintToServer("[Melee Test] ✓ Config file exists: %s", configPath);
	}
	else
	{
		PrintToServer("[Melee Test] ⚠ Config file does not exist (will be created on first run): %s", configPath);
	}
	
	// Test ConVar values
	ConVar cvar = FindConVar("rage_survivor_melee_saferoom_enabled");
	if (cvar != null)
	{
		bool enabled = cvar.BoolValue;
		PrintToServer("[Melee Test] Plugin enabled: %s", enabled ? "Yes" : "No");
	}
	
	cvar = FindConVar("rage_survivor_melee_saferoom_random");
	if (cvar != null)
	{
		bool random = cvar.BoolValue;
		PrintToServer("[Melee Test] Random mode: %s", random ? "Enabled" : "Disabled");
	}
	
	cvar = FindConVar("rage_survivor_melee_saferoom_amount");
	if (cvar != null)
	{
		int amount = cvar.IntValue;
		PrintToServer("[Melee Test] Random amount: %d", amount);
	}
	
	PrintToServer("[Melee Test] Configuration test complete");
	
	return Plugin_Handled;
}

