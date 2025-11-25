#if defined _RAGE_ADMIN_COMMANDS_INC
        #endinput
#endif
#define _RAGE_ADMIN_COMMANDS_INC

#include <sourcemod>

forward Action CmdRageMenu(int client, int args);
forward Action Cmd_PrintToHUD(int client, int args);
forward Action Cmd_ClearHUD(int client, int args);
forward Action Cmd_DeleteHUD(int client, int args);
forward Action Cmd_CloseHUD(int client, int args);
forward Action Cmd_GetHud(int client, int args);
forward Action Cmd_SetHud(int client, int args);
forward Action Cmd_SetupHud(int client, int args);
forward Action Cmd_SetVictim(int client, int args);
forward Action Command_Debug(int client, int args);
forward Action CmdModel(int client, int args);
forward Action GrenadeCommand(int client, int args);
forward Action HideCommand(int client, int args);

stock void RegisterAdminCommands()
{
        RegAdminCmd("sm_ragem", CmdRageMenu, ADMFLAG_ROOT, "Debug & Manage");
        RegAdminCmd("sm_hide", HideCommand, ADMFLAG_ROOT, "Hide player");
        RegAdminCmd("sm_rage_plugins", CmdPlugins, ADMFLAG_ROOT, "List plugins");
        RegAdminCmd("sm_yay", GrenadeCommand, ADMFLAG_ROOT, "Test grenades");
        RegAdminCmd("sm_hud", Cmd_PrintToHUD, ADMFLAG_ROOT, "Test HUD");
        RegAdminCmd("sm_hud_clear", Cmd_ClearHUD, ADMFLAG_ROOT, "Clear HUD");
        RegAdminCmd("sm_hud_delete", Cmd_DeleteHUD, ADMFLAG_ROOT, "Delete HUD");
        RegAdminCmd("sm_hud_close", Cmd_CloseHUD, ADMFLAG_ROOT, "Delete HUD");
        RegAdminCmd("sm_hud_get", Cmd_GetHud, ADMFLAG_ROOT, "Delete HUD");
        RegAdminCmd("sm_hud_set", Cmd_SetHud, ADMFLAG_ROOT, "Delete HUD");
        RegAdminCmd("sm_hud_setup", Cmd_SetupHud, ADMFLAG_ROOT, "Delete HUD");
        RegAdminCmd("sm_setvictim", Cmd_SetVictim, ADMFLAG_ROOT, "Set horde to attack player #");
        RegAdminCmd("sm_debug", Command_Debug, ADMFLAG_GENERIC, "sm_debug [0 = Off|1 = PrintToChat|2 = LogToFile|3 = PrintToChat AND LogToFile]");
        RegAdminCmd("sm_model", CmdModel, ADMFLAG_GENERIC, "Change model to custom one");
}

