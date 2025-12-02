#if defined _RAGE_SURVIVOR_MENU_KITS_INC_
 #endinput
#endif
#define _RAGE_SURVIVOR_MENU_KITS_INC_

ConVar g_hKitSlots;
int g_iKitsUsed[MAXPLAYERS + 1];

void Kits_OnPluginStart()
{
    g_hKitSlots = CreateConVar("rage_menu_kit_slots", "1", "How many kits a player can request from the Rage menu per life.");
    g_hKitSlots.AddChangeHook(Kits_OnKitSlotsChanged);
}

void Kits_OnClientPutInServer(int client)
{
    g_iKitsUsed[client] = 0;
}

void Kits_OnClientDisconnect(int client)
{
    g_iKitsUsed[client] = 0;
}

void Kits_OnPlayerSpawn(int client)
{
    g_iKitsUsed[client] = 0;
}

void Kits_OnKitSlotsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == null)
    {
        return;
    }

    if (convar.IntValue < 0)
    {
        convar.SetInt(0);
    }
}

bool Kits_CanUseKit(int client)
{
    int maxKits = (g_hKitSlots != null) ? g_hKitSlots.IntValue : 1;
    return maxKits > 0 && g_iKitsUsed[client] < maxKits;
}

int Kits_ConsumeKit(int client)
{
    int maxKits = (g_hKitSlots != null) ? g_hKitSlots.IntValue : 1;
    g_iKitsUsed[client]++;
    int kitsRemaining = maxKits - g_iKitsUsed[client];
    if (kitsRemaining < 0)
    {
        kitsRemaining = 0;
    }
    return kitsRemaining;
}
