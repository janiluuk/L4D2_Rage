#if defined _rage_timers_included
 #endinput
#endif
#define _rage_timers_included

#include <l4d2_airstrike>
#include <rage/effects>

// Plugin-specific code is wrapped in #if defined RAGE_SURVIVOR_PLUGIN blocks
// Basic timer callbacks are always available, but code that depends on rage_survivor.sp
// symbols will only compile when RAGE_SURVIVOR_PLUGIN is defined

#if !defined _f18airstrike_included
native void F18_ShowAirstrike(float origin[3], float direction);
#endif

static void TryShowAirstrike(float origin[3])
{
        if (GetFeatureStatus(FeatureType_Native, "F18_ShowAirstrike") == FeatureStatus_Available)
        {
                F18_ShowAirstrike(origin, GetRandomFloat(0.0, 180.0));
        }
}

#if defined RAGE_SURVIVOR_PLUGIN
static bool PressedSpecialSkillButton(int client, int buttons)
{
	// Check for mouse3 via IN_ZOOM (which is mouse wheel/middle button) or IN_ATTACK3
	bool pressed = (buttons & IN_ZOOM) != 0 || (buttons & IN_ATTACK3) != 0;
	bool wasPressed = (ClientData[client].LastButtons & IN_ZOOM) != 0 || (ClientData[client].LastButtons & IN_ATTACK3) != 0;
	return pressed && !wasPressed;
}

static bool PressedSecondarySkillButton(int client, int buttons)
{
        bool pressedZoom = (buttons & IN_ZOOM) != 0;
        bool pressedCombo = (buttons & IN_USE) != 0 && (buttons & IN_ATTACK) != 0;
        bool wasPressed = (ClientData[client].LastButtons & IN_ZOOM) != 0 ||
                ((ClientData[client].LastButtons & IN_USE) != 0 && (ClientData[client].LastButtons & IN_ATTACK) != 0);

        return (pressedZoom || pressedCombo) && !wasPressed;
}

static bool PressedPlantModifier(int client, int buttons)
{
	// Deployment requires CROUCH+SHOVE (IN_ATTACK2) specifically
	bool shovePressed = (buttons & IN_ATTACK2) != 0;
	bool crouchPressed = (buttons & IN_DUCK) != 0;
	bool wasShovePressed = (ClientData[client].LastButtons & IN_ATTACK2) != 0;
	bool wasCrouchPressed = (ClientData[client].LastButtons & IN_DUCK) != 0;
	
	// Require both CROUCH and SHOVE to be pressed together
	if (shovePressed && crouchPressed)
	{
		// Trigger on initial press when both buttons are pressed (at least one wasn't pressed before)
		if (!wasShovePressed || !wasCrouchPressed)
		{
			return true;
		}
	}
	
	return false;
}

static bool IsLookingDown(int client, float minPitch = 45.0)
{
	float ang[3];
	GetClientEyeAngles(client, ang);
	return ang[0] >= minPitch;
}

stock Action TimerStart(Handle timer)
{
	ResetPlugin();
	OnRoundState(1);
	DmgHookUnhook(true);

	return Plugin_Continue;
}

