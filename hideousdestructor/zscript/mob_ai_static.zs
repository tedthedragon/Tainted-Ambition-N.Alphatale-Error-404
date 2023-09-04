// ------------------------------------------------------------
// Static AI-related functions
// ------------------------------------------------------------
struct HDMobAI play{

	//set a feartarget for nearby mobs
	//hdmobai.frighten(self,256);
	enum FrigtenerFlags{
		FRIGHT_HOSTILEONLY=1,
		FRIGHT_DONTSETTARGET=2,
	}
	static void Frighten(
		actor caller,
		double fraidius,
		actor fearsome=null,
		int flags=0
	){
		if(!fearsome)fearsome=caller;
		blockthingsiterator it=blockthingsiterator.create(caller,fraidius);
		while(it.Next()){
			let aaa=hdmobbase(it.thing);
			if(
				!aaa
				||aaa.bnofear
				||(
					flags&FRIGHT_HOSTILEONLY
					&&!fearsome.ishostile(aaa)
				)
			)continue;

			aaa.threat=caller;

			//set frightenter's "owner" as frightenee's target
			if(
				!(flags&FRIGHT_DONTSETTARGET)
				&&!aaa.target
			){
				actor tgt=fearsome;
				actor ttt=fearsome.target;

				//if fearsome is not a valid target, try its target instead
				if(
					!tgt.bismonster
					&&!tgt.player
					&&!!ttt
					&&(
						ttt.bismonster
						||!!ttt.player
					)
				)tgt=ttt;

				//if it's not improper to attack this actor, set the target
				if(
					aaa.ishostile(tgt)  //actually hostile
					||(
						!aaa.isfriend(tgt)  //don't let friends ever infight
						&&random(0,255)<(aaa.painchance>>3)
					)
				)aaa.target=tgt;
			}

		}
	}


	//eyeball out how much one's projectile will drop and raise pitch accordingly
	static void DropAdjust(
		actor caller,
		class<actor> missiletype,
		double dist=0,
		double speedmult=1.,
		double gravity=0,
		actor target=null
	){
		if(!target)target=caller.target;
		if(!target)return;
		if(dist<1)dist=max(1,(target?caller.distance2d(target):1));
		let gdtmistype=getdefaultbytype(missiletype);
		if(!gravity)gravity=gdtmistype.gravity;
		double spd=gdtmistype.speed*speedmult;
		if(gdtmistype.gravity&&dist>spd){
			int ticstotake=int(dist/spd);
			int dropamt=0;
			for(int i=1;i<=ticstotake;i++){
				dropamt+=i;
			}
			caller.pitch-=min(atan(dropamt*gravity/dist),60);
		}

		//because we don't shoot from height 32 but 42
		if(dist>0)caller.pitch+=atan(10/dist);
	}


	//check if shot is clear
	//hdmobai.tryshoot(self,pradius:6,pheight:6)
	static bool TryShootAcceptableVictim(
		actor caller,
		actor victim,
		actor target
	){
		if(
			!target  //nothing worth shooting in the first place
			||!victim  //this test is only done when the linetrace hits, so it's hitting geo
		)return false;

		bool acceptable=(
			!victim.bshootable
			||victim==target
			||victim.target==caller
			||victim.target==caller.master
			||victim.master==target
		);
		if(!acceptable)return false;

		//even if it passes the above checks, it might block the view
		if(
			(
				//target is wholly or partially invisible
				!target.bspawnsoundsource
				&&(
					target.bshadow
					||target.bspecialfiredamage
				)
				&&!random(0,target.bspecialfiredamage?15:7)
			)
			||(
				//victim is visible and in the way
				target!=victim
				&&(
					!victim.binvisible
					&&victim.alpha>0.6
					&&victim.sprite!=actor.getspriteindex("TNT1")
				)
				&&!random(0,7)
			)
		)return false;

		return true;
	}
	enum TryShootFlags{
		TS_GEOMETRYOK=1,
	}
	static bool TryShoot(
		actor caller,
		double shootheight=-1,
		double range=1024,
		double pradius=0,
		double pheight=0,
		actor target=null,
		double angle=-999,
		double pitch=-999,
		int flags=0
	){
		if(!target)target=caller.target;
		if(!target)return false;
		let hdm=hdmobbase(caller);
		if(shootheight<0){
			if(hdm)shootheight=hdm.gunheight;
			else shootheight=caller.missileheight;
		}
		if(angle==-999)angle=caller.angle;
		if(pitch==-999)pitch=caller.pitch;

		if(!range)range=caller.distance3d(target)-target.radius;
		else if(range>0)range=min(range,caller.distance3d(target)-target.radius);
		else if(range<0)range=abs(range);

		flinetracedata flt;

		//bottom centre - always done
		caller.linetrace(
			angle,range,pitch,flags:0,
			offsetz:shootheight,
			offsetside:0,
			data:flt
		);
		if(
			flt.hittype!=Trace_HitNone
			&&(flt.hittype==Trace_HitActor&&(flags&TS_GEOMETRYOK))
			&&!TryShootAcceptableVictim(caller,flt.hitactor,target)
		)return false;


		//get zoffset for top shot
		shootheight+=pheight;

		//top centre
		if(pheight){
			caller.linetrace(
				angle,range,pitch,flags:0,
				offsetz:shootheight,
				offsetside:0,
				data:flt
			);
			if(
				flt.hittype!=Trace_HitNone
				&&!TryShootAcceptableVictim(caller,flt.hitactor,target)
			)return false;
		}


		//get zoffset for side shots
		if(!pradius)return true;

		shootheight-=pheight*0.5;

		//left and right
		caller.linetrace(
			angle,range,pitch,flags:0,
			offsetz:shootheight,
			offsetside:-pradius,
			data:flt
		);
		if(
			flt.hittype!=Trace_HitNone
			&&!TryShootAcceptableVictim(caller,flt.hitactor,target)
		)return false;
		caller.linetrace(
			angle,range,pitch,flags:0,
			offsetz:shootheight,
			offsetside:pradius,
			data:flt
		);
		if(
			flt.hittype!=Trace_HitNone
			&&!TryShootAcceptableVictim(caller,flt.hitactor,target)
		)return false;

		//if none of the checks fail
		return true;
	}


