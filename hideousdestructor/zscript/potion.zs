//-------------------------------------------------
// Healing potion
//-------------------------------------------------
class HDHealingPotion:hdinjectormaker{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Healing Potion"
		//$Sprite "BON1A0"

		hdmagammo.mustshowinmagmanager true;
		inventory.pickupmessage "$PICKUP_POTION";
		inventory.pickupsound "potion/swish";
		inventory.icon "BON1E0";
		scale 0.3;
		tag "$TAG_POTION";
		hdmagammo.maxperunit HDHM_BOTTLE;
		hdmagammo.magbulk ENC_POTION*0.7;
		hdmagammo.roundbulk ENC_POTION*0.04;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDHealingBottler";
	}
	override string,string,name,double getmagsprite(int thismagamt){
		return "BON1E0","TNT1A0","HDHealingPotion",0.3;
	}
	override int getsbarnum(int flags){return mags.size()?mags[0]:0;}
	override bool Extract(){return false;}
	override bool Insert(){
		bool plid=(Wads.CheckNumForName("id",0)!=-1);
		if(
			!plid
			||amount<2
		)return false;
		int lowindex=mags.size()-1;
		if(
			mags[lowindex]>=maxperunit
			||mags[0]<1
		)return false;
		mags[0]--;
		mags[lowindex]++;
		owner.A_StartSound("potion/swish",8);
		if(mags[0]<1){
			mags.delete(0);
			amount--;
			owner.A_StartSound("potion/open",CHAN_WEAPON);
			actor a=owner.spawn(plid?"SpentBottle":"SpentPolyp",(owner.pos.xy,owner.pos.z+owner.height*0.8),ALLOW_REPLACE);
			a.angle=owner.angle+2;a.vel=owner.vel;a.A_ChangeVelocity(3,1,4,CVF_RELATIVE);
			if(plid){
				a=owner.spawn("SpentCork",(owner.pos.xy,owner.pos.z+owner.height*0.8),ALLOW_REPLACE);
				a.angle=owner.angle+3;a.vel=owner.vel;a.A_ChangeVelocity(5,3,4,CVF_RELATIVE);
			}
		}
		return true;
	}
	states{
	use:
		TNT1 A 0 A_JumpIf(
			player.cmd.buttons&BT_USE
			&&(
				!findinventory("HDHealingBottler")
				||!HDHealingBottler(findinventory("HDHealingBottler")).bweaponbusy
			)
		,1);
		goto super::use;
	cycle:
		TNT1 A 0{
			invoker.syncamount();
			int firstbak=invoker.mags[0];
			int limamt=invoker.amount-1;
			for(int i=0;i<limamt;i++){
				invoker.mags[i]=invoker.mags[i+1];
			}
			invoker.mags[limamt]=firstbak;
			A_StartSound("potion/swish",CHAN_WEAPON,CHANF_OVERLAP,0.5);
			A_StartSound("weapons/pocket",9,volume:0.3);
		}fail;
	spawn:
		BON1 A 0 nodelay A_JumpIf(Wads.CheckNumForName("id",0)!=-1,"jiggling");
		BON1 A 0 A_JumpIf(floorz<pos.z,"plucked");
	planted:
		BON1 ABCDCB 2 light("HEALTHPOTION") A_SetTics(random(3,5));
		loop;
	plucked:
		BON1 E -1;
		stop;
	jiggling:
		BON1 ABCDCB 2 light("HEALTHPOTION") A_SetTics(random(1,3));
		loop;
	}
}
class HDHealingBottler:HDWoundFixer{
	default{
		weapon.selectionorder 1000;
		tag "$TAG_POTION";
	}
	override string,double getpickupsprite(){return "BON1A0",1.;}
	override string gethelptext(){LocalizeHelp();
		return LWPHELP_FIRE..StringTable.Localize("$HEALWH_FIRE")
		..LWPHELP_USE.." + "..LWPHELP_USE..StringTable.Localize("$HEALWH_USE")
		;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		sb.drawimage(
			"BON1E0",(-23,-7),
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT
		);
		sb.drawwepnum(hdw.weaponstatus[INJECTS_AMOUNT],HDHM_BOTTLE);
	}
	states{
	spawn:
		TNT1 A 1;
		TNT1 A 0{
			int amt=invoker.weaponstatus[INJECTS_AMOUNT];
			actor a=null;
			if(amt>0){
				a=spawn("HDHealingPotion",invoker.pos,ALLOW_REPLACE);
				a.A_StartSound("potion/swish",CHAN_BODY);
				if(HDHealingPotion(a))HDHealingPotion(a).mags[0]=amt;
			}else{
				a=spawn(invoker.bplayingid?"SpentBottle":"SpentPolyp",invoker.pos,ALLOW_REPLACE);
				a.A_StartSound("potion/open",CHAN_BODY);

				if(invoker.bplayingid){
					let aa=spawn("SpentCork",pos+gunpos(),ALLOW_REPLACE);
					aa.angle=angle+3;aa.vel=vel+(frandom(-1,1),frandom(-1,1),frandom(0,1));
				}
			}
			a.angle=self.angle;a.vel=self.vel;
			a.target=self;
			a.vel=vel;

			//if dropped while sprinting, treat as dropped one from inventory
			let hdp=HDPlayerPawn(target);
			if(
				!!hdp
				&&!!hdp.player
				&&!!NullWeapon(hdp.player.readyweapon)
			){
				let iii=HDInjectorMaker(hdp.findinventory("HDHealingPotion"));
				if(
					!!iii
					&&iii.amount>0
				){
					iii.SyncAmount();
					if(HDHealingPotion(a))HDHealingPotion(a).mags[0]=iii.mags[0];

					invoker.weaponstatus[0]^=~INJECTF_SPENT;
					invoker.weaponstatus[INJECTS_AMOUNT]=iii.mags[0];
					iii.mags.delete(0);
					iii.amount--;
				}
			}
		}
		stop;
	select:
		TNT1 A 0{
			if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$POTION_TEXT1"));
			A_StartSound("potion/swish",8,CHANF_OVERLAP);

			let iii=HDHealingPotion(findinventory("HDHealingPotion"));
			if(
				!!iii
				&&iii.amount>0
			){
				iii.SyncAmount();
				invoker.weaponstatus[INJECTS_AMOUNT]=iii.mags[0];
				iii.mags.delete(0);
				iii.amount--;
			}
		}
		goto super::select;
	deselect:
		TNT1 A 10 A_StartSound("potion/swish",8,CHANF_OVERLAP);
		TNT1 A 0{
			if(invoker.weaponstatus[INJECTS_AMOUNT]<1){
				DropInventory(invoker);
				return;
			}

			//make sure the last used one appears at the top
			let iii=HDHealingPotion(findinventory("HDHealingPotion"));
			if(!!iii){
				iii.mags.insert(0,invoker.weaponstatus[INJECTS_AMOUNT]);
				iii.amount++;
			}else HDMagAmmo.GiveMag(self,"HDHealingPotion",invoker.weaponstatus[INJECTS_AMOUNT]);
		}
		TNT1 A 0 A_Lower(999);
		wait;
	fire:
		TNT1 A 0{
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag(),2);
				A_Refire("nope");
			}
		}
		TNT1 A 4 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 1{
			A_StartSound("potion/open",CHAN_WEAPON);
			A_Refire();
		}
		TNT1 A 0 A_StartSound("potion/swish",8);
		goto nope;
	hold:
		TNT1 A 1;
		TNT1 A 0{
			A_WeaponBusy();
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag(),2);
				A_Refire("nope");
			}else if(pitch>-55){
				A_MuzzleClimb(0,-8);
				A_Refire();
			}else{
				A_Refire("inject");
			}
		}
		TNT1 A 0 A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
		goto nope;
	inject:
		TNT1 A 7{
			A_MuzzleClimb(0,-2);
			if(invoker.weaponstatus[INJECTS_AMOUNT]>0){
				invoker.weaponstatus[INJECTS_AMOUNT]--;
				A_StartSound("potion/chug",CHAN_VOICE);
				HDF.Give(self,"HealingMagic",HDHM_MOUTH);
			}
		}
		TNT1 AAAAA 1 A_MuzzleClimb(0,0.5);
		TNT1 A 5 A_JumpIf(!pressingfire(),"injectend");
		goto hold;
	injectend:
		TNT1 A 6;
		TNT1 A 0{
			if(invoker.weaponstatus[INJECTS_AMOUNT]>0)A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
		}
		goto nope;
	}
}
class HealingMagic:HDDrug{
	override void doeffect(){
		let hdp=hdplayerpawn(owner);

		double ret=min(0.1,amount*0.006);
		if(hdp.strength<1.+ret)hdp.strength+=0.003;
	}
	override void pretravelled(){
		let hdp=hdplayerpawn(owner);

		HDBleedingWound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		while(bldw=HDBleedingWound(bldit.next())){
			if(
				bldw
				&&bldw.bleeder==hdp
			){
				double cost=
					bldw.depth
					+bldw.width*0.8
					+bldw.patched*0.7
					+bldw.sealed*0.6
				;
				if(amount<cost)break;
				amount-=int(cost);
				bldw.depth=0;
				bldw.width=0;
				bldw.patched=0;
				bldw.sealed=0;
			}
		}

		let bloodloss=(hdp.bloodloss>>4);
		bloodloss=min(bloodloss,amount);
		if(bloodloss>0){
			amount-=bloodloss;
			hdp.bloodloss-=(bloodloss<<4);
		}

		return;
	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;

		if(hdp.beatcap<HDCONST_MINHEARTTICS){
			hdp.beatcap=max(hdp.beatcap,HDCONST_MINHEARTTICS+5);
			if(!random(0,99))amount--;
		}
		if(hdp.countinv("HDStim")){
			hdp.A_TakeInventory("HDStim",4);
			amount--;
		}
		if(hdp.bloodloss>0)hdp.bloodloss-=12;

		//heal shorter-term damage
		let hdbw=hdbleedingwound.findbiggest(hdp,HDBW_FINDPATCHED|HDBW_FINDSEALED);
		if(hdbw){
			double addamt=min(1.,hdbw.depth);
			hdbw.depth-=addamt;
			hdbw.patched+=addamt;
			addamt=min(0.8,hdbw.patched);
			hdbw.patched-=addamt;
			hdbw.sealed+=addamt;
			hdbw.sealed=max(0,hdbw.sealed-0.6);
			amount--;
		}

		if(hdp.beatcounter%12==0){
			//heal long-term damage
			if(
				hdp.burncount>0
				||hdp.oldwoundcount>0
				||hdp.aggravateddamage>0
			){
				hdp.burncount--;
				hdp.oldwoundcount--;
				hdp.aggravateddamage--;
				amount--;
			}

			if(
				hdp.beatcounter%60==0
				&&!random(0,7)
			){
				hdp.A_Log(Stringtable.Localize("$BLUES_POWER"),true);
				amount-=20;
				hdp.incaptimer=min(0,hdp.incaptimer);
				hdp.stunned=20;
				plantbit.spawnplants(hdp,33,144);
				switch(random(0,3)){
				case 0:
					blockthingsiterator rezz=blockthingsiterator.create(hdp,512);
					while(rezz.next()){
						actor rezzz=rezz.thing;
						if(
							hdp.canresurrect(rezzz,false)
							&&!rezzz.bboss
							&&rezzz.spawnhealth()<400
						){
							hdp.RaiseActor(rezzz,RF_NOCHECKPOSITION);
							rezzz.A_SetFriendly(true);
							rezzz.master=self;
							plantbit.spawnplants(rezzz,12,33);
							amount--;
							if(!random(0,2))break;
						}
					}
					break;
				case 1:
					blockthingsiterator fffren=
						blockthingsiterator.create(hdp,512);
					while(fffren.next()){
						actor ffffren=fffren.thing;
						if(
							ffffren.bismonster
							&&!ffffren.bfriendly
							&&!ffffren.bboss
							&&ffffren.health>0
							&&ffffren.spawnhealth()<400
						){
							ffffren.A_SetFriendly(true);
							if(hdmobbase(ffffren))
								hdmobbase(ffffren).A_Vocalize(ffffren.painsound);
								else ffffren.A_StartSound(ffffren.painsound,CHAN_VOICE);
							plantbit.spawnplants(ffffren,1,0);
							amount-=2;
							if(!random(0,3))break;
						}
					}
					break;
				default:
					hdp.aggravateddamage-=20;
					hdp.burncount-=20;
					for(int i=0;i<2;i++){
						let bld=hdbleedingwound.findbiggest(hdp,HDBW_FINDPATCHED|HDBW_FINDSEALED);
						if(bld)bld.destroy();
					}

					blockthingsiterator healit=
						blockthingsiterator.create(hdp,1024);
					while(healit.next()){
						actor healthis=healit.thing;
						if(
							healthis.bshootable
							&&!healthis.bcorpse
							&&healthis.health>0
							&&healthis.health<healthis.spawnhealth()
						){
							healthis.GiveBody(512);
						}
					}

					if(!random(0,3))spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					break;
				}
			}
		}

		if(hd_debug>=4)console.printf("HEALZ "..amount.."  = "..hdp.strength);
	}
}




