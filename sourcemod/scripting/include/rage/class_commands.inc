#if defined _RAGE_CLASS_COMMANDS_INC
        #endinput
#endif
#define _RAGE_CLASS_COMMANDS_INC

#include <sourcemod>

forward bool ApplyClassSelection(int client, int classIndex);

stock Action CmdClassInfo(int client, int args)
{
        for (int classIndex = 1; classIndex < view_as<int>(MAXCLASSES); classIndex++)
        {
                PrintToChat(client, "\x05%s\x01 - %s", MENU_OPTIONS[classIndex], g_ClassDescriptions[classIndex]);
        }

        return Plugin_Handled;
}

stock Action CmdClassMenu(int client, int args)
{
        if (GetClientTeam(client) != 2)
        {
                PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
                return Plugin_Handled;
        }
        CreatePlayerClassMenu(client);

        return Plugin_Handled;
}

stock Action CmdClassSet(int client, int args)
{
        if (GetClientTeam(client) != 2)
        {
                PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
                return Plugin_Handled;
        }

        if (args < 1)
        {
                PrintToChat(client, "%sSelect a class number between 1 and %d.", PRINT_PREFIX, view_as<int>(MAXCLASSES) - 1);
                return Plugin_Handled;
        }

        char arg[16];
        GetCmdArg(1, arg, sizeof(arg));

        int classIndex = StringToInt(arg);
        if (classIndex <= 0 || classIndex >= view_as<int>(MAXCLASSES))
        {
                PrintToChat(client, "%sSelect a class number between 1 and %d.", PRINT_PREFIX, view_as<int>(MAXCLASSES) - 1);
                return Plugin_Handled;
        }

        ApplyClassSelection(client, classIndex);
        return Plugin_Handled;
}

public Action CreatePlayerClassMenuDelay(Handle hTimer, any client)
{
        CreatePlayerClassMenu(client);

        return Plugin_Stop;
}

stock Action CmdClasses(int client, int args)
{
        for (new i = 1; i <= MaxClients; i++)
        {


                if(IsClientInGame(i) && GetClientTeam(i) == 2 && ClientData[i].ChosenClass != NONE)
                {
                        static char translation[256];

                        Format(translation, sizeof(translation), "\x04%N\x01 is a {green}%s{white} - %s", i, MENU_OPTIONS[ClientData[i].ChosenClass], g_ClassDescriptions[ClientData[i].ChosenClass]);
                        ReplaceColors(translation, sizeof(translation));
                        PrintToChatAll(translation);
                }
        }

        return Plugin_Handled;
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
