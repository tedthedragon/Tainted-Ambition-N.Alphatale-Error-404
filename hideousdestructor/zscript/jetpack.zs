//-------------------------------------------------
// We have no room for parachutes.
//-------------------------------------------------
class HDJetPack:HDCellWeapon{
	default{
		tag "$TAG_JETPACK";
		hdweapon.barrelsize 22,24,14;
		inventory.pickupmessage "$PICKUP_JETPACK";
		+inventory.invbar
		+hdweapon.dontnull
		+weapon.wimpy_weapon
		hdweapon.refid HDLD_JETPACK;
	}
	override double weaponbulk(){
		return 500+(weaponstatus[JETPACKS_BATTERY]>=0?ENC_BATTERY_LOADED:0);
	}
	override bool IsBeingWorn(){return owner&&owner.player&&owner.player.readyweapon==self;}
	override inventory CreateTossable(int amt){
		if(!player||player.readyweapon!=self)return super.createtossable(amount);

		HDArmour.ArmourChangeEffect(owner);
		return super.createtossable(amt);
	}
	actor pods[4];
	action void A_Pods(){
		bool podson=invoker.weaponstatus[0]&JETPACKF_ON;
		for(int i=0;i<4;i++){
			if(!invoker.pods[i]){
				invoker.pods[i]=spawn("HoverPod",pos);
				invoker.pods[i].angle=90*i+45;
				invoker.pods[i].master=self;
			}
			if(podson)invoker.pods[i].A_StartSound("jetpack/fwoosh",CHAN_AUTO,CHANF_DEFAULT,0.2,pitch:1.6+0.2*(level.time&(1|2)));
		}
		if(podson){
			if(invoker.weaponstatus[JETPACKS_BATTERYCOUNTER]>JETPACK_COUNTERMAX){
				invoker.weaponstatus[JETPACKS_BATTERY]--;
				invoker.weaponstatus[JETPACKS_BATTERYCOUNTER]=0;
			}else invoker.weaponstatus[JETPACKS_BATTERYCOUNTER]++;
		}
		if(invoker.weaponstatus[JETPACKS_BATTERY]<1)invoker.weaponstatus[0]&=~JETPACKF_ON;

		if(
			hdplayerpawn(self)
			&&hdplayerpawn(self).fallroll
		)DropInventory(invoker);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$JPWH_FIRE")
		..LWPHELP_ALTFIRE..StringTable.Localize("$JPWH_ALTFIRE")
		..LWPHELP_FIREMODE..StringTable.Localize("$JPWH_FMODE")
		..LWPHELP_RELOADRELOAD
		..LWPHELP_UNLOADUNLOAD
		;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawbattery(-54,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HDBattery"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		if(!hdw.weaponstatus[1])sb.drawstring(
			sb.mamountfont,"00000",(-16,-9),sb.DI_TEXT_ALIGN_RIGHT|
			sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);else if(hdw.weaponstatus[1]>0)sb.drawwepnum(hdw.weaponstatus[1],20);

		string velmsg=StringTable.Localize("$JPVELOCITY");
		if(hd_debug)velmsg=velmsg..owner.vel.z;
		else velmsg=velmsg..owner.vel.z*HDCONST_MPSTODUPT..StringTable.Localize("$JPVELOCITYMS");
		sb.drawstring(sb.pnewsmallfont,velmsg,
			(0,24),sb.DI_TEXT_ALIGN_LEFT|sb.DI_SCREEN_LEFT_TOP,
			abs(owner.vel.z)>10?font.CR_RED:font.CR_WHITE
		);
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[JETPACKS_BATTERY]=20;
		weaponstatus[JETPACKS_BATTERYCOUNTER]=0;
	}
	override void actualpickup(actor user){
		super.actualpickup(user);
		//put on the jetpack right away
		if(
			user.player&&user.player.cmd.buttons&BT_USE
			&&(
				!HDWeapon(user.player.readyweapon)
				||!HDWeapon(user.player.readyweapon).isbeingworn()
			)
		){
			inventory slf=user.findinventory(getclass());
			user.UseInventory(slf);
		}
	}
	states{
	spawn:
		JPAK A -1;
		stop;
	pods:
		TNT1 A 1 A_Pods();
		wait;
	select0:
		TNT1 A 12{
			invoker.weaponstatus[0]&=~JETPACKF_ON;
			A_Overlay(10,"pods");
			A_StartSound("jetpack/wear",CHAN_WEAPON);
		}
		goto super::select0;
	deselect0:
		TNT1 A 14{
			invoker.weaponstatus[0]&=~JETPACKF_ON;
			A_StartSound("jetpack/wear",CHAN_WEAPON);
		}
		goto super::deselect0;
	ready:
		TNT1 A 1 A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
		goto readyend;

	user4:
	unload:
		TNT1 A 20{
			int bat=invoker.weaponstatus[JETPACKS_BATTERY];
			if(bat<0){
				setweaponstate("nope");
				return;
			}
			if(pressingunload())invoker.weaponstatus[0]|=JETPACKF_UNLOADONLY;
			else invoker.weaponstatus[0]&=~JETPACKF_UNLOADONLY;

			HDMagAmmo.SpawnMag(self,"HDBattery",bat);
			invoker.weaponstatus[JETPACKS_BATTERY]=-1;
		}
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&JETPACKF_UNLOADONLY,"nope");
	reload:
		TNT1 A 20 A_JumpIf(invoker.weaponstatus[JETPACKS_BATTERY]>=0,"unload");
		TNT1 A 10{
			let mmm=hdmagammo(findinventory("HDBattery"));
			if(!mmm||mmm.amount<1){setweaponstate("nope");return;}
			invoker.weaponstatus[JETPACKS_BATTERY]=mmm.TakeMag(true);
		}
		goto nope;

