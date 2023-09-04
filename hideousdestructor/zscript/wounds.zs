// ------------------------------------------------------------
// SO MUCH BLOOD
// ------------------------------------------------------------

//a thinker that constantly bleeds
enum HDBleedingWoundFlags{
	HDBW_FINDPATCHED=1,
	HDBW_FINDSEALED=2,
}
class HDBleedingWound:Thinker{
	actor bleeder;
	actor source;
	double depth;
	double width;
	double patched;
	double sealed;
	double regenrate;
	name damagetype;
	vector2 location;
	int age;
	override void tick(){
		if(
			!bleeder
			||(
				age
				&&checkdestroy()
			)
		){
			destroy();
			return;
		}
		age++;

		if(checkskip())return;

		comeundone();

		if(depth)bleedout();

		regenerate();

		//console.printf(bleeder.gettag().."   "..width.." x "..depth.."/"..patched.."/"..sealed.."   = "..woundcount(bleeder));
	}
	static hdbleedingwound inflict(
		actor bleeder,
		double depth,
		double width=1,
		bool hitvital=false,
		actor source=null,
		name damagetype="piercing",
		vector3 hitlocation=(0,0,0)
	){
		if(!HDBleedingWound.canbleed(bleeder))return null;

		vector2 checklocation=(-999,-999);
		if(hitlocation!=(0,0,0)){
			checklocation.x=bleeder.deltaangle(bleeder.angle,HDMath.AngleTo(bleeder.pos.xy,hitlocation.xy,true));
			checklocation.y=(hitlocation.z-bleeder.pos.z)/bleeder.height;

//			console.printf(level.time.."  wound location:  "..checklocation);

			//add to existing wound in same location
			HDBleedingWound bldw=null;
			thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
			while(bldw=HDBleedingWound(bldit.next())){
				if(
					!bldw
					||bldw.bleeder!=bleeder
				)continue;
				double diffx=abs(bldw.location.x-checklocation.x)*bleeder.radius*(6./360.);
				double diffy=abs(bldw.location.y-checklocation.y)*bleeder.height;
				double maxdiff=max(bldw.width,width)*0.1;
				if(
					maxdiff<8
					&&!!bldw
					&&bldw.bleeder==bleeder
					&&diffx<maxdiff
					&&diffy<maxdiff
				){
//					console.printf(level.time.."   wound in same location merged:  "..maxdiff);
					maxdiff=min(diffx,diffy);
					bldw.width=max(bldw.width,width)+maxdiff;
					bldw.depth=hitvital?-1:depth+max(0,bldw.depth-maxdiff);
					bldw.source=source;  //yes, even if null, think about it
					bldw.damagetype=damagetype;
					return bldw;
				}
			}
		}


		let wwnd=new("HDBleedingWound");
		wwnd.bleeder=bleeder;
		wwnd.source=source;
		wwnd.damagetype=damagetype;

		wwnd.width=width;
		wwnd.depth=hitvital?-1:depth;
		wwnd.location=checklocation;
		wwnd.age=0;

		//always some fighting chance. theoretically.
		if(wwnd.depth<0)wwnd.depth*=-bleeder.radius*3.;

		let hpl=hdplayerpawn(bleeder);
		if(hpl){
			hpl.lastthingthatwoundedyou=source;
			wwnd.regenrate=0.00001;
		}else{
			wwnd.regenrate=1.+0.01*sqrt(bleeder.spawnhealth());
		}

		return wwnd;
	}
	clearscope static bool canbleed(actor b){
		return(
			!hd_nobleed
			&&!!b
			&&b.bshootable
			&&!b.bnoblood
			&&!b.bnoblooddecals
			&&!b.bnodamage
			&&!b.bdormant
			&&b.health>0
			&&b.bloodtype!="ShieldNeverBlood"
			&&(
				!hdmobbase(b)
				||!hdmobbase(b).bdoesntbleed
			)&&b.height>0
		);
	}
	clearscope static int woundcount(actor b){
		double amt=0;
		HDBleedingWound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		while(bldw=HDBleedingWound(bldit.next())){
			if(
				bldw
				&&bldw.bleeder==b
			){
				amt+=
					bldw.width
					+bldw.depth
					+bldw.patched*0.6
					+bldw.sealed*0.3
				;
			}
		}
		return (int(amt)>>1);
	}
	clearscope static HDBleedingWound findbiggest(
		actor bleeder,
		int flags=0
	){
		double deepest=0;
		HDBleedingWound bldwres=null;
		HDBleedingWound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		while(bldw=HDBleedingWound(bldit.next())){
			if(!bldw)continue;
			double deep=bldw.depth;
			if(flags&HDBW_FINDPATCHED)deep+=bldw.patched;
			if(flags&HDBW_FINDSEALED)deep+=bldw.sealed;
			if(
				bldw.bleeder==bleeder
				&&deepest<deep
			){
				deepest=deep;
				bldwres=bldw;
			}
		}
		return bldwres;
	}
	bool patch(
		double amount,
		bool seal=false
	){
		if(
			amount<=0
			||(
				depth<=0
				&&(
					!seal
					||patched<=0
				)
			)
		)return false;
		if(
			seal
			&&patched>0
		){
			double oldamt=amount;
			if(amount>patched)amount=patched;
			patched-=amount;
			sealed+=amount;
			amount=oldamt-amount;
		}
		if(amount>0){
			if(amount>depth)amount=depth;
			depth-=amount;
			if(seal)sealed+=amount;
			else patched+=amount;
		}
		return true;
	}
	static hdbleedingwound findandpatch(
		actor bleeder,
		double amount,
		int flags=0
	){
		let hdb=hdbleedingwound.findbiggest(bleeder,flags);
		if(hdb)hdb.patch(amount,flags);
		return hdb;
	}
	static void clearall(actor bleeder){
		HDBleedingWound bldw=null;
		thinkeriterator blditstat=thinkeriterator.create("HDBleedingWound",thinker.STAT_STATIC);
		while(bldw=HDBleedingWound(blditstat.next())){
			if(
				!!bldw
				&&bldw.bleeder==bleeder
			){
				bldw.changestatnum(thinker.STAT_DEFAULT);
			}
		}
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		while(bldw=HDBleedingWound(bldit.next())){
			if(
				!!bldw
				&&bldw.bleeder==bleeder
			){
				bldw.depth=0;
				bldw.width=0;
				bldw.patched=0;
				bldw.sealed=0;
			}
		}
	}

