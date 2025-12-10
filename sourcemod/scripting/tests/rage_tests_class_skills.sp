#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <RageCore>
#include <rage/skills>
#include <rage/validation>
#include <rage/timers>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_NAME "Rage Class Skills Tests"

// Timer delays (in seconds)
#define TIMER_DELAY_RESPAWN 0.5
#define TIMER_DELAY_CLASS_VERIFY 1.0
#define TIMER_DELAY_DEPLOYMENT 0.5
#define TIMER_DELAY_SKILLS 0.5
#define TIMER_DELAY_SKILL_NEXT 1.0
#define TIMER_DELAY_SUMMARY 0.5

// Test sequence delays for sm_test_class_all
#define TIMER_DELAY_SOLDIER 0.5
#define TIMER_DELAY_ATHLETE 3.0
#define TIMER_DELAY_MEDIC 5.5
#define TIMER_DELAY_SABOTEUR 8.0
#define TIMER_DELAY_COMMANDO 10.5
#define TIMER_DELAY_ENGINEER 13.0
#define TIMER_DELAY_BRAWLER 15.5

public Plugin myinfo =
{
    name = "[RAGE] Class Skills Comprehensive Tests",
    author = "Yani",
    description = "Comprehensive tests for class deployment menus and skills",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_cvTestEnabled;

// Track active test timers per client to prevent leaks
Handle g_hTestTimers[MAXPLAYERS+1];
bool g_bTestInProgress[MAXPLAYERS+1];

// Class skill mappings from rage_class_skills.cfg
enum struct ClassSkillConfig {
    char className[32];
    char special[64];
    char secondary[64];
    char tertiary[64];
    char deploy[64];
}

ClassSkillConfig g_ClassConfigs[8]; // MAXCLASSES = 8

// Cache for native availability check
bool g_bFindSkillIdAvailable = false;

public void OnPluginStart()
{
    g_cvTestEnabled = CreateConVar("rage_tests_class_enabled", "1", "Enable/disable class skill tests", FCVAR_NONE, true, 0.0, true, 1.0);
    
    // Check native availability once at startup
    g_bFindSkillIdAvailable = (GetFeatureStatus(FeatureType_Native, "FindSkillIdByName") == FeatureStatus_Available);
    
    // Initialize class configurations
    InitializeClassConfigs();
    
    RegAdminCmd("sm_test_class_all", Command_TestAllClasses, ADMFLAG_ROOT, "Test all classes - deployment menu and skills");
    RegAdminCmd("sm_test_class_soldier", Command_TestSoldier, ADMFLAG_ROOT, "Test Soldier class");
    RegAdminCmd("sm_test_class_athlete", Command_TestAthlete, ADMFLAG_ROOT, "Test Athlete class");
    RegAdminCmd("sm_test_class_medic", Command_TestMedic, ADMFLAG_ROOT, "Test Medic class");
    RegAdminCmd("sm_test_class_saboteur", Command_TestSaboteur, ADMFLAG_ROOT, "Test Saboteur class");
    RegAdminCmd("sm_test_class_commando", Command_TestCommando, ADMFLAG_ROOT, "Test Commando class");
    RegAdminCmd("sm_test_class_engineer", Command_TestEngineer, ADMFLAG_ROOT, "Test Engineer class");
    RegAdminCmd("sm_test_class_brawler", Command_TestBrawler, ADMFLAG_ROOT, "Test Brawler class");
}

public void OnPluginEnd()
{
    // Cleanup all active timers
    for (int i = 1; i <= MaxClients; i++)
    {
        CleanupTestTimers(i);
    }
}

public void OnMapEnd()
{
    // Cleanup all active timers on map end
    for (int i = 1; i <= MaxClients; i++)
    {
        CleanupTestTimers(i);
        g_bTestInProgress[i] = false;
    }
}

public void OnClientDisconnect(int client)
{
    // Cleanup timers when client disconnects
    CleanupTestTimers(client);
    g_bTestInProgress[client] = false;
}

void CleanupTestTimers(int client)
{
    if (client <= 0 || client > MaxClients)
        return;
    
    KillTimerSafe(g_hTestTimers[client]);
    g_hTestTimers[client] = null;
}

void InitializeClassConfigs()
{
    // Soldier
    strcopy(g_ClassConfigs[1].className, sizeof(ClassSkillConfig::className), "soldier");
    strcopy(g_ClassConfigs[1].special, sizeof(ClassSkillConfig::special), "Satellite");
    strcopy(g_ClassConfigs[1].secondary, sizeof(ClassSkillConfig::secondary), "skill:ZedTime");
    strcopy(g_ClassConfigs[1].tertiary, sizeof(ClassSkillConfig::tertiary), "skill:ChainLightning");
    strcopy(g_ClassConfigs[1].deploy, sizeof(ClassSkillConfig::deploy), "none");
    
    // Athlete
    strcopy(g_ClassConfigs[2].className, sizeof(ClassSkillConfig::className), "athlete");
    strcopy(g_ClassConfigs[2].special, sizeof(ClassSkillConfig::special), "command:Grenades:15");
    strcopy(g_ClassConfigs[2].secondary, sizeof(ClassSkillConfig::secondary), "skill:Blink");
    strcopy(g_ClassConfigs[2].tertiary, sizeof(ClassSkillConfig::tertiary), "skill:AthleteJump");
    strcopy(g_ClassConfigs[2].deploy, sizeof(ClassSkillConfig::deploy), "none");
    
    // Medic
    strcopy(g_ClassConfigs[3].className, sizeof(ClassSkillConfig::className), "medic");
    strcopy(g_ClassConfigs[3].special, sizeof(ClassSkillConfig::special), "command:Grenades:11");
    strcopy(g_ClassConfigs[3].secondary, sizeof(ClassSkillConfig::secondary), "skill:HealingOrb");
    strcopy(g_ClassConfigs[3].tertiary, sizeof(ClassSkillConfig::tertiary), "skill:UnVomit");
    strcopy(g_ClassConfigs[3].deploy, sizeof(ClassSkillConfig::deploy), "builtin:medic_supply");
    
    // Saboteur
    strcopy(g_ClassConfigs[4].className, sizeof(ClassSkillConfig::className), "saboteur");
    strcopy(g_ClassConfigs[4].special, sizeof(ClassSkillConfig::special), "skill:cloak:1");
    strcopy(g_ClassConfigs[4].secondary, sizeof(ClassSkillConfig::secondary), "skill:extended_sight");
    strcopy(g_ClassConfigs[4].tertiary, sizeof(ClassSkillConfig::tertiary), "skill:LethalWeapon");
    strcopy(g_ClassConfigs[4].deploy, sizeof(ClassSkillConfig::deploy), "builtin:saboteur_mines");
    
    // Commando
    strcopy(g_ClassConfigs[5].className, sizeof(ClassSkillConfig::className), "commando");
    strcopy(g_ClassConfigs[5].special, sizeof(ClassSkillConfig::special), "skill:Berzerk");
    strcopy(g_ClassConfigs[5].secondary, sizeof(ClassSkillConfig::secondary), "command:Missile:1");
    strcopy(g_ClassConfigs[5].tertiary, sizeof(ClassSkillConfig::tertiary), "command:Missile:2");
    strcopy(g_ClassConfigs[5].deploy, sizeof(ClassSkillConfig::deploy), "builtin:engineer_supply");
    
    // Engineer
    strcopy(g_ClassConfigs[6].className, sizeof(ClassSkillConfig::className), "engineer");
    strcopy(g_ClassConfigs[6].special, sizeof(ClassSkillConfig::special), "command:Grenades:7");
    strcopy(g_ClassConfigs[6].secondary, sizeof(ClassSkillConfig::secondary), "skill:Multiturret");
    strcopy(g_ClassConfigs[6].tertiary, sizeof(ClassSkillConfig::tertiary), "none");
    strcopy(g_ClassConfigs[6].deploy, sizeof(ClassSkillConfig::deploy), "builtin:engineer_supply");
    
    // Brawler
    strcopy(g_ClassConfigs[7].className, sizeof(ClassSkillConfig::className), "brawler");
    strcopy(g_ClassConfigs[7].special, sizeof(ClassSkillConfig::special), "none");
    strcopy(g_ClassConfigs[7].secondary, sizeof(ClassSkillConfig::secondary), "none");
    strcopy(g_ClassConfigs[7].tertiary, sizeof(ClassSkillConfig::tertiary), "none");
    strcopy(g_ClassConfigs[7].deploy, sizeof(ClassSkillConfig::deploy), "none");
}

public Action Command_TestAllClasses(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Class Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Class Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    // Prevent concurrent test runs
    if (g_bTestInProgress[client])
    {
        ReplyToCommand(client, "[Class Tests] A test is already in progress. Please wait for it to complete.");
        return Plugin_Handled;
    }
    
    g_bTestInProgress[client] = true;
    
    ReplyToCommand(client, "[Class Tests] ========================================");
    ReplyToCommand(client, "[Class Tests] Running All Class Tests...");
    ReplyToCommand(client, "[Class Tests] ========================================");
    
    // Test each class with delays - store handles for cleanup
    DataPack pack;
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(1); // Soldier
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_SOLDIER, Timer_TestClass, pack);
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(2); // Athlete
    CreateTimer(TIMER_DELAY_ATHLETE, Timer_TestClass, pack);
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(3); // Medic
    CreateTimer(TIMER_DELAY_MEDIC, Timer_TestClass, pack);
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(4); // Saboteur
    CreateTimer(TIMER_DELAY_SABOTEUR, Timer_TestClass, pack);
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(5); // Commando
    CreateTimer(TIMER_DELAY_COMMANDO, Timer_TestClass, pack);
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(6); // Engineer
    CreateTimer(TIMER_DELAY_ENGINEER, Timer_TestClass, pack);
    
    pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(7); // Brawler
    CreateTimer(TIMER_DELAY_BRAWLER, Timer_TestClass, pack);
    
    ReplyToCommand(client, "[Class Tests] All tests scheduled. Results will appear over the next few seconds.");
    return Plugin_Handled;
}

