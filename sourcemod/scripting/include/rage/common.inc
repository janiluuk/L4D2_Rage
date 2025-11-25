#if defined _rage_common_included
 #endinput
#endif
#define _rage_common_included

/**
 * Common constants shared across Rage plugins to reduce duplication
 */

// Common sound effects used across multiple plugins
#define SOUND_EXPLODE3		"weapons/hegrenade/explode3.wav"
#define SOUND_EXPLODE4		"weapons/hegrenade/explode4.wav"
#define SOUND_EXPLODE5		"weapons/hegrenade/explode5.wav"

// Special Infected type constants (for plugins that need them)
// Note: Use L4D2_Team enum from left4dhooks for team constants
#define SI_SMOKER 	1
#define SI_BOOMER 	2
#define SI_HUNTER 	3
#define SI_SPITTER  4
#define SI_JOCKEY 	5
#define SI_CHARGER  6
#define SI_TANK 	7
