// ------------------------------------------------------------
// The player!
// ------------------------------------------------------------
const HDCONST_SPRINTMAXHEARTRATE=20;
const HDCONST_SPRINTFATIGUE=30;
const HDCONST_WALKFATIGUE=40;
const HDCONST_DAMAGEFATIGUE=80;
enum HDPlayerSeeState{
	PLAYER_WALKTICS=10,
	PLAYER_RUNTICS=6,
	PLAYER_RUNTICS_HINDERED=8,
	PLAYER_SPRINTTICS=5,
}
class HDPlayerPawn:PlayerPawn{
	vector3 lastvel;double lastheight;
	bool teleported;

	int oldinput;
	double oldfm;double oldsm;

	HDPlayerCorpse playercorpse;
	actor scopecamera;

	hdweapon lastweapon;
	bool barehanded;
	bool gunbraced;

	double overloaded;
	double maxspeed;

	bool mustwalk;bool cansprint;
	int runwalksprint;

	double feetangle;
	vector3 gunpos;
	vector3 gunorigin;
	double gunpitch,gunangle;

	double heightmult;
	double foreheadheight;

	int stunned;
	int fatigue;
	int nocrosshair;
	double recoilfov;

	bool hasgrabbed;
	int jumptimer;
	bool isFocussing;

	bool flip;

	string wephelptext;

	double bobcounter;
	int bobtics;
	vector2 wepbob;
	vector2 crossbob,lastcrossbob;

	string classloadout;
	property loadout:classloadout;

