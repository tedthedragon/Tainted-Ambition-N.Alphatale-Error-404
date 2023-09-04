// ------------------------------------------------------------
// Hello.
// ------------------------------------------------------------

/*
	SPECIAL NOTE FOR MAPPERS
	You can customize individual characters using the user_ variables:

	user_weapon may be set 1-4 for ZM66, shotgun, SMG or RL.
	user_colour may be set 1-3 for white, brown or black.
		(technically any number not 1 or 3 is brown)
		add 100 to force masc voice, 200 fem, 300 neutral, 400 robot.

	Invert user_colour (e.g., -3 for dark skin) to use the goon red.
	Set an variable to zero to use the actor default. (HDOperator is random)
*/

class HDOperator:HDHumanoid replaces ScriptedMarine{
	enum HDOperatorStats{
		HDMW_RANDOM=0,
		HDMW_ZM66=1,
		HDMW_HUNTER=2,
		HDMW_SMG=3,
		HDMW_ROCKET=4,

		HDMBC_WARPLIMIT=4,
	}
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Operator"
		//$Sprite "PLAYA1"

		monster;
		+friendly
		+quicktoretaliate
		+activatepcross
		+hdmobbase.hashelmet
		speed 16;
		maxdropoffheight 64;
		maxstepheight 30;
		maxtargetrange 65536;
		minmissilechance 24;
		mass 150;
		seesound "operatorn/sight";
		painchance 240;
		obituary "$OB_MARINE";
		hitobituary "$OB_MARINEHIT";
		tag "$CC_MARINE";
	}
	int user_weapon;property user_weapon:user_weapon;
	int user_colour;property user_colour:user_colour;
	int gunloaded;
	int gunmax;
	int gunspent;
	int pistolloaded;
	bool glloaded;
	int wep;
	override void die(actor source,actor inflictor,int dmgflags){
		if(
			bfriendly
			&&!BotBot(self)
			&&!HDPlayerCorpse(self)
			&&getage()>TICRATE
		)A_Log(string.format("\cf%s died.",gettag()));
		super.die(source,inflictor,dmgflags);
	}
	override void Tick(){
		super.Tick();
		if(isfrozen())return;
		if(messagetimer>0)messagetimer--;
	}
	override void beginplay(){
		super.beginplay();
		givensprite=getspriteindex("PLAYA1");
		bhasdropped=false;
		spread=0;
		timesdied=0;
		jammed=0;

		//legacy settings
		if(stamina&&!user_colour){
			console.printf("Use of stamina deprecated. Please use user_colour to set operator appearance instead.");
			user_colour=stamina;
		}
		if(accuracy&&!user_weapon){
			console.printf("Use of stamina deprecated. Please use user_weapon to set operator weapon instead.");
			user_weapon=accuracy;
		}

		//weapon
		pistolloaded=15;
		glloaded=true;
		wep=user_weapon?user_weapon:clamp(random(1,4)-random(0,3),1,4);

		if(wep==HDMW_ZM66)gunmax=50;
		else if(wep==HDMW_HUNTER)gunmax=8;
		else if(wep==HDMW_SMG)gunmax=30;
		else if(wep==HDMW_ROCKET)gunmax=6;
		gunloaded=gunmax;


		//appearance
		SetSightPainDeath(
			self,
			user_colour?(abs(user_colour)/100):random(0,3)
		);

		user_colour%=100;

		string trnsl="";
		if(user_colour<0||self is "HDGoon")trnsl="Redshirt";else{
			if(wep==HDMW_ZM66)trnsl="Rifleman";
			else if(wep==HDMW_HUNTER)trnsl="Enforcer";
			else if(wep==HDMW_SMG)trnsl="Infiltrator";
			else if(wep==HDMW_ROCKET)trnsl="Rocketeer";
		}

		int melanin=user_colour?abs(user_colour):random(1,3);
		if(melanin==1)trnsl=string.format("White%s",trnsl);
		else if(melanin==3)trnsl=string.format("Black%s",trnsl);
		else trnsl=string.format("Brown%s",trnsl);

		A_SetTranslation(trnsl);
	}
	static void SetSightPainDeath(
		actor caller,
		int which=-1
	){
		if(which<0||which>3)which=random(0,3);
		string ggg="n";
		switch(which){
			case 0:ggg="m";break;
			case 1:ggg="f";break;
			case 3:ggg="b";break;
			case 2:
			default:ggg="n";break;
		}
		caller.seesound="operator"..ggg.."/sight";
		caller.painsound="operator"..ggg.."/pain";
		caller.deathsound="operator"..ggg.."/death";
	}
	virtual string SetNickname(int flags=0){
		if(!bfriendly){
			string ano="Anonymous";
			settag(ano);
			return ano;
		}

		//avoid repeats
		array<string> nicknames;nicknames.clear();
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i])nicknames.push(players[i].getusername());
		}
		HDOperator nmm;
		thinkeriterator nmit=thinkeriterator.create("HDOperator",STAT_DEFAULT);
		while(nmm=HDOperator(nmit.Next(exact:false))){
			if(nmm!=self)nicknames.push(nmm.gettag().makelower());
		}

		string nnn;
		bool unique;

		do{
			unique=true;
			nnn=HDMobBase.GenerateUserName();

			//this can theoretically crash... at least if the RNG were a true RNG.
			string nnntest=nnn.makelower();
			for(int i=0;i<nicknames.size();i++){
				if(nnntest==nicknames[i]){
					unique=false;
					break;
				}
			}
		}while(!unique);

		settag(nnn);
		return nnn;
	}
	virtual void A_HDMScream(){
		A_Vocalize(deathsound);
	}
	virtual void A_HDMPain(){
		A_Vocalize(painsound);
	}
	int givensprite;
	override void postbeginplay(){
		super.postbeginplay();
		givearmour(1.,0.12,0.6);
		SetNickname();
	}
	int lastinginjury;
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			health>0
			&&!(flags&DMG_FORCED)
			&&damage<TELEFRAG_DAMAGE
			&&damage>=health
			&&mod!="raisedrop"
			&&mod!="spawndead"
			&&damage<random(12,300-(lastinginjury<<1))
			&&(
				(mod=="bleedout"&&random(0,12))
				||(random(0,2))
			)
		){
			lastinginjury+=max((mod=="bashing"?0:1),(damage>>5));
			damage=health-5;
		}
		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}
	override void deathdrop(){
		if(getage()<35)return;

		if(bhasdropped){
			class<actor> dropammo="";
			if(wep==HDMW_SMG)dropammo="HD9mMag30";
			else if(wep==HDMW_ZM66)dropammo="HD4mMag";
			else if(wep==HDMW_ROCKET)dropammo="HDRocketAmmo";
			else if(wep==HDMW_HUNTER)dropammo="ShellPickup";
			if(
				dropammo!=""
				&&!random(0,timesdied)
			)DropNewItem(dropammo);
			if(!random(0,12+timesdied))DropNewItem("HD9mMag15");
			if(
				!random(0,timesdied)&&wep==HDMW_SMG
			)DropNewItem("HDRocketAmmo");
		}else{
			bhasdropped=true;
			hdweapon dropped=null;
			wep=abs(wep);
			if(wep==HDMW_SMG){
				dropped=DropNewWeapon("HDSMG");
				if(gunloaded){
					dropped.weaponstatus[SMGS_MAG]=gunloaded-1;
					dropped.weaponstatus[SMGS_CHAMBER]=2;
				}else{
					dropped.weaponstatus[SMGS_MAG]=0;
					dropped.weaponstatus[SMGS_CHAMBER]=0;
				}
			}else if(wep==HDMW_ZM66){
				dropped=DropNewWeapon("ZM66AssaultRifle");
				if(gunloaded){
					dropped.weaponstatus[ZM66S_MAG]=gunloaded-1;
					dropped.weaponstatus[0]|=ZM66F_CHAMBER;
				}else{
					dropped.weaponstatus[ZM66S_MAG]=0;
					dropped.weaponstatus[0]&=~ZM66F_CHAMBER;
				}
				if(jammed||!random(0,15))dropped.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
				if(glloaded)dropped.weaponstatus[0]|=ZM66F_GRENADELOADED;
			}else if(wep==HDMW_ROCKET){
				dropped=DropNewWeapon("HDRL");
				if(gunloaded){
					dropped.weaponstatus[RLS_MAG]=gunloaded-1;
					dropped.weaponstatus[RLS_CHAMBER]=1;
				}else{
					dropped.weaponstatus[RLS_MAG]=0;
					dropped.weaponstatus[RLS_CHAMBER]=0;
				}
			}else if(wep==HDMW_HUNTER){
				dropped=DropNewWeapon("Hunter");
				if(gunloaded){
					dropped.weaponstatus[HUNTS_TUBE]=gunloaded-1;
					dropped.weaponstatus[HUNTS_CHAMBER]=2;
				}else{
					dropped.weaponstatus[HUNTS_TUBE]=0;
					dropped.weaponstatus[HUNTS_CHAMBER]=0;
				}
				dropped.weaponstatus[SHOTS_SIDESADDLE]=random(0,12);
				dropped.weaponstatus[HUNTS_FIREMODE]=1;
				if(!random(0,31))dropped.weaponstatus[0]|=HUNTF_CANFULLAUTO;
				else dropped.weaponstatus[0]&=~HUNTF_CANFULLAUTO;
			}

			//drop the pistol
			dropped=DropNewWeapon("HDPistol");
			dropped.vel=vel+(frandom(-1,1),frandom(-1,1),2);
			if(pistolloaded){
				dropped.weaponstatus[PISS_MAG]=pistolloaded-1;
				dropped.weaponstatus[PISS_CHAMBER]=2;
			}else{
				dropped.weaponstatus[PISS_MAG]=0;
				dropped.weaponstatus[PISS_CHAMBER]=0;
			}

			//drop the blooper
			if(wep!=HDMW_SMG&&wep!=HDMW_HUNTER)return;
			dropped=HDWeapon(DropNewItem("Blooper"));
			if(glloaded)dropped.weaponstatus[0]|=BLOPF_LOADED;
		}
	}



	//returns true if area around target is clear of friendlies
	bool A_CheckBlast(actor tgt=null,double checkradius=256){
		if(!tgt)tgt=target;
		if(!tgt)return true;
		blockthingsiterator itt=blockthingsiterator.create(tgt,checkradius);
		while(itt.next()){
			actor it=itt.thing;
			if(
				it.health>0&&
				(isfriend(it)||isteammate(it))
			)return false;
		}
		return true;
	}

	actor A_OpShot(class<actor> missiletype,bool userocket=false){
		actor mmm=spawn(missiletype,(pos.xy,pos.z+gunheight),ALLOW_REPLACE);
		mmm.pitch=pitch+frandom(0,spread)-frandom(0,spread);
		mmm.angle=angle+frandom(0,spread)-frandom(0,spread);
		mmm.target=self;

		//one very special case
		if(userocket&&mmm is "RocketGrenade")RocketGrenade(mmm).isrocket=true;
		else userocket=false;

		if(!(mmm is "SlowProjectile"))mmm.A_ChangeVelocity(
			mmm.speed*cos(mmm.pitch),0,mmm.speed*sin(mmm.pitch),CVF_RELATIVE
		);
		return mmm;
	}
	//replaces with zombie if dying while zombie-sprited
	void A_DeathZombieZombieDeath(){
		if(
			sprite==getspriteindex("POSSA1")
			||sprite==getspriteindex("SPOSA1")
		){
			actor zzz=spawn("ZombieStormtrooper",pos,ALLOW_REPLACE);
			zzz.vel=vel;
			zzz.A_Die("extreme");
			destroy();
		}
	}


	//for deciding what to do
	bool ReloadNow(double dist){
		int awp=abs(wep);
		return
		(
			//everything is dry and they're right on us
			(
				gunloaded<1
				&&pistolloaded<1
			)
			&&dist>128
		)
		||(
			(
				//should reload
				(
					awp==HDMW_ZM66
					&&(
						!glloaded
						||gunloaded<1
					)
				)||(
					awp==HDMW_SMG
					&&(
						!glloaded
						||gunloaded<random(1,(gunmax>>2))
					)
				)||(
					awp==HDMW_HUNTER
					&&gunloaded<random(1,gunmax>>2)
				)||(
					awp==HDMW_ROCKET
					&&gunloaded<random(1,gunmax)
				)||(
					wep<0
					&&pistolloaded<15
				)
			)
			&&(
				//safe to reload
				!target
				||target.bcorpse
				||(hdplayerpawn(target)&&hdplayerpawn(target).incapacitated)
				||(!target.instatesequence(target.curstate,target.resolvestate("falldown")))
				||!CheckTargetInSight()
			)
		);
	}
	bool LeaveToReload(double dist){
		return
			(
				//everything is dry
				(
					gunloaded<1
					&&pistolloaded<1
				)
				&&dist>256
			)
			||(
				//pistol out
				wep<0
				&&pistolloaded<1
				&&dist>256
			)
			||(
				//can maybe top off
				(
					(
						gunloaded<gunmax
						&&wep!=HDMW_ZM66
					)
					||pistolloaded<15
				)
				&&!CheckTargetInSight()
				&&!random(0,3)
			)
		;
	}
	override void A_HDChase(
		statelabel meleestate,
		statelabel missilestate,
		int flags,
		double speedmult
	){
		speed=max(0.1,16-lastinginjury*frandom(0.5,1.));
		if(lastinginjury>0&&!random(0,50+lastinginjury))lastinginjury--;

		//ready pistol if out of ammo
		//DO NOT switch if already reloading!
		if(meleestate!=NULL){
			if(gunloaded>0)wep=abs(wep);
			else wep=-abs(wep);
		}

		if(!threat){
			double dist=2048;
			if(target&&checksight(target))dist=distance3d(target);
			if(
				meleestate!=NULL  //can't melee because already busy reloading
				&&ReloadNow(dist)
			){
				setstatelabel("reload");
				return;
			}
			if(LeaveToReload(dist)){
				missilestate=null;
				flags|=CHF_FLEE;
			}
		}
		if(wep==HDMW_ROCKET)meleethreshold=-800;
		else meleethreshold=0;
		super.A_HDChase(meleestate,missilestate,flags,speedmult);
	}
	override bool CanDoMissile(
		bool targsight,
		double targdist,
		out statelabel missilestate
	){
		if(abs(wep)==HDMW_ROCKET){
			if(targdist>800)wep=HDMW_ROCKET;
			else wep=-HDMW_ROCKET;
		}
		return
			(
				(wep<=0&&pistolloaded>0)
				||(wep<=4&&gunloaded>0)
			)
			&&super.CanDoMissile(targsight,targdist,missilestate)
		;
	}

	//a better refire
	bool A_CheckKeepShooting(statelabel shootstate){
		vector3 lastlasttargetpos=lasttargetpos;
		bool cts=false;
		bool ks=
			shootstate!=null
			&&(
				(wep>0&&gunloaded>0)
				||(pistolloaded>0&&shootstate=="shootpistol")
			)
			&&!!target
			&&(
				!(cts=CheckTargetInSight())
				||target.health>0
			)
		;
		if(ks){
			if(
				cts
				||(lasttargetpos-lastlasttargetpos).length()<target.radius*frandom(1,4)
			)setstatelabel("missile");
			else setstatelabel(shootstate);
		}else setstatelabel("see");
		return ks;
	}





	int messagetimer;
	states{
	spawn:
		PLAY A 0{sprite=givensprite;}
	idle:
		#### A 0 A_JumpIf(bambush,"spawnstill");
		#### ABCD 6 A_HDWander(CHF_LOOK);
	spawn2:
		#### A 0 A_Jump(80,"idle");
		#### A 0{angle+=DecideOnHandedness(-frandom(30,50));}
		#### EEEE 3 A_HDLook();
		#### A 0{angle+=DecideOnHandedness(-frandom(30,50));}
		#### EEEE 3 A_HDLook();
		loop;
	spawnstill:
		#### E 10 A_HDLook();
		loop;
	see:
		#### AABBCCDD 3 A_HDChase(speedmult:0.6);
		#### E 0 A_JumpIf(targetinsight,"see");
	roam:
		#### AABBCCDD 4 A_HDChase(flags:CHF_LOOK,speedmult:0.3);
		#### E 0 A_Jump(128,"roam");
		---- A 0 setstatelabel("roam2");
	roam2:
		#### A 0 A_JumpIf(threat,"see");
		#### A 0{
			angle+=DecideOnHandedness(-frandom(30,50));
			A_HDLook();
		}
		#### EEEE 2 A_Watch();
		#### A 0 A_JumpIf(threat,"see");
		#### A 0{
			angle+=DecideOnHandedness(-frandom(30,50));
			A_HDLook();
		}
		#### EEEE 2 A_Watch();
		#### A 0 A_Jump(90,"roam2");
		#### E 0 A_JumpIf(targetinsight,"see");
		#### E 0 setstatelabel("roam");

	missile:
		#### ABCD 3 A_TurnToAim(40,shootstate:"aiming");
		loop;
	aiming:
		#### E 1 A_StartAim(rate:0.8,mintics:random(0,timesdied),dontlead:randompick(0,0,0,1));
		//fallthrough to shoot
	shoot:
		#### E 4{
			if(!target||(checksight(target)&&target.health<1)){
				target=null;
				setstatelabel("noshot");
				return;
			}

			double dist=lasttargetdist;
			if(
				!hdmobai.tryshoot(self,
					range:1024,
					pradius:min(target.radius*0.6,4),
					pheight:min(target.height*0.6,4)
				)
			){
				return;
			}
			if(lastinginjury>0){
				double lic=min(lastinginjury,10);
				angle+=frandom(-0.4,0.4)*lic;
				pitch+=frandom(-0.5,0.2)*lic;
			}

			//grenade
			if(
				dist<HDCONST_ONEMETRE*144.
				&&dist>HDCONST_ONEMETRE*7.
				&&(
					(wep==HDMW_ROCKET&&gunloaded>0)
					||(
						glloaded
						&&(
							wep==HDMW_ZM66
							||wep==HDMW_SMG
						)
						&&!random(0,31)
					)
				)
			){
				setstatelabel("shootgl");
				return;
			}

			if(gunloaded>0){
				if(wep==HDMW_SMG)setstatelabel("shootsmg");
				else if(wep==HDMW_HUNTER)setstatelabel("shootsg");
				else if(wep==HDMW_ZM66)setstatelabel("shootzm66");
				else if(wep==HDMW_ROCKET)setstatelabel("shootrl");
				else if(pistolloaded>0)setstatelabel("shootpistol");
			}else if(pistolloaded>0)setstatelabel("shootpistol");
		}
		---- A 0 setstatelabel("see");


	shootzm66:
		#### E 2;
		#### E 1{
			if(jammed){
				setstatelabel("unjam");
				return;
			}
			class<actor> mn="HDB_426";
			A_LeadTarget(lasttargetdist/getdefaultbytype(mn).speed,randompick(0,0,0,1));
			hdmobai.DropAdjust(self,mn);
		}
	pullzm66:
		#### E 0{gunspent=min(gunloaded,randompick(1,1,1,1,1,3));}
	firezm66:
		#### F 0 A_JumpIf(gunloaded<1,"ohforfuckssake");
		#### FFF 1 bright light("SHOT"){
			if(gunloaded<1||gunspent<1){
				setstatelabel("firezm66end");
				return;
			}
			gunloaded--;gunspent--;
			A_StartSound("weapons/rifle",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_426");
			if(!random(0,1999-gunspent)){
				jammed=true;
				setstatelabel("unjam");
			}
		}
	firezm66end:
		#### E 2 A_ShoutAlert(1.,SAF_SILENT);
		#### E 0 A_CheckKeepShooting("pullzm66");
		goto see;


	shootsmg:
		#### E 1;
		#### E 1{
			class<actor> mn="HDB_9";
			A_LeadTarget(lasttargetdist/getdefaultbytype(mn).speed,randompick(0,0,0,1));
			hdmobai.DropAdjust(self,mn);
		}
	firesmg:
		#### F 0 A_JumpIf(gunloaded<1,"ohforfuckssake");
		#### F 1 bright light("SHOT"){
			gunloaded--;
			A_StartSound("weapons/smg",CHAN_WEAPON,volume:0.7);
			HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
			A_ShoutAlert(0.125,SAF_SILENT);
		}
		#### E 2 A_EjectSMGCasing();
		#### E 0 A_JumpIf(
			gunloaded>0
			&&random(0,2)
			&&checksight(target)
		,"firesmg");
	firesmgend:
		#### E 2 A_ShoutAlert(1.,SAF_SILENT);
		#### E 0 A_CheckKeepShooting("firesmg");
		goto see;


	shootsg:
		#### E 2;
		#### E 1{
			class<actor> mn="HDB_00";
			A_LeadTarget(lasttargetdist/getdefaultbytype(mn).speed,randompick(0,0,0,1));
			hdmobai.DropAdjust(self,mn);

			//aim for head or legs
			if(
				target
				&&target.countinv("HDArmourWorn")
				&&abs(pitch)<45
				&&!random(0,2)
			){
				double ddd=max(distance2d(target),radius);
				double ppp=frandom(10,25)*100/ddd;
				pitch+=random(0,2)?ppp:-ppp;
			}
		}
	firesg:
		#### F 0 A_JumpIf(gunloaded<1,"ohforfuckssake");
		#### F 1 bright light("SHOT"){
			gunloaded--;
			A_ShoutAlert(1.,SAF_SILENT);
			Hunter.Fire(self);
		}
	firesgend:
		#### E 1{
			if(random(0,4)){
				gunspent=0;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}else gunspent=1;
		}
		#### E 2{
			if(gunspent){
				gunspent=0;
				A_StartSound("weapons/huntrack",8);
				A_SetTics(random(4,6));
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
		}
		#### E random(3,6) A_HDChase(null,null,speedmult:0.7);
		#### E 0 A_CheckKeepShooting("firesg");
		goto see;

	shootrl:
		#### E 2;
		#### E 1{
			if(!A_CheckBlast(target)){
				wep=-abs(wep);
				if(pistolloaded<1)setstatelabel("reloadmag");
				else setstatelabel("shootpistol");
			}
		}
		#### E 1{
			class<actor> mn="RocketGrenade";
			A_LeadTarget(lasttargetdist/getdefaultbytype(mn).speed,randompick(0,0,0,1));
