#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Rage Music Player Tests"

public Plugin myinfo =
{
    name = "[RAGE] Music Player Tests",
    author = "Yani",
    description = "Comprehensive tests for RAGE music player",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_cvTestEnabled;

public void OnPluginStart()
{
    g_cvTestEnabled = CreateConVar("rage_tests_music_enabled", "1", "Enable/disable music player tests", FCVAR_NONE, true, 0.0, true, 1.0);
    
    RegAdminCmd("sm_test_music", Command_TestMusic, ADMFLAG_ROOT, "Test music player functionality");
    RegAdminCmd("sm_test_music_config", Command_TestMusicConfig, ADMFLAG_ROOT, "Test music player configuration");
    RegAdminCmd("sm_test_music_cookies", Command_TestMusicCookies, ADMFLAG_ROOT, "Test music player cookies");
    RegAdminCmd("sm_test_music_timers", Command_TestMusicTimers, ADMFLAG_ROOT, "Test music player timers");
}

public Action Command_TestMusic(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Music Tests] Tests are disabled. Set rage_tests_music_enabled to 1.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Music Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Music Tests] ========================================");
    ReplyToCommand(client, "[Music Tests] Testing Music Player...");
    ReplyToCommand(client, "[Music Tests] ========================================");
    
    // Test 1: Check if plugin is loaded
    bool pluginLoaded = LibraryExists("rage_music");
    ReplyToCommand(client, "[Music Tests] Plugin Loaded: %s", pluginLoaded ? "✓ PASS" : "✗ FAIL");
    
    if (!pluginLoaded)
    {
        ReplyToCommand(client, "[Music Tests] Music plugin not found. Skipping remaining tests.");
        return Plugin_Handled;
    }
    
    // Test 2: Check if config files exist
    char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof(configPath), "data/music_mapstart.txt");
    bool configExists = FileExists(configPath);
    ReplyToCommand(client, "[Music Tests] Config File Exists: %s (%s)", configExists ? "✓ PASS" : "✗ FAIL", configPath);
    
    // Test 3: Test music commands
    ReplyToCommand(client, "[Music Tests] Testing Commands...");
    FakeClientCommand(client, "sm_music");
    ReplyToCommand(client, "[Music Tests] ✓ sm_music command sent (check if menu appears)");
    
    // Test 4: Test play command
    FakeClientCommand(client, "sm_music_play");
    ReplyToCommand(client, "[Music Tests] ✓ sm_music_play command sent");
    
    // Test 5: Test pause command
    CreateTimer(2.0, Timer_TestPause, GetClientUserId(client));
    
    // Test 6: Test next command
    CreateTimer(4.0, Timer_TestNext, GetClientUserId(client));
    
    // Test 7: Test current command
    CreateTimer(6.0, Timer_TestCurrent, GetClientUserId(client));
    
    ReplyToCommand(client, "[Music Tests] Tests scheduled. Results will appear over the next few seconds.");
    return Plugin_Handled;
}

public Action Timer_TestPause(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    FakeClientCommand(client, "sm_music_pause");
    ReplyToCommand(client, "[Music Tests] ✓ sm_music_pause command sent");
    return Plugin_Stop;
}

public Action Timer_TestNext(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    FakeClientCommand(client, "sm_music_next");
    ReplyToCommand(client, "[Music Tests] ✓ sm_music_next command sent");
    return Plugin_Stop;
}

public Action Timer_TestCurrent(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }
    
    FakeClientCommand(client, "sm_music_current");
    ReplyToCommand(client, "[Music Tests] ✓ sm_music_current command sent");
    return Plugin_Stop;
}