public Action Timer_TestClass(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    switch (classIndex)
    {
        case 1: Command_TestSoldier(client, 0);
        case 2: Command_TestAthlete(client, 0);
        case 3: Command_TestMedic(client, 0);
        case 4: Command_TestSaboteur(client, 0);
        case 5: Command_TestCommando(client, 0);
        case 6: Command_TestEngineer(client, 0);
        case 7: Command_TestBrawler(client, 0);
    }
    
    return Plugin_Stop;
}

public Action Command_TestSoldier(int client, int args)
{
    return TestClass(client, 1, "Soldier");
}

public Action Command_TestAthlete(int client, int args)
{
    return TestClass(client, 2, "Athlete");
}

public Action Command_TestMedic(int client, int args)
{
    return TestClass(client, 3, "Medic");
}

public Action Command_TestSaboteur(int client, int args)
{
    return TestClass(client, 4, "Saboteur");
}

public Action Command_TestCommando(int client, int args)
{
    return TestClass(client, 5, "Commando");
}

public Action Command_TestEngineer(int client, int args)
{
    return TestClass(client, 6, "Engineer");
}

public Action Command_TestBrawler(int client, int args)
{
    return TestClass(client, 7, "Brawler");
}

Action TestClass(int client, int classIndex, const char[] className)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Class Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Class Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
    {
        ReplyToCommand(client, "[Class Tests] Invalid class index: %d", classIndex);
        return Plugin_Handled;
    }
    
    // Cleanup any existing timers for this client
    CleanupTestTimers(client);
    
    // Ensure client is on survivor team
    if (GetClientTeam(client) != 2)
    {
        ChangeClientTeam(client, 2);
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        g_hTestTimers[client] = CreateTimer(TIMER_DELAY_RESPAWN, Timer_RespawnClient, pack);
        ReplyToCommand(client, "[Class Tests] Switched you to survivor team. Respawn in %.1fs...", TIMER_DELAY_RESPAWN);
    }
    
    if (!IsPlayerAlive(client))
    {
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        g_hTestTimers[client] = CreateTimer(TIMER_DELAY_RESPAWN, Timer_RespawnClient, pack);
        ReplyToCommand(client, "[Class Tests] Respawning you in %.1fs...", TIMER_DELAY_RESPAWN);
    }
    
    ReplyToCommand(client, "[Class Tests] ========================================");
    ReplyToCommand(client, "[Class Tests] Testing %s Class (Index: %d)", className, classIndex);
    ReplyToCommand(client, "[Class Tests] ========================================");
    
    // Test 1: Set class
    ReplyToCommand(client, "[Class Tests] [1/5] Setting class to %s...", className);
    FakeClientCommand(client, "sm_class_set %d", classIndex);
    
    // Wait a moment for class to be set
    DataPack verifyPack = new DataPack();
    verifyPack.WriteCell(GetClientUserId(client));
    verifyPack.WriteCell(classIndex);
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_CLASS_VERIFY, Timer_VerifyClassSet, verifyPack);
    
    return Plugin_Handled;
}

