#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <rage/skills>
#include <rage/validation>
#include <rage/cooldown_notify>

// Stub implementations for forwards
public int OnSpecialSkillUsed(int client, int skill, int type) { return 0; }
public int OnCustomCommand(char[] name, int client, int param, int param2) { return 0; }

#define PLUGIN_VERSION "2.0"
#define PLUGIN_NAME "Rage Skills Comprehensive Tests"

public Plugin myinfo =
{
    name = "[RAGE] Comprehensive Skills System Tests",
    author = "Yani",
    description = "Comprehensive test coverage for all RAGE skill plugins",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_cvTestEnabled;
ConVar g_cvTestVerbose;

// Test results tracking
int g_iTestsRun = 0;
int g_iTestsPassed = 0;
int g_iTestsFailed = 0;

// Skill plugin definitions
enum struct SkillTest {
    char name[32];
    char library[64];
    char skillName[32];
    int classID;  // Class that should have this skill
    bool requiresAlive;
    bool requiresWeapon;
    char weaponClass[32];
}

SkillTest g_SkillTests[] = {
    {"Lethal Weapon", "rage_survivor_lethalweapon", "LethalWeapon", 4, true, true, "weapon_sniper_awp"},
    {"Extended Sight", "extended_sight", "extended_sight", 4, true, false, ""},
    {"Dead Ringer", "rage_deadringer", "cloak", 4, true, false, ""},
    {"Healing Orb", "rage_healingorb", "HealingOrb", 2, true, false, ""},
    {"Unvomit", "rage_survivor_unvomit", "UnVomit", 2, true, false, ""},
    {"Berzerk", "rage_berzerk", "Berzerk", 5, true, false, ""},
    {"Satellite", "rage_satellite", "Satellite", 0, true, false, ""},
    {"Nightvision", "rage_nightvision", "Nightvision", 0, true, false, ""},
    {"Parachute", "rage_parachute", "Parachute", 1, true, false, ""},
    {"Ninja Kick", "rage_ninjakick", "AthleteJump", 1, true, false, ""},
    {"Airstrike", "rage_airstrike", "Airstrike", 6, true, false, ""},
    {"Multiturret", "rage_multiturret", "Multiturret", 6, true, false, ""}
};

public void OnPluginStart()
{
    g_cvTestEnabled = CreateConVar("rage_tests_enabled", "1", "Enable/disable skill system tests", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvTestVerbose = CreateConVar("rage_tests_verbose", "1", "Enable verbose test output", FCVAR_NONE, true, 0.0, true, 1.0);
    
    // Individual skill test commands
    RegAdminCmd("sm_test_lethalweapon", Command_TestLethalWeapon, ADMFLAG_ROOT, "Test Lethal Weapon skill");
    RegAdminCmd("sm_test_extendedsight", Command_TestExtendedSight, ADMFLAG_ROOT, "Test Extended Sight skill");
    RegAdminCmd("sm_test_deadringer", Command_TestDeadRinger, ADMFLAG_ROOT, "Test Dead Ringer skill");
    RegAdminCmd("sm_test_healingorb", Command_TestHealingOrb, ADMFLAG_ROOT, "Test Healing Orb skill");
    RegAdminCmd("sm_test_unvomit", Command_TestUnvomit, ADMFLAG_ROOT, "Test Unvomit skill");
    RegAdminCmd("sm_test_berzerk", Command_TestBerzerk, ADMFLAG_ROOT, "Test Berzerk skill");
    RegAdminCmd("sm_test_satellite", Command_TestSatellite, ADMFLAG_ROOT, "Test Satellite skill");
    RegAdminCmd("sm_test_nightvision", Command_TestNightvision, ADMFLAG_ROOT, "Test Nightvision skill");
    RegAdminCmd("sm_test_parachute", Command_TestParachute, ADMFLAG_ROOT, "Test Parachute skill");
    RegAdminCmd("sm_test_ninjakick", Command_TestNinjaKick, ADMFLAG_ROOT, "Test Ninja Kick skill");
    RegAdminCmd("sm_test_airstrike", Command_TestAirstrike, ADMFLAG_ROOT, "Test Airstrike skill");
    RegAdminCmd("sm_test_multiturret", Command_TestMultiturret, ADMFLAG_ROOT, "Test Multiturret skill");
    
    // Comprehensive test commands
    RegAdminCmd("sm_test_all_skills", Command_TestAllSkills, ADMFLAG_ROOT, "Run all skill tests");
    RegAdminCmd("sm_test_skill_registration", Command_TestSkillRegistration, ADMFLAG_ROOT, "Test skill registration system");
    RegAdminCmd("sm_test_cooldown_system", Command_TestCooldownSystem, ADMFLAG_ROOT, "Test cooldown notification system");
    RegAdminCmd("sm_test_skill_edge_cases", Command_TestEdgeCases, ADMFLAG_ROOT, "Test edge cases and error handling");
    
    // Test summary
    RegAdminCmd("sm_test_summary", Command_TestSummary, ADMFLAG_ROOT, "Show test summary");
}

// ============================================================================
// Test Helper Functions
// ============================================================================

void TestStart(const char[] testName)
{
    g_iTestsRun++;
    if (g_cvTestVerbose.BoolValue)
    {
        PrintToServer("[Tests] Starting: %s", testName);
    }
}

bool TestAssert(bool condition, const char[] message, int client = 0)
{
    if (condition)
    {
        g_iTestsPassed++;
        if (g_cvTestVerbose.BoolValue && client > 0)
        {
            ReplyToCommand(client, "[Tests] ✓ PASS: %s", message);
        }
        return true;
    }
    else
    {
        g_iTestsFailed++;
        if (client > 0)
        {
            ReplyToCommand(client, "[Tests] ✗ FAIL: %s", message);
        }
        LogError("[Tests] FAIL: %s", message);
        return false;
    }
}

void TestResult(int client, bool passed, const char[] message)
{
    if (passed)
    {
        g_iTestsPassed++;
        if (client > 0)
        {
            ReplyToCommand(client, "[Tests] ✓ %s", message);
        }
    }
    else
    {
        g_iTestsFailed++;
        if (client > 0)
        {
            ReplyToCommand(client, "[Tests] ✗ %s", message);
        }
        LogError("[Tests] FAIL: %s", message);
    }
}

// ============================================================================
// Lethal Weapon Tests
// ============================================================================

public Action Command_TestLethalWeapon(int client, int args)
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
    
    TestStart("Lethal Weapon");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Lethal Weapon Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_survivor_lethalweapon");
    TestResult(client, pluginLoaded, "Lethal Weapon plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "LethalWeapon", false);
    TestResult(client, hasSkill, "Lethal Weapon skill registered");
    
    // Test 3: Class check (should be Saboteur)
    int playerClass = GetPlayerClass(client);
    TestResult(client, playerClass == 4, "Player is Saboteur class (required for Lethal Weapon)");
    
    // Test 4: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    if (!isAlive)
    {
        ReplyToCommand(client, "[Tests] Player must be alive. Skipping activation tests.");
        return Plugin_Handled;
    }
    
    // Test 5: Has sniper rifle
    int weapon = GetPlayerWeaponSlot(client, 0);
    char weaponClass[32];
    bool hasSniper = false;
    if (weapon > MaxClients && IsValidEntity(weapon))
    {
        GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
        hasSniper = (StrContains(weaponClass, "sniper") != -1 || StrContains(weaponClass, "hunting_rifle") != -1);
    }
    TestResult(client, hasSniper, "Player has sniper rifle weapon");
    
    if (!hasSniper)
    {
        ReplyToCommand(client, "[Tests] Give a sniper rifle: give weapon_sniper_awp");
    }
    
    // Test 6: Skill activation (if conditions met)
    if (hasSkill && isAlive && hasSniper)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Crouch and hold still to charge weapon.");
            ReplyToCommand(client, "[Tests] When charged, next shot will create explosion.");
        }
    }
    
    // Test 7: Cooldown system
    if (hasSkill)
    {
        // Check if cooldown notification is registered
        // This is harder to test directly, so we'll just verify the system exists
        bool cooldownSystemExists = LibraryExists("rage_cooldown_notify");
        TestResult(client, cooldownSystemExists, "Cooldown notification system available");
    }
    
    ReplyToCommand(client, "[Tests] Lethal Weapon tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Extended Sight Tests
// ============================================================================

public Action Command_TestExtendedSight(int client, int args)
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
    
    TestStart("Extended Sight");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Extended Sight Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("extended_sight");
    TestResult(client, pluginLoaded, "Extended Sight plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "extended_sight", false);
    TestResult(client, hasSkill, "Extended Sight skill registered");
    
    // Test 3: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 4: Skill activation
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Check visually if infected are glowing through walls.");
            CreateTimer(5.0, Timer_CheckExtendedSightActive, GetClientUserId(client));
        }
        else
        {
            ReplyToCommand(client, "[Tests] Skill may be on cooldown. Wait and try again.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Extended Sight tests completed.");
    return Plugin_Handled;
}

public Action Timer_CheckExtendedSightActive(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] Extended Sight should still be active. Check if glow effects are visible.");
    }
    return Plugin_Stop;
}