//			hdmobai.DropAdjust(self,mn,speedmult:6.4);  //it simply never matters
		}
		#### F 0 A_JumpIf(gunloaded<1,"ohforfuckssake");
		#### F 2 bright light("SHOT"){
			if(wep==HDMW_ROCKET)gunloaded--;else glloaded=false;
			A_StartSound("weapons/rockignite",CHAN_WEAPON);
			A_StartSound("weapons/bronto",CHAN_WEAPON,CHANF_OVERLAP);
			A_OpShot("RocketGrenade",userocket:true);
			A_ShoutAlert(1.,SAF_SILENT);
		}
		#### E 5{
			A_Recoil(-4);
			A_StartSound("weapons/rocklaunch",CHAN_WEAPON,CHANF_OVERLAP,0.6);
		}
		#### E 0 A_StartSound("weapons/huntrack",8);
		---- A 0 setstatelabel("see");


	shootgl:
		#### E 1{
			if(
				!A_CheckBlast(target)
				&&wep==HDMW_ROCKET
			){
				wep=-abs(wep);
				if(pistolloaded<1)setstatelabel("reloadmag");
				else setstatelabel("shootpistol");
			}
		}
		#### E 2{
			class<actor> mn="RocketGrenade";
			A_LeadTarget(lasttargetdist/getdefaultbytype(mn).speed,randompick(0,0,0,1));

			//everything else assumes you're aiming for centre, try ground instead
			double aaa=angle;
			A_FaceLastTargetPos(10,targetheight:1.);
			angle=aaa;

			hdmobai.DropAdjust(self,mn,lasttargetdist);
		}
		#### F 0 A_JumpIf(!glloaded,"ohforfuckssake");
		#### F 1 bright{
			if(wep==HDMW_ROCKET)gunloaded--;
			else glloaded=false;

			A_StartSound("weapons/grenadeshot",CHAN_WEAPON);
			A_OpShot("RocketGrenade");
		}
		#### E 4;
		goto see;


	shootpistol:
		#### E 1;
		#### E 1{
			class<actor> mn="HDB_9";
			A_LeadTarget(lasttargetdist/getdefaultbytype(mn).speed,randompick(0,0,0,1));
			hdmobai.DropAdjust(self,mn);
		}
	firepistol:
		#### F 0 A_JumpIf(pistolloaded<1,"ohforfuckssake");
		#### F 1 bright light("SHOT"){
			pistolloaded--;
			A_StartSound("weapons/pistol",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_9",spread:2.,speedfactor:frandom(0.97,1.03));
			A_ShoutAlert(0.25,SAF_SILENT);
		}
		#### E random(1,4)A_EjectPistolCasing();
		#### E random(1,4);
		#### E 0 A_CheckKeepShooting("firepistol");


	noshot:
		#### E 6;
		---- A 0{
			double aaa=angle+decideonhandedness(frandom(5,10));
			threat=spawn("idledummy",(pos.xy+(cos(aaa),sin(aaa)),pos.z));
			threat.stamina=12;
		}
		---- A 0 setstatelabel("see");


	unjam:
		#### E 10;
		#### E 0{
			if(gunloaded>=0){
				let ooo=HDMagAmmo(spawn("HD4mMag",pos+(0,0,40),ALLOW_REPLACE));
				ooo.vel+=vel;
				ooo.mags.clear();
				ooo.mags.push(gunloaded);
				ooo.amount=1;
				gunloaded=-1;
			}else if(!random(0,3)){
				jammed=false;
				A_StartSound("weapons/rifleclick",8);
				if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,height-12,4,frandom(-2,2),frandom(2,4));
				A_SpawnItemEx("BulletPuffBig",12,0,42,1,0,1);
				setstatelabel("reload");
			}
		}
		#### ABCD 3 A_HDChase("melee",null);
		loop;


	reload:
		#### E 8{
			if(
				pistolloaded<1
				&&(
					gunloaded>0
					||(
						target
						&&(
							checksight(target)
							||distance3d(target)<256
						)
					)
				)
			){
				wep=-abs(wep);
				setstatelabel("reloadmag");
				return;
			}

			wep=abs(wep);
			if(
				wep==HDMW_ZM66
				||wep==HDMW_SMG
			){
				if(gunloaded<1)setstatelabel("reloadmag");
				else if(!glloaded)setstatelabel("reloadgl");
			}
			else if(wep==HDMW_HUNTER)setstatelabel("reloadsg");
			else if(wep==HDMW_ROCKET)setstatelabel("reloadrl");
		}
		---- A 0 setstatelabel("see");


	reloadsg:
		#### A 0 A_StartSound("weapons/huntopen",8);
		#### AB 3 A_HDChase(null,null,CHF_FLEE);
	reloadsgloop:
		#### A 0 A_StartSound("weapons/pocket",9);
		#### CDAB 3 A_HDChase(null,null,CHF_FLEE);
		#### BBC 3{
			A_HDChase(null,null,CHF_FLEE,0.5);
			if(gunloaded<gunmax){
				gunloaded++;
				A_StartSound("weapons/sshotl",8);
			}
		}
		#### A 0 A_JumpIf(
			gunloaded<gunmax
			||(
				gunloaded>0
				&&CheckTargetInSight()
			)
		,"see");
		---- A 0 setstatelabel("reloadsgloop");

	reloadrl:
		#### A 0 A_StartSound("weapons/rifleclick2",8);
		#### AB 3 A_HDChase(null,null,CHF_FLEE);
	reloadrlloop:
		#### A 0 A_StartSound("weapons/pocket",9);
		#### CDAB 3 A_HDChase(null,null,CHF_FLEE);
		#### C 4{
			if(!random(0,3))A_HDChase(null,null,CHF_FLEE);
			if(gunloaded<gunmax){
				gunloaded++;
				A_StartSound("weapons/rockreload",8,CHANF_OVERLAP);
			}
		}
		#### A 0 A_JumpIf(gunloaded<gunmax,"reloadsgloop");
		---- A 0 setstatelabel("see");

	reloadmag:
		#### A 1 A_StartSound("weapons/rifleclick",8,CHANF_OVERLAP);
		#### AB 3 A_HDChase(null,null,CHF_FLEE);
		#### C 2{
			A_HDChase(null,null,CHF_FLEE);

			//pocket partial mag
			if(
				(
					wep<0
					&&pistolloaded>0
				)||(
					wep==HDMW_SMG
					&&gunloaded>0
				)
			){
				A_StartSound("weapons/pocket",8,CHANF_OVERLAP);
				tics+=10;
				gunloaded=-1;
				return;
			}

			name oldthing="";
			if(wep==HDMW_SMG)oldthing="HD9mMag30";
			else if(wep==HDMW_ZM66){
				if(jammed){
					setstatelabel("unjam");
					return;
				}
				oldthing="HD4mMag";
			}
			else oldthing="HD9mMag15";

			if(
				gunloaded>=0
				&&oldthing!=""
			){
				HDMagAmmo.SpawnMag(self,oldthing,max(0,gunloaded));
				A_StartSound("weapons/rifleclick",8);
				A_StartSound("weapons/rifleunload",8,CHANF_OVERLAP);
			}
			gunloaded=-1;
		}
		#### DAB 3 A_HDChase(null,null,CHF_FLEE);
		#### C 2 A_StartSound("weapons/rifleload",8);
		#### D 3{
			A_StartSound("weapons/rifleclick",8,CHANF_OVERLAP);
			A_HDChase(null,null);

			if(wep<0)pistolloaded=15;
			else gunloaded=gunmax;
		}
		---- A 0 setstatelabel("see");

	reloadgl:
		#### A 0 A_StartSound("weapons/grenopen",8);
		#### ABCD 3 A_HDChase(null,null,CHF_FLEE);
		#### AB 2 A_StartSound("weapons/rockreload",8);
		#### C 3{
			A_StartSound("weapons/grenopen",CHAN_WEAPON,CHANF_OVERLAP);
			A_HDChase("melee",null);
			glloaded=1;
		}
		#### D 4;
		---- A 0 setstatelabel("see");

	pain:
		#### G 3;
		#### G 3 A_HDMPain();
		#### G 0 A_Jump(100,"see");
		#### AB 2 A_FaceTarget(50,50);
		#### CD 3 A_ChangeVelocity(
			frandom(-1,1),
			frandom(1,max(0,5-lastinginjury*0.1))*randompick(-1,1),
			0,CVF_RELATIVE
		);
		#### G 0 A_CPosRefire();
		#### E 0 A_Jump(256,"missile");

	death.bleedout:
		#### HI 5;
		---- A 0 setstatelabel("deathpostscream");
	death:
		---- A 0 A_DeathZombieZombieDeath();
		#### H 5;
		#### I 5 A_HDMScream();
	deathpostscream:
		#### JK 5;
		---- A 0 setstatelabel("dead");

	dead:
		#### K 3 canraise A_JumpIf(abs(vel.z)<2.,1);
		loop;
		#### LMN 5 canraise A_JumpIf(abs(vel.z)>=2.,"dead");
		wait;
	raise:
		#### A 0{
			settag(RandomName());
			lastinginjury=random(0,(lastinginjury>>3));
		}
		#### MLK 7 A_SpawnItemEx("MegaBloodSplatter",0,0,4,
			vel.x,vel.y,vel.z,0,
			SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		#### JHE 4;
		#### H 0{
			scale.x=abs(scale.x);
			if(!random(0,15+timesdied))return;
			else if(!random(0,10-timesdied))damagemobj(
				null,null,health+(gibhealth)<<2,
				"raisebotch",
				DMG_NO_PAIN|DMG_FORCED|DMG_NO_FACTOR|DMG_NO_ARMOR|DMG_THRUSTLESS
			);
			else{
				speed=max(1,speed-random(0,1));
				damagemobj(
					self,self,
					min(random(0,3*timesdied),health-1),
					"balefire",
					DMG_NO_PAIN|DMG_FORCED|DMG_NO_FACTOR|DMG_NO_ARMOR|DMG_THRUSTLESS
				);
				seesound="freshgrunt/sight";
				painsound="freshgrunt/pain";
				deathsound="freshgrunt/death";
				A_StartSound(seesound,CHAN_VOICE);
			}
		}
		#### A 0 A_Jump(256,"see");

	xdeath:
		---- A 0 A_DeathZombieZombieDeath();
		#### O 5;
		#### P 5{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
			A_XScream();
		}
		#### Q 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
		#### Q 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
		#### RSTUV 5;
	xdead:
		#### W -1 canraise;
		stop;
	death.raisebotch:
	xxxdeath:
		---- A 0 A_DeathZombieZombieDeath();
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		goto xdead;
	ungib:
		#### W 0 A_JumpIf((random(1,12)-timesdied)<5,"RaiseZombie");
		#### WW 8;
		#### VUT 7;
		#### SRQ 5;
		#### POH 4;
		#### A 0 A_Jump(256,"see");
	raisezombie:
		#### U 4{
			if(health>0){
				damagemobj(null,null,health,"maxhpdrain",DMG_FORCED|DMG_NO_ARMOR);
				setstatelabel("raisezombie");
			}
		}
		#### U 8;
		#### T 4;
		#### T 2 A_StartSound("weapons/bigcrack",16);
		#### T 0{
			if(bplayingid)sprite=getspriteindex("POSS");
			else{
				sprite=getspriteindex("SPOS");
				A_SetTranslation("FreedoomGreycoat");
			}
		}
		#### S 2 A_StartSound("misc/wallchunks",17);
		#### AAAAA 0 A_SpawnItemEx("HugeWallChunk",0,0,40,random(4,6),0,random(-2,7),random(1,360));
		#### SRQ 6;
		#### PONMH 4;
		#### IJKL 4;
		#### M 0 spawn("DeadZombieStormtrooper",pos,ALLOW_REPLACE);
		stop;
		POSS SRQPONMHIJKL 0;
		SPOS SRQPONMHIJKL 0;
		stop;
	}
}

