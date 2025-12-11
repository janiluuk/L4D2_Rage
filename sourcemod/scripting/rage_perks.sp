#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "Rage Perks"

#include <sourcemod>
#include <perks.inc>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvPerksEnabled;
bool g_bPerksEnabled = true;

Handle g_hThisPlugin = null; // Store plugin handle from AskPluginLoad2

// Note: g_PerkAppliedForward and g_PerkRemovedForward are already defined in perks.inc

public Plugin myinfo =
{
    name = "[Rage] Perks System",
    author = "Yani",
    description = "Admin perk management system with creative combinations",
    version = PLUGIN_VERSION,
    url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Register library and natives early so other plugins can use them
    RegPluginLibrary("rage_perks");
    CreateNative("RagePerks_ShowMenu", Native_ShowPerkMenu);
    CreateNative("RagePerks_IsAvailable", Native_IsAvailable);
    
    // Store plugin handle for use in OnPluginStart
    g_hThisPlugin = myself;
    
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvPerksEnabled = CreateConVar("rage_perks_enabled", "1", "Enable/disable the perks system", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvPerksEnabled.AddChangeHook(OnPerksEnabledChanged);
    g_bPerksEnabled = g_cvPerksEnabled.BoolValue;
    
    // Initialize forwards if not already initialized (they're declared in perks.inc as GlobalForward)
    // These forwards are used by base.inc to notify when perks are applied/removed
    // Note: GlobalForward is a Handle type, so we check for null
    // Only create forwards if they don't already exist (may be created by another plugin)
    bool createdAppliedForward = false;
    bool createdRemovedForward = false;
    
    if (g_PerkAppliedForward == null)
    {
        g_PerkAppliedForward = CreateGlobalForward("OnPerkApplied", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);
        createdAppliedForward = (g_PerkAppliedForward != null && g_PerkAppliedForward != INVALID_HANDLE);
    }
    if (g_PerkRemovedForward == null)
    {
        g_PerkRemovedForward = CreateGlobalForward("OnPerkRemoved", ET_Ignore, Param_Cell, Param_String);
        createdRemovedForward = (g_PerkRemovedForward != null && g_PerkRemovedForward != INVALID_HANDLE);
    }
    
    // Hook into perk forwards to show hints when perks are applied/removed
    // Note: We register our callbacks to receive notifications when perks are applied/removed
    // The forwards are called by base.inc when perks change
    // Only add to forwards if they already existed (were created by another plugin)
    // If we just created them, skip adding ourselves - the forward might not be ready yet
    // We'll add ourselves using a timer callback to ensure the forward is fully initialized
    if (!createdAppliedForward && g_PerkAppliedForward != null && g_PerkAppliedForward != INVALID_HANDLE && g_hThisPlugin != null && g_hThisPlugin != INVALID_HANDLE)
    {
        AddToForward(g_PerkAppliedForward, g_hThisPlugin, OnPerkApplied);
    }
    // Note: If we created the forward, we skip adding ourselves - the forward system will handle it
    
    if (!createdRemovedForward && g_PerkRemovedForward != null && g_PerkRemovedForward != INVALID_HANDLE && g_hThisPlugin != null && g_hThisPlugin != INVALID_HANDLE)
    {
        // Forward already existed - add ourselves immediately
        AddToForward(g_PerkRemovedForward, g_hThisPlugin, OnPerkRemoved);
    }
    // Note: If we created the forward, we skip adding ourselves - the forward system will handle it
    
    // Initialize perks system
    SetupPerks();
    SetupsPerkCombos();
    LoadConfigCombos();
    
    // Register test command
    RegAdminCmd("sm_perks_test", Command_PerkTest, ADMFLAG_ROOT, "Run validation tests on the perks system");
}

public void OnPerksEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bPerksEnabled = g_cvPerksEnabled.BoolValue;
}

public int Native_ShowPerkMenu(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    bool isComboList = GetNativeCell(2);
    
    if (!g_bPerksEnabled || !IsValidClient(client))
    {
        return 0;
    }
    
    ShowPerkMenu(client, isComboList);
    return 1;
}

