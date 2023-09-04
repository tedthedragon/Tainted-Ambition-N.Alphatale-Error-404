//-------------------------------------------------
// Ladder
//-------------------------------------------------


/*
maybe someday...

class HDLadderSegment:HDUPK{
	HDLadderSegment above;
	HDLadderSegment below;
	vector2 segofs;
	override void Tick(){
		super.Tick();
		if(
			isfrozen()
			||!above
		)return;

		vector2 vxy=(vel.xy+above.vel.xy);
		if(!!below)vel.xy=(vxy+below.vel.xy)*0.27;
		else vel.xy=vxy*0.4;

		vector2 midxy=(above.pos.xy+above.segofs+pos.xy)*0.5;
		setorigin((midxy,pos.z),true);
		A_SetAngle((above.angle+angle)*0.5,SPF_INTERPOLATE);


		//winding up
		if(
			above.bfrightened
			||above.health<above.spawnhealth()
		){
			bfrightened=true;
			vel=(above.vel+vel)*0.4;
			if(vel.z<0)vel.z+=HDCONST_GRAVITY;
			setz((above.pos.z+pos.z)*0.5);

			if(!below){
				HDLadderTopSeg topseg;
				array<HDLadderSegment> aboves;aboves.clear();
				let bbb=above;
				while(!!bbb){
					aboves.push(bbb);
					bbb=bbb.above;
					if(HDLadderTopSeg(bbb))topseg=HDLadderTopSeg(bbb);
				}

				if(
					!!topseg
					&&topseg.pos.z-pos.z<=height
				){
					for(int i=0;i<aboves.size();i++){
						aboves[i].destroy();
					}
					let aaa=spawn("PortableLadder",(topseg.pos.xy+topseg.segofs,topseg.pos.z));
					if(aaa){
						aaa.translation=translation;
						aaa.vel=topseg.vel;
					}
					topseg.destroy();
					destroy();
					return;
				}
			}

			return;
		}


		double targetz=above.pos.z-height;
		if(pos.z>targetz+0.1){
			if(pos.z>above.pos.z+above.height){
				if(vel.z>0){
					above.vel.z+=vel.z*0.1;
					vel.z=min(0,vel.z*0.1);
				}
				A_StartSound("ladder/segbounce",CHAN_BODY);
				above.A_StartSound("ladder/segbounce",CHAN_BODY);
			}
			return;
		}
		if(pos.z>targetz){
			vel.z=0;
			return;
		}
		if(pos.z<targetz)vel.z+=(targetz-pos.z)*0.3;
		if(vel.z<-HDCONST_GRAVITY){
			vel.z=min(10,vel.z*-0.3);
			setz(clamp(pos.z,above.pos.z-height,above.pos.z+above.height));
			A_StartSound("ladder/segbounce",CHAN_BODY);
		}
		else vel.z=max(0,vel.z*0.9);
	}
	override bool OnGrab(actor grabber){
		grabber.A_Log("You touch the ladder.");
		return false;
	}
	default{
		+wallsprite
		+shootable +noblood +nopain
		+notargetswitch +friendly
		height 12;
		radius 10;
		health 30;
	}
	states{
	spawn:
		LADD B -1;
		stop;
	}
}
class HDLadderTopSeg:HDLadderSegment{
	default{
		+nogravity
		+blockasplayer

		-wallsprite
		+flatsprite
		+rollcenter

		height 10;
		radius 12;
		stamina 10;
	}
	override void Tick(){
		super.Tick();
		if(isfrozen())return;
		segofs=(cos(angle),sin(angle))*18;
	}
	override void PostBeginPlay(){
		super.PostBeginPlay();
		pitch=18;
		HDLadderSegment lastseg=self;
		vector2 sgo=(cos(angle),sin(angle))*0.2;
		segofs=sgo*90;
		vector3 segpos=(pos.xy+segofs,pos.z-10);
		for(int i=0;i<stamina;i++){
			let seg=HDLadderSegment(spawn("HDLadderSegment",segpos+sgo*i));
			if(!seg)break;
			seg.angle=angle;
			seg.above=lastseg;
			seg.segofs=sgo;
			seg.translation=translation;
			lastseg.below=seg;
			lastseg=seg;
		}
	}
	states{
	spawn:
		LADD A -1;
		stop;
	}
}
*/










