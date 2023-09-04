// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if they got........ damaged.
// ------------------------------------------------------------
extend class HDMobBase{
	int stunned;
	int bodydamage;
	int damagerecoil;
	int bloodloss;
	int maxbloodloss;
	int timesdied;
	property maxbloodloss:maxbloodloss;
	int downedframe;
	property downedframe:downedframe;
	int maxshields;
	property shields:maxshields;
	void resetdamagecounters(){
		stunned=0;
		damagerecoil=0;
		bloodloss=0;
		reactiontime=default.reactiontime;
		HDBleedingWound.clearall(self);
		A_SetInventory("HDMagicShield",maxshields);

		//not really damage stuff but oh well
		lasttargetdist=maxtargetrange;
	}

	static bool inpainablesequence(actor caller){
		state curstate=caller.curstate;
		return (
			!caller.bdormant
			&&!caller.bcorpse
			&&caller.health>0
			&&!caller.instatesequence(curstate,caller.resolvestate("falldown"))
			&&!caller.instatesequence(curstate,caller.resolvestate("raise"))
			&&!caller.instatesequence(curstate,caller.resolvestate("ungib"))
			&&!caller.instatesequence(curstate,caller.resolvestate("death"))
		);
	}
	static bool forcepain(actor caller){
		if(
			!caller
			||caller.bDORMANT
			||caller.bnopain
			||!caller.bshootable
			||!caller.findstate("pain",true)
			||caller.health<1
			||!hdmobbase.inpainablesequence(caller)
			||(hdplayerpawn(caller)&&hdplayerpawn(caller).incapacitated>0)
		)return false;
		caller.setstatelabel("pain");
		return true;
	}


	//standard doom knockback is way too much
	override void ApplyKickback(Actor inflictor, Actor source, int damage, double angle, Name mod, int flags){
		if(
			mod=="hot"
			||mod=="cold"
			||mod=="balefire"
		)return;
		else if(mod=="piercing")damage>>=4;
		else if(
			mod=="bashing"
			||mod=="electrical"
		)damage>>=1;
		else damage>>2;
		if(damage>0){
			vector3 vvv=vel;
			super.ApplyKickback(inflictor,source,damage,angle,mod,flags);
			double rrr=radius*0.3;
			if(
				!bonmobj
				||floorz<pos.z
				||abs(vvv.x-vel.x)>rrr
				||abs(vvv.y-vel.y)>rrr
			)bnodropoff=false;
		}
	}


	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if (bDORMANT)
		{
			return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
		}
		
		//bypass mdk
		if(damage==TELEFRAG_DAMAGE){
			bodydamage+=(spawnhealth()+gibhealth)*100;
			return super.damagemobj(
				inflictor,source,damage,
				"Telefrag",DMG_THRUSTLESS|DMG_NO_PAIN
			);
		}

		int sphlth=spawnhealth();
		bdontdrop=(inflictor==self&&mod!="bleedout");


		if(!inpainablesequence(self))flags|=DMG_NO_PAIN;


		//deal with some synonyms
		HDMath.ProcessSynonyms(mod);

		//process all items (e.g. armour) that may affect the damage
		array<HDDamageHandler> handlers;
		if(
			!(flags&DMG_FORCED)
			&&damage<TELEFRAG_DAMAGE
		){
			HDDamageHandler.GetHandlers(self,handlers);
			for(int i=0;i<handlers.Size();i++){
				let hhh=handlers[i];
				if(hhh&&hhh.owner==self)
				[damage,mod,flags]=hhh.HandleDamage(
					damage,
					mod,
					flags,
					inflictor,
					source
				);
			}
		}




		//if any other stuff is to be added dealing with damage types, add them here
		//alternatively consider a virtual

		bool inpain=instatesequence(curstate,resolvestate("pain"));

		//bashing
		if(mod=="bashing"){
			stunned+=(damage<<(inpain?3:2));
			damage>>=2;
			int bashthreshold=health-(sphlth>>3);
			if(
				damage>=bashthreshold
				&&damage<(sphlth>>random(0,2))
				&&damage<(health<<5)
				&&(
					!instatesequence(curstate,resolvestate("falldown"))
					||random(0,(sphlth>>1))
				)
			){
				damage=max(0,bashthreshold);
				if(!(flags&DMG_NO_PAIN))forcepain(self);
			}
		}else{
			//add stun for all other damage types
			stunned+=(damage>>(inpain?2:3));
		}



		//process all items that may affect damage after all the above
		if(
			!(flags&DMG_FORCED)
			&&damage<TELEFRAG_DAMAGE
		){
			HDDamageHandler.GetHandlers(self,handlers);
			for(int i=0;i<handlers.Size();i++){
				let hhh=handlers[i];
				if(hhh&&hhh.owner==self)
				[damage,mod,flags]=hhh.HandleDamagePost(
					damage,
					mod,
					flags,
					inflictor,
					source
				);
			}
		}


		//additional knockdown stun
		if(
			//check to make sure we're not already doing it
			//if already doing so, make sure the damage never goes into painstate
			instatesequence(curstate,resolvestate("falldown"))
		){
			if(
				!bnopain
				&&!(flags&DMG_NO_PAIN)
				&&damage>painthreshold
				&&random(0,255)<painchance
			)A_Vocalize(painsound);
			flags|=DMG_NO_PAIN;
		}else if(
			!bnopain
			&&!bnoincap
			&&health>0
			&&health<(spawnhealth()>>2)
			&&findstate("falldown")
			&&max(stunned,damage)>random(health,(sphlth<<4))
		){
			setstatelabel("falldown");
			flags|=DMG_NO_PAIN;
		}

		//bleeding
		if(mod=="bleedout"){
			bloodloss+=max(0,damage);
			if(!(bloodloss&(1|2|4|8))){
				bodydamage++;
			}

			//if a custom blood capacity is specified, use that instead of health
			int blhlth=maxbloodloss;
			if(blhlth<1)blhlth=sphlth;

			if(hd_debug)console.printf(getclassname().." bleed "..damage..", est. remain "..blhlth-bloodloss);
			if(bloodloss<blhlth)return 1;
			return super.damagemobj(
				inflictor,source,random(damage,health),mod,DMG_NO_PAIN|DMG_THRUSTLESS,angle
			);
		}


		//make sure bodily integrity tracker is affected
		int sgh=sphlth+gibhealth;
		if(bodydamage<(sgh<<(HDMOB_GIBSHIFT+1)))bodydamage+=damage;


		//check for gibbing
		if(
			findstate("xdeath",true)
			&&bodydamage>(gibhealth+sphlth)
		){
			if(
				health<1
				&&bodydamage>(sgh<<HDMOB_GIBSHIFT)
			){
				bgibbed=true;
				bshootable=false;
				bcorpse=true;
				if(findstate("xxxdeath",true))setstatelabel("xxxdeath");
				else setstatelabel("xdeath");
				return -1;
			}else{
				return super.damagemobj(inflictor,source,health,"extreme",flags|DMG_FORCED,angle);
			}
		}


		//force death even if not quite gibbing
		if(
			health>0
			&&bodydamage>sphlth
		){

			//force use maxhpdrain when anti-revive deaths should be in play
			//prevents e.g. burning baron corpse spawning shards over and over again
			if(
				instatesequence(curstate,resolvestate("death"))
				||instatesequence(curstate,resolvestate("dead"))
				||instatesequence(curstate,resolvestate("xdeath"))
				||instatesequence(curstate,resolvestate("raise"))
				||instatesequence(curstate,resolvestate("ungib"))
			)mod="maxhpdrain";
			return super.damagemobj(inflictor,source,abs(health),mod,flags|DMG_FORCED,angle);
		}


		bnotargetswitch=true;


		if(hd_debug)console.printf(gettag().."   "..damage.." "..mod.."   remain "..health);
		damage=super.damagemobj(inflictor,source,damage,mod,flags,angle);


		//consider retargeting
		bnotargetswitch=false;
		if(
			!!self
			&&health>0
			&&!!source
			&&source!=target
			&&source.bshootable
			&&source.health>0
			&&(
				source.bismonster
				||!!source.player
			)
			&&OkayToSwitchTarget(source)
			&&(
				!target
				||distance3dsquared(source)<height*height
				||!random(0,painchance>>4)
				||!checksight(target)
			)
		){
			if(
				target
				&&!target.bcorpse
			)lastenemy=target;
			target=source;
			A_Vocalize(seesound);

			//if a new target is acquired, add a confused delay
			if(!bquicktoretaliate)reactiontime=default.reactiontime;
		}


		return damage;
	}


	enum MobDamage{
		HDMOB_GIBSHIFT=2,
	}


	//tracks what is to be done about all this damage
	int deathticks;
	void DamageTicker(){

		if(
			bcorpse
			||health<1
		){
			//fall down if dead
			if(
				!bnoshootablecorpse
				&&height>deadheight
			)A_SetSize(-1,max(deadheight-0.1,height-liveheight*0.06));

			if(deathticks<8){
				deathticks++;
				if(deathticks==8){
					A_NoBlocking();
					if(!bdontdrop){
						if(!bnodeathdrop)deathdrop();
						if(!bhasdropped)bhasdropped=true;
					}
					deathticks=9;
				}
			}
			return;
		}

		//set height according to incap
		if(instatesequence(curstate,resolvestate("falldown"))){
			if(deadheight<height)A_SetSize(-1,max(deadheight,height*0.99));
		}else if(liveheight!=height)A_SetSize(-1,min(liveheight,height+liveheight*0.05));


		//this must be done here and not AttemptRaise because reasons
		if(bgibbed){
			bgibbed=false;
			if(findstate("ungib",true))setstatelabel("ungib");
		}

		if(stunned){
			stunned-=max(1,(spawnhealth()>>7));
			speed=frandom(0,default.speed);
			if(stunned<0)stunned=0;
		}else{
			speed=default.speed;
		}

		//regeneration
		if(!(level.time&(1|2|4|8|16|32|64|128|256|512)))GiveBody(1);
	}


	virtual void deathdrop(){}
	override void die(actor source,actor inflictor,int dmgflags){
		deathticks=0;
		timesdied++;


		bool incapacitated=(
			findstate("falldown",true)
			&&frame>=downedframe //"M" for serpentipede, "L" for humanoids
		);


		super.Die(source,inflictor,dmgflags);
		HDF.CheckNoKillCount();
		if(!self)return;

		//check gibbing
		bgibbed=(
			findstate("xdeath",true)
			&&(
				!inflictor
				||!inflictor.bnoextremedeath
			)&&(
				health < getgibhealth()
				||(inflictor&&inflictor.bextremedeath)
			)
		);

		//temp incap: reset +nopain, skip death sequence
		if(
			incapacitated
			&&!bgibbed
			&&findstate("dead",true)
		){
			if(!random(0,7))A_Vocalize(deathsound);
			setstatelabel("dead");
		}

		//set corpse stuff
		bnodropoff=false;
		bnoblockmonst=true;
		bnotautoaimed=true;
		balwaystelefrag=true;
		bpushable=false;
		maxstepheight=deadheight*0.1;
		A_TakeInventory("HDMagicShield");

		if(!bgibbed)bshootable=!bnoshootablecorpse;
		else bshootable=false;

		//set height
		if(
			!incapacitated
			&&!bnoshootablecorpse
			&&bshootable
		)A_SetSize(-1,liveheight);
	}


	//should be placed at the start of every raise state
	/*
		states: raise, ungib, xxxdeath, dead, xdead
		no special functions should be assigned to them to handle death/raise,
		absent some very special behaviour like zombification.
		raise and ungib should both terminate with goto checkraise.
	*/
	void AttemptRaise(){
		//reset corpse stuff
		let deff=default;
		bnodropoff=deff.bnodropoff;
		bnoblockmonst=deff.bnoblockmonst;
		bfloatbob=deff.bfloatbob;
		maxstepheight=deff.maxstepheight;
		bnotautoaimed=deff.bnotautoaimed;
		balwaystelefrag=deff.balwaystelefrag;
		bnogravity=deff.bnogravity;
		bpushable=deff.bpushable;
		gravity=deff.gravity;

		if(!bnoshootablecorpse)bshootable=true;
		deathsound=default.deathsound;

		bodydamage=clamp(bodydamage-200,0,((spawnhealth()+gibhealth)<<(HDMOB_GIBSHIFT+2)));
		if(hd_debug)console.printf(getclassname().." revived with remaining damage: "..bodydamage);

		if(bodydamage>spawnhealth()){
			let dmgchk=HDRaiseBodyDamageCheck(new("HDRaiseBodyDamageCheck"));
			dmgchk.owner=self;
		}

		minmissilechance=(default.minmissilechance*random(4,12))>>3;

		resetdamagecounters();

		A_ClearTarget();

		reactiontime+=16;
		stunned+=TICRATE*5;

		let aff=new("AngelFire");
		aff.master=self;aff.ticker=0;
	}


	//temporary stun
	void A_KnockedDown(){
		vel.xy+=(frandom(-0.1,0.1),frandom(-0.1,0.1));
		if(!random(0,3))vel.z+=frandom(0.4,1.);
		if(
			stunned>0
			||random(0,(bodydamage>>4))
		)return;

		double heightbak=height;
		A_SetSize(radius,liveheight);
		bool checkstand=checkmove(pos.xy,PCM_NOLINES);
		A_SetSize(radius,heightbak);
		if(
			!checkstand
			&&blockingmobj
			&&blockingmobj.pos.z>=pos.z
		){
			double mmm=mass*3./blockingmobj.mass;
			vector2 vvv=(blockingmobj.pos.xy-pos.xy);
			if(vvv==(0,0))vvv=rotatevector((3,0),frandom(0,360));
			blockingmobj.vel+=(vvv.unit()*mmm,1);
			A_Vocalize(random(0,2)?seesound:painsound);
			return;
		}

		//reset stuff and get up
		bnopain=default.bnopain;
		if(findstate("standup"))setstatelabel("standup");
		else if(findstate("raise"))setstatelabel("raise");
		else setstatelabel("see");
	}


	states{
	checkraise:
		---- A 0{if(hd_debug)console.printf("The checkraise state is deprecated. No need to do anything here.");}
		---- A 0 A_Jump(256,"see");
		stop;
	}

}