public Action Timer_RespawnClient(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    if (GetClientTeam(client) == 2 && !IsPlayerAlive(client))
    {
        int spawnPoint = FindEntityByClassname(-1, "info_player_start");
        if (spawnPoint == -1)
            spawnPoint = FindEntityByClassname(-1, "info_survivor_position");
        
        if (spawnPoint != -1 && IsValidEntity(spawnPoint))
        {
            float pos[3], ang[3];
            GetEntPropVector(spawnPoint, Prop_Send, "m_vecOrigin", pos);
            GetEntPropVector(spawnPoint, Prop_Send, "m_angRotation", ang);
            
            TeleportEntity(client, pos, ang, NULL_VECTOR);
        }
        
        SetEntProp(client, Prop_Send, "m_iHealth", 100);
        SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
    }
    
    return Plugin_Stop;
}

public Action Timer_VerifyClassSet(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
    {
        ReplyToCommand(client, "[Class Tests] Invalid class index in timer: %d", classIndex);
        return Plugin_Stop;
    }
    
    // Test 2: Verify class was set
    char currentClassName[32];
    GetPlayerClassName(client, currentClassName, sizeof(currentClassName));
    
    // Optimized class name comparison
    bool classSet = IsClassMatch(currentClassName, classIndex);
    
    ReplyToCommand(client, "[Class Tests] [2/5] Class Verification: %s (Expected: %s, Got: %s)", 
                   classSet ? "✓ PASS" : "✗ FAIL", 
                   g_ClassConfigs[classIndex].className, 
                   currentClassName);
    
    if (!classSet)
    {
        ReplyToCommand(client, "[Class Tests] Class was not set correctly. Skipping remaining tests.");
        g_bTestInProgress[client] = false;
        return Plugin_Stop;
    }
    
    // Test 3: Test deployment menu
    DataPack deployPack = new DataPack();
    deployPack.WriteCell(GetClientUserId(client));
    deployPack.WriteCell(classIndex);
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_DEPLOYMENT, Timer_TestDeploymentMenu, deployPack);
    
    return Plugin_Stop;
}