	virtual void comeundone() {
		//bandages/scabs get undone
		let hdp=hdplayerpawn(bleeder);
		if(
			patched>0
			&&frandom(0,2000)<(width+IsMoving.Count(bleeder))*0.5
		){
			double unpatch=frandom(0,(patched*.1));
			patched-=unpatch;
			depth+=unpatch;
		}
	}
	virtual void bleedout() {
		//blood supply is lost from wound
		let hdp=hdplayerpawn(bleeder);
		int bleedrate=int(width);
		if(bleedrate<1){
			double www=width-int(width);
			if(frandom(0,1)<www)bleedrate=1;
		}
		int bleeds=(bleedrate>>3)+random(-1,1);

		if(hdp){
			int dm=(random(10,int(bleedrate))-random(0,hdp.bloodpressure))*4/10;
			if(dm>0){
				hdp.damagemobj(
					hdp,source,dm,"bleedout",
					DMG_THRUSTLESS
					|(hdp.bloodloss>HDCONST_MAXBLOODLOSS?DMG_FORCED:0)
				);
			}else bleeds=0;
		}else{
			int bled=bleeder.damagemobj(bleeder,source,bleedrate,"bleedout",DMG_NO_PAIN|DMG_THRUSTLESS);
			if(bleeder&&bleeder.health<1&&width<frandom(10,60))bleeder.deathsound="";
		}
		while(bleeds>0){
			bleeds--;
			spawnblood();
		}
	}
	virtual void spawnblood() {
		//visual feedback
		double bleedradius=bleeder.radius*0.6;
		bool gbg;actor blood;
		[gbg,blood]=bleeder.A_SpawnItemEx(bleeder.bloodtype,
			frandom(-bleedradius,bleedradius),frandom(-bleedradius,bleedradius),
			bleeder.height*frandom(0.,0.3),
			flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
		);
		if(blood){
			blood.bambush=true;
			blood.bmissilemore=true; //used to avoid converting to shield
			blood.alpha=1.;
			blood.scale*=0.8+0.05*width;
			blood.gravity=HDCONST_GRAVITY;
		}
	}
	virtual void regenerate() {
		//slowly regenerate
		if(hdplayerpawn(bleeder)){
			double rgr=regenrate*100;
			if(depth>0){
				double rrr=depth>1.?regenrate:rgr;
				depth=max(0,depth-rrr);
				patched+=rrr;
			}
			else if(patched>0){
				double rrr=patched>1.?regenrate:rgr;
				patched=max(0,patched-rrr);
				sealed+=rrr;
			}
			else if(sealed>0){
				double rrr=(sealed>1.?regenrate:rgr)*10;
				sealed=max(0,sealed-rrr);
			}
		}else{
			if(depth>0){
				depth=max(0,depth-regenrate);
				patched+=regenrate;
			}else if(patched>0){
				patched=max(0,patched-regenrate*0.6);
				sealed+=regenrate*0.5;
			}else if(sealed>0){
				//HDMobBase.bodydamage already handles this, just clear it out
				sealed=max(0,sealed*0.1-regenrate*2.);
			}
		}
	}
	virtual bool checkdestroy() {
		return(
			!bleeder
			||(
				depth<=0
				&&(
					bleeder.health<1
					||(
						patched<=0
						&&sealed<=0
					)
				)
			)
			||bleeder.binvulnerable
			||!bleeder.bshootable
			||(
				!!bleeder.player
				&&bleeder.player.cheats&(CF_GODMODE2|CF_GODMODE)
			)
			||hd_nobleed
		);
	}
	virtual bool checkskip(){
		if (bleeder.isfrozen()) return true;
		let hdp=hdplayerpawn(bleeder);
		if(
			(
				hdp
				&&hdp.beatcount>0
			)||(
				!hdp
				&&(level.time&(1|2|4|8|16))
			)
		)return true;
		return false;
	}

