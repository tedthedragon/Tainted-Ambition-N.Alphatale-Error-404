// ------------------------------------------------------------
// Trilobite
// ------------------------------------------------------------
class FooFighter:HDActor{
	bool foowizard;
	bool foocleric;
	default{
		+bright +nogravity +float +noblockmap
		+seekermissile +missile
		+puffonactors +bloodlessimpact +alwayspuff +puffgetsowner +hittracer

		+rollsprite +rollcenter
		+forcexybillboard +bright
		renderstyle "add";

		height 20;radius 20;
		speed 20;
		maxstepheight 64;

		damagetype "electrical";

		seesound "caco/ballhum";
	}
	override void beginplay(){
		super.beginplay();
		vel*=frandom(0.4,1.7);
		stamina=random(300,600);
		ChangeTid(FOOF_TID);

		foowizard=randompick(0,0,0,0,1);
		foocleric=randompick(0,0,0,0,0,1);
	}
	override void tick(){
		if(isfrozen()){
			clearinterpolation();
			return;
		}
		if(bnointeraction){
			roll+=10;
			scale*=1.01;
			A_SpawnItemEx("HDGunSmoke",3,0,0,2,0,1,roll,SXF_NOCHECKPOSITION);
			super.tick();
			return;
		}
		roll=frandom(0,360);
		stamina--;

		if(!random(0,32))CacoZapArc(self);

		//apply movement and collision
		speed=vel.xy.length();
		int times=int(max(1,speed/radius));
		vector3 frac=(times==1)?vel:(vel/times);
		fcheckposition tm;
		for(int i=0;i<times;i++){
			if(stamina<1||!trymove(pos.xy+frac.xy,true,true,tm)){
				if(
					stamina>0&&random(0,blockingmobj==null?2:7)
				){
					setorigin((pos.xy+frac.xy,pos.z),true);
					continue;
				}

				//bzz
				if(blockingmobj){
					if(
						blockingmobj is "Trilobite"
						&&target
						&&target.target!=blockingmobj
					)continue;

					int pcbak=blockingmobj.painchance;
					blockingmobj.painchance=max(pcbak,240);
					blockingmobj.DamageMobj(self,target,random(1,3),"electrical");
					blockingmobj.painchance=pcbak;

					A_StartSound("caco/ballcrack",CHAN_WEAPON);
					while(random(0,2))A_SpawnParticle("white",
						SPF_RELATIVE|SPF_FULLBRIGHT,35,frandom(4,8),0,
						frandom(-4,4),frandom(-4,4),frandom(0,4),
						frandom(-1,1),frandom(-1,1),frandom(1,2),
						frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
					);
					if(random(0,3)){
						setorigin((pos.xy+frac.xy,pos.z),true);
						stamina-=1;
						vel*=0.9;
						continue;
					}
				}

				bmissile=false;
				bnointeraction=true;

				//kaBOOM
				A_HDBlast(
					blastradius:128,blastdamage:128,blastdamagetype:"electrical",
					pushradius:256,pushamount:512,pushmass:true,
					immolateradius:72,immolateamount:random(30,80),immolatechance:40,
					hurtspecies:false
				);
				distantnoise.make(self,"caco/bigexplodefar");
				A_StartSound("caco/bigexplode",CHAN_VOICE);
				A_StartSound("caco/ballecho",CHAN_BODY);
				A_StartSound("caco/bigcrack",5);

				A_SetSize(radius*2,height*1.4);
				if(
					abs(floorz-pos.z)<10
					||abs(ceilingz-(pos.z+height))<10
					||!checkmove(pos.xy,PCM_NOACTORS|PCM_DROPOFF)
				){
					A_SpawnChunks("HugeWallChunk",12,4,12);
					A_SpawnChunks("BigWallChunk",12,4,12);
					A_SpawnChunks("HDSmoke",3,0,2);
				}
				
				DistantQuaker.Quake(self,4,35,512,10);
				vel=(0,0,0.4);
				scale*=2.;
				setstatelabel("death");
				break;
			}
			addz(frac.z);
			if(pos.z<floorz){
				setz(floorz);
				vel.z=0;
			}else if(pos.z+height>ceilingz){
				setz(ceilingz-height);
				vel.z=0;
			}
		}
		vel.x*=frandom(0.9,1.05);
		vel.y*=frandom(0.9,1.05);
		vel.z*=frandom(0.9,1.05);
		if(accuracy>100&&tracer&&checksight(tracer)){
			A_Face(tracer,0,0,FAF_TOP);
			A_ChangeVelocity(cos(pitch),0,-sin(pitch),CVF_RELATIVE);
		}else if(!random(0,50))A_ChangeVelocity(5,0,0.2,CVF_RELATIVE);
		accuracy--;
		if(accuracy<0)accuracy=160;

		NextTic();
	}
	states{
	spawn:
		BAL2 ABABABABAB 1 light("PLAZMABX1");
		BAL2 A 0 A_Jump(24,"castspell");
		loop;
	castspell:
		BAL2 A 0{
			double achange=random(0,3)?frandom(-24,24):frandom(0,360);
			if(!random(0,3))vel.z=frandom(-vel.z*0.3,vel.z);
			vel.xy=rotatevector(vel.xy,achange);

			if(foowizard){
				int warptimes=random(3,7);
				double spdbak=speed;
				speed=100;
				for(int i=0;i<warptimes;i++){
					A_Wander();
				}
				speed=spdbak;
				setz(frandom(floorz,ceilingz-height));
			}
			if(foocleric){
				if(!tracer){
					foocleric=false;
					foowizard=true;
					return;
				}
				actor itt=null;
				actoriterator it=level.createactoriterator(FOOF_TID,"FooFighter");
				while(itt=it.next()){
					if(
						FooFighter(itt)
						&&checksight(itt)
					)itt.vel+=itt.vec3to(tracer).unit()*2;
				}
			}
		}goto spawn;
	death:
		BAL2 CDE 3 light("BAKAPOST1");
		BAL2 E 3 light("PLAZMABX2") A_FadeOut(0.3);
		wait;
	}
}

