// ------------------------------------------------------------
// Hatchling
// ------------------------------------------------------------
class Hatchling:HDMobBase replaces LostSoul{
	default{
		+float +nogravity
		health 40;
		height 30;
		radius 15;
		speed 8;
		mass 42;
		+hdmobbase.onlyscreamondeath
		attacksound "hatchling/shriek";
		activesound "hatchling/active";
		obituary "$OB_HATCHLING";
		hdmobbase.landsound "";
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.8,1.);
		voicepitch=frandom(0.95,1.05);
		blefthanded=!random(0,3);
	}
	override bool cancollidewith(actor other,bool passive){
		return
			other!=master
			||getage()>40
		;
	}


	void A_TakeOff(bool vocalize=false){
		if(vocalize)A_Vocalize(attacksound);
		A_LeadTarget(lasttargetdist*0.125,false);
		A_ChangeVelocity(cos(pitch)*8,0,sin(pitch)*-8,CVF_RELATIVE);
	}
	void A_Flying(){
		if(
			!checkmove(pos.xy+vel.xy*5)
			||!random(0,15)
			||(
				abs(vel.x)<3
				&&abs(vel.y)<3
				&&abs(vel.z)<3
			)
		){
			setstatelabel("flyend");
			return;
		}
		if(!checkmove(pos.xy+vel.xy)){
			vel.xy=rotatevector(vel.xy,frandom(150,210))*0.6;
			setstatelabel("pain");
		}

		if(
			!(level.time&(1|2))
			||!!blockingmobj
		)ZapCheck();

	}
	void ZapCheck(){
		blockthingsiterator it=blockthingsiterator.create(self,96);
		while(it.next()){
			actor itt=it.thing;
			if(
				itt.bshootable
				&&ishostile(itt)
				&&distance3dsquared(itt)<(96*96)
				&&checksight(itt)
			){
				ParticleZigZag(self,
					(pos.xy,pos.z+height*0.6),
					(itt.pos.xy,itt.pos.z+itt.height*0.6)
				);
				A_StartSound("hatchling/zap",CHAN_ARCZAP,CHANF_OVERLAP);
				itt.A_StartSound("hatchling/zap2",CHAN_ARCZAP,CHANF_OVERLAP);
				itt.A_StartSound("hatchling/zap3",CHAN_ARCZAP,CHANF_OVERLAP);

				vector3 pvv=(
					(itt.pos.xy,itt.pos.z+itt.height*0.5)
					-(pos.xy,pos.z+height*0.5)
				).unit();
				vel-=pvv*4;
				if(!itt.bdontthrust){
					if(itt.pos.z<=itt.floorz)pvv.z+=3;
					itt.vel-=pvv*300/max(1,itt.mass);
					itt.angle+=frandom(-1,1);
					itt.pitch+=frandom(-1,1);
				}

				itt.damagemobj(self,self,random(1,8),"electrical");
			}
		}
	}
	states{
	spawn:
		SKUL AB 10 A_HDWander(CHF_LOOK);
		loop;
	see:
		SKUL AB 4 A_HDChase();
		loop;
	missile:
		SKUL AB 2;
	aim:
		SKUL AB 1 A_TurnToAim(10);
		loop;
	shoot:
		SKUL B 1 bright A_Takeoff(true);
		SKUL C 1 bright ZapCheck();
		SKUL D 1 bright A_Takeoff();
	flying:
		SKUL CD 1 bright A_Flying();
		loop;
	flyend:
		SKUL CDCDCBA 1 bright{
			vel.xy*=0.9;
		}
		goto see;
	pain:
		SKUL E 3;
		SKUL E 3 A_Vocalize(painsound);
		goto see;
	death:
		SKUL E 2 bright{
			A_SetTranslucent(1,1);
			vel.z++;
		}
		TNT1 AAA 0 A_SpawnItemEx("BloodSplat",0,0,3,
			vel.x+frandom(-4,4),vel.y+frandom(-4,4),vel.z+frandom(1,6),
			0,SXF_ABSOLUTE|SXF_ABSOLUTEMOMENTUM
		);
		SKUL G 0 A_NoBlocking();
		SKUL GG 1 ZapArc(self);
		SKUL H 0 A_StartSound("hatchling/death",CHAN_BODY);
		SKUL HH 1 ParticleZigZag(self,
			(pos.xy+(frandom(-radius,radius),frandom(-radius,radius)),
			pos.z+frandom(0,height)),
			(pos.xy,pos.z)+(frandom(-1,1),frandom(-1,1),frandom(-1,1))*frandom(30,90)
		);
		SKUL HHH 0 A_SpawnItemEx("BloodSplatSilent",
			frandom(-2,2),frandom(-2,2),frandom(4,8),
			vel.x,vel.y,vel.z+random(1,2),
			0,SXF_ABSOLUTE|SXF_ABSOLUTEMOMENTUM
		);
		SKUL HHHHHHHHH 0 A_SpawnItemEx("BloodSplatSilent",
			frandom(-4,4),frandom(-4,4),frandom(2,14), 
			vel.x+frandom(-4,4),vel.y+frandom(-4,4),vel.z+frandom(-4,10),
			random(0,360),SXF_ABSOLUTEMOMENTUM|SXF_ABSOLUTE|SXF_SETTARGET
		);
		SKUL I 1{
			HDActor.HDBlast(self,
				blastradius:96,blastdamage:random(1,12),blastdamagetype:"electrical",
				immolateradius:96,immolateamount:random(4,20),immolatechance:32
			);
			for(int i=0;i<4;i++){
				ParticleZigZag(self,
					(pos.xy+(frandom(-radius,radius),frandom(-radius,radius)),
					pos.z+frandom(0,height)),
					(pos.xy,pos.z)+(frandom(-1,1),frandom(-1,1),frandom(-1,1))*frandom(30,90)
				);
			}
		}
		SKUL JJJJ 1 A_FadeOut(0.2);
		stop;
	}
}



