// ------------------------------------------------------------
// .355 Ammo
// ------------------------------------------------------------
class HDSpent355:HDSpent9mm{default{yscale 0.85;}}
class HDRevolverAmmo:HDPistolAmmo{
	default{
		xscale 0.7;
		yscale 0.85;
		inventory.pickupmessage "$PICKUP_RevolverAmmoPlural";
		hdpickup.refid HDLD_355;
		tag "$355ROUND";
		hdpickup.bulk ENC_355;
	}
	override string PickupMessage(){
		if(amount==1)return Stringtable.Localize("$PICKUP_RevolverAmmo");
		return super.PickupMessage();
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(10,72,"HD355BoxPickup","TEN9A0","PRNDA0");
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDRevolver");
	}
}
class HD355BoxPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of .355"
		//$Sprite "3BOXA0"
		scale 0.4;
		hdupk.amount 72;
		hdupk.pickupsound "weapons/pocket";
		hdupk.pickupmessage "$PICKUP_RevolverAmmoPlural";
		hdupk.pickuptype "HDRevolverAmmo";
	}
	states{
	spawn:
		3BOX A -1;
	}
}
class DeinoSpawn:actor{
	override void postbeginplay(){
		super.postbeginplay();
		let box=spawn("HD355BoxPickup",pos,ALLOW_REPLACE);
		if(box)HDF.TransferSpecials(self,box);
		spawn("HDRevolver",pos,ALLOW_REPLACE);
		self.Destroy();
	}
}
