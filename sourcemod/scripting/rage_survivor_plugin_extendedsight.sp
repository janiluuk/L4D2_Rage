#define PLUGIN_VERSION "1.2.4"
#define PLUGIN_NAME "Extended sight"
#define PLUGIN_SKILL_NAME "extended_sight"

#include <sourcemod>
#include <rage/validation>
#include <rage/skills>

#pragma semicolon 1
#pragma newdecls required

Handle g_rageCvarDuration;
Handle g_rageCvarCooldown;
Handle g_rageCvarGlow;
Handle g_rageCvarGlowMode;
Handle g_rageCvarGlowFade;
Handle g_rageCvarNotify;
Handle g_rageTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ...};
Handle g_rageRemoveTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

int g_rageGlowColor, g_ragePropGhost;
int g_rageGlowFadeSteps = 6; // Number of fade steps
bool g_rageActive[MAXPLAYERS+1] = {false, ...};
bool g_rageExtended[MAXPLAYERS+1] = {false, ...};
bool g_rageForever[MAXPLAYERS+1] = {false, ...};
float g_rageNextUse[MAXPLAYERS+1] = {0.0, ...};
int g_rageFadeStep[MAXPLAYERS+1] = {0, ...}; // Current fade step for each client
char g_rageGameName[64] = "";
int g_rageHasAbility[MAXPLAYERS+1] = {-1, ...};
const int CLASS_SABOTEUR = 4;
int g_iClassID = -1;
bool g_bRageAvailable = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("extended_sight");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;

}
public Plugin myinfo = 
{
	name = "[Rage] Extended Survivor Sight Plugin",
	author = "Yani, Jack'lul",
        description = "Saboteurs can briefly see Special Infected through walls on demand.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2085325"
}

public void OnPluginStart()
{
	GetGameFolderName(g_rageGameName, sizeof(g_rageGameName));
	if (!StrEqual(g_rageGameName, "left4dead2", false))
	{
		SetFailState("Plugin only supports Left 4 Dead 2!");
		return;
	}
	
	LoadTranslations("rage_extendedsight.phrases");
	
	CreateConVar("l4d2_extendedsight_version", PLUGIN_VERSION, "Extended Survivor Sight Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
        g_rageCvarNotify = CreateConVar("l4d2_extendedsight_notify", "1", "Notify players when they gain Extended Sight? 0 - disable, 1 - hintbox, 2 - chat", FCVAR_NOTIFY, true, 0.0, true, 2.0);
        g_rageCvarDuration = CreateConVar("l4d2_extendedsight_duration", "20", "How long should the Extended Sight last?", FCVAR_NOTIFY, true, 1.0);
        g_rageCvarCooldown = CreateConVar("l4d2_extendedsight_cooldown", "120", "Cooldown between uses in seconds", FCVAR_NOTIFY, true, 1.0);
	g_rageCvarGlow = CreateConVar("l4d2_extendedsight_glowcolor", "255 75 75", "Glow color, use RGB, seperate values with spaces", FCVAR_NOTIFY);
	g_rageCvarGlowMode = CreateConVar("l4d2_extendedsight_glowmode", "1", "Glow mode. 0 - persistent glow, 1 - fading glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_rageCvarGlowFade = CreateConVar("l4d2_extendedsight_glowfadeinterval", "3", "Interval between each glow fade", FCVAR_NOTIFY, true, 1.5, true, 10.0);
	
        RegConsoleCmd("sm_extendedsight", Command_ExtendedSight, "Trigger Extended Survivor Sight");
	
	AutoExecConfig(true, "l4d2_extendedsight");
	
	g_ragePropGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookConVarChange(g_rageCvarGlow, Changed_PluginCvarGlow);
}

public void OnAllPluginsLoaded()
{
    RageSkills_Refresh(PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryAdded(const char[] name)
{
    RageSkills_OnLibraryAdded(name, PLUGIN_SKILL_NAME, 0, g_iClassID, g_bRageAvailable);
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, RAGE_PLUGIN_NAME, false))
    {
        g_iClassID = -1;
    }

    RageSkills_OnLibraryRemoved(name, g_bRageAvailable);
}

public void Rage_OnPluginState(char[] plugin, int state)
{
    if (!StrEqual(plugin, RAGE_PLUGIN_NAME, false))
        return;

    if (state == 1)
    {
        g_bRageAvailable = true;
        if (g_iClassID == -1)
        {
            g_iClassID = RegisterRageSkill(PLUGIN_SKILL_NAME, 0);
        }
    }
    else if (state == 0)
    {
        g_bRageAvailable = false;
        g_iClassID = -1;
    }
}


public void OnPluginEnd() {
        DisableGlow();
}

//---------------------------------------------------------------------------------------------------------------

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
        g_rageHasAbility[client] = (newClass == CLASS_SABOTEUR) ? 1 : 0;
	return g_rageHasAbility[client];
}

public void OnMapStart()
{
    SetGlowColor();
    for(int i = 1; i <= MaxClients; ++i)
    {
        g_rageActive[i] = false;
        g_rageExtended[i] = false;
        g_rageForever[i] = false;
    }
}




public int OnSpecialSkillUsed(int client, int skill, int type)
{
        if (g_rageHasAbility[client] <= 0)
        {
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "not_saboteur");
                return 0;
        }

        if (g_rageActive[client])
        {
                PrintHintText(client, "Extended sight already active");
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "active");
                return 1;
        }

        float now = GetGameTime();
        float cooldown = GetConVarFloat(g_rageCvarCooldown);
        if (now < g_rageNextUse[client])
        {
                int remain = RoundToCeil(g_rageNextUse[client] - now);
                PrintHintText(client, "Extended sight ready in %d seconds", remain);
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "cooldown");
                return 1;
        }

        g_rageNextUse[client] = now + cooldown;
        AddExtendedSight(GetConVarFloat(g_rageCvarDuration), client);
        PrintHintText(client, "✓ Extended sight activated!");
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);

        return 1;
}

