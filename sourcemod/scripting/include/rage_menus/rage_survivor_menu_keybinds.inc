#if defined _RAGE_SURVIVOR_MENU_KEYBINDS_INC_
 #endinput
#endif
#define _RAGE_SURVIVOR_MENU_KEYBINDS_INC_

ConVar g_hDefaultMenuKey;
Handle g_hMenuKeyCookie = INVALID_HANDLE;

void Keybinds_OnPluginStart()
{
    g_hMenuKeyCookie = RegClientCookie("rage_menu_key_bound", "Rage menu key auto-bind status", CookieAccess_Private);
    g_hDefaultMenuKey = CreateConVar("rage_menu_default_key", "v", "Default key to bind the Rage menu to. Set to empty string to disable auto-binding. Can also use 'shift' for SHIFT key.", FCVAR_NONE);
}

void Keybinds_OnClientCookiesCached(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    if (g_hMenuKeyCookie == INVALID_HANDLE || g_hDefaultMenuKey == null)
    {
        return;
    }

    char boundStatus[8];
    GetClientCookie(client, g_hMenuKeyCookie, boundStatus, sizeof(boundStatus));

    // If cookie is empty or "0", the key hasn't been bound yet
    if (boundStatus[0] != '\0' && StringToInt(boundStatus) != 0)
    {
        return;
    }

    char defaultKey[32];
    g_hDefaultMenuKey.GetString(defaultKey, sizeof(defaultKey));

    // Only bind if a default key is configured and valid
    if (defaultKey[0] != '\0' && Keybinds_IsValidKeyString(defaultKey))
    {
        // Handle special key names
        char bindKey[32];
        if (StrEqual(defaultKey, "shift", false))
        {
            // Shift key uses +speed in Source engine
            strcopy(bindKey, sizeof(bindKey), "+speed");
        }
        else
        {
            strcopy(bindKey, sizeof(bindKey), defaultKey);
        }
        
        // Execute bind command for the client
        ClientCommand(client, "bind %s +rage_menu", bindKey);
        
        // For shift key, also need to bind -speed to close menu
        if (StrEqual(defaultKey, "shift", false))
        {
            ClientCommand(client, "bind -speed -rage_menu");
        }

        // Mark as bound in cookie
        SetClientCookie(client, g_hMenuKeyCookie, "1");

        // Notify the player
        CreateTimer(2.0, Timer_NotifyMenuKey, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

bool Keybinds_IsValidKeyString(const char[] key)
{
    int len = strlen(key);
    if (len == 0 || len > 31)
    {
        return false;
    }

    // Special case: "shift" is valid
    if (StrEqual(key, "shift", false))
    {
        return true;
    }

    for (int i = 0; i < len; i++)
    {
        char c = key[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'))
        {
            return false;
        }
    }

    return true;
}

Action Timer_NotifyMenuKey(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Stop;
    }

    char defaultKey[32];
    if (g_hDefaultMenuKey != null)
    {
        g_hDefaultMenuKey.GetString(defaultKey, sizeof(defaultKey));
        if (defaultKey[0] != '\0')
        {
            PrintToChat(client, "\x04[Rage]\x01 Menu bound to \x03%s\x01 key. Hold to open, release to close.", defaultKey);
            PrintToChat(client, "\x01Or press \x03X\x01 (voice menu) for quick access. Type \x03!rage_bind\x01 to change key.");
        }
    }

    return Plugin_Stop;
}