// Optimized class name matching
bool IsClassMatch(const char[] className, int classIndex)
{
    // First try exact match (case-insensitive)
    if (StrEqual(className, g_ClassConfigs[classIndex].className, false))
        return true;
    
    // Fallback: Check common class name variations
    static const char classNames[8][16] = {
        "",           // 0 - NONE
        "Soldier",    // 1
        "Athlete",    // 2
        "Medic",      // 3
        "Saboteur",   // 4
        "Commando",   // 5
        "Engineer",   // 6
        "Brawler"     // 7
    };
    
    if (classIndex >= 1 && classIndex < sizeof(classNames))
    {
        return StrEqual(className, classNames[classIndex], false);
    }
    
    return false;
}

public Action Timer_TestDeploymentMenu(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
        return Plugin_Stop;
    
    ReplyToCommand(client, "[Class Tests] [3/5] Testing Deployment Menu...");
    
    // Check if deployment is configured
    bool hasDeploy = !StrEqual(g_ClassConfigs[classIndex].deploy, "none", false);
    
    if (!hasDeploy)
    {
        ReplyToCommand(client, "[Class Tests] Deployment: ✓ PASS (No deployment configured for this class)");
    }
    else
    {
        // Try to trigger deployment menu
        ReplyToCommand(client, "[Class Tests] Attempting to open deployment menu...");
        FakeClientCommand(client, "deployment_action");
        
        ReplyToCommand(client, "[Class Tests] Deployment Menu: ✓ Command executed (verify manually in-game)");
    }
    
    // Test 4: Test skills
    DataPack skillsPack = new DataPack();
    skillsPack.WriteCell(GetClientUserId(client));
    skillsPack.WriteCell(classIndex);
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_SKILLS, Timer_TestSkills, skillsPack);
    
    return Plugin_Stop;
}