//show where the ladder is hanging
//no it doesn't swing, math is hard :(
class hdladdersection:IdleDummy{
	int secnum;
	default{
		+wallsprite
	}
	states{
	spawn:
		LADD B 0 nodelay A_JumpIf(master&&target,1);
		stop;
		LADD B 1 setz(max(target.floorz,master.pos.z-LADDER_SECTIONLENGTH*secnum));
		loop;
	}
}
class hdladdertopinvisible:hdladdertop{
	default{
		//$Category "Misc/Hideous Destructor/"
		//$Title "Ladder Top (Invisible)"
		//$Sprite "LADDA0"
		+invisible
	}
}
class hdladdertop:hdactor{
	default{
		//$Category "Misc/Hideous Destructor/"
		//$Title "Ladder Top"
		//$Sprite "LADDA0"

		+flatsprite
		+nointeraction
		+notrigger
		+blockasplayer

		height 4;radius 10;
		maxstepheight 64;
		maxdropoffheight 640;
		mass int.MAX;
	}
	states{
	spawn:
		LADD A 1 nodelay setz(getzat()+4);
		wait;
	}
	//pass uses through to ladder bottom
	override bool used(actor user){
		return target.used(user);
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnParticle("darkred",0,10);
		pitch=18;
		bmissile=false;master=target;
		setz(floorz);
		fcheckposition tm;
		vector2 mvlast=pos.xy;
		vector2 mv=angletovector(angle,2);
		for(int i=0;i<20;i++){

			if(
				!checkmove(mvlast,PCM_NOACTORS,tm)
				&&!!master //don't break if placed by mapper
			)break;

			A_UnsetSolid();
			mvlast+=mv;

			//found a place for the ladder to hang down
			double htdiff=clamp(floorz-tm.floorz,0,LADDER_MAX);
			if(
				htdiff
			){

				//spawn the ladder end
				target=spawn("hdladderbottom",tm.pos,ALLOW_REPLACE);
				target.target=self;
				target.master=master;
				target.angle=angle;
				target.pitch=-27;

				vector2 mv2=mv*0.02;
				vector3 newpos=tm.pos;

				//spawn the ladder sections
				if(binvisible){
					target.binvisible=true;
				}else{
					double sectionlength=min(htdiff,LADDER_MAX)/LADDER_SECTIONS;
					for(int i=1;i<=LADDER_SECTIONS;i++){
						newpos.xy+=mv2;
						let sss=hdladdersection(spawn("hdladdersection",newpos,ALLOW_REPLACE));
						sss.master=self;sss.target=target;sss.angle=angle+frandom(-1.,1.);
						sss.secnum=i;
						target.setorigin(newpos+(0,0,-sectionlength*i),true);
						if(master){
							sss.translation=master.translation;
							target.translation=master.translation;
						}
					}
				}

				//reposition the thing
				setorigin((tm.pos.xy-mv*radius,floorz),true);

				//only complete if start or within throwable range, else abort
				if(!master)return;
				if(pos.z-master.pos.z<108){
					A_StartSound("misc/ladder");
					master.A_Log(string.format(Stringtable.Localize("$LADDER_HANG"),HDWeapon.CheckDoHelpText(master)?Stringtable.Localize("$LADDER_HANG_HELPTEXT"):""),true);
					master.A_TakeInventory("PortableLadder",1);
					return;
				}
			}
		}

		//if there's no lower floor to drop the ladder, abort.
		if(master){
			master.A_Log(Stringtable.Localize("$LADDER_CANTHANG"),true);
		}else{
			actor hdl=spawn("PortableLadder",pos,ALLOW_REPLACE);
			hdl.A_StartSound("misc/ladder");
		}
		destroy();
	}
}
const LADDER_SECTIONLENGTH=12.;
const LADDER_MAX=LADDER_SECTIONLENGTH*67.;
const LADDER_SECTIONS=LADDER_MAX/LADDER_SECTIONLENGTH;

class HDLadderProxy:HDActor{
	default{
		+nogravity +invisible
		height 56;radius 10;
		mass int.MAX;
	}
	override bool used(actor user){
		if(master) return master.used(user);
		else destroy();
		return false;
	}
}