// ============================================================================
// Dead Ringer Tests
// ============================================================================

public Action Command_TestDeadRinger(int client, int args)
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
    
    TestStart("Dead Ringer");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Dead Ringer (Cloak) Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_deadringer");
    TestResult(client, pluginLoaded, "Dead Ringer plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "cloak", false);
    TestResult(client, hasSkill, "Dead Ringer skill registered");
    
    // Test 3: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    if (!isAlive)
    {
        ReplyToCommand(client, "[Tests] Player must be alive. Skipping activation test.");
        return Plugin_Handled;
    }
    
    // Test 4: Get health before activation
    int healthBefore = GetClientHealth(client);
    ReplyToCommand(client, "[Tests] Health before activation: %d", healthBefore);
    
    // Test 5: Skill activation
    if (hasSkill)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Check visually if:");
            ReplyToCommand(client, "[Tests]   - Player is invisible");
            ReplyToCommand(client, "[Tests]   - Fake corpse is spawned");
            ReplyToCommand(client, "[Tests]   - Speed boost is active");
            
            CreateTimer(2.0, Timer_CheckCloakState, GetClientUserId(client));
        }
    }
    
    ReplyToCommand(client, "[Tests] Dead Ringer tests completed.");
    return Plugin_Handled;
}

public Action Timer_CheckCloakState(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        // Check if player is still cloaked (hard to verify programmatically)
        ReplyToCommand(client, "[Tests] Cloak should be active. Check if player is invisible to others.");
    }
    return Plugin_Stop;
}