public Action Timer_TestSkills(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
        return Plugin_Stop;
    
    ReplyToCommand(client, "[Class Tests] [4/5] Testing Class Skills...");
    
    // Test Special skill
    TestSkill(client, classIndex, "Special", g_ClassConfigs[classIndex].special);
    
    // Test Secondary skill
    DataPack secondaryPack = new DataPack();
    secondaryPack.WriteCell(GetClientUserId(client));
    secondaryPack.WriteCell(classIndex);
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_SKILL_NEXT, Timer_TestSecondarySkill, secondaryPack);
    
    return Plugin_Stop;
}

public Action Timer_TestSecondarySkill(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
        return Plugin_Stop;
    
    TestSkill(client, classIndex, "Secondary", g_ClassConfigs[classIndex].secondary);
    
    // Test Tertiary skill
    DataPack tertiaryPack = new DataPack();
    tertiaryPack.WriteCell(GetClientUserId(client));
    tertiaryPack.WriteCell(classIndex);
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_SKILL_NEXT, Timer_TestTertiarySkill, tertiaryPack);
    
    return Plugin_Stop;
}

public Action Timer_TestTertiarySkill(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
        return Plugin_Stop;
    
    TestSkill(client, classIndex, "Tertiary", g_ClassConfigs[classIndex].tertiary);
    
    // Final summary
    DataPack summaryPack = new DataPack();
    summaryPack.WriteCell(GetClientUserId(client));
    summaryPack.WriteCell(classIndex);
    g_hTestTimers[client] = CreateTimer(TIMER_DELAY_SUMMARY, Timer_TestSummary, summaryPack);
    
    return Plugin_Stop;
}