const LADDER_CLIMBRANGE = 16;
const LADDER_WALKRANGE  = 40;

const LADDER_WALKRANGESQR = LADDER_WALKRANGE ** 2;

class hdladderbottom:hdactor{
	default{
		+nogravity +flatsprite
		height 56;radius 14;
		mass int.MAX;
	}
	override bool used(actor user){
		double upz=user.pos.z;
		if(
			upz>target.pos.z+24  
			||upz+user.height*1.3<pos.z
		)return false;

		bool grounded = user.pos.z <= user.floorz;
		if (user.player) grounded = user.player.onground;

		//check if user can reach
		if(
			grounded
			? distance2DSquared(user) > LADDER_WALKRANGESQR
			: !HDMath.InXYRange(Vec2To(user), LADDER_CLIMBRANGE)
		)return false;

		let thinker = HDLadderThinker(user.FindInventory('HDLadderThinker'));
		if (thinker && thinker.master == self) {
			thinker.DisengageLadder();
			return false;
		}

		if (!thinker) thinker = HDLadderThinker(user.GiveInventoryType('HDLadderThinker'));
		thinker.LinkToLadder(self);

		user.A_Log(string.format(Stringtable.Localize("$LADDER_CLIMB"),HDWeapon.CheckDoHelpText(user)?Stringtable.Localize("$LADDER_CLIMB_HELPTEXT"):""),true);
		return true;
	}
	override void postbeginplay(){
		if(CurSector.GetPortalType(Sector.Floor)==SectorPortal.TYPE_LINKEDPORTAL){
			SectorPortal portal=Level.SectorPortals[CurSector.Portals[Sector.Floor]];

			vector3 newPos=(pos.xy+portal.mDisplacement, 0);
			newPos.z=portal.mDestination.FloorPlane.ZAtPoint(newPos.xy);

			HDLadderProxy(Spawn("HDLadderProxy",newPos,ALLOW_REPLACE)).master=self;
		}
	}
	override void tick(){
		if(!target){destroy();return;}
		setz(
			clamp(floorz,
				max(target.pos.z-LADDER_MAX,floorz),
				target.pos.z+LADDER_MAX
			)
		);

		A_SetSize(-1,min(LADDER_MAX,target.pos.z-pos.z)+32);
	}
	states{
	spawn:
		LADD C -1;wait;
	}
}

class HDLadderThinker : Inventory {
	default { +inventory.untossable }

	void DisengageLadder(bool message = true) {
		//hack to reset bob to 0 when falling
		owner.vel += (owner.Vec2To(master).Unit()*0.3, 0);
		if(message) owner.A_Log(Stringtable.Localize("$LADDER_DISENGAGE"), true);
		Destroy();
	}

	bool dontCheckUse;
	void LinkToLadder(Actor ladder) {
		target = ladder.target;
		master = ladder;

		//DoEffect will be called in the same tick as the player using the ladder
		//this prevents the use-to-disengage code from running in that tick
		dontCheckUse = true;
	}

