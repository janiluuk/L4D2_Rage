#define PLUGIN_VERSION "1.0"
#define PLUGIN_SKILL_NAME "WallRun"
#define PLUGIN_NAME "[Rage] Wall Run & Climb"

#include <sourcemod>
#include <sdktools>
#include <rage/validation>
#include <rage/skills>

#pragma semicolon 1
#pragma newdecls required

// ConVars
ConVar g_cvarEnable;
ConVar g_cvarSpeed;
ConVar g_cvarMaxTime;
ConVar g_cvarClimbSpeed;
ConVar g_cvarStickDistance;

// Rage system
int g_iClassID = -1;
bool g_bRageAvailable = false;
const int CLASS_ATHLETE = 2;

// Client data
bool g_bHasAbility[MAXPLAYERS+1] = {false, ...};
bool g_bWallRunning[MAXPLAYERS+1] = {false, ...};
float g_fWallRunStart[MAXPLAYERS+1] = {0.0, ...};
float g_fWallNormal[MAXPLAYERS+1][3];
float g_fWallPoint[MAXPLAYERS+1][3];

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Rage Team",
	description = "Athlete skill: Wall running and wall climbing",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("rage_survivor_wallrun");
	RageSkills_MarkNativesOptional();
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("rage_wallrun_enable", "1", "Enable Wall Run skill", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpeed = CreateConVar("rage_wallrun_speed", "300.0", "Wall run speed", FCVAR_NOTIFY, true, 50.0, true, 500.0);
	g_cvarMaxTime = CreateConVar("rage_wallrun_maxtime", "3.0", "Maximum wall run time in seconds", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	g_cvarClimbSpeed = CreateConVar("rage_wallrun_climbspeed", "200.0", "Wall climb speed", FCVAR_NOTIFY, true, 50.0, true, 400.0);
	g_cvarStickDistance = CreateConVar("rage_wallrun_stickdistance", "50.0", "Distance to stick to wall", FCVAR_NOTIFY, true, 10.0, true, 100.0);

	AutoExecConfig(true, "rage_wallrun");
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

public int OnPlayerClassChange(int client, int newClass, int previousClass)
{
	g_bHasAbility[client] = (newClass == CLASS_ATHLETE);
	if (!g_bHasAbility[client])
	{
		StopWallRun(client);
	}
	return g_bHasAbility[client] ? 1 : 0;
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bWallRunning[i] = false;
		g_fWallRunStart[i] = 0.0;
	}
}

public void OnClientPutInServer(int client)
{
	g_bHasAbility[client] = false;
	g_bWallRunning[client] = false;
	g_fWallRunStart[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
	StopWallRun(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!g_bRageAvailable || !g_cvarEnable.BoolValue)
		return Plugin_Continue;

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (!g_bHasAbility[client])
		return Plugin_Continue;

	int flags = GetEntityFlags(client);
	bool onGround = (flags & FL_ONGROUND) != 0;

	// If on ground, stop wall running
	if (onGround)
	{
		if (g_bWallRunning[client])
		{
			StopWallRun(client);
		}
		return Plugin_Continue;
	}

	// Check if player is near a wall
	float clientPos[3], clientAng[3];
	GetClientAbsOrigin(client, clientPos);
	GetClientEyeAngles(client, clientAng);

	// Check for wall in front
	float wallPoint[3], wallNormal[3];
	if (FindWall(client, clientPos, clientAng, wallPoint, wallNormal))
	{
		float distance = GetVectorDistance(clientPos, wallPoint);
		if (distance <= g_cvarStickDistance.FloatValue)
		{
			// Start or continue wall run
			if (!g_bWallRunning[client])
			{
				StartWallRun(client, wallPoint, wallNormal);
			}
			else
			{
				UpdateWallRun(client, buttons, wallPoint, wallNormal, vel);
			}
		}
		else
		{
			StopWallRun(client);
		}
	}
	else
	{
		StopWallRun(client);
	}

	return Plugin_Continue;
}

bool FindWall(int client, float pos[3], float angles[3], float wallPoint[3], float wallNormal[3])
{
	float fwdVec[3], right[3], up[3];
	GetAngleVectors(angles, fwdVec, right, up);

	// Check multiple directions
	float directions[3][3];
	CopyVector(fwdVec, directions[0]);
	
	// Slightly to the right
	float temp[3];
	CopyVector(fwdVec, temp);
	ScaleVector(right, 0.3);
	AddVectors(temp, right, directions[1]);
	NormalizeVector(directions[1], directions[1]);
	
	// Slightly to the left
	CopyVector(fwdVec, temp);
	ScaleVector(right, -0.3);
	AddVectors(temp, right, directions[2]);
	NormalizeVector(directions[2], directions[2]);

	for (int i = 0; i < 3; i++)
	{
		float endPos[3];
		CopyVector(pos, endPos);
		ScaleVector(directions[i], g_cvarStickDistance.FloatValue * 2.0);
		AddVectors(endPos, directions[i], endPos);

		Handle trace = TR_TraceRayFilterEx(pos, directions[i], MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_WallRun, client);
		
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(wallPoint, trace);
			TR_GetPlaneNormal(trace, wallNormal);
			CloseHandle(trace);
			return true;
		}
		CloseHandle(trace);
	}

	return false;
}

public bool TraceFilter_WallRun(int entity, int contentsMask, int client)
{
	if (entity == client)
		return false;
	
	if (entity > 0 && entity <= MaxClients)
		return false;
	
	return true;
}

void StartWallRun(int client, float wallPoint[3], float wallNormal[3])
{
	g_bWallRunning[client] = true;
	g_fWallRunStart[client] = GetGameTime();
	CopyVector(wallPoint, g_fWallPoint[client]);
	CopyVector(wallNormal, g_fWallNormal[client]);
	
	PrintHintText(client, "Wall Run!");
}

void UpdateWallRun(int client, int buttons, float wallPoint[3], float wallNormal[3], float vel[3])
{
	float gameTime = GetGameTime();
	float elapsed = gameTime - g_fWallRunStart[client];
	
	if (elapsed > g_cvarMaxTime.FloatValue)
	{
		StopWallRun(client);
		return;
	}

	// Calculate movement along wall
	float right[3], up[3];
	float angles[3];
	GetClientEyeAngles(client, angles);
	
	GetAngleVectors(angles, NULL_VECTOR, right, up);
	
	// Project right vector onto wall plane
	float wallRight[3];
	CopyVector(right, wallRight);
	float dot = GetVectorDotProduct(wallRight, wallNormal);
	float scaled[3];
	CopyVector(wallNormal, scaled);
	ScaleVector(scaled, dot);
	SubtractVectors(wallRight, scaled, wallRight);
	NormalizeVector(wallRight, wallRight);
	
	// Apply wall run speed
	float speed = g_cvarSpeed.FloatValue;
	if (buttons & IN_FORWARD)
	{
		ScaleVector(wallRight, speed);
		AddVectors(vel, wallRight, vel);
	}
	else if (buttons & IN_BACK)
	{
		ScaleVector(wallRight, -speed);
		AddVectors(vel, wallRight, vel);
	}
	
	// Wall climbing (upward movement)
	if (buttons & IN_JUMP)
	{
		float climbVel[3];
		CopyVector(up, climbVel);
		ScaleVector(climbVel, g_cvarClimbSpeed.FloatValue);
		AddVectors(vel, climbVel, vel);
	}
	
	// Keep player stuck to wall
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	
	float toWall[3];
	SubtractVectors(wallPoint, clientPos, toWall);
	float distance = GetVectorLength(toWall);
	
	if (distance > g_cvarStickDistance.FloatValue)
	{
		// Pull player back to wall
		NormalizeVector(toWall, toWall);
		float pull[3];
		CopyVector(toWall, pull);
		ScaleVector(pull, (distance - g_cvarStickDistance.FloatValue) * 10.0);
		AddVectors(vel, pull, vel);
	}
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
}

void StopWallRun(int client)
{
	if (!g_bWallRunning[client])
		return;
	
	g_bWallRunning[client] = false;
	g_fWallRunStart[client] = 0.0;
}

void CopyVector(float src[3], float dst[3])
{
	dst[0] = src[0];
	dst[1] = src[1];
	dst[2] = src[2];
}

