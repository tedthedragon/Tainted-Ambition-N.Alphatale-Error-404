// ------------------------------------------------------------
// Shotgun Shells
// ------------------------------------------------------------
class HDShellAmmo:HDRoundAmmo{
	default{
		+inventory.ignoreskill
		+hdpickup.multipickup
		inventory.pickupmessage "$PICKUP_ShotgunShell";
		scale 0.3;
		tag "$TAG_SHOTGUNSHELLS";
		hdpickup.refid HDLD_SHOTSHL;
		hdpickup.bulk ENC_SHELL;
		inventory.icon "SHELA0";
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(4,20,"ShellBoxPickup","SHELA0","SHL1A0");
	}
	override string pickupmessage(){
		if(amount>1)return Stringtable.Localize("$PICKUP_ShotgunShellPlural");
		return super.pickupmessage();
	}
	states{
	spawn:
		SHL1 A -1;
		stop;
	death:
		ESHL A -1{
			HDSpentShell.FDShellTranslate(self);
			frame=randompick(0,0,0,0,4,4,4,4,2,2,5);
		}stop;
	}
}
class HDSpentShell:HDDebris{
	default{
		-noteleport +forcexybillboard
		seesound "misc/casing2";scale 0.3;height 2;radius 2;
		bouncefactor 0.5;
	}
	static void FDShellTranslate(actor caller){
		if(
			Wads.CheckNumForName("id",0)==-1
			&&!HDMath.CheckLumpReplaced("ESHLA0",Wads.AnyNamespace)
		)caller.A_SetTranslation("FreeShell");
	}
	override void postbeginplay(){
		super.postbeginplay();
		FDShellTranslate(self);
		if(vel==(0,0,0))A_ChangeVelocity(0.0001,0,-0.1,CVF_RELATIVE);
	}
	vector3 lastvel;
	override void Tick(){
		if(!isFrozen())lastvel=vel;
		super.Tick();
	}
	states{
	spawn:
		ESHL ABCDEFGH 2;
		loop;
	death:
		ESHL A -1{
			frame=randompick(0,0,0,0,4,4,4,4,2,2,5);
		}stop;
	}
}
//a shell that can be caught in hand, launched from the Slayer
class HDUnSpentShell:HDSpentShell{
	states{
	spawn:
		ESHL ABCDE 2;
		TNT1 A 0{
			if(A_JumpIfInTargetInventory("HDShellAmmo",0,"null"))
			A_SpawnItemEx("HDFumblingShell",
				0,0,0,vel.x+frandom(-1,1),vel.y+frandom(-1,1),vel.z,
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);else A_GiveToTarget("HDShellAmmo",1);
		}
		stop;
	}
}
//any other single shell tumblng out
class HDFumblingShell:HDSpentShell{
	default{
		bouncefactor 0.3;
	}
	states{
	spawn:
		ESHL ABCDEFGH 2;
		loop;
	death:
		TNT1 A 0{
			let sss=spawn("HDShellAmmo",pos);
			sss.vel.xy=lastvel.xy+lastvel.xy.unit()*abs(lastvel.z);
			sss.setstatelabel("death");
			if(sss.vel.x||sss.vel.y){
				sss.A_FaceMovementDirection();
				sss.angle+=90;
				sss.frame=randompick(0,4);
			}else sss.frame=randompick(0,0,0,4,4,4,2,2,5);
			inventory(sss).amount=1;
		}stop;
	}
}


class ShellBoxPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of Shotgun Shells"
		//$Sprite "SBOXA0"
		scale 0.4;
		hdupk.amount 20;
		hdupk.pickupsound "weapons/pocket";
		hdupk.pickupmessage "$PICKUP_ShotgunShell2";
		hdupk.pickuptype "HDShellAmmo";
	}
	states{
	spawn:
		SBOX A -1 nodelay{
			if(Wads.CheckNumForName("id",0)==-1)scale=(0.25,0.25);
			if(!HDMath.CheckLumpReplaced("SBOXA0",Wads.AnyNamespace))A_SetTranslation("GreyShell");
		}
	}
}
class ShellPickup:IdleDummy{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Four Shotgun Shells"
		//$Sprite "SHELA0"
	}
	states{
	spawn:
		SHEL A 0 nodelay{
			let iii=hdpickup(spawn("HDShellAmmo",pos,ALLOW_REPLACE));
			if(iii){
				hdf.transferspecials(self,iii,hdf.TS_ALL);
				iii.amount=4;
			}
		}stop;
	}
}