	override void DoEffect() {
		if(!target || owner.health < 1) {
			Destroy();
			return;
		}

		//check if facing the ladder
		bool facing = absangle(owner.angleto(master), owner.angle) < 90;

		let above = owner.pos.z > target.pos.z - 16;
		let atTop = owner.pos.z > target.pos.z - 20;

		let distSqr = master.distance2DSquared(owner);

		let userOffset = master.Vec2To(owner);

		let grounded = owner.pos.z <= owner.floorz;
		if(owner.player) grounded = owner.player.onground;

		let inClimbRange = HDMath.InXYRange(userOffset, LADDER_CLIMBRANGE);

		if(inClimbRange && !above && !grounded) {
			if(!atTop && distSqr < 9.) owner.A_ChangeVelocity(-1, 0, 0, CVF_RELATIVE);
			owner.vel = (0, 0, 0);
		}

		vector3 move = (0, 0, 0);
		if(owner.player){
			if(
				(grounded && distSqr > LADDER_WALKRANGESQR) ||
				(!grounded && !above && !inClimbRange)
			){
				DisengageLadder();
				return;
			}

			let bt = owner.player.cmd.buttons;
			let oldbt = owner.player.oldbuttons;
			if(bt&BT_JUMP){
				if(
					!target.binvisible
					&&owner.player.crouchfactor<0.9
				){
					owner.A_Log(
						above? Stringtable.Localize("$LADDER_UP") : Stringtable.Localize("$LADDER_DOWN"),
						true
					);

					actor hdl = spawn("PortableLadder", target.pos, ALLOW_REPLACE);
					hdl.A_StartSound("misc/ladder");
					hdl.translation=master.translation;

					if(!above)GrabThinker.Grab(owner, hdl);

					target.destroy();
					destroy();

					return;
				}else{
					if(!above){
						vector3 vl = (userOffset.unit(),1);
						if(hdplayerpawn(owner))vl*=(0.5+0.5*hdplayerpawn(owner).strength);
						owner.vel += vl;
					}
					disengageladder();
					return;
				}
			}
			else if(!dontCheckUse && (bt&BT_USE) && !(oldbt&BT_USE)){
				disengageladder();
				return;
			}
			else dontCheckUse = false;

			if(!above){
				//climbing interface
				if(!grounded || inClimbRange){
					double spm = owner.speed;
					double fm = owner.player.cmd.forwardmove;
					if(fm>0) fm = spm; else if(fm < 0) fm=-spm;
					double sm = owner.player.cmd.sidemove;
					if(sm>0) sm = spm; else if(sm < 0) sm=-spm;

					//barehanded and descending are faster
					if(facing){
						if(!sm && fm < 0) fm *= 1.5;
						weapon wp = owner.player.readyweapon;
						if(wp is "HDFist"||wp is "NullWeapon"){
							sm *= 2;fm *= 2;
						}
					}else fm *= -1;

					let hdp=hdplayerpawn(owner);
					if(hdp){
						fm*=(0.4+0.6*hdp.strength);
						if(hdp.stunned)fm*=0.2;
					}

					//apply climbing
					move.z = fm;
					if(sm) move.xy = angletovector(owner.angle - 90, sm);

					if (!(fm || sm) && PlayerPawn(owner))
					{
						//viewbob needs to be set after HDPlayerPawn.Tick
						let setter = new('HDViewbobSetter');
						setter.owner = PlayerPawn(owner);
						setter.viewbob = 0;
					}
				}
				if(!grounded && atTop){
					double fm = owner.player.cmd.forwardmove * 0.000125;
					double sm = owner.player.cmd.sidemove * 0.000125;
					if(fm||sm) move.xy = rotatevector((fm, -sm), owner.angle);
				}
			}
		}

		if(move.z){
			owner.vel.z = clamp(
				owner.pos.z + move.z,
				master.pos.z - owner.height * 1.3,
				target.pos.z - 16
			) - owner.pos.z;
		}

		if(move.x || move.y){
			//clamp movement
			let dest = userOffset + move.xy;
			move.x -= dest.x - clamp(dest.x, -LADDER_CLIMBRANGE, LADDER_CLIMBRANGE);
			move.y -= dest.y - clamp(dest.y, -LADDER_CLIMBRANGE, LADDER_CLIMBRANGE);
			owner.trymove(owner.pos.xy + move.xy, true);
		}
	}
}

//sets viewbob after HDPlayerPawn.Tick
class HDViewbobSetter : Thinker {
	double viewbob;
	PlayerPawn owner;

	override void Tick()
	{
		owner.ViewBob = ViewBob;
		Destroy();
	}
}

class PortableLadder:HDPickup{
	default{
		inventory.icon "LADDD0";
		inventory.pickupmessage "$PICKUP_LADDER";
		height 20;radius 8;
		hdpickup.bulk ENC_LADDER;
		hdpickup.refid HDLD_LADDER;
		tag "$TAG_LADDER";
	}
	states{
	spawn:
		LADD D -1;
		stop;
	use:
		TNT1 A 0{
			actor aaa;int bbb;
			[bbb,aaa]=A_SpawnItemEx(
				"HDLadderTop",18*cos(pitch),0,48-18*sin(pitch),
				flags:SXF_SETTARGET
			);if(!aaa)return;

			//let the engine correct the position (if necessary)
			aaa.trymove(aaa.pos.xy,1);

			//only face player if above player's stepheight
			if(aaa.floorz>pos.z+maxstepheight){  
				aaa.angle+=180;
			}
		}fail;
	}
}
