// ------------------------------------------------------------
// Loadout-related stuff!
// ------------------------------------------------------------
extend class HDPlayerPawn{
	//basic stuff every player should have
	virtual void GiveBasics(){
		if(!player)return;
		A_GiveInventory("HDFist");
		A_GiveInventory("SelfBandage");
		A_GiveInventory("HDFragGrenades");
		A_GiveInventory("MagManager");
		A_GiveInventory("PickupManager");
	}
}

//loadout common to all soldier classes
class SoldierExtras:HDPickup{
	default{
		-hdpickup.fitsinbackpack
		hdpickup.refid HDLD_SOLDIER;
		tag "$SOLDIERKITLOADOUT";
	}
	states{
	pickup:
		TNT1 A 0{
			A_SetInventory("PortableMedikit",max(1,countinv("PortableMedikit")));
			A_SetInventory("PortableStimpack",max(2,countinv("PortableStimpack")));
			A_SetInventory("GarrisonArmourWorn",1);

			A_SetInventory("HDPistol",max(countinv("HDPistol"),1));
			A_SetInventory("HD9mMag15",max(3,countinv("HD9mMag15")));

			A_SetInventory("HDFragGrenadeAmmo",max(3,countinv("HDFragGrenadeAmmo")));
			A_SetInventory("DERPUsable",max(1,countinv("DERPUsable")));
			A_SetInventory("PortableLadder",max(1,countinv("PortableLadder")));
		}fail;
	}
}



//reset inventory
class InvReset:Inventory{
	static void ReallyClearInventory(actor resetee,bool keepkeys=false){
		inventory item=resetee.inv;
		while(item){
			if(
				(!keepkeys||!(item is "Key"))
			){
				item.destroy();
				item=resetee.inv;
			}
		}
	}
	static void GiveStartItems(actor resetee){
		//now get all the "dropitems" (i.e. player's startitems) and give them
		let drop=resetee.default.getdropitems();
		if(drop){
			for(dropitem di=drop;di;di=di.Next){
				if(di.Name=='None')continue;
				resetee.A_GiveInventory(di.Name,di.Amount);
			}
		}
	}
	override void attachtoowner(actor other){
		reallyclearinventory(other);
		givestartitems(other);
		destroy();
	}
}
class DoomguyLoadout:InvReset{
	override void attachtoowner(actor other){
		reallyclearinventory(other,true);
		let d=HDPlayerPawn(other);
		if(d)d.GiveBasics();
		other.A_GiveInventory("HDPistol");
		other.A_GiveInventory("HD9mMag15",2);
		other.A_GiveInventory("HDPistolAmmo",4);
		HDWeaponSelector.Select(other,"HDPistol",1);
		destroy();
	}
}
//wait a moment and then select a weapon
//used to override default to fist on weapon removal
class HDWeaponSelector:Thinker{
	actor other;
	class<Weapon> weptype;
	static void Select(actor caller,class<Weapon> weptype,int waittime=10){
		let thth=new("HDWeaponSelector");
		thth.weptype=weptype;
		thth.other=caller;
		thth.ticker=waittime;
	}
	int ticker;
	override void Tick(){
		ticker--;
		if(ticker>0)return;
		if(
			!!other
			&&!other.bnoblockmap  //don't do this for spectators
		)other.A_SelectWeapon(weptype);
		destroy();
	}
}



//refids.
//these need to be defined ONLY where an item
//needs to be selectable through custom loadouts.
//all in one place for ease of checking for conflicts.

const HDLD_MAPTOO="all";

const HDLD_SOLDIER="sol";
const HDLD_SOLEXP= HDLD_MEDIKIT..","..HDLD_STIMPAK..","..HDLD_ARWG..","..HDLD_PISTOL..","..HDLD_NIMAG15..","..HDLD_GREFRAG..","..HDLD_DERPBOT..","..HDLD_LADDER;

const HDLD_INSURG="???";

const HDLD_NINEMIL="9mm";
const HDLD_NIMAG15="915";
const HDLD_NIMAG30="930";

const HDLD_355="355";

const HDLD_SEVNMIL="7mm";
const HDLD_SEVNREC="7mr";
const HDLD_SEVNMAG="730";
const HDLD_SEVCLIP="710";
//const HDLD_SEVNBUL="7bl";
const HDLD_SEVNBRA="7br";
const HDLD_776RL=  "7rl";