	static void SetStatics(){
		HDBleedingWound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		while(bldw=HDBleedingWound(bldit.next())){
			if(
				!!bldw
				&&!!bldw.bleeder
				&&!!bldw.bleeder.player	
			){
				bldw.changestatnum(STAT_STATIC);
			}
		}
	}
	static void UnSetStatics(){
		HDBleedingWound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound",STAT_STATIC);
		while(bldw=HDBleedingWound(bldit.next())){
			if(!!bldw){
				bldw.changestatnum(STAT_DEFAULT);
				double healamount=0.05;
				double keepamount=1.-healamount;
				bldw.width*=keepamount;
				bldw.sealed=(bldw.patched*healamount) + (bldw.sealed*keepamount);
				bldw.patched=bldw.depth + (bldw.patched*keepamount);
				bldw.depth=0;
			}
		}
	}
}



//inventory hack to allow Decorate-only mods to cause HD bleeding
//multiples of 1000 are counted as bleedrate
//e.g. 24010 = 10 bleedpoints at a rate of 24
//you can't give over 999 bleedpoints in one go
class HDWoundInventory:Inventory{
	default{inventory.maxamount int.MAX;}
	override void AttachToOwner(actor other){
		if(amount<1000)HDBleedingWound.Inflict(other,amount);
		else{
			HDBleedingWound.Inflict(other,amount%1000,amount/1000);
		}
		destroy();
	}
}
