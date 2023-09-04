// ------------------------------------------------------------
// Prototype weapon
// ------------------------------------------------------------
enum HDWeaponFlagsets{
	WRF_ALL=WRF_ALLOWRELOAD|WRF_ALLOWZOOM|WRF_ALLOWUSER1|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4,
	WRF_NONE=WRF_NOFIRE|WRF_DISABLESWITCH,
	BT_ALTFIRE=BT_ALTATTACK,
	BT_ALTRELOAD=BT_USER1,
	BT_FIREMODE=BT_USER2,
	BT_UNLOAD=BT_USER4,
}
class HDWeapon:Weapon{
	int HDWeaponFlags;
	flagdef DropTranslation:HDWeaponFlags,0;
	flagdef WeaponBusy:HDWeaponFlags,1;
	flagdef FitsInBackpack:HDweaponFlags,2;
	flagdef DontFistOnDrop:HDweaponFlags,3;
	flagdef JustChucked:HDWeaponFlags,4;
	flagdef ReverseGunInertia:HDWeaponFlags,5;
	flagdef AlwaysShowStatus:HDWeaponFlags,6;
	flagdef DontDefaultConfigure:HDWeaponFlags,7;
	flagdef PlayingId:HDWeaponFlags,8;
	flagdef DontDisarm:HDWeaponFlags,9;
	flagdef DebugOnly:HDWeaponFlags,10;
	flagdef IgnoreLoadoutAmount:HDWeaponFlags,11; //so "bak 450 10. z66 nogl" gives 1 backpack
	flagdef DontNull:HDWeaponFlags,12;
	flagdef NoRandomBackpackSpawn:HDWeaponFlags,13;
	flagdef HinderLegs:HDWeaponFlags,14;
	flagdef DoneSwitching:HDWeaponFlags,15;

	double barrellength;
	double barrelwidth;
	double barreldepth;
	property barrelsize:barrellength,barrelwidth,barreldepth;

	string refid;
	property refid:refid;
	string loadoutcodes;
	property loadoutcodes:loadoutcodes;

	int wornlayer;property wornlayer:wornlayer;

	class<HDPickup> hdammotype1,hdammotype2;
	int hdammogive1,hdammogive2;
	property ammo1:hdammotype1,hdammogive1;
	property ammo2:hdammotype2,hdammogive2;

	int weaponstatus[HDWEP_STATUSSLOTS];
	int msgtimer;
	int actualamount;
	string wepmsg;
	string LWPHELP_FIRE;
	string LWPHELP_ALTFIRE;
	string LWPHELP_RELOAD;
	string LWPHELP_ZOOM;
	string LWPHELP_ALTRELOAD;
	string LWPHELP_FIREMODE;
	string LWPHELP_USER3;
	string LWPHELP_UNLOAD;

	string LWPHELP_SPEED;
	string LWPHELP_UPDOWN;
	string LWPHELP_USE;
	string LWPHELP_DROP;
	string LWPHELP_DROPONE;