	firemode:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&JETPACKF_ON,"turnoff");
	turnon:
		TNT1 A 10 A_StartSound("jetpack/on",CHAN_WEAPON);
		TNT1 A 0{invoker.weaponstatus[0]|=JETPACKF_ON;}
		goto readyend;
	turnoff:
		TNT1 A 0{invoker.weaponstatus[0]&=~JETPACKF_ON;}
		goto nope;

	altfire:
	althold:
	fire:
	hold:
		TNT1 A 1{
			if(invoker.weaponstatus[JETPACKS_BATTERY]<1)return;
			if(!(invoker.weaponstatus[0]&JETPACKF_ON)){
				setweaponstate("turnon");
				return;
			}
			A_ClearRefire();
			if(invoker.weaponstatus[JETPACKS_BATTERYCOUNTER]>JETPACK_COUNTERMAX){
				invoker.weaponstatus[JETPACKS_BATTERY]--;
				invoker.weaponstatus[JETPACKS_BATTERYCOUNTER]=0;
			}else invoker.weaponstatus[JETPACKS_BATTERYCOUNTER]+=JETPACK_COUNTERUSE;
			double rawthrust=0.00001*min(invoker.weaponstatus[JETPACKS_BATTERY],5);
			double zzz=max(rawthrust,(16384+floorz-pos.z)*
				(
					(hdplayerpawn(self)&&hdplayerpawn(self).overloaded>1)?
					(rawthrust/(hdplayerpawn(self).overloaded*0.2+1))
				:rawthrust)
			);
			if(pressingaltfire()){
				vel.xy+=(cos(angle),sin(angle))*zzz*0.1;
				zzz*=0.9;
			}else if(vel.xy!=(0,0)){
				if(vel.x>0)vel.x-=min(0.1,vel.x);else vel.x-=max(-0.1,vel.x);
				if(vel.y>0)vel.y-=min(0.1,vel.y);else vel.y-=max(-0.1,vel.y);
			}
			vel.z+=zzz;
			int chn=(level.time&(1|2));
			for(int i=0;i<4;i++){
				if(!!invoker.pods[i]){
					let aaa=invoker.pods[i];
					aaa.A_StartSound(!chn?"jetpack/bang":"jetpack/fwoosh",chn,pitch:1+0.2*chn);
					if(!chn){
						let bbb=spawn("HDExplosion",(aaa.pos.xy,aaa.pos.z-20),ALLOW_REPLACE);
						bbb.vel.z-=20;
						bbb.vel.xy+=angletovector(aaa.angle+angle,6);
						bbb.deathsound="jetpack/bang";
					}
				}
			}
			if(!chn)A_AlertMonsters();

			blockthingsiterator itt=blockthingsiterator.create(self,128);
			while(itt.Next()){
				actor it=itt.thing;
				if(
					it.bdontthrust
					||it==self
					||(!it.bsolid&&!it.bshootable)
					||!it.mass
					||it.pos.z>pos.z
				)continue;
				double thrustamt=max(0,(1024+it.pos.z-pos.z)*rawthrust)*10/it.mass;
				it.vel+=(it.pos-pos).unit()*thrustamt;
				it.A_GiveInventory("Heat",int(thrustamt*frandom(1,30)));
				if(!random(0,10)){
					HDActor.ArcZap(it);
					it.damagemobj(invoker,self,int(thrustamt*frandom(10,40)),"electrical");
				}
				if(it)it.damagemobj(invoker,self,int(thrustamt*frandom(5,30)),"bashing");
			}
		}
		TNT1 A 0 A_JumpIf(pressingfire()||pressingaltfire(),"hold");
		goto nope;
	}
}
const JETPACK_DIST=16.;
enum HoverNums{
	JETPACKS_BATTERY=1,
	JETPACKS_BATTERYCOUNTER=2,

	JETPACKF_UNLOADONLY=1,
	JETPACKF_ON=2,

	JETPACK_COUNTERMAX=100000,
	JETPACK_COUNTERUSE=JETPACK_COUNTERMAX/80,
}
class HoverPod:Actor{
	default{
		-solid
		+nogravity
		+nointeraction
		+forceybillboard
		height 8;
		radius 4;
	}
	states{
	spawn:
		JPOD A 1 nodelay{
			if(
				master
				&&master.player
				&&(master.player.readyweapon is "HDJetPack")
			){
				double podz=master.pos.z+master.height-30;
				if(hdweapon(master.player.readyweapon).weaponstatus[0]&JETPACKF_ON)podz+=frandom(-0.5,0.5);
				setorigin((master.pos.xy+
					angletovector(angle+master.angle,JETPACK_DIST),
				podz),true);
			}else{
				destroy();
			}
		}
		wait;
	}
}
