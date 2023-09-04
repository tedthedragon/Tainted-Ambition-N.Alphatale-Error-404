// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if something happened to them.
// ------------------------------------------------------------

//All monsters should inherit from this.
class HDMobBase : HDActor{
	int hdmobflags;
	flagdef doesntbleed:hdmobflags,0;
	flagdef hasdropped:hdmobflags,1;
	flagdef gibbed:hdmobflags,2;
	flagdef novitalshots:hdmobflags,3;
	flagdef hashelmet:hdmobflags,4;
	flagdef smallhead:hdmobflags,5;
	flagdef biped:hdmobflags,6;
	flagdef noshootablecorpse:hdmobflags,7;
	flagdef playingid:hdmobflags,8;
	flagdef dontdrop:hdmobflags,9;  //this is for incap dropping not item droping
	flagdef norandomweakspots:hdmobflags,10;
	flagdef noincap:hdmobflags,11;
	flagdef noblurgaze:hdmobflags,12;
	flagdef nodeathdrop:hdmobflags,13;  //skip deathdrop() check
	flagdef chasealert:hdmobflags,14;  //will call A_ShoutAlert
	flagdef lefthanded:hdmobflags,15;
	flagdef climber:hdmobflags,16;
	flagdef climbpastdropoff:hdmobflags,17;
	flagdef bloodlesswhileshielded:hdmobflags,18;
	flagdef headless:hdmobflags,19;  //no separate head target - often it's all head
	flagdef onlyscreamondeath:hdmobflags,20;
	flagdef dontchecksight:hdmobflags,21; //no visual check when looking

	default{
		monster;
		radius 12;
		gibhealth 100;
		+dontgib
		-noblockmonst  //set true in HDActor, set false again in some monsters explicitly
		height 52;
		deathheight 24;
		burnheight 24;
		cameraheight 48;
		hdmobbase.gunheight 32;
		reactiontime 4;  //it's reduced by one per A_HDChase call, not per tic!
		bloodtype "HDMasterBlood";
		hdmobbase.shields 0;
		hdmobbase.downedframe 11; //"K"
		hdmobbase.landsound "misc/mobland";
		hdmobbase.stepsound "humanoid/step";
		hdmobbase.stepsoundwet "humanoid/squishstep";
		obituary "%o was killed by a $TAG.";
	}

	double liveheight;
	double deadheight;
	sound landsound;property landsound:landsound;
	sound stepsound;property stepsound:stepsound;
	sound stepsoundwet;property stepsoundwet:stepsoundwet;
	override void postbeginplay(){
		liveheight=default.height;
		deadheight=default.deathheight;
		hitboxscale=1.;
		voicepitch=1.;

		super.postbeginplay();

		resetdamagecounters();
		bplayingid=(Wads.CheckNumForName("id",0)!=-1);

		movepos=pos;
		ResetTargetPos();

		minmissilechance=(minmissilechance*random(4,12))>>3;

		HDF.CheckNoKillCount();
	}

	override void Tick(){
		super.tick();
		if(!self||isfrozen())return;

		if(firefatigue>0)firefatigue--;

		//reset reactiontime if teleported
		if(
			abs(prev.x-pos.x)>=64
			||abs(prev.y-pos.y)>=64
		){
			reactiontime=(default.reactiontime<<1);
		}
		//do some effects if fallen from a height
		else if(
			bsolid
			&&floorz<pos.z
		){
			double fallheight=floorz-pos.z;
			if(
				fallheight>vel.z
				&&vel.z<-4
			){
				HDMobFallSquishThinker.Init(self,fallheight,scale);
			}
		}

		//lighter-than-air enemies are a lot lighter than water
		if(
			bfloat
			&&waterlevel>1
		)vel.z=clamp(vel.z+0.5-getgravity(),vel.z,radius);


		//collision
		if(
			pos-prev!=lastvel
			&&abs(pos.x-prev.x)<100
			&&abs(pos.y-prev.y)<100
		){
			vector3 vchange=lastvel-vel;
			double vsq=
				vchange.x*vchange.x
				+vchange.y*vchange.y
				+vchange.z*vchange.z
			;
			if(blockingline){
				if(
					vsq>100
					&&doordestroyer.CheckDirtyWindowBreak(blockingline,mass*vsq*0.000001,(pos.xy,pos.z+height*0.5))
				)vel+=lastvel*0.2;
			}
		}


		DamageTicker();

		lastvel=vel;
	}
	vector3 lastvel;

