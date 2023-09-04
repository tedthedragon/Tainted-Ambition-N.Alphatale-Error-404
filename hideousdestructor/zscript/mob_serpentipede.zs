// ------------------------------------------------------------
// Imp
// ------------------------------------------------------------

class ReverseImpBallTail:IdleDummy{
	default{
		+nointeraction +forcexybillboard -invisible
		renderstyle "add";
		scale 0.6;alpha 0;
	}
	override void Tick(){
		A_SpawnParticle("99 44 11",0,random(30,40),frandom(1.2,2.1),0,frandom(-4,4),frandom(-4,4),frandom(0,2),frandom(-1,1),frandom(-1,1),frandom(0.9,1.3));
		super.Tick();
	}
	states{
		spawn:
			BAL1 EEDC 2 bright A_FadeIn(0.2);
		death:
			BAL1 BAB 2 bright A_FadeIn(0.2);
			BAL1 A 0{
				if(target&&target.health<1)A_Immolate(target,target.target,random(20,50));
			}
			stop;
	}
}
class HDImpBallTail:HDFireballTail{
	default{
		translation "ice";
		renderstyle "subtract";
		deathheight 0.9;
		gravity 0;
	}
	states{
	spawn:
		//BAL1 CDE 5{
		RSMK ABC 5{
			roll+=10;
			scale.x*=randompick(-1,1);
		}loop;
	}
}
class HDImpBall:HDFireball{
	default{
		+seekermissile
		missiletype "HDImpBallTail";
		decal "BrontoScorch";
		speed 12;
		damagetype "electrical";
		gravity 0;
		hdfireball.firefatigue int(HDCONST_MAXFIREFATIGUE*0.15);
	}
	double initangleto;
	double inittangle;
	double inittz;
	vector3 initpos;
	vector3 initvel;
	virtual void A_HDIBFly(){
		roll+=10;
		if(
			!(getage()&(1|2))
			||!A_FBSeek()
		){
			vel*=0.99;
			A_FBFloat();

			stamina++;
			switch(stamina){
			case 8:
			case 7:
				A_ChangeVelocity(0,-1,0,CVF_RELATIVE);break;
			case 6:
			case 5:
				A_ChangeVelocity(0,0,-1,CVF_RELATIVE);break;
			case 4:
			case 3:
				A_ChangeVelocity(0,1,0,CVF_RELATIVE);break;
			case 2:
			case 1:
				A_ChangeVelocity(0,0,1,CVF_RELATIVE);break;
			default:
				A_ChangeVelocity(cos(pitch)*0.1,0,-sin(pitch)*0.1,CVF_RELATIVE);
				stamina=0;break;
			}
		}
	}
	void A_ImpSquirt(){
		roll=frandom(0,360);alpha*=0.96;scale*=frandom(1.,0.96);
		if(!tracer)return;
		double diff=max(
			absangle(initangleto,angleto(tracer)),
			absangle(inittangle,tracer.angle),
			abs(inittz-tracer.pos.z)*0.05
		);
		int dmg=int(max(0,10-diff*0.1));
		if(
			tracer.bismonster
			&&!tracer.bnopain
			&&tracer.health>0
		)tracer.angle+=randompick(-10,10);

		//do it again
		initangleto=angleto(tracer);
		inittangle=tracer.angle;
		inittz=tracer.pos.z;

		setorigin((pos+(tracer.pos-initpos))*0.5,true);
		if(dmg){
			tracer.A_GiveInventory("Heat",dmg);
			tracer.damagemobj(self,target,max(1,dmg>>2),"hot");
		}
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(vel.x||vel.y||vel.z)initvel=vel.unit();
		else{
			double cp=cos(pitch);
			initvel=(cp*cos(angle),cp*sin(angle),-sin(pitch));
		}
		initvel*=0.3;
	}
	void A_FBTailAccelerate(){
		A_FBTail();
		vel+=initvel;
	}
	states{
	spawn:
		BAL1 ABABABABAB 2 A_FBTailAccelerate();
		BAL1 A 0 A_ChangeVelocity(0,-1,-1,CVF_RELATIVE);
	spawn2:
		BAL1 AB 3 A_HDIBFly();
		loop;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
		TNT1 A 0{
			A_Scream();
			tracer=null;
			if(blockingmobj){
				if(
					blockingmobj is "Serpentipede"
					&&(!target||blockingmobj!=target.target)
				)blockingmobj.givebody(random(1,10));
				else{
					if(!blockingline)tracer=blockingmobj;
					blockingmobj.damagemobj(self,target,random(6,18),"electrical");
				}
			}
			if(tracer){
				initangleto=angleto(tracer);
				inittangle=tracer.angle;
				inittz=tracer.pos.z;
				initpos=tracer.pos-pos;

				let hdt=hdmobbase(tracer);

				//HEAD SHOT
				if(
					pos.z-tracer.pos.z>tracer.height*0.8
					&&(
						!hdt
						||(
							!hdt.bnovitalshots
							&&!hdt.bheadless
						)
					)
				){
					if(hd_debug)A_Log("HEAD SHOT");
					bpiercearmor=true;
				}
			}
			A_SprayDecal("BrontoScorch",radius*2);
		}
		BAL1 ABCCDDEEEEEEE 3 A_ImpSquirt();
		stop;
	}
}