const HDLD_FOURMIL="4mm";
const HDLD_FOURMAG="450";

const HDLD_BATTERY="bat";
const HDLD_SHOTSHL="shl";
const HDLD_ROCKETS="rkt";
const HDLD_HEATRKT="rkh";
const HDLD_BROBOLT="brb";
const HDLD_GREFRAG="frg";

const HDLD_STIMPAK="stm";
const HDLD_MEDIKIT="med";
const HDLD_FINJCTR="2fl";
const HDLD_BERSERK="zrk";
const HDLD_BLODPAK="bld";
const HDLD_RADSUIT="rad";
const HDLD_LITEAMP="lit";
const HDLD_LADDER= "lad";
const HDLD_DOORBUS="dbs";
const HDLD_IEDKIT= "ied";
const HDLD_JETPACK="jet";
const HDLD_BACKPAK="bak";

const HDLD_KEY=    "key";
const HDLD_MAP=    "map";

const HDLD_DERPBOT="drp";
const HDLD_HERPBOT="hrp";

const HDLD_ARMG="arg";
const HDLD_ARMB="arb";
const HDLD_ARWG="awg";
const HDLD_ARWB="awb";

const HDLD_FIST=    "fis";
const HDLD_CHAINSW= "saw";
const HDLD_REVOLVER="rev";
const HDLD_PISTOL= "pis";
const HDLD_SMG    ="smg";
const HDLD_HUNTER= "hun";
const HDLD_SLAYER= "sla";
const HDLD_ZM66=   "z66";
const HDLD_VULCETT="vul";
const HDLD_LAUNCHR="lau";
const HDLD_BLOOPER="blo";
const HDLD_THUNDER="thu";
const HDLD_LIB=    "lib";
const HDLD_BFG=    "bfg";
const HDLD_BRONTO= "bro";
const HDLD_BOSS=   "bos";

//hacky shit: used to set player cvar in the status bar
class LoadoutMenuHackToken:ThinkerFlag{
	string loadout;
	override void tick(){
		destroy();
	}
}


//used for loadout configurations and custom spawns
class HDPickupGiver:HDPickup{
	class<hdpickup> pickuptogive;
	property pickuptogive:pickuptogive;
	hdpickup actualitem;
	virtual void configureactualpickup(){}
	override void postbeginplay(){
		super.postbeginplay();
		spawnactualitem();
	}
	void spawnactualitem(){
		if(hdpickup.checknoloadout(self,refid))return;

		//check if the owner already has this pickup
		if(owner)actualitem=hdpickup(owner.findinventory(pickuptogive));

		//spawn or give the pickup
		if(actualitem){
			//if actor present, just give more
			owner.A_GiveInventory(pickuptogive, amount);
		}else{
			actualitem=hdpickup(spawn(pickuptogive,pos));
			actualitem.amount=amount;
			HDF.TransferSpecials(self,actualitem);
			if(owner)actualitem.attachtoowner(owner);
		}

		//now apply the changes this pickupgiver is for
		configureactualpickup();
		destroy();
	}
	//this stuff must be done after the first tick,
	//as the loadout configurator needs time to read the actualpickup
	override void tick(){
		super.tick();
		destroy();
	}
}
class HDWeaponGiver:Inventory{
	class<hdweapon> weapontogive;
	property weapontogive:weapontogive;
	string weprefid;
	property weprefid:weprefid;
	string config;
	property config:config;
	double bulk;property bulk:bulk;
	hdweapon actualweapon;
	default{
		+nointeraction
		-inventory.invbar
		inventory.maxamount 1;
		hdweapongiver.config "";
		hdweapongiver.weprefid "";
	}
	override void postbeginplay(){
		super.postbeginplay();
		spawnactualweapon();
	}
	virtual void spawnactualweapon(){
		//check denylist for the target weapon
		if(hdpickup.checknoloadout(self,weprefid))return;

		//check if the owner already has this weapon
		bool hasprevious=(
			owner
			&&owner.findinventory(weapontogive)
		);

		//spawn the weapon
		actualweapon=hdweapon(spawn(weapontogive,pos));
		actualweapon.special=special;
		actualweapon.changetid(tid);
		if(owner){
			actualweapon.attachtoowner(owner);

			//apply defaults from owner
			actualweapon.defaultconfigure(player);
		}

		//apply config applicable to this weapongiver
		actualweapon.loadoutconfigure(config);

		//if there was a previous weapon, bring this one down to the spares
		if(hasprevious&&owner.getage()>5){
			actualweapon.AddSpareWeaponRegular(owner);
		}
	}
	//this stuff must be done after the first tick,
	//as the loadout configurator needs time to read the actualweapon
	override void tick(){
		super.tick();
		if(
			owner
			&&owner.player
			&&actualweapon is "HDWeapon"
		){
			let wp=actualweapon.getclassname();
			owner.A_SelectWeapon(wp);
		}
		destroy();
	}
}


