//Stuff specific to Freedoom
version "4.8"

#include "zscript/mob_lizardbaby.zs"


//add pistol zombie
class ZombieHideousFreeTrooper:RandomSpawner replaces ZombieHideousTrooper{
	default{
		dropitem "ZombieAutoStormtrooper",256,100;
		dropitem "ZombieSemiStormtrooper",256,20;
		dropitem "ZombieSMGStormtrooper",256,10;
		dropitem "UndeadHomeboy",256,14;
		dropitem "EnemyHERP",256,1;
	}
}



//otherwise the casting call would show the demonicron sprite
class FreeWormCC:Demon{
	default{
		scale 0.6;
		translation "16:47=48:79";
	}
	states{
	see:
		SARG ABCD 4;
		loop;
	melee:
		SARG E 6;
		SARG F 8;
		SARG G 12;
		goto see;
	death:
		SARG I 5 A_Scream();
		SARG JKLM 5;
		SARG N 40;
		stop;
	}
}
class FreePistolZombieCC:ShotgunGuy{
	states{
	see:
		POSS ABCDABCD 3;
		loop;
	missile:
		POSS E 7;
		POSS F 1;
		POSS E 4;
		POSS F 1;
		POSS E 5;
		POSS F 1;
		POSS E 10;
		goto see;
	death:
		POSS H 5 A_Scream();
		POSS IJK 5;
		POSS L 40;
		stop;
	}
}
class FreeZombieCC:ShotgunGuy{
	default{
		translation "FreedoomGreycoat";
	}
	states{
	see:
		SPOS ABCD 4;
		loop;
	missile:
		SPOS E 10;
		SPOS F 1;
		SPOS E 2;
		SPOS F 1;
		SPOS E 2;
		SPOS F 1;
		SPOS E 10;
		goto see;
	death:
		SPOS H 5 A_Scream();
		SPOS IJK 5;
		SPOS L 40;
		stop;
	}
}


