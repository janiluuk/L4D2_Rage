 
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Action Command_Debug(int client, int args) {
	
	if (args < 1)
	{
		ReplyToCommand(client, "\x03[Rage]\x01 Usage: \x04sm_debug\x01 [0 = Off|1 = On]");
		return Plugin_Handled;
	}
		
	decl String:arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	bool debugMode =  StringToInt(arg) > 0 ? true:false;
	setDebugMode(debugMode ? StringToInt(arg) : 0);
	ReplyToCommand(client, "Debug mode is set to %s", debugMode ? "ON" : "OFF");

	return Plugin_Handled;
}
public Action CmdModel(int client, int args) {
        if (args < 1)
        {
                ReplyToCommand(client, "\x03[Rage]\x01 Usage: \x04sm_model\x01 <model path>");
                return Plugin_Handled;
        }

        char sModel[PLATFORM_MAX_PATH];
        GetCmdArg(1, sModel, sizeof(sModel));

        SetEntityModel(client, sModel);
        ReplyToCommand(client, "Changing model to %s", sModel);

        return Plugin_Handled;

}

public Action Cmd_SetVictim(int client, int args) {
	if(args == 0) {
		ReplyToCommand(client, "Please enter a player to target");
	}else{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[1], target_count;
		bool tn_is_ml;

		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE, /* Only allow alive players */
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(int i = 0; i < target_count; i++) {
			int victim = target_list[i];
			//g_iSITargets
			g_bIsVictim[victim] = !g_bIsVictim[victim];
			ReplyToCommand(client, "Successfully toggled %N victim status to: %b", victim, g_bIsVictim[victim]);
			ShowActivity(client, "toggled special infected victim status for %N to %b", victim, g_bIsVictim[victim]);
		}
	}
	return Plugin_Handled;
}
public Action Cmd_GetHudText(int client, int args) {

	char text[1023];
	getHudText(text, sizeof(text));
	ReplyToCommand(client, "Current HUD text: %s", text);
	
	return Plugin_Handled;
}

public Action Cmd_GetHud(int client, int args) {

	int hud = getCurrentHud();
	ReplyToCommand(client, "Current HUD id: %i", hud);
	
	return Plugin_Handled;
}

public Action Cmd_SetupHud(int client, int args) {

	char arg1[64];
	char arg2[64];
	char arg3[64];
	char arg4[64];
	char arg5[64];
	char arg6[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	GetCmdArg(5, arg5, sizeof(arg5));
	GetCmdArg(6, arg6, sizeof(arg6));

	if(args < 6) {
		ReplyToCommand(client, "Give position ID, flags, xpos, ypos, width, height. (Min 0.0, Max 1.0) ");
	} else {

		SetupMessageHud(view_as<hudPosition>(StringToInt(arg1)), StringToInt(arg2), StringToFloat(arg3), StringToFloat(arg4), StringToFloat(arg5),StringToFloat(arg6));


		ReplyToCommand(client, "HUD has been setup");
	}

	return Plugin_Handled;
}

public Action Cmd_SetHud(int client, int args) {

	char arg1[128];

	if(args == 0) {
		ReplyToCommand(client, "Give position ID");
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
		setCurrentHud(StringToInt(arg1));
		ReplyToCommand(client, "Set current HUD to %i", arg1);
	}

	return Plugin_Handled;
}

public Action Cmd_ClearHUD(int client, int args) {

	ReplyToCommand(client, "Hud Cleared");
	ClearHUD();
	return Plugin_Handled;
}

public Action Cmd_CloseHUD(int client, int args) {

	ReplyToCommand(client, "Hud Closed");
	ClearHUD();
	return Plugin_Handled;
}

public Action Cmd_DeleteHUD(int client, int args) {

	char arg1[128];

	if(args == 0) {
		ReplyToCommand(client, "Deleting all huds");
		DeleteAllHUD();
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	
	int index = StringToInt(arg1);
	int a = 1;
	for (int i = 1; i < 16; i++) {
		if (i == index) {
			DeleteHUD(view_as<hudPosition>(a));
		}
		a=a*2;
	}

	ReplyToCommand(client, "Deleted hud %i (1-15)", StringToInt(arg1));

	return Plugin_Handled;
}

public Action Cmd_PrintToHUD(int client, int args) {
	char arg1[128];

	if(args == 0) {
		ReplyToCommand(client, "Please enter message and position (1-15)");
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	if (args < 2) {
		PrintToHud(arg1);
	} else {
		char arg2[3];
		GetCmdArg(2, arg2, sizeof(arg2));
		PrintToHudPosition(arg1, StringToInt(arg2));
	}

	return Plugin_Handled;
}

public Action GrenadeCommand(int client, int args)
{
        if (IsAdmin(client)) {
		// Index
		int index;
		char str[3];
		new type=GetCmdArg(1, str, 32);
		if(type==0) {
		}
		else
		{
			int c = StringToInt(str);
			index = c;
		}			
		useCustomCommand("Grenades", client, -1, index);
	}			
	
	return Plugin_Handled;
}

public Action HideCommand(int client, int args)
{
        if (client > 0 && IsClientInGame(client) && IsAdmin(client)) {

		new String:str[32];
		new type=GetCmdArg(1, str, 32);
		if(type==0) {
		}
		else
		{
			int c = StringToInt(str);
			if (c || IsValidEntity(c) || IsClientInGame(c)){
				client = c;					
			}
		}			
		HidePlayer(client);
	}
	return Plugin_Handled;
}

