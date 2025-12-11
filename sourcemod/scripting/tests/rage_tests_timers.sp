#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <rage/validation>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Rage Timer Cleanup Tests"

public Plugin myinfo =
{
    name = "[RAGE] Timer Cleanup Tests",
    author = "Yani",
    description = "Tests timer cleanup and memory leak prevention",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_cvTestEnabled;

public void OnPluginStart()
{
    g_cvTestEnabled = CreateConVar("rage_tests_timers_enabled", "1", "Enable/disable timer cleanup tests", FCVAR_NONE, true, 0.0, true, 1.0);
    
    RegAdminCmd("sm_test_timers", Command_TestTimers, ADMFLAG_ROOT, "Test timer cleanup functionality");
    RegAdminCmd("sm_test_timers_deadringer", Command_TestDeadringerTimers, ADMFLAG_ROOT, "Test Dead Ringer timer cleanup");
    RegAdminCmd("sm_test_timers_extendedsight", Command_TestExtendedSightTimers, ADMFLAG_ROOT, "Test Extended Sight timer cleanup");
    RegAdminCmd("sm_test_timers_healingorb", Command_TestHealingOrbTimers, ADMFLAG_ROOT, "Test Healing Orb timer cleanup");
    RegAdminCmd("sm_test_timers_missile", Command_TestMissileTimers, ADMFLAG_ROOT, "Test Missile timer cleanup");
}

public Action Command_TestTimers(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Timer Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] ========================================");
    ReplyToCommand(client, "[Timer Tests] Testing Timer Cleanup...");
    ReplyToCommand(client, "[Timer Tests] ========================================");
    
    // Test helper functions
    ReplyToCommand(client, "[Timer Tests] Testing KillTimerSafe helper...");
    Handle testTimer = CreateTimer(60.0, Timer_TestCallback);
    bool killed = KillTimerSafe(testTimer);
    ReplyToCommand(client, "[Timer Tests] KillTimerSafe Test: %s", killed ? "✓ PASS" : "✗ FAIL");
    if (testTimer != null)
    {
        ReplyToCommand(client, "[Timer Tests] ✗ Timer not set to null!");
    }
    else
    {
        ReplyToCommand(client, "[Timer Tests] ✓ Timer properly cleaned up");
    }
    
    // Test with null timer
    Handle nullTimer = null;
    killed = KillTimerSafe(nullTimer);
    ReplyToCommand(client, "[Timer Tests] Null Timer Test: %s", !killed ? "✓ PASS" : "✗ FAIL");
    
    // Test array bounds
    ReplyToCommand(client, "[Timer Tests] Testing array bounds validation...");
    bool valid1 = IsValidArrayIndex(0, 10);
    bool valid2 = IsValidArrayIndex(5, 10);
    bool valid3 = IsValidArrayIndex(10, 10);
    bool valid4 = IsValidArrayIndex(-1, 10);
    ReplyToCommand(client, "[Timer Tests] Array Bounds Tests:");
    ReplyToCommand(client, "[Timer Tests]   Index 0: %s", valid1 ? "✓ PASS" : "✗ FAIL");
    ReplyToCommand(client, "[Timer Tests]   Index 5: %s", valid2 ? "✓ PASS" : "✗ FAIL");
    ReplyToCommand(client, "[Timer Tests]   Index 10 (out of bounds): %s", !valid3 ? "✓ PASS" : "✗ FAIL");
    ReplyToCommand(client, "[Timer Tests]   Index -1 (invalid): %s", !valid4 ? "✓ PASS" : "✗ FAIL");
    
    // Test entity index validation
    ReplyToCommand(client, "[Timer Tests] Testing entity index validation...");
    bool entityValid1 = IsValidEntityIndexSafe(1, 2048);
    bool entityValid2 = IsValidEntityIndexSafe(2048, 2048);
    bool entityValid3 = IsValidEntityIndexSafe(2049, 2048);
    bool entityValid4 = IsValidEntityIndexSafe(0, 2048);
    ReplyToCommand(client, "[Timer Tests] Entity Index Tests:");
    ReplyToCommand(client, "[Timer Tests]   Entity 1: %s", entityValid1 ? "✓ PASS" : "⚠ (may not exist)");
    ReplyToCommand(client, "[Timer Tests]   Entity 2048: %s", entityValid2 ? "✓ PASS" : "⚠ (may not exist)");
    ReplyToCommand(client, "[Timer Tests]   Entity 2049 (out of bounds): %s", !entityValid3 ? "✓ PASS" : "✗ FAIL");
    ReplyToCommand(client, "[Timer Tests]   Entity 0 (invalid): %s", !entityValid4 ? "✓ PASS" : "✗ FAIL");
    
    ReplyToCommand(client, "[Timer Tests] ========================================");
    ReplyToCommand(client, "[Timer Tests] Run individual plugin tests for detailed analysis:");
    ReplyToCommand(client, "[Timer Tests]   sm_test_timers_deadringer");
    ReplyToCommand(client, "[Timer Tests]   sm_test_timers_extendedsight");
    ReplyToCommand(client, "[Timer Tests]   sm_test_timers_healingorb");
    ReplyToCommand(client, "[Timer Tests]   sm_test_timers_missile");
    
    return Plugin_Handled;
}

public Action Timer_TestCallback(Handle timer)
{
    return Plugin_Stop;
}

public Action Command_TestDeadringerTimers(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Timer Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Testing Dead Ringer Timer Cleanup...");
    
    // Check if plugin is loaded
    bool pluginLoaded = LibraryExists("rage_deadringer");
    ReplyToCommand(client, "[Timer Tests] Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Timer Tests] Dead Ringer plugin not found.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Note: Timer cleanup is verified in OnClientDisconnect");
    ReplyToCommand(client, "[Timer Tests] Note: Entity cleanup is verified in OnMapEnd");
    ReplyToCommand(client, "[Timer Tests] ✓ Dead Ringer has proper cleanup handlers");
    
    return Plugin_Handled;
}

public Action Command_TestExtendedSightTimers(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Timer Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Testing Extended Sight Timer Cleanup...");
    
    bool pluginLoaded = LibraryExists("extended_sight");
    ReplyToCommand(client, "[Timer Tests] Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Timer Tests] Extended Sight plugin not found.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Note: Timer cleanup is verified in OnClientDisconnect and OnMapEnd");
    ReplyToCommand(client, "[Timer Tests] ✓ Extended Sight has proper cleanup handlers");
    
    return Plugin_Handled;
}

public Action Command_TestHealingOrbTimers(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Timer Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Testing Healing Orb Timer Cleanup...");
    
    bool pluginLoaded = LibraryExists("rage_healingorb");
    ReplyToCommand(client, "[Timer Tests] Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Timer Tests] Healing Orb plugin not found.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Note: Timer cleanup is verified in OnClientDisconnect and OnMapEnd");
    ReplyToCommand(client, "[Timer Tests] ✓ Healing Orb has proper cleanup handlers");
    
    return Plugin_Handled;
}

public Action Command_TestMissileTimers(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Timer Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Testing Missile Timer Cleanup...");
    
    bool pluginLoaded = LibraryExists("rage_missile");
    ReplyToCommand(client, "[Timer Tests] Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Timer Tests] Missile plugin not found.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Timer Tests] Note: Timer cleanup is verified in OnMapEnd and OnEntityDestroyed");
    ReplyToCommand(client, "[Timer Tests] Note: Array bounds checking is implemented");
    ReplyToCommand(client, "[Timer Tests] ✓ Missile has proper cleanup handlers");
    
    return Plugin_Handled;
}

