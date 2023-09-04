// ------------------------------------------------------------
// Brontornis Cannon
// ------------------------------------------------------------
class TerrorSabotPiece:HDDebris{
	default{
		xscale 1;yscale 2.2;height 2;radius 2;
		translation "ice";
		bouncesound "misc/casing2";
	}
	states{
	spawn:
		TNT1 A 0 nodelay{
			int blh=random(20,35);
			A_ChangeVelocity(cos(pitch)*blh,frandom(-1,1),-sin(pitch)*blh,CVF_RELATIVE);
		}
	spawn2:
		RBRS A 2{angle+=45;}
		loop;
	death:
		---- A -1;
		stop;
	}
}
class TerrorCasing:HDDebris{
	default{
		scale 0.3;height 4;radius 4;bouncefactor 0.6;
		bouncesound "misc/casing4";
	}
	states{
	spawn:
		BSHX A 0 nodelay A_ChangeVelocity(cos(pitch),0,sin(-pitch)+1,CVF_RELATIVE);
	spawn2:
		BSHX ACBC random(1,3){angle+=45;}
		loop;
	death:
		---- A -1{
			A_FaceMovementDirection();
			angle+=90;
		}
		stop;
	}
}




class BrontornisRound:HDAmmo{
	default{
		+inventory.ignoreskill
		inventory.pickupmessage "$PICKUP_BRONTOROUND";
		tag "$TAG_BRONTOSHELL";
		inventory.icon "BROCA0";
		hdpickup.refid HDLD_BROBOLT;
		hdpickup.bulk ENC_BRONTOSHELL;
		scale 0.3;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("Brontornis");
	}
	states{
	spawn:
		BROC A -1;
		stop;
	}
}