class Rifleman:HDOperator{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Operator (Rifle)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_ZM66;
}}
class BlackRifleman:Rifleman{default{hdoperator.user_colour 3;}}
class BrownRifleman:Rifleman{default{hdoperator.user_colour 2;}}
class WhiteRifleman:Rifleman{default{hdoperator.user_colour 1;}}
class RifleFistman:Rifleman replaces MarineFist{}
class RifleChaingunman:Rifleman replaces MarineChaingun{}

class Enforcer:HDOperator{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Operator (Shotgun)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_HUNTER;
}}
class BlackEnforcer:Enforcer{default{hdoperator.user_colour 3;}}
class BrownEnforcer:Enforcer{default{hdoperator.user_colour 2;}}
class WhiteEnforcer:Enforcer{default{hdoperator.user_colour 1;}}
class EnforcerShot:Enforcer replaces MarineShotgun {}
class EnforcerSuperShot:Enforcer replaces MarineSSG {}
class EnforcerNoShot:Enforcer replaces MarineBerserk {}

class Infiltrator:HDOperator{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Operator (SMG)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_SMG;
}}
class BlackInfiltrator:Infiltrator{default{hdoperator.user_colour 3;}}
class BrownInfiltrator:Infiltrator{default{hdoperator.user_colour 2;}}
class WhiteInfiltrator:Infiltrator{default{hdoperator.user_colour 1;}}
class InfiltratorPistol:Infiltrator replaces MarinePistol{}
class InfiltratorChainsaw:Infiltrator replaces MarineChainsaw{}

