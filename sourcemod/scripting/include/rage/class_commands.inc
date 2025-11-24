#if defined _RAGE_CLASS_COMMANDS_INC
        #endinput
#endif
#define _RAGE_CLASS_COMMANDS_INC

#include <sourcemod>

forward bool ApplyClassSelection(int client, int classIndex);

public Action CmdClassInfo(int client, int args)
{
        PrintToChat(client,"\x05Soldier\x01 = Has faster attack rate, runs faster and takes less damage");
        PrintToChat(client,"\x05Athlete\x01 = Jumps higher, has parachute.");
        PrintToChat(client,"\x05Medic\x01 = Heals others, plants medical supplies. Faster revive & heal speed");
        PrintToChat(client,"\x05Saboteur\x01 = Can go invisible, plants powerful mines and throws special grenades");
        PrintToChat(client,"\x05Commando\x01 = Has fast reload, deals extra damage");
        PrintToChat(client,"\x05Engineer\x01 = Drops auto turrets and ammo");
        PrintToChat(client,"\x05Brawler\x01 = Has Lots of health");

        return Plugin_Handled;
}

public Action CmdClassMenu(int client, int args)
{
        if (GetClientTeam(client) != 2)
        {
                PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
                return Plugin_Handled;
        }
        CreatePlayerClassMenu(client);

        return Plugin_Handled;
}

public Action CmdClassSet(int client, int args)
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

                        Format(translation, sizeof(translation), "\x04%N\x01 is a {green}%s{white}%s",i,MENU_OPTIONS[ClientData[i].ChosenClass], ClassTips[ClientData[i].ChosenClass]);
                        ReplaceColors(translation, sizeof(translation));
                        PrintToChatAll(translation);
                }
        }

        return Plugin_Handled;
}

public Action CmdPlugins(int client, int args)
{
        for (new i = 1; i <= MaxClients; i++)
        {
                if(ClientData[i].ChosenClass != NONE)
                {
                        PrintToChat(client, "\x04%N\x01 is a %s",i,MENU_OPTIONS[ClientData[i].ChosenClass]);
                }
        }

        return Plugin_Handled;
}
