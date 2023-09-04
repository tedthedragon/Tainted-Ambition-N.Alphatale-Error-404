// ------------------------------------------------------------
// Revenant
// ------------------------------------------------------------
class BoneDrone:HDMobBase{
	default{
		+nogravity +float
		+rockettrail
		+noblood
		+forcexybillboard
		+notargetswitch
		+nofear
		+ambush
		+lookallaround
		-countkill
		+bright
		+missilemore
		+missileevenmore
		+noforwardfall
		-canusewalls
		-activatemcross
		+activatepcross

		+hdmobbase.noshootablecorpse
		+hdmobbase.novitalshots
		+hdmobbase.nodeathdrop

		-activatemcross
		+activatepcross
		+noblockmonst

		//gross hack to get through impassables
		+skyexplode
		+missile
		+bounceonactors
		+allowbounceonactors
		+canbouncewater
		bouncefactor 0.1;
		bouncetype "doom";

		painchance 200;
		health 40;mass 20;
		seesound "skeleton/attack";
		renderstyle "translucent";
		radius 8;
		height 10;
		scale 0.9;
		seesound "";
		speed 10;
		meleerange 64;
		spriteangle 0;
	}
	override void Tick(){
		super.Tick();
		if(!isfrozen()){
			bspriteangle=Wads.CheckNumForName("id",0)==-1&&(vel dot vel)<200;
			A_FaceMovementDirection();
		}
	}
	override bool cancollidewith(actor other,bool passive){
		return
			other!=master
			||getage()>35
		;
	}
	void A_CheckSelfDestruct(){
		if(
			GetAge()>(TICRATE*60*10)
			||!level.IsPointInLevel(pos+vel)
		)A_Die();
	}
	states{
	spawn:
		FATB A 0 nodelay A_StartSound("skeleton/attack",CHAN_VOICE);
		FATB ABAB 2;
		FATB A 0{bhitowner=true;}
	idle:
		FATB ABABAB 2;
		FATB A 0 A_CheckSelfDestruct();
		FATB A 0 A_HDWander(CHF_LOOK);
		loop;
	see:
		FATB A 0 A_CheckSelfDestruct();
		FATB AB 2{
			A_HDChase();
			A_StartSound("boner/drone",CHAN_BODY,CHANF_OVERLAP,volume:0.6);
		}
		loop;
	missile:
		FATB ABAB 2{
			A_StartSound("boner/drone",CHAN_BODY,CHANF_OVERLAP);
			if(!target)return;
			let vvv=(target.pos.xy,target.pos.z+target.height*0.8)-pos;

			if(
				abs(vvv.x)-target.radius<32
				&&abs(vvv.y)-target.radius<32
				&&abs(vvv.z)-target.height<32
				&&absangle(angle,angleto(target))<90
			){
				bdontfacetalker=true;
				A_Die();
				return;
			}

			if(
				vvv!=(0,0,0)
				&&abs(vel.x)<50
				&&abs(vel.y)<50
				&&abs(vel.z)<50
			)vel+=vvv.unit()*3;
		}
		goto see;
	death:
		FBXP A 2 light("BONEX1"){
			A_UnsetShootable();
			bmissile=false;
			bnointeraction=true;

			tracer=target;
			target=master;

			if(
				!tracer
				||(
					!!target
					&&distance3dsquared(target)<(128*128)
				)
			)bdontfacetalker=false;

			if(vel.xy==(0,0))vel=pos-prev;
			A_SprayDecal("revenantscorch",radius*2,direction:vel);
			A_StartSound("skeleton/tracex",CHAN_BODY,CHANF_OVERLAP);

			A_SetRenderStyle(1.,STYLE_Add);
			bbright=true;
			vel.z+=0.3;

			if(!bdontfacetalker){
				A_SpawnChunks("HDSmokeChunk",10,2,12);
				A_SpawnChunks("HugeWallChunk",10,2,12);
				Spawn("HDFlameRed",pos);
				return;
			}

			spawn("HDExplosion",pos);
			A_SpawnChunks("HugeWallChunk",4,2,16);
			A_SpawnChunks("HDSmokeChunk",random(0,3),2,16);

			A_HDBlast(
				pushradius:HDCONST_ONEMETRE,pushamount:64,
				fragradius:HDCONST_ONEMETRE*5,fragtype:"HDB_scrap",
				fragments:(HDEXPL_FRAGS>>2),
				immolateradius:64,immolateamount:random(4,20),
				immolatechance:20,
				source:target
			);
			A_SpawnChunksFrags("HDB_scrap",64,1.);
		}
		---- A 0 A_Quake(2,48,0,24,"");
		---- AA 0 A_SpawnItemEx("HDSmoke",0,0,-2,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		FBXP BBC 1 A_FadeOut(0.2);
		wait;
	}
}

class Boner:HDMobBase replaces Revenant{
	default{
		radius 12;
		height 56;
		deathheight 12;
		painchance 100;
		meleethreshold 256;
		+missilemore +missileevenmore
		+floorclip
		+hdmobbase.smallhead
		+hdmobbase.biped
		+hdmobbase.climber
		maxdropoffheight 128;
		hdmobbase.downedframe 15;
		seesound "skeleton/sight";
		painsound "skeleton/pain";
		deathsound "skeleton/death";
		activesound "skeleton/active";
		meleesound "skeleton/melee";
		tag "$CC_REVEN";

		+noblooddecals
		bloodtype "notquitebloodsplat";
		speed 14;
		mass 200;
		health 250;
		obituary "$OB_BONER";
		hitobituary "$OB_BONERSLAP";
		damagefactor "hot",1.1;
		damagefactor "cold",1.1;
		damagefactor "slashing",0.8;
		damagefactor "piercing",0.8;
	}
	override string GetObituary(actor victim,actor inflictor,name mod,bool playerattack){
		if(inflictor==self)return hitobituary;
		return obituary;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(bplayingid){
			bonlyscreamondeath=true;
			scale=(0.74,0.74);
			mass=80;
		}else{
			resize(0.8,1.1);
		}
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		HDMath.ProcessSynonyms(mod);
		if(mod=="hot"||mod=="cold")flags|=DMG_NO_PAIN;
		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	states{
	spawn:
		SKEL B 10 A_HDLook();
		wait;
	see:
		SKEL ABCDEF 3 A_HDChase();
		SKEL A 0{
			bfrightened=
				targetinsight
				||firefatigue>HDCONST_MAXFIREFATIGUE
			;
		}
		loop;
		SKEL A 0 A_JumpIf(
			!!target
			&&!targetinsight
			&&checkmove(pos.xy)
			&&firefatigue<random(-50,HDCONST_MAXFIREFATIGUE)
			,"missile"
		);
		loop;
	melee:
		SKEL G 1 A_JumpIf(!bplayingid,1);
		SKEL G 3 A_FaceTarget();
		SKEL G 1 A_SkelWhoosh();
		SKEL H 2;
		SKEL I 4{
			//copypasted from A_SkelFist with adjustments
			let targ=target;
			if(
				!targ
				||(targ.bcorpse&&!random(0,31))
			)return;
			A_FaceLastTargetPos();
			if(CheckMeleeRange()){
				A_StartSound("skeleton/melee",CHAN_WEAPON);
				if(bplayingid){
					int newdam=targ.DamageMobj(self,self,random(10,60),"Bashing");
					targ.TraceBleed(newdam>0?newdam:damage,self);
					A_SetTics(6);
				}else{
					targ.DamageMobj(self,self,random(10,40),"Claws");
					targ.TraceBleed(damage,self);
				}
			}
		}
		SKEL H 4;
		---- A 0 setstatelabel("see");
	missile:
		SKEL II 4 A_FaceLastTargetPos();
		SKEL J 3 bright{
			let aaa=spawn("BoneDrone",(pos.xy,pos.z+height*0.8),ALLOW_REPLACE);
			if(!aaa)return;
			aaa.target=target;aaa.bfriendly=bfriendly;aaa.friendplayer=friendplayer;
			aaa.master=self;
			aaa.angle=angle;aaa.pitch=pitch;
			aaa.A_ChangeVelocity(cos(pitch)*10,0,sin(pitch)*10,CVF_RELATIVE);
		}
		SKEL K 12{
			firefatigue+=int(HDCONST_MAXFIREFATIGUE*0.8);
			if(firefatigue>HDCONST_MAXFIREFATIGUE)firefatigue+=(TICRATE<<4);
			bfrightened=true;
		}
		---- A 0 setstatelabel("see");
	pain:
		SKEL L 5;
		SKEL L 5 A_Vocalize(painsound);
		---- A 0 setstatelabel("see");
	death:
		SKEL LM 7;
		SKEL N 7 A_StartSound(deathsound,CHAN_VOICE,CHANF_OVERLAP,pitch:bplayingid?1.:voicepitch);
		SKEL O 7 A_NoBlocking();
	dead:
		SKEL P 5 canraise A_JumpIf(floorz>pos.z-6,1);
		wait;
		SKEL Q 5 canraise A_JumpIf(floorz<=pos.z-6,"dead");
		wait;
	raise:
		SKEL Q 5;
		SKEL PONML 5;
		#### A 0 A_Jump(256,"see");
	falldown:
		SKEL L 5;
		SKEL M 5 A_Vocalize(painsound);
		SKEL NNOOP 2 A_SetSize(-1,max(deathheight,height-10));
		SKEL L 0 A_SetSize(-1,deathheight);
		SKEL Q 10 A_KnockedDown();
		wait;
	standup:
		SKEL P 6;
		SKEL O 0 A_Jump(160,2);
		SKEL O 0 A_Vocalize(seesound);
		SKEL PO 4 A_Recoil(-0.3);
		SKEL NML 4;
		---- A 0 setstatelabel("see");
	}
}

