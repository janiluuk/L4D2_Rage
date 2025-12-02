#if defined _RAGE_SKILL_ACTIONS_INC_
 #endinput
#endif
#define _RAGE_SKILL_ACTIONS_INC_

#define SKILL_ACTION_BIND_CONFIG "configs/rage_skill_actions.cfg"

enum SkillActionSlot
{
    SkillAction_Primary = 0,
    SkillAction_Secondary,
    SkillAction_Tertiary,
    SkillAction_Deploy,
    SkillActionSlot_Count
};

static const char g_SkillActionKeys[SkillActionSlot_Count][24] =
{
    "skill_action_1",
    "skill_action_2",
    "skill_action_3",
    "deployment_action"
};

char g_SkillActionBindings[SkillActionSlot_Count][64];

void ResetSkillActionBindings()
{
    strcopy(g_SkillActionBindings[SkillAction_Primary], sizeof(g_SkillActionBindings[]), "Mouse3");
    strcopy(g_SkillActionBindings[SkillAction_Secondary], sizeof(g_SkillActionBindings[]), "Mouse4");
    strcopy(g_SkillActionBindings[SkillAction_Tertiary], sizeof(g_SkillActionBindings[]), "Mouse5");
    strcopy(g_SkillActionBindings[SkillAction_Deploy], sizeof(g_SkillActionBindings[]), "Z");
}

void LoadSkillActionBindings()
{
    ResetSkillActionBindings();

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), SKILL_ACTION_BIND_CONFIG);
    if (!FileExists(path))
    {
        return;
    }

    KeyValues kv = new KeyValues("RageSkillActionBinds");
    if (!kv.ImportFromFile(path))
    {
        delete kv;
        return;
    }

    for (int i = 0; i < view_as<int>(SkillActionSlot_Count); i++)
    {
        char value[64];
        kv.GetString(g_SkillActionKeys[i], value, sizeof(value), "");
        if (value[0] != '\0')
        {
            strcopy(g_SkillActionBindings[i], sizeof(g_SkillActionBindings[]), value);
        }
    }

    delete kv;
}

void GetSkillActionBindingLabel(SkillActionSlot slot, char[] buffer, int maxlen)
{
    buffer[0] = '\0';
    int slotIndex = view_as<int>(slot);
    if (slotIndex < 0 || slotIndex >= view_as<int>(SkillActionSlot_Count))
    {
        return;
    }

    strcopy(buffer, maxlen, g_SkillActionBindings[slotIndex]);
}
