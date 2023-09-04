// ------------------------------------------------------------
// Yokai
// ------------------------------------------------------------
class Yokai:HDMobBase{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Yokai"
		//$Sprite "YOKAA0"

		monster;
		+nodamagethrust +noblooddecals +nogravity +floatbob +float -solid
		+forcexybillboard
		+notrigger
		+hdmobbase.noshootablecorpse
		+hdmobbase.novitalshots
		height 42;radius 10;
		renderstyle "Subtract";
		tag "$TAG_YOKAI";
		maxtargetrange 666;
		bloodtype "NullPuff";
		obituary "$OB_YOKAI";
		speed 1;
		scale 0.6;
		health 66;
		painchance 240;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_GiveInventory("ImmunityToFire");
	}
	override void tick(){
		super.tick();
		if(isfrozen())return;
		if(!(level.time&(1|2|4))){
			A_Trail();
			A_HurtTarget();
		}else{
			scale.x=frandom(0.660,0.672);
			scale.y=scale.x;
			alpha=clamp(alpha+frandom(-0.05,0.04),0,0.01*health);
		}
	}
	void A_HurtTarget(){
		if(SquadGhost(target)){
			A_Die();
			return;
		}
		if(
			!target
			||target.health<1
			||distance3dsquared(target)>(300*300)
			||!checksight(target)
		)return;

		alpha=min(alpha+0.06,max(frandom(0.6,0.9),alpha-0.05));
		GiveBody(4);

		target.A_StartSound("yokai/sight",666,CHANF_OVERLAP,volume:0.4,pitch:0.5);
		IsMoving.Give(target,2);
		target.damagemobj(
			self,self,
			1,!random(0,63)?"balefire":"internal",
			DMG_NO_ARMOR
		);
		if(
			target.health>0
			&&random(0,3)
			&&absangle(target.angle,target.angleto(self))>20
		)target.givebody(1);
	}
	states{
	spawn:
		YOKA ABCD 6 A_HDLook();
		loop;
	see:
		#### ABCD 4{
			vel.z+=frandom(-0.1,0.1);
			A_HDChase();
		}loop;
	pain:
		---- A 0{
			if(!target)return;
			alpha=0;
			setorigin((target.pos.xy-(cos(target.angle),sin(target.angle)),target.pos.z+target.height-height),false);
			angle=target.angle+180;
			speed*=10.;
			bfrightened=true;
			for(int i=0;i<40;i++)A_Chase(null,null);
			bfrightened=false;
			for(int i=0;i<40;i++)A_Wander();
			speed*=0.1;
		}
		goto see;
	death:
		TNT1 A 1;
		stop;
	}
}
class YokaiSpawner:HDActor{
	default{
		+ismonster -countkill +noblockmap +frightened
		+nogravity +float +lookallaround -telestomp
		speed 32;health 1;
		radius 18;height 24;
		translation "176:191=29:47","192:207=160:167","240:247=188:191";
		scale 0.666;
	}
	states{
	spawn:
		TNT1 A 0 nodelay A_JumpIf(!sv_nomonsters,"spawn2");
		stop;
	spawn2:
		TNT1 A 10 A_Look();
		loop;
	see:
		TNT1 A 1{
			A_Chase(null,null);
			setz(frandom((ceilingz+floorz)*0.5,ceilingz-height));

			if(!target)setstatelabel("spawn2");
			else if(!checksight(target)||distance3d(target)>512)setstatelabel("drop");  
		}loop;
	drop:
		TNT1 A 1 A_SetTics(random(210,700));
		TNT1 A 0{
			A_FaceTarget();
			vel=(0,0,0);
			A_SetTranslucent(0.1,1);
		}
		PINS ABCD 1 bright A_FadeIn(0.1);
		TNT1 A 1 A_SpawnItemEx("Yokai",zvel:-4,
			flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		stop;
	}
}