class CustomLoadoutGiver:Inventory{
	//must be DoEffect as AttachToOwner and Pickup are not called during a range reset!
	override void doeffect(){
		let hdp=HDPlayerPawn(owner);
		if(hdp)hdp.GiveCustomItems(hdp.classloadout);
		destroy();
	}
}
extend class HDPlayerPawn{
	string startingloadout;property startingloadout:startingloadout;
	void GiveCustomItems(string loadinput){
		if(!player)return;
		if(HDPlayerPawn(self))HDPlayerPawn(self).GiveBasics();

		string weapondefaults=hdweapon.getdefaultcvar(player);

		//special conditions that completely overwrite the loadout giving
		if(
			hd_forceloadout!=""
			&&hd_forceloadout!="0"
			&&hd_forceloadout!="false"
			&&hd_forceloadout!="none"
			&&hd_forceloadout!="''"
		){
			loadinput=hd_forceloadout;
			A_Log("Loadout settings forced by administrator:  "..hd_forceloadout,true);
		}else{
			string myloadout=cvar.getcvar("hd_myloadout",player).getstring();
			if(
			myloadout!=""
			&&myloadout!="0"
			&&myloadout!="false"
			&&myloadout!="none"
			&&myloadout!="''"
			){
				loadinput=myloadout;
				A_Log("Temporary loadout set through myloadout:  "..myloadout,true);
			}
		}
		if(loadinput.left(3)~=="hd_"){
			loadinput=cvar.getcvar(loadinput,player).getstring();
		}
		string loadoutname;
		[loadinput,loadoutname]=HDMath.GetLoadoutStrings(loadinput);
		if(loadoutname!="")A_Log("Starting Loadout: "..loadoutname,true);
		if(loadinput=="")return;
		if(loadinput~=="doomguy")loadinput="pis,9152,9mm4";
		if(loadinput~=="insurgent"){
			A_GiveInventory("InsurgentLoadout");
			return;
		}

		string denylist=hd_noloadout;
		if(denylist!=""){
			denylist=denylist.makelower();
			denylist.replace(" ","");
			array<string>blist;blist.clear();
			A_Log("Some items in your loadout may have been denylisted from this game and removed or substituted at start: "..denylist,true);
			denylist.split(blist,",");
			for(int i=0;i<blist.size();i++){
				string blisti=blist[i];
				if(blisti.length()>=3){
					if(blisti.indexof("=")>0){
						string replacement=blisti.mid(blisti.indexof("=")+1);
						loadinput.replace(blisti.left(3),replacement);
					}else loadinput.replace(blisti.left(3),"fis");
				}
			}
		}


		array<string> whichitem;whichitem.clear();
		array<int> whichitemclass;whichitemclass.clear();
		array<string> howmany;howmany.clear();
		array<string> loadlist;loadlist.clear();

		string firstwep="";


		loadinput.split(loadlist,"-");
		loadlist[0].split(whichitem,",");
		if(hd_debug)A_Log("Loadout: "..loadlist[0]);
		for(int i=0;i<whichitem.size();i++){
			whichitemclass.push(-1);
			howmany.push(whichitem[i].mid(3,whichitem[i].length()));
			whichitem[i]=whichitem[i].left(3);
		}
		for(int i=0;i<allactorclasses.size();i++){
			class<actor> reff=allactorclasses[i];
			if(reff is "HDPickup"||reff is "HDWeapon"){
				string ref;
				if(reff is "HDPickup")ref=getdefaultbytype((class<hdpickup>)(reff)).refid;
				else ref=getdefaultbytype((class<hdweapon>)(reff)).refid;
				if(ref=="")continue;
				for(int j=0;j<whichitem.size();j++){
					if(
						whichitemclass[j]<0
						&&whichitem[j]~==ref
					)whichitemclass[j]=i;
				}
			}
		}
		hdweapon firstwepactor;
		for(int i=whichitemclass.size()-1;i>=0;i--){
			if(whichitem[i]=="all")continue;  //used in hd_forceloadout

			if(whichitemclass[i]<0){
				A_Log("\ca*** Unknown loadout code:  \"\cx"..whichitem[i].."\ca\"",true);
				continue;
			}
			class<actor> reff=allactorclasses[whichitemclass[i]];

			//don't spawn if certain dmflags
			if(
				deathmatch  //sv_noarmor/health normally does nothing outside dm
				&&(
					(sv_noarmor&&getdefaultbytype((class<inventory>)(reff)).bisarmor)
					||(sv_nohealth&&getdefaultbytype((class<inventory>)(reff)).bishealth)
				)
			)continue;

			if(reff is "HDWeapon"){
				if(
					getdefaultbytype((class<HDWeapon>)(reff)).bdebugonly
					&&hd_debug<=0
				){
					A_Log("\caLoadout code \"\cx"..whichitem[i].."\ca\" ("..getdefaultbytype(reff).gettag()..") can only be used in debug mode.",true);
					continue;
				}
				if(!i){
					if(reff is "HDWeaponGiver"){
						let greff=getdefaultbytype((class<HDWeaponGiver>)(reff)).weapontogive;
						if(greff)firstwep=greff.getclassname();
					}else{
						firstwep=reff.getclassname();
					}
				}

				int thismany;
				if(getdefaultbytype((class<hdweapon>)(reff)).bignoreloadoutamount)thismany=1;
				else thismany=clamp(howmany[i].toint(),1,40);

				while(thismany>0){
					thismany--;
					hdweapon newwep;
					if(reff is "HDWeaponGiver"){
						let newgiver=hdweapongiver(spawn(reff,pos));
						newgiver.spawnactualweapon();
						newwep=newgiver.actualweapon;
						newgiver.destroy();
						if(newwep&&hdpickup.checknoloadout(newwep,newwep.refid,true))return;
					}else{
						newwep=hdweapon(spawn(reff,pos));
					}
					if(newwep){
						//clear any randomized garbage
						newwep.weaponstatus[0]=0;

						//apply the default based on user cvar first
						newwep.defaultconfigure(player);

						//now apply the loadout input to overwrite the defaults
						string wepinput=howmany[i];
						wepinput.replace(" ","");
						wepinput=wepinput.makelower();
						newwep.loadoutconfigure(wepinput);

						//the only way I know to force the weapongiver to go last: make it go again
						if(reff is "HDWeaponGiver"){
							let hdwgreff=(class<hdweapongiver>)(reff);
							let gdhdwgreff=getdefaultbytype(hdwgreff);
							newwep.loadoutconfigure(gdhdwgreff.config);
						}

						newwep.actualpickup(self,true);
					}
				}
			}else{
				A_GiveInventory(
					reff.getclassname(),
					clamp(howmany[i].toint(),1,int.MAX)
				);
				let iii=hdpickup(findinventory(reff.getclassname()));
				if(iii){
					iii.amount=min(iii.amount,iii.maxamount);
					if(hdmagammo(iii))hdmagammo(iii).syncamount();

					//(as copypasted from the weapon)
					//now apply the loadout input to overwrite the defaults
					string wepinput=howmany[i];
					wepinput.replace(" ","");
					wepinput=wepinput.makelower();
					iii.loadoutconfigure(wepinput);
				}
			}
		}

		//attend to backpack and contents
		if(loadinput.indexof("-")>=0){
			A_Log("Warning: deprecated loadout code for backpack. This may not be supported in future versions of Hideous Destructor.",true);
			if(hd_debug)A_Log("Backpack Loadout: "..loadlist[1]);
			A_GiveInventory("HDBackpack");
			hdbackpack(FindInventory("HDBackpack",true)).initializeamount(loadlist[1]);
		}

		//select the correct weapon
		HDWeaponSelector.Select(self,firstwep);
	}
}