public Action Command_TestMusicConfig(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Music Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Music Tests] Testing Music Configuration...");
    
    // Test config file reading
    char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof(configPath), "data/music_mapstart.txt");
    
    if (!FileExists(configPath))
    {
        ReplyToCommand(client, "[Music Tests] ✗ Config file does not exist: %s", configPath);
        return Plugin_Handled;
    }
    
    File hFile = OpenFile(configPath, "r");
    if (hFile == null)
    {
        ReplyToCommand(client, "[Music Tests] ✗ Cannot open config file");
        return Plugin_Handled;
    }
    
    int lineCount = 0;
    int validLines = 0;
    char sLine[PLATFORM_MAX_PATH];
    
    while (!hFile.EndOfFile() && hFile.ReadLine(sLine, sizeof(sLine)))
    {
        lineCount++;
        TrimString(sLine);
        if (strlen(sLine) > 0 && !(sLine[0] == '/' && sLine[1] == '/'))
        {
            validLines++;
        }
    }
    
    CloseHandle(hFile);
    
    ReplyToCommand(client, "[Music Tests] Config File Stats:");
    ReplyToCommand(client, "[Music Tests]   Total Lines: %d", lineCount);
    ReplyToCommand(client, "[Music Tests]   Valid Tracks: %d", validLines);
    ReplyToCommand(client, "[Music Tests] %s", validLines > 0 ? "✓ PASS" : "✗ FAIL");
    
    // Test newly connected list
    char newlyPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, newlyPath, sizeof(newlyPath), "data/music_mapstart_newly.txt");
    bool newlyExists = FileExists(newlyPath);
    ReplyToCommand(client, "[Music Tests] Newly Connected List: %s", newlyExists ? "✓ EXISTS" : "⚠ NOT FOUND (optional)");
    
    return Plugin_Handled;
}

public Action Command_TestMusicCookies(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Music Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(client))
    {
        ReplyToCommand(client, "[Music Tests] You must be a valid client to run tests.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Music Tests] Testing Music Cookies...");
    
    // Test cookie existence
    Handle cookie = FindClientCookie("music_mapstart_cookie");
    bool cookieExists = (cookie != INVALID_HANDLE);
    ReplyToCommand(client, "[Music Tests] Cookie Exists: %s", cookieExists ? "✓ PASS" : "✗ FAIL");
    
    if (cookieExists)
    {
        // Test cookie reading
        if (AreClientCookiesCached(client))
        {
            char cookieValue[16];
            GetClientCookie(client, cookie, cookieValue, sizeof(cookieValue));
            ReplyToCommand(client, "[Music Tests] Cookie Value: %s", strlen(cookieValue) > 0 ? cookieValue : "(empty)");
            ReplyToCommand(client, "[Music Tests] ✓ Cookie readable");
        }
        else
        {
            ReplyToCommand(client, "[Music Tests] ⚠ Cookies not cached yet");
        }
    }
    
    return Plugin_Handled;
}

public Action Command_TestMusicTimers(int client, int args)
{
    if (!g_cvTestEnabled.BoolValue)
    {
        ReplyToCommand(client, "[Music Tests] Tests are disabled.");
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "[Music Tests] Testing Music Timers...");
    ReplyToCommand(client, "[Music Tests] Note: Timer tests require manual verification");
    
    // Check ConVars
    ConVar delayCvar = FindConVar("l4d_music_mapstart_delay");
    if (delayCvar != null)
    {
        float delay = delayCvar.FloatValue;
        ReplyToCommand(client, "[Music Tests] Music Delay: %.1f seconds", delay);
        ReplyToCommand(client, "[Music Tests] %s", delay >= 0.0 ? "✓ PASS" : "✗ FAIL");
    }
    else
    {
        ReplyToCommand(client, "[Music Tests] ✗ Delay ConVar not found");
    }
    
    ConVar enabledCvar = FindConVar("start_music_enabled");
    if (enabledCvar != null)
    {
        bool enabled = enabledCvar.BoolValue;
        ReplyToCommand(client, "[Music Tests] Music Enabled: %s", enabled ? "Yes" : "No");
    }
    
    ConVar roundStartCvar = FindConVar("l4d_music_mapstart_play_roundstart");
    if (roundStartCvar != null)
    {
        bool roundStart = roundStartCvar.BoolValue;
        ReplyToCommand(client, "[Music Tests] Play on Round Start: %s", roundStart ? "Yes" : "No");
    }
    
    ReplyToCommand(client, "[Music Tests] Timer tests completed.");
    return Plugin_Handled;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

