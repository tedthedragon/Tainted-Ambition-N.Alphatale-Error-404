// ------------------------------------------------------------
// Lizard baby in a tube
// HD's version of this https://forum.zdoom.org/viewtopic.php?f=46&t=75780
// ------------------------------------------------------------

class HDLizardJar:HDActor replaces CommanderKeen{
	default{
		health 100;
		radius 16;
		height 68;
		deathheight 68;
		mass 10000000;
		painchance 256;
		+solid
		+spawnceiling
		+ceilinghugger
		+nogravity
		+nodamagethrust
		+dontfall
		+shootable
		+countkill
		+noicedeath
		+ismonster
		+noblood
		+nospriteshadow
		painsound "keen/pain";
		deathsound "keen/death";
	}
	override void postbeginplay(){
		super.postbeginplay();
		setz(ceilingz-height);
	}
	states{
	spawn:
		KEEN A -1;
		wait;
	pain:
		KEEN M 2 {if(health<50)bnoblood=false;}
		KEEN M 1 bright A_Pain();
		KEEN M 2 A_StartSound("misc/freeze",CHAN_BODY,CHANF_OVERLAP,volume:0.3,pitch:1.2+0.004*health);
		goto spawn;
	death:
		KEEN B 2 A_Scream();
		KEEN C 2 A_StartSound("misc/icebreak",CHAN_BODY,CHANF_OVERLAP,pitch:1.2);
		KEEN D 2{
			A_NoBlocking();

			A_SetTranslation(!random(0,4)?"BrownLBB":!random(0,3)?"TanLBB":!random(0,2)?"OliveLBB":!random(0,1)?"WhiteLBB":"none");

			for(int i=0;i<20;i++){
				let spw=spawn(
					"HugeWallChunk",pos+(
						frandom(-radius,radius),
						frandom(-radius,radius),
						frandom(0,height-24)
					)
				);
				if(spw){
					spw.scale*=frandom(1.3,2.4);
					spw.vel=(frandom(-1,1),frandom(-1,1),-getgravity()-frandom(0,1));
					spw.bwallsprite=true;
					spw.angle=frandom(0,360);
					spw.A_SetRenderStyle(frandom(0.6,0.8),STYLE_Translucent);
					spw.A_SetTranslation("AllRed");
					if(!(i&(1|2|4)))spw.A_StartSound("misc/glassbreak",10,CHANF_OVERLAP);
				}
			}
		}
		KEEN E 2;
		KDRP A 40{
			let rrr=spawn("HDJarGoop",(pos.xy,pos.z-3),ALLOW_REPLACE);
			if(!rrr)return;
			rrr.vel.z=-getgravity()*2.;
		}
		KDRP B 50{
			let bb=hdmobbase(spawn("HDJarLizard",(pos.xy,pos.z+(64-34)),ALLOW_REPLACE));
			if(!bb)return;
			if(!!target&&!!target.player)bb.friendplayer=target.playernumber()+1;
			bb.translation=translation;
			bb.vel.z+=getgravity()*1.5;
			bb.scale.x=randompick(-1,1);
			bb.resize(0.95,1.05);
		}
		KDRP B 0 A_KeenDie();
		KDRP B random(30,300){
			HDF.Particle(self,
				"darkred",(pos.xy+(frandom(-5,5),frandom(-5,5)),pos.z+frandom(50,54)),
				150,
				size:frandom(3.,6.),
				accel:(0,0,-gravity)
			);
		}
		wait;
	}
}
class HDJarLizard:HDMobBase{
	default{
		+friendly
		+noblockmap
		-shootable
		+castspriteshadow
		height 21;
		radius 9;

		speed 2;
		maxdropoffheight 1024;
		maxstepheight 3;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		spawn("TeleportFog",pos,ALLOW_REPLACE);
		setstatelabel("disappear");
		return -1;
	}
	states{
	spawn:
	fall:
		LBBY A 0 nodelay A_JumpIf(floorz>=pos.z,"sit");
		LBBY AAAB 3 A_JumpIf(floorz>=pos.z,"splat");
		wait;
	splat:
		LBBY A 0 A_StartSound("misc/mobland",CHAN_BODY,CHANF_OVERLAP,volume:0.5);
		LBBY CDE 3;
	sit:
		LBBY E 1 A_SetTics(random(random(6,40),100));
		LBBY F random(2,3) A_Jump(42,"think","stretch","stretch","creep");
		loop;
	stretch:
		LBBY FD 4;
		LBBY C 1 A_SetTics(random(20,60));
		LBBY DF 6;
		goto sit;
	creep:
		LBBY FDCDE 4 A_HDWander();
		LBBY F 0 A_Jump(128,"creep");
		goto sit;
	think:
		LBBY F 20;
		LBBY F 0{
			speed=17.;
			maxstepheight=1024;
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					playeringame[i]
					&&!!players[i].mo
					&&!(
						abs(players[i].mo.pitch)<70
						&&absangle(players[i].mo.angle,players[i].mo.angleto(self))>150
					)
					&&players[i].mo.checksight(self)
				){
					spawn("TeleportFog",pos,ALLOW_REPLACE);
					return;
				}
			}
		}
	disappear:
		TNT1 AAAAAAAAA 10 A_Wander();
		TNT1 A 10{
			int fp=friendplayer-1;
			if(
				fp>=0
				&&fp<MAXPLAYERS
				&&playeringame[fp]
				&&!!players[fp].mo
				&&!random(0,7)
			){
				bnogravity=true;
				bfloat=true;
				setorigin(players[fp].mo.pos,false);
				return;
			}
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					playeringame[i]
					&&!!players[i].mo
					&&!(
						abs(players[i].mo.pitch)<70
						&&absangle(players[i].mo.angle,players[i].mo.angleto(self))>150
					)
					&&players[i].mo.checksight(self)
				){
					return;
				}
			}
			bnogravity=false;
			bfloat=false;
			speed=default.speed;
			maxstepheight=default.maxstepheight;
			setstatelabel("fall");
		}
		loop;
	}
}
class HDJarGoop:HDActor{
	default{
		-solid
		-shootable
		+noblockmap
		+castspriteshadow
		height 8;
		radius 16;
	}
	void A_SplashBlood(){
		int gbg;actor bld;
		[gbg,bld]=A_SpawnItemEx("BloodSplatSilent",
			frandom(0,radius),0,(frame==5?0:frandom(0,height-20)),
			frandom(0,1),0,frandom(2,4)*getgravity(),
			frandom(0,360),
			SXF_NOCHECKPOSITION
		);
	}
	states{
	spawn:
	fall:
		KSPL A 2 A_JumpIf(floorz>=pos.z,"splat");
		wait;
	splat:
		KSPL B 0{
			A_StartSound("misc/gibbed",pitch:1.8);
			bcastspriteshadow=false;
		}
		KSPL BBCCDDEEFF 2 A_SplashBlood();
		KSPL FFFFFFF 4 A_SplashBlood();
		KSPL F -1;
		stop;
	}
}