	//randomize size
	double hitboxscale;
	double gunheight;property gunheight:gunheight;  //2022-06-23 missileheight is not modifiable
	void resize(double minscl=0.9,double maxscl=1.,int minhealth=0){
		double drad=radius;
		double dheight=height;
		double minchkscl=max(1.,minscl+0.1);
		double scl;
		do{
			scl=frandom(minscl,maxscl);
			A_SetSize(drad*scl,dheight*scl);
			maxscl=scl; //if this has to check again, don't go so high next time
		}while(
			//keep it smaller than the geometry
			scl>minchkscl
			&&!checkmove(pos.xy,PCM_NOACTORS)
		);
		A_SetHealth(int(health*max(scl,1)));
		scale*=scl;
		mass=int(scl*mass);
		speed*=scl;
		meleerange*=scl;
		gunheight*=scl;
		cameraheight*=scl;

		//save a few things for future reference
		hitboxscale=scl;
		liveheight=default.height*scl;
		deadheight=deathheight*scl;
	}
	override double getdeathheight(){
		return super.getdeathheight()*hitboxscale;
	}


	//give each monster a unique voice pitch
	double voicepitch;
	void A_Vocalize(sound soundname,int flags=0,double attenuation=ATTN_NORM,double volume=1.,double pitch=1.){
		A_StartSound(soundname,CHAN_VOICE,
			flags,
			volume,
			attenuation:attenuation,
			pitch:(hd_monstervoicepitch?voicepitch:1.)*pitch
		);
	}
	void A_HDBossScream(){
		DistantNoise.Make(self,deathsound,pitch:hd_monstervoicepitch?voicepitch:1.);
	}


	virtual void CheckFootStepSound(){}


	//return hitobituary as necessary
	override string GetObituary(Actor victim,Actor inflictor,Name mod,bool playerattack){
		string ob;
		double mll=meleerange+victim.radius;
		if(
			(
				mod=="bashing"
				||mod=="teeth"
				||mod=="claws"
				||mod=="nails"
			)
			&&victim.distance3dsquared(self)<=mll*mll
		)ob=HitObituary;
		else ob=super.GetObituary(victim,inflictor,mod,playerattack);
		let tag=gettag();
		if(bplayingid)tag=tag.makelower();
		ob.replace("$TAG",tag);
		return ob;
	}

	//drop an item without sending it flying
	//255=always spawn
	//256=always spawn and do not add any velocity
	Actor DropNewItem(class<actor> type,int chance=255){
		if(random(0,255)>chance)return null;
		let iii=spawn(type,(pos.xy,pos.z+height*0.6),ALLOW_REPLACE);
		if(!iii)return null;
		iii.bdropped=true;
		if(chance<256)iii.vel=vel+(frandom(-0.4,0.4),frandom(-0.4,0.4),frandom(0,0.6));
		return iii;
	}
	HDWeapon DropNewWeapon(class<hdweapon> type){
		let www=HDWeapon(DropNewItem(type,256));
		www.vel=(vel.xy+(cos(angle),sin(angle))*0.4,vel.z+0.6);
		www.angle=angle+frandom(-20,20);
		www.pitch=frandom(-20,20);
		www.setreflexreticle(random(-1,7));
		return www;
	}

	//allow climbing of walls
	bool CheckClimb(){
		bool onground=bonmobj||floorz>=pos.z;
		vector2 checkdir=(cos(angle),sin(angle));
		double zatrad=radius*HDCONST_SQRTTWO+1;
		double zatradten=getzat(zatrad);

		//make sure space above is big enough
		if(onground){
			double zbk=pos.z;
			setz(zatradten);
			bool checkdest=checkmove(pos.xy+checkdir*radius*2);
			setz(zbk);
			if(!checkdest)return false;
		}

		let tthr=threat;
		if(
			!tthr
			&&!!target
			&&(
				bfrightened
				||target.bfrightening
			)
		)tthr=target;

		if(
			(
				(
					!!tthr
					&&(
						absangle(angle,angleto(tthr))>70
						||!checksight(tthr)
					)
					&&(
						!!threat
						||tthr.health>0
					)
				)||(
					!!target
					&&(
						(
							pos.z>floorz
							&&prev.z-pos.z>3
						)
						||absangle(angle,angleto(target))<70
					)
					&&(
						target.health>0
						||(
							!checksight(target)
							&&random(0,63)
						)
					)
				)
			)
			&&zatradten>pos.z+maxstepheight
			&&getzat(zatrad,flags:GZF_CEILING)-zatradten>=height
			&&(
				bclimbpastdropoff
				||zatradten-floorz<=default.maxdropoffheight
			)
		){
			vector3 climbdest=(pos.xy+checkdir*(radius+10),zatradten);
			if(!level.ispointinlevel(climbdest))return false;

			if(
				!!tthr
				||(
					!!target
					&&distance3dsquared(target)>meleerange*meleerange
				)
			){
				bnodropoff=false;

				if(onground)vel.z+=3;
				else vel.z=max(vel.z,1);

				addz(max(5,speed*0.4)+2*scale.y,true);
				vel.x+=cos(angle)*radius*0.1;
				vel.y+=sin(angle)*radius*0.1;

				//face the wall
				if(blockingline){
					if(!blockingline.sidedef[1])return false;
					let delta=blockingline.delta;
					if(blockingline.backsector==cursector)delta=-delta;
					angle=VectorAngle(-delta.y,delta.x);
				}

				return true;
			}
		}return false;
	}

}



