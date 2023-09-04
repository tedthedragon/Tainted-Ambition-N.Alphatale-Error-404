// ------------------------------------------------------------
// HD's custom mob AI.
// ------------------------------------------------------------

/*
  Special flag usages:
   +SPAWNSOUNDSOURCE: can be located without visual contact.
   +SPECIALFIREDAMAGE: is totally invisible.

   +NOBOUNCESOUND: not alerted by sound - will not even acquire a target.
*/

const HDCONST_MOBSOUNDRANGE=256.;
const ATTN_DIRBOSS=0.0001;

enum HDChaseFlags{
	//some flags can be replaced since they would never be used in HD.
	CHF_FLEE=CHF_FASTCHASE, //lol
	CHF_DONTCHANGEMOVEPOS=CHF_NIGHTMAREFAST, //they're all subject to nightmare speed
	CHF_WANDER=CHF_RESURRECT, //HD checks for presence of "heal" state
	CHF_LOOK=CHF_NOPOSTATTACKTURN, //HD never makes this assumption
}

extend class HDMobBase{
	bool MustUnstick(){
		if(CheckMove(pos.xy))return false;
		if(floorz>pos.z)setz(floorz);
		bool bfl=bfloat;
		bfloat=true;
		A_Wander();
		bfloat=bfl;
		return true;
	}
	void ResetTargetPos(){
		lasttargetdist=32000;
		lasttargetpos=(cos(angle)*32000,sin(angle)*32000,pos.z);
	}

	double seedist,heardist,seefov;
	property SeeDist: seedist;
	property HearDist: heardist;
	property FOV: seefov;
	int firefatigue;
	vector3 movepos;
	vector3 lasttargetpos;
	double lasttargetdist;
	double lasttargetradius;
	double lasttargetheight;
	vector3 lasttargetvel;
	bool targetinsight;
	double absangletotarg;
	actor threat;
	virtual void A_HDWander(int flags=0){A_HDChase(null,null,flags|CHF_WANDER,0.4);}
	virtual void A_HDChase(
		statelabel meleestate="melee",
		statelabel missilestate="missile",
		int flags=0,
		double speedmult=1.
	){
		if(HDAIOverride.HDChase(self,meleestate,missilestate,flags,speedmult))return;

		if(
			health<1
			||MustUnstick()
			||!inpainablesequence(self)
		)return;

		if(reactiontime>0)reactiontime--;


		//climbing a wall in pursuit of target
		if(
			bclimber
			&&CheckClimb()
		){
			CheckFootstepSound();
			return;
		}


		//check if walking is an option
		bool onground=bonmobj||floorz>=pos.z;
		bool floating=bfloat||waterlevel>1;
		if(
			!floating
			&&onground
			&&CheckMove(pos.xy,PCM_DROPOFF)
		)bnodropoff=true;

		//restore pitch to something not ridiculous
		if(abs(pitch)>20)pitch*=0.5;

		if(onground)CheckFootstepSound();

//if(hd_debug>2)console.printf(level.time.."   "..gettag().." is targeting   "..(target?target.gettag():"nothing"));


		//wander and look
		if(
			flags&CHF_LOOK
		){
			actor tgt=target;
			A_HDLook();
			if(
				target
				&&target!=tgt
			)flags|=CHF_WANDER;
		}


		//if wander, don't go into attack states
		if(flags&CHF_WANDER){
			meleestate=null;
			missilestate=null;
		}else if(
			//abort if no target and not wandering
			!target
			||(
				!ishostile(target)
				&&target.target!=self
				&&!!lastenemy
				&&ishostile(lastenemy)
			)||(
				target.default.bshootable
				&&(
					!target.bshootable
					||target.health<1
				)
				&&target!=goal
			)
			||isfriend(target)
		){
			if(bfriendly){
				A_ClearTarget();
				A_HDLook(LOF_NOJUMP);
			}else{
				if(lastenemy==target)lastenemy=null;
				target=null;
				if(
					!!lastenemy
					&&lastenemy.health>0
				){
					target=lastenemy;
					lastenemy=null;
					ResetTargetPos();
				}else{
					A_HDLook(LOF_NOJUMP);
					if(
						!target
						&&!goal
					){
						bjustattacked=true;
						reactiontime=default.reactiontime;
						SetIdle();
						return;
					}
				}
			}
		}


		vector2 pathcheck=pos.xy;


		//play active and alert noises
		if(!(flags&CHF_NOPLAYACTIVE)){
			if(
				stunned>40
				&&random(0,4095)<painchance+(stunned>>8)
			){
				HDMobFallSquishThinker.Init(self,frandom(0,2),scale);
				A_Vocalize(
					randompick(
						painsound,painsound,painsound,painsound,painsound,
						seesound,seesound,
						bonlyscreamondeath?seesound:deathsound
					),
					volume:frandom(0.9,1.),
					pitch:frandom(0.99,1.01)
				);
			}
			else if(!random(0,200))A_Vocalize(
				activesound,
				volume:frandom(0.7,1.),
				pitch:frandom(0.98,1.02)
			);
			else if(
				bchasealert
				&&target
			){
				if(!random(0,300))A_Vocalize(seesound);
				else A_ShoutAlert(0.004);
			}
		}


		//initialize target stuff
		if(!target){
			target=lastenemy;
			ResetTargetPos();
		}




		vector3 lastlasttargetpos=lasttargetpos;
		CheckTargetInSight();




		if(!targetinsight)bouncecount++;


		//strain to attack
		//basically turns stun into DoT
		if(
			stunned>1000
			&&(
				targetinsight
				||lasttargetdist<height*6.
			)
		){
			stunned-=(stunned>>3);
			bodydamage+=(stunned>>6);
		}


		if(
			!targetinsight
			&&!bnotargetswitch
		){
			//check for any other targets that are in sight
			if(
				lastheard==target
				||!random(0,7)
			){
				let tgt=target;
				target=null;
				A_HDLook(LOF_NOJUMP|LOF_NOSOUNDCHECK);
				if(
					!!target
					&&tgt!=target
				)return;
				target=tgt;  //restore original target if this look brings up nothing
			}


			//randomly lose track of target
			if(
				!!target
				&&(
					(bfriendly&&reactiontime<4)
					||bouncecount>1024-painchance+(health<<2)
				)
			){
				ResetTargetPos();
				let lll=lastenemy;
				if(!lll)lll=lastheard;
				if(
					!!lll
					&&lll.health>0
				){
					if(lastenemy==target)lastenemy=null;
					else lastenemy=target;
					target=lll;
				}else if(
					random(0,2)
				)target=null;
			}
		}


		//friendlies only search within a very short distance.
		//this gives them a fighting chance against enemies further away.
		if(
			!bfriendly
			&&target
		){
			let hdp=hdplayerpawn(target);
			if(
				hdp
				&&hdp.nearbyfriends.size()>0
			){
				for(int i=0;i<hdp.nearbyfriends.size();i++){
					let fff=hdp.nearbyfriends[i];
					if(
						fff
						&&!fff.target
						&&fff.health>0
					){
						fff.target=self;
						if(hd_debug)console.printf("* "..fff.gettag().." was alerted to "..gettag().." for attacking "..target.gettag());
						break;
					}
				}
			}else if(
				target.bfriendly
				&&!target.target
			)target.target=self;
		}


		//if melee, melee and skip movement
		double touchdist=target?(target.radius+radius*1.05)*HDCONST_SQRTTWO:0;
		if(
			(
				targetinsight
				||(
					!!target
					&&!(random(0,(stunned>>4)))
					&&distance3dsquared(target)<(touchdist*touchdist)
				)
			)
			&&target!=goal
			&&findstate(meleestate)
			&&lasttargetdist>0
			&&lasttargetdist<meleerange+lasttargetradius+radius
		){
			lasttargetpos=target.pos;
			vector3 tpp=target.pos-pos;
			if(tpp!=(0,0,0))vel+=tpp.unit()*speed*0.3;
			setstatelabel(meleestate);
			return;
		}


		//how do you access aggressiveness???
		bool fastmonsters=skill==4||sv_fastmonsters;
		if(fastmonsters&&tics>1)tics>>=1;


		if(
			!threat
			||bnofear
		){
			//consider doing a missile
			if(
				CanDoMissile(
					targetinsight,
					lasttargetdist,
					missilestate
				)
			){
				//totally new randomizer trying to keep with the spirit of the original
				double dsp=maxtargetrange?
					abs(lasttargetdist/maxtargetrange)
					:min(0.99,lasttargetdist/(HDCONST_ONEMETRE*30))
				;
				double mms=minmissilechance*speedmult*(1./128);
				if(bmissilemore)mms*=0.5;
				if(bmissileevenmore)mms*=0.25;
				if(
					targetinsight
					&&absangletotarg<5
					&&absangle(angleto(target),hdmath.angleto(pos.xy,lastlasttargetpos.xy))<15
				)mms*=0.2;

				double mchk=frandom(0.,fastmonsters?5.12:2.56);
				mms=1.+max(mms,dsp);
				if(mchk>mms){
					setstatelabel(missilestate);
					return;
				}
			}

			HealNearbyCorpse(radius*1.4);
		}


		//skip if actor can't even move
		//do this AFTER the attack checks
		if(
			(
				!bfloat
				&&!onground
			)||(
				vel dot vel > speed*5.
			)
		)return;


		//(re-)initialize default movepos
		if(
			!(flags&CHF_DONTCHANGEMOVEPOS)
			&&(
				movepos.xy==pos.xy
				||(
					abs(movepos.x-pos.x)<meleerange
					&&abs(movepos.y-pos.y)<meleerange
				)
			)
		){
			movepos=(pos.xy+AngleToVector(angle,1024),pos.z);
		}

		vector2 vecto=movepos.xy-pos.xy;
		vector2 vectp=vecto.unit()*radius;

		pathcheck+=vectp;
		bool ckmv=true;
		int ckrg=int(clamp(speed*speedmult*frandom(0.2,0.5),3,16));
		maxdropoffheight=maxstepheight;
		blockingline=null;
		for(int i=0;i<ckrg;i++){
			if(
				!CheckMove(pathcheck+vectp*i,PCM_DROPOFF)
				&&(
					bavoidmelee
					||!blockingmobj
					||blockingmobj!=target
				)
			){
				if(
					i<5
					&&!!blockingline
					&&bcanusewalls
				){
					ckmv=blockingline.activate(self,0,SPAC_Use);
				}else ckmv=false;

				break;
			}
		}
		maxdropoffheight=default.maxdropoffheight;


		//move the movepos as necessary
		if(
			//path blocked
			!ckmv
		){
			//chance of turning non-handed side
			double turnangle=DecideOnHandedness(-frandom(50,140));
			if(
				(!blefthanded&&turnangle>0)
				||(blefthanded&&turnangle<0)
			)turnangle*=3;
			vecto=rotatevector(vecto,turnangle);
		}else if(
			//threat in range
			!!threat
			&&checksight(threat)
			&&distance3dsquared(threat)<(HDCONST_SPEEDOFSOUND*HDCONST_SPEEDOFSOUND)
		){
			//if already facing away, keep going
			//because always beelining sometimes gets you stuck
			if(absangle(angle,angleto(threat))>120)vecto=angletovector(angle,1024);
			else vecto=threat.Vec2To(self);

			//add some ziggyzags
			vecto=rotatevector(vecto,frandom(-10,10));

			//hurry up!
			speedmult*=1.7;
		}else if(
			!(flags&CHF_DONTCHANGEMOVEPOS)
			&&(
				vel.xy==(0,0)
				||!random(0,7)  //don't do this too often
			)
		){

			//find a valid healtarget
			//can't do in the block below since you need to check if there is one or wander
			vector2 healvecto=(0,0);
			bool goheal=false;
			if(findstate("heal")){
				blockthingsiterator it=blockthingsiterator.create(self,HDCONST_SPEEDOFSOUND);
				while(it.next()){
					actor itt=it.thing;
					if(
						itt.bcorpse
						&&itt.canresurrect(self,true)
						&&canresurrect(itt,false)
						&&itt.findstate("raise")
						&&!random(0,4)
						&&abs(itt.pos.z-pos.z)<maxstepheight*2
						&&heat.getamount(itt)<50
						&&checksight(itt)
					){
						healvecto=Vec2To(itt);
						goheal=true;
						break;
					}
				}
			}


			if(
				target
				&&(
					absangletotarg>seefov
					||!random(0,3)
				)
			){
				//if only there were a vec2to that took a vector2
				let txyz=target.pos;
				target.setxyz(lasttargetpos);
				vecto=Vec2To(target);
				target.setxyz(txyz);

				//chance of flanking non-handed side
				double turnangle=DecideOnHandedness(-frandom(10,40));
				vecto=rotatevector(vecto,turnangle);

				//reverse the logic if we're trying to flee
				if(
					bfrightened
					||flags&CHF_FLEE
					||target.bfrightening
					||(
						meleethreshold<0
						&&lasttargetdist<abs(meleethreshold)
					)
				)vecto=rotatevector(vecto,180);
			}else if(
				//non-target goal exists
				bchasegoal
				&&goal
			){
				vecto=Vec2To(goal);
				//add some ziggyzags
				vecto=rotatevector(vecto,frandom(-10,10));
			}else if(
				goheal
			){
				vecto=healvecto;
			}else if(
				bfriendly
				&&friendplayer<=MAXPLAYERS
				&&(
					!multiplayer
					||(players[max(0,friendplayer-1)].mo)
				)
				&&!random(0,3)
			){
				vecto=Vec2To(players[multiplayer?max(0,friendplayer-1):0].mo);
				double rtv=decideonhandedness(frandom(1,5)*20,0.25);
				vecto=rotatevector(vecto,rtv);
			}else if(
				//wander aimlessly
				!(flags&CHF_NORANDOMTURN)
				&&!random(0,7)
			){
				//chance of turning handed side
				double turnangle=decideonhandedness(-frandom(10,160),0.4);
				vecto=rotatevector(vecto,turnangle);
			}
		}


		//just brute-force *some* valid value
		if(vecto==(0,0))vecto=angletovector(angle+decideonhandedness(frandom(-50,30)),1);


		//goal checks
		if(goal){
			vector3 gpp=goal.pos-pos;
			if(max(abs(gpp.x),abs(gpp.y),abs(gpp.z))<=meleerange+goal.radius){
				// https://github.com/ZDoom/gzdoom/blob/9082ef7d49f49c68859c1ce98d560ae300c13392/src/playsim/p_enemy.cpp#L2368

				actoriterator iterator=level.createactoriterator(goal.args[0],"PatrolPoint");
				actoriterator specit=level.createactoriterator(goal.tid,"PatrolSpecial");
				actor spec=null;
				while((spec=specit.Next())){
					spec.A_CallSpecial(
						spec.special,spec.args[0],
						spec.args[1],spec.args[2],
						spec.args[3],spec.args[4]
					);
				}

				double lastgoalang=goal.angle;
				int delay;

				Actor newgoal=iterator.Next();
				if(newgoal&&goal==target){
					delay=newgoal.args[1];
					reactiontime=delay*TICRATE+Level.maptime;
				}else{
					delay=0;
					reactiontime=default.reactiontime;
					angle=lastgoalang;		// Look in direction of last goal
				}
				if(target==goal)target=null;
				bjustattacked=true;
				if(newgoal&&delay){
					bincombat=true;
					SetIdle();
				}
				goal=newgoal;
				return;
			}else if(random(0,3))vecto=Vec2To(goal);
		}


		if(!(flags&CHF_DONTCHANGEMOVEPOS))movepos.xy=pos.xy+vecto;


		//actually start moving towards the movepos
		if(flags&CHF_DONTMOVE)return;
		if(floating){
			if(vel.x||vel.y||vel.z)vel-=vel.unit()*speed*0.1;

			if(!(flags&CHF_DONTCHANGEMOVEPOS)){
				if(
					!targetinsight
					&&!!target
					&&!random(0,7)
				){
					movepos.z=lasttargetpos.z;
				}else if(
					!random(0,2)
				)movepos.z=floorz;
				else if(
					!random(0,2)
				)movepos.z=ceilingz-height;
				else movepos.z=floorz+(ceilingz-floorz)*0.61803;
			}

			vel.z+=(movepos.z>pos.z?speed:-speed)*0.12;

			//a little extra oomph from the g round
			if(onground&&vel.z>0)vel.z+=speed*0.1;
		}else if(!(flags&CHF_DONTCHANGEMOVEPOS))movepos.z=pos.z;


		//don't go at full throttle without good reason
		if(!target&&!threat)speedmult=min(speedmult,0.4);


		//face mvt dir
		speedmult*=0.16; 
		if(!(flags&CHF_NODIRECTIONTURN)){
			if(
				!threat
				&&!!target
				&&lasttargetdist<height*(targetinsight||target.bSPAWNSOUNDSOURCE?5.:3.)
			){
				double destangle=HDMath.AngleTo(pos.xy,lasttargetpos.xy);
				destangle=deltaangle(angle,destangle);
				angle+=clamp(destangle,-20,20);
				speedmult*=0.8;
			}
			else A_FaceMovementDirection(0,20,20);
		}

		vel.xy+=vecto.unit()*speed*speedmult;
	}


	bool CheckTargetInSight(){
		if(!target){
			targetinsight=false;
			return false;
		}

		double att=angleto(target);
		absangletotarg=absangle(angle,att);
		int didntsee=max(0,stunned-(mass>>1));

		lasttargetdist=level.Vec3Diff(pos,lasttargetpos).length()-target.radius;


		//handle invisibility
		if(
			!bnoblurgaze
			&&!bseeinvisible
			&&!(
				target.bSPAWNSOUNDSOURCE
				&&lasttargetdist<HDCONST_MOBSOUNDRANGE
			)
		){
			//imitate blursphere invisibility
			if(
				target.bspecialfiredamage
			){
				didntsee+=int(600+absangletotarg+lasttargetdist*0.1);
			}else if(
				target.bshadow
				&&!target.instatesequence(target.curstate,target.resolvestate("pain"))
			){
				didntsee+=max(
					13,
					int(absangletotarg+lasttargetdist*0.1)-((255-target.cursector.lightlevel)>>5)
				);
			}
		}else if(!blookallaround)didntsee+=(int(absangletotarg)>>5);

		//check sight and distance
		targetinsight=
			!bdontchecksight
			&&!random(0,didntsee)
			&&(
				blookallaround
				||target.bspawnsoundsource
				||absangletotarg<
					(seefov?seefov:180)
					*frandom(
						0.2,  //"within X degrees" implies fov of 2X
						max(
							abs(lasttargetpos.x-target.pos.x),
							abs(lasttargetpos.y-target.pos.y)
						)<(10*HDCONST_ONEMETRE)
						?1.:0.6
					)
			)
			&&checksight(target)
		;
		if(targetinsight){
			lasttargetpos=target.pos;
			lasttargetradius=target.radius;
			lasttargetheight=target.height;
			lasttargetvel=target.pos-target.prev;
		}else{
			if(
				target.bSPAWNSOUNDSOURCE
				&&absangle(hdmath.angleto(pos.xy,lasttargetpos.xy),att)>30
			){
				lasttargetpos=(
					target.pos.x+frandom(-1,1)*(0.2*HDCONST_MOBSOUNDRANGE),
					target.pos.y+frandom(-1,1)*(0.2*HDCONST_MOBSOUNDRANGE),
					frandom(target.pos.z,target.ceilingz)
				);
			}
			else lasttargetpos.xy+=(frandom(-5,5),frandom(-5,5));
		}

		if(
			hd_debug>1
			&&!!target
		)HDF.Particle(target,"red",(lasttargetpos.xy,lasttargetpos.z+target.height*0.7),20,6,fullbright:true);

		if(targetinsight)bouncecount=0;

		return targetinsight;
	}


	//criteria for doing a missile
	virtual bool CanDoMissile(
		bool targetinsight,
		double lasttargetdist,
		out statelabel missilestate
	){
		return
		targetinsight
		&&target!=goal
		&&!reactiontime
		&&findstate(missilestate)
		&&(
			!maxtargetrange
			||lasttargetdist<maxtargetrange
		)
		&&firefatigue<HDCONST_MAXFIREFATIGUE
		&&hdmobai.tryshoot(
			self,
			angle:hdmath.angleto(pos.xy,lasttargetpos.xy),
			pitch:hdmath.pitchto(pos,lasttargetpos),
			flags:hdmobai.TS_GEOMETRYOK
		)
		&&(
			!meleethreshold
			||lasttargetdist>abs(meleethreshold)
			||!random(0,7)  //brainfart or fuckit
		);
	}


	//used for looking
	bool ValidTarget(
		actor other,
		bool sightcheck=true,
		double halflookfov=100,
		double mindist=0,
		double maxdist=0
	){
		if(
			!other
			||!other.bshootable
			||other.bdormant
			||(!other.bismonster&&!other.player)
			||other.health<=0
			||(isfriend(other))
			||(
				!ishostile(other)
				&&other.target!=self
			)
		)return false;

		double dist=distance3dsquared(other);
		double feelrange=(radius+other.radius)*HDCONST_SQRTTWO;
		return(
				!mindist
				||mindist<dist
			)&&(
				!maxdist
				||maxdist>dist
			)&&(
				!sightcheck
				||feelrange*feelrange>dist
				||(
					(
						bSEEINVISIBLE
						||!other.bSPECIALFIREDAMAGE
					)
					&&checksight(other)
					&&(
						bLOOKALLAROUND
						||halflookfov>=180
						||absangle(angle,angleto(other))<halflookfov
					)
				)
			)
		;
	}


	//use this look function to implement voice pitch and other stuff
	bool A_HDLook(
		int flags=0,
		double minseedist=0,double maxseedist=-1,double maxheardist=-1,double lookfov=-1,
		statelabel label="see"
	){
		let tgbk=target;

		if(
			HDAIOverride.HDLook(self,flags,minseedist,maxseedist,maxheardist,lookfov,label)
		)return target&&target!=tgbk;

		if(bINCONVERSATION)return false;

		//set goal
		if(special==Thing_SetGoal){
			actoriterator itt=level.CreateActorIterator(args[1],"PatrolPoint");
			special=0;
			goal=itt.Next();
			if(goal){
				movepos=goal.pos;
				reactiontime=args[2]*TICRATE+level.maptime;
				bCHASEGOAL=(!args[3]);
			}
		}


		if(bjustattacked){
			bjustattacked=false;
			if(!tics)tics=1;
			return false;
		}

		if(maxseedist<0)maxseedist=seedist;
		if(maxheardist<0)maxheardist=heardist;
		if(lookfov<0)lookfov=seefov;




		//a whole new system to look for targets
		if(
			!ValidTarget(target,!random(0,7))
		){
			array<actor>targetlist;targetlist.clear();


			//precalculate a few things
			double hlfv=lookfov?lookfov*0.5:100;
			double dmax=maxseedist*maxseedist;
			double dmin=minseedist*minseedist;
			double hmax=maxheardist*maxheardist;


			//acquire sound target
			if(
				!bNOBOUNCESOUND
				&&!(flags&LOF_NOSOUNDCHECK)
			){
				actor stt=lastheard?lastheard:cursector.soundtarget;
				if(ValidTarget(stt,false,0,hmax)){
					targetlist.push(stt);
					if(!lastheard)lastheard=stt;
				}
			}


			//add last enemy to candidate list
			if(ValidTarget(lastenemy,false))targetlist.push(lastenemy);


			if(
				!(flags&LOF_NOSIGHTCHECK)
				&&!bdontchecksight  //this one's for Thing_Hate
			){

				//look for monsters
				if(
					bfriendly
					||deathmatch
				){
					blockthingsiterator itt=blockthingsiterator.create(self,1280);
					while(itt.next()){
						actor aaa=itt.thing;
						if(ValidTarget(aaa,true,hlfv,dmin,dmax)){
							targetlist.push(aaa);

							//let hostiles return the favour
							if(
								bfriendly
								&&!aaa.target
								&&(
									aaa.blookallaround
									||deltaangle(aaa.angle,aaa.angleto(self))<100
								)
							){
								let hdm=hdmobbase(aaa);
								if(hdm){
									hdm.lasttargetdist=hdm.maxtargetrange;
									hdm.lasttargetpos=pos;
								}
								aaa.target=self;
								aaa.A_StartSound(
									aaa.seesound,CHAN_VOICE,
									attenuation:aaa.bboss?ATTN_DIRBOSS:ATTN_NORM,
									pitch:hdm?hdm.voicepitch:1.
								);
							}
						}
					}
				}


				//look for players
				if(
					!bnohateplayers
					&&(
						!bfriendly
						||deathmatch
					)
				){
					for(int i=0;i<MAXPLAYERS;i++){
						if(
							!playeringame[i]
							||players[i].cheats&CF_NOTARGET
						)continue;

						actor aaa=players[i].mo;

						//botbot
						if(HDBotSpectator(aaa)){
							BotBot bbb=null;
							thinkeriterator nmit=thinkeriterator.create("BotBot",STAT_DEFAULT);
							while(bbb=BotBot(nmit.Next())){
								if(bbb.masterplayer==i){
									aaa=bbb;
									break;
								}
							}
						}

						if(ValidTarget(aaa,true,hlfv,dmin,dmax))targetlist.push(aaa);
					}
				}
			}


			//pick one viable candidate at random
			if(targetlist.size()>0){
				actor newtarget=targetlist[random(0,targetlist.size()-1)];

				if(lastenemy==newtarget)lastenemy=null;
				else if(ValidTarget(newtarget,false))lastenemy=newtarget;

				if(newtarget==lastheard)lastheard=null;

				lasttargetpos=newtarget.pos;
				if(
					!checksight(newtarget)
				)lasttargetpos.xy+=(frandom(-1,1),frandom(-1,1))*HDCONST_MOBSOUNDRANGE;

				target=newtarget;
			}
		}


		//if a TID has been set by Thing_Hate
		if(
			!target
			&&tidtohate
		){
			//i'm sorry i ran out of variable name ideas
			actoriterator itt=level.createactoriterator(tidtohate);
			array<actor> targetlist;targetlist.clear();
			actor aaa=null;
			while(aaa=itt.Next()){
				if(
					aaa.bshootable
					&&aaa.health>00
					&&aaa!=self
					&&(
						bnosightcheck
						||checksight(aaa)
					)
				){
					targetlist.push(aaa);
					break;
				}
			}
			if(targetlist.size()>0)target=targetlist[random(0,targetlist.size()-1)];
		}


		if(!target){

			//switch to see state if no target but goal
			if(goal){
				bool dostate=(
					!instatesequence(curstate,resolvestate(label))
					&&!(flags&LOF_NOJUMP)
				);
				if(dostate)setstatelabel(label);
				return true;
			}

			return false;
		}



		//whether a state jump should be made
		let tgbkk=target;
		bool dostate=(
			!instatesequence(curstate,resolvestate(label))
			&&!(flags&LOF_NOJUMP)
			&&(
				!bambush
				||checksight(target)
			)
		);
		target=tgbkk;

		//do only if the target was changed
		if(target!=tgbk){
			reactiontime=default.reactiontime;

			//don't spawncamp the player
			if(level.time<TICRATE*3){
				reactiontime+=50;
				let fff=spawn("idledummy",pos+(rotatevector(target.pos.xy-pos.xy,randompick(-45,45))*0.05));
				threat=fff;
				fff.stamina=TICRATE;
			}

			lasttargetpos=target.pos+(
				frandom(-1,1)*(0.3*HDCONST_MOBSOUNDRANGE),
				frandom(-1,1)*(0.3*HDCONST_MOBSOUNDRANGE),
				target.bfloat?
					frandom(-1,1)*(0.3*HDCONST_MOBSOUNDRANGE):
					0
			);

			if(dostate&&!(flags&LOF_NOSEESOUND))A_Vocalize(seesound
				,attenuation:bboss?ATTN_DIRBOSS:ATTN_NORM
			);
			if(!HDAIOverride.CheckOnAlert(self,dostate))OnAlert(dostate);
		}

		//do this last in case the state executes anything weird
		if(dostate)setstatelabel(label);

		return true;
	}

	//use this to do stuff when a monster first acquires a target
	virtual void OnAlert(bool dostate){}




	//sometimes monsters will alert other monsters
	enum ShoutAlertFlags{
		SAF_SIGHTONLY=1,  //only if target in sight
		SAF_NOMONSTERCOUNT=2,  //don't skip if too many monsters
		SAF_SILENT=4,  //don't play any sound

		SAC_MAXMONSTERCOUNT=1024,  //consider a server cvar
	}
	int nextshouttime;
	bool A_ShoutAlert(
		double chance=1.,
		int flags=0
	){
		if(
			!!target
			&&(
				!(flags&SAF_NOMONSTERCOUNT)
				||level.total_monsters<SAC_MAXMONSTERCOUNT
			)&&(
				chance==1.
				||frandom(0,1.)<chance
			)&&(
				!(flags&SAF_SIGHTONLY)
				||checksight(target)
			)&&(
				(flags&SAF_SILENT)
				||level.time>nextshouttime
			)
		){
			nextshouttime=level.time+TICRATE;
			if(!(flags&SAF_SILENT))A_Vocalize(
				random(0,2)?seesound
				:random(0,3)?activesound
				:painsound
			);

			//reset the timer
			let sac=ShoutAlertCounter.Get(target);
			if(!sac){
				sac=new("ShoutAlertCounter");
				sac.target=target;
				sac.cooldown=random(TICRATE*1,TICRATE*7);

				//grabs nearby monsters and alerts them
				blockthingsiterator itt=blockthingsiterator.create(self,HDCONST_MOBSOUNDRANGE);
				actor aat;
				while(itt.next()){
					actor aat=itt.thing;
					if(
						aat
						&&aat.bISMONSTER
						&&aat.health>0
						&&aat.findstate("see")
						&&inpainablesequence(aat)

						//capable of having a common enemy
						&&!ishostile(aat)
						&&aat.target!=self
						&&aat.lastheard!=self
						&&aat!=target
						&&aat!=lastheard

						&&(
							!aat.player
							||!(aat.player.cheats&CF_NOTARGET)
						)

						//not preoccupied with a more urgent target
						&&(
							!aat.target
							||(
								aat.target!=target
								&&(
									isfriend(aat)
									||!aat.checksight(aat.target)
								)
								&&!random(0,7)
							)
						)

						&&!aat.bNOBOUNCESOUND

						&&random(0,3)
					){
						aat.target=target;
						aat.reactiontime=aat.default.reactiontime;
						let hdmb=HDMobBase(aat);
						if(hdmb){
							hdmb.lasttargetpos=lasttargetpos+(
								frandom(-1,1)*(0.3*HDCONST_MOBSOUNDRANGE),
								frandom(-1,1)*(0.3*HDCONST_MOBSOUNDRANGE),
								(target&&target.bfloat)?
									frandom(-1,1)*(0.3*HDCONST_MOBSOUNDRANGE):
									0
							);
							if(!HDAIOverride.CheckOnAlert(hdmb,!aat.bambush))
								hdmb.OnAlert(!aat.bambush);
						}else{
							aat.a_startsound(aat.seesound,CHAN_VOICE
								,attenuation:aat.bboss?ATTN_DIRBOSS:ATTN_NORM
							);
						}
						if(hd_debug)console.printf("  * "..aat.gettag().." was alerted to "..target.gettag());
						if(!aat.bambush)aat.setstatelabel("see");
					}
				}

			}
			return true;
		}
		return false;
	}

	//heal a corpse
	virtual actor HealNearbyCorpse(double healradius){
		if(!findstate("heal"))return null;
		blockthingsiterator it=blockthingsiterator.create(self,healradius);
		while(it.next()){
			actor itt=it.thing;
			if(
				itt.bcorpse
				&&itt.canresurrect(self,true)
				&&canresurrect(itt,false)
				&&itt.findstate("raise")
				&&abs(itt.pos.z-pos.z)<maxstepheight*2
				&&heat.getamount(itt)<50
				&&checksight(itt)
				&&distance3dsquared(itt)<(healradius*healradius)
			){
				A_Face(itt);

				RaiseActor(itt,RF_NOCHECKPOSITION);
				itt.A_SetFriendly(bfriendly);
				itt.master=self;
				itt.target=target;
				itt.friendplayer=friendplayer;
				tracer=itt;

				setstatelabel("heal");
				return itt;
			}
		}
		return null;
	}


	//default for deciding a direction
	virtual double DecideOnHandedness(double rightnum,double reversechance=0.333){
		if(blefthanded)rightnum=-rightnum;
		return (frandom(0,1)<reversechance)?-rightnum:rightnum;
	}
}


