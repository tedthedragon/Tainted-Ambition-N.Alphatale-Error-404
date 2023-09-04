// ------------------------------------------------------------
// "I call the big one Bitey!"
// ------------------------------------------------------------
class Babuin:HDMobBase{

	actor latchtarget;
	double latchheight;  //as a proportion between 0 and 1
	double latchangle;  //relative to the latchtarget's angle
	double lastltangle;  //absolute, for comparison only
	double latchmass;

	override void postbeginplay(){
		super.postbeginplay();
		resize(0.9,1.1);
		voicepitch=1.6-scale.x+frandom(-0.1,0.1);
		lastpointinmap=pos;
		bbiped=bplayingid;
		bonlyscreamondeath=bplayingid;
		lastpointinmap=pos;
		latchmass=1.+mass*1./default.mass;
		maxstepheight=height*(bplayingid?0.6:0.8);
	}
	void TryLatch(){
		if(
			blockingline
			&&CheckClimb()
		){
			setstatelabel("see");
			return;
		}

		double checkrange=!!target?(target.radius*HDCONST_SQRTTWO)+meleerange:0;
		if(
			health<1
			||!target
			||target==self
			||!target.height
			||distance3dsquared(target)>checkrange*checkrange
			||absangle(angleto(target),angle)>30
			||!checkmove(0.5*(pos.xy+target.pos.xy),PCM_NOACTORS)
		){
			latchtarget=null;
			return;
		}else{
			bnodropoff=false;
			latchtarget=target;

			latchheight=(pos.z-latchtarget.pos.z)/latchtarget.height;
			lastltangle=latchtarget.angle;
			latchangle=deltaangle(lastltangle,latchtarget.angleto(self));

			setstatelabel("latched");
		}
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			(
				other!=latchtarget
				&&other!=target
			)||(
				!latchtarget
				&&max(
					abs(other.pos.x-pos.x),
					abs(other.pos.y-pos.y)
				)>=other.radius+radius  
			)
		);
	}
	override void Die(actor source,actor inflictor,int dmgflags){
		latchtarget=null;
		super.Die(source,inflictor,dmgflags);
	}
	vector3 lastpointinmap;
	override void Tick(){
		if(isfrozen())return;

		//brutal force
		if(
			health>0
			&&(
				!level.ispointinlevel(pos)
				||!checkmove(pos.xy,PCM_NOACTORS)
			)
		){
			setorigin(lastpointinmap,true);
			setz(clamp(pos.z,floorz,ceilingz-height));
		}else lastpointinmap=pos;


		if(latchtarget){
			A_Face(latchtarget,0,0);


			vector3 lp=latchtarget.pos;
			bool teleported=
				abs(lp.x-pos.x)>100||
				abs(lp.y-pos.y)>100||
				abs(lp.z-pos.z)>100
			;
			

			double oldz=pos.z;
			setz(max(floorz,min(
				latchtarget.pos.z+latchtarget.height*latchheight,
				latchtarget.pos.z+latchtarget.height-height*0.6
			)));

			vector2 newxy=latchtarget.pos.xy+
				+angletovector(
					latchtarget.angle+latchangle,
					latchtarget.radius*frandom(0.9,1.)
				)
			;

			//abort if blocked
			if(
				max(
//					absangle(lastltangle,latchtarget.angle)*latchheight,
					abs(newxy.x-pos.x),
					abs(newxy.y-pos.y)
				)>frandom(10,100)
				||!checkmove(newxy,PCM_NOACTORS)
				||!level.ispointinlevel((newxy,pos.z))
				||!latchtarget
				||latchtarget.health<random(-10,1)
			){
				setz(oldz);
				if(latchtarget.health>0){
					A_Changevelocity(-5,frandom(-2,2),frandom(2,4),CVF_RELATIVE);
					forcepain(self);
				}else{
					target=lastenemy;
					setstatelabel("idle");
				}
				latchtarget=null;
			}


			if(latchtarget){
				lastltangle=latchtarget.angle;

				setorigin(
					(newxy,pos.z)+(frandom(-1,1),frandom(-1,1),frandom(-1,1))
					,!teleported
				);


				if(!random(0,30))A_Vocalize(painsound);


				double latchforce=max(latchheight,-latchheight*5)*latchmass;
				let hdp=hdplayerpawn(latchtarget);


				bool onground=
					latchtarget.bonmobj
					||latchtarget.floorz>=latchtarget.pos.z;
				double latchjump=0.;

				//fuck with the victim's pitch/angle and movement
				if(latchtarget.health>0){
					if(hdp){
						vector2 vvv=(frandom(-5,5),frandom(-4,6));
						hdp.muzzleclimb1+=vvv*latchforce;
						hdp.muzzleclimb2+=vvv*latchforce;
					}else if(
						latchtarget.bismonster
						||(
							latchtarget.player
							&&latchtarget.player.bot
						)
					){
						latchtarget.pitch=clamp(
							latchtarget.pitch+frandom(-8,8)*latchforce,-90,90
						);
						latchtarget.angle+=frandom(-8,8)*latchforce;

						//make bots and monsters thrash to try to shake it off
						latchtarget.angle+=frandom(-20,20);
					}

					if(onground){
						if(latchtarget.pos.x<pos.x)latchtarget.vel.x+=0.1*latchforce;
						else if(latchtarget.pos.x>pos.x)latchtarget.vel.x-=0.1*latchforce;
						if(latchtarget.pos.y<pos.y)latchtarget.vel.y+=0.1*latchforce;
						else if(latchtarget.pos.y>pos.y)latchtarget.vel.y-=0.1*latchforce;
					}else if(latchtarget.bfloat)latchjump=-0.1*latchforce;
				}

				//inflict damage
				if(!(level.time&1))switch(random(0,5)){
				case 0:
					latchjump=frandom(0,2)*latchforce;
					double laa=(latchangle%90)*0.2;
					if(hdp){
						hdp.muzzleclimb1+=(latchforce*frandom(0,laa),frandom(0,latchforce*5));
						hdp.muzzleclimb2+=(latchforce*frandom(0,laa),frandom(0,latchforce*5));
						hdp.muzzleclimb3+=(latchforce*frandom(0,laa),frandom(0,latchforce*5));
					}else{
						latchtarget.angle+=latchforce*frandom(0,laa*3);
						latchtarget.pitch=clamp(
							latchtarget.pitch+frandom(0,latchforce*15),-90,90
						);
					}
					latchtarget.damagemobj(
						self,self,1+int(frandom(0,8)*latchforce),"jointlock"
					);break;
				case 1:
					latchjump=frandom(1,3)*latchforce;
					latchtarget.damagemobj(
						self,self,int(frandom(0,10)*latchforce),"falling"
					);break;
				default:
					setorigin(pos+(frandom(-1,1),frandom(-1,1),frandom(-1,1))*2,true);
					latchtarget.damagemobj(
						self,self,2+int(frandom(0,8*latchforce)),"teeth"
					);break;
				}

				if(
					onground
					&&!!latchtarget
					&&latchjump
				)latchtarget.vel.z+=latchjump;

				latchheight=clamp(latchheight+frandom(-0.01,0.014),-0.2,0.9);
			}


			NextTic();
		}
		else super.Tick();
	}
	void A_CheckFreedoomSprite(){
		if(bplayingid)sprite=getspriteindex("SRG2");
		else sprite=getspriteindex("SARG");
	}
	override void CheckFootStepSound(){
		if(bplayingid)HDHumanoid.FootStepSound(self,0.4,drysound:"babuin/step");
		else if(!frame)A_StartSound("babuin/wormstep",88,CHANF_OVERLAP);
	}

	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Babuin"
		//$Sprite "SRG2A1"

		+hdmobbase.chasealert
		+cannotpush +pushable
		+hdmobbase.climber
		+hdmobbase.climbpastdropoff
		health 90;radius 12;
		height 32;deathheight 10;
		scale 0.6;
		translation "16:47=48:79";
		speed 12;
		mass 70;
		meleerange 40;
		maxtargetrange 420;
		minmissilechance 220;
		painchance 90; pushfactor 0.2;

		maxstepheight 24;maxdropoffheight 64;

		seesound "babuin/sight";painsound "babuin/pain";
		deathsound "babuin/death";activesound "babuin/active";
		obituary "$OB_BABUIN";
		damagefactor "hot",0.76;
		tag "$TAG_BABUIN";
	}

	states{
	spawn:
		SARG A 0;
		SRG2 A 0 A_CheckFreedoomSprite();
	idle:
		#### A 0 A_JumpIf(bambush,"spawnstill");
	spawnwander:
		#### ABCD random(4,6){
			blookallaround=false;
			hdmobai.wander(self);
		}
		#### A 0{
			if(!random(0,5))setstatelabel("spawnsniff");
			else if(!random(0,9))A_Vocalize(activesound);
		}loop;
	spawnsniff:
		#### A 0{blookallaround=true;}
		#### EEEE 4{
			angle+=frandom(-2,2);
			A_HDLook();
		}
		#### F 2{
			angle+=frandom(-20,20);
			if(!random(0,9))A_Vocalize(activesound);
		}
		#### FFF 2 A_HDLook();
		#### A 0{
			blookallaround=false;
			if(!random(0,6))setstatelabel("spawnwander");
		}loop;
	spawnstill:
		#### AB 8 A_HDLook();
		loop;
	see:
		#### A 0{
			//because babuins come into this state from all sorts of weird shit
			if(
				!checkmove(pos.xy,true)
				&&blockingmobj
			){
				setorigin((pos.xy+(pos.xy-blockingmobj.pos.xy),pos.z+1),true);
			}

			blookallaround=false;
			if(!random(0,127))A_Vocalize(seesound);
			MustUnstick();

			if(CheckClimb())return;

			bnofear=target&&distance3dsquared(target)<65536.;

			if(
				(target&&checksight(target))
				||!random(0,7)
			)setstatelabel("seechase");
			else setstatelabel("roam");
		}
	seechase:
		#### ABCD random(2,4) A_HDChase();
		---- A 0 setstatelabel("seeend");
	roam:
		#### ABCD random(3,6){
			A_HDChase(flags:CHF_WANDER);
			A_HDLook();
		}
		---- A 0 setstatelabel("seeend");
	seeend:
		#### A 0 givebody(random(2,12));
		#### A 0 A_Jump(256,"see");
	melee:
		#### EE 3{
			A_FaceTarget(0,0);
			A_Vocalize("babuin/bite");
			A_Changevelocity(cos(pitch)*2,0,sin(-pitch)*2,CVF_RELATIVE);
		}
		#### FF 3 A_Changevelocity(cos(pitch)*3,0,sin(-pitch)*3+2,CVF_RELATIVE);
		#### GG 1 TryLatch();
	postmelee:
		#### G 6 A_CustomMeleeAttack(random(5,15),"","","teeth",true);
		---- A 0 setstatelabel("see");

	latched:
		#### EF random(1,2);
		#### A 0 A_JumpIf(!latchtarget,"pain");
		loop;

	missile:
		#### ABCD 2{
			A_FaceTarget(16,16);
			bnodropoff=false;
			A_Changevelocity(1,0,0,CVF_RELATIVE);
			if(A_JumpIfTargetInLOS("null",20,0,128)){
				A_Vocalize(seesound);
				setstatelabel("jump");
			}
		}
		---- A 0 setstatelabel("see");
	jump:
		#### A 3 A_FaceTarget(16,16);
		#### E 3{
			A_Changevelocity(cos(pitch)*3,0,sin(-pitch)*3,CVF_RELATIVE);
		}
		#### E 2 A_FaceTarget(6,6,FAF_TOP);
		#### F 1 A_ChangeVelocity(cos(pitch)*16,0,sin(-pitch-frandom(-4,1))*16,CVF_RELATIVE);
		#### FF 1 TryLatch();
	fly:
		#### F 1{
			TryLatch();
			if(
				bonmobj
				||floorz>=pos.z
				||vel.xy==(0,0)
			)setstatelabel("land");
			else if(max(abs(vel.x),abs(vel.y)<3))vel.xy+=(cos(angle),sin(angle))*0.1;
		}wait;
	land:
		#### FEH 3{vel.xy*=0.8;}
		#### D 4{vel.xy=(0,0);}
		#### ABCD 3 A_HDChase("melee",null);
		---- A 0 setstatelabel("see");
	pain:
		#### H 2 A_SetSolid();
		#### H 6 A_Vocalize(painsound);
		#### ABCD 2 A_HDChase();
		---- A 0 setstatelabel("see");
	death:
		#### I 5{
			A_CheckFreedoomSprite();
			A_Vocalize(deathsound);
			bpushable=false;
			A_SpawnItemEx("BFGNecroShard",flags:SXF_TRANSFERPOINTERS|SXF_SETMASTER,240);
		}
	deathend:
		#### J 5 A_NoBlocking();
		#### KLM 5;
	dead:
	death.spawndead:
		#### M 3 canraise{
			if(abs(vel.z)<2)frame++;
		}loop;
	raise:
		#### NMLKJI 5;
		SRG2 A 0 A_CheckFreedoomSprite();
		#### A 0 A_Jump(256,"see");
	ungib:
		TROO U 6;
		TROO UT 8;
		TROO SRQ 6;
		TROO PO 4;
		SRG2 A 0 A_CheckFreedoomSprite();
		#### A 0 A_Jump(256,"see");
	xdeath:
		TROO O 0 A_XScream();
		TROO OPQ 4{spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);}
		TROO RST 4;
		goto xdead;
	xxxdeath:
		TROO O 4 A_XScream();
		TROO PQRST 4;
	xdead:
		TROO T 5 canraise{
			if(abs(vel.z)<2)frame++;
		}loop;
	}
}


