// ------------------------------------------------------------
// 7.76mm Ammo
// ------------------------------------------------------------
class SevenMilAmmo:HDRoundAmmo{
	default{
		+forcexybillboard +cannotpush
		+inventory.ignoreskill
		+hdpickup.multipickup
		xscale 0.7;yscale 0.8;
		inventory.pickupmessage "$Pickup_7mmRound";
		hdpickup.refid HDLD_SEVNMIL;
		tag "$TAG_7MMAMMO";
		hdpickup.bulk ENC_776;
		inventory.icon "TEN7A0";
	}
	override string pickupmessage(){
		if(amount>1)return Stringtable.Localize("$Pickup_7mmRoundPlural");
		return super.pickupmessage();
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(10,50,"HD7mBoxPickup","TEN7A0","RBRSA0");
		if(amount==10)scale.y=(0.8*0.83);
		else scale.y=0.8;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("LiberatorRifle");
		itemsthatusethis.push("BossRifle");
		itemsthatusethis.push("AutoReloader");
	}
	states{
	spawn:
		RBRS A -1;
		TEN7 A -1;
	}
}
class SevenMilAmmoRecast:SevenMilAmmo{
	default{
		inventory.pickupmessage "$Pickup_7mmRoundRecast";
		hdpickup.refid "";
		tag "$TAG_7MMAMMOR";
		inventory.icon "TEN7A0";
		hdpickup.refid HDLD_SEVNREC;
	}
	override void SplitPickup(){
		//set boxnum to 0 so the box is never spawned
		SplitPickupBoxableRound(10,0,"HD7mBoxPickup","TEN7A0","RBRSA0");
		if(amount==10)scale.y=(0.8*0.83);
		else scale.y=0.8;
	}
}

class HD7mMag:HDMagAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Liberator Magazine"
		//$Sprite "RMAGA0"

		hdmagammo.maxperunit 3030;
		hdmagammo.roundtype "SevenMilAmmo";
		hdmagammo.roundbulk ENC_776_LOADED;
		hdmagammo.magbulk ENC_776MAG_EMPTY;
		hdpickup.refid HDLD_SEVNMAG;
		tag "$TAG_7MMAG";
		inventory.pickupmessage "$PICKUP_7MMAG";
		scale 0.8;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite=(thismagamt>0)?"RMAGA0":"RMAGB0";
		return magsprite,"RBRSA3A7","SevenMilAmmo",1.7;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("BossRifle");
	}

	override int GetMagHudCount(int input){return input%100;}
	override void DrawRoundCount(HDStatusBar sb,HDPlayerPawn hpl,name roundsprite,double scl,int offx,int offy){
		offx+=40;
		scl=1.6;
		sb.drawstring(
			sb.pSmallFont,sb.FormatNumber(hpl.countinv("SevenMilAmmo")),
			(offx+2,offy),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,
			font.CR_BROWN
		);
		sb.drawimage(roundsprite,(offx,offy),
			sb.DI_SCREEN_CENTER|sb.DI_ITEM_RIGHT_TOP,
			scale:(scl,scl)
		);
		if(!hpl.countinv("SevenMilAmmoRecast"))return;
		offy+=20;
		sb.drawstring(
			sb.pSmallFont,sb.FormatNumber(hpl.countinv("SevenMilAmmoRecast")).." \cu[Use] load recast",
			(offx+2,offy),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,
			font.CR_BROWN
		);
		sb.drawimage(roundsprite,(offx,offy),
			sb.DI_SCREEN_CENTER|sb.DI_ITEM_RIGHT_TOP,
			scale:(scl,scl)
		);
	}

	override void Consolidate(){
		SyncAmount();
		if(amount<2)return;
		int totalrounds=0;
		int totalfullets=0;
		for(int i=0;i<amount;i++){
			totalrounds+=mags[i]%100;
			totalfullets+=mags[i]/100;
			mags[i]=0;
		}
		int mpu=maxperunit%100;
		for(int i=0;i<amount;i++){
			int toinsert=min(mpu,totalrounds);
			mags[i]=toinsert;
			totalrounds-=toinsert;

			if(totalfullets>0){
				int toinsertfullet=min(totalfullets,toinsert);
				mags[i]+=100*toinsertfullet;
				totalfullets-=toinsertfullet;
			}

			if(totalrounds<1)break;
		}
	}

	static bool CheckRecast(int amt,int amt2=-1){
		//method 1: compare total rounds to total that are recasts
		if(amt2>=0)return
			amt<=amt2
			||random(1,amt)<=amt2
		;

		//method 2: extract numbers from "hundreds are NOT recasts" method
		int fullets=amt/100;
		int rounds=amt%100;
		return
			fullets<1
			||random(1,rounds)>fullets
		;
	}
	override void DoEffect(){
		if(
			!!owner
			&&!!owner.player
			&&(
				owner.player.cmd.buttons&BT_USE
				||!owner.countinv("SevenMilAmmo")
			)
			&&owner.countinv("SevenMilAmmoRecast")
		)roundtype="SevenMilAmmoRecast";
		else roundtype="SevenMilAmmo";
		super.DoEffect();
	}

	override bool Extract(){
		SyncAmount();
		if(
			mags.size()<1
			||mags[mags.size()-1]<1
		)return false;

		class<inventory> rndtp="SevenMilAmmo";
		int mindex=mags.size()-1;

		if(CheckRecast(mags[mindex]))rndtp="SevenMilAmmoRecast";
		else mags[mindex]-=100;

		if(HDPickup.MaxGive(owner,rndtp,roundbulk)>=1)HDF.Give(owner,rndtp,1);
		else HDPickup.DropItem(owner,rndtp,1);
		owner.A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);

		mags[mindex]--;
		return true;
	}
	override bool Insert(){
		SyncAmount();
		if(
			mags.size()<1
			||mags[mags.size()-1]%100>=maxperunit%100
			||!owner.countinv(roundtype)
		)return false;

		owner.A_TakeInventory(roundtype,1,TIF_NOTAKEINFINITE);
		owner.A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
		int mindex=mags.size()-1;
		mags[mindex]++;

		//add the flag if it's a regular non-recast
		if(roundtype=="SevenMilAmmo")mags[mindex]+=100;

		return true;
	}

	override double getbulkonemag(int which){
		return magbulk+roundbulk*(mags[which]%100);
	}

	states{
	spawn:
		RMAG A -1;
		stop;
	spawnempty:
		RMAG B -1 A_SpawnEmpty();
		stop;
	}
}
class HD7mClip:HD7mMag{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Boss Clip"
		//$Sprite "RCLPA0"