// ------------------------------------------------------------
// Fighter
// ------------------------------------------------------------
class Serpentipede:HDMobBase{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Imp Fighter"
		//$Sprite "TROOA1"

		+hdmobbase.chasealert

		mass 100;
		+floorclip
		+hdmobbase.climber
		seesound "imp/sight";
		painsound "imp/pain";
		deathsound "imp/death";
		activesound "imp/active";
		meleesound "imp/melee";
		hdmobbase.downedframe 12;
		tag "$CC_IMP";

		damagefactor "hot",0.66;
		health 100;
		gibhealth 100;

		radius 14;
		height 56;
		hdmobbase.gunheight 36;
		deathheight 15;
		speed 12;
		maxdropoffheight 128;

		damage 4;
		meleedamage 4;

		painchance 80;
		translation "MediumImp";
		obituary "$OB_IMP";
		hitobituary "$OB_IMP_HIT";
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(bplayingid){
			bsmallhead=true;
			bbiped=true;
			A_SetSize(13,54);
		}
		resize(0.8,1.1);
		voicepitch=frandom(0.9,1.1);

		maxstepheight=bplayingid?24:36;
	}
	override void CheckFootStepSound(){
		if(bplayingid)HDHumanoid.FootStepSound(self,0.2,drysound:"imp/step");
		else A_StartSound("serpentipede/step",88,CHANF_OVERLAP);
	}
	override void deathdrop(){
		if(!bfriendly)DropNewItem("HDHandgunRandomDrop");
	}
	bool strafeleft;
	void A_Strafe(){
		A_FaceLastTargetPos(10);
		strafeleft=(random(0,2))?blefthanded:!blefthanded;
		vector2 newdir=angletovector((strafeleft?angle+90:angle-90)+frandom(-20,20),frandom(0.5,2.5));
		vel.xy+=newdir;
		if(floorz==pos.z)vel.z+=randompick(-2.,1.);
	}
	states{
	spawn:
		TROO A 0;
	idle:
		#### AAABBCCCDD 8 A_HDLook();
		#### A 0 A_SetAngle(angle+random(-4,4));
		#### A 1 A_SetTics(random(1,3));
		---- A 0 A_Jump(216,2);
		---- A 0 A_Vocalize(activesound);
		#### A 0 A_JumpIf(bambush,"idle");
		#### A 0 A_Jump(32,"spawn2");
		loop;
	spawn2:
		#### ABCD 4 A_HDWander(CHF_LOOK);
		#### A 0 A_Jump(198,"spawn2");
		#### A 0 {vel.xy-=(cos(angle),sin(angle))*0.4;}
		#### A 0 A_Jump(64,"idle");
		loop;

	see:
		#### ABCD 4 A_HDChase();
		#### A 0 A_Jump(116,"roam","roam","roam","roam2","roam2");
		loop;
	roam:
		#### AABB 3 A_Watch();
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_JumpIf(targetinsight||!random(0,31),"see");
		#### ABCD 6 A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(80,"roam");
		loop;

	missile:
		#### ABCD 4{
			A_Strafe();
			A_TurnToAim(40,gunheight);
		}
		loop;
	shoot:
		#### E 0 A_Jump(16,"hork");
		goto lead;

	lead:
		#### E 0 A_Strafe();
		#### E 4 A_FaceLastTargetPos(40,gunheight);
		#### E 0 A_Strafe();
		#### E 1 A_FaceLastTargetPos(20,gunheight);
		#### E 0 A_Strafe();
		#### F 4 A_LeadTarget(min(20,lasttargetdist/getdefaultbytype("HDImpBall").speed));
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,gunheight,256,10,10,flags:HDMobAI.TS_GEOMETRYOK),"see");
		#### G 6 A_SpawnProjectile("HDImpBall",34,0,0,CMF_AIMDIRECTION,pitch-frandom(0,0.1));
		#### F 4 A_ChangeVelocity(0,frandom(-3,3),0,CVF_RELATIVE);
		---- A 0 A_JumpIfTargetInsideMeleeRange("melee");
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,gunheight,512,10,10,flags:HDMobAI.TS_GEOMETRYOK),"see");
		#### E 0 A_Jump(16,"see");
		#### E 0 A_Jump(140,"coverfire");
		---- A 0 setstatelabel("see");

	spam:
		#### E 3 A_SetTics(random(4,6));
		#### EF 2 A_Strafe();
		#### G 6 A_SpawnProjectile("HDImpBall",gunheight,0,frandom(-3,4),CMF_AIMDIRECTION,pitch+frandom(-2,1.8));
		#### F 4;
		#### F 0 A_JumpIf(firefatigue>HDCONST_MAXFIREFATIGUE,"pain");
		//fall through to more cover fire
	coverfire:
		---- A 0 A_JumpIfTargetInLOS("see");
		#### EEEEE 3 A_Coverfire("coverdecide");
		---- A 0 setstatelabel("see");
	coverdecide:
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,32,512,10,10,flags:HDMobAI.TS_GEOMETRYOK),"see");
		---- A 0 A_Jump(180,"spam");
		---- A 0 A_Jump(90,"hork");
		---- A 0 setstatelabel("missile");
	hork:
		#### E 0 A_Jump(156,"spam");
		---- A 0 A_FaceLastTargetPos(40,gunheight);
		#### E 2 A_Strafe();
		#### E 0 A_Vocalize(seesound);
		#### EEEEE 2 A_SpawnItemEx("ReverseImpBallTail",4,24,gunheight,1,0,0,0,160);
		#### EF 2 A_Strafe();
		#### G 0 A_SpawnProjectile("HDImpBall",gunheight,0,(frandom(-2,10)),CMF_AIMDIRECTION,pitch+frandom(-4,3.6));
		#### G 0 A_SpawnProjectile("HDImpBall",gunheight,0,(frandom(-4,4)),CMF_AIMDIRECTION,pitch+frandom(-4,3.6));
		#### G 0 A_SpawnProjectile("HDImpBall",gunheight,0,(frandom(-2,-10)),CMF_AIMDIRECTION,pitch+frandom(-4,3.6));
		#### GGFE 5 A_SetTics(random(4,6));
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,32,256,10,10,flags:HDMobAI.TS_GEOMETRYOK),"see");
		#### E 0 A_Watch();
		---- A 0 setstatelabel("see");
	melee:
		#### EE 4 A_FaceTarget();
		#### F 2;
		#### G 8 A_CustomMeleeAttack(random(10,30),meleesound,"","claws",true);
		#### F 4;
		---- A 0 setstatelabel("see");
	pain:
		#### H 3 A_GiveInventory("HDFireEnder",3);
		#### H 3 A_Vocalize(painsound);
		---- A 0 A_ShoutAlert(0.4,SAF_SILENT);
		#### A 2 A_FaceTarget();
		#### BCD 2 A_FastChase();
		#### A 0 A_JumpIf(firefatigue>(HDCONST_MAXFIREFATIGUE*1.6),"see");
		goto missile;
	death:
		#### I 6 A_Gravity();
		#### J 6 A_Vocalize(deathsound);
		#### KL 5;
	dead:
	death.spawndead:
		#### L 3 canraise A_JumpIf(abs(vel.z)<2,1);
		loop;
		#### M 5 canraise A_JumpIf(abs(vel.z)>=2,"Dead");
		loop;
	xxxdeath:
		#### N 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### O 5 A_XScream();
		#### PQRS 5;
		#### T 5;
		goto xdead;
	xdeath:
		---- A 0 A_Gravity();
		#### N 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### O 5 A_XScream();
		#### O 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### P 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### QRS 5;
		#### T 5;
	xdead:
		#### T 5 canraise A_JumpIf(abs(vel.z)<2,1);
		wait;
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2,"XDead");
		wait;
	raise:
		#### M 4;
		#### ML 6;
		#### KJI 4;
		---- A 0 setstatelabel("see");
	ungib:
		#### U 6;
		#### UT 8;
		#### SRQ 6;
		#### PONH 4;
		---- A 0 setstatelabel("see");
	falldown:
		#### H 5;
		#### I 5 A_Vocalize(deathsound);
		#### JJKKL 2 A_SetSize(-1,max(deathheight,height-10));
		#### L 2 A_SetSize(-1,deathheight);
		#### M 10 A_KnockedDown();
		wait;
	standup:
		#### LK 5;
		#### J 0 A_Jump(64,2);
		#### J 0 A_Vocalize(seesound);
		#### JI 4 {vel.xy-=(cos(angle),sin(angle))*0.3;}
		#### HE 5;
		---- A 0 setstatelabel("see");
	}
}


