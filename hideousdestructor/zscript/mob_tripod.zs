// ------------------------------------------------------------
// Cyberdemon
// ------------------------------------------------------------
class Roboball:SlowProjectile{
	default{
		+rockettrail
		damage 30;
		speed 72;
		mass 800;
		radius 5;height 5;
		missileheight 3;
		gravity 0;
		decal "Scorch";
		seesound "weapons/rocklf";
		scale 0.37;
	}
	override void ExplodeSlowMissile(line blockingline,actor blockingmobj){
		//damage
		HDHEAT.HEATShot(self,72);

		//explosion
		if(!inthesky){
			A_SprayDecal("Scorch",16);
			A_HDBlast(
				blastradius:512,blastdamage:random(128,256),fullblastradius:96,
				pushradius:256,pushamount:256,fullpushradius:96,
				fragradius:666,fragtype:"HDB_frag",
				immolateradius:128,immolateamount:random(3,60),
				immolatechance:15
			);

			//hit map geometry
			if(
				blockingline||
				floorz>=pos.z||
				ceilingz-height<=pos.z
			){
				bmissilemore=true;
				if(blockingline)doordestroyer.destroydoor(self,200,frandom(24,48),6,dedicated:true);
			}
		}else DistantNoise.Make(self,"world/rocketfar");
		A_SpawnChunks("HDB_frag",240,300,900);

		//destroy();return;
		bmissile=false;
		setstatelabel("death");
	}
	void A_SatanRoboRocketThrust(){
		if(fuel>0){
			fuel--;
			A_StartSound("weapons/rocklaunch",CHAN_BODY,CHANF_OVERLAP,0.6);
			if(
				abs(vel.x)<500
				&&abs(vel.y)<500
			)A_ChangeVelocity(thrust.x,0,thrust.y,CVF_RELATIVE);
		}else{
			bnogravity=false; //+nogravity is automatically set and causes all subsequent GetGravity() to return 0
			setstatelabel("spawn3");
		}
	}
	int fuel;
	vector2 thrust;
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_StartSound("weapons/rocklf",CHAN_VOICE,CHANF_OVERLAP);
			fuel=100;
			thrust=(cos(pitch),-sin(pitch))*10;
		}
	spawn2:
		MISL A 2 light("ROCKET") A_SatanRoboRocketThrust();
		loop;
	spawn3:
		MISL A 1 light("ROCKET"){
			if(grav>=1.)A_SetTics(-1);
			else{
				gravity+=0.1;
				grav=getgravity();
			}
		}
		wait;
	death:
		TNT1 A 1{
			vel.xy*=0.3;
			for(int i=0;i<3;i++){
				actor xp=spawn("HDExplosion",pos+(frandom(-2,2),frandom(-2,2),frandom(-2,2)),ALLOW_REPLACE);
				xp.vel.z=frandom(1,3);
			}
			A_StartSound("world/explode",CHAN_VOICE,CHANF_OVERLAP);
			DistantNoise.Make(self,"world/rocketfar");
			DistantQuaker.Quake(self,4,35,512,10);
		}
		TNT1 A 0 A_SpawnChunks("HDSmokeChunk",random(3,4),0.1,4);
		TNT1 AAAA 0 A_SpawnItemEx("HDSmoke",
			frandom(-6,6),frandom(-6,6),frandom(-2,6),
			frandom(-1,5),0,frandom(0,1),
			frandom(-5,15)
		);
		TNT1 A 0 A_SpawnChunks("HugeWallChunk",12,4,12);
		TNT1 A 12 A_JumpIf(bmissilemore,"deathsmash");
		stop;
	deathsmash:
		TNT1 A 0 A_SpawnChunks("HugeWallChunk",16,3,8);
		TNT1 A 0 A_SpawnChunks("BigWallChunk",24,5,12);
		TNT1 A 12;
		stop;
	}
}
class Satanball:HDFireball{
	default{
		+extremedeath
		damagetype "balefire";
		activesound "cyber/ballhum";
		seesound "weapons/plasmaf";
		decal "scorch";
		gravity 0;
		height 12;radius 12;
		speed 50;
		scale 0.4;
		damagefunction(256);
	}
	actor lite;
	string pcol;
	override void postbeginplay(){
		super.postbeginplay();
		lite=spawn("SatanBallLight",pos,ALLOW_REPLACE);lite.target=self;
		A_TakeFromTarget("HDMagicShield",20);
		pcol=(Wads.CheckNumForName("id",0)!=-1)?"55 ff 88":"55 88 ff";
	}
	states{
	spawn:
		BFS1 A 0{
			if(stamina>40||!target||target.health<1)return;  
			stamina++;
			actor tgt=target.target;
			if(getage()>144)vel+=(frandom(-0.3,0.3),frandom(-0.3,0.3),frandom(0.1,-0.3));
		}
		BFS1 ABAB 1 bright{
			for(int i=0;i<10;i++){
				A_SpawnParticle(pcol,SPF_RELATIVE|SPF_FULLBRIGHT,35,frandom(1,4),0,
					frandom(-8,8)-5*cos(pitch),frandom(-8,8),frandom(0,8)+sin(pitch)*5,
					frandom(-1,1),frandom(-1,1),frandom(1,2),
					-0.1,frandom(-0.1,0.1),-0.05
				);
			}
			scale=(1,1)*frandom(0.35,0.45);
		}loop;
	death:
		BFE1 A 1 bright{
			spawn("HDSmoke",pos,ALLOW_REPLACE);
			A_StartSound("weapons/bfgx",CHAN_BODY,CHANF_OVERLAP,volume:0.4);
			damagetype="hot";
			bextremedeath=false;
			A_Explode(64,64);
			if(lite)lite.args[3]=128;
			DistantQuaker.Quake(self,2,35,512,10);

			//hit map geometry
			if(
				blockingline||
				floorz>=pos.z||  
				ceilingz-height<=pos.z
			){
				A_SpawnChunks("HDSmoke",3,2,3);
				A_SpawnChunks("HugeWallChunk",50,4,20);
			}

			//teleport victim
			if(
				blockingmobj
				&&!blockingmobj.player
				&&!blockingmobj.special
				&&(
					!blockingmobj.bismonster
					||blockingmobj.health<1
				)
				&&!random(0,3)
			){
				spawn("TeleFog",blockingmobj.pos,ALLOW_REPLACE);
				blockingmobj.setorigin(level.PickDeathmatchStart(),false);
				blockingmobj.vel=(frandom(-10,10),frandom(-10,10),frandom(10,20));
				spawn("TeleFog",blockingmobj.pos,ALLOW_REPLACE);
			}
		}
		BFE1 BBCDDEEE 2 bright A_FadeOut(0.05);
		stop;
	}
}
class SatanBallLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=52;
		bool freedoom=(Wads.CheckNumForName("FREEDOOM",0)!=-1);
		args[1]=freedoom?48:206;
		args[2]=freedoom?206:48;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-10,1);
			if(args[3]<1)destroy();
		}else{
			if(target.bmissile)args[3]=random(32,40);
			else args[3]=random(48,64);
			setorigin(target.pos,true);
		}
	}
}