class Rocketeer:HDOperator{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Operator (Rocket)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_ROCKET;
}}
class BlackRocketeer:Rocketeer{default{hdoperator.user_colour 3;}}
class BrownRocketeer:Rocketeer{default{hdoperator.user_colour 2;}}
class WhiteRocketeer:Rocketeer{default{hdoperator.user_colour 1;}}
class RRocketeer:Rocketeer replaces MarineRocket{}
class BFuglyteer:Rocketeer replaces MarineBFG{}
class Plasmateer:Rocketeer replaces MarinePlasma{}
class Railgunteer:Rocketeer replaces MarineRailgun{}


class HDGoon:HDOperator{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Goon"
		//$Sprite "PLAYA1"
		-friendly
}}
class BlackGoon:HDGoon{default{hdoperator.user_colour 3;}}
class BrownGoon:HDGoon{default{hdoperator.user_colour 2;}}
class WhiteGoon:HDGoon{default{hdoperator.user_colour 1;}}

class RifleGoon:HDGoon{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Goon (Rifle)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_ZM66;
}}
class BlackRifleGoon:RifleGoon{default{hdoperator.user_colour 3;}}
class BrownRifleGoon:RifleGoon{default{hdoperator.user_colour 2;}}
class WhiteRifleGoon:RifleGoon{default{hdoperator.user_colour 1;}}

