#if defined _RAGE_SURVIVOR_MENU_THIRDPERSON_INC_
 #endinput
#endif
#define _RAGE_SURVIVOR_MENU_THIRDPERSON_INC_

enum ThirdPersonMode
{
    TP_Off = 0,
    TP_MeleeOnly,
    TP_Always
};

bool g_bThirdPersonPluginAvailable = false;
ThirdPersonMode g_ThirdPersonMode[MAXPLAYERS + 1];
bool g_ThirdPersonActive[MAXPLAYERS + 1];
Handle g_hThirdPersonCookie = INVALID_HANDLE;

void ThirdPerson_OnPluginStart()
{
    g_hThirdPersonCookie = RegClientCookie("rage_tp_mode", "Rage third person preference", CookieAccess_Public);
    g_bThirdPersonPluginAvailable = true; // Bundled helper plugin is shipped alongside this menu.
}

void ThirdPerson_OnClientPutInServer(int client)
{
    g_ThirdPersonActive[client] = false;
    g_ThirdPersonMode[client] = TP_Off;
}

void ThirdPerson_OnClientDisconnect(int client)
{
    g_ThirdPersonActive[client] = false;
    g_ThirdPersonMode[client] = TP_Off;
}

void ThirdPerson_OnCookiesCached(int client)
{
    if (g_hThirdPersonCookie == INVALID_HANDLE || !IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    char buffer[8];
    GetClientCookie(client, g_hThirdPersonCookie, buffer, sizeof(buffer));
    if (buffer[0] != '\0')
    {
        g_ThirdPersonMode[client] = view_as<ThirdPersonMode>(StringToInt(buffer));
    }

    ThirdPerson_Apply(client);
}

void ThirdPerson_OnPlayerSpawn(int client)
{
    ThirdPerson_Apply(client);
}

void ThirdPerson_OnWeaponSwitch(int client)
{
    ThirdPerson_Apply(client);
}

void ThirdPerson_SetMode(int client, ThirdPersonMode newMode)
{
    g_ThirdPersonMode[client] = newMode;
    ThirdPerson_Persist(client);
    ThirdPerson_Apply(client);
}

void ThirdPerson_Persist(int client)
{
    if (g_hThirdPersonCookie == INVALID_HANDLE || IsFakeClient(client))
    {
        return;
    }

    char buffer[8];
    IntToString(view_as<int>(g_ThirdPersonMode[client]), buffer, sizeof(buffer));
    SetClientCookie(client, g_hThirdPersonCookie, buffer);
}

void ThirdPerson_Apply(int client)
{
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return;
    }

    bool shouldThird = false;
    switch (g_ThirdPersonMode[client])
    {
        case TP_MeleeOnly:
        {
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            shouldThird = ThirdPerson_IsMeleeWeapon(weapon);
        }
        case TP_Always:
        {
            shouldThird = true;
        }
    }

    if (shouldThird == g_ThirdPersonActive[client])
    {
        return;
    }

    g_ThirdPersonActive[client] = shouldThird;
    ThirdPerson_SetActive(client, shouldThird);
}

void ThirdPerson_SetActive(int client, bool enable)
{
    if (!g_bThirdPersonPluginAvailable || client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    if (enable)
    {
        FakeClientCommand(client, "sm_3rdon");
    }
    else
    {
        FakeClientCommand(client, "sm_3rdoff");
    }
}

bool ThirdPerson_IsMeleeWeapon(int weapon)
{
    if (weapon <= 0 || !IsValidEntity(weapon))
    {
        return false;
    }

    char cls[64];
    GetEntityClassname(weapon, cls, sizeof(cls));
    return StrContains(cls, "melee", false) != -1 || StrEqual(cls, "weapon_chainsaw", false);
}