extend class HDHandlers{
	override void WorldThingRevived(WorldEvent e){
		let mbb=hdmobbase(e.thing);
		if(mbb)mbb.AttemptRaise();
	}
}

//checks to see if bodydamage is excessive and deals nominal health damage accordingly to trigger re-gibs
class HDRaiseBodyDamageCheck:Thinker{
	hdmobbase owner;
	override void Tick(){
		if(!owner||owner.bcorpse){
			destroy();
			return;
		}
		if(
			!(owner.getage()&31)
			&&owner.bodydamage>owner.spawnhealth()
			&&(
				!owner.instatesequence(owner.curstate,owner.resolvestate("death"))
				&&!owner.instatesequence(owner.curstate,owner.resolvestate("dead"))
				&&!owner.instatesequence(owner.curstate,owner.resolvestate("raise"))
				&&!owner.instatesequence(owner.curstate,owner.resolvestate("ungib"))
			)
		)owner.damagemobj(owner,owner,1,"maxhpdrain",DMG_FORCED|DMG_NO_FACTOR|DMG_NO_PAIN);
	}
}


class HDMobFallSquishThinker:Thinker{
	static void Init(
		actor caller,
		double fallheight,
		vector2 startscale
	){
		HDMobFallSquishThinker sss;
		thinkeriterator ssi=ThinkerIterator.create("HDMobFallSquishThinker");
		while(sss=HDMobFallSquishThinker(ssi.next(true))){
			if(
				sss.target==caller
			){
				return;
			}
		}

		sss=new("HDMobFallSquishThinker");

		sss.target=caller;
		sss.mult=min(abs(fallheight),20)*(caller.bcorpse?0.002:0.004);
		sss.scale=caller.scale;
		sss.zvel=fallheight;
	}
	double zvel;
	actor target;
	vector2 scale;
	double mult;
	int ticker;
	override void Tick(){
		if(!target){destroy();return;}
		switch(ticker){
		case 1:target.scale.x=scale.x*(1+mult*2);target.scale.y=scale.y*(1-mult*2);break;
		case 2:target.scale.x=scale.x*(1+mult*4);target.scale.y=scale.y*(1-mult*4);
			sound landsound;
			double vol=min(1.,target.mass*0.01);
			if(hdmobbase(target))landsound=hdmobbase(target).landsound;
				else landsound="misc/mobland";
			target.A_StartSound(landsound,CHAN_BODY,CHANF_OVERLAP,volume:vol);
			if(zvel<-10)target.A_StartSound("misc/punch",CHAN_BODY,CHANF_OVERLAP,volume:vol);
			if(!target.cursector.planemoving(sector.floor))
				target.vel.z-=zvel*(target.bcorpse?0.3:0.1);
			break;
		case 3:target.scale.x=scale.x*(1+mult*5);target.scale.y=scale.y*(1-mult*5);break;
		case 4:target.scale.x=scale.x*(1+mult*4);target.scale.y=scale.y*(1-mult*4);break;
		case 5:target.scale.x=scale.x*(1+mult*3);target.scale.y=scale.y*(1-mult*3);break;
		case 6:target.scale.x=scale.x*(1+mult*2);target.scale.y=scale.y*(1-mult*2);break;
		case 7:target.scale.x=scale.x*(1+mult*2);target.scale.y=scale.y*(1-mult*1);break;
		case 8:target.scale=scale;
		case 9:destroy();return;
		default:break;
		}
		ticker++;
	}
}



