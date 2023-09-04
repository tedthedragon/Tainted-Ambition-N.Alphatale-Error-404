// ------------------------------------------------------------
// Mancu, mancu very much.
// ------------------------------------------------------------
class manjuicelight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=164;
		args[1]=66;
		args[2]=18;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-20,4);
			if(args[3]<1)destroy();
		}else{
			setorigin(target.pos,true);
			if(target.bmissile)args[3]=random(28,44);
			else args[3]=random(32,64);
		}
	}
}
const CSLUG_BALLSPEED=56.;
class manjuicesmoke:HDFireballTail{
	default{
		deathheight 0.9;
		gravity 0;
	}
	states{
	spawn:
		RSMK A random(3,5);RSMK A 0 A_SetScale(scale.y*2);
		---- BCD -1{frame=random(1,3);}wait;
	}
}
class manjuice:hdfireball{
	default{
		missiletype "manjuicesmoke";
		missileheight 8;
		damagetype "hot";
		activesound "misc/firecrkl";
		decal "scorch";
		gravity HDCONST_GRAVITY*0.8;
		speed CSLUG_BALLSPEED;
		radius 7;
		height 8;
		hdfireball.firefatigue HDCONST_MAXFIREFATIGUE*0.2;
	}
	actor trailburner;
	override void ondestroy(){
		if(trailburner)trailburner.destroy();
		super.ondestroy();
	}
	states{
	spawn:
		MANF A 0 nodelay{
			actor mjl=spawn("manjuicelight",pos+(0,0,16),ALLOW_REPLACE);
			mjl.target=self;
		}
		MANF ABAB 2 A_FBTail();
	spawn2:
		MANF A 2 A_FBFloat();
		MANF B 2;
		loop;
	death:
		MISL B 0{
			vel.z+=1.;
			A_HDBlast(
				128,66,16,"hot",
				immolateradius:48,random(20,90),42,
				false
			);
			A_SpawnChunks("HDSmokeChunk",random(2,4),6,20);
			A_StartSound("misc/fwoosh",CHAN_WEAPON);
			scale=(0.9*randompick(-1,1),0.9);
		}
		MISL BBBB 1{
			vel.z+=0.5;
			scale*=1.05;
		}
		MISL CCCDDD 1{
			alpha-=0.15;
			scale*=1.01;
		}
		TNT1 A 0{
			A_Immolate(tracer,target,80,requireSight:true);
			addz(-20);
		}
		TNT1 AAAAAAAAAAAAAAA 4{
			if(tracer){
				setorigin((tracer.pos.xy,tracer.pos.z+frandom(0.1,tracer.height*0.4)),false);
				vel=tracer.vel;
			}
			A_SpawnItemEx("HDSmoke",
				frandom(-2,2),frandom(-2,2),frandom(0,2),
				vel.x+frandom(2,-4),vel.y+frandom(-2,2),vel.z+frandom(1,4),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
		}stop;
	}
}

class CombatSlug:HDMobBase replaces Fatso{
	default{
		health 600;
		mass 1000;
		speed 10;
		monster;
		+map07boss1
		+floorclip
		+bossdeath
		seesound "fatso/sight";
		painsound "fatso/pain";
		deathsound "fatso/death";
		activesound "fatso/active";
		tag "$cc_mancu";

		+dontharmspecies
		+hdmobbase.onlyscreamondeath
		deathheight 20;
		radius 28;
		height 60;

		meleerange 96;

		damagefactor "hot", 0.7;
		damagefactor "cold", 0.8;
		hdmobbase.shields 500;
		obituary "$OB_COMBATSLUG";
		painchance 80;
	}
	override bool CanDoMissile(
		bool targsight,
		double targdist,
		out statelabel missilestate
	){
		return
		(
			targdist<(HDCONST_ONEMETRE*100)
			||!target
			||target.pos.z-pos.z<128
		)&&super.CanDoMissile(targsight,targdist,missilestate);
	}
	override void CheckFootStepSound(){
		if(
			(
				frame==0
				||frame==3
			)
			&&frame!=curstate.nextstate.frame
		){
			if(HDMath.CheckLiquidTexture(self))A_StartSound("humanoid/squishstep",88,CHANF_OVERLAP,volume:0.4);
			A_StartSound("mancubus/step",88,CHANF_OVERLAP);
		}
	}
	states{
	spawn:
		FATT AB 15 A_HDLook();
		loop;
	see:
		FATT ABCDEF 6 A_HDChase();
		---- A 1 A_Jump(64,"guard");
		loop;
	guard:
		FATT J 4 A_StartSound("fatso/raiseguns",CHAN_VOICE);
	guard2:
		FATT # 0 A_FaceLastTargetPos(20,32);
		FATT ####### 3 A_Watch();
		FATT # 0 A_Jump(64,"guard2");
		goto see;
	missile:
		FATT ABCDEF 3 A_TurnToAim(20,shootstate:"raiseshoot");
		loop;
	raiseshoot:
		FATT G 4{
			A_StartSound("fatso/raiseguns",CHAN_VOICE);
			A_FaceLastTargetPos(20,32);
		}
		FATT G 4 A_FaceLastTargetPos(20,32);
		FATT GGGG 1 A_SpawnItemEx("HDSmoke",
			16,randompick(24,-24),bplayingid?18:40,
			random(2,4),flags:SXF_NOCHECKPOSITION
		);
	shoot:
		FATT G 2{
			A_FaceLastTargetPos(20,32);
			A_SpawnItemEx("HDSmoke",
				16,randompick(24,-24),bplayingid?18:40,
				random(2,4),flags:SXF_NOCHECKPOSITION
			);
		}
		FATT G 2 A_LeadTarget(lasttargetdist*(1./CSLUG_BALLSPEED)*frandom(0.9,1.2),false);
		FATT H 10 bright{
			A_StartSound("weapons/bronto",CHAN_WEAPON);

			hdmobai.DropAdjust(self,"ManJuice");

			vector2 atv=angletovector(angle-90,24);
			vector3 shotpos=(pos.xy,pos.z+32);

			if(lasttargetdist<1000){
				A_LeadTarget(lasttargetdist*(1./CSLUG_BALLSPEED),true);
				angle+=frandom(-1,1)*max(0,1000-lasttargetdist)*0.01;
			}

			//lead target
			let bbb=spawn("manjuice",(shotpos.xy+atv,shotpos.z));
			bbb.pitch=pitch;
			bbb.angle=angle;
			bbb.target=self;
			bbb.vel=vel+(cos(pitch)*(cos(angle),sin(angle)),-sin(pitch))*CSLUG_BALLSPEED;


			//random
			int opt=random(0,2);
			if(opt==1){
				double pbak=pitch;
				A_LeadTarget(lasttargetdist*(1./CSLUG_BALLSPEED),true);
				pitch=pbak;
			}else if(opt==2){
				angle+=frandom(-10,10)/lasttargetdist;
				pitch+=frandom(-1,1);
			}

			bbb=spawn("manjuice",(shotpos.xy-atv,shotpos.z));
			bbb.pitch=pitch;
			bbb.angle=angle;
			bbb.target=self;
			bbb.vel=vel+(cos(pitch)*(cos(angle),sin(angle)),-sin(pitch))*CSLUG_BALLSPEED;
		}
		FATT G 6;
		FATT G 10{
			if(
				accuracy<2
				&&(!random(0,4-(!!target&&target.health>0)))
			){
				accuracy++;
				setstatelabel("shoot");
			}else accuracy=0;
		}
		---- A 0 setstatelabel("see");

	melee:
		FATT ABCD 3 A_TurnToAim(40,shootstate:"melee2");
	melee2:
		FATT D 3 A_FaceLastTargetPos(10);
		FATT E 2;
		FATT G 3 A_CustomMeleeAttack(random(1,40),"weapons/smack","","bashing",true);
		FATT H 1 bright;
		FATT H 2 bright{
			A_StartSound("mancubus/thrust",CHAN_WEAPON,CHANF_OVERLAP);
			actor iii;
			double extml=meleerange+radius+12;
			blockthingsiterator iiii=blockthingsiterator.create(self,meleerange);
			while(iiii.next()){
				iii=iiii.thing;
				if(
					iii==self
					||!iii.bshootable
					||iii.bdontthrust
					||iii.mass<=0
				)continue;
				double angoffset=absangle(angle,angleto(iii));
				double meleerangesquared=extml+iii.radius;
				meleerangesquared*=meleerangesquared;
				double dist=extml;
				if(
					angoffset<30
					&&(dist=distance3dsquared(iii))<meleerangesquared
				){
					A_Immolate(iii,self,20);
					vector3 thr=iii.pos-pos;
					thr*=0.15*(40-(angoffset))*meleerangesquared/(dist*iii.mass);
					iii.vel+=thr;
				}
			}
		}
		FATT GFED 3;
		FATT JJJJ 4 A_Watch(meleestate:null);
		FATT J 0 setstatelabel("see");

	pain:
		FATT J 3;
		FATT J 3 A_Pain;
		---- A 0 setstatelabel("see");
	death:
		FATT K 6 A_SpawnItemEx("HDExplosion",0,0,36,flags:SXF_SETTARGET);
		FATT L 6 A_Scream();
		FATT MNOPQRS 6 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(26,32),
			0,0,frandom(1,4),
			0,SXF_NOCHECKPOSITION
		);
		FATT TTT 8 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(26,32),
			0,0,frandom(1,4),
			0,SXF_NOCHECKPOSITION
		);
		FATT T -1{
			A_BossDeath();
			balwaystelefrag=true; //not needed?
			bodydamage+=1200;
		}stop;
	raise:
		FATT ST 14 damagemobj(self,self,1,"maxhpdrain",DMG_NO_PAIN|DMG_FORCED|DMG_NO_FACTOR);
		FATT TSR 10;
		FATT QPONMLK 5;
		---- A 0 setstatelabel("see");
	death.maxhpdrain:
		FATT STST 14 A_SpawnItemEx("MegaBloodSplatter",
			frandom(-1,1),frandom(-1,1),frandom(10,16),
			vel.x,vel.y,vel.z,0,SXF_NOCHECKPOSITION
		);
		FATT T -1;
		stop;
	}
}