	default{
		gravity HDCONST_GRAVITY;

		+interpolateangles
		telefogsourcetype "";
		telefogdesttype "";

		-playerpawn.nothrustwheninvul
		-pickup
		+forceybillboard //zoom actor will fuck up otherwise

		+nomenu
		+noskin

		height HDCONST_PLAYERHEIGHT;
		radius 12;
		mass 150;
		gibhealth 180;
		deathheight HDCONST_PLAYERHEIGHT*0.44;

		player.viewheight HDCONST_PLAYERHEIGHT;
		player.attackzoffset HDCONST_PLAYERHEIGHT*0.389;
		player.damagescreencolor "12 06 04",0;
		player.jumpz 0;
		player.colorrange 112,127;
		maxstepheight 24;
		player.gruntspeed 9999999999.0;
		player.displayname "Operator";
		player.crouchsprite "PLYC";

		hdplayerpawn.loadout "";
		hdplayerpawn.maxpocketspace HDCONST_MAXPOCKETSPACE;
		player.startitem "CustomLoadoutGiver";
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			!player
			||other.floorz==other.pos.z
			||!hdfist(player.readyweapon)
			||hdfist(player.readyweapon).grabbed!=other
		);
	}
	override void PostBeginPlay(){
		super.PostBeginPlay();
		cachecvars();
		SetPostBeginPlayStuff();
		hdlivescounter.updatefragcounts(hdlivescounter.get());
		showgametip();
	}
	void SetPostBeginPlayStuff(){
		standsprite=sprite;
		if(player)ApplyUserSkin(true);

		lastvel=vel;
		lastheight=height;
		lastangle=angle;
		lastpitch=pitch;
		beatcap=35;beatmax=35;
		feetangle=angle;

		bobtics=(360/(PLAYER_WALKTICS<<2));

		if(!scopecamera)scopecamera=spawn("ScopeCamera",pos+(0,0,height-6),ALLOW_REPLACE);
		scopecamera.target=self;

		if(
			player
			&&player.bot
			&&hd_nobots
			&&!HDBotSpectator(self)
			&&!hdlivescounter.wiped(playernumber())
		)ReplaceBot();
		A_TakeInventory("NullWeapon");

		A_SetTeleFog("TeleportFog","TeleportFog");
	}
	void A_CheckGunBraced(){
		if(incapacitated||HDWeapon.IsBusy(self))gunbraced=false;
		else if(
			!barehanded
			&&!gunbraced
			&&floorz==pos.z
			&&!IsMoving.Count(self)
			&&!countinv("HDZerk")
		){
			double zat2=(getzat(16*heightmult)-floorz-height);
			if(zat2<0 && zat2>=-30*heightmult){
				gunbraced=true;
				muzzleclimb1.y-=0.1;
				muzzleclimb2.y+=0.05;
				muzzleclimb3.y+=0.05;
			}else{
				gunbraced=false;
				flinetracedata glt;
				linetrace(
					angle+22,12,pitch,
					offsetz:height-7,
					offsetforward:cos(pitch)*10,
					data:glt
				);
				if(glt.hittype==Trace_HitWall){
					muzzleclimb1.x+=0.1;
					muzzleclimb2.x-=0.05;
					muzzleclimb3.x-=0.05;
					gunbraced=true;
				}else{
					linetrace(
						angle-22,12,pitch,
						offsetz:height-7,
						offsetforward:cos(pitch)*10,
						data:glt
					);
					if(glt.hittype==Trace_HitWall){
						muzzleclimb1.x-=0.1;
						muzzleclimb2.x+=0.05;
						muzzleclimb3.x+=0.05;
						gunbraced=true;
					}
				}
			}
			if(gunbraced)A_StartSound("weapons/guntouch",8,CHANF_OVERLAP,0.3);
		}
	}
	void A_CheckSeeState(){
		if(!player)return;

		if(!frame){
			gunbraced=false;
			UpdateEncumbrance();
			feetangle=angle;

			//random low health stumbling
			if(floorz>=pos.z && !random(1,2)){
				if(health<random(35,45)){
					if(player.crouchfactor<0.7)A_ChangeVelocity(
						random(-4,2),frandom(-3,3),random(-1,0),CVF_RELATIVE
					);
					vel.xy*=frandom(0.7,1.0);
				}else if(health<random(60,65)){
					if(player.crouchfactor<0.7)A_ChangeVelocity(
						random(-2,1),frandom(-1,1),random(-1,0),CVF_RELATIVE
					);
					vel.xy*=frandom(0.9,1.0);
				}
			}

			if(player.readyweapon&&player.readyweapon!=WP_NOCHANGE){
				player.readyweapon.bobspeed=player.readyweapon.default.bobspeed;
				if(stunned||mustwalk||runwalksprint<0){
					player.readyweapon.bobspeed*=0.6;
				}
			}
		}

		if(
			IsFrozen()
			||(
				!player.cmd.forwardmove
				&&!player.cmd.sidemove
				&&abs(vel.x)<2
				&&abs(vel.y)<2
			)
		){
			if(frame==1){
				setstatelabel("spawn");
				return;
			}
			bobtics=4;
		}else if(stunned){
			bobtics=clamp(bobtics+random(-3,3),4,20);
			IsMoving.Give(self,2);
		}else if(
			cansprint
			&&runwalksprint>0
		){
			bobtics=PLAYER_SPRINTTICS;
			if(
				!(frame&1)
				&&bloodpressure<30
			)bloodpressure+=1;
			A_CheckFootStepSound(1.3);
		}else if(
			runwalksprint<0
		){
			bobtics=PLAYER_WALKTICS;
			if(player.crouchfactor>0.7){
				IsMoving.Give(self,-5);
				A_CheckFootStepSound(max(abs(vel.x),abs(vel.y))*0.4);
			}else A_CheckFootStepSound();
		}else{
			if(
				!!hdweapon(player.readyweapon)
				&&hdweapon(player.readyweapon).bhinderlegs
			)bobtics=PLAYER_RUNTICS_HINDERED;
			else bobtics=PLAYER_RUNTICS;
			A_CheckFootStepSound();
		}
		A_SetTics(bobtics);
		bobtics=(360/(bobtics<<((player.crouchfactor<0.7)?3:2)));
	}
	void A_CheckFootStepSound(double mult=1.){
		if(floorz<pos.z)return;
		if(player.crouchfactor<0.7){
			if(frame==3)return;
			mult*=0.3;
		}
		HDHumanoid.FootStepSound(self,mult);

		//checking again because i don't trust "out" in functions
		if(HDMath.CheckDirtTexture(self))mult*=0.5;

		if(frandom(0,20)<mult*mult){
			blockthingsiterator it=blockthingsiterator.create(self,256);
			while(it.next()){
				let itt=hdmobbase(it.thing);
				if(
					!!itt
					&&!itt.bcorpse
					&&itt.target==self
				){
					itt.lasttargetpos=(pos.x+frandom(-64,64),pos.y+frandom(-64,64),floorz);
					break;
				}
			}
			it.destroy();
		}
	}
	states{
	spawn:
		PLAY A 4 nodelay ApplyUserSkin();
	spawn2:
		#### E 5;
		---- A 5{
			IsMoving.Clear(self);
			A_CheckGunBraced();
		}
		---- AAAAA 5 A_CheckGunBraced();
		loop;
	see:
		#### ABCD 4 A_CheckSeeState();
		loop;
	missile:
		#### E 4 UpdateEncumbrance();
		---- A 0 A_Jump(256,"spawn2");
	melee:
		#### F 2 bright light("SHOT"){
			bspawnsoundsource=true;
		}
		---- A 0 A_Jump(256,"missile");
	}
	transient cvar hd_nozoomlean;
	transient cvar hd_aimsensitivity;
	transient cvar hd_bracesensitivity;
	transient cvar hd_noslide;
	transient cvar hd_usefocus;
	transient cvar hd_lasttip;
	transient cvar hd_helptext;
	transient cvar hd_voicepitch;
	transient cvar hd_maglimit;
	transient cvar hd_skin;
	transient cvar hd_give;
	transient cvar hd_monstervoicepitch;
	transient cvar hd_pronouns;
	transient cvar hd_height;
	transient cvar hd_strength;
	transient cvar neverswitchonpickup;
	void cachecvars(){
		playerinfo plr;
		if(player)plr=player;
		else{
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]){
					plr=players[i];
					break;
				}
			}
		}
		hd_nozoomlean=cvar.getcvar("hd_nozoomlean",plr);
		hd_aimsensitivity=cvar.getcvar("hd_aimsensitivity",plr);
		hd_bracesensitivity=cvar.getcvar("hd_bracesensitivity",plr);
		hd_noslide=cvar.getcvar("hd_noslide",plr);
		hd_usefocus=cvar.getcvar("hd_usefocus",plr);
		hd_lasttip=cvar.getcvar("hd_lasttip",plr);
		hd_helptext=cvar.getcvar("hd_helptext",plr);
		hd_voicepitch=cvar.getcvar("hd_voicepitch",plr);
		hd_maglimit=cvar.getcvar("hd_maglimit",plr);
		hd_skin=cvar.getcvar("hd_skin",plr);
		hd_give=cvar.getcvar("hd_give",plr);
		hd_monstervoicepitch=cvar.getcvar("hd_monstervoicepitch",plr);
		hd_pronouns=cvar.getcvar("hd_pronouns",plr);
		hd_height=cvar.getcvar("hd_height",plr);
		hd_strength=cvar.getcvar("hd_strength",plr);
		neverswitchonpickup=cvar.getcvar("neverswitchonpickup",plr);
	}
}
const VB_MAX=0.9;




