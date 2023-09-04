// ------------------------------------------------------------
// Stealth monster replacements
// ------------------------------------------------------------
class HDStealthPorter:Actor{
	class<actor>spawntype;
	property spawntype:spawntype;
	default{
		+ismonster
		+lookallaround
		maxtargetrange 512;
		speed 10;
		hdstealthporter.spawntype "";
		maxstepheight 128;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(!spawntype){
			A_SpawnItemEx("NinjaPirate",
				flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_TRANSFERAMBUSHFLAG
			);
			destroy();
			return;
		}
		A_SetSize(
			getdefaultbytype(spawntype).radius,
			getdefaultbytype(spawntype).height
		);
		speed=radius;
	}
	void A_CheckPortIn(){
		if(
			target
			&&absangle(target.angleto(self),target.angle)>90
		){
			let aaa=spawn(spawntype,pos,ALLOW_REPLACE);
			if(!aaa)return;

			HDF.TransferSpecials(self,aaa,HDF.TS_ANGLE);
			aaa.target=target;
			let hdm=hdmobbase(aaa);
			if(hdm)hdm.A_Vocalize(hdm.seesound);
			else hdm.A_StartSound(hdm.seesound,CHAN_VOICE);

			spawn("TeleFog",pos,ALLOW_REPLACE);
			A_AlertMonsters();

			destroy();
			return;
		}else A_Wander();
	}
	states{
	spawn:
		TNT1 A 10 A_Look();
		loop;
	see:
		TNT1 A 4 A_Chase();
		loop;
	missile:
		TNT1 A 4 A_CheckPortIn();
		---- A 0 setstatelabel("see");
	}
}
class HDStealthArachnotron:HDStealthPorter replaces StealthArachnotron{
	default{hdstealthporter.spawntype "TechnoSpider";}
}
class HDStealthArchvile:HDStealthPorter replaces StealthArchvile{
	default{hdstealthporter.spawntype "Necromancer";}
}
class HDStealthBaron:HDStealthPorter replaces StealthBaron{
	default{hdstealthporter.spawntype "PainLord";}
}
class HDStealthCacodemon:HDStealthPorter replaces StealthCacodemon{
	default{
		+float
		hdstealthporter.spawntype "Trilobite";
	}
}
class HDStealthChaingunGuy:HDStealthPorter replaces StealthChaingunGuy{
	default{hdstealthporter.spawntype "VulcanetteZombie";}
}
class StealthPortBabuin:HDStealthPorter{
	default{hdstealthporter.spawntype "Babuin";}
}
class HDStealthDemon:RandomSpawner replaces StealthDemon{
	default{
		+ismonster
		dropitem "NinjaPirate",256,20;
		dropitem "SpecBabuin",256,5;
		dropitem "StealthPortBabuin",256,4;
		dropitem "ShellShade",256,1;
	}
}
class HDStealthHellKnight:HDStealthPorter replaces StealthHellKnight{
	default{hdstealthporter.spawntype "PainBringer";}
}
class HDStealthDoomImp:HDStealthPorter replaces StealthDoomImp{
	default{hdstealthporter.spawntype "Serpentipede";}
}
class HDStealthCombatSlug:HDStealthPorter replaces StealthFatso{
	default{hdstealthporter.spawntype "CombatSlug";}
}
class HDStealthBoner:HDStealthPorter replaces StealthRevenant{
	default{hdstealthporter.spawntype "Boner";}
}
class HDStealthRevenant:HDStealthBoner{}
class HDStealthShotgunGuy:HDStealthPorter replaces StealthShotgunGuy{
	default{hdstealthporter.spawntype "ZombieShotgunner";}
}
class HDStealthZombieMan:HDStealthPorter replaces StealthZombieMan{
	default{hdstealthporter.spawntype "ZombieStormtrooper";}
}