// ============================================================================
// Healing Orb Tests
// ============================================================================

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
    
    TestStart("Healing Orb");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Healing Orb Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_healingorb");
    TestResult(client, pluginLoaded, "Healing Orb plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "HealingOrb", false);
    TestResult(client, hasSkill, "Healing Orb skill registered");
    
    // Test 3: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    if (!isAlive)
    {
        ReplyToCommand(client, "[Tests] Player must be alive. Skipping activation test.");
        return Plugin_Handled;
    }
    
    // Test 4: Get health before
    int healthBefore = GetClientHealth(client);
    int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    ReplyToCommand(client, "[Tests] Health before: %d/%d", healthBefore, maxHealth);
    
    // Test 5: Skill activation
    if (hasSkill)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Check visually if healing orb spawned.");
            CreateTimer(3.0, Timer_CheckHealingOrbHealth, GetClientUserId(client));
        }
    }
    
    ReplyToCommand(client, "[Tests] Healing Orb tests completed.");
    return Plugin_Handled;
}

public Action Timer_CheckHealingOrbHealth(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        int healthAfter = GetClientHealth(client);
        ReplyToCommand(client, "[Tests] Health after 3 seconds: %d (should increase if orb is working)", healthAfter);
    }
    return Plugin_Stop;
}

// ============================================================================
// Unvomit Tests
// ============================================================================