	//similar to A_ShoutAlert for general use
	static void HDNoiseAlert(
		actor target,
		actor emitter=null,
		double range=512,
		int percentchancefail=0
	){
		if(!target||target.health<1)return;
		if(!emitter)emitter=target;

		//grabs nearby monsters and alerts them
		blockthingsiterator itt=blockthingsiterator.create(emitter,range);
		actor aat;
		while(itt.next()){
			actor aat=itt.thing;
			if(
				aat
				&&aat.bismonster
				&&aat.health>0
				&&aat.findstate("see")
				&&HDMobBase.inpainablesequence(aat)
				&&aat.target!=target

				&&!aat.isfriend(target)

				&&(
					!aat.target
					||(
						!aat.target.checksight(aat)
						&&!random(0,3)
					)
				)

				&&(
					!percentchancefail
					||random(0,99)<percentchancefail
				)
			){
				aat.target=target;
				if(!aat.bambush)aat.setstatelabel("see");
				let hdmb=HDMobBase(aat);
				if(hdmb){
					hdmb.lasttargetpos=target.pos;
					hdmb.A_Vocalize(hdmb.seesound,attenuation:hdmb.bboss?ATTN_NONE:ATTN_NORM);
					hdmb.OnAlert(!aat.bambush);
				}else{
					aat.a_startsound(aat.seesound,CHAN_VOICE);
				}
				if(hd_debug)console.printf("  * "..aat.gettag().." was alerted to "..target.gettag());
			}
		}
	}


	//wander around to unstick
	//left undeprecated in case anyone wants to use it for a non-HDMobBase
	static void UnstickWander(actor caller){
		if(caller.floorz>caller.pos.z)caller.setz(caller.floorz);
		bool bfl=caller.bfloat;
		caller.bfloat=true;
		caller.A_Wander();
		caller.bfloat=bfl;
	}


	//acquire a target
	static void AcquireTarget(
		actor caller,
		actor target
	){
		if(
			caller.target
			&&caller.checksight(caller.target)
		)return;

		if(caller.target)caller.lastenemy=caller.target;
		caller.target=target;

		if(
			!caller.instatesequence(caller.curstate,caller.resolvestate("see"))
			||!caller.instatesequence(caller.curstate,caller.resolvestate("missile"))
			||!caller.instatesequence(caller.curstate,caller.resolvestate("melee"))
			||!caller.instatesequence(caller.curstate,caller.resolvestate("pain"))
		)return;
		caller.setstatelabel("see");
	}




///////////////////////////all items below this line are considered deprecated as of 4.6.0a