	string LWPHELP_FIRESHOOT;
	string LWPHELP_RELOADRELOAD;
	string LWPHELP_UNLOADUNLOAD;
	string LWPHELP_MAGMANAGER;
	string LWPHELP_INJECTOR;
	default{
		+solid
		+weapon.ammo_optional +weapon.alt_ammo_optional +weapon.noalert +weapon.noautoaim
		+weapon.no_auto_switch
		+noblockmonst +notrigger +dontgib
		+usebouncestate +hittracer
		+skyexplode
		-hdweapon.dontfistondrop
		-hdweapon.fitsinbackpack
		+weapon.dontbob
		weapon.ammogive 0;weapon.ammogive2 0;
		weapon.ammouse1 0;weapon.ammouse2 0;
		weapon.bobstyle "Alpha";
		inventory.pickupsound "misc/w_pkup";
		radius 12;height 12;
		gravity HDCONST_GRAVITY;
		bouncefactor 1.;

		weapon.bobspeed 2.4;
		weapon.bobrangex 0.2;
		weapon.bobrangey 0.8;
		hdweapon.barrelsize 0,0,0;
		hdweapon.refid "";
		hdweapon.loadoutcodes "";
		hdweapon.wornlayer 0;
		tag "";
	}
	void LocalizeHelp()//thanks to N00b from DoomPower forum for help with this one
	{
		LWPHELP_FIRE=WEPHELP_BTCOL..StringTable.Localize("$WPHFIRE")..WEPHELP_RGCOL;
		LWPHELP_ALTFIRE=WEPHELP_BTCOL..StringTable.Localize("$WPHALTFIRE")..WEPHELP_RGCOL;
		LWPHELP_RELOAD=WEPHELP_BTCOL..StringTable.Localize("$WPHRELOAD")..WEPHELP_RGCOL;
		LWPHELP_ZOOM=WEPHELP_BTCOL..StringTable.Localize("$WPHZOOM")..WEPHELP_RGCOL;
		LWPHELP_ALTRELOAD=WEPHELP_BTCOL..StringTable.Localize("$WPHAREL")..WEPHELP_RGCOL;
		LWPHELP_FIREMODE=WEPHELP_BTCOL..StringTable.Localize("$WPHFMODE")..WEPHELP_RGCOL;
		LWPHELP_USER3=WEPHELP_BTCOL..StringTable.Localize("$WPHUSER3")..WEPHELP_RGCOL;
		LWPHELP_UNLOAD=WEPHELP_BTCOL..StringTable.Localize("$WPHUNLOAD")..WEPHELP_RGCOL;
		LWPHELP_SPEED=WEPHELP_BTCOL..StringTable.Localize("$WPHSPEED")..WEPHELP_RGCOL;
		LWPHELP_UPDOWN=WEPHELP_BTCOL..StringTable.Localize("$WPHMLOOK")..WEPHELP_RGCOL;
		LWPHELP_USE=WEPHELP_BTCOL..StringTable.Localize("$WPHUSE")..WEPHELP_RGCOL;
		LWPHELP_DROP=WEPHELP_BTCOL..StringTable.Localize("$WPHDROP")..WEPHELP_RGCOL;
		LWPHELP_DROPONE=WEPHELP_BTCOL..StringTable.Localize("$WPHDROPO")..WEPHELP_RGCOL;
		LWPHELP_FIRESHOOT=LWPHELP_FIRE..StringTable.Localize("$WPHSHT");
		LWPHELP_RELOADRELOAD=LWPHELP_RELOAD..StringTable.Localize("$WPHREL");
		LWPHELP_UNLOADUNLOAD=LWPHELP_UNLOAD..StringTable.Localize("$WPHUNL");
		LWPHELP_MAGMANAGER=LWPHELP_USER3..StringTable.Localize("$WPHMMAN");
		LWPHELP_INJECTOR=LWPHELP_FIRE..StringTable.Localize("$WPHUSEONY")..LWPHELP_ALTFIRE..StringTable.Localize("$WPHUSEONS"); 
	}
	override bool getnoteleportfreeze(){return true;}
	override bool cancollidewith(actor other,bool passive){return bmissile||HDPickerUpper(other);}
	//wrapper for setpsprite
	action void SetWeaponState(statelabel st,int layer=PSP_WEAPON){
		if(player)player.setpsprite(layer,invoker.findstate(st));
	}
	//wrapper for setpsprite
	void SetOwnerWeaponState(statelabel st,int layer=PSP_WEAPON){
		if(owner&&owner.player)owner.player.setpsprite(layer,findstate(st));
	}
	//use target to help a dropped weapon remember its immediately prior owner
	override void detachfromowner(){
		actor oldowner=owner;
		if(
			!bdontfistondrop
			&&oldowner.player
			&&!oldowner.player.readyweapon
		){
			oldowner.A_SelectWeapon("HDFist");
			let fff=HDFist(oldowner.findinventory("HDFist"));
			if(fff)fff.washolding=true;
		}
		angle=oldowner.angle;pitch=oldowner.pitch;
		target=oldowner;
		if(bdroptranslation)translation=oldowner.translation;
		super.detachfromowner();
	}
	//wrapper for checking if gun is braced
	action bool gunbraced(){
		return hdplayerpawn(self)&&hdplayerpawn(self).gunbraced;
	}
	//set the weapon as "busy" to reduce movement, etc.
	action void A_WeaponBusy(bool yes=true){invoker.bweaponbusy=yes;}
	static void SetBusy(actor onr,bool yes=true){
		if(onr.player&&hdweapon(onr.player.readyweapon))
		hdweapon(onr.player.readyweapon).bweaponbusy=yes;
	}
	static bool IsBusy(actor onr){
		return(
			onr.player
			&&hdweapon(onr.player.readyweapon)
			&&hdweapon(onr.player.readyweapon).bweaponbusy
		);
	}
	virtual bool IsBeingWorn(){return false;}
	virtual double RestrictSpeed(double speedcap){return speedcap;}
	//use this to set flash translucency and make it additive
	action void HDFlashAlpha(int variance=0,bool noalpha=false,int layer=PSP_FLASH){
		A_OverlayFlags(layer,PSPF_ALPHA|PSPF_ADDBOB|PSPF_RENDERSTYLE,true);
		A_OverlayRenderstyle(layer,STYLE_Add);
		double fa;
		if(noalpha){
			A_OverlayAlpha(layer,1.);
		}else{
			fa=1.-((cursector.lightlevel-variance*frandom(0.6,1.))*0.003);
			A_OverlayAlpha(layer,fa);
		}
		if(noalpha||fa>0.1)setstatelabel("melee");
	}
	//wrapper for HDWeapon and ActionItem
	//remember: LEFT and DOWN
	//if it's janky, TURN WEPDOT OFF
	action void A_MuzzleClimb(
		double mc10=0,double mc11=0,
		double mc20=0,double mc21=0,
		double mc30=0,double mc31=0,
		double mc40=0,double mc41=0,
		bool wepdot=true
	){
		let hdp=HDPlayerPawn(self);
		if(hdp){
			hdp.A_MuzzleClimb((mc10,mc11),(mc20,mc21),(mc30,mc31),(mc40,mc41),wepdot);
		}else{ //I don't even know why
			vector2 mc0=(mc10,mc11)+(mc20,mc21)+(mc30,mc31)+(mc40,mc41);
			A_SetPitch(pitch+mc0.y,SPF_INTERPOLATE);
			A_SetAngle(angle+mc0.x,SPF_INTERPOLATE);
		}
	}
	action void A_ZoomRecoil(double prop){
		let hdp=hdplayerpawn(self);
		if(hdp){
			if(hdp.strength)prop=1.+(1.-prop)/hdp.strength;
			hdp.recoilfov=(hdp.recoilfov+prop)*0.5;
		}
	}
	//do these whenever the gun is ready
	action void A_ReadyEnd(){
		A_WeaponBusy(false);
		invoker.bdoneswitching=true;
		if(invoker.msgtimer>0){
			invoker.msgtimer--;
			if(invoker.msgtimer<1)invoker.wepmsg="";
		}
		let p=HDPlayerPawn(self);
		if(!p)return;
		p.movehijacked=false;

		if(p.lastmisc1)p.lastmisc1/=2;
		if(p.lastmisc2)p.lastmisc2/=2;

		if(
			player.bot&&
			!random(0,3)
		)setweaponstate("botreload");
	}

	//for when the player dies or collapses
	virtual void OnPlayerDrop(){}

	//forces you to have some ammo, called in encumbrance
	virtual void ForceBasicAmmo(){
		if(!!hdammotype1){
			owner.A_SetInventory(hdammotype1,hdammogive1);
			let mmm=hdmagammo(owner.findinventory(hdammotype1));
			if(mmm){
				mmm.mags.clear();
				mmm.syncamount();
			}
		}
		if(!!hdammotype2){
			owner.A_SetInventory(hdammotype2,hdammogive2);
			let mmm=hdmagammo(owner.findinventory(hdammotype2));
			if(mmm){
				mmm.mags.clear();
				mmm.syncamount();
			}
		}
	}
	void ForceOneBasicAmmo(class<inventory> type,int amt=1){
		owner.A_SetInventory(type,amt);
		let mmm=hdmagammo(owner.findinventory(type));
		if(mmm){mmm.mags.clear();mmm.SyncAmount();}
	}

	//activate a laser rangefinder
	//because every gun should have one of these
	//note that this uses the gunpos xy offset unlike the command
	action void FindRange(){
		let hdp=hdplayerpawn(self);
		if(hdp)HDHandlers.FindRange(hdp,true);
	}


	//grabs mouse/whatever input and freezes the player if desired
	action int GetMouseX(bool hijack=false){
		if(hijack){
			reactiontime=max(reactiontime,1);
			let hdp=HDPlayerPawn(self);
			if(hdp){
				hdp.lastcrossbob=hdp.crossbob;
				hdp.crossbob*=0.8;
			}
		}
		return player.cmd.yaw;
	}
	action int GetMouseY(bool hijack=false){
		if(hijack){
			reactiontime=max(reactiontime,1);
			let hdp=HDPlayerPawn(self);
			if(hdp){
				hdp.lastcrossbob=hdp.crossbob;
				hdp.crossbob*=0.8;
			}
		}
		return player.cmd.pitch;
	}


	//stops moving input
	action void HijackMove(){
		let ppp=hdplayerpawn(self);if(ppp)ppp.movehijacked=true;
		else player.cmd.forwardmove=0;player.cmd.sidemove=0;
	}