class FoofPuff:Actor{
	default{
		+nointeraction +bloodlessimpact
		decal "";
	}
	states{spawn:TNT1 A 0;stop;}
}
class Foof:HDFireball{
	default{
		height 12;radius 12;
		gravity 0;
		decal "BulletScratch";
		damagefunction(random(20,40));
		hdfireball.firefatigue int(HDCONST_MAXFIREFATIGUE*0.25);
	}
	void ZapSomething(){
		roll=frandom(0,360);
		A_StartSound("misc/arczap",CHAN_BODY);
		blockthingsiterator it=blockthingsiterator.create(self,72);
		actor tb=target;
		actor zit=null;
		bool didzap=false;
		while(it.next()){
			if(
				it.thing.bshootable
				&&abs(it.thing.pos.z-pos.z)<72
			){
				zit=it.thing;
				if(
					zit.health>0
					&&checksight(it.thing)
					&&(
						!tb
						||zit==tb.target
						||!(zit is "Trilobite")
					)
				){
					A_Face(zit,0,0,flags:FAF_MIDDLE);
					CacoZapArc(self,zit,ARC2_RANDOMDEST);
					zit.damagemobj(self,tb,random(0,7),"electrical");
					didzap=true;
					break;
				}
			}
		}
		if(!zit||zit==tb){pitch=frandom(-90,90);angle=frandom(0,360);}
		if(!didzap)CacoZapArc(self,null,ARC2_SILENT,radius:32,height:32,pvel:vel);

		A_FaceTracer(4,4);
		if(
			bmissile
			&&tracer
		){
			vector3 vvv=tracer.pos-pos;
			if(vvv.x||vvv.y||vvv.z){
				vvv*=1./max(abs(vvv.x),abs(vvv.y),abs(vvv.z));
				vel+=vvv;
			}
		}
		if(pos.z-floorz<24)vel.z+=0.3;
	}
	states{
	spawn:
		BAL2 A 0 ZapSomething();
		BAL2 AB 2 light("PLAZMABX1") A_Corkscrew();
		loop;
	death:
		BAL2 C 0 A_SprayDecal("CacoScorch",radius*2);
		BAL2 C 0 A_StartSound("misc/fwoosh",5);
		BAL2 CDE 3 light("BAKAPOST1") ZapSomething();
	death2:
		BAL2 E 0 ZapSomething();
		BAL2 E 3 light("PLAZMABX2") A_FadeOut(0.3);
		loop;
	}
}