class ShoutAlertCounter:Thinker{
	int cooldown;
	actor target;
	override void Tick(){
		cooldown--;
		if(cooldown<1)destroy();
	}
	static ShoutAlertCounter Get(actor target){
		ThinkerIterator it=ThinkerIterator.Create("ShoutAlertCounter",STAT_DEFAULT);
		ShoutAlertCounter p;
		while(p=ShoutAlertCounter(it.Next())){
			if(p.target==target)return p;
		}
		return null;
	}
}



// hacky actor that lets you override some AI functions
// to use, create a descendant class that replaces HDAIOverride,
// then customize the available virtual functions as required.
// if the function returns true, the regular one is skipped.
class HDAIOverride:Actor{
	default{+nointeraction}
	static HDAIOverride Get(){
		ThinkerIterator it=ThinkerIterator.Create("HDAIOverride",STAT_DEFAULT);
		HDAIOverride p;
		while(p=HDAIOverride(it.Next())){
			return p;
		}
		return HDAIOverride(spawn("HDAIOverride",(0,0,0),ALLOW_REPLACE));
	}


	virtual bool A_HDLook(
		hdmobbase caller,
		int flags,
		double minseedist,double maxseedist,double maxheardist,double lookfov,
		statelabel label
	){return false;}
	static bool HDLook(
		hdmobbase caller,
		int flags,
		double minseedist,double maxseedist,double maxheardist,double lookfov,
		statelabel label
	){
		let aio=HDAIOverride.Get();
		if(aio)return aio.A_HDLook(caller,flags,minseedist,maxseedist,maxheardist,lookfov,label);
		return false;
	}


	virtual bool A_HDChase(
		hdmobbase caller,
		statelabel meleestate,
		statelabel missilestate,
		int flags,
		double speedmult
	){return false;}
	static bool HDChase(
		hdmobbase caller,
		statelabel meleestate,
		statelabel missilestate,
		int flags,
		double speedmult
	){
		let aio=HDAIOverride.Get();
		if(aio)return aio.A_HDChase(caller,meleestate,missilestate,flags,speedmult);
		return false;
	}


	virtual bool OnAlert(
		hdmobbase caller,
		bool dostate
	){return false;}
	static bool CheckOnAlert(
		hdmobbase caller,
		bool dostate
	){
		let aio=HDAIOverride.Get();
		if(aio)return aio.OnAlert(caller,dostate);
		return false;
	}

}


