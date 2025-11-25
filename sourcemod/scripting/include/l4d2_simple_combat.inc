#if defined _l4d2_simple_combat_included
 #endinput
#endif
#define _l4d2_simple_combat_included

/**
 * Optional include stub for the Simple Combat library used by satellite cannon.
 * Provides native declarations so the plugin can compile even when the library
 * is absent from the build environment.
 */

#define SIMPLE_COMBAT_VERSION "1.0"

/**
 * Registers a spell with the Simple Combat system.
 */
native void SC_CreateSpell(const char[] name, const char[] description, int cost, int cooldown, const char[] help);

/**
 * Retrieves the Simple Combat level for a client.
 */
native int SC_GetClientLevel(int client);

/**
 * Forward fired after a spell is used.
 */
forward void SC_OnUseSpellPost(int client, const char[] classname);