class ShotGoon:HDGoon{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Goon (Shotgun)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_HUNTER;
}}
class BlackShotGoon:ShotGoon{default{hdoperator.user_colour 3;}}
class BrownShotGoon:ShotGoon{default{hdoperator.user_colour 2;}}
class WhiteShotGoon:ShotGoon{default{hdoperator.user_colour 1;}}

class SMGGoon:HDGoon{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Goon (SMG)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_SMG;
}}
class BlackSMGGoon:SMGGoon{default{hdoperator.user_colour 3;}}
class BrownSMGGoon:SMGGoon{default{hdoperator.user_colour 2;}}
class WhiteSMGGoon:SMGGoon{default{hdoperator.user_colour 1;}}

class RocketGoon:HDGoon{
	default{
		//$Category "Monsters/Hideous Destructor/Operators"
		//$Title "Goon (Rocket)"
		//$Sprite "PLAYA1"
		hdoperator.user_weapon HDMW_ROCKET;
}}
class BlackRocketGoon:RocketGoon{default{hdoperator.user_colour 3;}}
class BrownRocketGoon:RocketGoon{default{hdoperator.user_colour 2;}}
class WhiteRocketGoon:RocketGoon{default{hdoperator.user_colour 1;}}



// ------------------------------------------------------------
// Operator corpse
// ------------------------------------------------------------
class UndeadRifleman:HDOperator{
	default{
		//$Category "Monsters/Hideous Destructor/"
		//$Title "Undead Operator"
		//$Sprite "PLAYA1"
		-friendly
		-activatepcross
	}
	override void postbeginplay(){
		super.postbeginplay();
		givearmour(0.6,0.12,0.1);
		timesdied+=random(1,3);
		bhasdropped=true;
		speed=max(1,speed-random(0,2));
		damagemobj(
			self,self,
			min(random(0,3*timesdied),health-1),
			"balefire",
			DMG_NO_PAIN|DMG_NO_FACTOR|DMG_THRUSTLESS
		);
		seesound="freshgrunt/sight";
		painsound="freshgrunt/pain";
		deathsound="freshgrunt/death";
	}
}
class DeadRifleman:HDOperator replaces DeadMarine{
	override void postbeginplay(){
		super.postbeginplay();
		A_TakeInventory("HDArmourWorn");
		bhasdropped=true;
		damagemobj(null,null,health+1,"spawndead",DMG_FORCED|DMG_NO_PAIN);
		setstatelabel("spawndead");
	}
	states{
	spawndead:
		---- A 0{
			givearmour(0.6,0.12,0.1);
			A_SetShootable();
			setstatelabel("dead");
		}stop;
	}
}
class ReallyDeadRifleman:DeadRifleman replaces GibbedMarine{
	states{
	spawndead:
		---- A 1{
			bodydamage=health+gibhealth+1;
			bgibbed=true;
		}
		---- A 0 setstatelabel("xdead");
	}
}
class DeadRiflemanCrouched:DeadRifleman{
	states{
	spawndead:
		PLYC A 0;
		goto super::spawndead;
	raise:
		PLAY A 0;
		goto super::raise;
	}
}
class ReallyDeadRiflemanCrouched:ReallyDeadRifleman replaces GibbedMarineExtra{
	states{
	spawndead:
		PLYC A 0;
		goto super::spawndead;
	raise:
		PLAY A 0;
		goto super::raise;
	}
}