public Action Command_ExtendedSight(int client, int args)
{
        if (g_rageHasAbility[client] <= 0) return Plugin_Handled;

        if (g_rageActive[client])
        {
                ReplyToCommand(client, "%t", "ALREADYACTIVE");
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "active");
                return Plugin_Handled;
        }

        float now = GetGameTime();
        float cooldown = GetConVarFloat(g_rageCvarCooldown);
        if (now < g_rageNextUse[client])
        {
                int remain = RoundToCeil(g_rageNextUse[client] - now);
                ReplyToCommand(client, "%t", "COOLDOWN", remain);
                OnSpecialSkillFail(client, PLUGIN_SKILL_NAME, "cooldown");
                return Plugin_Handled;
        }

        g_rageNextUse[client] = now + cooldown;
        AddExtendedSight(GetConVarFloat(g_rageCvarDuration), client);
        PrintHintText(client, "✓ Extended sight activated!");
        OnSpecialSkillSuccess(client, PLUGIN_SKILL_NAME);

        return Plugin_Handled;
}


public void Changed_PluginCvarGlow(Handle convar, const char[] oldValue, const char[] newValue) {
        SetGlowColor();
}

public Action TimerRemoveSight(Handle timer)
{
	RemoveExtendedSight();
	
	if(GetConVarInt(g_rageCvarNotify) != 0)
		NotifyPlayers();
	return Plugin_Handled;
}

public Action TimerChangeGlow(Handle timer, Handle hPack)
{
	ResetPack(hPack);
	int userId = ReadPackCell(hPack);
	int fadeStep = ReadPackCell(hPack);
	int client = GetClientOfUserId(userId);
	
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if(g_rageActive[client])
	{
		int color = CalculateFadeColor(fadeStep);
		SetGlow(color, client);
	}
	else if (g_rageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_rageTimer[client]);
		g_rageTimer[client] = INVALID_HANDLE;
	}

	CloseHandle(hPack);
	return Plugin_Stop;
}

/**
 * Calculate faded glow color based on step
 * @param step    Fade step (0 = full color, g_rageGlowFadeSteps = invisible)
 * @return        Calculated color value
 */
int CalculateFadeColor(int step)
{
	if (step >= g_rageGlowFadeSteps)
		return 0;
	
	if (step == 0)
		return g_rageGlowColor;
	
	// Extract RGB components
	int r = g_rageGlowColor & 0xFF;
	int g = (g_rageGlowColor >> 8) & 0xFF;
	int b = (g_rageGlowColor >> 16) & 0xFF;
	
	// Calculate fade multiplier (linear fade)
	float multiplier = 1.0 - (float(step) / float(g_rageGlowFadeSteps));
	
	// Apply fade to each component
	r = RoundFloat(r * multiplier);
	g = RoundFloat(g * multiplier);
	b = RoundFloat(b * multiplier);
	
	// Recombine into color value
	return r + (g << 8) + (b << 16);
}

