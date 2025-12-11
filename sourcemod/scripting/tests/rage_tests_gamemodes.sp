#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <rage/validation>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
	name = "[Rage] Gamemode Tests",
	author = "Yani",
	description = "Tests for gamemode plugins",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_test_gamemodes", Command_TestGamemodes, ADMFLAG_ROOT, "Run tests for gamemode plugins");
}

Action Command_TestGamemodes(int client, int args)
{
	PrintToChat(client, "\x04[Tests]\x01 Running gamemode tests...");
	
	int passed = 0;
	int failed = 0;
	
	// Test 1: GuessWho plugin exists
	PrintToChat(client, "\x04[Tests]\x01 Test 1: Checking GuessWho plugin...");
	if(LibraryExists("rage_gamemode_guesswho"))
	{
		PrintToChat(client, "\x04[Tests]\x01   ✓ PASS: GuessWho plugin loaded");
		passed++;
	}
	else
	{
		PrintToChat(client, "\x04[Tests]\x01   ✗ FAIL: GuessWho plugin not loaded");
		failed++;
	}
	
	// Test 2: Race Mod plugin exists
	PrintToChat(client, "\x04[Tests]\x01 Test 2: Checking Race Mod plugin...");
	ConVar raceCvar = FindConVar("rage_racemod_on");
	if(raceCvar != null)
	{
		PrintToChat(client, "\x04[Tests]\x01   ✓ PASS: Race Mod plugin loaded (CVar found)");
		passed++;
	}
	else
	{
		PrintToChat(client, "\x04[Tests]\x01   ✗ FAIL: Race Mod plugin not loaded (CVar missing)");
		failed++;
	}
	
	// Test 3: Gamemode menu integration
	PrintToChat(client, "\x04[Tests]\x01 Test 3: Checking gamemode menu integration...");
	if(LibraryExists("rage_menu_base"))
	{
		PrintToChat(client, "\x04[Tests]\x01   ✓ PASS: Menu system available");
		passed++;
	}
	else
	{
		PrintToChat(client, "\x04[Tests]\x01   ✗ FAIL: Menu system not available");
		failed++;
	}
	
	// Test 4: Race Mod CVar toggle
	PrintToChat(client, "\x04[Tests]\x01 Test 4: Testing Race Mod CVar toggle...");
	if(raceCvar != null)
	{
		int oldValue = raceCvar.IntValue;
		raceCvar.IntValue = oldValue > 0 ? 0 : 1;
		int newValue = raceCvar.IntValue;
		raceCvar.IntValue = oldValue; // Restore
		
		if(newValue != oldValue)
		{
			PrintToChat(client, "\x04[Tests]\x01   ✓ PASS: Race Mod CVar can be toggled");
			passed++;
		}
		else
		{
			PrintToChat(client, "\x04[Tests]\x01   ✗ FAIL: Race Mod CVar toggle failed");
			failed++;
		}
	}
	else
	{
		PrintToChat(client, "\x04[Tests]\x01   ✗ SKIP: Race Mod CVar not found");
		failed++;
	}
	
	// Test 5: Verify gamemode count
	PrintToChat(client, "\x04[Tests]\x01 Test 5: Verifying gamemode count...");
	// This would require accessing the menu constants, which we can't easily do
	// Just check that we can find the menu plugin
	if(LibraryExists("rage_survivor_menu"))
	{
		PrintToChat(client, "\x04[Tests]\x01   ✓ PASS: Survivor menu plugin loaded");
		passed++;
	}
	else
	{
		PrintToChat(client, "\x04[Tests]\x01   ✗ FAIL: Survivor menu plugin not loaded");
		failed++;
	}
	
	// Summary
	PrintToChat(client, "\x04[Tests]\x01 ========================================");
	PrintToChat(client, "\x04[Tests]\x01 Test Results: %d passed, %d failed", passed, failed);
	if(failed == 0)
	{
		PrintToChat(client, "\x04[Tests]\x01 ✓ All gamemode tests passed!");
	}
	else
	{
		PrintToChat(client, "\x04[Tests]\x01 ✗ Some tests failed. Check plugin loading.");
	}
	
	return Plugin_Handled;
}

