// ------------------------------------------------------------
// Some items common to multiple cell weapons
// ------------------------------------------------------------
class HDCellWeapon:HDWeapon{
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory("HDBattery",1);
		}
	}
	default{
		hdweapon.ammo1 "HDBattery",1;
	}
}


// ------------------------------------------------------------
// Chainsaw
// ------------------------------------------------------------
const LUMBERJACKDRAIN=1023;
class Lumberjack:HDCellWeapon replaces Chainsaw{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Lumberjack"
		//$Sprite "CSAWA0"
		+hdweapon.fitsinbackpack
		weapon.selectionorder 90;
		weapon.slotnumber 1;
		weapon.slotpriority 1;
		weapon.bobstyle "Alpha";
		weapon.bobrangex 0.3;
		weapon.bobrangey 1.4;
		weapon.bobspeed 2.1;
		weapon.kickback 2;
		scale 0.4;
		hdweapon.barrelsize 26,1,2;
		hdweapon.refid HDLD_CHAINSW;
		tag "$TAG_CHAINSAW";
		obituary "$OB_MPCHAINSAW";
		inventory.pickupmessage "$PICKUP_CHAINSAW";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override string,double getpickupsprite(){return "CSAWA0",0.7;}
	int walldamagemeter;
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawbattery(-54,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HDBattery"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(!hdw.weaponstatus[1])sb.drawstring(
			sb.mamountfont,"00000",(-16,-9),sb.DI_TEXT_ALIGN_RIGHT|
			sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);else if(hdw.weaponstatus[1]>0)sb.drawwepnum(hdw.weaponstatus[1],20);
		if(walldamagemeter>0)sb.drawwepnum(walldamagemeter,100,posy:-9);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$SAWWPH_CUT")
		..LWPHELP_RELOADRELOAD
		..LWPHELP_UNLOADUNLOAD
		;
	}
	override double gunmass(){
		return 5+(weaponstatus[CSAWS_BATTERY]<0?0:1);
	}
	override double weaponbulk(){
		return 100+(weaponstatus[CSAWS_BATTERY]>=0?ENC_BATTERY_LOADED:0);
	}
	override void consolidate(){
		CheckBFGCharge(CSAWS_BATTERY);
	}
	action void A_HDSaw(){
		A_WeaponReady(WRF_NONE);
		int battery=invoker.weaponstatus[CSAWS_BATTERY];
		int inertia=invoker.weaponstatus[CSAWS_INERTIA];
		if(inertia<12)invoker.weaponstatus[CSAWS_INERTIA]++;

		int drainprob=LUMBERJACKDRAIN;
		int dmg=0;
		name sawpuff="HDSawPuff";
		if((inertia>11)&&(battery>random(5,8))){
			dmg=random(5,16);
			A_MuzzleClimb(
				randompick(-1,1)*frandom(0.2,0.3),
				randompick(-1,1)*frandom(0.2,0.4)
			);
		}else if((inertia>6)&&(battery>random(2,4))){
			dmg=random(3,12);
			A_SetTics(2);
			A_MuzzleClimb(
				randompick(-1,1)*frandom(0.1,0.3),
				randompick(-1,1)*frandom(0.1,0.4)
			);
		}else if((inertia>1)&&(battery>random(1,4))){
			drainprob*=3/2;
			dmg=random(1,8);
			A_SetTics(random(2,4));
			A_MuzzleClimb(
				randompick(-1,1)*frandom(0.05,0.6),
				randompick(-1,1)*frandom(0.05,0.2)
			);
		}else{
			drainprob*=4;
			A_StartSound("weapons/sawidle",CHAN_WEAPON);
			sawpuff="HDSawPufShitty";
			A_SetTics(random(3,6));
			A_MuzzleClimb(
				frandom(-0.2,0.2),
				frandom(-0.2,0.2)
			);
		}
		if(battery>0&&!random(0,drainprob))invoker.weaponstatus[CSAWS_BATTERY]--;

		actor victim=null;
		int finaldmg=0;
		vector3 puffpos=pos+gunpos();
		flinetracedata flt;
		if(dmg>0){
			A_AlertMonsters();

			//determine angle
			double shootangle=angle;
			double shootpitch=pitch;
			vector3 shootpos=(0,0,height*0.8);
			let hdp=hdplayerpawn(self);
			if(hdp){
				shootangle=hdp.gunangle;
				shootpitch=hdp.gunpitch;
				shootpos=gunpos((0,0,-4));
			}

			//create the line
			linetrace(
				shootangle,
				invoker.barrellength+2,
				shootpitch,
				flags:TRF_NOSKY|TRF_ABSOFFSET,
				offsetz:shootpos.z,
				offsetforward:shootpos.x,
				offsetside:shootpos.y,
				data:flt
			);

			if(flt.hittype!=Trace_HitNone){
				A_SprayDecal("BulletChip",invoker.barrellength+2,gunpos(),flt.hitdir);
				A_StartSound("weapons/sawhit",9);
			}
			A_StartSound("weapons/sawfull",CHAN_WEAPON);

			if(flt.hitactor){
				victim=flt.hitactor;
				puffpos=flt.hitlocation+flt.hitdir*min(victim.radius,frandom(2,5));
				invoker.setxyz(flt.hitlocation);
				finaldmg=victim.damagemobj(invoker,self,dmg,"cutting");
			}else if(flt.hittype!=Trace_HitNone){
				puffpos=flt.hitlocation-flt.hitdir*4;
				if(dmg>6){
					bool didit;double didwhat;
					[didit,didwhat]=doordestroyer.destroydoor(
						self,dmg*30,dmg*0.01,48,height-20,
						angle,pitch
					);
					if(didit||!didwhat)invoker.walldamagemeter=0;else
					invoker.walldamagemeter=int(clamp(1-didwhat,0,1)*100);
				}
			}
		}

		if(
			!!victim
			&&(
				finaldmg>0
				||victim.bcorpse
			)
		){
			invoker.weaponstatus[0]|=CSAWF_CHOPPINGFLESH;
			if(victim.bnoblood)spawn("BulletPuffMedium",puffpos,ALLOW_REPLACE);
			else{
				int pdmg=7;
				array<HDDamageHandler> handlers;
				HDDamageHandler.GetHandlers(victim,handlers);
				for(int i=0;i<handlers.Size();i++){
					let hhh=handlers[i];
					if(hhh&&hhh.owner==victim)pdmg=hhh.HandleDamage(
						pdmg,
						"cutting",
						0,
						invoker,
						self
					);
				}

				if(pdmg<1){
					spawn("BulletPuffMedium",puffpos,ALLOW_REPLACE);
					return;
				}else{
					actor vb=spawn(victim.bloodtype,puffpos,ALLOW_REPLACE);
					vb.vel=victim.vel-flt.hitdir;
					vb.translation=victim.bloodtranslation;
				}

				double ddd=frandom(1,pdmg);
				double www=frandom(4,2.*pdmg);
				double maxdepth=max(40.,victim.radius*5.);
				let hdblw=hdbleedingwound.inflict(
					victim,ddd,www,source:target,damagetype:"cutting",hitlocation:flt.hitlocation
				);
				if(
					!!hdblw
					&&hdblw.depth>maxdepth
				){
					let extrawidth=hdblw.depth-maxdepth;
					hdblw.depth=maxdepth;
					hdblw.width+=extrawidth*frandom(0.6,1);
				}


				if(hdmobbase(victim)){
					hdmobbase(victim).bodydamage+=int(max(ddd,www));
					hdmobbase(victim).stunned+=(pdmg<<2);
				}
			}
		}else if(
			dmg>0
			&&flt.hittype!=Trace_HitNone
		){
			spawn("FragPuff",puffpos,ALLOW_REPLACE);
			if(
				invoker.weaponstatus[CSAWS_BATTERY]>0
				&&!random(0,LUMBERJACKDRAIN*3)
			)invoker.weaponstatus[CSAWS_BATTERY]--;
			if(invoker.weaponstatus[0]&CSAWF_CHOPPINGFLESH){
				invoker.weaponstatus[0]&=~CSAWF_CHOPPINGFLESH;
				let tgt=HDPlayerPawn(self);
				if(tgt){
					tgt.muzzleclimb1.x+=random(-30,10);
					tgt.muzzleclimb1.y+=random(-10,6);
				}
				A_Recoil(random(-1,2));
				damagemobj(invoker,self,1,"cutting");
			}
		}
	}
	states{
	ready:
		BEVG C 1{
			invoker.weaponstatus[0]&=~CSAWF_CHOPPINGFLESH;
			invoker.walldamagemeter=0;
			if(invoker.weaponstatus[CSAWS_INERTIA]>0)setweaponstate("ready2");
			else A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
		}goto readyend;
	ready2:
		BEVG CD 3{
			if(invoker.weaponstatus[CSAWS_INERTIA]>0)invoker.weaponstatus[CSAWS_INERTIA]--;
			if((invoker.weaponstatus[CSAWS_INERTIA]>4)&&(invoker.weaponstatus[CSAWS_BATTERY]>4)){
				A_SetTics(2);
				A_StartSound("weapons/sawfull",CHAN_WEAPON);
			}else if((invoker.weaponstatus[CSAWS_INERTIA]>1)&&(invoker.weaponstatus[CSAWS_BATTERY]>2)){
				A_StartSound("weapons/sawidle",CHAN_WEAPON);
			}else{
				A_SetTics(random(2,4));
				A_StartSound("weapons/sawidle",CHAN_WEAPON);
			}
			A_WeaponReady(WRF_NOSECONDARY);
		}goto readyend;
	select0:
		BEVG A 0{invoker.weaponstatus[CSAWS_INERTIA]=0;}
		goto select0big;
	deselect0:
		BEVG A 0;
		goto deselect0big;
	hold:
		BEVG A 0 A_JumpIf(invoker.weaponstatus[CSAWS_BATTERY]>0,"saw");
		goto nope;
	fire:
		BEVG C 2;
		BEVG C 4 A_JumpIf(invoker.weaponstatus[CSAWS_BATTERY]>0,"saw");
		goto nope;
	saw:
		BEVG AB 1 A_HDSaw();
		BEVG B 0 A_Refire();
		goto readyend;

	reload:
		BEVG C 0{
			if(
				invoker.weaponstatus[CSAWS_BATTERY]>=20
				||!countinv("HDBattery")
			){return resolvestate("nope");}
			invoker.weaponstatus[0]&=~CSAWF_JUSTUNLOAD;
			return resolvestate("unmag");
		}

	user4:
	unload:
		BEVG C 0{
			if(invoker.weaponstatus[CSAWS_BATTERY]<0){
				return resolvestate("nope");
			}invoker.weaponstatus[0]|=CSAWF_JUSTUNLOAD;return resolvestate(null);
		}
	unmag:
		BEVG A 1 offset(0,33);
		BEVG A 1 offset(0,35);
		BEVG A 1 offset(0,37);
		BEVG A 1 offset(0,39);
		BEVG A 2 offset(0,44);
		BEVG A 2 offset(0,52);
		BEVG A 3 offset(2,62);
		BEVG A 4 offset(4,74);
		BEVG A 7 offset(6,78)A_StartSound("weapons/csawopen",8);
		BEVG A 0{
			A_StartSound("weapons/csawload",8,CHANF_OVERLAP);
			if(
				!PressingUnload()&&!PressingReload()
			){
				setweaponstate("dropmag");
			}else setweaponstate("pocketmag");
		}
	dropmag:
		BEVG A 0{
			if(invoker.weaponstatus[CSAWS_BATTERY]>=0){
				HDMagAmmo.SpawnMag(self,"HDBattery",invoker.weaponstatus[CSAWS_BATTERY]);
			}
			invoker.weaponstatus[CSAWS_BATTERY]=-1;
		}goto magout;
	pocketmag:
		BEVG A 6 offset(7,80){
			if(invoker.weaponstatus[CSAWS_BATTERY]>=0){
				HDMagAmmo.GiveMag(self,"HDBattery",invoker.weaponstatus[CSAWS_BATTERY]);
				A_StartSound("weapons/pocket",9);
				A_MuzzleClimb(
					randompick(-1,1)*frandom(-0.3,-1.2),
					randompick(-1,1)*frandom(0.3,1.8)
				);
			}
			invoker.weaponstatus[CSAWS_BATTERY]=-1;
		}
		BEVG A 7 offset(6,81) A_StartSound("weapons/pocket",9);
		goto magout;

	magout:
		BEVG A 0 A_JumpIf(invoker.weaponstatus[0]&CSAWF_JUSTUNLOAD,"reloadend");
	loadmag:
		BEVG A 4 offset(7,79) A_MuzzleClimb(
			randompick(-1,1)*frandom(-0.3,-1.2),
			randompick(-1,1)*frandom(0.3,0.8)
		);
		BEVG A 2 offset(6,78) A_StartSound("weapons/pocket",9);
		BEVG AA 5 offset(5,76) A_MuzzleClimb(
			randompick(-1,1)*frandom(-0.3,-1.2),
			randompick(-1,1)*frandom(0.3,0.8)
		);
		BEVG A 0{
			let mmm=HDMagAmmo(findinventory("HDBattery"));
			if(mmm)invoker.weaponstatus[CSAWS_BATTERY]=mmm.TakeMag(true);
		}
	reloadend:
		BEVG A 6 offset(5,72);
		BEVG A 5 offset(4,74)A_StartSound("weapons/csawclose",8);
		BEVG A 4 offset(2,62);
		BEVG A 3 offset(0,52);
		BEVG A 4 offset(0,44);
		BEVG A 1 offset(0,37);
		BEVG A 1 offset(0,35);
		BEVG C 1 offset(0,33);
		goto ready;

	user3:
		BEVG A 0 A_MagManager("HDBattery");
		goto ready;

	spawn:
		CSAW A -1;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[CSAWS_BATTERY]=20;
	}
}
enum lumberstatus{
	CSAWF_JUSTUNLOAD=1,
	CSAWF_CHOPPINGFLESH=2,

	CSAWS_FLAGS=0,
	CSAWS_BATTERY=1,
	CSAWS_INERTIA=2,
};



class HDSawPuffShitty:IdleDummy{
	states{
	spawn:
	death:
		TNT1 A 10 A_StartSound("weapons/csawtouch",volume:0.4);
		stop;
	xdeath:
		TNT1 A 10 A_StartSound("weapons/csawbleh",volume:0.4);
		stop;
	}
}