//type "give loadoutcode" to print a loadout code that best approximates your current inventory.
class LoadoutCode:custominventory{
	default{
		inventory.maxamount 999;
	}
	states{
	pickup:
		TNT1 A 0{
			array<hdbackpack> backpacks;backpacks.clear();

			string lll="";
			bool first=true;
			for(inventory hdppp=inv;hdppp!=null;hdppp=hdppp.inv){
				let hdw=hdweapon(hdppp);
				let hdp=hdpickup(hdppp);
				let bp=hdbackpack(hdppp);
				string refid=(hdw?hdw.refid:hdp?hdp.refid:"");
				if(refid=="")continue;
				if(first){
					lll=refid.." "..hdppp.amount;
					first=false;
				}else if(
					hdw
					&&hdw==player.readyweapon
				){
					//readyweapon gets first position
					lll=hdw.refid.." 1, "..lll;
				}else{
					//append all items to end
					lll=lll..", "..refid;
					if(!bp)lll=lll.." "..hdppp.amount;
				}

				if(
					bp
					&&bp.Storage.TotalBulk>0
				){
					bp.Storage.UpdateStorage(bp,self); // [Ace] Just to make sure it's all correct.
					lll=lll..". ";
					int smax=bp.Storage.Items.Size();
					for(int i=0;i<smax;i++){
						StorageItem curItem=bp.Storage.Items[i];
						if(
							curItem.HaveNone()
							||curItem.refid==""
						)continue;
						lll=lll..curItem.ToLoadoutCode();
						if(i<smax-1)lll=lll..". ";
					}
				}
			}

			int havekey=0;
			if(countinv("BlueCard"))havekey|=1;
			if(countinv("YellowCard"))havekey|=2;
			if(countinv("RedCard"))havekey|=4;
			if(havekey)lll=lll..", key "..havekey;



			string outstring="The loadout code for your current gear is:\n"..(lll==""?"nothing, you're naked.":"\cy"..lll);
			A_Log(outstring,true);
			if(invoker.amount>900){
				string warning="\cxYour \cyhd_loadout1\cx has been automatically updated.";
				A_Log(warning,true);
				let lodstor=loadoutmenuhacktoken(ThinkerFlag.Get(self,"loadoutmenuhacktoken"));
				lodstor.loadout=lll;
			}
		}fail;
	}
}


