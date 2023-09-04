//-------------------------------------------------
// [insert homestar reference here]
//-------------------------------------------------
extend class HDPlayerPawn{
	//cheats to give or take away bad stuff
	bool cheatgivestatusailments(string name,int amount=1){
		if(name~=="fire"){
			if(amount<0)A_GiveInventory("immunitytofire");else{
				if(!scopecamera){
					scopecamera=spawn("ScopeCamera",pos,ALLOW_REPLACE);
					scopecamera.target=self;
				}
				let hdsc=hdactor(scopecamera);
				if(hdsc)hdsc.A_Immolate(self,self,amount);
			}
		}
		if(name~=="wound"||name~=="wounds"){
			hdbleedingwound.inflict(self,amount,source:self);return true;
		}
		if(name~=="incap"||name~=="incapacitation"){
			incaptimer+=amount;return true;
		}
		if(name~=="oldwound"||name~=="oldwounds"||name~=="oldwoundcount"){
			oldwoundcount+=amount;return true;
		}
		if(name~=="burn"||name~=="burns"||name~=="burncount"){
			burncount+=amount;return true;
		}
		if(name~=="aggro"||name~=="aggravateddamage"){
			aggravateddamage+=amount;return true;
		}
		if(name~=="stun"){
			stunned+=amount;return true;
		}
		if(name~=="forwardroll"||name~=="fallroll"){
			ForwardRoll(amount,hdplayerpawn.FROLL_VOLUNTARY);return true;
		}
		return false;
	}
	override void CheatGive(string name, int amount){
		let player=self.player;
		if(!player.mo||player.health<1)return;

		if(cheatgivestatusailments(name,amount)) return;

		bool allthings=(name~=="all"||name~=="everything");

		//apply giveammo principles to HDAmmo
		class<inventory> type;
		if(allthings||name~=="ammo"){
			A_GiveInventory("HDBackpack");
			for(int i=0;i<AllActorClasses.Size();++i){
				type=(class<HDAmmo>)(AllActorClasses[i]);
				if(!type)continue;
				if(
					!getdefaultbytype((class<HDPickup>)(type)).bcheatnogive
					&&getdefaultbytype((class<HDAmmo>)(type)).refid!=""
				){
					let ammoitem=hdpickup(findinventory(type));
					if(!ammoitem)ammoitem=hdpickup(GiveInventoryType(type));
					ammoitem.amount=ammoitem.maxamount;
					let magammoitem=hdmagammo(ammoitem);
					if(magammoitem)magammoitem.maxcheat();
				}
			}
		}

		//just work around armour
		if(allthings||name~=="armor"||name~=="armour"){
			A_TakeInventory("HDArmourWorn");
			A_GiveInventory("BattleArmourWorn");
			return;
		}

		//super call
		super.cheatgive(name,amount);

		//load weapons that use variables instead of ammo types
		if(allthings||name~=="ammo"){
			for(inventory hdww=inv;hdww!=null;hdww=hdww.inv){
				let hdw=hdweapon(hdww);
				if(hdw)hdw.initializewepstats(true);
			}
		}

		//clean up some stuff
		A_TakeInventory("backpack");
		A_TakeInventory("BasicArmor");

		//warn the player if IDFA will slow them way down
		//skip warning of low-encumb enough that the excess gets deleted anyway
		if(
			hdmath.getencumbrancemult()>0.17  //got this # by trial and error
			&&(allthings||name~=="ammo"||name~=="weapons")
		){
			A_Print("You are now crushed under all the stuff you just gave yourself with this cheat. You can try:\n\n\n* dropping some weapons\n\n* typing hd_purge in the console\n\n* attempting to sprint to automatically drop items\n\n* switching to fist and hitting Zoom+Dropweapon\n\n* using the hd_doomguy command\n\n* giving  yourself the InvReset item",10.,"BIGFONT");
		}
	}
	override void CheatTake(string name, int amount){
		if(!cheatgivestatusailments(name,-amount))super.cheattake(name,amount);
	}


	//lets you specify configurations when giving a weapon
	void CheckGiveCheat(){
		string giveconfig=hd_give.getstring();
		if(giveconfig=="")return;
		hd_give.setstring("");
		if(deathmatch&&!sv_cheats)return;
		let giverefid=giveconfig.left(3);
		giveconfig=giveconfig.mid(3);
		giveconfig.replace(",","");
		giveconfig.replace(" ","");
		giveconfig=giveconfig.makelower();
		bool found=false;
		for(int i=0;i<allactorclasses.size();i++){
			let hpk=((class<hdpickup>)(allactorclasses[i]));
			if(
				hpk
				&&getdefaultbytype(hpk).refid~==giverefid
			){
				A_GiveInventory(hpk,giveconfig.toint());
				found=true;
				break;
			}
			let hpw=((class<hdweapon>)(allactorclasses[i]));
			if(
				hpw
				&&getdefaultbytype(hpw).refid~==giverefid
			){
				let www=hdweapon(spawn(hpw,pos));
				www.bdontdefaultconfigure=true;
				www.loadoutconfigure(giveconfig);
				www.actualpickup(self);
				found=true;
				break;
			}
		}
		if(!found)A_Log("hd_give: code \""..giverefid.."\" not found.",true);
	}
}