public Action:TimerThink(Handle:hTimer, any:userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Stop;
	}
	
	new buttons = GetClientButtons(client);
	new Float:fCanDropTime = (GetGameTime() - ClientData[client].LastDropTime);
	new bool:CanDrop = (fCanDropTime >= ClientData[client].SpecialDropInterval);
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	int iDropTime = RoundToFloor(fCanDropTime);
	// Removed redundant button detection for skill actions - console commands handle this now
	bool pressedPlant = PressedPlantModifier(client, buttons);
	int entityFlags = GetEntityFlags(client);
	bool onGround = (entityFlags & FL_ONGROUND) != 0;
	// Deployment requires CROUCH+SHOVE (IN_ATTACK2) to be held
	bool holdingDeploy = (buttons & IN_ATTACK2) != 0 && (buttons & IN_DUCK) != 0;
	bool lookingDown = IsLookingDown(client);

	ClassTypes classType = ClientData[client].ChosenClass;

	// Skill actions are now handled via console commands (+skill_action_1/2/3)
	// No need for redundant button detection here

	switch (classType)
	{
		case athlete:
		{
			SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(ATHLETE_SPEED), true);
		}
		case saboteur:
		{
			if (BombActive == true)
			{
				if (iDropTime > 0 && iDropTime < GetConVarInt(SABOTEUR_BOMB_ACTIVATE))
				{
					PrintHintText(client, "Mine is arming in %i seconds", GetConVarInt(SABOTEUR_BOMB_ACTIVATE) - iDropTime);
				}
				else if (iDropTime == GetConVarInt(SABOTEUR_BOMB_ACTIVATE))
				{
					if (BombHintTimestamp != iDropTime)
					{
						PrintHintTextToAll("%N's mine is now armed!", client);
						BombHintTimestamp = iDropTime;
					}
				}
			}
			if (buttons & IN_DUCK)
			{
				int hidingTime = RoundToFloor(GetGameTime() - ClientData[client].HideStartTime);
				if (hidingTime >= GetConVarInt(SABOTEUR_INVISIBLE_TIME))
				{
					if (InvisibilityTimestamp != hidingTime && InvisibilityHint == false)
					{
						SetRenderProperties(client);
						FakeClientCommand(client, "sm_nap_apply 7");
						FakeClientCommand(client, "sm_extendedsight");
						InvisibilityTimestamp = hidingTime;
						InvisibilityHint = true;
					}
				}
				if (hidingTime < GetConVarInt(SABOTEUR_INVISIBLE_TIME) && (hidingTime > 2))
				{
					GlowPlayer(client, "Blue", FX:FxHologram);

					if (InvisibilityTimestamp != hidingTime)
					{
						PrintHintText(client,"Becoming invisible in %i seconds", GetConVarInt(SABOTEUR_INVISIBLE_TIME) - hidingTime);
						InvisibilityTimestamp = hidingTime;
					}
				}
			}
			else
			{
				InvisibilityHint = false;
			}
		}
		case medic:
		{
			if (buttons & IN_DUCK)
			{
				SetEntDataFloat(client, g_flLaggedMovementValue, 1.7, true);

				if ((GetGameTime() - ClientData[client].HealStartTime) >= 3.0)
				{
					if (MedicHint == false)
					{
						PrintHintTextToAll("%N is healing everyone around him!", client);
						MedicHint = true;
					}
				}
			}
			else
			{
				SetEntDataFloat(client, g_flLaggedMovementValue, 1.0, true);
				MedicHint = false;
			}
		}
		case soldier:
		{
			SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(SOLDIER_SPEED), true);
		}
	}

	// Check deployment when holding CTRL (IN_DUCK) - no longer requires SHOVE or looking down
	bool holdingCTRL = (buttons & IN_DUCK) != 0;
	if (holdingCTRL)
	{
		HandleDeployInput(client, classType, holdingCTRL, pressedPlant, onGround, CanDrop, iDropTime);
	}
	else
	{
		// CTRL released - close deployment menu
		HandleDeployInput(client, classType, false, false, onGround, CanDrop, iDropTime);
	}

	ClientData[client].LastButtons = buttons;
	return Plugin_Continue;
}
#endif // RAGE_SURVIVOR_PLUGIN

#if defined RAGE_SURVIVOR_PLUGIN
public Action:TimerLoadClient(Handle:hTimer, any:client)
{
	if (!client ||  !IsValidEntity(client) || !IsClientInGame(client)) 
	return Plugin_Stop;

	ResetPlugin();
	ResetClientVariables(client);	
	if (RoundStarted == false && !IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client)) {
		RoundStarted = true;	
	}
	return Plugin_Stop;
}