//type "give loadoutitemlist" to print a list of all loadout codes.
class LoadoutItemList:CustomInventory{
	states{
	pickup:
		TNT1 A 0{
			string blah="All loadout codes for all items including loaded mods:";
			for(int i=0;i<allactorclasses.size();i++){
				class<actor> reff=allactorclasses[i];
				string ref="";
				string nnm="";
				if(reff is "HDPickup"){
					let gdb=getdefaultbytype((class<hdpickup>)(reff));
					nnm=gdb.gettag();if(nnm=="")nnm=gdb.getclassname();
					ref=gdb.refid;
				}else if(reff is "HDWeapon"){
					let gdb=getdefaultbytype((class<hdweapon>)(reff));
					nnm=gdb.gettag();if(nnm=="")nnm=gdb.getclassname();
					ref=gdb.refid;
				}
				if(ref!=""){
					blah=blah.."\n"..ref.."   "..nnm;
				}
			}
			A_Log(blah,true);
		}fail;
	}
}






class InsurgentLoadout:HDPickup{
	default{
		tag "$INSURGENTLOADOUT";
		hdpickup.refid HDLD_INSURG;
		+hdpickup.norandombackpackspawn
		+hdpickup.cheatnogive
		+nointeraction
	}
	override void Tick(){
		if(!owner){destroy();return;}
		let hdp=hdplayerpawn(owner);

		//set up arrays
		array<string> supplies;supplies.clear();
		array<string> weapons;weapons.clear();
		for(int i=0;i<allactorclasses.size();i++){

			let thisclass=((class<hdpickup>)(allactorclasses[i]));
			if(
				thisclass
				&&getdefaultbytype(thisclass).refid!=""
			){
				supplies.push(thisclass.getclassname());
			}

			//build weapon list
			let thiswclass=((class<hdweapon>)(allactorclasses[i]));
			if(!!thiswclass){
				let defw=getdefaultbytype(thiswclass);
				if(
					defw.refid!=""
					&&!defw.bundroppable
					&&!defw.bdebugonly
					&&!defw.bcheatnotweapon
				){
					if(
						!defw.bwimpy_weapon
						&&!defw.binvbar
					)weapons.push(thiswclass.getclassname());
					else supplies.push(thiswclass.getclassname());
				}
			}
		}

		//pick one or two random weapons
		class<inventory> ammoforwep=null;
		int imax=randompick(1,1,1,1,1,1,1,1,1,2,2,2,3);
		int amax=weapons.size()-1;
		for(int i=0;i<imax;i++){
			let thiswep=weapons[random(0,amax)];
			owner.A_GiveInventory(thiswep);
			owner.A_SelectWeapon(thiswep);

			let twg=HDWeapon(owner.findinventory(thiswep));
			if(!!twg){
				twg.loadoutconfigure("");
				let aaa=twg.hdammotype1;
				if(!!aaa)owner.A_GiveInventory(aaa,random(1,twg.hdammogive1*3));
				aaa=twg.hdammotype2;
				if(!!aaa)owner.A_GiveInventory(aaa,random(1,twg.hdammogive2*3));
			}
			if(hdp)hdp.updateencumbrance();
		}

		//give random other gear
		imax=random(3,6);
		amax=supplies.size()-1;
		for(int i=0;i<imax;i++){
			if(hdp)hdp.updateencumbrance();
			let thisclass=supplies[random(0,amax)];
			let thisitem=HDPickup(owner.GiveInventoryType(thisclass));
			int thismax=1;
			if(thisitem){
				if(hd_debug)A_Log("insurgent input: "..thisclass);
				let thismag=hdmagammo(thisitem);
				if(thismag)thismag.syncamount();

				thismax=max(1,HDPickup.MaxGive(owner,thisitem.getclass(),
					thismag?thismag.getbulk():thisitem.bulk
				));

				thisitem.amount=random(1,max(1,thismax>>2));
				if(thismag)thismag.syncamount();
				if(hd_debug)A_Log(thisitem.getclassname().."  "..thisitem.amount);
			}else{
				let thiswitem=HDWeapon(owner.GiveInventoryType(thisclass));
				if(thiswitem){
					if(hd_debug)A_Log("insurgent input: "..thisclass);

					let wb=thiswitem.weaponbulk();
					if(wb)thismax=int(max(1,HDCONST_MAXPOCKETSPACE/wb));
					else thismax=thiswitem.maxamount>>3;

					thiswitem.amount=random(1,max(1,thismax>>2));
					if(hd_debug)A_Log(thiswitem.getclassname().."  "..thiswitem.amount);
				}
			}
		}

		let bp=hdbackpack(owner.FindInventory("HDBackpack",true));
		if(bp&&!random(0,31))bp.randomcontents();

		destroy();
	}
}