//Humanoid template
class HDHumanoid:HDMobBase{
	bool jammed;
	default{
		gibhealth 140;
		health 100;
		height HDCONST_PLAYERHEIGHT;
		hdmobbase.gunheight HDCONST_PLAYERHEIGHT*HDCONST_EYEHEIGHT;
		radius 12;
		deathheight 12;
		mass 120;
		speed 10;
		maxdropoffheight 48;
		+hdmobbase.smallhead
		+hdmobbase.biped
		+hdmobbase.chasealert
		+hdmobbase.climber
		hdmobbase.downedframe 11;
		tag "$cc_zombie";
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.9,1.1);
		gunheight=cameraheight-1.5;
		voicepitch=frandom(0.9,1.2);
		blefthanded=!random(0,3);
	}
	override void CheckFootStepSound(){
		FootStepSound(self);
	}
	static void FootStepSound(
		actor caller,
		double mult=1.,
		sound drysound="null",
		sound wetsound="null"
	){
		if(
			(
				caller.frame==1
				||caller.frame==3
			)
			&&caller.frame!=caller.curstate.nextstate.frame
		){
			if(
				drysound=="null"
				||wetsound=="null"
			){
				let hdp=HDPlayerPawn(caller);
				if(!!hdp){
					wetsound=hdp.stepsoundwet;
					drysound=hdp.stepsound;
				}else{
					let hdm=HDMobBase(caller);
					if(hdm){
						wetsound=hdm.stepsoundwet;
						drysound=hdm.stepsound;
					}
				}
			}

			if(
				HDMath.CheckLiquidTexture(caller)
				&&wetsound!="null"
			){
				caller.A_StartSound(wetsound,88,CHANF_OVERLAP,volume:mult);
			}else{
				if(
					HDMath.CheckDirtTexture(caller)
				)mult*=0.5;
				caller.A_StartSound(drysound,88,CHANF_OVERLAP,volume:mult);
			}
		}
	}
	//give armour
	hdarmourworn givearmour(double chance=1.,double megachance=0.,double minimum=0.){
		a_takeinventory("hdarmourworn");
		if(frandom(0.,1.)>chance)return null;
		let arw=hdarmourworn(giveinventorytype("hdarmourworn"));
		int maxdurability;
			if(frandom(0.,1.)<megachance){
			arw.mega=true;
			maxdurability=HDCONST_BATTLEARMOUR;
		}else maxdurability=HDCONST_GARRISONARMOUR;
		arw.durability=int(max(1,frandom(min(1.,minimum),1.)*maxdurability));
		return arw;
	}
	void A_EjectPistolCasing(){
		HDWeapon.EjectCasing(self,"HDSpent9mm",
			-frandom(89,92),
			(frandom(6,7),0,frandom(0,1)),
			(10,0,0)
		);
	}
	void A_EjectSMGCasing(){
		HDWeapon.EjectCasing(self,"HDSpent9mm",
			-frandom(79,81),
			(frandom(7,7.5),0,0),
			(13,0,0)
		);
	}
	void A_TurnHandDirection(double amt){
		if(blefthanded)angle+=amt;
		else angle-=amt;
	}
	override void A_HDChase(
		statelabel meleestate,
		statelabel missilestate,
		int flags,
		double speedmult
	){
		let aaa=HDArmourWorn(findinventory("HDArmourWorn"));
		if(aaa)speed=min(speed,aaa.mega?10:14);
		super.A_HDChase(meleestate,missilestate,flags,speedmult);
	}
	states{
	falldown:
		#### H 5;
		#### I 5 A_Vocalize(deathsound);
		#### JJKKK 2 A_SetSize(-1,max(deathheight,height-10));
		#### L 0 A_SetSize(-1,deathheight);
		#### L 10 A_KnockedDown();
		wait;
	standup:
		#### K 6;
		#### J 0 A_Jump(160,2);
		#### J 0 A_Vocalize(seesound);
		#### JI 4 A_Recoil(-0.3);
		#### HE 6;
		#### A 0 setstatelabel("see");
	melee:
		#### B 4 A_FaceTarget(0,0);
		#### A 0 A_JumpIf(
			!random(0,15)
			||(
				target
				&&target.pos.z+target.height<pos.z+height*0.6
			)
		,"meleekick");
		#### A 0 A_Jump(256,"meleebody","meleehead","meleeheadbig");
	meleekick:
		#### BC 3;
		#### A 6{
			pitch=0;
			A_HumanoidMeleeAttack(frandom(height*0.05,(!!target?target.height:0.4)),1.4);
		}
		#### A 0 setstatelabel("meleeend");
	meleebody:
		#### CD 3;
		#### E 5 A_HumanoidMeleeAttack(height*0.6);
		#### A 0 setstatelabel("meleeend");
	meleehead:
		#### CD 3;
		#### E 5 {
			pitch+=frandom(-40,-8);
			A_HumanoidMeleeAttack(height*0.7);
		}
		#### A 0 setstatelabel("meleeend");
	meleeheadbig:
		#### CB 3 A_TurnHandDirection(30);
		#### A 8 A_TurnHandDirection(30);
		#### BD 1 A_TurnHandDirection(-30);
		#### E 1 {
			A_TurnHandDirection(-30);
			pitch+=frandom(-45,-8);
			A_HumanoidMeleeAttack(height*0.7,3.);
		}
		#### E 4 A_TurnHandDirection(-10);
		#### A 0 setstatelabel("meleeend");
	meleeend:
		#### D 3 A_JumpIf(
			findstate("missile2",true)
			&&target
			&&!A_JumpIfCloser(64,"null")
		,"meleeendshoot");
		#### A 0 setstatelabel("see");
	meleeendshoot:
		#### E 3;
		#### E 4 A_FaceTarget(10,10);
		#### A 0 setstatelabel("missile2");
	}
	virtual void A_HumanoidMeleeAttack(double hitheight,double mult=1.){
		flinetracedata mtrace;
		linetrace(
			angle,
			meleerange,
			pitch,
			offsetz:hitheight,
			data:mtrace
		);
		if(!mtrace.hitactor){
			A_StartSound("misc/fwoosh",CHAN_WEAPON,CHANF_OVERLAP,volume:min(0.1*mult,1.));
			return;
		}
		A_StartSound("weapons/smack",CHAN_WEAPON,CHANF_OVERLAP);

		hitheight=mtrace.hitlocation.z-mtrace.hitactor.pos.z;
		double hitheightproportion=hitheight/mtrace.hitactor.height;
		string hitloc="";
		int dmfl=0;

		double dmg=
			clamp(20-absangle(angle,angleto(mtrace.hitactor))*0.5,1,10)
			*0.0084*(mass+speed)
			*mult
			*frandom(0.61803,1.61803)
		;

		if(hitheightproportion>0.8){
			hitloc="HEAD";
			dmg*=2.;
		}else if(hitheightproportion>0.5){
			hitloc="BODY";
		}else{
			hitloc="LEGS";
			dmg*=1.3;
		}

		if(hd_debug)console.printf(gettag().." hit "..mtrace.hitactor.gettag().." in the "..hitloc.." for "..dmg);

		addz(hitheight);
		mtrace.hitactor.damagemobj(self,self,int(dmg),"bashing",flags:dmfl);
		addz(-hitheight);

		//impact unjams held ZM66
		if(jammed&&!random(0,32)){
			if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,height-12,4,frandom(-2,2),frandom(2,4));
			for(int i=0;i<5;i++)A_SpawnItemEx("FourMilChunk",0,0,20,
				random(4,7),random(-2,2),random(-2,1),0,SXF_NOCHECKPOSITION
			);
			jammed=false;
			A_StartSound("weapons/rifleclick",8);
		}
	}
}
class HDHoid:HDHumanoid{
	default{+nopain +nodamage}
	states{
	spawn:
	pain:
		PLAY A -1;
		stop;
	}
}
//compat wrapper for the old name
class HDMobMan:HDHumanoid{}