// ------------------------------------------------------------
// You have no authority to order them around, but...
// ------------------------------------------------------------
extend class HDOperator{
	static void PlayerCheckIn(actor caller){
		if(!caller||!caller.player||caller.health<1)return;
		string msg=string.format(
			"Operator reporting in at [%i,%i]."
			,caller.pos.x,caller.pos.y
		);
		HDTeamSay(caller,msg,HDTS_INCLUDESELF);
	}
	enum HDTeamSayFlags{
		HDTS_INCLUDESELF=1,
		HDTS_DONTFORMAT=2,
	}
	static void HDTeamSay(
		actor caller,
		string msg,
		int flags=0
	){
		if(caller.bcorpse||caller.health<1)return;
		if(!(flags&HDTS_DONTFORMAT))msg="\cd"..caller.gettag()..": "..msg;
		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&(
					flags&HDTS_INCLUDESELF
					||!caller.player
					||players[i]!=caller.player
				)
				&&!!players[i].mo
				&&(
					caller.isfriend(players[i].mo)
					||caller.isteammate(players[i].mo)
				)
			){
				actor pmo=players[i].mo;
				pmo.A_StartSound("misc/chat",420,CHANF_UI|CHANF_NOPAUSE|CHANF_LOCAL);
				pmo.A_Log(msg,true);
			}
		}
	}
	static void CallCheckIn(actor caller){
		if(!caller.player)return;
		HDTeamSay(caller,"Report in, team.",HDTS_INCLUDESELF);
		//all players check in
		for(int i=0;i<MAXPLAYERS;i++){
			PlayerCheckIn(players[i].mo);
		}
		//all HDOperators check in
		HDOperator nmm;
		thinkeriterator nmit=thinkeriterator.create("HDOperator",STAT_DEFAULT);
		while(nmm=HDOperator(nmit.Next(exact:false))){
			if(
				nmm.isfriend(caller)
				||nmm.isteammate(caller)
			)nmm.HDMCheckIn();
		}
	}
	virtual void HDMCheckIn(){
		if(
			health<1
			||(!bfriendly&&random(0,15))
		)return;

		int x;int y;
		if(!bfriendly){
			settag("Anonymous");
			x=random(-32700,32700);
			y=random(-32700,32700);
		}

		string msg=string.format(
			"Operator reporting in at [%i,%i].",
			pos.x,pos.y
		);

		bool anyfriendly=false;
		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&players[i].mo
				&&(
					isfriend(players[i].mo)
					||isteammate(players[i].mo)
				)
			){
				anyfriendly=true;
				if(target&&target.health>0)msg=msg..
					" I need some backup."
				;
				actor pmo=players[i].mo;
				if(
					distance3dsquared(pmo)<(512.*512.)
					||checksight(pmo)
				)msg=msg..
					" I'm right here, watch your fire!"
				;
			}
		}
		if(anyfriendly)HDTeamSay(self,msg,HDTS_INCLUDESELF);
	}
	
	void LookMessage(actor looker){
		if(messagetimer>0)return;
		messagetimer=TICRATE*3;
		if(getage()<10)return;
		string msg;
		bool incombat=
			target
			&&target.health>0
		;
		string barkset=Wads.ReadLump(Wads.CheckNumForName("opbarks",0));
		barkset.Replace("\r","");
		if(incombat)barkset=barkset.mid(barkset.indexof("\n---")+5);
		else barkset=barkset.left(barkset.indexof("\n---"));
		array<string>barks;barks.clear();
		barkset.split(barks,"\n");
		int blength=barks.size()-1;

		if(blength<0)msg="a";
		else msg=barks[abs(random(0,blength)-random(0,blength))];

		msg=HDMath.BuildVariableString(msg);

		msg.replace("$YOU",looker.gettag());

		HDTeamSay(self,msg);
	}
}