extend class HDStaticHandlers{
	ui void DumpRefList() {
		string reflist;
		int jw=0;int jp=0;
		for(int i=0;i<allactorclasses.size();i++){
			class<actor> reff=allactorclasses[i];
			if(reff is "HDPickup"){
				let ref=getdefaultbytype((class<hdpickup>)(reff));
				if(ref.refid!=""){
					string lrefid=ref.refid.makelower();
					if(!(jp%5))reflist=reflist.."\n";jp++;
					reflist=reflist.."\n\cy"..ref.refid.."\cj   "..ref.gettag();
				}
			}else if(reff is "HDWeapon"){
				let ref=getdefaultbytype((class<hdweapon>)(reff));
				if(
					ref.refid!=""
					&&(
						!ref.bdebugonly
						||hd_debug>0
					)
				){
					string lrefid=ref.refid.makelower();
					if(!(jw%5))reflist="\n"..reflist;jw++;

					//determine colour
					string refidcol="\n\c"..(ref.bdebugonly?"u":(ref.bwimpy_weapon?"y":"x"));

					//if there are loadout codes, add them
					string rgt=ref.gettag();
					string loc=ref.loadoutcodes;
					if(loc!="")rgt=rgt..loc;

					//treat wimpy weapons as inventory items
					if(ref.bwimpy_weapon)
						reflist=reflist..refidcol..ref.refid.."\cj   "..rgt;
					else
						reflist=refidcol..ref.refid.."\cj   "..rgt..reflist;
				}
			}
		}
		reflist=reflist.mid(1); //get rid of the first "\n"
		console.printf("\cr=== \cjLoadout Codes \cr===\n"..reflist);
	}
}
