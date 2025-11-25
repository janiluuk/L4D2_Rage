/**
 * L4D2 Predicaments Plugin - Include File
 * 
 * Provides forwards and natives for controlling healing and struggle mechanics
 * 
 * Forward Hooks:
 * - Predicaments_OnCanHealOthers: Called when a survivor attempts to heal another
 * - Predicaments_OnCanStruggle: Called when a pinned survivor attempts to struggle
 */

#if defined _l4d2_predicaments_included
 #endinput
#endif
#define _l4d2_predicaments_included

/**
 * Called when a survivor attempts to heal another incapacitated survivor
 *
 * @param client        The client attempting to heal
 * @param target        The target being healed
 * @param canHeal       Reference to bool - set to false to prevent healing
 * @return              Plugin_Handled/Plugin_Stop to apply your decision, Plugin_Continue otherwise
 */
forward Action Predicaments_OnCanHealOthers(int client, int target, bool &canHeal);

/**
 * Called when a pinned survivor attempts to struggle
 *
 * @param client        The client attempting to struggle
 * @param canStruggle   Reference to bool - set to false to prevent struggling
 * @return              Plugin_Handled/Plugin_Stop to apply your decision, Plugin_Continue otherwise
 */
forward Action Predicaments_OnCanStruggle(int client, bool &canStruggle);

/**
 * Check if a client can heal another client
 *
 * @param client        The client attempting to heal
 * @param target        The target being healed
 * @return              True if allowed, false otherwise
 */
native bool Predicaments_CanHealOthers(int client, int target);

/**
 * Check if a client can struggle when pinned by an infected
 *
 * @param client        The client attempting to struggle
 * @return              True if allowed, false otherwise
 */
native bool Predicaments_CanStruggle(int client);

public SharedPlugin __pl_l4d2_predicaments = 
{
	name = "l4d2_predicaments",
	file = "l4d2_predicaments.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_predicaments_SetNTVOptional()
{
	MarkNativeAsOptional("Predicaments_CanHealOthers");
	MarkNativeAsOptional("Predicaments_CanStruggle");
}
#endif
