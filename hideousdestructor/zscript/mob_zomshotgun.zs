// ------------------------------------------------------------
// Former Human Sergeant
// ------------------------------------------------------------
class HideousJackbootReplacer:RandomSpawner replaces ShotgunGuy{
	default{
		dropitem "UndeadJackbootman",256,60;
		dropitem "JackAndJillboot",256,40;
		dropitem "Jackboot",256,120;
		dropitem "EnemyHERP",256,1;
		dropitem "EnemyDERP",256,1;
	}
}

class Jackboot:ZombieShotgunner{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shotgun Guy (Pump)"
		//$Sprite "SPOSA1"
		accuracy 1;
}}
class JackAndJillboot:ZombieShotgunner{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shotgun Guy (Side-By-Side)"
		//$Sprite "SPOSA1"
		accuracy 2;
}}
class UndeadJackbootman:ZombieShotgunner{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "ZM66 Burst Guy"
		//$Sprite "PLAYF1"
		accuracy 3;
}}
class ZombieShotgunner:HDHumanoid{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shotgun Guy"
		//$Sprite "SPOSA1"

		seesound "shotguy/sight";
		painsound "shotguy/pain";
		deathsound "shotguy/death";
		activesound "shotguy/active";
		tag "$TAG_ZOMBSHOTGUN";

		speed 10;
		decal "BulletScratch";
		meleesound "weapons/smack";
		meleedamage 4;
		maxtargetrange 4000;
		painchance 200;
		accuracy 0;