public Action Timer_Ready(Handle timer, int client) {
	if (!IsValidClient(client) ||  !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{ return Plugin_Stop; }

	GetPlayerSkillReadyHint(client);
	//KillTimer(g_ReadyTimer, true);
	g_ReadyTimer[client] = null;
	return Plugin_Stop;
}

public Action:TimerRestorePlayer(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new userid = ReadPackCell(hPack);
	new client = GetClientOfUserId(userid);
	new chosenClass = ReadPackCell(hPack);
	CloseHandle(hPack);
	ClientData[client].ChosenClass = view_as<ClassTypes>(chosenClass);

	return Plugin_Stop;

}
public Action:TimerSetClientTempHealth(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new iValue = ReadPackCell(hPack);
	CloseHandle(hPack);
	
	if(!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| IsClientObserver(client)
		|| GetClientTeam(client) != 2)
	return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

public Action:GlowTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int health = ReadPackCell(pack);
	CloseHandle(pack);

	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	new newHp = GetClientHealth(client);
	new TempHealth = GetClientTempHealth(client);
	new totalHp = newHp+TempHealth;

	if (totalHp > health) {
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, client);
		WritePackCell(hPack, totalHp);

		CreateTimer(1.0, GlowTimer, hPack, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	} else {
		SetRenderProperties(client);
	}

	return Plugin_Stop;
}

public Action:TimerDetectHealthChanges(Handle:hTimer, any:client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| ClientData[client].ChosenClass != medic)
	return Plugin_Stop;
	
	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{	return Plugin_Continue; }
	
	new btns = GetClientButtons(client);

	if (btns & IN_DUCK)
	{
		// Enhanced medic glow effect on the medic themselves
		CreateParticle(client, MEDIC_GLOW, true, 1.0);
		
		// Add pulsing healing aura effect around medic
		decl Float:medicPos[3], Float:medicEyePos[3];
		GetClientAbsOrigin(client, medicPos);
		GetClientEyePosition(client, medicEyePos);
		medicPos[2] += 40.0; // Raise effect slightly above ground
		
		// Create healing aura ring effect
		if (g_BeamSprite != -1 && g_HaloSprite != -1)
		{
			decl greenColorAura[4];
			greenColorAura[0] = 0;
			greenColorAura[1] = 255;
			greenColorAura[2] = 100;
			greenColorAura[3] = 200;
			
			float healRadius = GetConVarFloat(MEDIC_HEAL_DIST);
			TE_SetupBeamRingPoint(medicPos, healRadius - 10.0, healRadius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 2.0, greenColorAura, 10, 0);
			TE_SendToAll();
		}

		decl Float:pos[3];
		decl String:sMessage[256];	
		GetClientAbsOrigin(client, pos);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
			{
				decl Float:tpos[3], Float:targetEyePos[3];
				GetClientAbsOrigin(i, tpos);
				GetClientEyePosition(i, targetEyePos);
				
				if (GetVectorDistance(pos, tpos) <= GetConVarFloat(MEDIC_HEAL_DIST))
				{
					// Enhanced visual effects: healing beam between medic and target
					if (g_BeamSprite != -1)
					{
						decl greenBeamColor[4];
						greenBeamColor[0] = 100;
						greenBeamColor[1] = 255;
						greenBeamColor[2] = 150;
						greenBeamColor[3] = 255;
						
						// Create healing beam from medic to target
						medicEyePos[2] -= 20.0; // Lower beam start point
						targetEyePos[2] -= 20.0; // Lower beam end point
						TE_SetupBeamPoints(medicEyePos, targetEyePos, g_BeamSprite, 0, 0, 0, 0.3, 3.0, 3.0, 1, 0.0, greenBeamColor, 0);
						TE_SendToAll();
						
						// Add healing particles at target location using CreateParticle
						CreateParticle(i, MEDIC_GLOW, true, 0.5);
					}
					
					// pre-heal set values
					new MaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
					new TempHealth = GetClientTempHealth(i);

					Format(sMessage, sizeof(sMessage), "%N is healing you!", client);

					ShowBar(i, sMessage, float(GetClientHealth(i)), float(MaxHealth));
					SetEntityHealth(i, GetClientHealth(i) + GetConVarInt(MEDIC_HEALTH_VALUE));
					SetClientTempHealth(i, TempHealth);
					
					// post-heal set values
					new newHp = GetClientHealth(i);
					new totalHp = newHp + TempHealth;
					
					// Enhanced glow effect with pulsing
					GlowPlayer(i, "Green", FX:FxPulseFast);
					
					// Add healing sparkle effect with beam ring
					if (g_BeamSprite != -1 && g_HaloSprite != -1)
					{
						decl Float:sparklePos[3];
						sparklePos[0] = tpos[0];
						sparklePos[1] = tpos[1];
						sparklePos[2] = tpos[2] + 30.0;
						
						decl sparkleColor[4];
						sparkleColor[0] = 150;
						sparkleColor[1] = 255;
						sparkleColor[2] = 200;
						sparkleColor[3] = 255;
						
						// Create healing pulse ring around healed player
						TE_SetupBeamRingPoint(sparklePos, 5.0, 50.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 2.0, 1.0, sparkleColor, 10, 0);
						TE_SendToAll();
					}
					
					new Handle:hPack = CreateDataPack();
					WritePackCell(hPack, i);
					WritePackCell(hPack, totalHp);

					CreateTimer(1.0, GlowTimer, hPack, TIMER_FLAG_NO_MAPCHANGE); 	
					
					if (totalHp > MaxHealth)
					{
						new diff = totalHp - MaxHealth;
						
						if (TempHealth >= diff)
						{
							SetClientTempHealth(i, TempHealth - diff);
							continue;
						}
						
						SetClientTempHealth(i, 0);
						SetEntityHealth(i, MaxHealth);
					}
				}
			}
		}
	} else {

		MedicHint = false;
	}
	
	return Plugin_Continue;
}
#endif // RAGE_SURVIVOR_PLUGIN