	//randomize size
	static void resize(actor caller,double minscl=0.9,double maxscl=1.,int minhealth=0){
		let hdmbb=hdmobbase(caller);
		if(hdmbb){
			if(hd_debug)console.printf(hdmbb.getclassname().." is still using hdmobai.resize, please use hdmobbase own resize function directly.");
			hdmbb.resize(minscl,maxscl,minhealth);
			return;
		}
		double drad=caller.radius;double dheight=caller.height;
		double minchkscl=max(1.,minscl+0.1);
		double scl;
		do{
			scl=frandom(minscl,maxscl);
			caller.A_SetSize(drad*scl,dheight*scl);
			maxscl=scl; //if this has to check again, don't go so high next time
		}
		while(
			//keep it smaller than the geometry
			scl>minchkscl&&  
			!caller.checkmove(caller.pos.xy,PCM_NOACTORS)
		);
		caller.health=int(max(scl,1)*caller.health);
		caller.scale*=scl;
		caller.mass=int(scl*caller.mass);
		caller.speed*=scl;
		caller.meleerange*=scl;
	}


	//smooth wander
	//basically smooth chase with less crap to deal with
	static void Wander(
		actor caller,
		bool dontlook=false
	){
		let hmb=HDMobBase(caller);

		if(!caller.checkmove(caller.pos.xy)){
			UnstickWander(caller);
			return;
		}

		//remember original position, etc.
		vector3 pg=caller.pos;

		double speedbak=caller.speed;
		bool benoteleport=caller.bnoteleport;
		caller.bnoteleport=true;
		if(!caller.target||caller.target.health<1)caller.speed*=0.5;

		//wander and record the resulting position
		caller.A_Wander();
		vector3 pp=caller.pos;

		//abort if can't propel caller
		if(
			!caller.bfloat
			&&caller.floorz<caller.pos.z
		){
			caller.bnoteleport=benoteleport;
			caller.speed=caller.default.speed;
			return;
		}
		caller.vel.xy*=0.7; //slow down

		//reset position and move in chase direction
		if(pp!=pg){
			if(!caller.bteleport)caller.setorigin(pg,false);
			if(caller.bfloat){
				caller.vel.xy+=caller.angletovector(caller.angle,caller.speed*0.16);
			}else{
				caller.vel.xy+=caller.angletovector(caller.angle,caller.speed*0.16);
			}
		}

		//look
		if(!dontlook){
			if(hmb)hmb.A_HDLook();
			else caller.A_Look();
		}

		//reset things
		caller.bnoteleport=benoteleport;
		caller.speed=caller.default.speed;
	}
	//smooth chase
	//do NOT try to set targets in here, JUST do the chase sequence
	enum hdchaseflags{
		CHF_TURNLEFT=8,
		CHF_INITIALIZED=16,
		CHF_FLOATDOWN=32,
	}
	static void chase(actor caller,
		statelabel meleestate="melee",
		statelabel missilestate="missile",
		int flags=0,
		bool flee=false
	){
		let hmb=HDMobBase(caller);

		if(!caller.checkmove(caller.pos.xy)){
			UnstickWander(caller);
			return;
		}else{
			double oldang=caller.angle;
			bool befrightened=caller.bfrightened;
			bool bechasegoal=caller.bchasegoal;
			bool benoteleport=caller.bnoteleport;
			int bminmissilechance=caller.minmissilechance;
			vector3 oldpos=caller.pos;

			caller.minmissilechance<<=2;
			caller.bnoteleport=true;
			if(flee){
				caller.bfrightened=true;
				caller.bchasegoal=false;
			}

			if(hmb&&hmb.bchasealert){
				if(!random(0,127))hmb.A_Vocalize(hmb.seesound);
				else hmb.A_ShoutAlert(0.01);
			}

			caller.A_Chase(meleestate,missilestate,flags&(hmb?CHF_NOPLAYACTIVE:0));

			vector3 posdif=caller.pos-oldpos;
			caller.setorigin(oldpos,false);

			//decelerate
			if(caller.bfloat&&caller.bnogravity)caller.vel*=0.7;
			else caller.vel.xy*=0.7;


			//translate the resulting movement into velocity
			if(posdif!=(0,0,0))caller.vel+=
				posdif.unit()
				*caller.speed
				*(hmb&&hmb.threat?0.24:0.16);

			//reset temporary flags and properties
			caller.bfrightened=befrightened;
			caller.bchasegoal=bechasegoal;
			caller.bnoteleport=benoteleport;
			caller.minmissilechance=bminmissilechance;
		}
	}
}


