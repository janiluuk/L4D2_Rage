#if defined _RAGE_CLASS_COMMANDS_INC
        #endinput
#endif
#define _RAGE_CLASS_COMMANDS_INC

#include <sourcemod>

forward bool ApplyClassSelection(int client, int classIndex);

public Action CreatePlayerClassMenuDelay(Handle hTimer, any client)
{
        CreatePlayerClassMenu(client);

        return Plugin_Stop;
}

stock Action CmdPlugins(int client, int args)
{
        for (new i = 1; i <= MaxClients; i++)
        {
                if(ClientData[i].ChosenClass != NONE)
                {
                        PrintToChat(client, "\x04%N\x01 is a %s - %s", i, MENU_OPTIONS[ClientData[i].ChosenClass], g_ClassDescriptions[ClientData[i].ChosenClass]);
                }
        }

        return Plugin_Handled;
}