class Triloball:IdleDummy{
	default{
		+extremedeath
		+forcexybillboard +rollsprite +rollcenter
		renderstyle "add";
		scale 1.8; alpha 0.6;
	}
	double theight;
	override void tick(){
		if(!target){destroy();return;}
		if(isfrozen()){
			clearinterpolation();
			return;
		}
		setorigin((angletovector(target.angle,target.radius),theight)+target.pos,false);
		roll=frandom(0,360);
		alpha=random(0,1)?frandom(0.8,1.6):frandom(0,0.3);

		NextTic();
	}
	states{
	spawn:
		BAL2 A 40 bright light("BAKAPOST1") nodelay{
			if(target)target.tracer=self;
			A_StartSound("caco/charge",CHAN_AUTO,attenuation:1.);
			theight=target.height*0.6;
		}stop;
	}
}



enum CacoNums{
	CACO_MAXHEALTH=420,

	FOOF_TID=424707,
}
class CacoChunk:WallChunk{
	override void postbeginplay(){
		super.postbeginplay();
		if(!target)return;
		if(random(-CACO_MAXHEALTH*2,CACO_MAXHEALTH)>target.health){
			A_SetTranslation("AllBlue");
		}else{
			scale*=frandom(0.8,2.);
			if(!random(0,3))A_SetTranslation("AllPurple");
			else A_SetTranslation("AllRed");
		}
	}
}
class CacoShellBlood:BloodSplatSilent{
	override void postbeginplay(){
		bloodsplatsilent.postbeginplay();
		A_StartSound("misc/bulletflesh",volume:0.02);
		A_SpawnChunks("CacoChunk",random(1,7),1,7);
		if(
			!hdmobbase(target) //HOW THE FUCK.
			||hdmobbase(target).bdoesntbleed
		)destroy();
	}
}
class Trilobite:HDMobBase replaces Cacodemon{
	int charge;
	double sweepangle;
	default{
		health CACO_MAXHEALTH;
		radius 24;
		meleerange 96;
		height 48;
		mass 400;
		+float +nogravity
		seesound "caco/sight";
		painsound "caco/pain";
		deathsound "caco/death";
		activesound "caco/active";
		hitobituary "$ob_cacohit";
		tag "$cc_caco";

		+noblooddecals
		+pushable
		+hdmobbase.doesntbleed
		+hdmobbase.headless
		+hdmobbase.onlyscreamondeath
		gravity HDCONST_GRAVITY*0.4;
		pushfactor 0.05;
		bloodtype "CacoShellBlood";
		bloodcolor "10 00 90";
		painchance 90;
		deathheight 29;
		damagefactor "piercing", 0.86;
		obituary "$OB_TRILOBITE";
		speed 4;
		maxtargetrange 8192;
	}
	override void beginplay(){
		super.beginplay();
		resize(0.8,1.1);
		speed*=3.-2*scale.x;
	}
	void A_CacoCorpseZap(){
		A_StartSound("caco/arczap",volume:0.3,attenuation:2.);
		A_CustomRailgun((random(1,4)),0,"","blueviolet",
			RGF_SILENT|RGF_NOPIERCING|RGF_FULLbright|RGF_CENTERZ,
			0,4000,"HDArcPuff",180,180,random(60,160),18,1.4,1.5
		);
	}
	void A_CacoMeleeZap(){
		A_FaceTarget(10,10);
		actor tgt=tracer;
		if(target){
			double range=meleerange+target.radius*1.14;
			range*=range;
			if(range>distance3dsquared(target)){
				double directness=20-absangle(angleto(target),angle);
				if(directness>0){
					tgt=target;
					CacoZapArc(tgt,tgt,ARC2_SILENT);

					vector3 pvv=(
						(tgt.pos.xy,tgt.pos.z+tgt.height*0.5)
						-(pos.xy,pos.z+height*0.5)
					).unit();
					vel-=pvv*0.2;
					if(!tgt.bdontthrust){
						if(tgt.pos.z<=tgt.floorz)pvv.z+=3;
						tgt.vel-=pvv*100/max(1,tgt.mass);
						tgt.angle+=frandom(-1,1);
						tgt.pitch+=frandom(-1,1);
					}

					target.damagemobj(tracer,self,int(frandom(1,directness+2)),"electrical");
				}
			}
		}
		CacoZapArc(tracer,tgt,ARC2_RANDOMDEST,radius:64,height:64);
	}
	override bool CanResurrect(actor other,bool passive){
		return !passive||tics<0;
	}
	override double bulletresistance(double hitangle){
		return max(0,health*0.006);
	}
	states{
	spawn:
		HEAD A 10{
			A_HDLook();
			givebody(3);
			if(health>(CACO_MAXHEALTH*0.5))bfloatbob=false;
			if(!bambush&&!random(0,10))A_HDWander();
		}wait;
	see:
		HEAD A 4{
			bnogravity=true;
			if(health>(CACO_MAXHEALTH*0.5))bfloatbob=false;
			givebody(1);
			A_HDChase();
		}loop;
	pain:
		HEAD E 2{
			if(health<(CACO_MAXHEALTH*0.4))bfloatbob=true;
			else if(health<(CACO_MAXHEALTH*0.8))bdoesntbleed=false;
			bnogravity=false;
		}
		HEAD F 6 A_Vocalize(painsound);
		HEAD E 3 A_SetGravity(clamp(1.-(health/CACO_MAXHEALTH),0,HDCONST_GRAVITY));
		---- A 0 setstatelabel("see");
	missile:
		HEAD A 3 A_TurnToAim(10);
		loop;
	shoot:
		HEAD A 0{vel.z+=frandom(-1,2);}
		HEAD A 0 A_JumpIf(charge>30,"bigzap");
	foof:
		HEAD B 2{
			A_FaceLastTargetPos(3,32,FLTP_TOP);
			A_LeadTarget(lasttargetdist*0.15,maxturn:45);
			charge++;
		}
		HEAD C 1;
		HEAD D 6 bright A_SpawnProjectile("Foof",flags:CMF_AIMDIRECTION,pitch);
		HEAD C 2;
		HEAD B 3;
		HEAD A 4 A_Jump(8,"foof");
		---- A 0 setstatelabel("see");
	bigzap:
		HEAD B 2;
		HEAD C 3;
		HEAD D 36 bright{
			vel.z+=frandom(0.2,1.2);
			A_FaceLastTargetPos(40,32,0);
			A_LeadTarget(lasttargetdist*0.01);
			bnopain=true;
			A_SpawnProjectile("Triloball",28,0,0,CMF_AIMDIRECTION,pitch);
			if(!A_JumpIfCloser(1024,"null")&&random(0,3)){
				charge=666;
				A_StartSound("caco/sight",CHAN_VOICE,volume:1.,attenuation:0.1);
				A_FaceLastTargetPos(4,32,0);
			}else A_StartSound("caco/sight",CHAN_VOICE);
		}
		HEAD D 24{
			distantnoise.make(self,"caco/bigexplodefar2");
			A_StartSound("caco/bigshot",CHAN_WEAPON);
			A_ChangeVelocity(-cos(pitch)*3,0,sin(pitch),CVF_RELATIVE);
			if(charge==666){
				A_FaceLastTargetPos(1,32,0);
				HDBulletActor.FireBullet(self,"KekB",32);
			}else{
				A_CustomRailgun(random(100,200),50,"","azure",
					RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
					0,40.0,null,0,0,2048,
					12,0.4,2.0,"",-4
				);
				actor bll=LineAttack(
					angle,2048,pitch,random(128,512),"","FooFighter"
				);
				if(bll){
					CacoZapArc(bll,self);
					bll.stamina=0;
						for(int i=0;i<3;i++){
							bll.tracer=target;
							bll.A_SpawnItemEx("FooFighter",
								0,0,3,frandom(-1,4),0,frandom(1,5),
								angle+frandom(-50,50),
								SXF_ABSOLUTEANGLE|
								SXF_NOCHECKPOSITION|
								SXF_TRANSFERPOINTERS
							);
						}
				}
			}
			charge=0;
			firefatigue+=int(HDCONST_MAXFIREFATIGUE);
			bnopain=false;
		}
		HEAD C 6;
		HEAD B 3;
		HEAD A 6;
		---- A 0 setstatelabel("see");
	melee:
		HEAD BB 2 A_FaceTarget(40,40);
		HEAD C 4{
			angle+=frandom(-10,10);
			pitch+=frandom(-10,10);
			A_StartSound("caco/sight");
		}
		HEAD D 2 bright A_SpawnProjectile("Triloball",28);
		HEAD DDDDDDDDDDDD 2 bright A_CacoMeleeZap();
		HEAD C 4;
		HEAD B 2;
		HEAD A 6;
		---- A 0 setstatelabel("see");
	death.spawndead:
		HEAD G 0{
			bfloatbob=false;
			bnogravity=false;
		}goto dead;
	death:
		HEAD F 3{
			bfloatbob=false;
			bnogravity=false;
			gravity=HDCONST_GRAVITY;
			A_StartSound(seesound,CHAN_VOICE);
		}
		HEAD GH 3;
		HEAD H 2 A_JumpIf(vel.z<=0,"deadsplatting");
		wait;
	deadsplatting:
		HEAD I 3 A_StartSound("caco/death",CHAN_VOICE,CHANF_OVERLAP); //don't use "deathsound"
		HEAD J 2;
		HEAD JKKKKKKK 1 light("PLAZMABX1") A_CacoCorpseZap();
		HEAD L 1 A_SetTics(random(5,25));
		HEAD LLLLL 2 light("PLAZMABX1") A_CacoCorpseZap();
	deadzapping:
		HEAD L 1 light("PLAZMABX1") A_SetTics(random(1,4));
		HEAD L 0 A_StartSound("caco/arczap",volume:0.6,attenuation:2.);
		HEAD L 1{
			if(!random(0,3))ArcZap(self,radius*1.6,8,true);else CacoZapArc(self);
			if(!random(0,3))A_SpawnItemEx(bloodtype,
				frandom(-radius,radius),0,frandom(0,height)
				,frandom(0,1),0,frandom(0,1),frandom(0,360),
				SXF_NOCHECKPOSITION|SXF_USEBLOODCOLOR
			);
			if(!random(0,3))HDMobFallSquishThinker.Init(self,frandom(-5,5),scale);
			if(!(level.time&0))A_SetTics(random(1,accuracy));
			accuracy++;
			if(accuracy>100)setstatelabel("dead");
		}
		loop;
	dead:
		HEAD L -1;
		stop;
	raise:
		---- A 0{
			accuracy=0;
		}
		HEAD L 8 A_UnSetFloorClip;
		HEAD KJIHG 8;
		#### A 0 A_Jump(256,"see");
	}
}
class DeadTrilobite:Trilobite replaces DeadCacodemon{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}

