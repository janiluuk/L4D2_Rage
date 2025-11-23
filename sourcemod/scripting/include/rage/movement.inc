#if defined _rage_movement_included
 #endinput
#endif
#define _rage_movement_included

#if !defined SOUND_HELICOPTER
    #define SOUND_HELICOPTER "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
#endif

// Provide local fallbacks for common models used by the parachute ability so this
// helper can be included without relying on broader talent definitions.
#if !defined PARACHUTE
    #define PARACHUTE "models/props_swamp/parachute01.mdl"
#endif

#if !defined FAN_BLADE
    #define FAN_BLADE "models/props/de_inferno/ceiling_fan_blade.mdl"
#endif

/**
 * Lightweight containers for movement-centric abilities so they can be reused
 * from talent classes without cluttering the primary plugin file.
 */

enum struct ParachuteAbility
{
    bool active[MAXPLAYERS + 1];
    int entityRef[MAXPLAYERS + 1];
    int velocityOffset;

    void Initialize()
    {
        this.velocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
        for (int i = 1; i <= MaxClients; i++)
        {
            this.ResetClient(i);
        }
    }

    void ResetClient(int client)
    {
        this.active[client] = false;
        this.entityRef[client] = INVALID_ENT_REFERENCE;
    }

    bool HandleRunCmd(int client, int buttons, int flags, Handle parachuteToggle, bool isLeft4Dead2)
    {
        #pragma unused flags

        if (!GetConVarBool(parachuteToggle))
        {
            return false;
        }

        if (this.active[client])
        {
            if (!(buttons & IN_USE) || !IsPlayerAlive(client) || (GetEntityFlags(client) & FL_ONGROUND))
            {
                this.Disable(client, isLeft4Dead2);
                return true;
            }

            float velocity[3];
            GetEntDataVector(client, this.velocityOffset, velocity);

            if (velocity[2] >= 0.0)
            {
                this.Disable(client, isLeft4Dead2);
                return true;
            }

            float originalSpeed = velocity[2];
            if (velocity[2] < -100.0)
            {
                velocity[2] = -100.0;
            }

            if (originalSpeed != velocity[2])
            {
                TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
            }

            return true;
        }

        if (!(buttons & IN_USE) || !IsPlayerAlive(client) || (GetEntityFlags(client) & FL_ONGROUND))
        {
            return false;
        }

        float velocity[3];
        GetEntDataVector(client, this.velocityOffset, velocity);
        if (velocity[2] >= 0.0)
        {
            return false;
        }

        int entity = CreateEntityByName("prop_dynamic_override");
        DispatchKeyValue(entity, "model", isLeft4Dead2 ? PARACHUTE : FAN_BLADE);
        DispatchSpawn(entity);

        SetEntityMoveType(entity, MOVETYPE_NOCLIP);

        float parachutePos[3], parachuteAng[3];
        GetClientAbsOrigin(client, parachutePos);
        GetClientAbsAngles(client, parachuteAng);
        parachutePos[2] += 80.0;
        parachuteAng[0] = 0.0;

        TeleportEntity(entity, parachutePos, parachuteAng, NULL_VECTOR);

        int red = GetRandomInt(0, 255), green = GetRandomInt(0, 255), blue = GetRandomInt(0, 255);
        SetEntProp(entity, Prop_Send, "m_nGlowRange", 1000);
        SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", red + (green * 256) + (blue * 65536));
        SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 0.3);

        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 255, 255, 255, 2);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);
        this.entityRef[client] = EntIndexToEntRef(entity);
        this.active[client] = true;
        return true;
    }

    void Disable(int client, bool isLeft4Dead2)
    {
        int entity = EntRefToEntIndex(this.entityRef[client]);
        if (entity != INVALID_ENT_REFERENCE)
        {
            AcceptEntityInput(entity, "ClearParent");
            AcceptEntityInput(entity, "kill");
        }

        this.Drop(client, isLeft4Dead2);
        this.active[client] = false;
        this.entityRef[client] = INVALID_ENT_REFERENCE;
    }

    void Drop(int client, bool isLeft4Dead2)
    {
        if (!IsClientInGame(client))
        {
            return;
        }

        if (!isLeft4Dead2)
        {
            StopSound(client, SNDCHAN_STATIC, SOUND_HELICOPTER);
        }
    }
}

enum struct JumpKickState
{
    float energy;
    float lastTime;
    int attacker;
    float attackTime;
    float nextShoveTime;
    float shoveTime;
    float shoveDelay;
    float jumpTime;
    float jumpOnGroundTime;
    float keyPressedTime;
    bool attackDisable;
    float attackDisableTime;
    int enemyList[MAXPLAYERS + 1];

    void Reset()
    {
        this.energy = 0.0;
        this.lastTime = 0.0;
        this.attacker = 0;
        this.attackTime = 0.0;
        this.nextShoveTime = 0.0;
        this.shoveTime = 0.0;
        this.shoveDelay = 100.0;
        this.jumpTime = 0.0;
        this.jumpOnGroundTime = 0.0;
        this.keyPressedTime = 0.0;
        this.attackDisable = false;
        this.attackDisableTime = 0.0;

        for (int i = 0; i <= MaxClients; i++)
        {
            this.enemyList[i] = 0;
        }
    }
}

enum struct JumpKickAbility
{
    JumpKickState state[MAXPLAYERS + 1];

    void ResetAll()
    {
        for (int i = 0; i <= MaxClients; i++)
        {
            this.ResetClient(i);
        }
    }

    void ResetClient(int client)
    {
        this.state[client].Reset();
    }

    void ResetPair(int first, int second)
    {
        if (first > 0)
        {
            this.ResetClient(first);
        }
        if (second > 0)
        {
            this.ResetClient(second);
        }
    }
}