	//for throwing a weapon
	override inventory CreateTossable(int amt){
		let onr=hdplayerpawn(owner);
		bool throw=(
			onr
			&&onr.player
			&&onr.player.cmd.buttons&BT_ZOOM
		);
		bool isreadyweapon=onr&&onr.player&&onr.player.readyweapon==self;
		if(!isreadyweapon)throw=false;
		let thrown=super.createtossable(amt);
		if(!thrown)return null;
		let newwep=GetSpareWeapon(onr,doselect:isreadyweapon);
		hdweapon(thrown).bjustchucked=true;
		thrown.target=onr;
		thrown.lastenemy=onr;
		if(throw){
			thrown.bmissile=true;
			thrown.bBOUNCEONWALLS=true;
			thrown.bBOUNCEONFLOORS=true;
			thrown.bALLOWBOUNCEONACTORS=true;
			thrown.bBOUNCEAUTOOFF=true;
		}else{
			thrown.bmissile=false;
			thrown.bBOUNCEONWALLS=false;
			thrown.bBOUNCEONFLOORS=false;
			thrown.bALLOWBOUNCEONACTORS=false;
			thrown.bBOUNCEAUTOOFF=false;
		}
		return thrown;
	}
	//an override is needed because DropInventory will undo anything done in CreateTossable
	double throwvel;
	override void OnDrop(Actor dropper){
		if(bjustchucked&&target){
			double cp=cos(target.pitch);
			if(bmissile){
				vel=target.vel+
					(cp*(cos(target.angle),sin(target.angle)),-sin(target.pitch))
					*min(20,800/weaponbulk())
					*(hdplayerpawn(target)?hdplayerpawn(target).strength:1.)
				;
			}else vel=target.vel+(cp*(cos(target.angle),sin(target.angle)),-sin(target.pitch))*4;
			throwvel=vel dot vel;
			bjustchucked=false;
		}

		//copypasted from HDPickup
		if(dropper){
			setz(dropper.pos.z+dropper.height*0.8);
			if(!bmissile){
				double dp=max(dropper.pitch-6,-90);
				vel=dropper.vel+(
					cos(dp)*(cos(dropper.angle),sin(dropper.angle)),
					-sin(dp)
				)*3;
			}
			HDBackpack.ForceUpdate(dropper);
		}
	}

	override void DoEffect(){
		if(amount<1){
			destroy();
			return;
		}

		//update count
		actualamount=1;
		if(owner&&owner.findinventory("SpareWeapons")){
			let spw=spareweapons(owner.findinventory("SpareWeapons"));
			string gcn=getclassname();
			for(int i=0;i<spw.weapontype.size();i++){
				if(spw.weapontype[i]==gcn)actualamount++;
			}
		}

		//if there are offsets specified, assume raising is finished
		if(
			!!owner
			&&!!owner.player
		){
			let psp=owner.player.getpsprite(PSP_WEAPON);
			if(
				!!psp
				&&!!psp.curstate
				&&(
					psp.curstate.misc1
					||psp.curstate.misc2
				)
			)bdoneswitching=true;
		}
	}
	action void A_GunBounce(){invoker.GunBounce();}
	virtual void GunBounce(){
		double wb=weaponbulk();
		int dmg=int(throwvel*wb*wb*frandom(0.000001,0.00002));

		if(tracer){
			tracer.damagemobj(self,target,dmg,"Bashing");
			if(hd_debug)A_Log(tracer.getclassname().." hit for "..dmg.." damage with thrown "..getclassname());
		}

		vel*=frandom(0.3,0.4);
		if(
			abs(vel.x)<5
			&&abs(vel.y)<5
			&&abs(vel.z)<5
		){
			bmissile=false;
			bBOUNCEONWALLS=false;
			bBOUNCEONFLOORS=false;
			bALLOWBOUNCEONACTORS=false;
			bBOUNCEAUTOOFF=false;
		}

		A_StartSound("weapons/smack",CHAN_BODY,CHANF_OVERLAP,min(0.5,dmg*0.02));
		setstatelabel("spawn");
	}

	//zoom adjuster for rifles
	action void A_ZoomAdjust(int slot,int minzoom,int maxzoom,int secondbutton=BT_USER2){
		if(!PressingZoom()){
			setweaponstate("nope");
			return;
		}
		if(!(player.cmd.buttons&secondbutton)){
			A_WeaponReady(WRF_ALL);
			return;
		}
		let hdp=hdplayerpawn(self);
		if(!hdp)return;
		int inputamt=GetMouseY(true);

		if(inputamt){
			if(abs(inputamt)<(1<<5))inputamt=clamp(inputamt,-1,1);
			else inputamt>>=5;
		}
		inputamt+=(justpressed(BT_ATTACK)?1:justpressed(BT_ALTATTACK)?-1:0);
		invoker.weaponstatus[slot]=clamp(
			invoker.weaponstatus[slot]-inputamt,minzoom,maxzoom
		);
		A_WeaponReady(WRF_NOFIRE);
	}

	//determine mass for weapon inertia purposes
	virtual double gunmass(){return 0;}
	//determine bulk for weapon encumbrance purposes
	virtual double weaponbulk(){return 0;}

	//for consolidating stuff between maps
	virtual void Consolidate(){}

	//what to do when hitting the "drop one unit of ammo" key
	virtual void DropOneAmmo(int amt=1){}

	//for smoking barrels
	void drainheat(
		int ref,
		int smklength=18,
		double smkscale=1.,  //set to zero for no smoke at all
		double smkspeed=3.,
		double smkstartalpha=0.
	){
		if(isfrozen())return;
		if(weaponstatus[ref]>0){
			weaponstatus[ref]--;
			if(
				smkscale<=0
				||random(1,10)>weaponstatus[ref]
			)return;
			vector3 smkpos=pos;
			vector3 smkvel=vel;
			vector3 smkdir=(0,0,0);
			double smkang=angle;
			double smkpitch=pitch;
			if(owner){
				smkpos=owner.pos;
				if(
					!owner.player
					||owner.player.readyweapon==self
				){
					//spawn smoke from muzzle
					actor sccam;
					if(
						hdplayerpawn(owner)
						&&hdplayerpawn(owner).scopecamera
					)sccam=hdplayerpawn(owner).scopecamera;
					else sccam=owner;
					smkang=sccam.angle;smkpitch=sccam.pitch;
					smkdir=(cos(sccam.pitch)*(cos(smkang),sin(smkang)),-sin(sccam.pitch));
					smkpos.z=sccam.pos.z-4+smkdir.z*smklength;
					smkpos.xy+=smklength*smkdir.xy;
				}else{
					//spawn smoke from behind owner
					smkang=owner.angle;
					smkpos.z+=owner.height*0.6;
					smkpos.xy-=10*(cos(smkang),sin(smkang));
				}
				smkvel=owner.vel;
				smkpos-=smkvel;
			}
			if(!smkstartalpha)smkstartalpha=getdefaultbytype("HDGunsmoke").alpha;
			actor a=spawn("HDGunsmoke",smkpos,ALLOW_REPLACE);
			smkvel*=0.4;
			smkdir*=smkspeed;
			smkvel+=smkdir;
			a.angle=smkang;a.pitch=smkpitch;a.vel=smkvel;a.scale*=smkscale;a.alpha=smkstartalpha;
			for(int i=30;i<weaponstatus[ref];i+=30){
				if(!random(0,3)){
					a=spawn("HDGunsmoke",smkpos,ALLOW_REPLACE);
					a.angle=smkang;a.pitch=smkpitch;
					a.scale*=smkscale;a.alpha=smkstartalpha;
					a.vel=smkvel+(frandom(-2,2),frandom(-2,2),frandom(-2,2));
				}
			}
		}
		//also deal with spares, no smoke because lazy
		if(owner){
			let spw=spareweapons(owner.findinventory("spareweapons"));
			if(spw){
				string gcn=getclassname();
				for(int i=0;i<spw.weapontype.size();i++){
					if(spw.weapontype[i]==gcn){
						array<string> wepstat;
						spw.weaponstatus[i].split(wepstat,",");
						if(wepstat[ref].toint()>0)wepstat[ref]=""..(wepstat[ref].toint()-1);
						string newwepstat="";
						for(int j=0;j<wepstat.size();j++){
							if(j)newwepstat=newwepstat..",";
							newwepstat=newwepstat..wepstat[j];
						}
						spw.weaponstatus[i]=newwepstat;
					}
				}
			}
		}
	}