// ------------------------------------------------------------
// Healer
// ------------------------------------------------------------
class tempshieldimp:tempshield{
	default{
		+noblooddecals
		bloodtype "ShieldNeverBlood";
		radius 18;height 26;
		stamina 10;
	}
}
class ShieldImpBall:HDImpBall{
	default{
		+seekermissile +forcexybillboard
		decal "DoomImpScorch";
		-noblockmap
		+shootable +mthruspecies +noblooddecals
		scale 1.2;
		height 20;
		radius 20;
		speed 8;
		damagetype "electrical";
		damage 5;
		bloodtype "ShieldNeverBlood";
		health 1;
		hdfireball.firefatigue int(HDCONST_MAXFIREFATIGUE*0.6);
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!bmissile)return 0;
		ExplodeMissile();
		tempshield.spawnshield(self,"tempshieldimp",false,8);
		A_Scream();
		bmissile=false;
		setstatelabel("death");
		return 0;
	}
	vector2 savedvel;
	states{
	spawn:
		BAL1 A 0 nodelay{
			A_StartSound("imp/attack",CHAN_VOICE);
			savedvel=vel.xy;
		}
		BAL1 ABABAB 2 bright;
		BAL1 B 2 A_JumpIfTargetInLOS("see");
		BAL1 ABABAB 2 bright A_SeekerMissile(6,9);
	spawn2:
		BAL1 AB 3 A_HDIBFly();
		TNT1 A 0 {
			savedvel=vel.xy;
			A_FBTail();
			A_ChangeVelocity(
				0,
				sin(getage()),
				sin(level.time),
				CVF_RELATIVE
			);
			if(
				tracer
				&&(
					floorz>pos.z-16
					||floorz<pos.z+64
				)
				&&checksight(tracer)
			)A_SeekerMissile(6,9);
		}
		loop;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),0,savedvel.x*0.2+frandom(-3,3),savedvel.y*0.2+frandom(-3,3),frandom(1,3),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		BAL1 A 2{
			vel.xy=savedvel*0.1;vel.z=1;
			A_NoBlocking();
		}
		BAL1 A 0{bshootable=false;}
		BAL1 BBCC 1 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,savedvel.x*0.2+frandom(-3,3),savedvel.y*0.2+frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		TNT1 A 0 A_FadeOut(0.2);
		BAL1 CCCC 1 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		TNT1 A 0 A_FadeOut(0.2);
		BAL1 DDDD 1 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		BAL1 E 0 bright A_FadeOut(0.2);
		TNT1 A 0 A_Gravity();
		TNT1 A 0 A_GiveInventory("Heat",300);
		BAL1 E 2 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		BAL1 E 2 bright A_FadeOut(0.2);
		BAL1 E 2 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		BAL1 E 2 bright A_FadeOut(0.2);
		TNT1 AAAAAAA 4 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		TNT1 AAAAAAA 6 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		TNT1 AAAAAAA 14 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		stop;
	}
}
class Regentipede:Serpentipede{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Imp Healer"
		//$Sprite "TROOA1"