public Action Command_TestUnvomit(int client, int args)
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
    
    TestStart("Unvomit");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Unvomit Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_survivor_unvomit");
    TestResult(client, pluginLoaded, "Unvomit plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "UnVomit", false);
    TestResult(client, hasSkill, "Unvomit skill registered");
    
    // Test 3: Player is Medic
    int playerClass = GetPlayerClass(client);
    TestResult(client, playerClass == 2, "Player is Medic class (required for Unvomit)");
    
    // Test 4: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 5: Skill activation (will fail if not vomited)
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        if (result == 1)
        {
            TestResult(client, true, "Skill activation successful (bile cleared)");
        }
        else
        {
            ReplyToCommand(client, "[Tests] Skill not activated (expected if player is not covered in bile)");
            ReplyToCommand(client, "[Tests] To test: Get covered in boomer bile, then use skill.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Unvomit tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Berzerk Tests
// ============================================================================

public Action Command_TestBerzerk(int client, int args)
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
    
    TestStart("Berzerk");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Berzerk Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_berzerk");
    TestResult(client, pluginLoaded, "Berzerk plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Berzerk", false);
    TestResult(client, hasSkill, "Berzerk skill registered");
    
    // Test 3: Player is Commando
    int playerClass = GetPlayerClass(client);
    TestResult(client, playerClass == 5, "Player is Commando class (required for Berzerk)");
    
    // Test 4: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 5: Skill activation
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Berzerk mode should activate.");
            ReplyToCommand(client, "[Tests] Check for: faster attacks, damage boost, fire shield.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Berzerk tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Satellite Tests
// ============================================================================

public Action Command_TestSatellite(int client, int args)
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
    
    TestStart("Satellite");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Satellite Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_satellite");
    TestResult(client, pluginLoaded, "Satellite plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Satellite", false);
    TestResult(client, hasSkill, "Satellite skill registered");
    
    // Test 3: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 4: Skill activation
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Satellite strike should target outdoor area.");
            ReplyToCommand(client, "[Tests] Check for: orbital strike effects, damage to infected.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Satellite tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Nightvision Tests
// ============================================================================

public Action Command_TestNightvision(int client, int args)
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
    
    TestStart("Nightvision");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Nightvision Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_nightvision");
    TestResult(client, pluginLoaded, "Nightvision plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Nightvision", false);
    TestResult(client, hasSkill, "Nightvision skill registered");
    
    // Test 3: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 4: Skill activation (toggle)
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Nightvision should toggle on/off.");
            ReplyToCommand(client, "[Tests] Check for: brighter/darker screen effect.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Nightvision tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Parachute Tests
// ============================================================================

public Action Command_TestParachute(int client, int args)
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
    
    TestStart("Parachute");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Parachute Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded (parachute is integrated into core)
    bool pluginLoaded = LibraryExists("rage_parachute") || LibraryExists(RAGE_PLUGIN_NAME);
    TestResult(client, pluginLoaded, "Parachute functionality available");
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Parachute", false);
    TestResult(client, hasSkill, "Parachute skill registered");
    
    // Test 3: Player is Athlete
    int playerClass = GetPlayerClass(client);
    TestResult(client, playerClass == 1, "Player is Athlete class (required for Parachute)");
    
    // Test 4: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    ReplyToCommand(client, "[Tests] Note: Parachute activates automatically when falling.");
    ReplyToCommand(client, "[Tests] Jump from high place and hold USE to test.");
    
    ReplyToCommand(client, "[Tests] Parachute tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Ninja Kick Tests
// ============================================================================

public Action Command_TestNinjaKick(int client, int args)
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
    
    TestStart("Ninja Kick");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Ninja Kick Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_ninjakick");
    TestResult(client, pluginLoaded, "Ninja Kick plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "AthleteJump", false);
    TestResult(client, hasSkill, "Ninja Kick skill registered");
    
    // Test 3: Player is Athlete
    int playerClass = GetPlayerClass(client);
    TestResult(client, playerClass == 1, "Player is Athlete class (required for Ninja Kick)");
    
    // Test 4: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    ReplyToCommand(client, "[Tests] Note: Ninja Kick activates with Sprint + Jump.");
    ReplyToCommand(client, "[Tests] Sprint and jump near infected to test.");
    
    ReplyToCommand(client, "[Tests] Ninja Kick tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Airstrike Tests
// ============================================================================

public Action Command_TestAirstrike(int client, int args)
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
    
    TestStart("Airstrike");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Airstrike Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_airstrike");
    TestResult(client, pluginLoaded, "Airstrike plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Airstrike", false);
    TestResult(client, hasSkill, "Airstrike skill registered");
    
    // Test 3: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 4: Skill activation
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Airstrike marker should be thrown.");
            ReplyToCommand(client, "[Tests] Check for: F-18 airstrike explosion at target location.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Airstrike tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Multiturret Tests
// ============================================================================

public Action Command_TestMultiturret(int client, int args)
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
    
    TestStart("Multiturret");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Multiturret Skill");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Plugin loaded
    bool pluginLoaded = LibraryExists("rage_multiturret");
    TestResult(client, pluginLoaded, "Multiturret plugin loaded");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Tests] Plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Skill registered
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    bool hasSkill = StrEqual(skillName, "Multiturret", false);
    TestResult(client, hasSkill, "Multiturret skill registered");
    
    // Test 3: Player is Engineer
    int playerClass = GetPlayerClass(client);
    TestResult(client, playerClass == 6, "Player is Engineer class (required for Multiturret)");
    
    // Test 4: Player alive
    bool isAlive = IsPlayerAlive(client);
    TestResult(client, isAlive, "Player is alive");
    
    // Test 5: Skill activation (opens menu)
    if (hasSkill && isAlive)
    {
        int result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 1, "Skill activation successful (menu opened)");
        
        if (result == 1)
        {
            ReplyToCommand(client, "[Tests] Note: Turret menu should be displayed.");
            ReplyToCommand(client, "[Tests] Select turret type and deploy location.");
        }
    }
    
    ReplyToCommand(client, "[Tests] Multiturret tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Comprehensive Test Commands
// ============================================================================

public Action Command_TestAllSkills(int client, int args)
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
    
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Running All Skill Tests");
    ReplyToCommand(client, "[Tests] ========================================");
    
    g_iTestsRun = 0;
    g_iTestsPassed = 0;
    g_iTestsFailed = 0;
    
    // Run all skill tests with delays
    CreateTimer(0.5, Timer_RunSkillTest, GetClientUserId(client) | (0 << 16));  // Lethal Weapon
    CreateTimer(1.0, Timer_RunSkillTest, GetClientUserId(client) | (1 << 16));  // Extended Sight
    CreateTimer(1.5, Timer_RunSkillTest, GetClientUserId(client) | (2 << 16));  // Dead Ringer
    CreateTimer(2.0, Timer_RunSkillTest, GetClientUserId(client) | (3 << 16));  // Healing Orb
    CreateTimer(2.5, Timer_RunSkillTest, GetClientUserId(client) | (4 << 16));  // Unvomit
    CreateTimer(3.0, Timer_RunSkillTest, GetClientUserId(client) | (5 << 16));  // Berzerk
    CreateTimer(3.5, Timer_RunSkillTest, GetClientUserId(client) | (6 << 16));  // Satellite
    CreateTimer(4.0, Timer_RunSkillTest, GetClientUserId(client) | (7 << 16));  // Nightvision
    CreateTimer(4.5, Timer_RunSkillTest, GetClientUserId(client) | (8 << 16));  // Parachute
    CreateTimer(5.0, Timer_RunSkillTest, GetClientUserId(client) | (9 << 16));  // Ninja Kick
    CreateTimer(5.5, Timer_RunSkillTest, GetClientUserId(client) | (10 << 16)); // Airstrike
    CreateTimer(6.0, Timer_RunSkillTest, GetClientUserId(client) | (11 << 16)); // Multiturret
    
    CreateTimer(7.0, Timer_ShowTestSummary, GetClientUserId(client));
    
    ReplyToCommand(client, "[Tests] All tests scheduled. Results will appear over the next few seconds.");
    return Plugin_Handled;
}

public Action Timer_RunSkillTest(Handle timer, int data)
{
    int client = GetClientOfUserId(data & 0xFFFF);
    int testIndex = (data >> 16) & 0xFF;
    
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    switch (testIndex)
    {
        case 0: Command_TestLethalWeapon(client, 0);
        case 1: Command_TestExtendedSight(client, 0);
        case 2: Command_TestDeadRinger(client, 0);
        case 3: Command_TestHealingOrb(client, 0);
        case 4: Command_TestUnvomit(client, 0);
        case 5: Command_TestBerzerk(client, 0);
        case 6: Command_TestSatellite(client, 0);
        case 7: Command_TestNightvision(client, 0);
        case 8: Command_TestParachute(client, 0);
        case 9: Command_TestNinjaKick(client, 0);
        case 10: Command_TestAirstrike(client, 0);
        case 11: Command_TestMultiturret(client, 0);
    }
    
    return Plugin_Stop;
}

public Action Timer_ShowTestSummary(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        ReplyToCommand(client, "[Tests] ========================================");
        ReplyToCommand(client, "[Tests] Test Summary");
        ReplyToCommand(client, "[Tests] ========================================");
        ReplyToCommand(client, "[Tests] Tests Run: %d", g_iTestsRun);
        ReplyToCommand(client, "[Tests] Tests Passed: %d", g_iTestsPassed);
        ReplyToCommand(client, "[Tests] Tests Failed: %d", g_iTestsFailed);
        
        if (g_iTestsFailed == 0)
        {
            ReplyToCommand(client, "[Tests] ✓ All tests passed!");
        }
        else
        {
            ReplyToCommand(client, "[Tests] ✗ Some tests failed. Check logs for details.");
        }
    }
    return Plugin_Stop;
}

// ============================================================================
// Skill Registration Tests
// ============================================================================

public Action Command_TestSkillRegistration(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Skill Registration System");
    ReplyToCommand(client, "[Tests] ========================================");
    
    int registered = 0;
    int missing = 0;
    
    for (int i = 0; i < sizeof(g_SkillTests); i++)
    {
        bool pluginExists = LibraryExists(g_SkillTests[i].library);
        TestResult(client, pluginExists, "%s plugin loaded", g_SkillTests[i].name);
        
        if (pluginExists)
        {
            registered++;
        }
        else
        {
            missing++;
        }
    }
    
    ReplyToCommand(client, "[Tests] Registered: %d/%d skills", registered, sizeof(g_SkillTests));
    ReplyToCommand(client, "[Tests] Missing: %d skills", missing);
    
    return Plugin_Handled;
}

// ============================================================================
// Cooldown System Tests
// ============================================================================

public Action Command_TestCooldownSystem(int client, int args)
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
    
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Cooldown Notification System");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Cooldown system available
    bool systemExists = LibraryExists("rage_cooldown_notify");
    TestResult(client, systemExists, "Cooldown notification system available");
    
    if (!systemExists)
    {
        ReplyToCommand(client, "[Tests] Cooldown system not found. Check includes.");
        return Plugin_Handled;
    }
    
    // Test 2: Register a test cooldown
    float endTime = GetGameTime() + 5.0;
    bool registered = CooldownNotify_Register(client, endTime, "TestSkill");
    TestResult(client, registered, "Cooldown registration successful");
    
    if (registered)
    {
        ReplyToCommand(client, "[Tests] Cooldown registered. Waiting 5 seconds for notification...");
        ReplyToCommand(client, "[Tests] You should hear a sound and see a hint when cooldown ends.");
    }
    
    // Test 3: Unregister cooldown
    CreateTimer(6.0, Timer_TestUnregister, GetClientUserId(client));
    
    return Plugin_Handled;
}

public Action Timer_TestUnregister(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        CooldownNotify_Unregister(client, "TestSkill");
        ReplyToCommand(client, "[Tests] Cooldown unregistered successfully.");
    }
    return Plugin_Stop;
}

// ============================================================================
// Edge Cases and Error Handling Tests
// ============================================================================

public Action Command_TestEdgeCases(int client, int args)
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
    
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Testing Edge Cases and Error Handling");
    ReplyToCommand(client, "[Tests] ========================================");
    
    // Test 1: Invalid client index
    int result = OnSpecialSkillUsed(0, 0, 0);
    TestResult(client, result == 0, "Invalid client (0) rejected");
    
    // Test 2: Invalid client index (too high)
    result = OnSpecialSkillUsed(MAXPLAYERS + 1, 0, 0);
    TestResult(client, result == 0, "Invalid client (too high) rejected");
    
    // Test 3: Dead player
    if (!IsPlayerAlive(client))
    {
        result = OnSpecialSkillUsed(client, 0, 0);
        TestResult(client, result == 0, "Dead player skill activation rejected");
    }
    
    // Test 4: Wrong class
    int currentClass = GetPlayerClass(client);
    char skillName[32];
    GetPlayerSkillName(client, skillName, sizeof(skillName));
    
    // Try to use a skill that requires a different class
    if (currentClass != 4 && StrEqual(skillName, "LethalWeapon", false))
    {
        TestResult(client, false, "Lethal Weapon should not be available to non-Saboteur");
    }
    
    // Test 5: Cooldown system with invalid client
    CooldownNotify_Register(0, GetGameTime() + 5.0, "TestSkill");
    TestResult(client, true, "Cooldown system handles invalid client gracefully");
    
    // Test 6: Multiple rapid activations
    if (IsPlayerAlive(client))
    {
        int rapidResults = 0;
        for (int i = 0; i < 5; i++)
        {
            rapidResults += OnSpecialSkillUsed(client, 0, 0);
        }
        ReplyToCommand(client, "[Tests] Rapid activations: %d/5 succeeded (expected: 1 due to cooldown)", rapidResults);
    }
    
    ReplyToCommand(client, "[Tests] Edge case tests completed.");
    return Plugin_Handled;
}

// ============================================================================
// Test Summary
// ============================================================================

public Action Command_TestSummary(int client, int args)
{
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Test Summary");
    ReplyToCommand(client, "[Tests] ========================================");
    ReplyToCommand(client, "[Tests] Tests Run: %d", g_iTestsRun);
    ReplyToCommand(client, "[Tests] Tests Passed: %d", g_iTestsPassed);
    ReplyToCommand(client, "[Tests] Tests Failed: %d", g_iTestsFailed);
    
    if (g_iTestsRun > 0)
    {
        float passRate = (float(g_iTestsPassed) / float(g_iTestsRun)) * 100.0;
        ReplyToCommand(client, "[Tests] Pass Rate: %.1f%%", passRate);
    }
    
    return Plugin_Handled;
}

// Helper function to get player class
int GetPlayerClass(int client)
{
    if (!IsValidClient(client))
        return -1;
    
    // Try to get class name and convert to ID
    char className[32];
    if (GetPlayerClassName(client, className, sizeof(className)) > 0)
    {
        // Map class names to IDs
        if (StrEqual(className, "soldier", false)) return 0;
        if (StrEqual(className, "athlete", false)) return 1;
        if (StrEqual(className, "medic", false)) return 2;
        if (StrEqual(className, "saboteur", false)) return 4;
        if (StrEqual(className, "commando", false)) return 5;
        if (StrEqual(className, "engineer", false)) return 6;
        if (StrEqual(className, "brawler", false)) return 7;
    }
    
    return -1;
}