	//spawns an actor in front of you and moves it to the side
	action actor A_EjectCasing(
		class<actor> type,
		double ejectangle,
		vector3 ejectvel=(0,0,0),
		vector3 offset=(0,0,0)
	){
		return HDWeapon.EjectCasing(
			self,
			type,
			ejectangle,
			ejectvel,
			offset
		);
	}
	static actor EjectCasing(
		actor caller,
		class<actor> type,
		double ejectangle,
		vector3 ejectvel=(0,0,0),
		vector3 offset=(0,0,0)
	){
		vector3 spawnpos=caller.pos+HDMath.GetGunPos(caller);
		spawnpos+=HDMath.RotateVec3D(offset,caller.angle,caller.pitch);
		actor aaa=spawn(type,spawnpos);

		ejectangle+=caller.angle;
		aaa.angle=ejectangle;
		aaa.pitch=caller.pitch;
		aaa.vel=caller.vel;
		aaa.vel+=HDMath.RotateVec3D(ejectvel,ejectangle,aaa.pitch);
		return aaa;
	}


	//interface stuff
	virtual clearscope string,double getpickupsprite(bool usespare=false){return "",1.;}
	clearscope int GetSpareWeaponValue(
		int statusslot,
		bool dousespares=true
	){
		if(!dousespares)return weaponstatus[statusslot];
		if(!owner)return weaponstatus[statusslot];
		let spw=SpareWeapons(owner.findinventory("SpareWeapons"));
		if(!spw)return weaponstatus[statusslot];
		for(int i=0;i<spw.weapontype.size();i++){
			if(
				spw.weapontype[i]==getclassname()
			)return spw.GetWeaponValue(i,statusslot);
		}
		return weaponstatus[statusslot];
	}

