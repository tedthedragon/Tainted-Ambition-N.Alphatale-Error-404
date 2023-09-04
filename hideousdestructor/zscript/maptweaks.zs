// ------------------------------------------------------------
// Not a territory but a living document
// ------------------------------------------------------------
const HDCONST_LIFTWAITMULT=5;
class DelayedLineActivator:Thinker{
	int timer;
	int activationtype;
	actor activator;
	line activated;
	static void Init(
		line lll,
		int type,
		actor aaa=null,
		int ttt=1
	){
		DelayedLineActivator dla=null;
		ThinkerIterator finder=ThinkerIterator.Create("DelayedLineActivator");
		while(dla=DelayedLineActivator(finder.Next())){
			if(dla.activated==lll)return;
		}
		dla=new("DelayedLineActivator");
		dla.activator=aaa;
		dla.activated=lll;
		dla.activationtype=type;
		if(ttt<=0)dla.timer=1;
		else dla.timer=ttt;
	}
	override void Tick(){
		if(!timer){
			int ls=activated.special;
			int a0=activated.args[0];
			int a1=activated.args[1];
			int a2=activated.args[2];
			int a3=activated.args[3];
//			if(activator)activator.A_CallSpecial(ls,a0,a1,a2,a3);
			activated.activate(activator,line.front,activationtype);
		}else if(timer<0){
			destroy();
			return;
		}
		timer--;
	}
}
extend class HDHandlers{

	bool LinePartOfTaggedSector(
		line lll,
		bool trueifany=false
	){
		int largo=lll.args[0];
		if(!largo)return true; //assume it's just using the sector behind it
		int sci=-1;
		let scc=level.CreateSectorTagIterator(largo);
		bool anyfound=false;
		while((sci=scc.Next())>=0){
			sector sss=level.sectors[sci];
			bool isinthissector=false;
			for(int i=0;i<sss.lines.size();i++){
				if(sss.lines[i]==lll){
					isinthissector=true;
					anyfound=true;
					break;
				}
			}
			if(
				!isinthissector
				&&!trueifany
			)return false;
		}
		return anyfound;
	}

	override void WorldLinePreActivated(WorldEvent e){
		let lll=e.ActivatedLine;
		switch(lll.special){
		case Plat_DownWaitUpStayLip:
		case Plat_DownWaitUpStay:
		case Generic_Lift:
			if(
				e.ActivationType==SPAC_Cross
				&&e.Thing
				&&LinePartOfTaggedSector(lll,true)
			){
				bool aaaaa=false;
				DelayedLineActivator dla=null;
				ThinkerIterator finder=ThinkerIterator.Create("DelayedLineActivator");
				while(dla=DelayedLineActivator(finder.Next())){
					if(dla.activated==lll){
						aaaaa=true;
						break;
					}
				}
				if(!aaaaa){
					e.ShouldActivate=false;
					DelayedLineActivator.Init(lll,e.ActivationType,e.Thing,25);
				}
			}
			break;
		}
	}

	void MapTweaks(){

		//generic map hacks
		textureid dirtyglass=texman.checkfortexture("HDWINDOW",texman.type_any);
		bool dww=hd_dirtywindows;
		int itmax=level.lines.size();
		for(int i=0;i<itmax;i++){
			line lll=level.lines[i];
			if(lll.special){
				switch(lll.special){

				//increase door delays
				case Door_WaitRaise: //delay is third arg
				case Door_WaitClose:
				case Door_Raise:
				case Door_LockedRaise:
				case Door_WaitClose:
				case Door_Animated:
				//case Door_CloseWaitOpen:
				//case Door_WaitRaise:
					if(
						hd_safelifts
						&&!LinePartOfTaggedSector(lll)
					)lll.args[2]*=HDCONST_LIFTWAITMULT;
					break;
				case Generic_Door: //delay is fourth arg
					if(
						hd_safelifts
						&&!LinePartOfTaggedSector(lll)
					)lll.args[3]*=HDCONST_LIFTWAITMULT;
					break;


				//cap platform speeds
				case Plat_DownWaitUpStayLip: //delay is third arg
				case Plat_DownWaitUpStay:
				case Plat_UpNearestWaitDownStay:
				case Plat_UpWaitDownStay:
				case Plat_PerpetualRaise:
				case Plat_PerpetualRaiseLip:
				case Generic_Lift:
					if(
						hd_safelifts
						&&!LinePartOfTaggedSector(lll)
					)lll.args[2]*=HDCONST_LIFTWAITMULT;
				case Plat_DownByValue:
				case Plat_PerpetualRaiseLip:
				case Plat_PerpetualRaise:
				case Plat_RaiseAndStayTx0:
				case Plat_UpByValue:
				case Plat_UpByValueStayTx:
				case Generic_Floor:
				case Floor_LowerByValue:
				case Floor_LowerToLowest:
				case Floor_LowerToHighest:
				case Floor_LowerToHighestEE:
				case Floor_LowerToNearest:
				case Floor_RaiseByValue:
				case Floor_RaiseToHighest:
				case Floor_RaiseToNearest:
				case Floor_RaiseToLowest:
					if(
						hd_safelifts
					)lll.args[1]=clamp(lll.args[1],-24,24);
					break;

				//prevent lights from going below 1
				case Light_ChangeToValue:
				case Light_Fade:
				case Light_LowerByValue:
					lll.args[1]=max(lll.args[1],1);break;
				case Light_Flicker:
				case Light_Glow:
				case Light_Strobe:
					lll.args[2]=max(lll.args[2],1);break;
				case Light_StrobeDoom:
					lll.args[2]=min(lll.args[2],1);break;
				case Light_RaiseByValue:
					if(lll.args[1]>=0)break;
				case Light_LowerByValue:
					sectortagiterator sss=level.createsectortagiterator(lll.args[0]);
					int ssss=sss.next();
					int lowestlight=255;
					while(ssss>-1){
						lowestlight=min(lowestlight,level.sectors[ssss].lightlevel);
						ssss=sss.next();
					}
					lll.args[1]=min(lll.args[1],lowestlight-1);

				default: break;
				}
			}


			//remove arbitrary invisible barriers
			if(
				dww
				&&!!lll.sidedef[1]
				&&!lll.sidedef[0].gettexture(side.mid)
				&&!lll.sidedef[1].gettexture(side.mid)
			){
				if(
					lll.flags&(
						line.ML_BLOCKEVERYTHING
						|line.ML_BLOCK_PLAYERS
						|line.ML_BLOCKING
					)
				){
					if(
						lll.frontsector.gettexture(lll.frontsector.ceiling)==skyflatnum
						||lll.backsector.gettexture(lll.frontsector.ceiling)==skyflatnum

						||lll.frontsector.gettexture(lll.backsector.floor)==skyflatnum
						||lll.backsector.gettexture(lll.backsector.floor)==skyflatnum

						||UnfitWindowSectors(lll)
					){
						lll.flags|=line.ML_BLOCKMONSTERS;
						lll.flags&=~(
							line.ML_BLOCKEVERYTHING
							|line.ML_BLOCK_PLAYERS
							|line.ML_BLOCKHITSCAN
							|line.ML_BLOCKPROJECTILE
							|line.ML_BLOCKING
							|line.ML_BLOCKUSE
						);
					}else{
						lll.flags|=
							line.ML_BLOCK_PLAYERS
							|line.ML_BLOCKMONSTERS
							|line.ML_BLOCKHITSCAN
							|line.ML_BLOCKPROJECTILE
							|line.ML_BLOCKING
							|line.ML_BLOCKUSE
						;

						//make the barrier visible
						lll.flags|=line.ML_WRAP_MIDTEX;
						lll.sidedef[0].settexture(side.mid,dirtyglass);
						lll.sidedef[1].settexture(side.mid,dirtyglass);
						lll.alpha=0.2;
					}
				}
			}
		}


		//lol nirvana sux
		if(
			Wads.CheckNumForName("doom2hellonearth",0)!=-1
			&&level.mapname~=="MAP21"
			&&!HDMath.CheckLumpReplaced("MAP21")
		){
			actor.spawn("HDExit",(4538,3134,0));
			console.printf("An exit teleport has spawned in the starting room.");
		}


		if(Wads.CheckNumForName("freedoom",0)!=-1){
			if(
				level.mapname~=="MAP26"
				&&!HDMath.CheckLumpReplaced("MAP26")
			){
				//This map does NOT play well with HD at all
				//so have an exit pad instead.
				actor.spawn("HDExit",(-32,-162,0));
				console.printf("An exit teleport has spawned in the starting room.");
			}else if(
				level.mapname~=="MAP12"
				&&!HDMath.CheckLumpReplaced("MAP12")
			){
				//the line circumvents HD's delayed lift by putting
				//the walk-over just NEXT to the sector that lowers,
				//instead of using a line on the lowering sector itself.
				//this is gross as fuck and is bad enough in vanilla to
				//lower the platform BEFORE you even step onto it in any way.
				//serious what the FUCK were you thinking, mapper!??!?

				line ll=level.lines[1561];  //original triggering line
				line lll=level.lines[1572];  //actual line on the platform

				lll.special=ll.special;
				lll.flags|=line.ML_MONSTERSCANACTIVATE|line.ML_REPEAT_SPECIAL;
				lll.args[0]=ll.args[0];
				lll.args[1]=ll.args[1];
				lll.args[2]=ll.args[2]/HDCONST_LIFTWAITMULT;
				lll.args[3]=ll.args[3];
				lll.activation=SPAC_Cross;

				ll.special=0;

				level.sectors[228].settexture(sector.floor,level.sectors[225].gettexture(sector.floor),true);
			}else if(
				level.mapname~=="MAP17"
				&&!HDMath.CheckLumpReplaced("MAP17")
			){
				//give only one player the blursphere, y'all can figure it out
				for(int i=0;i<MAXPLAYERS;i++){
					if(players[i].mo){
						players[i].mo.A_GiveInventory("HDBlursphere");
						break;
					}
				}
			}else if(
				level.mapname~=="MAP31"
				&&!HDMath.CheckLumpReplaced("MAP31")
			){
				//give *everyone* a blursphere, one rocket can kill the whole squad before you can even move
				for(int i=0;i<MAXPLAYERS;i++){
					if(players[i].mo)players[i].mo.A_GiveInventory("HDBlursphere");
				}
			}
		}
	}


	//a lot of maps have recessed switches behind invisible blocking lines.
	//this checks for any such blocker that shares a sector with a usable
	//or shootable switch so that the glassification process can be skipped.
	bool LineIsSwitch(line lll){
		return
			lll.special>0
			&&lll.special!=Line_Horizon
			&&lll.activation&(
				SPAC_Use
				|SPAC_Push
				|SPAC_Impact
				|SPAC_UseThrough
				|SPAC_MUse
				|SPAC_MPush
				|SPAC_UseBack
			)
		;
	}
	bool UnfitWindowSectors(line lll){
		//don't bother if it's actually meant to block the switch
		if(lll.flags&line.ML_BLOCKUSE)return false;

		sector csec=lll.frontsector;
		int linecount=csec.lines.size();
		if(linecount<20)for(int i=0;i<linecount;i++){
			if(LineIsSwitch(csec.lines[i]))return true;
		}
		csec=lll.backsector;
		linecount=csec.lines.size();
		if(linecount<20)for(int i=0;i<linecount;i++){
			if(LineIsSwitch(csec.lines[i]))return true;
		}
		return false;
	}
}


//exit pad that can be placed anywhere
class HDExit:SwitchableDecoration{
	default{
		radius 32;
		height 50;
		+flatsprite
		+usespecial
		activation thingspec_switch;
	}
	states{
	spawn:
		TNT1 A 0 nodelay{
			angle=-90;
			setz(floorz);
		}
		goto inactive;
	active:
		GATE A -1;
		stop;
	inactive:
		GATE B 10{
			bool standingon=false;
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					!playeringame[i]
					||players[i].bot
				)continue;
				let ppp=players[i].mo;
				if(ppp){
					vector3 dist=pos-ppp.pos;
					double dist2=max(abs(dist.x),abs(dist.y));

					if(dist2<32&&!dist.z)standingon=true;
					else if(
						//abort if any player is too far away
						standingon
						&&dist2>256
					){
						console.printf("You must gather your party before venturing forth.");
						return;
					}

				}
			}
			if(standingon)A_BrainDie();
		}wait;
	}
}


/*
class HDMapTweaks:LevelPostProcessor{
	protected void Apply(Name checksum, String mapname){
		if(Wads.CheckNumForName("freedoom",0)!=-1){
		}
	}
}
*/