class kekb:HDBulletActor{
	default{
		+bright +nogravity +rollcenter +rollsprite
		renderstyle "add";
		speed 666;
		translation 2;
		height 4;radius 3;
		missileheight 2;
	}
	override void HitGeometry(
		line hitline,
		sector hitsector,
		int hitside,
		int hitpart,
		vector3 vu,
		double lastdist
	){
		bulletdie();
	}
	vector3 oldpos;
	override void Tick(){
		oldpos=pos;
		super.Tick();
		if(1){
			vector3 velunit=(oldpos-pos).unit()*40;
			vector3 spawnpos=velunit;
			vector3 offs=(0,0,0);
			for(int i=0;i<700;i+=20){
				A_SpawnParticle(
					"azure",SPF_FULLBRIGHT,40,frandom(3,7),0,
					spawnpos.x+offs.x,spawnpos.y+offs.y,spawnpos.z+offs.z,
					offs.x*0.1,offs.y*0.1,offs.z*0.1
				);
				offs=(
					clamp(offs.x+frandom(-3,3),-10,10),
					clamp(offs.y+frandom(-3,3),-10,10),
					clamp(offs.z+frandom(-3,3),-10,10)
				);
				spawnpos+=velunit;
			}
		}
	}
	void A_KekSplode(){
		bmissile=false;
		bnointeraction=true;
		vel=(0,0,0.2);
		roll=frandom(0,360);
		scale=(randompick(-1,1)*2.,2.);

		A_AlertMonsters();
		A_HDBlast(
			320,random(24,42)*10,128,"slashing",
			pushradius:420,pushamount:420,
			immolateradius:256,immolateamount:-200,immolatechance:90
		);
		A_SprayDecal("BusterScorch",14);
		distantnoise.make(self,"world/rocketfar");
		distantnoise.make(self,"caco/bigexplodefar2",2.);
		DistantQuaker.Quake(self,
			5,50,2048,8,128,256,256
		);

		//check floor and ceiling and spawn more debris
		distantnoise.make(self,"world/rocketfar");
		for(int i=0;i<3;i++)A_SpawnItemEx("WallChunker",
			frandom(-4,4),frandom(-4,4),-4,
			flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);

		//"open" a door
		doordestroyer.destroydoor(self,160,32);
	}
	override void postbeginplay(){
		super.postbeginplay();
		actor kb=spawn("KekBlight",pos,ALLOW_REPLACE);
		kb.target=self;
	}
	states{
	spawn:
		BAL7 AB 1;
		loop;
	death:
		TNT1 AAAA 0 Spawn("HDExplosion",pos+(frandom(-4,4),frandom(-4,4),frandom(-4,4)),ALLOW_REPLACE);
		TNT1 AAAA 0 Spawn("HDSmoke",pos+(frandom(-4,4),frandom(-4,4),frandom(-4,4)),ALLOW_REPLACE);
		TNT1 A 0 A_KekSplode();
		TNT1 AAAAAAAA 0 ArcZap(self);
		BAL2 CCCDDDEEEE 1{
			roll+=20;
			scale*=1.1;
			alpha*=0.9;
			ArcZap(self);
			ArcZap(self);
		}
		TNT1 AAAAAAAAAAAAAAAAAAAA 1 ArcZap(self);
		stop;
	}
}
class KekBlight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=240;
		args[1]=196;
		args[2]=64;
		args[3]=196;
		args[4]=0;
	}
	override void tick(){
		if(isfrozen())return;
		if(bstandstill||!target){
			args[3]+=randompick(-30,15,-60);
			if(args[3]<1)destroy();
			return;
		}
		args[3]=randompick(164,296,328,436);
		if(!target.bmissile){
			args[0]=255;
			args[1]=250;
			args[2]=128;
			args[3]=300;
			args[4]=0;
			bstandstill=true;
		}
	}
}



