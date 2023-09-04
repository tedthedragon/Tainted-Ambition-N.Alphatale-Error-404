// ------------------------------------------------------------
// Former Human
// ------------------------------------------------------------

/*
	NOTE FOR MAPPERS
	You can customize individual zombies using user_weapon.
	1=ZM66 regular; 2=ZM66 marksman; 3=SMG
*/

class ZombieStormtrooper:HDHumanoid{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman"
		//$Sprite "POSSA1"

		+floorclip
		seesound "grunt/sight";
		painsound "grunt/pain";
		deathsound "grunt/death";
		activesound "grunt/active";
		tag "$cc_zombie";

		translation "58:66=128:136","214:223=141:148","176:191=24:47","16:34=68:79";
		speed 8;
		dropitem "";attacksound "";decal "BulletScratch";
		painchance 250;
		obituary "$OB_ZOMBRIFLE";
		hitobituary "$OB_ZOMBRIFLE_HIT";
		accuracy 0;
	}
	double turnamount;
	int user_weapon;
	int mag;
	int firemode; //-2 SMG; -1 semi only; 0 semi; 1 auto; 2+ burst
	override void postbeginplay(){
		super.postbeginplay();
		if(user_weapon)accuracy=user_weapon;
		if(accuracy==1)firemode=random(0,5);
		else if(accuracy==2)firemode=-1;
		else if(accuracy==3)firemode=-2;
		else firemode=random(-2,4);
		if(firemode==-2){
			mag=random(1,30);
			A_SetTranslation("ZombieSMG");
		}else{
			mag=random(1,50);
			if(firemode>2)firemode=1;
			maxtargetrange=6000;
		}
	}
	void A_ZomFrag(){
		bool garbage;actor gg;
		double cpp=cos(pitch);double spp=sin(pitch);
		[garbage,gg]=A_SpawnItemEx("HDFragSpoon",
			cpp*-4,-3,height-6-spp*-4,
			cpp*3,0,-spp*3,
			frandom(30,45),SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		gg.vel+=self.vel;
		double gforce=frandom(10,30);
		[garbage,gg]=A_SpawnItemEx("HDFragGrenade",
			0,0,height-6,
			cpp*gforce,0,-spp*gforce,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		gg.vel+=self.vel;
	}
	override void deathdrop(){
		if(bhasdropped&&bfriendly)return;
		hdweapon wp=null;
		if(firemode==-2){
			if(!bhasdropped){
				if(wp=DropNewWeapon("HDSMG")){
					wp.weaponstatus[SMGS_AUTO]=random(0,2);
					wp.weaponstatus[SMGS_MAG]=mag;
					wp.weaponstatus[SMGS_CHAMBER]=2;
				}
				DropNewItem("HDFragGrenadeAmmo",8);
				DropNewItem("HDFragGrenadeAmmo",4);
				DropNewItem("HD9mMag30");
			}else{
				DropNewItem("HD9mMag30",240);
				DropNewItem("HD9mMag30",128);
				DropNewItem("HDFragGrenadeAmmo",4);
				DropNewItem("HDFragGrenadeAmmo",4);
			}
		}else{
			if(!bhasdropped){
				if(wp=DropNewWeapon("ZM66AssaultRifle")){
					wp.weaponstatus[0]=ZM66F_NOLAUNCHER|(random(0,1)*ZM66F_CHAMBER);
					if(firemode==-1)wp.weaponstatus[0]|=ZM66F_NOFIRESELECT;

					if(mag>=50)wp.weaponstatus[ZM66S_MAG]=51;
					else wp.weaponstatus[ZM66S_MAG]=mag;

					wp.weaponstatus[ZM66S_ZOOM]=random(16,70);

					if(jammed||!random(0,15))wp.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
					else wp.weaponstatus[ZM66S_AUTO]=clamp(firemode,0,2);
				}
			}else{
				DropNewItem("HD4mMag",96);
			}
		}
		if(!bhasdropped){
			DropNewItem("HDHandgunRandomDrop");
			bhasdropped=true;
		}
	}
	void A_CheckFreedoomSprite(){
		if(bplayingid)sprite=getspriteindex("POSS");
		else{
			sprite=getspriteindex("SPOS");
			A_SetTranslation("FreedoomGreycoat");
		}
	}
	states{
	spawn:
		POSS A 0;
		SPOS A 0 A_CheckFreedoomSprite();
	idle:
	spawn2:
		#### A 0{
			A_HDLook();
			A_Recoil(frandom(-0.1,0.1));
		}
		#### EEE 1{
			A_SetTics(random(5,17));
			A_HDLook();
		}
		#### E 1{
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
		#### B 0 A_Jump(28,"spawngrunt");
		#### B 0 A_Jump(132,"spawnswitch");
		#### B 8 A_Recoil(frandom(-0.2,0.2));
		loop;
	spawngrunt:
		#### G 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
			if(!random(0,7))A_Vocalize(activesound);
		}
		#### A 0 A_Jump(256,"spawn2");
	spawnswitch:
		#### A 0 A_JumpIf(bambush,"spawnstill");
		goto spawnwander;
	spawnstill:
		#### A 0 A_HDLook();
		#### A 0 A_Recoil(random(-1,1)*0.4);
		#### CD 5 A_SetAngle(angle+random(-4,4));
		#### A 0{
			A_HDLook();
			if(!random(0,127))A_Vocalize(activesound);
		}
		#### AB 5 A_SetAngle(angle+random(-4,4));
		#### B 1 A_SetTics(random(10,40));
		#### A 0 A_Jump(256,"spawn2");
	spawnwander:
		#### CDAB 5 A_HDWander();
		#### A 0{
			if(!random(0,127))A_Vocalize(activesound);
			A_HDLook();
		}
		#### A 0 A_Jump(64,"spawn2");
		loop;
	missile:
		#### A 0{
			if(!target){
				setstatelabel("spawn2");
				return;
			}
			double dt=distance3d(target);
			if(
				firemode==-2
				&&target
				&&!random(0,39)
				&&dt>200
				&&dt<1000
			)setstatelabel("frag");
		}
		#### ABCD 3 A_TurnToAim(40,shootstate:"aiming");
		loop;
	aiming:
		#### E 3 A_FaceLastTargetPos(30);
		#### E 1 A_StartAim(maxspread:20,maxtics:random(0,35));
		//fallthrough to shoot
	shoot:
		#### E 0 A_JumpIf(jammed,"jammed");
		#### E 0{
			pitch+=frandom(-spread,spread);
			angle+=frandom(-spread,spread);
		}
	fire:
		#### F 1 bright light("SHOT"){
			if(mag<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			if(firemode==-2){
				A_StartSound("weapons/smg",CHAN_WEAPON);
				HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
				A_EjectSMGCasing();
				pitch+=frandom(-0.2,0.1)*spread;
				angle+=frandom(-0.2,0.1)*spread;
			}else{
				A_StartSound("weapons/rifle",CHAN_WEAPON);
				HDBulletActor.FireBullet(self,"HDB_426");
				if(random(0,2000)<firemode){
					jammed=true;
					A_StartSound("weapons/rifleclick",5);
					setstatelabel("jammed");
				}
				pitch+=frandom(-spread,spread*0.5)*0.3;
				angle+=frandom(-spread*0.5,spread)*0.3;
			}

			mag--;
		}
		#### E 2{
			if(
				//conditions under which no autofire can happen
				!firemode
				||firemode==-1
				||firemode>3
				||mag<1
			){
				if(firemode>2)firemode=2;
				setstatelabel("postshot");
			}else if(
				//if burst, do not wait the tics of this frame
				firemode>=2
			){
				firemode++;
				setstatelabel("fire");
			}
			else spread++;
		}
		#### A 0 A_Jump(120,"shoot");
		//fallthrough to postshot
	postshot:
		#### E 5{
			if(!random(0,127))A_Vocalize(activesound);
			if(mag<1){
				setstatelabel("reload");
				return;
			}
			spread=max(0,spread-1);
			A_SetTics(random(2,6));
		}
		#### E 3;
		#### E 0 A_JumpIf(!hdmobai.tryshoot(self),"see");
		#### E 0 A_JumpIfTargetInLOS(1);
		goto coverfire;  //even if not in los,occasionally keep shooting anyway
		#### E 3 A_FaceTarget(10,10);
		#### E 0 A_Jump(30,"see");  //even if in los,occasionally stop shooting anyway
		goto coverfire;

	coverfire:
		#### E 1{
			spread=2;
			A_Coverfire();
			A_SetTics(random(2,6));
		}
		wait;

	frag:
		---- A 10 A_Vocalize(seesound);
		---- A 20{
			A_StartSound("weapons/pocket",CHAN_WEAPON);
			A_FaceTarget(0,0);
			pitch-=frandom(20,40);
		}
		---- A 10{
			A_SpawnItemEx("HDFragSpoon",cos(pitch)*4,-1,height-6-sin(pitch)*4,cos(pitch)*cos(angle)*4+vel.x,cos(pitch)*sin(angle)*4+vel.y,sin(-pitch)*4+vel.z,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH);
			A_ZomFrag();
		}
		---- A 0 A_JumpIf(mag<1,"reload");
		---- A 0 setstatelabel("see");

	jammed:
		#### E 8;
		#### E 0 A_Jump(128,"see");
		#### E 4 A_Vocalize(random(0,2)?seesound:painsound);
		---- A 0 setstatelabel("see");

	ohforfuckssake:
		#### E 8;
	reload:
		---- A 0 A_JumpIf(mag<0,"unloadedreload");
		---- A 4 A_StartSound("weapons/rifleclick2");
		#### AA 1 A_HDChase("melee",null,flags:CHF_FLEE);
		#### A 0{
			A_StartSound("weapons/rifleunload");
			name emptymag="HD4mMag";
			if(firemode==-2)emptymag="HD9mMag30";
			HDMagAmmo.SpawnMag(self,emptymag,0);
			mag=-1;
		}
	unloadedreload:
		#### BCD 2 A_HDChase("melee",null,flags:CHF_FLEE);
		#### E 12 A_StartSound("weapons/pocket",8);
		#### E 8 A_StartSound("weapons/rifleload",9);
		#### E 2{
			A_StartSound("weapons/rifleclick2",8);
			if(firemode==-2)mag=30;else mag=50;
		}
		#### CCBB 2 A_HDWander();

	see:
		#### A 0{if(firemode>=0)firemode=random(0,2);}
	see2:
		#### A 0 A_JumpIf(!jammed&&mag<1,"reload");
		#### ABCD 4 A_HDChase();
		#### A 0{
			spread=2;
		}
		#### A 0 A_JumpIfTargetInLOS("see");
		#### A 0 A_Jump(24,"roam");
		loop;
	roam:
		#### E 3 A_Jump(60,"roam2");
		#### E 0{spread=1;}
		#### E 4 A_Watch();
		#### E 0{spread=0;}
		#### EEE 4 A_Watch();
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_Jump(8,"see");
		#### ABCD 6 A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(140,"roam");
		#### A 0 A_JumpIfTargetInLOS("see");
		loop;

	turnaround:
		#### A 0 A_FaceTarget(15,0);
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### E 0{spread=3;}
		#### A 0 A_FaceTarget(15,0);
		#### E 0{spread=6;}
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### E 0{spread=4;}
		#### ABCD 3 A_HDChase();
		---- A 0 setstatelabel("see");
	pain:
		#### G 2;
		#### G 3 A_Vocalize(painsound);
		#### G 0{
			A_ShoutAlert(0.1,SAF_SILENT);
			if(target&&distance3d(target)<100)setstatelabel("see");
		}
		#### ABCD 2 A_HDChase(flags:CHF_FLEE);
		---- A 0 setstatelabel("see");
	death:
		#### H 5;
		#### I 5 A_Vocalize(deathsound);
		#### JK 5;
	dead:
		#### K 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### L 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	xxxdeath:
		#### M 5;
		#### N 5 A_XScream();
		#### OPQRST 5;
		goto xdead;
	xdeath:
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### OP 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### QRST 5;
		goto xdead;
	xdead:
		#### T 3 canraise A_JumpIf(abs(vel.z)<2.,1);
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2.,"xdead");
		wait;
	raise:
		#### L 4{
			jammed=false;
		}
		#### LK 6;
		#### JIH 4;
		#### A 0 A_Jump(256,"see");
	ungib:
		#### U 12;
		#### T 8;
		#### SRQ 6;
		#### PONM 4;
		#### A 0 A_Jump(256,"see");
	}
}