// ------------------------------------------------------------
// Matribite
// ------------------------------------------------------------
class MatribiteBall:ShieldImpBall{
	default{speed 26;}
}
class Matribite:HDMobBase replaces PainElemental{
	default{
		radius 24;
		height 56;
		health 400;
		mass 400;
		painchance 128;
		+float 
		+nogravity
		seesound "pain/sight";
		painsound "pain/pain";
		activesound "pain/active";
		tag "$cc_pain";

		+pushable
		pushfactor 0.3;
		obituary "$OB_MATRIBITE";
		hitobituary "$OB_MATRIBITE_HIT";
		hdmobbase.shields 1000;
		+hdmobbase.onlyscreamondeath
		speed 4;
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.9,1.1);
	}
	int brewing;
	states{
	spawn:
		PAIN A 10 A_HDLook();
		loop;
	see:
		PAIN AAABBBCCC 3 A_HDChase();
		loop;
	missile:
		TNT1 A 0 A_JumpIfTargetInLOS("missile2",20);
		PAIN ABCB 3 A_FaceLastTargetPos(10);
		TNT1 A 0 A_ChangeVelocity(0.8,0,frandom(-0.4,0.4),CVF_RELATIVE);
		TNT1 A 0 A_JumpIfTargetInLOS("missile");
		TNT1 A 0 A_Jump(40,"missile2");
		---- A 0 setstatelabel("see");
	missile2:
		PAIN DDE 2 A_FaceLastTargetPos(5);
		PAIN F 3 A_FaceLastTargetPos(5);
		PAIN F 0 A_JumpIf(brewing>0,"missile2a");
		PAIN F 6{
			let aaa=Hatchling(spawn("Hatchling",(pos.xy,pos.z+32),ALLOW_REPLACE));
			if(!aaa){
				A_SpawnProjectile("Satanball",flags:CMF_AIMDIRECTION,pitch:pitch);
				A_ChangeVelocity(-cos(pitch),0,sin(pitch),CVF_RELATIVE);
				return;
			}
			aaa.master=self;
			aaa.target=target;
			aaa.angle=angle;
			aaa.pitch=pitch;
			aaa.vel=vel;
			aaa.A_SetFriendly(bfriendly);
			if(bbossspawned)aaa.bbossspawned=true;
			aaa.A_Vocalize(aaa.attacksound);
			aaa.A_ChangeVelocity(cos(pitch)*15,0,sin(pitch)*-15,CVF_RELATIVE);
			brewing=4;
			HDMagicShield.Deplete(self,66);
		}
		goto missileend;
	missile2a:
		PAIN F 6{
			brewing--;
			A_SpawnProjectile("MatribiteBall",flags:CMF_AIMDIRECTION,pitch:pitch);
			A_GiveInventory("HDMagicShield",24);
			vel.z+=frandom(0.2,2.);
		}
		PAIN F 4 A_SpawnProjectile("MatribiteBall",flags:CMF_AIMDIRECTION,pitch:pitch);
		PAIN F 3 A_SpawnProjectile("ShieldImpBall",flags:CMF_AIMDIRECTION,pitch:pitch);
	missileend:
		PAIN ED 3;
		---- A 0 setstatelabel("see");
	melee:
		PAIN DE 4 A_FaceTarget(10,10);
		PAIN F 6 A_FaceTarget(10,10);
		PAIN C 12 A_CustomMeleeAttack(random(20,40));
		---- A 0 setstatelabel("see");
	pain:
		PAIN G 6{
			A_ScaleVelocity(0.6);
			brewing--;
		}
		PAIN G 6 A_Pain();
		---- A 0 setstatelabel("missile2");
	death.telefrag:
		TNT1 A 0 spawn("Telefog",pos,ALLOW_REPLACE);
		TNT1 A 0 A_NoBlocking();
		TNT1 AAAAAAAAAAAAA 0 A_SpawnItemEx("BFGNecroShard",
			frandom(-4,4),frandom(-4,4),frandom(6,24),
			frandom(1,6),0,frandom(1,3),
			frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_SETMASTER
		);
		stop;
	death:
		PAIN H 2;
		PAIN I 3 A_StartSound("pain/death",CHAN_BODY);
		TNT1 A 0 A_NoBlocking();
		TNT1 AAAA 0 A_SpawnItemEx("HDSmokeChunk", random(-7,7),random(-7,7),random(2,6), vel.x+random(-7,7),vel.y+random(-7,7),vel.z+random(4,8),0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		PAIN J 1 bright;
		TNT1 A 0 HDBlast(self,
			blastradius:196,blastdamage:random(20,69),blastdamagetype:"electrical",
			immolateradius:96,immolateamount:random(4,20),immolatechance:32
		);
		TNT1 AAAAA 0 A_SpawnItemEx("MegaBloodSplatter", random(-7,7),random(-7,7),random(2,6), vel.x+random(-7,7),vel.y+random(-7,7),vel.z+random(4,8),0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		PAIN JJJKKK 1{
			A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), vel.x,vel.y,vel.z+random(1,4), random(0,360), 168, 16);
			for(int i=0;i<3;i++){
				Hatchling.ParticleZigZag(self,
					(pos.xy+(frandom(-radius,radius),frandom(-radius,radius)),
					pos.z+frandom(0,height)),
					(pos.xy,pos.z)+(frandom(-1,1),frandom(-1,1),frandom(-1,1))*frandom(30,90)
				);
			}
		}
		PAIN L 0{
			for(int i=0;i<7;i++){
				Hatchling.ParticleZigZag(self,
					(pos.xy+(frandom(-radius,radius),frandom(-radius,radius)),
					pos.z+frandom(0,height)),
					(pos.xy,pos.z)+(frandom(-1,1),frandom(-1,1),frandom(-1,1))*frandom(30,90)
				);
			}
		}
		PAIN LLL 0{
			actor aaa;
			[bseesdaggers,aaa]=A_SpawnItemEx("Hatchling",
				randompick(-20,0,20),randompick(-20,0,20),frandom(1,12),
				frandom(2,7),frandom(-4,4),frandom(1,3),
				frandom(-45,45),
				flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
			);
		}
		PAIN LL 1 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), vel.x,vel.y,vel.z+random(1,4), random(0,360), 168, 16);
		PAIN LLLMMMM 1 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), vel.x,vel.y,vel.z+random(1,4), random(0,360), 168, 72);
		TNT1 AAAAAAA 3 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), 0, 0, 0, random(0,360), 160, 92);
		stop;
	raise:
		PAIN MLKJIH 8;
		---- A 0 setstatelabel("see");
	}
}