//actor that sets monster's goal
//deprecated - only kept in case any mod uses it, 
class HDMobster:IdleDummy{
	vector3 firstposition;
	actor subject;
	actor threat;
	double thraidius;
	int leftright;
	int boredthreshold;int bored;
	actor healablecorpse;
	default{
		meleethreshold 0;
	}
	static hdmobster SpawnMobster(actor caller){
		let hdmb=hdmobster(spawn("HDMobster",caller.pos,ALLOW_REPLACE));
		console.printf("\ca"..caller.gettag().." is still using HDMobster. Please convert to the internal HDMobBase AI.");
		hdmb.subject=caller;
		hdmb.target=caller.target;
		hdmb.bfrightened=caller.bfrightened;
		hdmb.meleerange=caller.meleerange;
		hdmb.firstposition=caller.pos;
		hdmb.leftright=randompick(-1,-1,-1,-1,0,1,1);
		hdmb.threat=null;
		hdmb.thraidius=256;
		hdmb.bored=0;
		hdmb.boredthreshold=20;
		hdmb.healablecorpse=null;
		let mob=HDMobBase(caller);
		return hdmb;
	}
	states{
	spawn:
		TNT1 A random(17,30){
			if(
				!subject
				//abort if something else is setting the goal, e.g. a level script
				||(subject.goal&&subject.goal!=self)
			){
				destroy();return;
			}
			A_SetFriendly(subject.bfriendly);
			if(
				bfriendly
				||subject.instatesequence(subject.curstate,subject.resolvestate("falldown"))
				||subject.instatesequence(subject.curstate,subject.resolvestate("pain"))
			)return;
			if(subject.health<1){
				threat=null;
				return;
			}

			//see if this is a healer
			if(!random(0,14))healablecorpse=null;
			if(
				subject.findstate("heal")
				&&!threat
			){
				blockthingsiterator it=blockthingsiterator.create(subject,256);
				while(it.next()){
					actor itt=it.thing;
					if(
						itt.bcorpse
						&&itt.canresurrect(self,true)
						&&canresurrect(itt,false)
						&&!random(0,4)
						&&abs(itt.pos.z-subject.pos.z)<subject.maxstepheight*2
						&&heat.getamount(itt)<50
						&&itt.checksight(subject)
					){
						healablecorpse=itt;
						if(
							itt.distance3d(subject)<
							(itt.radius+subject.radius+12)*HDCONST_SQRTTWO
						){
							itt.target=subject.target;
							subject.A_Face(itt);
							subject.setstatelabel("heal");

							RaiseActor(itt,RF_NOCHECKPOSITION);
							itt.A_SetFriendly(subject.bfriendly);
							itt.master=subject;
						}
						break;
					}
				}
			}

			//decide where to place goal
			target=subject.target;
			if(threat){
				bored=0;
				subject.bfrightened=true;
				subject.goal=self;subject.bchasegoal=true;
				setorigin(subject.pos+(subject.pos-threat.pos)
					+(random(-128,128),random(-128,128),0),false);
				A_SetTics(tics*4);
				if(
					!subject.checksight(threat)
					||subject.distance3d(threat)>thraidius  
				)threat=null;
			}else if(healablecorpse){
				subject.bfrightened=bfrightened;
				subject.goal=self;subject.bchasegoal=true;
				setorigin(healablecorpse.pos,true);
			}else if(target){
				subject.bfrightened=bfrightened;
				subject.goal=self;subject.bchasegoal=true;
				//chase target directly, or occasionaly randomize general direction
				if(
					target.health>0  
					&&subject.checksight(target)
				){
					vector2 mpo=subject.pos.xy;
					double mth=meleethreshold;
					vector2 tpo=subject.target.pos.xy;
					if(
						(!mth||mth<distance3d(target))
						&&!random(0,7)
					){
						vector2 flank=rotatevector(mpo-tpo,
							random(30,80)*(leftright
								*randompick(1,1,1,1,-1,-1,0))
						);
						tpo+=flank;
					}
					setorigin((tpo,subject.target.pos.z+subject.target.height),false);
					bored=0;
				}else if(!random(0,15)){
					setorigin((
						subject.pos.xy
						+rotatevector(pos.xy-subject.pos.xy
							+(random(-512,512),random(-512,512)),
							random(60,120)*
							(leftright+randompick(1,1,1,1,-1,-1,0))
						)
					,subject.pos.z),false);
					bored++;
				}
				if(bored>boredthreshold||(subject.bfriendly&&!random(0,99))){
					bored=0;
					subject.goal=null;subject.bchasegoal=false;
					A_ClearTarget();subject.A_ClearTarget();
					if(subject.findstate("idle"))subject.setstatelabel("idle");
					else subject.setstatelabel("spawn");
				}
			}else{
				subject.goal=null;subject.bchasegoal=false;
				subject.A_ClearTarget();
				setorigin(firstposition,false); //go back to start
			}
		}wait;
	}
}

