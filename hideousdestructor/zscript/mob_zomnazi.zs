// ------------------------------------------------------------
// born to forever sucker fruit hawaiian in the motherfuckin
// ------------------------------------------------------------
class HoopBubble:HDHumanoid replaces WolfensteinSS{
	default{
		seesound "wolfss/sight";
		painsound "wolfss/pain";
		deathsound "wolfss/death";
		activesound "wolfss/active";
		tag "$fn_wolfss";

		painchance 170;

		obituary "$OB_ZOMNAZI";
		translation "192:207=103:111","240:247=5:8";
	}
	override void postbeginplay(){
		super.postbeginplay();
		gunloaded=31;
		if(!bplayingid){
			scale*=0.81;
		}
		givearmour(1.);
	}
	int gunloaded;
	override void deathdrop(){
		hdweapon wp=null;
		if(!bhasdropped){
			DropNewItem("HDHandgunRandomDrop");
			bhasdropped=true;
			if(wp=DropNewWeapon("HDSMG")){
				wp.weaponstatus[SMGS_AUTO]=2;
				wp.weaponstatus[SMGS_MAG]=random(0,30);
				wp.weaponstatus[SMGS_CHAMBER]=2;
			}
			DropNewItem("HD9mMag30");
		}else if(!bfriendly){
			DropNewItem("HD9mMag30",240);
			DropNewItem("HD9mMag30",128);
		}
	}
	states{
	spawn:
		SSWV FF 1{
			A_HDLook();
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
		SSWV B 0 A_Jump(16,"spawnstretch");
		SSWV B 0 A_Jump(116,"spawnwander");
		SSWV B 8 A_Recoil(frandom(-0.2,0.2));
		loop;
	spawnstretch:
		SSWV E 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
			if(!random(0,3))A_Vocalize("grunt/active");
		}
		---- A 0 setstatelabel("spawn");
	spawnstill:
		SSWV A 0 A_HDLook();
		SSWV A 0 A_Recoil(frandom(-0.4,0.4));
		SSWV CD 5 A_SetAngle(angle+frandom(-4.,4.));
		SSWV A 0 A_HDLook();
		SSWV A 0 A_Jump(192,2);
		SSWV A 0 A_Vocalize("grunt/active");
		SSWV AB 5 A_SetAngle(angle+frandom(-4.,4.));
		SSWV A 0 A_HDLook();
		SSWV B 1 A_SetTics(random(10,40));
		---- A 0 setstatelabel("spawn");
	spawnwander:
		SSWV CDAB 5 A_HDWander();
		---- A 0 setstatelabel("spawn");
	see:
		SSWV A 0 A_JumpIf(gunloaded<2,"reload");
		SSWV ABCD 4 A_HDChase();
		SSWV A 0 A_JumpIfTargetInLOS("see");
		---- A 0 setstatelabel("roam");
	roam:
		#### E 3 A_Jump(60,"roam2");
		#### E 0{spread=1;}
		#### EEEE 1 A_Watch();
		#### E 0{spread=0;}
		#### EEEEEEEEEEEEE 1 A_Watch();
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_Jump(8,"see");
		#### ABCD 5 A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(140,"Roam");
		#### A 0 A_JumpIfTargetInLOS("see");
		loop;
	pain:
		SSWV H 3;
		SSWV H 3 A_Pain();
		SSWV A 0 A_Jump(192,"see");
		---- A 0 setstatelabel("see");
	missile:
		#### ABCD 3 A_TurnToAim(40,shootstate:"aiming");
		loop;
	aiming:
		#### E 3 A_FaceLastTargetPos(30);
		#### F 1 A_StartAim(rate:0.85,mintics:0,maxtics:35);
		//fallthrough to shoot
	shoot:
		SSWV G 1 bright light("SHOT"){
			if(gunloaded<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			pitch+=frandom(0,spread)-frandom(0,spread);
			angle+=frandom(0,spread)-frandom(0,spread);
			A_StartSound("weapons/smg",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
			gunloaded--;
		}
		SSWV F 2 A_EjectSMGCasing();
		SSWV F 0 A_Jump(128,"shoot");
	shootend:
		SSWV F 1 A_FaceTarget(0,0);
		SSWV F 4 A_Jump(132,"see");
		SSWV FFFFF 4 A_CoverFire();
		loop;
	ohforfuckssake:
		SSWV F 8;
	reload:
		SSWV A 3 A_HDChase("melee",null,CHF_FLEE);
		SSWV B 4{
			A_StartSound("weapons/rifleclick2",8);
			if(gunloaded>=0)A_SpawnProjectile("HDSMGEmptyMag",38,0,random(90,120));
			gunloaded=-1;
		}
		SSWV CD 3 A_HDChase("melee",null,CHF_FLEE);
		SSWV E 4{
			A_StartSound("weapons/rifleload",8);
			A_HDWander();
		}
		SSWV F 3{
			A_StartSound("weapons/rifleclick2",8);
			gunloaded+=30;
			A_HDWander();
		}
		---- A 0 setstatelabel("see");
	death:
		SSWV I 5;
		SSWV J 5 A_Scream();
		SSWV KL 5;
	dead:
		SSWV L 3 A_JumpIf(abs(vel.z)<2,1);
		loop;
		SSWV M 5 canraise A_JumpIf(abs(vel.z)>=2,"dead");
		loop;
	xxxdeath:
		SSWV N 5;
		SSWV O 5 A_XScream();
		SSWV PQRSTU 5;
		---- A 0 setstatelabel("xdead");
	xdeath:
		SSWV N 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV O 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV O 5 A_XScream();
		SSWV P 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV Q 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV QRSTU 5;
	xdead:
		SSWV U 3 canraise A_JumpIf(abs(vel.z)<2,1);
		wait;
		SSWV V 5 canraise A_JumpIf(abs(vel.z)>=2,"xdead");
		wait;
	raise:
		SSWV M 4;
		SSWV MLK 6;
		SSWV JIH 4;
		---- A 0 setstatelabel("see");
	ungib:
		SSWV V 4;
		SSWV VUT 8;
		SSWV SRQ 6;
		SSWV PON 4;
		---- A 0 setstatelabel("see");
	}
	override void die(actor source,actor inflictor,int dmgflags){
		if(
			bplayingid
			&&source
			&&source==inflictor
			&&source.player
			&&HDFist(source.player.readyweapon)
		){
			source.A_StartSound("nazi/punched",19450430,CHANF_OVERLAP);
			let ppp=hdplayerpawn(source);
			if(!ppp)source.givebody(10);
			else{
				for(int i=0;i<3;i++){hdbleedingwound.findandpatch(ppp,40,HDBW_FINDPATCHED);}
				ppp.aggravateddamage-=max(1,ppp.aggravateddamage>>3);
				ppp.fatigue>>=1;
				ppp.stunned=0;
				ppp.givebody(6);
			}
		}
		super.die(source,inflictor,dmgflags);
	}
}