		-missilemore
		speed 8;
		health 120;
		gibhealth 140;
		translation "LightImp";
		seesound "";
		activesound "";
		meleedamage 3;
		obituary "$OB_IMPH";
		hitobituary "$OB_IMPH_HIT";
		tag "$CC_IMPH";
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.6,0.85);
	}
	states{
	missile:
		#### E 0 A_Jump(128,"Missile2");
		#### EF 4 A_FaceLastTargetPos(50,32);
		#### G 8 A_SpawnProjectile("HDImpBall",gunheight,0,(random(-6,6)),CMF_AIMDIRECTION,pitch);
		#### F 5;
		---- A 0 setstatelabel("see");
	missile2:
		#### E 2 A_FaceLastTargetPos(50,32);
		#### E 0 A_Vocalize(seesound);
		#### EEEEE 2 A_SpawnItemEx("ReverseImpBallTail",3,19,gunheight,1,0,0,0,160);
		#### F 4 A_FaceLastTargetPos(50,32);
		#### F 4 A_FaceLastTargetPos(50,32);
		#### G 0 A_SpawnProjectile("ShieldImpBall",gunheight,8,0,CMF_AIMDIRECTION,pitch);
		#### GGFE 5;
		---- A 0 setstatelabel("see");
	pain:
		---- A 0 A_GiveInventory("HDFireEnder",5);
		#### H 3;
		#### H 3 A_Vocalize(painsound);
		---- A 0 setstatelabel("see");
	heal:
		#### AHAHAHAHAHA 4 light("HEAL");
		---- A 0 setstatelabel("see");
	death:
		---- A 0 A_SpawnItemEx("BFGNecroShard",0,0,24,0,0,8,0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,164);
		goto super::death;
	xdeath:
		---- A 0 A_SpawnItemEx("BFGNecroShard",0,0,24,0,0,8,0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,188);
		goto super::xdeath;
	raise:
		#### M 4 A_SpawnItemEx("MegaBloodSplatter",0,0,4,vel.x,vel.y,vel.z+3,0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		#### ML 6;
		#### KJI 4;
		goto pain;
	}
}