class SpecBabuin:Babuin{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Babuin (Cloaked)"
		//$Sprite "SRG2A1"

		renderstyle "fuzzy";
		dropitem "HDBlurSphere",1;
		tag "$TAG_SPECBABUIN";
	}
	override void Tick(){
		if(
			frame>3
		){
			a_setrenderstyle(1.,STYLE_Normal);
			bspecialfiredamage=false;
		}else if(!(level.time&(2|4))){
			if(bspecialfiredamage){
				a_setrenderstyle(0.9,STYLE_Fuzzy);
				bspecialfiredamage=false;
			}else{
				a_setrenderstyle(0.,STYLE_None);
				bspecialfiredamage=true;
			}
		}
		super.Tick();
	}
	states{
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(2,14),
			vel.x,vel.y,vel.z+random(1,3),0,
			SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
		);
		TNT1 A 0 A_CheckFreedoomSprite();
		TNT1 A 0 A_SetTranslucent(1,0);
		goto super::death;
	xdeath:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(2,14),
			vel.x,vel.y,vel.z+random(1,3),0,
			SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
		);
		TNT1 A 0 A_SetTranslucent(1,0);
		goto super::xdeath;
	}
}
class DeadBabuin:Babuin{
	override void postbeginplay(){
		super.postbeginplay();
		A_CheckFreedoomSprite();
		A_Die("spawndead");
	}
}
class DeadSpecBabuin:SpecBabuin{
	override void postbeginplay(){
		super.postbeginplay();
		A_CheckFreedoomSprite();
		A_NoBlocking();
		A_SetTranslucent(1,0);
		A_Die("spawndead");
	}
}


class DeadDemonSpawner:RandomSpawner replaces DeadDemon{
	default{
		+ismonster
		dropitem "DeadBabuin",256,5;
		dropitem "DeadSpecBabuin",256,2;
		dropitem "DeadSpectre",256,1;
	}
}
