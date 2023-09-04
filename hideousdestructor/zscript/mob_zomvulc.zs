// ------------------------------------------------------------
// Vulcanette Guy
// ------------------------------------------------------------
class HDChainReplacer:RandomSpawner replaces ChaingunGuy{
	default{
		dropitem "VulcanetteZombie",256,6;
		dropitem "UndeadRifleman",256,2;
		dropitem "EnemyHERP",256,1;
		dropitem "EnemyDERP",256,1;
	}
}class VulcanetteZombie:HDHumanoid{
	default{
		radius 14;
		height 54;
		painchance 170;
		monster;
		+floorclip
		seesound "chainguy/sight";
		painsound "chainguy/pain";
		deathsound "chainguy/death";
		activesound "chainguy/active";
		tag "$cc_heavy";

		health 120;
		speed 9;
		mass 200;
		maxtargetrange 6000;
		obituary "$OB_VULCZOMBIE";
		hdmobbase.downedframe 11;
	}
	bool turnleft;
	bool superauto;
	int thismag;
	int mags;
	int chambers;
	int burstcount;
	vector2 coverdir;
	override void postbeginplay(){
		super.postbeginplay();
		chambers=5;
		burstcount=random(4,20);
		superauto=randompick(0,0,0,1);
		mags=4;
		thismag=50;
		bhashelmet=!bplayingid;
		bnoincap=bplayingid;

		gunheight=32;

		if(bplayingid)givearmour(1.,0.06,-0.4);
		else givearmour(1.,0.2,-0.4);
	}
	bool noammo(){
		return chambers<1&&thismag<1&&mags<1;
	}
	void A_VulcZombieShot(){
		//abort if burst is over
		if(
			burstcount<1
			||noammo()
		){
			burstcount=random(3,5);
			setstatelabel("postshot");
			return;
		}

		//check for ammo
		if(
			thismag<1
			&&mags>0
		){
			setstatelabel("shuntmag");
			return;
		}
		if(chambers<1)setstatelabel("chamber");

		//shoot the bullet
		A_StartSound("weapons/vulcanette",CHAN_WEAPON,CHANF_OVERLAP);
		HDBulletActor.FireBullet(self,"HDB_426",spread:2,distantsound:"world/vulcfar");
		pitch+=frandom(-0.4,0.3);angle+=frandom(-0.3,0.3);
		burstcount--;
		chambers--;

		//cycle the next round
		if(chambers<5 && thismag){
			thismag--;
			chambers++;
			A_StartSound("weapons/rifleclick2",8);
		}
	}
	override void deathdrop(){
		if(!bhasdropped){
			bhasdropped=true;
			DropNewItem("HDBattery",16);
			DropNewItem("HDHandgunRandomDrop");
			let vvv=DropNewWeapon("Vulcanette");
			if(!vvv)return;
			vvv.weaponstatus[VULCS_MAG1]=thismag;
			for(int i=VULCS_MAG2;i<=VULCS_MAG5;i++){
				if(mags>0){
					vvv.weaponstatus[i]=51;
					mags--;
				}else vvv.weaponstatus[i]=-1;
			}
			vvv.weaponstatus[VULCS_CHAMBER1]=(!random(0,3))?2:1;
			vvv.weaponstatus[VULCS_CHAMBER2]=(!random(0,3))?2:1;
			vvv.weaponstatus[VULCS_CHAMBER3]=(!random(0,3))?2:1;
			vvv.weaponstatus[VULCS_CHAMBER4]=(!random(0,3))?2:1;
			vvv.weaponstatus[VULCS_CHAMBER5]=(!random(0,3))?2:1;
			if(superauto)vvv.weaponstatus[0]|=VULCF_FAST;
			vvv.weaponstatus[VULCS_BATTERY]=random(1,20);
			vvv.weaponstatus[VULCS_BREAKCHANCE]=random(0,random(1,500));
			vvv.weaponstatus[VULCS_ZOOM]=random(16,70);
		}else if(!bfriendly){
			DropNewItem("HD4mMag",96);
			DropNewItem("HD4mMag",96);
			DropNewItem("HDBattery",8);
		}
	}
	states{
	spawn:
		CPOS B 1 nodelay{
			A_HDLook();
			A_Recoil(random(-1,1)*0.1);
			A_SetTics(random(10,40));
		}
		CPOS BB 1{
			A_HDLook();
			A_SetTics(random(10,40));
		}
		CPOS A 8{
			if(bambush)setstatelabel("spawnhold");
			else if(!random(0,1))setstatelabel("spawnstill");
			else A_Recoil(random(-1,1)*0.2);
		}loop;
	spawnhold:
		CPOS G 1{
			A_HDLook();
			if(!random(0,8))A_Recoil(random(-1,1)*0.4);
			A_SetTics(random(10,30));
			if(!random(0,8))A_Vocalize(activesound);
		}wait;
	spawnstill:
		CPOS C 0 A_Jump(196,"spawnscan","spawnscan","spawnwander");
		CPOS C 0{
			A_HDLook();
			A_Recoil(random(-1,1)*0.4);
		}
		CPOS CD 5{angle+=random(-4,4);}
		CPOS AB 5{
			A_HDLook();
			if(!random(0,15))A_Vocalize(activesound);
			angle+=random(-4,4);
		}
		CPOS B 1 A_SetTics(random(10,40));
		---- A 0 setstatelabel("spawn");
	spawnwander:
		CPOS A 0 A_HDLook();
		CPOS CD 5 A_HDWander();
		CPOS A 5{
			A_HDLook();
			if(!random(0,15))A_Vocalize(activesound);
			A_HDWander();
		}
		CPOS B 5 A_HDWander();
		CPOS A 0 A_Jump(96,"spawn","spawnscan");
		loop;
	spawnscan:
		CPOS E 4{
			turnleft=randompick(0,0,0,1);
			if(turnleft)angle-=frandom(18,24);
			else angle+=frandom(18,24);
		}
	spawnturn:
		CPOS EEEEEE 4 A_HDLook(label:"missile");
		CPOS E 0 A_Jump(116,"spawnturn","spawnscan","spawnscan");
		---- A 0 setstatelabel("spawnwander");
	see:
	scan:
		CPOS E 4{
			turnleft=randompick(0,0,0,1);
			if(turnleft)angle-=frandom(18,24);
			else angle+=frandom(18,24);
		}
	scanturn:
		CPOS E 0{if(!targetinsight)A_HDLook(LOF_NOJUMP|LOF_NOSOUNDCHECK);}
		CPOS EEEEEE 4 A_Watch();
		CPOS E 0 A_Jump(32,"scanturn","scanturn","scan");
		//fallthrough to seemove
	seemove:
		CPOS A 0 A_JumpIf(!mags&&thismag<1,"reload");
		CPOS ABCD 5 A_HDChase(null,"melee");
		CPOS A 0 A_Jump(64,"scan");
		loop;
	missile:
		CPOS ABCD 5 A_TurnToAim(30,shootstate:"aim");
		loop;
	aim:
		CPOS E 2{
			if(
				target
				&&target.spawnhealth()>random(50,1000)
			)superauto=true;
		}
		CPOS E 1 A_StartAim(rate:0.92,maxtics:random(20,30));
		//fallthrough to shoot
	shoot:
		CPOS E 4 A_LeadTarget(6);
	fire:
		CPOS F 1 bright light("SHOT") A_VulcZombieShot();
		CPOS E 2 A_JumpIf(superauto,"fire");
		loop;
	postshot:
	considercover:
		CPOS E 1;
		CPOS E 0 A_JumpIf(thismag<1&&mags<1,"reload");
	cover:
		CPOS EEEE 3 A_Coverfire("fire",5);
		loop;
	shuntmag:
		CPOS E 1;
		CPOS E 3{
			A_StartSound("weapons/vulcshunt",8);
			if(thismag>=0){
				actor mmm=HDMagAmmo.SpawnMag(self,"HD4mMag",0);
				mmm.A_ChangeVelocity(3,frandom(-3,2),frandom(0,-2),CVF_RELATIVE|CVF_REPLACE);
			}
			thismag=-1;
			if(mags>0){
				mags--;
				thismag=50;
			}
		}
		---- A 0 setstatelabel("fire");
	chamber:
		CPOS E 3{
			if(chambers<5&&thismag>0){
				thismag--;
				chambers++;
				A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
			}
		}
		---- A 0 setstatelabel("fire");

	reload:
		CPOS A 0 A_JumpIf(!target||!checksight(target),"loadamag");
		CPOS ABCD 5 A_Chase(null,null,flags:CHF_FLEE);
	loadamag:
		CPOS E 9 A_StartSound("weapons/pocket",9);
		CPOS E 7 A_StartSound("weapons/vulcmag",8);
		CPOS E 10{
			if(thismag<0)thismag=50;
			else if(mags<4)mags++;
			else{
				setstatelabel("seemove");
				return;
			}A_StartSound("weapons/rifleclick2",8);
		}loop;

	melee:
		CPOS DAB 2 A_FaceTarget(10,10);
		CPOS C 6 A_FaceTarget();
		CPOS D 2;
		CPOS E 3 A_CustomMeleeAttack(
			random(9,99),"weapons/smack","","none",randompick(0,0,0,1)
		);
		CPOS E 2 A_JumpIfTargetInsideMeleeRange("melee");
		---- A 0 setstatelabel("considercover");
		CPOS E 0 A_JumpIf(target.health<random(-3,1),"see");
		CPOS EC 2;
		---- A 0 setstatelabel("melee");

	pain:
		CPOS G 3;
		CPOS G 3 A_Vocalize(painsound);
		---- A 0 setstatelabel("seemove");


	death:
		CPOS H 5;
		CPOS I 5{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
			A_Vocalize(deathsound);
		}
		CPOS J 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		CPOS KL 5;
		CPOS M 5;
	dead:
		CPOS M 3;
		CPOS N 5 canraise{
			if(abs(vel.z)>1)setstatelabel("dead");
		}wait;
	xxxdeath:
		CPOS LKO 3;
		CPOS P 3{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
			A_XScream();
		}
		CPOS R 2;
		CPOS QRS 5;
		---- A 0 setstatelabel("xdead");

	xdeath:
		CPOS O 5;
		CPOS P 3{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
			A_XScream();
		}
		CPOS R 2 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		CPOS Q 5;
		CPOS Q 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		CPOS RS 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
	xdead:
		CPOS S 3;
		CPOS T 5 canraise{
			if(abs(vel.z)>1)setstatelabel("dead");    
		}wait;
	raise:
		CPOS N 2 A_SpawnItemEx("MegaBloodSplatter",0,0,4,0,0,3,0,SXF_NOCHECKPOSITION);
		CPOS NML 6;
		CPOS KJIH 4;
		#### A 0 A_Jump(256,"see");
	ungib:
		CPOS T 6 A_SpawnItemEx("MegaBloodSplatter",0,0,4,0,0,3,0,SXF_NOCHECKPOSITION);
		CPOS TS 12 A_SpawnItemEx("MegaBloodSplatter",0,0,4,0,0,3,0,SXF_NOCHECKPOSITION);
		CPOS RQ 7;
		CPOS POH 5;
		#### A 0 A_Jump(256,"see");
	}
}
