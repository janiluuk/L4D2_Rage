#if defined _rage_cooldown_notify_included
 #endinput
#endif
#define _rage_cooldown_notify_included

/**
 * Global cooldown notification system
 * Plays sound and shows HUD/hint when any skill cooldown ends
 */

// Include required dependencies
#if !defined _sdktools_included
 #include <sdktools>
#endif

// Include validation for KillTimerSafe and IsValidClient
#if !defined _rage_validation_included
 #include <rage/validation>
#endif

#define COOLDOWN_READY_SOUND "level/startwam.wav"  // Sound from Lethal Weapon plugin

// Cooldown tracking structure
enum struct CooldownEntry {
    int client;
    float endTime;
    char skillName[32];
    Handle timer;
}

ArrayList g_CooldownEntries;

// Initialize cooldown notification system
stock void CooldownNotify_Init()
{
    if (g_CooldownEntries == null)
    {
        g_CooldownEntries = new ArrayList(sizeof(CooldownEntry));
    }
}

// Cleanup cooldown notification system
stock void CooldownNotify_Cleanup()
{
    if (g_CooldownEntries != null)
    {
        for (int i = 0; i < g_CooldownEntries.Length; i++)
        {
            CooldownEntry entry;
            g_CooldownEntries.GetArray(i, entry);
            Handle timer = entry.timer;
            KillTimerSafe(timer);
        }
        delete g_CooldownEntries;
        g_CooldownEntries = null;
    }
}

// Register a cooldown to track
// Returns true if registered, false if already exists
// Marked stock so it can be safely included in plugins that don't call it (avoids unused warnings)
stock bool CooldownNotify_Register(int client, float endTime, const char[] skillName)
{
    if (g_CooldownEntries == null)
    {
        CooldownNotify_Init();
    }
    
    // Check if cooldown already exists for this client+skill
    for (int i = 0; i < g_CooldownEntries.Length; i++)
    {
        CooldownEntry entry;
        g_CooldownEntries.GetArray(i, entry);
        if (entry.client == client && StrEqual(entry.skillName, skillName))
        {
            // Update existing entry
            entry.endTime = endTime;
            Handle timer = entry.timer;
            KillTimerSafe(timer);
            float delay = endTime - GetGameTime();
            if (delay > 0.0)
            {
                DataPack pack = new DataPack();
                pack.WriteCell(client);
                pack.WriteString(skillName);
                entry.timer = CreateTimer(delay, Timer_CooldownNotify, pack);
            }
            else
            {
                entry.timer = INVALID_HANDLE;
            }
            g_CooldownEntries.SetArray(i, entry);
            return true;
        }
    }
    
    // Create new entry
    CooldownEntry entry;
    entry.client = client;
    entry.endTime = endTime;
    strcopy(entry.skillName, sizeof(entry.skillName), skillName);
    
    float delay = endTime - GetGameTime();
    if (delay > 0.0)
    {
        DataPack pack = new DataPack();
        pack.WriteCell(client);
        pack.WriteString(skillName);
        entry.timer = CreateTimer(delay, Timer_CooldownNotify, pack);
    }
    else
    {
        entry.timer = INVALID_HANDLE;
    }
    
    g_CooldownEntries.PushArray(entry);
    return true;
}

// Unregister a cooldown (when skill is used or client disconnects)
stock void CooldownNotify_Unregister(int client, const char[] skillName = "")
{
    if (g_CooldownEntries == null)
    {
        return;
    }
    
    for (int i = g_CooldownEntries.Length - 1; i >= 0; i--)
    {
        CooldownEntry entry;
        g_CooldownEntries.GetArray(i, entry);
        if (entry.client == client)
        {
            if (skillName[0] == '\0' || StrEqual(entry.skillName, skillName))
            {
                Handle timer = entry.timer;
                KillTimerSafe(timer);
                g_CooldownEntries.Erase(i);
            }
        }
    }
}

// Timer callback when cooldown ends
stock Action Timer_CooldownNotify(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = pack.ReadCell();
    char skillName[32];
    pack.ReadString(skillName, sizeof(skillName));
    delete pack;
    
    if (!IsValidClient(client) || !IsClientInGame(client))
    {
        CooldownNotify_Unregister(client, skillName);
        return Plugin_Stop;
    }
    
    // Play ready sound
    EmitSoundToClient(client, COOLDOWN_READY_SOUND, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
    
    // Show HUD notification
    char displayName[64];
    FormatSkillDisplayName(skillName, displayName, sizeof(displayName));
    PrintHintText(client, "✓ %s ready!", displayName);
    
    // HUD update is handled by GetPlayerSkillReadyHint in rage_survivor.sp
    
    // Remove from tracking
    CooldownNotify_Unregister(client, skillName);
    
    return Plugin_Stop;
}

// Format skill name for display
stock void FormatSkillDisplayName(const char[] skillName, char[] buffer, int maxlen)
{
    // Convert skill name to display format
    // e.g., "LethalWeapon" -> "Lethal Weapon"
    strcopy(buffer, maxlen, skillName);
    
    // Replace underscores with spaces
    ReplaceString(buffer, maxlen, "_", " ");
    
    // Capitalize first letter of each word
    bool capitalize = true;
    for (int i = 0; i < strlen(buffer); i++)
    {
        if (buffer[i] == ' ')
        {
            capitalize = true;
        }
        else if (capitalize)
        {
            if (buffer[i] >= 'a' && buffer[i] <= 'z')
            {
                buffer[i] = CharToUpper(buffer[i]);
            }
            capitalize = false;
        }
        else
        {
            if (buffer[i] >= 'A' && buffer[i] <= 'Z')
            {
                buffer[i] = CharToLower(buffer[i]);
            }
        }
    }
}

// Cleanup on client disconnect
stock void CooldownNotify_OnClientDisconnect(int client)
{
    CooldownNotify_Unregister(client);
}

// Cleanup on map end
stock void CooldownNotify_OnMapEnd()
{
    CooldownNotify_Cleanup();
    CooldownNotify_Init();
}