	virtual ui int getsbarnum(int flags=0){return -1000000;}
	virtual ui int DisplayAmount(){return actualamount;}
	virtual ui void DrawHUDStuff(HDStatusBar sb,HDWeapon wp,HDPlayerPawn hpl){}
	virtual ui void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
		,string whichdot="redpxl"  //deprecated
	){}
	virtual string gethelptext(){return "";}
	action void A_SetHelpText(){
		let hdp=hdplayerpawn(invoker.owner);  //can't use "self", backpack does something weird with this
		if(hdp){
			invoker.LocalizeHelp();
			string ttt=invoker.gethelptext();
			if(ttt!="")hdp.wephelptext="\cu"..invoker.gettag().."\n"..ttt;
			else hdp.wephelptext=ttt;
		}
	}
	//that said, why get picky when you can just shoot twice?
	action void A_MagManager(name type){
		A_SetInventory("MagManager",1);
		let mmm=MagManager(findinventory("MagManager"));
		mmm.thismag=hdmagammo(findinventory(type));mmm.thismagtype=type;
		UseInventory(mmm);
	}


	//when a grabber touches it but before the pull
	virtual bool OnGrab(actor grabber){return true;}

	//for picking up
	override void touch(actor toucher){}
	virtual void actualpickup(actor other,bool silent=false){
		let gcn=getclassname();
		let oldwep=hdweapon(other.findinventory(gcn));
		let hdp=hdplayerpawn(other);


		if(oldwep){

			//see how many the user already has
			int wepcount=1;
			let spw=spareweapons(hdp.findinventory("spareweapons"));
			if(spw){
				for(int i=0;i<spw.weapontype.size();i++){
					if(spw.weapontype[i]==gcn)wepcount++;
				}
			}

			//allow maximum 2 of each weapon in low encumbrance mode
			if(
				hd_encumbrance<1.
				&&wepcount>=2
			){
				if(!silent)other.A_Log(string.format(StringTable.Localize("$WEPWH_LOWENCU")..gettag()..StringTable.Localize("$WEPWH_LOWFIRST")),true);
				return;
			}

			//if low encumb restriction does not apply, add the weapon
			if(
				hdp
				&&hdp.neverswitchonpickup
				&&hdp.neverswitchonpickup.getbool()
			){
				bool asw=addspareweapon(other);
				if(asw&&!silent&&!!self){
					HDPickup.LogPickupMessage(other,pickupmessage());

					other.A_StartSound(pickupsound,CHAN_AUTO);
					//provide some feedback that the player has picked up extra weapons
					if(
						hdp
						&&hdp.hd_helptext.getbool()
						&&level.time>10
					){
						hdp.A_Log(StringTable.Localize("$WEPWH_THISYOUR")..gettag()..StringTable.Localize("$WEPWH_NUMBER")..(wepcount+1)..".",true);
					}
				}
				return;
			}
			if(
				oldwep
				&&!oldwep.AddSpareWeapon(other)
			){
				//fast-unload weapon without picking it up
				angle=other.angle-70;
				failedpickupunload();
				return;
			}
		}

		if(
			wornlayer
			&&isbeingworn()
			&&!HDPlayerPawn.CheckStrip(other,self,false)
		)return;

		if(!self)return;
		if(!silent){
			HDPickup.LogPickupMessage(other,pickupmessage());
			other.A_StartSound(pickupsound,CHAN_AUTO);
		}
		attachtoowner(other);
	}

	//when you have the same gun, just strip the new one
	virtual void failedpickupunload(){}
	void failedpickupunloadmag(int magslot,class<hdmagammo> type){
		if(weaponstatus[magslot]<0)return;
		A_StartSound("weapons/rifleclick2",8);
		A_StartSound("weapons/rifleload",8,CHANF_OVERLAP);
		HDMagAmmo.SpawnMag(self,type,weaponstatus[magslot]);
		weaponstatus[magslot]=-1;
		setstatelabel("spawn");
	}

	//swap out alternative "fixed" weapon sprites - id
	action void A_CheckIdSprite(string altsprite,string regsprite,int layer=PSP_WEAPON){
		bool needspritefix=false;
		if(
			Wads.CheckNumForName("id",0)!=-1
			&&texman.checkfortexture(altsprite,texman.type_sprite).isvalid()
		){
			int i=-1,counter=0;
			do{
				i=wads.CheckNumForName(regsprite,i+1,wads.ns_sprites);
				counter++;
			}until (i<0);
			if(counter<=2)needspritefix=true; //original + textures replacement = 2
		}
		if(needspritefix)Player.GetPSprite(layer).sprite=GetSpriteIndex(altsprite);
		else Player.GetPSprite(layer).sprite=GetSpriteIndex(regsprite);
	}

	//because weapons don't use proper "ammo" anymore for loaded items
	virtual void InitializeWepStats(bool idfa=false){}
	override void beginplay(){
		for(int i=0;i<HDWEP_STATUSSLOTS;i++)weaponstatus[i]=0;
		msgtimer=0;wepmsg="";
		initializewepstats();
		bplayingid=(Wads.CheckNumForName("id",0)!=-1);
		setreflexreticle(-1);
		super.beginplay();
	}

	//parse what would normally be the amount string as a set of variables
	virtual void loadoutconfigure(string input){}
	//retrieves the entire hd_weapondefaults cvar for a given player
	static string getdefaultcvar(playerinfo pl){
		if(!pl)return "";
		string weapondefaults=cvar.getcvar("hd_weapondefaults",pl).getstring();
		weapondefaults=weapondefaults.makelower();
		weapondefaults.replace(" ","");
		return weapondefaults;
	}
	//apply config from owner's hd_weapondefaults cvar
	virtual void defaultconfigure(playerinfo whichplayer,string weapondefaults="cvar"){
		bdontdefaultconfigure=true;
		if(!whichplayer)return;
		if(weapondefaults=="cvar")weapondefaults=hdweapon.getdefaultcvar(whichplayer);
		if(weapondefaults=="")return;
		weapondefaults.replace(" ","");
		weapondefaults.makelower();
		int defvarstart=weapondefaults.indexof(refid);
		if(defvarstart>=0){
			string wepdefault=weapondefaults.mid(defvarstart);
			int defcomma=wepdefault.indexof(",");
			if(defcomma>=0)wepdefault=wepdefault.left(defcomma);
			loadoutconfigure(wepdefault);
		}
	}
	//parse a weapon loadout variable to an int
	int getloadoutvar(string input,string varname,int maxdigits=int.MAX){
		int varstart=input.indexof(varname);
		if(varstart<0)return -1;
		int digitstart=varstart+varname.length();
		string inp=input.mid(digitstart,maxdigits);
		if(inp=="0")return 0;
		if(inp.indexof("e")>=0)inp=inp.left(inp.indexof("e")); //"123e45"
		if(inp.indexof("x")>=0)inp=inp.left(inp.indexof("x")); //"0xffffff..."
		int inpint=inp.toint();
		if(!inpint)return 1; //var merely mentioned with no number
		return inpint;
	}


	//deprecated as of 4.8.x
	//shoots out a line to see if the area ahead is unimpeded.
	//if it is, the gun cannot be raised up to the eyes.
	static double GetShootOffset(
		actor caller,
		double eyerange=36,
		double chestrange=-1,
		double gundepth=3
	){
		vector3 spp=HDMath.GetGunPos(caller);
		if(hd_debug)console.printf("Deprecated wrapper HDWeapon.GetShootOffset. Use HDMath.GetGunPos instead.");
		return spp.z;
	}
	action vector3 gunpos(
		vector3 offset=(0,0,0)
	){
		let hdp=hdplayerpawn(self);
		if(hdp){
			if(offset.x||offset.y||offset.z)return hdp.gunpos+HDMath.RotateVec3D(offset,angle,pitch);
			return hdp.gunpos;
		}
		return (0,0,height*0.8);
	}
	action double gunheight(){
		let hdp=hdplayerpawn(self);
		if(hdp)return hdp.gunpos.z;
		return height*0.8;
	}

	override void postbeginplay(){
		super.postbeginplay();
		if(hdpickup.checknoloadout(self,refid))return;
		if(!bwimpy_weapon)bno_auto_switch=false;
		if(!bdontdefaultconfigure&&owner&&owner.player)defaultconfigure(owner.player);
	}
	//because A_Print doesn't cut it
	action void A_WeaponMessage(string msg,int time=100){
		invoker.wepmsg=msg;
		invoker.msgtimer=abs(time);
		if(time<0)A_Log(msg,true);
	}
	static void ForceWeaponMessage(actor caller,string msg,int time=100){
		if(!caller||!caller.player)return;
		let invoker=HDWeapon(caller.player.readyweapon);
		if(!invoker){
			caller.A_Print(msg);
			return;
		}
		invoker.wepmsg=msg;
		invoker.msgtimer=abs(time);
	}

	//same as HDPickup
	override string PickupMessage(){
		return Stringtable.Localize(PickupMsg);
	}

	action bool DoHelpText(actor caller=null){
		if(!caller)caller=self;
		return HDWeapon.CheckDoHelpText(caller);
	}
	static bool CheckDoHelpText(actor caller){
		return
			!!caller
			&&!!caller.player
			&&caller.player.mo==caller
			&&(
				hdplayerpawn(caller)
				&&hdplayerpawn(caller).hd_helptext
				&&hdplayerpawn(caller).hd_helptext.getbool()
			)
		;
	}


	//because I'm too lazy to retype all that shit
	action bool PressingFire(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_ATTACK;}
	action bool PressingAltfire(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_ALTATTACK;}
	action bool PressingReload(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_RELOAD;}
	action bool PressingZoom(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_ZOOM;}
	action bool PressingAltReload(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_USER1;}
	action bool PressingFiremode(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_USER2;}
	action bool PressingUser3(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_USER3;}
	action bool PressingUnload(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_USER4;}
	action bool PressingUse(){return invoker.owner && invoker.owner.player.cmd.buttons&BT_USE;}
	action bool Pressing(int whichbuttons){return invoker.owner.player.cmd.buttons&whichbuttons;}
	action bool JustPressed(int whichbutton){return(
		invoker.owner && invoker.owner.player.cmd.buttons&whichbutton&&!(invoker.owner.player.oldbuttons&whichbutton)
	);}
	action bool JustReleased(int whichbutton){return(
		invoker.owner && !(invoker.owner.player.cmd.buttons&whichbutton)&&invoker.owner.player.oldbuttons&whichbutton
	);}
	action void A_StartDeselect(bool gotodzero=true){
		A_WeaponBusy();
		invoker.bdoneswitching=false;
		A_SetCrosshair(21);
		invoker.wepmsg="";invoker.msgtimer=0;
		if(gotodzero)setweaponstate("deselect0");
	}


	//nothing to see here, go away
	action void A_UnmakeLevel(int times=1){HDWeapon.UnmakeLevel(times);}
	static void UnmakeLevel(int times=1){
		for(int k=0;k<times;k++){
			sector thissector=level.sectors[random(0,level.sectors.size()-1)];
			int dir=random(-3,3);
			double zatpoint=thissector.floorplane.ZAtPoint(thissector.centerspot);
			thissector.MoveFloor(dir,zatpoint,0,zatpoint>0?-1:1,false);
			dir=random(-3,3);
			zatpoint=thissector.ceilingplane.ZAtPoint(thissector.centerspot);
			thissector.MoveCeiling(dir,zatpoint,0,zatpoint>0?-1:1,false);
			thissector.changelightlevel(random(-random(3,4),3));
			//then maybe add some textures
			textureid shwal;
			switch(random(0,4)){
			case 1:
				shwal=texman.checkfortexture("WALL63_2",texman.type_any);break;
			case 2:
				shwal=texman.checkfortexture("W94_1",texman.type_any);break;
			case 3:
				shwal=texman.checkfortexture("FIREBLU1",texman.type_any);break;
			case 4:
				shwal=texman.checkfortexture("SNAK"..random(7,8).."_1",texman.type_any);break;
			default:
				shwal=texman.checkfortexture("ASHWALL2",texman.type_any);break;
			}
			for(int i=0;i<thissector.lines.size();i++){
				line lnn=thissector.lines[i];
				for(int j=0;j<2;j++){
					if(!lnn.sidedef[j])continue;
					if(!lnn.sidedef[j].GetTexture(side.top))lnn.sidedef[j].SetTexture(side.top,shwal);
					if(!lnn.sidedef[j].GetTexture(side.bottom))lnn.sidedef[j].SetTexture(side.bottom,shwal);
				}
			}
		}
	}



	states{
	spawn:
		TNT1 A 0;
		stop;
	bounce:
		---- A 0 { tracer = null; }
	bounce.actor:
	death:
		---- A 0 A_GunBounce();
		goto spawn;
	select:
		TNT1 A 0{
			//these two don't actually work???
			A_OverlayFlags(PSP_WEAPON,PSPF_CVARFAST|PSPF_POWDOUBLE,false);
			A_OverlayFlags(PSP_FLASH,PSPF_CVARFAST|PSPF_POWDOUBLE,false);

			A_WeaponBusy();
			invoker.bdoneswitching=false;
			A_SetHelpText();

			return resolvestate("select0");
		}
	select0:
		---- A 0 A_Raise();
		wait;
	deselect:
		TNT1 A 0 A_StartDeselect();
	deselect0:
		---- A 0 A_Lower();
		wait;

	select0big:
		---- A 2 A_JumpIfInventory("NulledWeapon",1,"select1big");
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(11);
		---- A 1 A_Raise(1);
		wait;
	deselect0big:
		---- A 0 A_JumpIfInventory("NulledWeapon",1,"deselect1big");
		---- A 1 A_Lower(0);
		---- A 1 A_Lower(1);
		---- AA 1 A_Lower(1);
		---- A 1 A_Lower(3);
		---- AA 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		---- A 1 A_Lower();
		wait;
	deselect1big:
		---- AA 1 A_Lower(1);
		---- AA 1 A_Lower(2);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		wait;
	select1big:
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(35);
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(1);
		wait;
	select0small:
		---- A 1 A_JumpIfInventory("NulledWeapon",1,"select1small");
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(10);
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(12);
		---- A 1 A_Raise(6);
		---- A 1 A_Raise(1);
		wait;
	deselect0small:
		---- A 0 A_JumpIfInventory("NulledWeapon",1,"deselect1small");
		---- A 1 A_Lower(1);
		---- AA 1 A_Lower(2);
		---- AA 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(30);
		---- A 1 A_Lower(36);
		---- A 1 A_Lower();
		wait;
	deselect1small:
		---- A 1 A_Lower(1);
		---- A 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		---- A 1 A_Lower(36);
		wait;
	select1small:
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(16);
		---- A 1 A_Raise(12);
		---- A 1 A_WeaponOffset(0,2,WOF_ADD);
		---- A 1 A_Raise(1);
		wait;
	select0bfg:
		---- A 3 A_JumpIfInventory("NulledWeapon",1,"select1bfg");
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise();
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(18);
		---- A 1 A_Raise(12);
		---- AAA 1 A_Raise();
		---- A 1 A_Raise(-2);
		---- AA 1 A_Raise(-1);
		---- AA 1{
			A_MuzzleClimb(0.3,0.8);
			A_Raise(-1);
		}
		---- AA 1 A_MuzzleClimb(-0.1,-0.4);
		---- AA 1 A_Raise();
		---- A 1 A_Raise();
		---- A 1 A_Raise(12);
		---- A 1 A_Raise(12);
		wait;
	deselect0bfg:
		---- A 0 A_JumpIfHealthLower(1,"deselect1big");
		---- A 0 A_JumpIfInventory("NulledWeapon",1,"deselect1bfg");
		---- AA 1 A_Lower(0);
		---- AA 1 A_Lower();
		---- A 1 A_Lower(1);
		---- AA 1 A_Lower(1);
		---- AA 1{
			A_MuzzleClimb(0.3,0.8);
			A_Lower(0);
		}
		---- AA 1{
			A_MuzzleClimb(-0.1,-0.4);
			A_Lower(2);
		}
		---- AAAA 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(24);
		wait;
	deselect1bfg:
		---- AA 1 A_Lower(-2);
		---- A 1 A_Lower(0);
		---- AAA 1 A_Lower();
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(24);
		wait;
	select1bfg:
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(16);
		---- A 1 A_Raise(12);
		---- A 1{
			A_WeaponOffset(0,-6,WOF_ADD);
			A_MuzzleClimb(-0.1,-1.);
		}
		---- AA 1 A_WeaponOffset(0,2,WOF_ADD);
		---- A 1 A_Raise(1);
		wait;

	ready:
		TNT1 A 1 A_WeaponReady(WRF_ALL);
	readyend:
		---- A 0 A_ReadyEnd();
		---- A 0 A_Jump(256,"ready");
	user1:
		---- A 0 A_Jump(256,"altreload");
	user2:
		---- A 0 A_Jump(256,"firemode");
	user3:
		---- A 0 A_MagManager("HDBattery");
		goto readyend;
	user4:
		---- A 0 A_Jump(256,"unload");
	fire:
	altfire:
	hold:
	althold:
	reload:
	altreload:
	firemode:
	unload:
	nope:
		---- A 1{
			A_ClearRefire();
			A_WeaponReady(WRF_NOFIRE);
			if(invoker.msgtimer>0){
				invoker.msgtimer--;
				if(invoker.msgtimer<1)invoker.wepmsg="";
			}
			let p=hdplayerpawn(self);
			if(p){
				p.lastmisc1>>=1;
				p.lastmisc2>>=1;
			}
		}
		---- A 0{
			int inp=getplayerinput(MODINPUT_BUTTONS);
			if(
				inp&BT_ATTACK||
				inp&BT_ALTATTACK||
				inp&BT_RELOAD||
//				inp&BT_ZOOM||
				inp&BT_USER1||
				inp&BT_USER2||
				inp&BT_USER3||
				inp&BT_USER4
			)setweaponstate("nope");
		}
		---- A 0 A_Jump(256,"ready");

	botreload:
		TNT1 A 10;
		TNT1 A 40{
			invoker.initializewepstats(true);
		}goto readyend;
	}
}