void TestSkill(int client, int classIndex, const char[] skillType, const char[] skillConfig)
{
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
        return;
    
    if (StrEqual(skillConfig, "none", false))
    {
        ReplyToCommand(client, "[Class Tests] %s Skill: ✓ PASS (No skill configured)", skillType);
        return;
    }
    
    // Parse skill configuration
    char skillName[64];
    int skillParam = 0;
    
    if (StrContains(skillConfig, "skill:") == 0)
    {
        // Format: skill:Name or skill:Name:param
        char parts[3][64];
        int partCount = ExplodeString(skillConfig[6], ":", parts, sizeof(parts), sizeof(parts[]));
        strcopy(skillName, sizeof(skillName), parts[0]);
        if (partCount > 1)
        {
            skillParam = StringToInt(parts[1]);
        }
        
        // Check if skill is registered
        bool skillRegistered = IsSkillRegistered(skillName);
        
        ReplyToCommand(client, "[Class Tests] %s Skill (%s): %s", 
                       skillType, skillName, 
                       skillRegistered ? "✓ Registered" : "✗ NOT REGISTERED");
        
        if (skillRegistered)
        {
            // Get skill ID if native is available (use cached value)
            int skillId = -1;
            if (g_bFindSkillIdAvailable)
            {
                char skillNameCopy[64];
                strcopy(skillNameCopy, sizeof(skillNameCopy), skillName);
                skillId = FindSkillIdByName(skillNameCopy);
                ReplyToCommand(client, "[Class Tests]   Skill ID: %d, Param: %d", skillId, skillParam);
            }
            else
            {
                ReplyToCommand(client, "[Class Tests]   Param: %d (Skill ID lookup unavailable)", skillParam);
            }
            ReplyToCommand(client, "[Class Tests]   Note: Activation test requires in-game verification");
            ReplyToCommand(client, "[Class Tests]   Try using the skill in-game to verify it works");
        }
    }
    else if (StrContains(skillConfig, "command:") == 0)
    {
        // Format: command:Plugin:type
        char parts[3][64];
        int partCount = ExplodeString(skillConfig[8], ":", parts, sizeof(parts), sizeof(parts[]));
        strcopy(skillName, sizeof(skillName), parts[0]);
        if (partCount > 1)
        {
            skillParam = StringToInt(parts[1]);
        }
        
        ReplyToCommand(client, "[Class Tests] %s Skill (command:%s:%d): ✓ Configured", 
                       skillType, skillName, skillParam);
        ReplyToCommand(client, "[Class Tests]   Note: Command-based skills require plugin verification");
    }
    else if (StrContains(skillConfig, "builtin:") == 0)
    {
        // Format: builtin:name
        strcopy(skillName, sizeof(skillName), skillConfig[8]);
        ReplyToCommand(client, "[Class Tests] %s Skill (builtin:%s): ✓ Configured", 
                       skillType, skillName);
    }
    else
    {
        ReplyToCommand(client, "[Class Tests] %s Skill: ✗ UNKNOWN FORMAT (%s)", skillType, skillConfig);
    }
}

public Action Timer_TestSummary(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int classIndex = pack.ReadCell();
    delete pack;
    
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    // Bounds check
    if (classIndex < 1 || classIndex >= sizeof(g_ClassConfigs))
    {
        return Plugin_Stop;
    }
    
    ReplyToCommand(client, "[Class Tests] [5/5] Test Summary for %s:", g_ClassConfigs[classIndex].className);
    ReplyToCommand(client, "[Class Tests]   Special: %s", g_ClassConfigs[classIndex].special);
    ReplyToCommand(client, "[Class Tests]   Secondary: %s", g_ClassConfigs[classIndex].secondary);
    ReplyToCommand(client, "[Class Tests]   Tertiary: %s", g_ClassConfigs[classIndex].tertiary);
    ReplyToCommand(client, "[Class Tests]   Deploy: %s", g_ClassConfigs[classIndex].deploy);
    ReplyToCommand(client, "[Class Tests] ========================================");
    ReplyToCommand(client, "[Class Tests] %s class tests completed!", g_ClassConfigs[classIndex].className);
    
    // Mark test as complete
    g_bTestInProgress[client] = false;
    CleanupTestTimers(client);
    
    return Plugin_Stop;
}

// Helper function to check if skill is registered
// Uses native FindSkillIdByName from RageCore
bool IsSkillRegistered(const char[] skillName)
{
    // Use cached native availability
    if (!g_bFindSkillIdAvailable)
    {
        // Fallback: Check if skill library exists
        char libName[64];
        strcopy(libName, sizeof(libName), skillName);
        
        // Use built-in StringToLower if available, otherwise manual conversion
        for (int i = 0; i < strlen(libName); i++)
        {
            if (libName[i] >= 'A' && libName[i] <= 'Z')
            {
                libName[i] = libName[i] + ('a' - 'A');
            }
        }
        
        return (LibraryExists(libName) || LibraryExists(skillName));
    }
    
    // Use native to find skill ID (native requires non-const char[])
    char skillNameCopy[64];
    strcopy(skillNameCopy, sizeof(skillNameCopy), skillName);
    int skillId = FindSkillIdByName(skillNameCopy);
    return (skillId != -1);
}