// ------------------------------------------------------------
// Fireballer
// ------------------------------------------------------------
class Ardentipede:Serpentipede{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Imp Caster"
		//$Sprite "TROOA1"

		-missilemore
		translation "MageImp";
		speed 10;
		health 110;
		maxdropoffheight 96;
		obituary "$OB_IMPM";
		hitobituary "$OB_IMPM_HIT";
		tag "$CC_IMPM";
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.9,1.2);
	}
	override void tick(){
		super.tick();
		if(instatesequence(curstate,findstate("missile3a")))gravity=0;
		else gravity=HDCONST_GRAVITY;
	}
	states{
	recharge:
		---- A 6;
		#### ABCD 4 {
			hdmobai.wander(self,true);
			if(!random(0,2))stamina>>=1;
		}---- A 0 setstatelabel("see");
	missile:
		---- A 0 A_JumpIf(stamina>random(5,10),"recharge");
		---- A 0 A_JumpIf(health<random(0,200),1);
		goto super::missile;
		---- A 0{
			stamina+=3;
			if(
				CheckTargetInSight()
				||!random(0,15)
			)setstatelabel("missile1");
			else if(
				lasttargetdist>640
				&&random(0,7)
			)setstatelabel("missile3");
			else if(lasttargetdist<256)setstatelabel("missile1");
		}
		goto missile2;
	missile1:
		#### EF 6 A_FaceLastTargetPos(40,32);
		#### G 8 A_SpawnProjectile("ArdentipedeBall",gunheight,0,(random(-6,6)),CMF_AIMDIRECTION,pitch);
		---- A 0 setstatelabel("see");
	missile2:
		#### E 2 A_FaceLastTargetPos(40,gunheight);
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,gunheight,256,10,10,flags:HDMobAI.TS_GEOMETRYOK),"see");
		#### E 2 A_Vocalize(seesound);
		#### EEEEEEE 2 A_SpawnItemEx("ReverseImpBallTail",bplayingid?frandom(3,5):radius,bplayingid?frandom(23,25):0,gunheight+frandom(-1,1),1,0,0,0,160);
		#### F 3 A_FaceLastTargetPos(40,gunheight);
		#### F 3 A_LeadTarget(lasttargetdist*0.08);
		#### G 10{
			stamina+=5;

			let abs=getdefaultbytype("ArdentipedeBall2").speed*2;
			double cp=cos(pitch)*abs;
			double sp=-sin(pitch)*abs;
			vector3 fbpos=(pos.xy,pos.z+gunheight);
			if(bplayingid)fbpos.xy+=angletovector(angle-60,radius*0.8);

			for(int i=0;i<8;i++){
				vector3 rnpos=(frandom(-2,2),frandom(-2,2),frandom(2,4));
				let ab=ArdentipedeBall2(spawn("ArdentipedeBall2",fbpos,ALLOW_REPLACE));
				if(!ab)return;

				ab.target=self;
				ab.tracer=target;
				ab.accelpos=lasttargetpos;

				ab.angle=angle+frandom(-5,5);
				ab.pitch=pitch+frandom(-6,4);

				ab.vel=vel;
				ab.A_ChangeVelocity(cp,0,sp,CVF_RELATIVE);
			}

		}
		#### FE 5;
		---- A 0 setstatelabel("see");
	missile3:
		#### E 0 A_Jump(16,"missile1");
		#### E 0 A_Jump(32,"missile2");
		#### EEH 3{
			A_FaceLastTargetPos(40,gunheight);
			vel.xy*=0.8;
		}
	missile3a:
		#### H 16 bright{
			vel.xy*=0.8;
			CheckTargetInSight();
			A_FaceLastTargetPos(30,gunheight);
			vel.z+=2;
			stamina+=8;
			accuracy=6;
		}
		#### HHHH 2 bright{
			vel.z*=0.6;
		}
		#### HHHHHH 2 bright{
			vel.z+=getgravity();

			CheckTargetInSight();
			A_FaceLastTargetPos(10,gunheight);

			double abp=pitch-accuracy*10.;
			let abs=getdefaultbytype("ArdentipedeBall2").speed;
			double cp=cos(abp)*abs;
			double sp=-sin(abp)*abs;
			vector3 fbpos=(pos.xy,pos.z+gunheight);
			for(int i=0;i<2;i++){
				let ab=ArdentipedeBall2(spawn("ArdentipedeBall2",fbpos,ALLOW_REPLACE));
				if(!ab)return;

				ab.target=self;
				ab.tracer=target;
				ab.accelpos=lasttargetpos;

				ab.angle=i?angle-160:angle+160;
				ab.pitch=abp;

				ab.vel=vel;
				ab.A_ChangeVelocity(cp,0,sp,CVF_RELATIVE);
			}
			accuracy--;
		}
		#### H 6 bright;
	missile3b:
		#### H 8;
		goto missile1;
	pain:
		#### H 3 {
			A_GiveInventory("HDFireEnder",3);
			A_Gravity();
		}
		#### H 3 A_Vocalize(painsound);
		#### A 2 A_FaceTarget();
		#### BCD 2 A_FastChase();
		goto missile;
	}
}

