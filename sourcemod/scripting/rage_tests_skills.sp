#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <rage/skills>
#include <rage/validation>

// Stub implementations for forwards (tests don't need real functionality)
// Note: OnSpecialSkillUsed and OnCustomCommand are defined as forwards in RageCore.inc
// We just need to implement them, not redeclare them
public int OnSpecialSkillUsed(int client, int skill, int type) { return 0; }
public int OnCustomCommand(char[] name, int client, int param, int param2) { return 0; }

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Rage Skills Tests"

public Plugin myinfo =
{
    name = "[RAGE] Skills System Tests",
    author = "Yani",
    description = "Comprehensive tests for RAGE skill plugins",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_cvTestEnabled;

public void OnPluginStart()
{
    g_cvTestEnabled = CreateConVar("rage_tests_enabled", "1", "Enable/disable skill system tests", FCVAR_NONE, true, 0.0, true, 1.0);
    
    RegAdminCmd("sm_test_deadsight", Command_TestDeadsight, ADMFLAG_ROOT, "Test deadsight (extended sight) functionality");
    RegAdminCmd("sm_test_deadringer", Command_TestDeadringer, ADMFLAG_ROOT, "Test dead ringer functionality");
    RegAdminCmd("sm_test_healingorb", Command_TestHealingOrb, ADMFLAG_ROOT, "Test healing orb functionality");
    RegAdminCmd("sm_test_grenades", Command_TestGrenades, ADMFLAG_ROOT, "Test grenades functionality");
    RegAdminCmd("sm_test_missile", Command_TestMissile, ADMFLAG_ROOT, "Test missile deployment functionality");
    RegAdminCmd("sm_test_all_skills", Command_TestAllSkills, ADMFLAG_ROOT, "Run all skill tests");
}

public Action Command_TestDeadsight(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled. Set rage_tests_enabled to 1.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] Testing Deadsight (Extended Sight)...");
    
    // Test 1: Check if plugin is loaded
    bool pluginLoaded = LibraryExists("extended_sight");
    ReplyToCommand(client, "[Tests] Deadsight Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Extended sight plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Check if skill is registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "extended_sight", false);
    ReplyToCommand(client, "[Tests] Has Extended Sight Skill: %s (Current: %s)", hasSkill ? "✓ PASS" : "✗ FAIL", skillName);
    
    // Test 3: Try to activate skill
    if (hasSkill)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        ReplyToCommand(client, "[Tests] Skill Activation Result: %d (1=success, 0=cooldown/fail)", result);
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] ✓ Skill activated successfully");
        }
        else
        {
            ReplyToCommand(client, "[Tests] ✗ Skill activation failed or on cooldown");
        }
    }
    
    // Test 4: Check for glow effects (if applicable)
    // This would require checking if infected are glowing, which is harder to test automatically
    
    ReplyToCommand(client, "[Tests] Deadsight tests completed.");
    return Plugin_Handled;
}

public Action Command_TestDeadringer(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] Testing Dead Ringer...");
    
    // Test 1: Check if plugin is loaded
    bool pluginLoaded = LibraryExists("rage_deadringer");
    ReplyToCommand(client, "[Tests] Dead Ringer Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Dead ringer plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Check if skill is registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "cloak", false);
    ReplyToCommand(client, "[Tests] Has Dead Ringer Skill: %s (Current: %s)", hasSkill ? "✓ PASS" : "✗ FAIL", skillName);
    
    // Test 3: Check if player is alive
    bool isAlive = IsPlayerAlive(client);
    ReplyToCommand(client, "[Tests] Player Alive: %s", isAlive ? "✓ PASS" : "✗ FAIL");
    
    if (!isAlive)
    {
        ReplyToCommand(client, "[Tests] Player must be alive to test dead ringer. Skipping activation test.");
        return Plugin_Handled;
    }
    
    // Test 4: Try to activate skill
    if (hasSkill)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        ReplyToCommand(client, "[Tests] Skill Activation Result: %d", result);
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] ✓ Skill activated successfully");
            ReplyToCommand(client, "[Tests] Note: Check visually if player is cloaked and corpse is spawned.");
        }
        else
        {
            ReplyToCommand(client, "[Tests] ✗ Skill activation failed or on cooldown");
        }
    }
    
    ReplyToCommand(client, "[Tests] Dead Ringer tests completed.");
    return Plugin_Handled;
}