public Action TimerGlowFading(Handle timer, int userId)
{	
	int client = GetClientOfUserId(userId);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if(g_rageActive[client])
	{
		// Increment fade step
		g_rageFadeStep[client]++;
		
		// If we've completed all fade steps, reset and restart cycle
		if (g_rageFadeStep[client] > g_rageGlowFadeSteps)
		{
			g_rageFadeStep[client] = 0;
		}
		
		// Apply the current fade step
		int color = CalculateFadeColor(g_rageFadeStep[client]);
		SetGlow(color, client);
	}
	else if (g_rageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_rageTimer[client]);
		g_rageTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//---------------------------------------------------------------------------------------------------------------

void AddExtendedSight(float time, int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) 
	{
		return;
	}

	if(g_rageActive[client])
	{		
		if (g_rageRemoveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_rageRemoveTimer[client]);
			g_rageRemoveTimer[client] = INVALID_HANDLE;	
		}
		g_rageExtended[client] = true;
	}
	
	g_rageActive[client] = true;
	g_rageFadeStep[client] = 0;
	
	if(time == 0.0)
		g_rageForever[client] = true;
	
	if(GetConVarInt(g_rageCvarGlowMode) == 1 && !g_rageExtended[client])
		g_rageTimer[client] = CreateTimer(GetConVarFloat(g_rageCvarGlowFade), TimerGlowFading, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else if(!g_rageExtended[client]) 
	{
		// Persistent glow mode - just set it once
		SetGlow(g_rageGlowColor, client);
	}
	
	if(time > 0.0 && GetConVarInt(g_rageCvarGlowMode) == 1)
		g_rageRemoveTimer[client] = CreateTimer(time, TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
	else if(time > 0.0)
		g_rageRemoveTimer[client] = CreateTimer(time+GetConVarFloat(g_rageCvarGlowFade), TimerRemoveSight, TIMER_FLAG_NO_MAPCHANGE);
		
	if(time > 0.0 && GetConVarInt(g_rageCvarNotify) != 0)
		NotifyPlayers();
}

void RemoveExtendedSight()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(g_rageActive[iClient])
		{
			g_rageActive[iClient] = false;
			g_rageExtended[iClient] = false;
			g_rageForever[iClient] = false;
			
			DisableGlow();
		}
	}
}

void SetGlow(any color, int client)
{
	if (g_rageHasAbility[client] <= 0) return;

	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3 && g_rageActive[client] == true && color != 0 && GetEntData(iClient, g_ragePropGhost, 1)!=1)
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", color);
		}
		else if(IsClientInGame(iClient))
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);	
		}
	}
}

void DisableGlow()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);	
		}
	}	
}

void NotifyPlayers()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			if(GetClientTeam(iClient) == 2)
			{
				if(g_rageActive[iClient] && !g_rageExtended[iClient])
				{
					if(GetConVarInt(g_rageCvarNotify)==1)
						PrintHintText(iClient, "%t", "ACTIVATED");
					else
						PrintToChat(iClient, "%t", "ACTIVATED");
				}
				else if(g_rageExtended[iClient])
				{
					if(GetConVarInt(g_rageCvarNotify)==1)
						PrintHintText(iClient, "%t", "DURATIONEXTENDED");
					else
						PrintToChat(iClient, "%t", "DURATIONEXTENDED");
				}
				else
				{	
					if(GetConVarInt(g_rageCvarNotify)==1)
						PrintHintText(iClient, "%t", "DEACTIVATED");
					else
						PrintToChat(iClient, "%t", "DEACTIVATED");
				}
			}
		}	
	}
}

void SetGlowColor()
{
	char split[3][3];
	char sPluginCvarGlow[64];
	
	GetConVarString(g_rageCvarGlow, sPluginCvarGlow, sizeof(sPluginCvarGlow));
	ExplodeString(sPluginCvarGlow, " ", split, 3, 4);
	
	int rgb[3];
	// Parse and clamp RGB values to valid range (0-255) in one step
	for (int i = 0; i < 3; i++)
	{
		rgb[i] = StringToInt(split[i]);
		if (rgb[i] < 0) 
			rgb[i] = 0;
		else if (rgb[i] > 255) 
			rgb[i] = 255;
	}
	
	// Store color as single integer: R + (G << 8) + (B << 16)
	g_rageGlowColor = rgb[0] + (rgb[1] << 8) + (rgb[2] << 16);
}

