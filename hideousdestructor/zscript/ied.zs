//-------------------------------------------------
// Not-Quite-Improvised Explosive Device
//-------------------------------------------------
/*
	SPECIAL NOTE FOR MAPPERS
	Setting user_startmode to -1 will disable targeting.
*/
enum HDIEDConst{
	HDIED_TID=8495,

	IEDC_DETONATE=999,
	IEDC_ON=1,
	IEDC_OFF=2,
}
class HDIEDKit:HDPickup{
	int botid;
	default{
		inventory.amount 1;
		inventory.interhubamount 24;
		inventory.icon "IEDSC0";
		inventory.pickupmessage "$PICKUP_IED";
		height 4;radius 4;scale 0.5;
		hdpickup.bulk ENC_IEDKIT;
		tag "$TAG_IEDKIT";
		hdpickup.refid HDLD_IEDKIT;
		+hdpickup.multipickup
		+forcexybillboard
	}
	override int getsbarnum(int flags){return botid;}
	override void beginplay(){
		super.beginplay();
		botid=1;
	}
	states{
	spawn:
		IEDK A -1;
		stop;
	use:
		TNT1 A 0{
			if(invoker.amount<1)return;
			class<inventory> which="";
			if(countinv("DudRocketAmmo"))which="DudRocketAmmo";
			else if(countinv("HDRocketAmmo"))which="HDRocketAmmo";
			else{
				A_Log(Stringtable.Localize("$IED_ONELIVEORDUD"),true);
				return;
			}

			A_TakeInventory(which,1,TIF_NOTAKEINFINITE);
			actor ied;
			[bripper,ied]=A_SpawnItemEx("HDIED",0,0,height-12,
				vel.x,vel.y,vel.z,0,
				SXF_SETMASTER|SXF_NOCHECKPOSITION|
				SXF_ABSOLUTEMOMENTUM|SXF_TRANSFERPITCH
			);
			HDIED(ied).botid=invoker.botid;
			ied.A_ChangeVelocity(4*cos(pitch),0,4*sin(-pitch),CVF_RELATIVE);

			if(
				!sv_infiniteammo
				||invoker.amount>1
			)invoker.amount--;
		}fail;
	}
}
class HDIEDPack:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		let iii=spawn("HDIEDKit",pos,ALLOW_REPLACE);
		if(iii)HDF.TransferSpecials(self,iii);
		for(int i=0;i<5;i++)spawn("HDIEDKit",pos,ALLOW_REPLACE);
		destroy();
	}
}
class HDEnemyIED:HDIED{
	default{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Enemy IED"
		//$Sprite "IEDSC0"
		-friendly
	}
}
class HDIED:DudRocket{
	int botid;
	int user_startmode;
	default{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Friendly IED"
		//$Sprite "IEDSA0"

		//mm: actively scanning
		-missilemore

		-missile +friendly +lookallaround +nosplashalert +ambush
		-pushable +shootable +noblood +nodamage
		+ismonster
		height 7;radius 4;
		painchance 256;maxtargetrange 96;
		obituary "$OB_IED";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			!random(0,7)
			||(mod=="Piercing"&&!random(0,3))
		){
			setstatelabel("destroy");
		}
		return -1;
	}
	override bool OnGrab(actor grabber){
		setstatelabel("dismantle");
		return false;
	}
	static void IEDPrint(string txt,actor ppp){
		if(!ppp)return;
		ppp.A_Log(Stringtable.Localize("$IED_IED")..txt,true);
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(master){
			ChangeTid(HDIED_TID);
			if(master.player){
				if(cvar.getcvar("hd_autoactivateied",master.player).getbool()){
					IEDPrint(
						string.format(
							Stringtable.Localize("$IED_DEPLOYED"),
							botid,botid,botid
						),master
					);
					bmissilemore=true;
				}else if(cvar.getcvar("hd_helptext",master.player).getbool())
					IEDPrint(
						string.format(
							Stringtable.Localize("$IED_DEPLOYED_IDLE"),
							botid,botid,botid
						),master
					);
			}
		}else bmissilemore=user_startmode>-1; //map-placed should be seeking
	}
	void A_IEDScan(){
		if(!bmissilemore)return;
		blockthingsiterator itt=blockthingsiterator.create(self,maxtargetrange);
		while(itt.Next()){
			actor hitactor=itt.thing;
			if(
				hitactor
				&&hitactor.bshootable
				&&!hitactor.bdormant
				&&!hitactor.bnotarget
				&&!hitactor.bnevertarget
				&&(hitactor.bismonster||hitactor.player)
				&&(!hitactor.player||!(hitactor.player.cheats&CF_NOTARGET))
				&&hitactor.health>0
				&&isHostile(hitactor)
				&&checksight(hitactor)
				&&(
					!master
					||!checksight(master)
					||distance3d(master)>256
				)
			){
				tracer=hitactor;
				setstatelabel("detonate");
				return;
			}
		}
	}
	states{
	spawn:
		IEDS A 0 nodelay A_JumpIf(!bmissilemore,"idle");
		IEDS C 35 A_StartSound("ied/beep",CHAN_VOICE);
		IEDS CBCBC 4;
		IEDS ABABABABABABAB 2;
		IEDS ABABAB 1;
	idle:
		IEDS A 10 A_IEDScan();
		IEDS C 10 A_JumpIf(!bmissilemore,"idle");
		loop;
	detonate:
		IEDS A 8{
			bshootable=false;
			A_SetFriendly(false);
			bismonster=false;
			target=master;
		}
		IEDS A 0 AddZ(3); //it's standing on its tail
		goto explode;
	destroy:
		IEDS A 0{
			if(!random(0,7))setstatelabel("detonate");
			else if(!random(0,3))stamina=666;
		}goto dismantle;
	dismantle:
		IEDS A 0{
			A_SpawnItemEx("HDIEDKit",0,0,height-12,
				vel.x,vel.y,vel.z+4,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
			A_SpawnItemEx(stamina==666?"DudRocket":"DudRocketAmmo",0,0,height-12,
				vel.x,vel.y,vel.z+2,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
		}stop;
	}
}


//spawn actor
class HDIEDKits:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_SpawnItemEx("HDIEDKit",-2,0,0);
			A_SpawnItemEx("HDIEDKit",-2,-2,0);
			A_SpawnItemEx("HDIEDKit",-2,-4,0);
			A_SpawnItemEx("HDIEDKit",0,-2,0);
			A_SpawnItemEx("HDIEDKit",0,-4,0);
			A_SpawnItemEx("HDIEDKit",0,0,0);
		}stop;
	}
}