class Brontornis:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Brontornis"
		//$Sprite "BLSTA0"

		+hdweapon.fitsinbackpack
		weapon.selectionorder 60;
		weapon.slotnumber 7;
		weapon.slotpriority 2;
		weapon.kickback 100;
		weapon.bobrangex 0.21;
		weapon.bobrangey 0.86;
		scale 0.6;
		inventory.pickupmessage "$PICKUP_BRONTO";
		obituary "$OB_BRONTO";
		hdweapon.barrelsize 24,1,2;
		tag "$TAG_BRONTO";
		hdweapon.refid HDLD_BRONTO;

		hdweapon.ammo1 "BrontornisRound",1;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void tick(){
		super.tick();
		drainheat(BRONS_HEAT,12);
		buntossable=hd_instagib;
	}
	override void beginplay(){
		super.beginplay();
		weaponstatus[BRONS_DOT]=3;
	}
	override double gunmass(){
		double amt=weaponstatus[BRONS_CHAMBER];
		return 6+amt*amt;
	}
	override double weaponbulk(){
		return 75+(weaponstatus[BRONS_CHAMBER]>1?ENC_BRONTOSHELLLOADED:0);
	}
	override string,double getpickupsprite(){return "BLSTA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("BROCA0",(-48,-10),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.7,0.7));
			sb.drawnum(hpl.countinv("BrontornisRound"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[BRONS_CHAMBER]>1)sb.drawrect(-21,-13,5,3);
		sb.drawwepnum(
			hpl.countinv("BrontornisRound"),
			(HDCONST_MAXPOCKETSPACE/ENC_BRONTOSHELL)
		);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_RELOADRELOAD
		..LWPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		sb.drawimage(
			"brfrntsit",(0,0)+bob*1.14,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		if(scopeview){
			double degree=6.;
			int scaledwidth=50;
			int scaledyoffset=(scaledwidth>>1)+12;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(
				bob.x-(scaledwidth>>1),bob.y+scaledyoffset-(scaledwidth>>1),
				scaledwidth,scaledwidth,
				sb.DI_SCREEN_CENTER
			);

			sb.fill(color(255,0,0,0),
				bob.x-27,scaledyoffset+bob.y-27,
				54,54,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);

			texman.setcameratotexture(hpc,"HDXCAM_BRON",degree);
			let cam=texman.CheckForTexture("HDXCAM_BRON",TexMan.Type_Any);
			double camSize=texman.GetSize(cam);
			sb.DrawCircle(cam,(0,scaledyoffset)+bob*5,.085,usePixelRatio:true);


			screen.SetClipRect(cx,cy,cw,ch);

			sb.drawimage(
				"brret",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			sb.drawimage(
				"brontoscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
		}
	}
	override void SetReflexReticle(int which){weaponstatus[BRONS_DOT]=which;}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory("BrontornisRound",1);
		}
	}
	states{
	select0:
		BLSG A 0;
		goto select0small;
	deselect0:
		BLSG A 0;
		goto deselect0small;
	ready:
		BLSG A 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	fire:
		BLSG A 1 offset(0,34){
			if(invoker.weaponstatus[BRONS_CHAMBER]<2){
				setweaponstate("nope");
				return;
			}
			A_GunFlash();
			A_StartSound("weapons/bronto",CHAN_WEAPON);
			A_StartSound("weapons/bronto",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("weapons/bronto2",CHAN_WEAPON,CHANF_OVERLAP);
			let tb=HDBulletActor.FireBullet(self,"HDB_bronto");
			invoker.weaponstatus[BRONS_CHAMBER]=1;
			invoker.weaponstatus[BRONS_HEAT]+=32;
		}
		BLSG B 2;
		BLSG B 0 A_JumpIf(
			hd_instagib
			&&player
			&&player.bot
		,"reload");
		goto nope;
	flash:
		BLSF A 1 bright{
			A_AlertMonsters();
			HDFlashAlpha(0,true);
			A_Light1();

			IsMoving.Give(self,gunbraced()?2:7);
			if(
				!binvulnerable
				&&(
					floorz<pos.z
					||IsMoving.Count(self)>6
				)
			){
				givebody(max(0,11-health));
				damagemobj(invoker,self,10,"bashing");
				IsMoving.Give(self,5);
			}
		}
		BLSF B 1{
			A_ZoomRecoil(0.5);
			A_Light1();
		}
		TNT1 A 1 A_Light0();
		TNT1 A 0{
			bool gb=gunbraced();
			hdplayerpawn(self).gunbraced=false;
			double recoilside=randompick(-1,1);
			double pushforce=frandom(5,8)*player.crouchfactor;
			if(
				gb
				&&player.onground
				&&pressingzoom()
			){
				A_ChangeVelocity(
					cos(pitch)*-pushforce,0,
					sin(pitch)*pushforce,
					CVF_RELATIVE
				);
				A_MuzzleClimb(
					recoilside*2,-4.,
					recoilside*1,-2.,
					recoilside*0.4,-1.,
					recoilside*0.2,-0.4,
					wepdot:true
				);
			}else{
				pushforce*=frandom(0.2,0.3);
				A_ChangeVelocity(
					cos(pitch)*-pushforce,0,
					sin(pitch)*pushforce,
					CVF_RELATIVE
				);
				A_MuzzleClimb(
					recoilside*5,-frandom(5.,8.),
					recoilside*4,-frandom(3.,6.),
					recoilside*3,-frandom(2.,4.),
					recoilside*2,-frandom(1.,2.),
					wepdot:true
				);
			}
		}
		stop;
	reload:
		BLSG A 0{
			invoker.weaponstatus[0]&=~BRONF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[BRONS_CHAMBER]>1
				||(
					!hd_instagib
					&&!countinv("BrontornisRound")
				)
			)setweaponstate("nope");
		}goto unloadstart;
	unload:
		BLSG A 0{
			invoker.weaponstatus[0]|=BRONF_JUSTUNLOAD;
		}goto unloadstart;

	unloadstart:
		BLSG A 1;
		BLSG CCC 2 A_MuzzleClimb(
			-frandom(0.5,0.6),frandom(0.5,0.6),
			-frandom(0.5,0.6),frandom(0.5,0.6)
		);
		BLSG C 1 offset(1,34);
		BLSG C 1 offset(2,44) A_SetTics(invoker.weaponstatus[BRONS_HEAT]>>3);
		BLSG C 1 offset(3,42) A_StartSound("weapons/brontoopen",8,CHANF_OVERLAP);
		BLSG D 3 offset(4,34){
			int chm=invoker.weaponstatus[BRONS_CHAMBER];
			int bheat=invoker.weaponstatus[BRONS_HEAT];
			invoker.weaponstatus[BRONS_CHAMBER]=0;
			if(chm<1){
				A_SetTics(3+max(0,bheat-20));
				return;
			}

			A_StartSound("weapons/brontoload",8,CHANF_OVERLAP);
			if(chm>1){
				double aaa=angle;
				bool id=(Wads.CheckNumForName("id",0)!=-1);
				if(id)aaa+=5;else aaa-=5;
				let bbr=spawn("BrontornisRound",
					pos+(
						cos(pitch)*(
							cos(aaa)*10,
							sin(aaa)*10
						),
						height*0.8-sin(pitch)*8
					),ALLOW_REPLACE
				);
				bbr.translation=translation;
				if(id)aaa=angle+50;else aaa=angle-50;
				bbr.vel=(vel.xy+(cos(aaa),sin(aaa)),vel.z+1.);
				if(!A_JumpIfInventory("BrontornisRound",0,"null"))GrabThinker.Grab(self,bbr,5);
			}else if(chm==1){
				A_StartSound("weapons/brontopop",8,CHANF_OVERLAP,
					volume:0.04*bheat
				);
				A_SpawnItemEx("TerrorCasing",
					cos(pitch)*4,0,height*0.8-sin(pitch)*4,
					vel.x,vel.y,vel.z+min(0.12*bheat,4),
					frandom(-1,1),SXF_ABSOLUTEMOMENTUM|
					SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH|
					SXF_TRANSFERTRANSLATION
				);
			}
		}
		BLSG E 1 offset(0,36);
		BLSG E 1 offset(0,38){
			if(!(invoker.weaponstatus[0]&BRONF_JUSTUNLOAD))A_StartSound("weapons/pocket",9,CHANF_OVERLAP);
		}
		BLSG E 1 offset(0,42);
		BLSG E 1 offset(0,48);
		BLSG E 1 offset(0,54);
		BLSG E 1 offset(0,62);
		TNT1 A 3;
		TNT1 A 8 A_JumpIf(invoker.weaponstatus[0]&BRONF_JUSTUNLOAD,1);
		TNT1 A 10{
			if(invoker.weaponstatus[0]&BRONF_JUSTUNLOAD)return;
			invoker.weaponstatus[BRONS_CHAMBER]=2;
			A_TakeInventory("BrontornisRound",1,TIF_NOTAKEINFINITE);
			A_StartSound("weapons/brontoload",8,CHANF_OVERLAP);
		}
		BLSG B 1 offset(0,67);
		BLSG B 1 offset(0,60);
		BLSG B 1 offset(0,56);
		BLSG B 1 offset(0,53);
		BLSG B 1 offset(0,52);
	reloadend:
		BLSG B 1 offset(0,48);
		BLSG B 1 offset(0,44);
		BLSG B 1 offset(0,36);
		BLSG B 1 offset(0,33) A_StartSound("weapons/brontoclose",8,CHANF_OVERLAP);
		BLSG BA 2 offset(0,34);
		BLSG A 0 A_JumpIf(pressingunload(),"nope");
		goto ready;

	spawn:
		BLST A -1;
		stop;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[BRONS_CHAMBER]=2;
		if(!idfa){
			weaponstatus[0]=0;
			weaponstatus[BRONS_HEAT]=0;
			weaponstatus[BRONS_DOT]=4;
		}
	}
	override void loadoutconfigure(string input){
		int xhdot=getloadoutvar(input,"dot",3);
		if(xhdot>=0)weaponstatus[BRONS_DOT]=xhdot;
	}
}
enum brontostatus{
	BRONF_JUSTUNLOAD=1,

	BRONS_STATUS=0,
	BRONS_CHAMBER=1,
	BRONS_HEAT=2,
	BRONS_DOT=3,
};



//map pickup
class BrontornisSpawner:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_SpawnItemEx("BrontornisRound",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BrontornisRound",3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BrontornisRound",1,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BrontornisRound",-3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("Brontornis",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		}stop;
	}
}