public Action Command_TestHealingOrb(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] Testing Healing Orb...");
    
    // Test 1: Check if plugin is loaded
    bool pluginLoaded = LibraryExists("rage_healingorb");
    ReplyToCommand(client, "[Tests] Healing Orb Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Healing orb plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Check if skill is registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "HealingOrb", false);
    ReplyToCommand(client, "[Tests] Has Healing Orb Skill: %s (Current: %s)", hasSkill ? "✓ PASS" : "✗ FAIL", skillName);
    
    // Test 3: Check if player is alive
    bool isAlive = IsPlayerAlive(client);
    ReplyToCommand(client, "[Tests] Player Alive: %s", isAlive ? "✓ PASS" : "✗ FAIL");
    
    if (!isAlive)
    {
        ReplyToCommand(client, "[Tests] Player must be alive to test healing orb. Skipping activation test.");
        return Plugin_Handled;
    }
    
    // Test 4: Get current health
    int currentHealth = GetClientHealth(client);
    int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    ReplyToCommand(client, "[Tests] Current Health: %d/%d", currentHealth, maxHealth);
    
    // Test 5: Try to activate skill
    if (hasSkill)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        ReplyToCommand(client, "[Tests] Skill Activation Result: %d", result);
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] ✓ Skill activated successfully");
            ReplyToCommand(client, "[Tests] Note: Check visually if healing orb spawned and heals nearby players.");
            
            // Wait a bit and check health
            CreateTimer(2.0, Timer_CheckHealingOrbHealth, GetClientUserId(client));
        }
        else
        {
            ReplyToCommand(client, "[Tests] ✗ Skill activation failed or on cooldown");
        }
    }
    
    ReplyToCommand(client, "[Tests] Healing Orb tests completed.");
    return Plugin_Handled;
}

public Action Timer_CheckHealingOrbHealth(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return Plugin_Stop;
    }
    
    int newHealth = GetClientHealth(client);
    ReplyToCommand(client, "[Tests] Health after 2 seconds: %d (should increase if orb is working)", newHealth);
    return Plugin_Stop;
}

public Action Command_TestGrenades(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] Testing Grenades...");
    
    // Test 1: Check if plugin is loaded
    bool pluginLoaded = LibraryExists("rage_grenades");
    ReplyToCommand(client, "[Tests] Grenades Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Grenades plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Check if player has grenade weapon
    int grenadeSlot = GetPlayerWeaponSlot(client, 2); // Grenade slot
    bool hasGrenade = (grenadeSlot > MaxClients && IsValidEntity(grenadeSlot));
    ReplyToCommand(client, "[Tests] Has Grenade Weapon: %s (Entity: %d)", hasGrenade ? "✓ PASS" : "✗ FAIL", grenadeSlot);
    
    if (!hasGrenade)
    {
        ReplyToCommand(client, "[Tests] Player needs a grenade weapon. Give one with: give pipe_bomb");
        return Plugin_Handled;
    }
    
    // Test 3: Check if skill is registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Grenades", false);
    ReplyToCommand(client, "[Tests] Has Grenades Skill: %s (Current: %s)", hasSkill ? "✓ PASS" : "✗ FAIL", skillName);
    
    // Test 4: Try to open grenade menu
    if (hasSkill)
    {
        FakeClientCommand(client, "sm_grenade");
        ReplyToCommand(client, "[Tests] ✓ Grenade menu command sent");
        ReplyToCommand(client, "[Tests] Note: Check if grenade selection menu appears.");
    }
    
    // Test 5: Check grenade type persistence
    // This would require checking the cookie/preference system
    
    ReplyToCommand(client, "[Tests] Grenades tests completed.");
    return Plugin_Handled;
}