// Null weapon for lowering weapon
class NulledWeapon:InventoryFlag{}
class NullWeapon:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.cheatnotweapon
		+nointeraction
		+weapon.noalert
		+inventory.untossable
		+hdweapon.dontnull

		tag "sprinting";
	}
	override inventory CreateTossable(int amt){
		let onr=hdplayerpawn(owner);
		if(onr){
			if(onr.lastweapon)onr.DropInventory(onr.lastweapon);
		}
		return null;
	}
	override double gunmass(){
		return 12;
	}
	override string gethelptext(){
		LocalizeHelp();
		return LWPHELP_ZOOM.."+"..LWPHELP_USE..StringTable.Localize("$NWWH_KICK")
		;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	select0:
		TNT1 A 0{
			A_TakeInventory("PowerFrightener");
			A_SetInventory("NulledWeapon",1);
			A_SetCrosshair(21);
		}
		TNT1 A 0 A_Raise();
		wait;
	deselect0:
		TNT1 A 0 A_SetCrosshair(21);
		TNT1 A 0 A_Lower();
		wait;
	ready:
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 0 A_WeaponBusy(false);
		loop;
	fire:
		TNT1 A 1;
		goto ready;
	}
}


// ------------------------------------------------------------
// Database for spare weapons
// ------------------------------------------------------------
class SpareWeapons:HDPickup{
	array<double> weaponbulk;
	array<string> weapontype;
	array<string> weaponstatus;
	default{
		+nointeraction
		+hdpickup.nevershowinpickupmanager
		-inventory.invbar
		hdpickup.bulk 0;
	}
	override bool isused(){return owner&&owner.player&&!(owner.player.cmd.buttons&BT_ZOOM);}
	double,int getwepbulk(){
		//in encumbrance, have a special check for this actor - add to weapon count
		int i;
		double bulksum;
		for(i=0;i<weaponbulk.size();i++){
			bulksum+=weaponbulk[i];
		}
		return bulksum,i;
	}
	override inventory createtossable(int amt){
		while(weapontype.size()){
			let newwep=hdweapon(spawn(weapontype[0],(owner.pos.xy,owner.pos.z+owner.height*0.6)));
			weapontype.delete(0);

			array<string> wepstat;
			weaponstatus[0].split(wepstat,",");
			for(int i=0;i<wepstat.size();i++){
				newwep.weaponstatus[i]=wepstat[i].toint();
			}
			weaponstatus.delete(0);

			weaponbulk.delete(0);
			newwep.vel+=owner.vel+(frandom(-1,1),frandom(-1,1),frandom(0,2));
			newwep.angle=owner.angle;
			newwep.A_ChangeVelocity(3*cos(pitch),0,3*-sin(pitch),CVF_RELATIVE);
		}
		return null;
	}
	//retrieve the int from one specific slot from one specific weapon index
	clearscope int GetWeaponValue(int wepindex,int statusslot){
		if(weaponstatus.size()<=wepindex)return -1;
		array<string> wepstat;
		string wepstat2="";
		weaponstatus[wepindex].split(wepstat,",");
		return wepstat[statusslot].toint();
	}
	//shortcut for changing values in a stowed weapon
	void ChangeWeaponValue(
		int wepindex,
		int statslot,int newvalue,
		int statslot2=-1,int newvalue2=-1,
		int statslot3=-1,int newvalue3=-1,
		int statslot4=-1,int newvalue4=-1,
		int statslot5=-1,int newvalue5=-1,
		int statslot6=-1,int newvalue6=-1,
		int statslot7=-1,int newvalue7=-1,
		int statslot8=-1,int newvalue8=-1
	){
		if(weaponstatus.size()<=wepindex)return;
		array<string> wepstat;
		string wepstat2="";
		weaponstatus[wepindex].split(wepstat,",");
		for(int i=0;i<wepstat.size();i++){
			if(i)wepstat2=wepstat2..",";
			if(i==statslot)wepstat2=wepstat2..newvalue;
			else if(i==statslot2)wepstat2=wepstat2..newvalue2;
			else if(i==statslot3)wepstat2=wepstat2..newvalue3;
			else if(i==statslot4)wepstat2=wepstat2..newvalue4;
			else if(i==statslot5)wepstat2=wepstat2..newvalue5;
			else if(i==statslot6)wepstat2=wepstat2..newvalue6;
			else if(i==statslot7)wepstat2=wepstat2..newvalue7;
			else if(i==statslot8)wepstat2=wepstat2..newvalue8;
			else wepstat2=wepstat2..wepstat[i];
		}
		weaponstatus[wepindex]=wepstat2;
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	use:
		TNT1 A 0{
			if(!player)return;
			let thwep=hdweapon(player.readyweapon);
			if(
				thwep is "NullWeapon"
				||thwep is "HDFist"
			)return;
			A_GiveInventory("WeaponStashSwitcher");
			let wss=WeaponStashSwitcher(findinventory("WeaponStashSwitcher"));
			wss.thisweapon=thwep;
			A_SelectWeapon("WeaponStashSwitcher");
		}fail;
	}
}
class WeaponStashSwitcher:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.cheatnotweapon
		+nointeraction
	}
	hdweapon thisweapon;
	states{
	spawn:TNT1 A 0;stop;
	ready:
		TNT1 A 1{
			A_WeaponReady(WRF_NOFIRE);
			let sww=SpareWeapons(GiveInventoryType("SpareWeapons"));
			let hdw=invoker.thisweapon;
			if(
				sww
				&&hdw
				&&hdw.addspareweapon(self)
			){
				hdw.getspareweapon(self,reverse:true);
			}
			invoker.thisweapon=null;
		}
		TNT1 A 1 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		wait;
	}
}
extend class HDWeapon{
	//override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	//override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	virtual bool AddSpareWeapon(actor newowner){return false;}
	bool AddSpareWeaponRegular(actor newowner){
		double wbulk=weaponbulk();
		let hdp=hdplayerpawn(newowner);
		if(hdp){
			if(
				(wbulk+hdp.enc)*hdmath.getencumbrancemult()
				>2000
			){
				if(hdp.getage()>10)hdp.A_Log(StringTable.Localize("$WEP_TOOHEAVY"),true);
				return false;
			}
		}
		let mwt=SpareWeapons(newowner.findinventory("SpareWeapons"));
		if(!mwt){
			mwt=SpareWeapons(newowner.giveinventorytype("SpareWeapons"));
			mwt.amount=1;
			mwt.weaponbulk.clear();
			mwt.weapontype.clear();
			mwt.weaponstatus.clear();
		}
		mwt.weaponbulk.insert(0,wbulk);
		mwt.weapontype.insert(0,getclassname());

		string wepstat=""..weaponstatus[0];
		for(int i=1;i<HDWEP_STATUSSLOTS;i++){
			if(!i)wepstat=""..weaponstatus[i];
			else wepstat=wepstat..","..weaponstatus[i];
		}
		mwt.weaponstatus.insert(0,wepstat);

		destroy();
		return true;
	}
	virtual hdweapon GetSpareWeapon(actor newowner,bool reverse=false,bool doselect=true){return null;}
	hdweapon GetSpareWeaponRegular(actor newowner,bool reverse=false,bool doselect=true){
		if(!newowner)return null;
		let mwt=SpareWeapons(newowner.findinventory("SpareWeapons"));
		if(!mwt)return null;

		int getindex;
		if(reverse){
			getindex=mwt.weapontype.size();
			let checkclassname=getclassname();
			for(int i=getindex-1;i>=0;i--){
				if(mwt.weapontype[i]==checkclassname){
					getindex=i;
					break;
				}
				else if(!i)return null;
			}
		}else{
			getindex=mwt.weapontype.find(getclassname());
			if(getindex==mwt.weapontype.size())return null;
		}

		//apply each of the items at getindex and delete the entry from the spares
		let newwep=hdweapon(newowner.giveinventorytype(getclassname()));
		if(!newwep)return null;
		newwep.bdontdefaultconfigure=true;

		array<string> wepstat;
		mwt.weaponstatus[getindex].split(wepstat,",");
		for(int i=0;i<wepstat.size();i++){
			newwep.weaponstatus[i]=wepstat[i].toint();
		}

		if(doselect)HDWeaponSelector.Select(newowner,newwep.getclassname(),max(4,int(newwep.gunmass())));

		mwt.weaponstatus.delete(getindex);
		mwt.weaponbulk.delete(getindex);
		mwt.weapontype.delete(getindex);

		return newwep;
	}
	static int GetActualAmount(actor caller,name wepclass){
		let www=hdweapon(caller.findinventory(wepclass));
		if(!www)return 0;
		int wepcount=max(1,www.amount);
		let spw=spareweapons(caller.findinventory("SpareWeapons"));
		if(!spw)return wepcount;
		for(int i=0;i<spw.weapontype.size();i++){
			if(spw.weapontype[i]==wepclass)wepcount++;
		}
		return wepcount;
	}
}
enum HDWepConsts{
	HDWEP_FLAGS=0,
	HDWEP_STATUSSLOTS=32,
	HDWEP_MODFLAGS=HDWEP_STATUSSLOTS-1,
	HDWEP_MMAXRETICLESUFFIX=9999, //+HDCONST_RETICLEPREFIX must add up to 8 characters or less
}