//set stuff for instagib mode
extend class HDPlayerPawn{
	void PurgeInstagibGear(){
		if(!hd_instagib)return;

		let prw=player.readyweapon;
		bool doswitch=
			!Brontornis(prw)
			&&!NullWeapon(prw)
			&&!HDFist(prw)
			&&!HDWoundFixer(prw)
			&&!HDCapFlag(prw)
			&&(
				!prw
				||!prw.bwimpy_weapon
			)
		;

		array<inventory> iii;iii.clear();
		inventory item=inv;
		for(inventory item=inv;item!=null;item=!item?null:item.inv){
			if(
				(
					HDDamageHandler(item)
					&&!HDDrug(item)
				)||(
					weapon(item)
					&&(
						!weapon(item).bwimpy_weapon
						||(
							DERPUsable(item)
							||HERPUsable(item)
						)
					)
					&&!HDWoundFixer(item)
					&&!NullWeapon(item)
					&&!HDFist(item)
					&&!Brontornis(item)
				)
			){
				iii.push(item);
			}
			if(HDFragGrenadeAmmo(item))item.amount=min(item.amount,3);
		}
		for(int i=0;i<iii.size();i++){
			iii[i].destroy();
		}
		if(!countinv("Brontornis")){
			A_GiveInventory("Brontornis");
			doswitch=true;
		}
		if(doswitch)A_SelectWeapon("Brontornis");

		A_TakeInventory("SpareWeapons");
		PurgeUselessAmmo(true);
	}
}
