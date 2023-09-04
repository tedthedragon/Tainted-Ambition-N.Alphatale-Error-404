//-------------------------------------------------
// Equipped gear and damage handling
//-------------------------------------------------

//put your socks on before your shoes.
//any wearable gadget should be added to this function.
//see backpack for the minimum setup required.
extend class HDPlayerPawn{
	//returns whether the selected layer can be removed
	int striptime;
	static bool CheckStrip(
		actor caller,
		actor checkitem,
		bool remove=true,
		bool silent=false
	){
		let hdp=hdplayerpawn(caller);
		if(hdp&&hdp.striptime>0)return false;

		let cp=hdpickup(checkitem);
		let cw=hdweapon(checkitem);
		if(
			!cp
			&&!cw
			&&checkitem!=caller
		)return true;

		//set checkitem to the same as caller to strip everything
		int which=cp?cp.wornlayer:cw?cw.wornlayer:1;

		inventory preventory=null;

		//the thing in your hands in front of you is always the top layer
		if(
			caller.player
			&&hdweapon(caller.player.readyweapon)
			&&hdweapon(caller.player.readyweapon).isbeingworn()
		)preventory=caller.player.readyweapon;
		else{

			//go through inventory for things being worn
			for(let item=caller.inv;item!=NULL;item=item.inv){
				if(item==checkitem)continue;

				let hp=HDPickup(item);
				let hw=HDWeapon(item);
				if(
					(hp&&hp.wornlayer>=which)
					||(
						hw
						&&hw.wornlayer>=which
						&&hw.isbeingworn()
					)
				){
					if(
						!preventory
						||(
							hdpickup(preventory)
							&&(
								(hp&&hdpickup(preventory).wornlayer<hp.wornlayer)
								||(hw&&hdpickup(preventory).wornlayer<hw.wornlayer)
							)
						)
					)preventory=item;
				}
			}
		}


		if(preventory){
			if(remove){
				caller.dropinventory(preventory);
				if(!silent)caller.A_Log(StringTable.Localize("$WORNREMOVING")..preventory.gettag()..StringTable.Localize("$WORNFIRST"),true);
				if(hdp)hdp.striptime=25;
			}
			return false;
		}
		return true;
	}
}
enum StripArmourLevels{
	STRIP_ARMOUR=1000,
	STRIP_RADSUIT=2000,
	STRIP_BACKPACK=3000,
}




//Inventory items that affect bullets and damage before they are finally inflicted on any HDMobBase or HDPlayerPawn
//New class to avoid searching through all your ammo, consumables, etc. each time
class HDDamageHandler:HDPickup{
	//determines order in which damage handlers are called
	//higher is earlier
	double priority;
	property priority: priority;

	default{
		-inventory.invbar
		-hdpickup.fitsinbackpack
		+hdpickup.notinpockets
		+hdpickup.nevershowinpickupmanager
	}

	//called from HDPlayerPawn and HDMobBase's DamageMobj
	//should modify amount and kind of damage
	virtual int,name,int,double,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound=0,
		int toburn=0,
		int tostun=0,
		int tobreak=0
	){
		return damage,mod,flags,towound,toburn,tostun,tobreak;
	}
	virtual int,name,int,double,int,int,int,int HandleDamagePost(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound=0,
		int toburn=0,
		int tostun=0,
		int tobreak=0,
		int toaggravate=0
	){
		return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;
	}

	//called from HDBulletActor's OnHitActor
	//should modify the bullet itself - then let it inflict damage
	virtual double,double OnBulletImpact(
		HDBulletActor bullet,
		double pen,
		double penshell,
		double hitangle,
		double deemedwidth,
		vector3 hitpos,
		vector3 vu,
		bool hitactoristall
	){
		return pen,penshell;
	}

	//get a list of damage handlers from an actor's inventory
	//higher priority numbers are listed (and thus processed) before lower numbers
	static void GetHandlers(
		actor owner,
		out array<HDDamageHandler> handlers
	){
		handlers.Clear();
		if(!owner)return;

		for(let item=owner.inv;item!=NULL;item=item.inv){
			let handler=HDDamageHandler(item);
			if(!handler)continue;

			bool didInsert=false;
			for(int i=0;i<handlers.Size();i++){
				if(handlers[i].priority < handler.priority){
					handlers.Insert(i,handler);
					didInsert = true;
					break;
				}
			}
			if(!didInsert)handlers.Push(handler);
		}
	}
}
