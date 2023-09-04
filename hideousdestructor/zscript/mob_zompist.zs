// ------------------------------------------------------------
// Pistol guy
// ------------------------------------------------------------
class UndeadHomeboy:HDHumanoid{
	//tracking ammo
	int chamber;
	int thismag;
	int firemode; //based on the old pistol method: -1=semi only, 0=semi selected, 1=full auto

	//specific to undead homeboy
	int user_weapon; //0 random, 1 semi, 2 auto

	override void postbeginplay(){
		super.postbeginplay();
		bhasdropped=false;

		//specific to undead homeboy
		thismag=random(1,15);
		chamber=2;
		if(
			user_weapon==2
			||(
				user_weapon!=1
				&&!random(0,15)
			)
		)firemode=randompick(0,0,0,1);
		else firemode=-1;
	}
	virtual bool noammo(){
		return chamber<1&&thismag<1;
	}


	/*
	These functions were originally meant to be a prototype for a lot of generalized
	monster attack functions. As of this last review (2021-07) I am abandoning
	that idea since each monster has such specialized attacks that it's better
	to customize each one separately, with a few common specific complex calculations
	like HDMobAI.DropAdjust that are too tedious to repeat.
	*/



	//post-shot checks
	void A_HDMonsterRefire(statelabel jumpto,int chancetocontinue=0){
		if(
			random(1,100)>chancetocontinue
			&&(
				!target
				||!checksight(target)
				||target.health<1
				||absangle(angle,angleto(target))>3
				||!hdmobai.tryshoot(self,flags:hdmobai.TS_GEOMETRYOK)
			)
		)setstatelabel(jumpto);
	}


	void A_PistolZombieAttack(){
		if(chamber<2){
			if(chamber>0)A_EjectPistolCasing();
			if(thismag>0){
				chamber=2;
				thismag--;
			}
			setstatelabel("postshot");
			return;
		}

		pitch+=frandom(0,spread)-frandom(0,spread);
		angle+=frandom(0,spread)-frandom(0,spread);
		HDBulletActor.FireBullet(self,"HDB_9",spread:2.,speedfactor:frandom(0.97,1.03));

		A_StartSound("weapons/pistol",CHAN_WEAPON);
		pitch+=frandom(-0.4,0.3);
		angle+=frandom(-0.4,0.4);

		A_EjectPistolCasing();
		if(thismag>0)thismag--;
		else chamber=0;
	}
	override void deathdrop(){
		if(bhasdropped){
			DropNewItem("HD9mMag15",96);
		}else{
			bhasdropped=true;
			let ppp=DropNewWeapon("HDPistol");
			ppp.weaponstatus[PISS_MAG]=thismag;
			ppp.weaponstatus[PISS_CHAMBER]=chamber;
			if(firemode>=0){
				ppp.weaponstatus[0]|=PISF_SELECTFIRE;
				if(firemode>0)ppp.weaponstatus[0]|=PISF_FIREMODE;
			}
		}
	}
	void A_PistolZombieUnload(int which=0){
		if(thismag>=0){
			HDMagAmmo.SpawnMag(self,"HD9mMag15",thismag);
			A_StartSound("weapons/pismagclick",8);
		}
		thismag=-1;
	}
	bool A_HDReload(int which=0){
		if(thismag>=0)return false;
		thismag=15;
		if(chamber<2){
			if(chamber>0)A_EjectPistolCasing();
			chamber=2;
			thismag--;
		}
		A_StartSound("weapons/pismagclick",8);
		return true;
	}


	//defaults and states
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Pistol Zombie"
		//$Sprite "POSSA1"

		seesound "grunt/sight";
		painsound "grunt/pain";
		deathsound "grunt/death";
		activesound "grunt/active";
		tag "$cc_zombie";

		radius 10;
		speed 12;
		mass 100;
		painchance 200;
		obituary "$OB_ZOMBPISTOL";
		hitobituary "$OB_ZOMBPISTOL_HIT";
	}
	states{
	spawn:
		POSS E 1{
			A_HDLook();
			A_Recoil(frandom(-0.1,0.1));
		}
		#### EEE random(5,17) A_HDLook();
		#### E 1{
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
		#### B 0 A_JumpIf(noammo(),"reload");
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
		#### A 0 A_Jump(256,"spawn");
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
		#### A 0 A_Jump(256,"spawn");
	spawnwander:
		#### CDAB 5 A_HDWander();
		#### A 0 A_Jump(64,"spawn");
		loop;

	see:
		#### ABCD random(3,4) A_HDChase();
		#### A 0 A_JumpIf(noammo(),"reload");
		#### A 0 A_Jump(116,"roam","roam","roam","roam2","roam2");
		loop;
	roam:
		#### EEEE 3 A_Watch();
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_JumpIf(targetinsight||!random(0,31),"see");
		#### ABCD 5 A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(80,"roam");
		loop;

	missile:
		#### ABCD 3 A_TurnToAim(20);
		loop;
	shoot:
		#### E 1 A_SetTics(min(1,int(lasttargetdist)>>5));
		#### E 2 A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1));
	fire:
		#### F 1 bright light("SHOT") A_PistolZombieAttack();
	postshot:
		#### E 1;
		#### E 0 A_JumpIf(chamber!=2||!target,"nope");
		#### E 0{
			if(
				firemode>0
			){
				pitch+=frandom(-2.4,2);
				angle+=frandom(-2,2);
				setstatelabel("fire");
			}else A_SetTics(random(3,10));
		}
		#### E 0 A_HDMonsterRefire("see",25);
		goto fire;
	nope:
		#### E 10;
	reload:
		#### ABCD 4 A_HDChase("melee",null,CHF_FLEE);
		#### A 7 A_PistolZombieUnload();
		#### BC 6 A_HDChase("melee",null,CHF_FLEE);
		#### D 8 A_HDReload();
		---- A 0 setstatelabel("see");

	pain:
		#### G 2;
		#### G 3 A_Vocalize(painsound);
		#### G 0{
			A_ShoutAlert(0.1,SAF_SILENT);
			if(
				floorz==pos.z
				&&target
				&&(
					!random(0,4)
					||distance3d(target)<128
				)
			){
				double ato=angleto(target)+randompick(-90,90);
				vel+=((cos(ato),sin(ato))*speed,1.);
				setstatelabel("missile");
			}
		}
		#### ABCD 2 A_HDChase(flags:CHF_FLEE);
		---- A 0 setstatelabel("see");
	death:
		#### H 5;
		#### I 5 A_Vocalize(deathsound);
		#### J 5 A_NoBlocking();
		#### K 5;
	dead:
		#### K 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### L 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	xxxdeath:
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### OPQRST 5;
		goto xdead;
	xdeath:
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### O 0 A_NoBlocking();
		#### OP 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### QRST 5;
		goto xdead;
	xdead:
		#### T 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2.,"xdead");
		wait;
	raise:
		#### L 4;
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