// ------------------------------------------------------------
// A replacement.
// ------------------------------------------------------------
class BotBot:HDOperator{
	default{
		+noblockmonst
		+nofear
		species "Player";
		obituary "$OB_BOT";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!bfriendly)return super.damagemobj(inflictor,source,damage,mod,flags,angle);

		//because spawn telefrags are bullshit
		if(
			damage==TELEFRAG_DAMAGE
			&&source
			&&(
				(
					source.player
					&&source.player.mo==source
				)
				||botbot(source)
			)&&(
				level.time<TICRATE
				||source.getage()<10
			)
		){
			return -1;
		}

		//abort if zero team damage, otherwise save factor for wounds and burns
		if(
			source
			&&source!=self
			&&(
				isteammate(source)
				||(
					!deathmatch&&
					(source.player||botbot(source))
				)
			)
		){
			if(!teamdamage)return 0;
			else damage=int(damage*teamdamage);
		}

		lastmod=mod;
		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	name lastmod;
	override void Die(actor source,actor inflictor,int dmgflags){
		super.Die(source,inflictor,dmgflags);
		if(masterplayer>=0){
			actor rpp=players[masterplayer].mo;
			if(rpp){
				rpp.A_SetShootable();
				rpp.damagemobj(inflictor,source,rpp.health,lastmod,dmgflags|DMG_FORCED);
				rpp.A_UnsetShootable();
			}
		}
	}
	int warptimer;
	int unseen;
	bool seen;
	vector3 oldppos;
	override void tick(){
		super.tick();
		if(
			masterplayer<1
			||health<1
			||isfrozen()
		)return;
		actor rpp=players[masterplayer].mo;
		if(rpp){
			rpp.setorigin((
				pos.xy+angletovector(angle,1),
				pos.z+height-8
			),true);
			rpp.A_SetAngle(angle,SPF_INTERPOLATE);
			rpp.A_SetPitch(pitch,SPF_INTERPOLATE);
		}

		if(!bfriendly||timesdied>0||target){
			unseen=0;
			return;
		}

		warptimer++;
		if(!(warptimer%35)){
			seen=false;
			warptimer=0;
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					playeringame[i]&&!players[i].bot&&players[i].mo
					&&checksight(players[i].mo)
				){
					seen=true;
					unseen=0;
				}
			}
			if(!seen)unseen++;
			if(unseen==HDMBC_WARPLIMIT){
				gunloaded=gunmax;
				glloaded=true;
				pistolloaded=15;
				for(int i=0;i<MAXPLAYERS;i++){
					if(
						playeringame[i]&&!players[i].bot&&players[i].mo
					){
						oldppos=players[i].mo.pos;
						break;
					}
				}
			}else if(unseen>HDMBC_WARPLIMIT){
				vector3 posbak=pos;
				setorigin(oldppos,false);
				for(int i=0;i<MAXPLAYERS;i++){
					if(
						playeringame[i]&&!players[i].bot&&players[i].mo
						&&(absangle(
							players[i].mo.angle,
							players[i].mo.angleto(self)
						)<100)
					){
						seen=true;
						unseen--;
					}
				}
				if(unseen>HDMBC_WARPLIMIT+3){
					unseen=0;
					seen=true;
					warptimer=0;
					A_StartSound(seesound,CHAN_VOICE);
					spawn("HDSmoke",pos,ALLOW_REPLACE);
				}else{
					setorigin(posbak,false);
				}
			}
		}
	}
	override void A_HDMScream(){
		A_Vocalize(deathsound);
		master=null;masterplayer=-1;
		if(hd_disintegrator){
			A_SpawnItemEx("Telefog",0,0,0,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM);
			destroy();
		}
	}
	override void A_HDMPain(){
		A_Vocalize(painsound);
	}
	int masterplayer;
	override void postbeginplay(){
		super.postbeginplay();
		givearmour(1.,0.12,1.);
		if(!master){
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]&&players[i].mo){
					master=players[i].mo;
					break;
				}
			}
		}
		masterplayer=master.playernumber();
		settag(players[masterplayer].getusername());

		SetSightPainDeath(self,players[masterplayer].getgender());

		voicepitch=1.+0.3*sin(masterplayer<<2);
		double vp=2.-voicepitch;
		A_SetSize(default.radius,default.height);
		scale=default.scale;
		resize(vp,vp);
	}

	//nick should be the player's nick
	override string SetNickname(){return gettag();}
	//don't do anything, let the playerpawn do the reporting instead
	override void HDMCheckIn(){}

	states{
	xdead:
		---- A 0{bgibbed=true;}
	dead:
		#### N 1{
			if(bgibbed)frame=22; //W
			let mmm=HDOperator(spawn(bgibbed?"ReallyDeadRifleman":"DeadRifleman",pos));
			mmm.vel=vel;
			mmm.translation=translation;
			mmm.scale=scale;
			mmm.settag(gettag());
			mmm.givensprite=givensprite;
			master=mmm;
		}
		TNT1 A 0{
			let mmm=HDOperator(master);
			if(mmm)mmm.settag(gettag());
		}stop;
	}
}

