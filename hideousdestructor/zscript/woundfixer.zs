//-------------------------------------------------
// Generic wound interface
//-------------------------------------------------
class HDWoundFixer:HDWeapon{
	default{
		+weapon.wimpy_weapon +weapon.no_auto_switch +weapon.cheatnotweapon
		+nointeraction
	}
	static bool DropMeds(actor caller,int amt=1){
		if(!caller)return false;
		array<inventory> items;items.clear();
		for(inventory item=caller.inv;item!=null;item=!item?null:item.inv){
			if(
				item.bishealth
			){
				items.push(item);
			}
		}
		if(!items.size())return false;
		double aang=caller.angle;
		double ch=items.size()?20.:0;
		caller.angle-=ch*(items.size()-1)*0.5;
		for(int i=0;i<items.size();i++){
			caller.a_dropinventory(items[i].getclassname(),amt>0?amt:items[i].amount);
			caller.angle+=ch;
		}
		caller.angle=aang;
		return true;
	}
	hdbleedingwound targetwound;
	override void DropOneAmmo(int amt){
		DropMeds(owner,clamp(amt,1,10));
	}
	//used for injectors
	action void A_TakeInjector(class<inventory> injectortype){
		let mmm=HDMagAmmo(findinventory(injectortype));
		if(mmm){
			mmm.amount--;
			if(mmm.amount<1)mmm.destroy();
			else if(mmm.mags.size())mmm.mags.pop();
		}
	}
	//return any worn item that would block the action
	static inventory CheckCovered(
		actor caller,
		int flags
	){
		//go through inventory for things being worn
		for(let item=caller.inv;item!=NULL;item=item.inv){
			let hp=HDPickup(item);
			if(
				hp
				&&hp.wornlayer>0
				&&(
					hp.bfullcoverage
					||(
						!(flags&CHECKCOV_ONLYFULL)
						&&(
							(
								(flags&CHECKCOV_CHECKBODY)
								&&hp.bbodycoverage
							)||(
								(flags&CHECKCOV_CHECKFACE)
								&&hp.bfacecoverage
							)
						)
					)
				)
			){
				return hp;
			}
		}
		return null;
	}
	action void A_TakeOffFirst(
		string itemtag,
		int time=100
	){
		if(DoHelpText())A_WeaponMessage(StringTable.Localize("$WOUNDFIX_TAKEOFF1")..itemtag..StringTable.Localize("$WOUNDFIX_TAKEOFF2"),time);
	}
	states{
	reload:
		TNT1 A 4{
			if(player&&!(player.oldbuttons&BT_RELOAD))HDPlayerPawn.CheckStrip(self,self,silent:true);
			A_ClearRefire();
		}
		goto readyend;
	}
}
