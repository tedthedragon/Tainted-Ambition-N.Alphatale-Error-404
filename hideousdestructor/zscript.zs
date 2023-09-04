// HD's main ZScript lump.

version "4.10"

const HDCONST_TAU = 6.2831853;
const HDCONST_SQRTTWO = 1.41421356;
const HDCONST_ONEOVERSQRTTWO = 0.70710678;
const HDCONST_TICFRAC=1./Object.TICRATE;

//assume 175cm, find 1cm, multiply by 100, multiply standard Doom pixel height.
const HDCONST_PLAYERHEIGHT = 54.;
const HDCONST_DEFAULTHEIGHTCM = 175.;
const HDCONST_ONEMETRE = HDCONST_PLAYERHEIGHT*120./HDCONST_DEFAULTHEIGHTCM;
const HDCONST_MPSTODUPT = HDCONST_ONEMETRE*HDCONST_TICFRAC;
const HDCONST_MPSTOKPH = 3.6;
const HDCONST_SPEEDOFSOUND = HDCONST_MPSTODUPT*350.;
const HDCONST_GRAVITY = HDCONST_MPSTODUPT*HDCONST_TICFRAC*1.2*9.81;

const HDCONST_MINDISTANTSOUND = HDCONST_ONEMETRE*3.; //this is an engine issue, don't use metrics

const SXF_ABSOLUTE=SXF_NOCHECKPOSITION|SXF_ABSOLUTEANGLE|SXF_ABSOLUTEPOSITION;

const HDCONST_426MAGMSG = "Reloading a 4.26 UAC Standard magazine into another firearm without authorization is a breach of the Volt End User License Agreement.";

//for calculating where the gun is on a body
const HDCONST_EYEHEIGHT=0.92;
const HDCONST_MINEYERANGE=HDCONST_PLAYERHEIGHT*18*(1./54);
const HDCONST_GUNPOSOFFSET=10;



#include "zscript/function.zs"
#include "zscript/maptweaks.zs"

#include "zscript/weapon.zs"

#include "zscript/commands.zs"

#include "zscript/fire.zs"
#include "zscript/effect.zs"
#include "zscript/bullet.zs"
#include "zscript/slowprojectile.zs"
#include "zscript/doorbuster.zs"

#include "zscript/player.zs"
#include "zscript/pl_ticker.zs"
#include "zscript/pl_skins.zs"
#include "zscript/pl_turn.zs"
#include "zscript/pl_extras.zs"
#include "zscript/pl_move.zs"
#include "zscript/pl_heart.zs"
#include "zscript/pl_damage.zs"
#include "zscript/pl_lives.zs"
#include "zscript/pl_crawl.zs"
#include "zscript/pl_death.zs"
#include "zscript/pl_respawn.zs"
#include "zscript/pl_invhandling.zs"
#include "zscript/pl_encumbrance.zs"
#include "zscript/pl_loadout.zs"
#include "zscript/pl_cheat.zs"

#include "zscript/tips.zs"

#include "zscript/flagpole.zs"

#include "zscript/pickup.zs"
#include "zscript/miscpickups.zs"
#include "zscript/magammo.zs"

#include "zscript/statusbar.zs"
#include "zscript/statusweapons.zs"
#include "zscript/crosshair.zs"

#include "zscript/explosion.zs"
#include "zscript/fireball.zs"

#include "zscript/wounds.zs"
#include "zscript/woundfixer.zs"
#include "zscript/medikit.zs"
#include "zscript/selfbandage.zs"
#include "zscript/injectors.zs"
#include "zscript/potion.zs"
#include "zscript/bloodpack.zs"

#include "zscript/wornitems.zs"
#include "zscript/armour.zs"
#include "zscript/radsuit.zs"
#include "zscript/liteamp.zs"
#include "zscript/jetpack.zs"
#include "zscript/ied.zs"
#include "zscript/ladder.zs"
#include "zscript/backpack.zs"
#include "zscript/blursphere.zs"
#include "zscript/squadghost.zs"

#include "zscript/ammo_9.zs"
#include "zscript/ammo_355.zs"
#include "zscript/ammo_12.zs"
#include "zscript/ammo_426.zs"
#include "zscript/ammo_776.zs"
#include "zscript/ammo_bat.zs"
#include "zscript/magmanager.zs"

//these must be arranged bulkiest to lightest
#include "zscript/wep_bfg.zs"
#include "zscript/wep_vulcanette.zs"
#include "zscript/wep_launcher.zs"
#include "zscript/wep_rocket.zs"
#include "zscript/wep_bossrifle.zs"
#include "zscript/wep_thunderbuster.zs"
#include "zscript/wep_liberator.zs"
#include "zscript/wep_brontornis.zs"
#include "zscript/wep_shotguns.zs"
#include "zscript/wep_hunter.zs"
#include "zscript/wep_slayer.zs"
#include "zscript/wep_chainsaw.zs"
#include "zscript/wep_zm66.zs"
#include "zscript/wep_smg.zs"
#include "zscript/wep_revolver.zs"
#include "zscript/wep_pistol.zs"
#include "zscript/wep_fist.zs"


#include "zscript/wep_tripwires.zs"
#include "zscript/wep_grenade.zs"

#include "zscript/derp.zs"
#include "zscript/herp.zs"
#include "zscript/chunkflick.zs"


#include "zscript/shields.zs"
#include "zscript/mob.zs"
#include "zscript/mob_damage.zs"
#include "zscript/mob_ai.zs"
#include "zscript/mob_ai_static.zs"
#include "zscript/mob_attack.zs"
#include "zscript/mob_names.zs"

#include "zscript/mob_barrel.zs"
#include "zscript/mob_putto.zs"
#include "zscript/mob_yokai.zs"

#include "zscript/mob_operator.zs"
#include "zscript/mob_zomrifle.zs"
#include "zscript/mob_zomshotgun.zs"
#include "zscript/mob_zomvulc.zs"
#include "zscript/mob_zomnazi.zs"
#include "zscript/mob_zompist.zs"

#include "zscript/mob_serpentipede.zs"
#include "zscript/mob_babuin.zs"
#include "zscript/mob_spectre.zs"
#include "zscript/mob_trilobite.zs"
#include "zscript/mob_hatchling.zs"
#include "zscript/mob_painlord.zs"

#include "zscript/mob_painbringer.zs"
#include "zscript/mob_boner.zs"
#include "zscript/mob_combatslug.zs"
#include "zscript/mob_technospider.zs"
#include "zscript/mob_necromancer.zs"

#include "zscript/mob_tripod.zs"
#include "zscript/mob_technorantula.zs"
#include "zscript/mob_bossbrain.zs"
#include "zscript/mob_stealthmonsters.zs"


#include "zscript/decorations.zs"

#include "zscript/range.zs"

#include "zscript/menu.zs"