public Action Command_TestMissile(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] Testing Missile Deployment...");
    
    // Test 1: Check if plugin is loaded
    bool pluginLoaded = LibraryExists("rage_missile");
    ReplyToCommand(client, "[Tests] Missile Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Missile plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Check if player is alive
    bool isAlive = IsPlayerAlive(client);
    ReplyToCommand(client, "[Tests] Player Alive: %s", isAlive ? "✓ PASS" : "✗ FAIL");
    
    if (!isAlive)
    {
        ReplyToCommand(client, "[Tests] Player must be alive to test missile. Skipping activation test.");
        return Plugin_Handled;
    }
    
    // Test 3: Check if skill is registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Missile", false);
    ReplyToCommand(client, "[Tests] Has Missile Skill: %s (Current: %s)", hasSkill ? "✓ PASS" : "✗ FAIL", skillName);
    
    // Test 4: Test dummy missile (type 1)
    if (hasSkill)
    {
        ReplyToCommand(client, "[Tests] Testing Dummy Missile (type 1)...");
        int result = OnCustomCommand("Missile", client, 0, 1);
        ReplyToCommand(client, "[Tests] Dummy Missile Result: %d (1=success)", result);
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] ✓ Dummy missile launched successfully");
        }
        else
        {
            ReplyToCommand(client, "[Tests] ✗ Dummy missile launch failed");
        }
    }
    
    // Test 5: Test homing missile (type 2)
    if (hasSkill)
    {
        CreateTimer(2.0, Timer_TestHomingMissile, GetClientUserId(client));
    }
    
    ReplyToCommand(client, "[Tests] Missile tests completed.");
    return Plugin_Handled;
}

public Action Timer_TestHomingMissile(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return Plugin_Stop;
    }
    
    ReplyToCommand(client, "[Tests] Testing Homing Missile (type 2)...");
    int result = OnCustomCommand("Missile", client, 0, 2);
    ReplyToCommand(client, "[Tests] Homing Missile Result: %d (1=success)", result);
    if (result == 1)
    {
        ReplyToCommand(client, "[Tests] ✓ Homing missile launched successfully");
        ReplyToCommand(client, "[Tests] Note: Check if missile tracks infected targets.");
    }
    else
    {
        ReplyToCommand(client, "[Tests] ✗ Homing missile launch failed");
    }
    return Plugin_Stop;
}

public Action Command_TestAllSkills(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Running All Skill Tests...");
    ReplyToCommand(client, "[Tests] ========================================");
    
    CreateTimer(0.5, Timer_RunTest, GetClientUserId(client) | (1 << 16)); // Deadsight
    CreateTimer(1.0, Timer_RunTest, GetClientUserId(client) | (2 << 16)); // Dead Ringer
    CreateTimer(1.5, Timer_RunTest, GetClientUserId(client) | (3 << 16)); // Healing Orb
    CreateTimer(2.0, Timer_RunTest, GetClientUserId(client) | (4 << 16)); // Grenades
    CreateTimer(2.5, Timer_RunTest, GetClientUserId(client) | (5 << 16)); // Missile
    
    ReplyToCommand(client, "[Tests] All tests scheduled. Results will appear over the next few seconds.");
    return Plugin_Handled;
}

public Action Timer_RunTest(Handle timer, int data)
{
    int client = GetClientOfUserId(data & 0xFFFF);
    int testType = (data >> 16) & 0xFF;
    
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    switch (testType)
    {
        case 1: Command_TestDeadsight(client, 0);
        case 2: Command_TestDeadringer(client, 0);
        case 3: Command_TestHealingOrb(client, 0);
        case 4: Command_TestGrenades(client, 0);
        case 5: Command_TestMissile(client, 0);
    }
    
    return Plugin_Stop;
}

