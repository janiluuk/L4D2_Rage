#if defined _RAGE_SURVIVOR_MENU_HUD_INC_
 #endinput
#endif
#define _RAGE_SURVIVOR_MENU_HUD_INC_

bool g_bHudEnabled = true;

void Hud_OnMapStart()
{
    if (!g_bHudEnabled)
    {
        return;
    }

    hudPosition currentPos = view_as<hudPosition>(getCurrentHud());
    if (currentPos < HUD_POSITION_FAR_LEFT || currentPos > HUD_POSITION_SCORE_4)
    {
        currentPos = HUD_POSITION_MID_TOP;
    }

    SetupMessageHud(currentPos, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS);
}

void Hud_SetEnabled(bool enabled, int activator)
{
    if (activator > 0 && IsClientInGame(activator))
    {
        if (g_bHudEnabled == enabled)
        {
            PrintHintText(activator, "HUD is already %s.", enabled ? "on" : "off");
            return;
        }
    }

    g_bHudEnabled = enabled;

    BuildRageMenus();

    if (!enabled)
    {
        DeleteAllHUD();

        if (activator > 0 && IsClientInGame(activator))
        {
            PrintHintText(activator, "HUD disabled.");
        }

        return;
    }

    // Only setup HUD if a map is running (entities can be created)
    char mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    if (mapname[0] == '\0')
    {
        // Map not loaded yet, HUD will be initialized in OnMapStart
        return;
    }

    hudPosition currentPos = view_as<hudPosition>(getCurrentHud());
    if (currentPos < HUD_POSITION_FAR_LEFT || currentPos > HUD_POSITION_SCORE_4)
    {
        currentPos = HUD_POSITION_MID_TOP;
    }

    SetupMessageHud(currentPos, HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_TEAM_SURVIVORS);

    if (activator > 0 && IsClientInGame(activator))
    {
        PrintHintText(activator, "HUD enabled.");
    }
}