#if defined RAGE_SURVIVOR_PLUGIN
public Action:TimerAirstrike(Handle timer, Handle:hPack)
{
	new Float:pos[3];
	new Float:time;
	int client;
	int entity;
	int userId;
	ResetPack(hPack);
	userId = ReadPackCell(hPack);		
	client = GetClientOfUserId(userId);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	time =  ReadPackFloat(hPack);
	entity = ReadPackCell(hPack);

	if (client > 0 && IsClientInGame(client) && RoundToFloor(GetGameTime()-time) <= 10) {
		PrintHintTextToAll("Airstrike in %i, take cover!",10-(RoundToFloor(GetGameTime()-time)));
		
		return Plugin_Continue;
	} else {

		g_bAirstrikeValid = true;
                PrintHintTextToAll("Airstrike completed!");
                ClientData[client].SpecialsUsed++;
                TryShowAirstrike(pos);

		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}

	return Plugin_Stop;
}

public Action:TimerActivateBomb(Handle:hTimer, Handle:hPack)
{
	CreateTimer(0.3, TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:TimerCheckBombSensors(Handle:hTimer, Handle:hPack)
{
	new Float:pos[3];
	decl Float:clientpos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	new ownerUser = ReadPackCell(hPack);
	new owner = GetClientOfUserId(ownerUser);
	
	if (IsValidSurvivor(owner, false) != true) {
		return Plugin_Stop;
	}

	new session = ReadPackCell(hPack);
	int index = ReadPackCell(hPack);
	int bombType = ReadPackCell(hPack);
	int entity = ReadPackCell(hPack);

	if (index < 0) index = 0;

	if (session != RndSession)
	return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{

		if (!IsValidEntity(client) || !IsClientInGame(client))
		continue;

		if(GetClientTeam(client) == 3 || GetClientTeam(client) == 2 || IsWitch(client))
		{
			char classname[32];
			GetClientAbsOrigin(client, clientpos);
			GetEdictClassname(client, classname, sizeof(classname));

			if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
			{
				if (GetClientTeam(client) == 3 || IsWitch(client) || IsTank(client)) {
	
					
					if (GetConVarInt(SABOTEUR_BOMB_TYPES) == 1) {
						PrintDebugAll("Enabling single minetype mode");
						CreateExplosion(pos, client);					
					}
					
					if (!IsValidEntity(owner) || !IsClientInGame(owner)) {
						return Plugin_Stop;
					}
					BombActive = false;
					BombIndex[index] = false;
					PrintHintTextToAll("%N's mine detonated!", owner);
		

					PrintDebugAll("Detonating Mine %s on entity %i", getBombName(bombType), entity );

					useCustomCommand("Grenades", owner, entity, bombType-1);					
					
					return Plugin_Stop;
				}
				else if (GetClientTeam(client) == 2) {
					
					if (!mineWarning[client] || mineWarning[client] < GetGameTime() + 5) {
						PrintHintText(client, "Warning! You are nearby armed mine.");
						mineWarning[client] = GetGameTime();
					}
				}
			}
			
		}
	}
	return Plugin_Continue;
}
#endif // RAGE_SURVIVOR_PLUGIN

#if defined RAGE_SURVIVOR_PLUGIN
/**
 * @note Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */

stock bool IsTank(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 33)
		if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
			return true;
	
	return false;
}
#endif // RAGE_SURVIVOR_PLUGIN

// Basic timer callbacks - always available (used by rage/effects.inc)
public Action:TimerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if (IsValidEdict(Particle))
	AcceptEntityInput(Particle, "Kill");
}