class ArdentipedeBall:HDImpBall{
	default{
		missiletype "ArdentipedeBallTail";
		speed 10;
		scale 1.2;
		hdfireball.firefatigue int(HDCONST_MAXFIREFATIGUE*0.4);
	}
	vector3 lasttracerpos;
	double lasttracerheight;
	override void A_HDIBFly(){
		roll=frandom(0,360);
		let hdm=hdmobbase(target);
		let ttt=tracer;
		if(!ttt&&!!target){
			ttt=target.target;
			tracer=ttt;
		}
		if(!ttt&&!hdm)return;

		vector3 dst;
		double thrust=0.7;

		if(
			!!ttt
			&&HDMath.Vec3Shorter((ttt.pos.xy,ttt.pos.z+ttt.height*0.6)-pos,256)
			&&checksight(ttt)
		){
			lasttracerpos=ttt.pos;
			lasttracerheight=ttt.height;
			thrust=0.9;
		}else if(!!hdm){
			lasttracerpos=hdm.lasttargetpos;
			lasttracerheight=hdm.lasttargetheight;
		}
		dst=lasttracerpos-pos;
		vel*=0.9;

		dst.x+=lasttracerheight*frandom(-0.6,0.6);
		dst.y+=lasttracerheight*frandom(-0.6,0.6);
		dst.z+=lasttracerheight*((!hdm||hdm.bcorpse)?frandom(0.05,0.3):frandom(0.3,0.9));
		vel+=HDMath.CrudeUnit(dst)*thrust;
	}
	states{
	spawn:
		BAL1 ABABABAB 2 A_FBTail();
		goto spawn2;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
		TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,40);}
		goto super::death;
	}
}
class ArdentipedeBall2:HDImpBall{
	default{
		missiletype "ArdentipedeBallTail2";
		damage 2;
		speed 7;
		height 4;radius 4;
		scale 0.6;
		decal "Scorch";
		hdfireball.firefatigue int(HDCONST_MAXFIREFATIGUE*0.06);
	}
	override void A_HDIBFly(){
		roll=frandom(0,360);
		A_FBSeek(256);
	}
	vector3 accelpos;
	override void postbeginplay(){
		super.postbeginplay();
		if(!hdmobbase(target))accelpos=(0,0,0);
	}
	states{
	spawn:
		BAL1 A 2 bright{
			let ttt=hdmobbase(target);
			if(ttt)accelpos=(ttt.lasttargetpos.xy,ttt.lasttargetpos.z+ttt.lasttargetheight);
			if(accelpos!=(0,0,0)){
				vector3 acceldir=(accelpos-pos);
				acceldir/=max(abs(acceldir.x),abs(acceldir.y),abs(acceldir.z));
				vel=vel*0.8+acceldir*2;
			}
			stamina++;
			if(stamina>20){
				A_FaceMovementDirection();
				pitch+=frandom(-1,1);
				angle+=frandom(-1,1);
				setstatelabel("spawn2");
			}else if(stamina<5)A_FBTail();
		}
		loop;
	spawn2:
		BAL1 ABAB 1 bright fast A_ChangeVelocity(cos(pitch)*4,0,-sin(pitch)*4,CVF_RELATIVE);
	spawn3:
		BAL1 AB 3 bright fast A_HDIBFly();
		BAL1 A 0{
			let tocrash=(pos.z+vel.z*50-floorz);
			if(tocrash<0)vel.z-=0.01*tocrash;
		}
		loop;
	death:
		TNT1 A 0{
			spawn("HDSmoke",pos,ALLOW_REPLACE);
			if(blockingmobj)A_Immolate(blockingmobj,target,random(10,32));
		}
		BAL1 CDE 4 bright A_FadeOut(0.2);
		stop;
	}
}
class ArdentipedeBallTail:HDFireballTail{
	default{
		deathheight 0.9;
		gravity 0;
		friction 0.92;
		radius 1.6;
	}
	states{
	spawn:
		BAL1 AB 2{
			roll=frandom(0,360);
			scale.x*=randompick(-1,1);
		}loop;
	}
}
class ArdentipedeBallTail2:ArdentipedeBallTail{
	default{
		deathheight 0.86;
		radius 0.7;
	}
}


// ------------------------------------------------------------
// Imp Spawner
// ------------------------------------------------------------
class ImpSpawner:RandomSpawner replaces DoomImp{
	default{
		+ismonster
		dropitem "Serpentipede",256,5;
		dropitem "Regentipede",256,2;
		dropitem "Ardentipede",256,3;
	}
}
class DeadImpSpawner:RandomSpawner replaces DeadDoomImp{
	default{
		+ismonster
		dropitem "DeadSerpentipede",256,5;
		dropitem "DeadRegentipede",256,2;
		dropitem "DeadArdentipede",256,3;
	}
}
class DeadSerpentipede:Serpentipede{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}
class DeadRegentipede:Regentipede{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}
class DeadArdentipede:Ardentipede{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}