// common blood type that changes depending on shields.
// overwrite spawn state if something other than a splat is needed.
class HDMasterBlood:BloodSplatSilent{
	override void postbeginplay(){
		super.postbeginplay();
		if(
			!bmissilemore
			&&target
			&&target.countinv("HDMagicShield")>0
		){
			A_SetTranslucent(1,1);
			grav=-0.6;
			setstatelabel("spawnshield");
			bnointeraction=true;
			return;
		}
		if(!bambush)A_StartSound("misc/bulletflesh",CHAN_BODY,volume:0.2);
	}
	states{
	spawnshield:
		TFOG A 0 A_SetScale(frandom(0.2,0.5));
		TFOG ABCDEFGHIJ 3 bright A_FadeOut(0.05);
		stop;
	}
}



//not just an old web 1.0 host anymore
//a marker to identify and eventually remove raised friendlies
class AngelFire:Thinker{
	actor master;
	int ticker;
	override void Tick(){
		ticker++;
		if(!ticker||(ticker&(1|2|4)))return;
		if(
			!master
			||!master.bfriendly
			||master.health<1
		){
			destroy();
			return;
		}
		if(ticker>(35*60*15)){
			master.A_Die();
			destroy();
			return;
		}
		master.givebody(1);
		double mrad=master.radius*0.3;

		if(level.time&1)master.A_SpawnParticle(
			"green",SPF_FULLBRIGHT,50,
			frandom(4,8),0,
			frandom(-mrad,mrad),frandom(-mrad,mrad), frandom(0.1,0.9)*master.height,
			frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(0.05,0.2),
			frandom(-0.05,0.05),frandom(-0.05,0.05),0.06,
			startalphaf:0.8,
			sizestep:0.1
		);
	}
}