//for setting the reflex reticle
const HDCONST_RETICLEPREFIX="rret";
extend class HDHandlers{
	void SetReflexReticle(hdplayerpawn ppp,int which){
		if(!ppp.player)return;
		let www=hdweapon(ppp.player.readyweapon);
		if(www){
			if(which>9999){
				string err="ERROR: reticle number must be within range 0 through "..HDWEP_MMAXRETICLESUFFIX..". Treating "..which.." as ";
				do{which/=10;}while(which>HDWEP_MMAXRETICLESUFFIX);
				err=err..which.." instead.";
				console.printf(err);
			}
			www.SetReflexReticle(which);
		}
	}
}
extend class HDWeapon{
	virtual void SetReflexReticle(int which){}
	action void A_CheckDefaultReflexReticle(int slot){
		if(
			!player
			||invoker.weaponstatus[slot]>=0
		)return;

		string input=getdefaultcvar(player);
		int indof=input.indexof(invoker.refid);
		input=input.mid(indof,input.indexof(",",indof)-indof);
		int xhdot=invoker.getloadoutvar(input,"dot",3);
		if(xhdot>=0){
			invoker.weaponstatus[slot]=xhdot;
			return;
		}

		invoker.SetReflexReticle(cvar.getcvar("hd_crosshair",player).getint());
	}
}