//Camera actor for player's scope
class ScopeCamera:IdleDummy{
	hdplayerpawn hpl;
	override void postbeginplay(){
		super.postbeginplay();
		hpl=hdplayerpawn(target);
	}
	override void tick(){
		if(!hpl){
			destroy();
			return;
		}
		A_SetAngle(hpl.gunangle,SPF_INTERPOLATE);
		A_SetPitch(hpl.gunpitch,SPF_INTERPOLATE);
		A_SetRoll(hpl.roll);

		setorigin(hpl.pos+hpl.gunpos,true);
	}
//	states{spawn:BLET A -1;}
}



//stuff to reset upon entering a new level
extend class HDHandlers{
	override void PlayerEntered(PlayerEvent e){
		let p=HDPlayerPawn(players[e.PlayerNumber].mo);
		if(p){
			//do NOT put anything here that must be done for everyone at the very start of the game!
			//Players 5-8 will not work.

			if(deathmatch)p.spawn("TeleFog",p.pos,ALLOW_REPLACE);

			p.levelreset();  //reset if changing levels
			hdlivescounter.get();  //only needs to be done once

			//replace bot if changing levels
			if(
				hd_nobots
				&&players[e.PlayerNumber].bot
				&&!hdlivescounter.wiped(e.playernumber)
			){
				p.ReplaceBot();
			}
		}
	}
}

extend class HDPlayerPawn{
	//reset various... things.
	void levelreset(){
		lastvel=vel;
		lastheight=height;
		lastangle=angle;
		lastpitch=pitch;

		incapacitated=0;
		incaptimer=0;

		beatcap=35;beatmax=35;
		bloodpressure=0;beatcounter=0;
		fatigue=0;
		stunned=0;

		bloodloss=0;
		healthcap=maxhealth();
		strength=basestrength();

		A_Capacitated();

		feetangle=angle;
		hasgrabbed=false;

		//heat presists after zero value, so it must be destroyed
		let hhh=findinventory("Heat");if(hhh)hhh.destroy();

		oldwoundcount=min(90,oldwoundcount-1);
		burncount=min(90,burncount-1);
		if(!random(0,7))aggravateddamage--;

		givebody(max(0,maxhealth()-health));

		UpdateEncumbrance();

		HDWeapon.SetBusy(self,false);
		IsMoving.Clear(self);
		A_TakeInventory("Heat");
		gunbraced=false;

		GiveBasics();
		GetOverlayGivers(OverlayGivers);

		A_WeaponOffset(0,30); //reset the weaponoffset so weapon floatiness in playerturn works after level change

		let hbl=HDBlurSphere(findinventory("HDBlurSphere"));
		if(!hbl||!hbl.worn){
			bshadow=false;
			bnotarget=false;
			bnevertarget=false;
			a_setrenderstyle(1.,STYLE_Normal);
		}


		if(!player)return;

		if(cvar.getcvar("hd_consolidate",player).getbool())ConsolidateAmmo();

		if(getage()>10)showgametip();

		if(player==players[consoleplayer])PPShader.SetEnabled("NiteVis",false);
	}
}
class kickchecker:actor{
	default{
		projectile;
		radius 6;height 10;
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			other.bshootable
			&&!other.bghost
			&&!(other is "HDPickup")
			&&!(other is "HDUPK")
			&&!(other is "HDWeapon")
		);
	}
}