		//placeholder
		obituary "$OB_SHOTGUNZOMBIE";
		hitobituary "$OB_SHOTZOMB_HIT";
	}
	bool semi;
	int gunloaded;
	int gunspent;
	int wep;
	int choke; //record here because the gun should only drop once
	override void beginplay(){
		super.beginplay();
		bhasdropped=0;

		//-1 zm66, 0 sg, 1 ssg
		if(!accuracy) wep=random(0,1)-random(0,1);
		else if(accuracy==1)wep=0;
		else if(accuracy==2)wep=1;
		else if(accuracy==3)wep=-1;

		//if no ssg, sg
		if(Wads.CheckNumForName("SHT2B0",wads.ns_sprites,-1,false)<0&&wep==1)wep=0;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(wep<0){
			bhashelmet=true;
			sprite=GetSpriteIndex("PLAYA1");
			A_SetTranslation("HattedJackboot");
			gunloaded=random(10,50);
			givearmour(1.,0.06,-0.4);
		}else{
			sprite=GetSpriteIndex("SPOSA1");
			A_SetTranslation("ShotgunGuy");
			gunloaded=wep?random(1,2):random(3,8);
			if(random(0,7))choke=(wep?(7+8*7):1);else{
				choke=random(0,7);
				//set second barrel
				if(wep)choke+=8*random(0,7);
			}
		}
		semi=randompick(0,0,1);
	}
	override void deathdrop(){
		A_NoBlocking();
		if(bhasdropped){
			if(!bfriendly){
				if(wep<0)DropNewItem("HD4mMag",96);
				else DropNewItem("ShellPickup",200);
			}
		}else{
			DropNewItem("HDHandgunRandomDrop");
			bhasdropped=true;
			hdweapon wp=null;
			if(wep==-1){
				wp=DropNewWeapon("ZM66AssaultRifle");
				if(wp){
					wp.weaponstatus[0]=
						ZM66F_NOLAUNCHER|(randompick(0,1,1,1,1)*ZM66F_CHAMBER);
					if(gunloaded>=50)wp.weaponstatus[ZM66S_MAG]=51;
					else wp.weaponstatus[ZM66S_MAG]=gunloaded;
					wp.weaponstatus[ZM66S_AUTO]=2;
					wp.weaponstatus[ZM66S_ZOOM]=random(16,70);
					if(jammed||!random(0,7))wp.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
					wp.weaponstatus[ZM66S_DOT]=random(-1,5);

					gunloaded=50;
				}
			}
			if(wep==0){
				wp=DropNewWeapon("Hunter");
				if(wp){
					wp.weaponstatus[HUNTS_FIREMODE]=semi?1:0;
					if(gunspent)wp.weaponstatus[HUNTS_CHAMBER]=1;
					else if(gunloaded>0){
						wp.weaponstatus[HUNTS_CHAMBER]=2;
						gunloaded--;
					}
					if(gunloaded>0)wp.weaponstatus[HUNTS_TUBE]=gunloaded;
					wp.weaponstatus[SHOTS_SIDESADDLE]=random(0,12);
					wp.weaponstatus[0]&=~HUNTF_CANFULLAUTO;
					wp.weaponstatus[HUNTS_CHOKE]=choke;

					gunloaded=8;
				}
			}
			if(wep==1){
				wp=DropNewWeapon("Slayer");
				if(wp){
					if(gunloaded==2)wp.weaponstatus[SLAYS_CHAMBER2]=2;
					else if(gunspent==2)wp.weaponstatus[SLAYS_CHAMBER2]=1;
					if(gunloaded>0)wp.weaponstatus[SLAYS_CHAMBER1]=2;
					else if(gunspent>0)wp.weaponstatus[SLAYS_CHAMBER1]=1;
					wp.weaponstatus[SHOTS_SIDESADDLE]=random(0,12);
					wp.weaponstatus[SLAYS_CHOKE1]=(choke&(1|2|4));
					wp.weaponstatus[SLAYS_CHOKE2]=(choke>>3);

					gunloaded=2;
				}
			}
		}
		gunspent=0;
		if(wep==-1){
			gunloaded=50;
		}
		if(wep==0){
			gunloaded=8;
		}
		if(wep==1){
			gunloaded=2;
		}
	}
	states{
	spawn:
		SPOS A 0 nodelay A_JumpIf(wep>=0,"spawn2");
		PLAY A 0;
	idle:
	spawn2:
		#### EEEEEE 1{
			A_HDLook();
			vel.xy-=(cos(angle),sin(angle))*frandom(-0.1,0.1);
			A_SetTics(random(1,10));
		}
		#### B 0 A_Jump(132,2,5,5,5,5);
		#### B 8{
			if(!random(0,1)){
				if(!random(0,4)){
					setstatelabel("spawnstretch");
				}else{
					if(bambush)setstatelabel("spawnstill");
					else setstatelabel("spawnwander");
				}
			}else vel.xy-=(cos(angle),sin(angle))*frandom(-0.2,0.2);
		}loop;
	spawnstretch:
		#### G 1{
			vel.xy-=(cos(angle),sin(angle))*frandom(-0.4,0.4);
			A_SetTics(random(30,80));
		}
		#### A 0 A_Vocalize(activesound);
		---- A 0 setstatelabel("spawn2");
	spawnstill:
		#### C 0{
			A_HDLook();
			vel.xy-=(cos(angle),sin(angle))*frandom(-0.4,0.4);
		}
		#### CD 5{angle+=random(-4,4);}
		#### A 0{
			A_HDLook();
			if(!random(0,15))A_Vocalize(activesound);
		}
		#### AB 5{angle+=random(-4,4);}
		#### B 1 A_SetTics(random(10,40));
		---- A 0 setstatelabel("spawn2");
	spawnwander:
		#### CD 5 A_HDWander();
		#### A 0 {
			if(!random(0,15))A_Vocalize(activesound);
			A_HDLook();
		}
		#### AB 5 A_HDWander();
		#### A 0 A_Jump(64,"spawn2");
		loop;

	see:
		#### A 0{
			if(jammed)return;
			else if(gunloaded<1)setstatelabel("reload");
			else if(!wep&&gunspent>0)setstatelabel("chambersg");
		}
		#### ABCD 4 A_HDChase();
		#### A 0 A_Jump(116,"roam","roam","roam","roam2","roam2");
		loop;
	roam:
		#### EEEE 3 A_Watch();
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_JumpIf(targetinsight||!random(0,31),"see");
		#### ABCD 6 A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(80,"roam");
		loop;

	missile:
		#### ABCD 3 A_TurnToAim(40,shootstate:"aiming");
		loop;
	aiming:
		#### E 1 A_StartAim(rate:0.88,maxtics:random(10,40));
		//fallthrough to shoot
	shoot:
		#### E 2 A_LeadTarget(tics);
		#### E 0{
			if(jammed){
				setstatelabel("jammed");
				return;
			}
			if(gunloaded<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			angle+=frandom(0,spread)-frandom(0,spread);
			pitch+=frandom(0,spread)-frandom(0,spread);

			if(wep==-1)setstatelabel("shootzm66");
			else if(wep==1)setstatelabel("shootssg");
			else setstatelabel("shootsg");
		}

	shootzm66:
		#### E 1{
			gunspent=0;
		}
	shootzm662:
		#### F 1 bright light("SHOT"){
			if(!random(0,999)){
				A_StartSound("weapons/rifleclick",8);
				gunloaded=-gunloaded;
				setstatelabel("ohforfuckssake");
				return;
			}

			A_StartSound("weapons/rifle",CHAN_WEAPON);

			gunspent++;
			gunloaded--;
			HDBulletActor.FireBullet(self,"HDB_426");
			if(random(0,2000)<gunspent+2){
				jammed=true;
				A_StartSound("weapons/rifleclick",8);
				setstatelabel("jammed");
			}
		}
		#### E 1{
			if(gunspent<3&&gunloaded>0)setstatelabel("shootzm662");
			else A_SetTics(random(4,12));
		}
		#### E 0 A_Jump(127,"see");
		goto missile;

	shootssg:
		#### F 1 bright light("SHOT"){
			A_StartSound("weapons/slayersingle",CHAN_WEAPON);
			if(gunloaded>1&&!random(0,5)){
				//both barrels
				A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
				gunspent=2;
				gunloaded=0;
				Slayer.Fire(self,0,(choke&(1|2|4)));
				Slayer.Fire(self,1,(choke>>3));
			}else{
				//single barrel
				gunspent++;
				gunloaded--;
				if(gunspent)Slayer.Fire(self,1,(choke>>3));
				else Slayer.Fire(self,0,(choke&(1|2|4)));
			}
		}
		#### E 1 A_SetTics(random(2,4));
		#### E 0 A_Jump(192,"see");
		goto roam;

	shootsg:
		#### F 1 bright light("SHOT"){
			if(gunspent>0){
				setstatelabel("chambersg");
				return;
			}
			if(Hunter.Fire(self,choke)<=Hunter.HUNTER_MINSHOTPOWER)semi=false;
			gunspent=1;
		}
		#### E 3{
			if(semi){
				A_SetTics(0);
				if(gunloaded>0)gunloaded--;
				gunspent=0;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				if(!random(0,7))semi=false;
			}
		}
		#### E 1{
			if(gunspent)setstatelabel("chambersg");
			else A_SetTics(random(3,8));
		}
		#### E 0 A_Jump(127,"see");
		#### E 0 A_Jump(32,"missile");
		---- A 0 setstatelabel("roam");
	chambersg:
		#### E 8{
			if(gunspent){
				A_SetTics(random(3,10));
				A_StartSound("weapons/huntrack",8);
				gunspent=0;
				if(gunloaded>0)gunloaded--;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
			if(!random(0,7))semi=true;
		}
		#### E 1 A_SetTics(random(3,8));
		#### E 0 A_Jump(127,"see");
		goto roam;

	jammed:
		#### E 8;
		#### E 0 A_Jump(128,"see");
		#### E 4 A_Vocalize(random(0,2)?seesound:painsound);
		---- A 0 setstatelabel("see");

	ohforfuckssake:
		#### E 6;
	reload:
		#### A 0{
			if(wep==-1)setstatelabel("reloadzm66");
			else if(wep==1)setstatelabel("reloadssg");
			else setstatelabel("reloadsg");
		}


	reloadzm66:
		#### A 2 A_HDChase("melee",null,CHF_FLEE);
		#### A 0 A_StartSound("weapons/rifleclick2",8);
		#### BCD 2 A_HDWander(flags:CHF_FLEE);
		#### A 2{
			A_HDWander();
			if(gunspent==999)return;

			A_StartSound("weapons/rifleunload",8);
			HDMagAmmo.SpawnMag(self,"HD4mMag",gunloaded);
		}
		#### BCD 2 A_HDWander(flags:CHF_FLEE);
		#### A 4 A_StartSound("weapons/pocket",9);
		#### BC 4 A_HDWander(flags:CHF_FLEE);
		#### E 6 A_StartSound("weapons/rifleload",8);
		#### E 2{
			A_StartSound("weapons/rifleclick2");
			gunloaded=50;
			gunspent=0;
			A_HDChase();
		}
		#### CB 4 A_HDChase("melee",null);
		goto missile;

	reloadssg:
		#### E 2;
		#### E 2 A_StartSound("weapons/sshoto",8);
		#### E 0{
			while(gunspent>0){
				gunspent--;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*5,-1,height-7-sin(pitch)*5,
					cos(pitch-45)*cos(angle)*random(1,4)+vel.x,
					cos(pitch-45)*sin(angle)*random(1,4)+vel.y,
					-sin(pitch-45)*random(1,4)+vel.z,0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
		}

		#### ED 2 A_HDChase("melee",null,flags:CHF_FLEE);
		#### DAAB 3 A_HDChase("melee",null,flags:CHF_FLEE,speedmult:0.5);
		#### B 1 A_StartSound("weapons/sshotl",8);
		#### CCD 4;
		#### E 6{
			A_StartSound("weapons/sshotc",8);
			gunloaded=2;
		}
		---- A 0 setstatelabel("see");

	reloadsg:
		#### A 2 A_HDChase("melee",null);
		#### A 0 A_StartSound("weapons/huntopen",8);
		#### BCDA 2 A_HDChase("melee",null,flags:CHF_FLEE);
	reloadsg2:
		#### BB 3 A_HDWander(flags:CHF_FLEE);
		#### B 0{
			gunloaded++;
			A_StartSound("weapons/huntreload",8);
			if(gunloaded>=8)setstatelabel("reloadsgend");
		}
		#### CC 3 A_HDWander(flags:CHF_FLEE);
		#### C 0{
			gunloaded++;
			A_StartSound("weapons/huntreload",8);
			if(gunloaded>=8)setstatelabel("reloadsgend");
		}
		#### DD 3 A_HDChase("melee",null,CHF_FLEE);
		#### D 0{
			gunloaded++;
			A_StartSound("weapons/huntreload",8);
			if(gunloaded>=8)setstatelabel("reloadsgend");
		}
		#### A 0 A_StartSound("weapons/pocket",9);
		#### ABCDA 2 A_HDWander();
		loop;
	reloadsgend:
		#### BCD 3 A_HDWander(flags:CHF_FLEE);
		#### A 0 A_StartSound("weapons/huntopen",8);
		#### E 4 A_HDChase("melee","missile",CHF_DONTMOVE);
		---- A 0 setstatelabel("see");

	pain:
		#### G 3 A_Jump(12,1);
		#### G 3 A_Vocalize(painsound);
		#### G 0{
			A_ShoutAlert(0.2,SAF_SILENT);
			if(target&&distance3d(target)<100)setstatelabel("see");
		}
		#### ABCD 2 A_HDChase(flags:CHF_FLEE);
		#### G 0{bfrightened=false;}
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
		#### M 0 A_JumpIf(wep<0,"xxxdeath2");
		#### M 5;
		#### N 5 A_XScream();
		#### OPQRST 5;
		goto xdead;
	xxxdeath2:
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		goto xdead2;
	xdeath:
		#### M 0 A_JumpIf(wep<0,"xdeath2");
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### OP 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### QRST 5;
		goto xdead;
	xdead:
		#### T 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### U 5 canraise{if(abs(vel.z)>=2.)setstatelabel("xdead");}
		wait;
	xdeath2:
		#### O 5;
		#### P 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### QR 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### STUV 5;
		goto xdead2;
	xdead2:
		#### V 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### W 5 canraise{if(abs(vel.z)>=2.)setstatelabel("xdead2");}
		wait;
	raise:
		#### A 0{
			jammed=false;
		}
		#### L 4 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### LK 6;
		#### JIH 4;
		#### A 0 A_Jump(256,"see");
	ungib:
		#### U 12;
		#### T 8;
		#### SRQ 6;
		#### PON 4;
		#### A 0 A_Jump(256,"see");
	}
}

class DeadJackboot:DeadZombieShotgunner{default{accuracy 1;}}
class DeadJackAndJillboot:DeadZombieShotgunner{default{accuracy 2;}}
class DeadUndeadJackbootman:DeadZombieShotgunner{default{accuracy 3;}}
class DeadZombieShotgunner:ZombieShotgunner replaces DeadShotgunGuy{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	death.spawndead:
		---- A 0;
		goto dead;
	}
}