//defaults for weapon helptext
const WEPHELP_BTCOL="\cy";
const WEPHELP_RGCOL="\cj";
const WEPHELP_FIRE=WEPHELP_BTCOL.."Fire"..WEPHELP_RGCOL;
const WEPHELP_ALTFIRE=WEPHELP_BTCOL.."Altfire"..WEPHELP_RGCOL;
const WEPHELP_RELOAD=WEPHELP_BTCOL.."Reload"..WEPHELP_RGCOL;
const WEPHELP_ZOOM=WEPHELP_BTCOL.."Zoom"..WEPHELP_RGCOL;
const WEPHELP_ALTRELOAD=WEPHELP_BTCOL.."Alt.Reload"..WEPHELP_RGCOL;
const WEPHELP_FIREMODE=WEPHELP_BTCOL.."Firemode"..WEPHELP_RGCOL;
const WEPHELP_USER3=WEPHELP_BTCOL.."User3"..WEPHELP_RGCOL;
const WEPHELP_UNLOAD=WEPHELP_BTCOL.."Unload"..WEPHELP_RGCOL;

const WEPHELP_SPEED=WEPHELP_BTCOL.."Speed"..WEPHELP_RGCOL;
const WEPHELP_UPDOWN=WEPHELP_BTCOL.."Mouselook"..WEPHELP_RGCOL;
const WEPHELP_USE=WEPHELP_BTCOL.."Use"..WEPHELP_RGCOL;
const WEPHELP_DROP=WEPHELP_BTCOL.."Drop"..WEPHELP_RGCOL;
const WEPHELP_DROPONE=WEPHELP_BTCOL.."Drop One"..WEPHELP_RGCOL;

const WEPHELP_FIRESHOOT=WEPHELP_FIRE.."  Shoot\n";
const WEPHELP_RELOADRELOAD=WEPHELP_RELOAD.."  Reload\n";
const WEPHELP_UNLOADUNLOAD=WEPHELP_UNLOAD.."  Unload\n";
const WEPHELP_MAGMANAGER=WEPHELP_USER3.."  Magazine Manager\n";
const WEPHELP_INJECTOR=WEPHELP_FIRE.."  Use on yourself\n"..WEPHELP_ALTFIRE.."  Use on someone else";