class ZombieAutoStormtrooper:ZombieStormTrooper{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (ZM66)"
		//$Sprite "POSSA1"
		accuracy 1;
}}
class ZombieSemiStormtrooper:ZombieStormTrooper{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (ZM66 Semi)"
		//$Sprite "POSSA1"
		accuracy 2;
}}
class ZombieSMGStormtrooper:ZombieStormTrooper{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (SMG)"
		//$Sprite "POSSA1"
		accuracy 3;
}}

class ZombieHideousTrooper:RandomSpawner replaces ZombieMan{
	default{
		dropitem "ZombieAutoStormtrooper",256,100;
		dropitem "ZombieSemiStormtrooper",256,20;
		dropitem "ZombieSMGStormtrooper",256,10;
		dropitem "EnemyHERP",256,1;
	}
}
class DeadZombieStormtrooper:ZombieStormtrooper replaces DeadZombieMan{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	death.spawndead:
		SPOS A 0;
		POSS A 0 A_CheckFreedoomSprite();
		goto dead;
	}
}
class DeadZombieAutoStormtrooper:DeadZombieStormtrooper{default{accuracy 1;}}
class DeadZombieSemiStormtrooper:DeadZombieStormtrooper{default{accuracy 2;}}
class DeadZombieSMGStormtrooper:DeadZombieStormtrooper{default{accuracy 3;}}