public int Native_IsAvailable(Handle plugin, int numParams)
{
    return g_bPerksEnabled ? 1 : 0;
}

// Load combos from config file
void LoadConfigCombos()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rage_perk_combos.cfg");
    
    if (!FileExists(sPath))
    {
        // Create default config file
        CreateDefaultComboConfig(sPath);
        return;
    }
    
    KeyValues kv = new KeyValues("PerkCombos");
    if (!kv.ImportFromFile(sPath))
    {
        delete kv;
        LogError("[Rage Perks] Failed to load combo config from %s", sPath);
        return;
    }
    
    if (kv.JumpToKey("Combos", false))
    {
        if (kv.GotoFirstSubKey(false))
        {
            do
            {
                char comboName[64];
                kv.GetSectionName(comboName, sizeof(comboName));
                
                PerkCombo combo;
                SetupCombo(combo, comboName);
                
                // Load perks for this combo
                if (kv.GotoFirstSubKey(false))
                {
                    do
                    {
                        char perkName[64];
                        kv.GetSectionName(perkName, sizeof(perkName));
                        
                        int flags = kv.GetNum("flags", 0);
                        char modStr[16];
                        kv.GetString("modifier", modStr, sizeof(modStr), "");
                        
                        perkModifier mod = PerkMod_Invalid;
                        if (StrEqual(modStr, "instant", false))
                            mod = PerkMod_Instant;
                        else if (StrEqual(modStr, "constant", false))
                            mod = PerkMod_Constant;
                        else if (StrEqual(modStr, "both", false))
                            mod = view_as<perkModifier>(PerkMod_Instant | PerkMod_Constant);
                        
                        combo.AddPerk(perkName, flags, mod);
                    }
                    while (kv.GotoNextKey(false));
                    kv.GoBack();
                }
            }
            while (kv.GotoNextKey(false));
        }
        kv.GoBack();
    }
    
    delete kv;
    LogMessage("[Rage Perks] Loaded combos from config");
}

void CreateDefaultComboConfig(const char[] path)
{
    KeyValues kv = new KeyValues("PerkCombos");
    kv.JumpToKey("Combos", true);
    
    // Example combo
    kv.JumpToKey("Chaos Mode", true);
    kv.JumpToKey("Special Magnet", true);
    kv.SetNum("flags", 0);
    kv.SetString("modifier", "constant");
    kv.GoBack();
    kv.JumpToKey("Tank Magnet", true);
    kv.SetNum("flags", 0);
    kv.SetString("modifier", "constant");
    kv.GoBack();
    kv.JumpToKey("Slow Speed", true);
    kv.SetNum("flags", 4); // 50% speed
    kv.SetString("modifier", "constant");
    kv.GoBack();
    kv.GoBack();
    
    kv.ExportToFile(path);
    delete kv;
    LogMessage("[Rage Perks] Created default combo config at %s", path);
}

// Hook into perk application to show hints
public void OnPerkApplied(int victim, const char[] perkName, int flags, int activator)
{
    if (!g_bPerksEnabled || !IsValidClient(victim))
        return;
    
    char activatorName[64] = "System";
    if (IsValidClient(activator) && activator != victim)
    {
        GetClientName(activator, activatorName, sizeof(activatorName));
        PrintHintText(victim, "Perk Applied: %s\nApplied by: %s", perkName, activatorName);
    }
    else
    {
        PrintHintText(victim, "Perk Applied: %s", perkName);
    }
}

// Note: Timer_AddToForwards is no longer used - we don't add ourselves to forwards we create
// The forwards are for other plugins to hook into. base.inc will call the forwards,
// and if we need to be notified, we can hook into the forward calls directly or
// be called by base.inc when it processes perk changes.

// Hook into perk removal to show hints
public void OnPerkRemoved(int victim, const char[] perkName)
{
    if (!g_bPerksEnabled || !IsValidClient(victim))
        return;
    
    PrintHintText(victim, "Perk Removed: %s", perkName);
}