		hdmagammo.maxperunit 1010;
		hdmagammo.roundtype "SevenMilAmmo";
		hdmagammo.roundbulk ENC_776;
		hdmagammo.magbulk ENC_776CLIP_EMPTY;
		hdpickup.refid HDLD_SEVCLIP;
		tag "$TAG_7MCLIP";
		inventory.pickupmessage "$PICKUP_7MCLIP";
		scale 0.6;
		inventory.maxamount 1000;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite;
		thismagamt=thismagamt%100;
		if(thismagamt>8)magsprite="RCLPA0";
		else if(thismagamt>6)magsprite="RCLPB0";
		else if(thismagamt>4)magsprite="RCLPC0";
		else if(thismagamt>2)magsprite="RCLPD0";
		else if(thismagamt>0)magsprite="RCLPE0";
		else magsprite="RCLPF0";
		return magsprite,"RBRSA3A7","SevenMilAmmo",1.5;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("LiberatorRifle");
	}
	states(actor){
	spawn:
		RCLP ABCDE -1 nodelay{
			if(!mags.size()){destroy();return;}
			int amt=mags[0]%100;
			if(amt>8)frame=0;
			else if(amt>6)frame=1;
			else if(amt>4)frame=2;
			else if(amt>2)frame=3;
			else if(amt>0)frame=4;
		}stop;
	spawnempty:
		RCLP F -1;
		stop;
	}
}
//(primers and bullet lead can be cannibalized from 4.26mm rounds)
class SevenMilBrass:HDAmmo{
	default{
		+inventory.ignoreskill +forcexybillboard +cannotpush
		+hdpickup.multipickup
		+hdpickup.cheatnogive
		height 16;radius 8;
		tag "$TAG_7MCASING";
		hdpickup.refid HDLD_SEVNBRA;
		hdpickup.bulk ENC_776B;
		xscale 0.7;yscale 0.8;
		inventory.pickupmessage "$Pickup_7mmBrass";
		inventory.icon "RBRSA3A7";
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("LiberatorRifle");
		itemsthatusethis.push("AutoReloader");
	}
	states{
	spawn:
		RBRS A -1;
		stop;
	}
}

class LiberatorEmptyMag:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		HDMagAmmo.SpawnMag(self,"HD7mMag",0);
		destroy();
	}
}
class HDSpent7mm:HDUPK{
	default{
		+missile
		+hdupk.multipickup
		height 4;radius 2;
		bouncetype "doom";
		hdupk.pickuptype "SevenMilBrass";
		hdupk.pickupmessage "$Pickup_7mmBrass";

		bouncesound "misc/casing";
		bouncefactor 0.4;
		xscale 0.7;yscale 0.8;
		maxstepheight 0.6;
	}
	states{
	spawn:
		RBRS A 2{
			if(bseesdaggers)angle-=45;else angle+=45;
			if(pos.z-floorz<2&&abs(vel.z)<2.)setstatelabel("death");
		}wait;
	death:
		RBRS A -1{
			if(hdmath.deathmatchclutter())A_SetTics(140);
			bmissile=false;
			vel.xy+=(pos.xy-prev.xy)*max(abs(vel.z),abs(prev.z-pos.z),1.);
			if(vel.xy==(0,0)){
				double aaa=angle-90;
				vel.x+=cos(aaa);
				vel.y+=sin(aaa);
			}else{
				A_FaceMovementDirection();
				angle+=90;
			}
			let gdb=getdefaultbytype(pickuptype);
			A_SetSize(gdb.radius,gdb.height);
			return;
		}stop;
	}
}
class HDLoose7mm:HDSpent7mm{
	override void postbeginplay(){
		HDUPK.postbeginplay();
	}
	default{
		bouncefactor 0.6;
		hdupk.pickuptype "SevenMilAmmo";
		hdupk.pickupmessage "$Pickup_7mmRound";
	}
}
class HDLoose7mmRecast:HDLoose7mm{
	default{
		hdupk.pickuptype "SevenMilAmmoRecast";
		hdupk.pickupmessage "$Pickup_7mmRoundRecast";
	}
}

class HD7mBoxPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of 7.76mm"
		//$Sprite "7BOXA0"

		scale 0.4;
		hdupk.amount 50;
		hdupk.pickupsound "weapons/pocket";
		hdupk.pickupmessage "$Pickup_7mmRoundPlural";
		hdupk.pickuptype "SevenMilAmmo";
	}
	states{
	spawn:
		7BOX A -1;
	}
}