public Action:timerHurtEntity(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	new Float:amount = ReadPackFloat(pack);
	new type = ReadPackCell(pack);
	CloseHandle(pack);
	HurtEntity(client, attacker, amount, type);
}

public Action:TimerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:TimerDeleteParticles(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 7; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	CloseHandle(pack);
}

public Action:TimerActivateBombParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}

}

// Basic timer callbacks - always available (used by rage/effects.inc)
public Action:TimerStopAndRemoveBombParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	int entity = ReadPackCell(pack);
	#if defined RAGE_SURVIVOR_PLUGIN
	int index = ReadPackCell(pack);
	int mine = ReadPackCell(pack);	
	#endif
	CloseHandle(pack);
	if (entity > 0 && IsValidEntity(entity)) 
	{
		#if defined RAGE_SURVIVOR_PLUGIN
		if (BombActive == false) {
			AcceptEntityInput(entity, "Kill");
		} else {
			static float vPos[3];
			char color[12];
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, index);
			WritePackCell(hPack, entity);
			GetConVarString(SABOTEUR_ACTIVE_BOMB_COLOR, color, sizeof(color));
			SetupPrjEffects(entity, vPos, color); // Red
			int defibParticle;
			int elmosParticle;
			// Particle
			defibParticle = DisplayParticle(entity, PARTICLE_DEFIB, vPos, NULL_VECTOR);				
			WritePackCell(hPack, defibParticle);

			if (defibParticle) InputKill(defibParticle, 2.0);
			elmosParticle = DisplayParticle(entity, PARTICLE_ELMOS, vPos, NULL_VECTOR);
			if (elmosParticle) InputKill(elmosParticle, 3.0);
			WritePackCell(hPack, elmosParticle);
			WritePackCell(hPack, mine);

			CreateTimer(15.0, TimerDeleteBombs, hPack, TIMER_FLAG_NO_MAPCHANGE);			
		}
		#else
		// Fallback: just kill the entity if plugin-specific code not available
		AcceptEntityInput(entity, "Kill");
		#endif
	}
}

#if defined RAGE_SURVIVOR_PLUGIN
public Action:TimerStopAndRemoveParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		if (BombActive == true) {
			CreateTimer(3.0, TimerStopAndRemoveParticle, entity, TIMER_FLAG_NO_MAPCHANGE);			
		} else {
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public Action:TimerDeleteBombs(Handle:timer, Handle:pack)
{		
	ResetPack(pack);
	int index = ReadPackCell(pack);
	bool removed = false;

	if (BombIndex[index] == false) {
		for (new i = 0; i < 3; i++)
		{
			int entity = ReadPackCell(pack);
			if(entity > 0 && IsValidEntity(entity))
			{
				AcceptEntityInput(entity, "Kill");
				removed = true;
			}
		}
		CloseHandle(pack);

	} else {
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, index);
		int entity = ReadPackCell(pack);
		WritePackCell(hPack, entity);
		int defibParticle = ReadPackCell(pack);
		WritePackCell(hPack, defibParticle);
		int elmosParticle = ReadPackCell(pack);
		WritePackCell(hPack, elmosParticle);
		int mine = ReadPackCell(pack);
		WritePackCell(hPack, mine);
		CloseHandle(pack);
		CreateTimer(5.0, TimerDeleteBombs, hPack, TIMER_FLAG_NO_MAPCHANGE);		
		return Plugin_Continue;
	}
	if (removed == true) {
		return Plugin_Stop;
	} 
	return Plugin_Continue;
}
#endif // RAGE_SURVIVOR_PLUGIN

public Action Timer_Parachute( Handle timer, any iEntity)
{
	int iParachute = EntRefToEntIndex(iEntity);
	if (IsValidEntity(iParachute))
	{
		RotateParachute(iParachute, 100.0, 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void RotateParachute(int index, float value, int axis)
{
	if (IsValidEntity(index))
	{
		float s_rotation[3];
		GetEntPropVector(index, Prop_Data, "m_angRotation", s_rotation);
		s_rotation[axis] += value;
		TeleportEntity(index, NULL_VECTOR, s_rotation, NULL_VECTOR);
	}
}