class SatanRobo:HDMobBase replaces Cyberdemon{
	double launcheroffset;
	default{
		height 100;
		radius 32;
		missileheight 42;
		+boss 
		+missilemore
		+floorclip
		+dontmorph
		+bossdeath
		seesound "cyber/sight";
		painsound "cyber/pain";
		deathsound "cyber/death";
		activesound "cyber/active";
		tag "$CC_CYBER";

		+e1m8boss
		+avoidmelee +nofear
		+noblooddecals
		+hdmobbase.smallhead
		+hdmobbase.biped
		+hdmobbase.noshootablecorpse
		+hdmobbase.chasealert
		+hdmobbase.nodeathdrop
		+hdmobbase.onlyscreamondeath
		damagefactor "hot", 0.5;
		damagefactor "cold", 0.5;
		hdmobbase.shields 8000;
		gibhealth 900;
		health 4000;
		mass 12000;
		speed 15;
		deathheight 110;
		painchance 32;
		painthreshold 200;
		maxtargetrange 0;
		radiusdamagefactor 0.6;
		obituary "$OB_CYBER";
		minmissilechance 196;
	}
	override double bulletresistance(double hitangle){
		return max(0,frandom(0.6,4.0)-hitangle*0.01);
	}
	void A_CyberGunSmoke(){
		A_SpawnItemEx("HDSmoke",
			44,launcheroffset,50,
			frandom(3,7),frandom(-1,1),frandom(1,3),
			0,SXF_NOCHECKPOSITION
		);
	}
	void A_SatanRoboAttack(double spread=0){
		A_StartSound("weapons/bronto",CHAN_WEAPON,CHANF_OVERLAP);
		if(shottype=="Roboball"){
			A_CyberGunSmoke();
			DistantNoise.Make(self,"cyber/rocketfar");
		}else{
			tics=max(1,tics-2);
			DistantNoise.Make(self,"cyber/blasterfar");
		}

		double dist=lasttargetdist;
		double dmult=1.;

		vector3 shotpos=(pos.xy,pos.z+missileheight);
		if(launcheroffset)shotpos.xy+=angletovector(angle-90,launcheroffset);

		let bbb=spawn(shottype,shotpos);
		bbb.pitch=pitch+frandom(-spread,spread);
		bbb.angle=angle+frandom(-spread,spread);
		bbb.target=self;
		bbb.vel=vel+(cos(pitch)*(cos(angle),sin(angle)),-sin(pitch))*bbb.speed;
	}
	override void tick(){
		super.tick();
		if(
			bnofear&&
			health<1600&&
			!random(0,max(10,health))
		)A_SpawnItemEx("HDSmoke",
			random(-32,32),random(-32,32),random(46,96),
			0,0,random(2,4),0,160,64
		);
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		//cheat
		if(source==self)return 0;

		if(damage==TELEFRAG_DAMAGE)
			return super.damagemobj(inflictor,source,TELEFRAG_DAMAGE,"Telefrag");

		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	override void postbeginplay(){
		super.postbeginplay();
		rockets=HDCB_ROCKETMAX;
		shottype="Roboball";
		if(bplayingid)launcheroffset=-24;
	}
	int rockets;
	class<actor>shottype;
	enum CyberStats{
		HDCB_ROCKETMAX=50,
	}
	states{
	spawn:
		CYBR EEEE 10{
			A_HDLook();
			angle+=frandom(-5,5);
		}
	spawn2:
		CYBR CDDAA 6 A_HDWander(CHF_LOOK);
		CYBR B 0 A_StartSound("cyber/walk",15,CHANF_OVERLAP);
		CYBR BB 6 A_HDWander(CHF_LOOK);
		CYBR C 6{
			A_StartSound("cyber/hoof",15,CHANF_OVERLAP);
			A_HDWander(CHF_LOOK);
		}
		CYBR C 0 A_Jump(32,"spawn");
		loop;
	see:
		CYBR AAB 2 A_HDChase();
		CYBR B 3{
			A_StartSound("cyber/walk",15,CHANF_OVERLAP);
			A_ShoutAlert(1.,SAF_SILENT);
			bfrightening=true;
			A_HDChase();
		}
		CYBR C 3{
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
			if(health<1)setstatelabel("death");
			else A_HDChase();
		}
		CYBR CDD 2 A_HDChase();
		loop;
	pain:
		CYBR G 7;
		CYBR G 3{
			A_Pain();
			if(health<3500){
				if(health<3000)minmissilechance-=5;
				if(health>1000)speed++;else speed--;
				speed=clamp(speed,random(1,8),random(20,30));
			}
		}---- A 0 setstatelabel("see");
	missile:
		CYBR A 4 A_TurnToAim(40,missileheight,shootstate:"inposition");
		CYBR B 4{
			A_TurnToAim(40,missileheight,shootstate:"inposition");
			A_StartSound("cyber/walk",15,CHANF_OVERLAP);
			A_Recoil(-4);
		}
		CYBR C 4{
			A_TurnToAim(40,missileheight,shootstate:"inposition");
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
			A_Recoil(-4);
		}
		CYBR D 4 A_TurnToAim(40,missileheight,shootstate:"inposition");
		CYBR E random(15,25) A_Recoil(-4);
		CYBR E 0 A_JumpIfTargetInLOS("missile");
		CYBR E 0 A_Jump(128,"spray");
		---- A 0 setstatelabel("see");
	inposition:
		CYBR E 4{
			A_Recoil(1);
			bfrightening=true;
			A_FaceLastTargetPos(12,missileheight);
		}

		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();

		CYBR E 4;

		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();

		CYBR E 4 A_FaceLastTargetPos(12,missileheight);

		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();

		CYBR E 4 A_SetTics(target?clamp(int(distance2d(target)*0.0003),4,random(4,24)):4);
		CYBR A 0{
			if(!target){
				setstatelabel("fireend");
				return;
			}

			shottype="SatanBall";
			bool ctis=CheckTargetInSight();
			double dist=lasttargetdist;

			if(
				rockets>frandom(0,(HDCB_ROCKETMAX<<2)-dist*0.005)
			){
				shottype="Roboball";
				rockets--;
				setstatelabel("single");
			}
			else if(
				(
					!ctis
					||dist<1024
				)
				&&!random(0,7)
			)setstatelabel("spray");
			else if(
				dist<8192
				&&!random(0,2)
			)setstatelabel("leadtarget");
			else setstatelabel("directshots");
		}
	leadtarget:
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack();
		CYBR E 1 A_SetTics(random(1,4));
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 0 A_CyberGunSmoke();
	leadtarget2:
		CYBR E 8 A_FaceLastTargetPos(12,missileheight,target?frandom(0,target.height):0);
		CYBR F 3 bright light("ROCKET"){
			A_LeadTarget(lasttargetdist/(shottype=="Roboball"?20:15),randompick(0,0,1));
			A_SatanRoboAttack(0.6);
		}
		CYBR E 1 A_SetTics(random(1,8));
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 0 A_CyberGunSmoke();
	leadtarget3:
		CYBR E 8 A_FaceLastTargetPos(12,missileheight,target?frandom(0,target.height):0);
		CYBR F 3 bright light("ROCKET"){
			A_LeadTarget(lasttargetdist/(shottype=="Roboball"?30:25),false);
			A_SatanRoboAttack();
		}
		goto fireend;

	single:
		#### E 1 A_StartAim(rate:0.7,dontlead:randompick(0,0,0,1));
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack();
		goto fireend;

	directshots:
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack();
		CYBR E 8 A_FaceLastTargetPos(12,missileheight);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(0.3);
		CYBR E 8 A_FaceLastTargetPos(12,missileheight);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(0.7);
		goto fireend;

	spray:
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(1.);
		CYBR E 6 A_FaceLastTargetPos(12,missileheight,target?frandom(0,target.height):0);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(2.);
		CYBR E 6 A_FaceLastTargetPos(12,missileheight,target?frandom(0,target.height):0);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(3.);
	fireend:
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();
		CYBR E 17;
		---- A 0 setstatelabel("see");

	death:
		CYBR G 1 A_Pain();
		CYBR G 12{
			A_SetSolid();
			A_SetShootable();
			CheckTargetInSight();
			deathticks=9;
		}
		CYBR DD 6 A_Recoil(-2);
		CYBR A 12 A_SetSolid();
		CYBR A 0{
			A_FaceLastTargetPos(40,missileheight);
			A_SetAngle(angle+random(-10,10));
			A_StartSound("cyber/walk",15,CHANF_OVERLAP);
		}
		CYBR BB 6 A_Recoil(-2);
		CYBR C 12{
			A_FaceLastTargetPos(40,missileheight);
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
		}
		CYBR A 0{
			A_FaceLastTargetPos(40,missileheight);
			angle+=random(-10,10);
		}
		CYBR DD 6 A_Recoil(-2);
		CYBR A 10{
			A_SpawnItemEx("HDExplosionBoss",
				frandom(-12,12),frandom(-12,12),frandom(60,64),
				frandom(-1,1),frandom(-1,1),frandom(1,3)
			);
			A_SpawnItemEx("HDSmokeChunk",
				frandom(-10,10),frandom(-10,10),frandom(38,60), 
				vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+frandom(1,6),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM,144
			);
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
		}
		CYBR D 0 A_SpawnItemEx("HDExplosionBoss",
			frandom(-12,12),frandom(-12,12),frandom(60,64),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR A 5{
			A_FaceLastTargetPos(40,missileheight);
			angle+=random(-10,10);
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
		}
		CYBR B 6 A_StartSound("cyber/walk",15,CHANF_OVERLAP);
		CYBR B 6{
			A_SpawnItemEx("HDExplosionBoss",
				frandom(-26,26),frandom(-26,26),frandom(60,64),
				frandom(-1,1),frandom(-1,1),frandom(1,3)
			);
			A_SpawnItemEx("HDSmokeChunk",
				frandom(-10,10),frandom(-10,10),frandom(38,60),
				vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+random(1,4),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM,144
			);
		}
		CYBR C 16{
			A_FaceLastTargetPos(40,missileheight);
			angle+=frandom(-10,10);
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
		}
		CYBR DD 6 A_Recoil(-2);
		CYBR D 6 A_SpawnItemEx("HDExplosionBoss",
			frandom(-26,26),frandom(-26,26),frandom(60,64),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR A 20 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+frandom(1,4),
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM,144
		);
		CYBR B 0{
			A_FaceLastTargetPos(40,missileheight);
			angle+=random(-10,10);
			A_StartSound("cyber/walk",15,CHANF_OVERLAP);
		}
		CYBR BB 6 A_Recoil(-1);
		CYBR C 24{
			A_SpawnItemEx("HDExplosionBoss",
				frandom(-26,26),frandom(-26,26),frandom(70,88),
				frandom(-1,1),frandom(-1,1),frandom(1,3)
			);
			A_StartSound("cyber/hoof",16,CHANF_OVERLAP);
		}
		CYBR E 14{
			A_StartSound("cyber/walk",15,CHANF_OVERLAP);
		}
		CYBR EEEE 6 A_FaceLastTargetPos(10,missileheight);
		CYBR FF 0 A_SpawnItemEx("HDSmoke",54,launcheroffset,52,
			frandom(1,4),frandom(-1,1),frandom(2,4)
		);
		CYBR FFFFFF 0 A_SpawnItemEx("BigWallChunk",44,launcheroffset,52,
			frandom(4,14),frandom(-3,3),frandom(1,4),frandom(0,360)
		);
		CYBR FFFF 0 A_SpawnItemEx("HugeWallChunk",44,launcheroffset,52,
			frandom(4,24),frandom(-3,3),frandom(1,4),frandom(0,360)
		);
		CYBR F 3 bright A_SpawnItemEx("HDExplosion",54,launcheroffset,52);
		CYBR E 56;
		CYBR E 0 {HDMobAI.Frighten(self,666);}
		CYBR EEEEEE 4 A_SpawnItemEx("HDSmoke",44,launcheroffset,52,
			frandom(1,4),frandom(-1,1),frandom(2,4)
		);
		CYBR E 0 {HDMobAI.Frighten(self,666);}
		CYBR EEEEEE 2 A_SpawnItemEx("HDSmoke",44,launcheroffset,52,
			frandom(1,4),frandom(-1,1),frandom(3,6)
		);
	xdeath:
		CYBR EEEEEE 1 A_SpawnItemEx("HDSmoke",44,launcheroffset,52,
			frandom(1,4),frandom(-1,1),frandom(4,8)
		);
		CYBR H 0 A_HDBossScream();
		CYBR HHHH 2 bright A_SpawnItemEx("HDExplosion",
			frandom(-26,26),frandom(-26,26),frandom(56,64),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR H 3 bright A_SpawnItemEx("HDExplosionBoss",
			frandom(-36,36),frandom(-36,36),frandom(40,46),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR H 1 bright A_SpawnItemEx("HDExplosion",
			frandom(-26,26),frandom(-46,46),frandom(30,36),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR I 2{
			A_UnSetSolid();
			A_UnSetShootable();
			A_SetSize(radius,bplayingid?8:32);
			A_Explode(512,16);
			DistantQuaker.Quake(self,8,140,4096,7,400,666,256);
		}

		CYBR AAAAAAA 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(1,4)
		);
		CYBR I 2 bright A_SpawnItemEx("HDExplosionBoss",
			frandom(-36,36),frandom(-26,26),frandom(60,78),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR I 2 bright A_SpawnItemEx("HDExplosion",
			frandom(-36,36),frandom(-26,26),frandom(50,68),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR I 3 bright A_SpawnItemEx("HDExplosion",
			frandom(-26,26),frandom(-26,26),frandom(75,82),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);

		CYBR AA 0 A_SpawnItemEx("CyberGibs",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(1,4)
		);
		CYBR AA 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(6,12)
		);

		CYBR J 3 bright A_SpawnItemEx("HDExplosionBoss",
			frandom(-26,26),frandom(-46,46),frandom(45,52),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR AA 0 A_SpawnItemEx("CyberGibs",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(1,4)
		);
		CYBR J 3 bright A_SpawnItemEx("HDExplosion",
			frandom(-36,36),frandom(-26,26),frandom(64,82),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR J 3 bright A_SpawnItemEx("HDExplosionBoss",
			frandom(-36,36),frandom(-26,26),frandom(45,82),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);

		CYBR KK 0 A_SpawnItemEx("CyberGibs",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(1,4)
		);
		CYBR KK 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(1,4)
		);

		CYBR K 4 bright A_SpawnItemEx("HDExplosion",
			frandom(-36,36),frandom(-46,46),frandom(48,62),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR K 4 A_SpawnItemEx("HDExplosionBoss",
			frandom(-66,66),frandom(-66,66),frandom(15,42),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);

		CYBR L 4 A_SpawnItemEx("HDExplosion",
			frandom(-36,36),frandom(-36,36),frandom(62,82),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR L 1 A_SpawnItemEx("HDExplosionBoss",
			frandom(-16,16),frandom(-16,16),frandom(75,82),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);

		CYBR LL 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(38,60),
			frandom(-6,6),frandom(-6,6),frandom(1,4)
		);

		CYBR LLLL 3 A_SpawnItemEx("HDSmoke",
			frandom(-36,36),frandom(-36,36),frandom(24,80),
			frandom(-1,1),frandom(-1,1),frandom(3,6)
		);

		CYBR M 0 A_NoBlocking();
		CYBR MMMM 2 A_SpawnItemEx("HDSmoke",
			frandom(-20,20),frandom(-20,20),frandom(24,80),
			frandom(-1,1),frandom(-1,1),frandom(2,4)
		);
		CYBR O 0 a_spawnitemex("CyberRemains",flags:SXF_NOCHECKPOSITION|SXF_SETMASTER);

		CYBR PPPP 4 A_SpawnItemEx("HDSmoke",
			frandom(-26,26),frandom(-26,26),frandom(12,40),
			frandom(-1,1),frandom(-1,1),frandom(1,3)
		);
		CYBR PPPPPPPPPPPPPPPPP 1 A_SpawnItemEx("HDSmoke",
			frandom(-26,26),frandom(-26,26),frandom(32,60),
			frandom(-2,2),frandom(-2,2),frandom(1,6)
		);
		CYBR PPPPPPPPPPPPPPPP 5 A_SpawnItemEx("HDSmoke",
			frandom(-26,26),frandom(-26,26),frandom(1,14),
			frandom(-1,1),frandom(-1,1),frandom(1,4),frandom(0,255)
		);
		CYBR P 200{bnofear=false;}
		CYBR P -1 A_BossDeath();
		stop;

	//And see if there be any wicked way in me, and lead me in the way everlasting.
	death.telefrag:
		TNT1 A 100{
			bnofear=false;
			A_Pain();
			A_NoBlocking();
			A_SpawnItemEx("TeleFog",flags:SXF_NOCHECKPOSITION);
		}
		TNT1 A 200 A_Scream();
		TNT1 A 0 A_BossDeath();
		stop;
	}
}


class CyberRemains:Actor{
	default{
		renderstyle "add";
		radius 32;height 16;
		+shootable +ghost
	}
	int smokelag;
	override void postbeginplay(){
		super.postbeginplay();
		A_Die();
	}
	override void die(actor source,actor inflictor,int dmgflags){
		super.die(source,inflictor,dmgflags);
		bshootable=true;
		HDF.Give(Self,"Heat",6666);
	}
	override void tick(){
		if(master)setorigin(master.pos,true);
		super.tick();
	}
	states{
	spawn:
		CYBR NOPE 0;
		---- A 0 setstatelabel("death");
	death:
		#### NO 4;
	spawn2:
		---- AA 1 A_SpawnItemEx("HDSmoke",
			frandom(-30,30),frandom(-30,30),frandom(12,14),
			frandom(-1,1),frandom(-1,1),0,
			0,SXF_NOCHECKPOSITION
		);
		---- A 0 A_StartSound("misc/firecrkl",CHAN_AUTO,volume:1.0-(smokelag*0.005));
		---- AAA 0 A_SpawnItemEx("HDFlameRed",
			frandom(-66,66),frandom(-56,56),frandom(12,14),
			frandom(-1,1),frandom(-1,1),0,
			0,SXF_NOCHECKPOSITION
		);
		---- A 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-30,30),frandom(-30,30),frandom(4,12),
			frandom(-3,3),frandom(-3,3),frandom(0,3),
			0,SXF_NOCHECKPOSITION,160+smokelag
		);
		---- AAA 0 A_SpawnItemEx("HugeWallChunk",
			frandom(-30,30),frandom(-30,30),frandom(4,12),
			frandom(-6,6),frandom(-6,6),frandom(1,4),
			0,SXF_NOCHECKPOSITION,64+smokelag/2
		);
		---- A 0{
			A_SetTics(random(1,smokelag/7));
			smokelag++;
			if(alpha>0.2)alpha-=0.04;
			else A_FadeOut(0.001);
		}
		---- A 0 A_JumpIf(alpha<0.2,1);
		loop;
	spawn3:
		CYBR P 0;
		goto spawn2;
		CYBR E 0;
		stop;
	}
}
class CyberGibs:HDActor{
	default{
		+noblockmap
		+shootable +corpse
		radius 20;height 16;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){return -1;}
	void A_CyberGibTrail(){
		HDF.Give(Self,"Heat",666);
		for(int i=0;i<20;i++){
			A_SpawnParticle("66 00 00",
				0,random(70,100),frandom(3.,8.),0,
				frandom(-6,6),frandom(-6,6),frandom(3,6),
				frandom(-1,1),frandom(-1,1),frandom(3,6),
				-0.1,frandom(-0.1,0.1),-0.3
			);
			A_SpawnParticle("ff ed 40",
				0,random(40,70),frandom(2.,3.),0,
				frandom(-6,6),frandom(-6,6),frandom(2,4),
				frandom(-1,1),frandom(-1,1),frandom(0,4),
				-0.1,frandom(-0.1,0.1),-0.01
			);
			A_SpawnParticle("36 30 30",
				0,random(70,100),frandom(7.,10.),0,
				frandom(-12,12),frandom(-12,12),frandom(4,6),
				0,0,frandom(1.,3.),
				frandom(-0.05,0.05),frandom(-0.05,0.05),-0.005
			);
		}
		if(abs(vel.z)<4)setstatelabel("crash");
	}
	void A_CyberGibSplat(){
		for(int i=0;i<20;i++){
			A_SpawnParticle("66 00 00",
				0,random(50,80),frandom(3.,8.),0,
				frandom(-6,6),frandom(-6,6),frandom(0,4),
				frandom(-3,3),frandom(-3,3),frandom(0,4),
				-0.1,frandom(-0.1,0.1),-HDCONST_GRAVITY
			);
			if(!i%5)A_SpawnParticle("36 36 36",
				0,random(50,80),frandom(24.,48.),0,
				frandom(-12,12),frandom(-12,12),frandom(0,3),
				0,0,frandom(1.,3.),
				frandom(-0.05,0.05),frandom(-0.05,0.05),-0.005
			);
		}
	}
	void A_CyberGibFade(){
		for(int i=0;i<20*alpha;i++){
			A_SpawnParticle("66 00 00",
				0,50,frandom(3.,12.),0,
				frandom(-20,20),frandom(-20,20),frandom(0,8),
				frandom(-3,3),frandom(-3,3),frandom(0,4),
				-0.1,frandom(-0.1,0.1),-HDCONST_GRAVITY
			);
		}
		if(heat.getamount(self)<20)A_FadeOut(0.07);
		A_SpawnItemEx("HDSmokeChunk",
			frandom(-3,3),frandom(-3,3),2,
			vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+frandom(0,7*alpha),
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
	}
	states{
	spawn:
		POSS O 5 nodelay A_SetScale(randompick(-1,1)*frandom(0.8,1.3),frandom(0.8,1.2));
		POSS P 2 A_CyberGibTrail();
		wait;
	crash:
		POSS QQ 1 A_SpawnItemEx("HDExplosion",
			random(-3,3),random(-3,3),2,vel.x,vel.y,vel.z+1,
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		POSS QRRSSTT 2 A_CyberGibSplat();
		POSS U 6 A_CyberGibFade();
		wait;
	}
}