extend class HDHandlers{
	void SetIED(hdplayerpawn ppp,int iedcmd,int botcmdid){
		let iedinv=HDIEDKit(ppp.findinventory("HDIEDKit"));
		int botid=iedinv?iedinv.botid:1;

		//set IED tag number with -#
		//e.g., "ied -123" will set tag to 123
		if(iedcmd<0){
			if(!iedinv)return;
			iedinv.botid=-iedcmd;
			HDIED.IEDPrint(string.format(Stringtable.Localize("$IED_SETTAG"),-iedcmd),ppp);
			return;
		}

		//give actual commands
		bool badcommand=true;
		actoriterator it=level.createactoriterator(HDIED_TID,"HDIED");
		actor ied;bool anyieds=false;
		int affected=0;

		while(ied=it.Next()){
			anyieds=true;
			if(
				ied.master==ppp
				&&(
					!botcmdid||
					botcmdid==HDIED(ied).botid
				)
			){
				if(iedcmd==999){
					badcommand=false;
					ied.setstatelabel("detonate");
					affected++;
				}
				else if(iedcmd==1){
					badcommand=false;
					ied.bmissilemore=true;
					affected++;
				}
				else if(iedcmd==2){
					badcommand=false;
					ied.bmissilemore=false;
					affected++;
				}
				else if(iedcmd==123){
					badcommand=false;
					HDIED.IEDPrint(string.format(Stringtable.Localize("$IED_MYPOS"),
						ied.pos.x,ied.pos.y,
						HDIED(ied).botid,
						ied.bmissilemore?Stringtable.Localize("$IED_ACTIVE"):Stringtable.Localize("$IED_PASSIVE")
					),ppp);
				}
				else{
					badcommand=true;
					break;
				}
			}
		}
		if(
			!badcommand
			&&iedcmd!=123
		){
			string verb=Stringtable.Localize("$IED_VHACK");
			if(iedcmd==IEDC_DETONATE)verb=Stringtable.Localize("$IED_VDETONATE");
			else if(iedcmd==IEDC_ON)verb=Stringtable.Localize("$IED_VON");
			else if(iedcmd==IEDC_OFF)verb=Stringtable.Localize("$IED_VOFF");
			HDIED.IEDPrint(string.format(
				Stringtable.Localize("$IED_RESULT"),affected,affected==1?Stringtable.Localize("$IED_SINGULAR"):Stringtable.Localize("$IED_PLURAL"),
				botcmdid?string.format(Stringtable.Localize("$IED_WITHTAG"),botcmdid):"",
				verb
			),ppp);
		}else if(badcommand)HDIED.IEDPrint(string.format(Stringtable.Localize("$IED_HELPTEXT"),anyieds?"":Stringtable.Localize("$IED_NODEPLOYED"),botid),ppp);
	}
}
