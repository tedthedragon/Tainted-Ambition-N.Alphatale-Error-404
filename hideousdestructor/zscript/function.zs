// ------------------------------------------------------------
// Basic functional stuff
// ------------------------------------------------------------

//event handler
class HDStaticHandlers:StaticEventHandler{}
class HDHandlers:EventHandler{
	array<double> invposx;
	array<double> invposy;
	array<double> invposz;

	override void RenderOverlay(renderevent e){
		hdlivescounter.RenderEndgameText(e.camera);
	}
	override void WorldLoaded(WorldEvent e){
		//seed a few more spawnpoints
		for (int i=0;i<5;i++){
			vector3 ip=level.PickDeathmatchStart();
			invposx.push(ip.x);
			invposy.push(ip.y);
			invposz.push(ip.z);
		}

		if(hd_flagpole)spawnflagpole();

		//reset some player stuff
		for(int i=0;i<MAXPLAYERS;i++){
			flagcaps[i]=0;
		}

		HDBleedingWound.UnSetStatics();

		MapTweaks();
	}
	override void WorldUnloaded(WorldEvent e){
		HDBleedingWound.SetStatics();
	}
}

//because "extend class Actor" doesn't work
class HDActor:Actor{
	default{
		+noblockmonst
		gravity HDCONST_GRAVITY;
	}

	//for frags: A_SpawnChunks("HDB_frag",42,100,700);
	void A_SpawnChunks(
		class<actor> chunk,
		int number=12,
		double minvel=10,
		double maxvel=20,
		double anglespread=180,
		double pitchspread=90
	){
		double burstz=pos.z+height*0.5;

		double minpch=-90;
		double maxpch=90;

		if(pos.z>ceilingz)minpch=10;
		else{
			minpch=ceilingz-burstz<16?-9:max(pitch-pitchspread,-90);
			maxpch=burstz-floorz<16?9:min(pitch+pitchspread,90);
		}


		for(int i=0;i<number;i++){
			actor frg=spawn(chunk,(pos.xy,burstz),ALLOW_REPLACE);
			if(HDBulletActor(frg))frg.bincombat=true; //shouldn't be happening inside shooter

			frg.target=target;
			frg.master=master;
			frg.tracer=tracer;

			frg.pitch=frandom(minpch,maxpch);
			frg.angle=angle+frandom(-anglespread,anglespread);

			double cp=cos(frg.pitch);
			frg.vel=vel+(cp*cos(frg.angle),cp*sin(frg.angle),-sin(frg.pitch))*frandom(minvel,maxvel);
		}
	}

	//manually advance state sequence
	void NextTic()
	{
		//reached end of state sequence
		if(!CurState){
			Destroy();
			return;
		}

		//advance to next state
		//automatically goes through all 0-tick states
		if(CheckNoDelay() && tics != -1 && --tics <= 0)
			SetState(CurState.NextState);
	}
}
class HDArcPuff:HDActor{
	default{
		+nogravity
		+puffgetsowner
		+puffonactors
		+forcepain
		+noblood
		scale 0.4;
		damagetype "electrical";
		radius 0.1;
		height 0.1;
	}
	states{
	spawn:
		TNT1 A 5 A_StartSound("misc/arczap",CHAN_ARCZAP,CHANF_OVERLAP,volume:0.1,attenuation:0.4);
		stop;
	}
}



// a replacement for the old inventoryflag system.
// no more initializing a whole new actor every give.
class ThinkerFlag:Thinker{
	actor owner;
	double amount;

	//finds a flag
	clearscope static ThinkerFlag Find(actor owner,class<ThinkerFlag> type){
		ThinkerFlag ttt;
		ThinkerIterator finder=ThinkerIterator.Create(type);
		while(ttt=ThinkerFlag(finder.Next())){
			if(ttt.owner==owner)return ttt;
		}
		return null;
	}
	//returns the amount for this owner
	clearscope static double Count(actor owner,class<ThinkerFlag> type){
		let ttt=ThinkerFlag.Find(owner,type);
		if(ttt)return ttt.amount;
		return 0;
	}
	//finds a flag and creates one if none found
	static ThinkerFlag Get(actor owner,class<ThinkerFlag> type){
		let ttt=ThinkerFlag.Find(owner,type);
		if(ttt)return ttt;
		ttt=ThinkerFlag(new(type));
		ttt.owner=owner;
		ttt.amount=0;
		return ttt;
	}
	static double Set(actor owner,class<ThinkerFlag> type,double amount){
		let ttt=ThinkerFlag.Get(owner,type);
		ttt.amount=amount;
		return ttt.amount;
	}
	static double Give(actor owner,class<ThinkerFlag> type,double amount){
		let ttt=ThinkerFlag.Get(owner,type);
		ttt.amount+=amount;
		return ttt.amount;
	}
	//removes all of this flag for this owner
	static void Remove(actor owner,class<ThinkerFlag> type){
		ThinkerFlag ttt;
		ThinkerIterator finder=ThinkerIterator.Create(type);
		while(ttt=ThinkerFlag(finder.Next())){
			if(ttt.owner==owner)ttt.destroy();
		}
	}
}

//should only be used for things that must be kept across level changes
class InventoryFlag:Inventory{
	default{
		+inventory.untossable;+nointeraction;+noblockmap;
		inventory.maxamount 1;inventory.amount 1;
	}
	override void tick(){
		if(!owner){destroy();return;}
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	}
}
//"should" -_-
class IsMoving:InventoryFlag{
	default{
		+inventory.keepdepleted
		inventory.maxamount 20;
		inventory.interhubamount 0;
	}
	static IsMoving Get(actor caller){
		return IsMoving(caller.findinventory("IsMoving"));
	}
	static void Give(actor caller,int amt){
		let im=IsMoving.Get(caller);
		if(im){
			im.amount=clamp(im.amount+amt,0,im.maxamount);
		}else if(amt>0)caller.A_GiveInventory("IsMoving",amt);
	}
	static void Clear(actor caller){
		let im=IsMoving.Get(caller);
		if(im)im.amount=0;
	}
	static int Count(actor caller){
		let im=IsMoving.Get(caller);
		if(im)return im.amount;
		return 0;
	}
}
class ActionItem:CustomInventory{
	default{
		+inventory.untossable -inventory.invbar +noblockmap
	}
	//wrapper for HDWeapon and ActionItem
	//remember: LEFT and DOWN
	//would use vector2s but lol bracketing errors I don't need that kind of negativity in my life
	action void A_MuzzleClimb(
		double mc10=0,double mc11=0,
		double mc20=0,double mc21=0,
		double mc30=0,double mc31=0,
		double mc40=0,double mc41=0
	){
		let hdp=HDPlayerPawn(self);
		if(hdp){
			hdp.A_MuzzleClimb((mc10,mc11),(mc20,mc21),(mc30,mc31),(mc40,mc41));
		}else{ //I don't even know why
			vector2 mc0=(mc10,mc11)+(mc20,mc21)+(mc30,mc31)+(mc40,mc41);
			A_SetPitch(pitch+mc0.y,SPF_INTERPOLATE);
			A_SetAngle(angle+mc0.x,SPF_INTERPOLATE);
		}
	}
	override void tick(){
		if(!owner){destroy();return;}
	}
	states{
	nope:
		TNT1 A 0;fail;
	spawn:
		TNT1 A 0;stop;
	}
}


class IdleDummy:HDActor{
	default{
		+noclip +nointeraction +noblockmap
		height 0;radius 0;
	}
	override void Tick(){
		if(isfrozen())return;
		clearinterpolation();
		setorigin(pos+vel,true);
		vel*=friction;
		nexttic();
	}
	states{
	spawn:
		TNT1 A -1 nodelay{if(stamina>0)A_SetTics(stamina);}
		stop;
	}
}
class CheckPuff:IdleDummy{
	default{
		+bloodlessimpact +hittracer +puffonactors +alwayspuff +puffgetsowner
		stamina 1;
	}
}


// Blocker to prevent shotguns from overpenetrating multiple targets
// tempshield.spawnshield(self);
class tempshield:HDActor{
	default{
		-solid +shootable +nodamage
		radius 16;height 50;
		stamina 16;
	}
	static actor spawnshield(
		actor caller,class<actor> type="tempshield",
		bool deathheight=false,int shieldlength=16
	){
		actor sss=caller.spawn(type,caller.pos,ALLOW_REPLACE);
		if(!sss)return null;
		sss.master=caller;
		sss.A_SetSize(
			caller.radius,
			deathheight?getdefaultbytype(caller.getclass()).deathheight
			:getdefaultbytype(caller.getclass()).height
		);
		sss.bnoblood=caller.bnoblood;
		sss.stamina=shieldlength;
		return sss;
	}
	override void Tick(){
		if(!master||stamina<1){destroy();return;}
		setorigin(master.pos,false);
		stamina--;
	}
	states{
	spawn:
		TNT1 A -1;
		stop;
	}
}


//collection of generic math functions
struct HDMath{
	//check if there is more than one of this lump loaded
	static bool CheckLumpReplaced(
		name lmpnm,
		int ns=Wads.GlobalNamespace
	){
		let aaa=Wads.FindLump(lmpnm,ns:ns);
		return Wads.CheckNumForName(lmpnm,ns)!=aaa;
	}

	//checks encumbrance multiplier
	//hdmath.getencumbrancemult()
	static double GetEncumbranceMult(){
		return max(hd_encumbrance,0.);
	}

	//returns if pvp with no clear end in sight
	static bool deathmatchclutter(){
		return 
			deathmatch
			&&(
				!fraglimit
				||fraglimit>150
				||(
					fraglimit<100
					&&fraglimit>10
				)
			)
		;
	}

	//get the opposite sector of a line
	static sector OppositeSector(line hitline,sector hitsector){
		if(!hitline||!hitline.backsector)return null;
		if(hitline.backsector==hitsector)return hitline.frontsector;
		return hitline.backsector;
	}

	//calculate whether 2 actors are approaching each other
	static bool IsApproaching(actor a1,actor a2){
		vector3 veldif=a1.vel-a2.vel;
		vector3 posdif=a1.pos-a2.pos;
		return (veldif dot posdif)<0;
	}
	//calculate the speed at which 2 actors are moving towards each other
	static double TowardsEachOther(actor a1, actor a2){
		vector3 oldpos1=a1.pos;
		vector3 oldpos2=a2.pos;
		vector3 newpos1=oldpos1+a1.vel;
		vector3 newpos2=oldpos2+a2.vel;
		double l1=(oldpos1-oldpos2).length();
		double l2=(newpos1-newpos2).length();
		return l1-l2;
	}

	//basically so stuff launched up and to the side can go flying backwards
	static vector3 RotateVec3D(
		vector3 startvec,
		double angle,
		double pitch
	){
		if(startvec==(0,0,0))return startvec;

		vector3 endvec=startvec;

		if(startvec.z||pitch){
			vector2 sideways=actor.rotatevector((startvec.x,startvec.z),-pitch);
			endvec.z=sideways.y;
			endvec.x=sideways.x;
		}
		endvec.xy=actor.rotatevector(endvec.xy,angle);

		return endvec;
	}

	//angle between any two vec2s
	static double AngleTo(vector2 v1,vector2 v2,bool absolute=false){
		let diff=absolute?v2-v1:level.Vec2Diff(v1,v2);
		return atan2(diff.y,diff.x);
	}
	//kind of like angleto
	static double PitchTo(vector3 this,vector3 that){
		return atan2(this.z-that.z,(this.xy-that.xy).length());
	}
	//return a string indicating a rough cardinal direction
	static string CardinalDirection(double angle){
		angle=actor.deltaangle(0,angle);
		if(angle>=22&&angle<=66)return("northeast");
		else if(angle>=67&&angle<=113)return("north");
		else if(angle>=114&&angle<=158)return("northwest");
		else if(angle>=159&&angle<=203)return("west");
		else if(angle>=204&&angle<=248)return("southwest");
		else if(angle>=249&&angle<=292)return("south");
		else if(angle>=293&&angle<=338)return("southeast");
		return("east");
	}


	//return a loadout and its name, icon and description, e.g. "Robber: pis, bak~Just grab and run."
	static string,string,string,string GetLoadoutStrings(string input,bool keepspaces=false){
		int pnd=input.indexof("#");
		int col=input.indexof(":");
		int sls=input.indexof("/");

		//"STFEVL0#Voorhees:saw/Chainsaw: Your #1 communicator!"
		if(sls>0){
			if(sls<pnd)pnd=-1;
			if(sls<col)col=-1;
		}

		string pic=""; if(pnd>-1)pic=input.left(pnd);
		string nam=""; if(col>-1)nam=input.left(col);
		string lod=input;
		string desc="";

		if(sls>-1){
			desc=input.mid(sls+1);
			lod.remove(sls,int.Max);
		}

		if(col>-1){
			if(pnd>-1)nam.remove(0,pnd+1);
			lod.remove(0,col+1);
		}else if(pnd>-1)lod.remove(0,pnd+1);

		if(!keepspaces)lod.replace(" ","");
		lod=lod.makelower();

		if(hd_debug>1)console.printf(
			pic.."   "..
			nam.."   "..
			lod.."   "..
			desc
		);
		return lod,nam,pic,desc;
	}

	//basically storing a 5-bit int array in a single 32-bit int.
	//every 32 is a 1 in the second entry, every 32*32 a 1 in the third, etc.
	static int GetFromBase32FakeArray(int input,int slot){
		input=(input>>(5*slot));
		return input&(1|2|4|8|16);
	}

	//get a nice name for any actor
	//mostly for exceptions for players and monsters
	static string GetName(actor named){
		if(named.player)return named.player.getusername();
		string tagname=named.gettag();
		if(tagname!="")return tagname;
		return named.getclassname();
	}

	//check if vector x and y are in range [-dist, dist]
	static bool InXYRange(vector2 vec, double distX, double distY = -1){
		if (distY < 0) distY = distX;
		let x = abs(vec.x);
		let y = abs(vec.y);

		// `<= dist` can be inaccurate due to floating point error
		return (x < distX || x ~== distX) && (y < distY || y ~== distY);
	}

	//when there's too many of these to do unit() all the time
	static vector3 CrudeUnit(vector3 vec){
		return vec/max(abs(vec.x),abs(vec.y),abs(vec.z),0.01);
	}
	static bool Vec3Shorter(vector3 vec,double dist){
		return dist*dist>vec.x*vec.x+vec.y*vec.y+vec.z*vec.z;
	}

	//treat certain damage types as equivalent
	static void ProcessSynonyms(out name mod){
		if(
			mod=="electro"
			||mod=="electricity"
			||mod=="lightning"
			||mod=="bolt"
		)mod="electrical";
		else if(
			mod=="fire"
			||mod=="heat"
			||mod=="plasma"
			||mod=="burning"
			||mod=="thermal"
		)mod="hot";
		else if(
			mod=="ice"
			||mod=="freeze"
			||mod=="cryo"
		)mod="cold";
		else if(
			mod=="hellfire"
			||mod=="unholy"
		)mod="balefire";
		else if(
			mod=="cutting"
			||mod=="lacerating"
		)mod="slashing";
		else if(
			mod=="unholy"
			||mod=="hellfire"
		)mod="balefire";
		else if(
			mod=="stabbing"
		)mod="piercing";
		else if(
			mod=="bite"
			||mod=="fangs"
		)mod="teeth";
		else if(
			mod=="scratch"
			||mod=="nails"
		)mod="claws";
		else if(
			mod=="invisiblebleedout"
		)mod="bleedout";
	}

	//seeing if you're standing on a liquid texture
	static const string lqtex[]={
		"SFLR6_1","SFLR6_4",
		"SFLR7_1","SFLR7_4",
		"FWATER1","FWATER2","FWATER3","FWATER4",
		"BLOOD1","BLOOD2","BLOOD3",
		"SLIME1","SLIME2","SLIME3","SLIME4",
		"SLIME5","SLIME6","SLIME7","SLIME8"
	};
	static bool CheckLiquidTexture(actor caller){
		int lqlength=HDMath.lqtex.size();
		let fp=caller.floorpic;
		for(int i=0;i<lqlength;i++){
			TextureID tx=TexMan.CheckForTexture(HDMath.lqtex[i],TexMan.Type_Flat);
			if (tx&&fp==tx){
				return true;
			}
		}
		return false;
	}
	//seeing if you're standing on a soft dirt texture
	static const string dstex[]={
		"MFLR8_4","MFLR8_2","MFLR8_4"
	};
	static bool CheckDirtTexture(actor caller){
		int lqlength=HDMath.dstex.size();
		let fp=caller.floorpic;
		for(int i=0;i<lqlength;i++){
			TextureID tx=TexMan.CheckForTexture(HDMath.dstex[i],TexMan.Type_Flat);
			if (tx&&fp==tx){
				return true;
			}
		}
		return false;
	}


	//returns a colour code from a given cvar int
	static clearscope string MessageColour(
		actor caller,
		name cvarname,
		playerinfo pl=null
	){
		if(!pl)pl=caller.player;
		if(!pl)return TEXTCOLOR_UNTRANSLATED;
		let ccc=CVar.GetCVar(cvarname,pl);
		int which=ccc.GetInt();
		switch(which){
			case 0: return TEXTCOLOR_BRICK;
			case 1: return TEXTCOLOR_TAN;
			case 2: return TEXTCOLOR_GRAY;
			case 3: return TEXTCOLOR_GREEN;
			case 4: return TEXTCOLOR_BROWN;
			case 5: return TEXTCOLOR_GOLD;
			case 6: return TEXTCOLOR_RED;
			case 7: return TEXTCOLOR_BLUE;
			case 8: return TEXTCOLOR_ORANGE;
			case 9: return TEXTCOLOR_WHITE;
			case 10: return TEXTCOLOR_YELLOW;
			default:
			case 11: return TEXTCOLOR_UNTRANSLATED;
			case 12: return TEXTCOLOR_BLACK;
			case 13: return TEXTCOLOR_LIGHTBLUE;
			case 14: return TEXTCOLOR_CREAM;
			case 15: return TEXTCOLOR_OLIVE;
			case 16: return TEXTCOLOR_DARKGREEN;
			case 17: return TEXTCOLOR_DARKRED;
			case 18: return TEXTCOLOR_DARKBROWN;
			case 19: return TEXTCOLOR_PURPLE;
			case 20: return TEXTCOLOR_DARKGRAY;
			case 21: return TEXTCOLOR_CYAN;
			case 22: return TEXTCOLOR_ICE;
			case 23: return TEXTCOLOR_FIRE;
			case 24: return TEXTCOLOR_SAPPHIRE;
			case 25: return TEXTCOLOR_TEAL;
		}
	}

	// Caligari's variable-substring maker
	// some input example strings:
	// "an empty {beer|soda|wine|champagne} bottle. {It is {cracked|broken|unlabeled}.}"
	// "{an action figure|a doll}. {|||||||||||||It is naked.}");
	// "a {small|large|||} plush {emoji toy|cacodemon|teddy bear|furbie}."
	static string BuildVariableString(string msg){

		// Collapse substrings, repeat until no more { }
		while(true){
			int LeftBrace, RightBrace;
			LeftBrace = msg.RightIndexOf("{"); // find the rightmost {
			RightBrace = msg.IndexOf("}",LeftBrace+1); // find the innermost matching }
			if (LeftBrace == -1 || RightBrace == -1) { break; } // stop looping if no more { }

			string substring = msg.Mid(LeftBrace+1, (RightBrace-LeftBrace)-1); // get the inner text string
			msg.Remove(LeftBrace+1, (RightBrace-LeftBrace)-1); // remove the inside text string

			// build an array of substrings from the extracted string, separated by |
			array<string> substrings;
			substring.Split(substrings,"|"); 

			// pick a random sub-string from the { | | | } set
			// replace the leftover {} with the picked substring
			msg.Replace("{}", substrings[random(0,substrings.Size()-1)]);
		}

		// Remove double-spaces, repeat until no more
		while (true) {
			if (msg.IndexOf("  ", 0) > -1) { msg.Replace("  ", " "); }
			else { break; }
		}

		return msg;
	}

	//find the relative position for the origin point of a projectile
	static vector3 GetGunPos(actor caller){
		let hdp=hdplayerpawn(caller);
		let hdm=hdmobbase(caller);

		if(hdp)return hdp.gunpos;
		if(hdm)return (0,0,hdm.gunheight);

		double defaultheight=32.;
		if(caller.missileheight)defaultheight=caller.missileheight;
		return (0,0,defaultheight);
	}
}
struct HDF play{
	//because this is 10 times faster than A_GiveInventory
	static void Give(actor whom,class<inventory> what,int howmany=1){
		whom.A_SetInventory(what,whom.countinv(what)+howmany);
	}
	//transfer special, args, TID and maybe orientation and velocity
	static void TransferSpecials(actor source,actor dest,int flags=0){
		dest.changetid(source.tid);
		dest.bCountSecret=source.bCountSecret;
		dest.special=source.special;
		for(int i=0;i<5;i++){
			dest.args[i]=source.args[i];
		}
		if(flags&TS_ANGLE){
			dest.angle=source.angle;
			dest.pitch=source.pitch;
		}
		if(flags&TS_VEL)dest.vel=source.vel;
	}
	enum TransferSpecialsFlags{
		TS_ANGLE=1,
		TS_VEL=2,
		TS_ALL=TS_ANGLE|TS_VEL,
	}
	//transfer fire. returns # of fire actors affected.
	static int TransferFire(actor ror,actor ree,int maxfires=-1){
		actoriterator it=level.createactoriterator(-7677,"HDFire");
		actor fff;int counter=0;
		while(maxfires && (fff=it.next())){
			maxfires--;
			if(fff.target==ror){
				counter+=fff.stamina;
				if(ree)fff.target=ree;
				else fff.destroy();
			}
		}
		return counter;
	}
	//figure out if something hit some map geometry that isn't (i.e., "sky").
	//why is GetTexture play!?
	static bool linetracehitsky(flinetracedata llt){
		if(
			(
				llt.hittype==Trace_HitCeiling
				&&llt.hitsector.gettexture(1)==skyflatnum
			)||(
				llt.hittype==Trace_HitFloor
				&&llt.hitsector.gettexture(0)==skyflatnum
			)||(
				!!llt.hitline
				&&llt.hitline.special==Line_Horizon
			)
		)return true;
		if(llt.hittype!=Trace_HitWall)return false;
		let othersector=llt.lineside==line.back?llt.hitline.frontsector:llt.hitline.backsector;
		return(
			!!othersector
			&&(
				(
					othersector.gettexture(othersector.ceiling)==skyflatnum
					&&othersector.ceilingplane.zatpoint(llt.hitdir.xy)<llt.hitlocation.z
				)||(
					othersector.gettexture(othersector.floor)==skyflatnum
					&&othersector.floorplane.zatpoint(llt.hitdir.xy)>llt.hitlocation.z
				)
			)
		);
	}
	static void CheckNoKillCount(){
		if(hd_nokillcount){
			level.total_monsters=0;
			level.killed_monsters=0;
		}
	}

	//a de-shittifying wrapper.
	//lets you set vel/pos/accel with absolute vector3s
	static void Particle(
		actor caller,
		color color,
		vector3 pos,
		int lifetime=35,
		double size=1,
		vector3 vel=(0,0,0),
		bool fullbright=false,
		vector3 accel=(0,0,0),
		double alpha=1,
		double fadestep=-1,
		double sizestep=0
	){
		caller.A_SpawnParticle(
			color,
			fullbright?SPF_FULLBRIGHT:0,
			lifetime,
			size,
			caller.angle,
			pos.x-caller.pos.x,
			pos.y-caller.pos.y,
			pos.z-caller.pos.z,
			vel.x,vel.y,vel.z,
			accel.x,accel.y,accel.z,
			alpha,fadestep,sizestep
		);
	}
}

//reads data that only exists at load time
class HDLoadTimeReader : LevelPostProcessor {
	void Apply(Name checksum, String mapName) {
		Array<Line> polyLines;

		let handler = HDHandlers(EventHandler.Find('HDHandlers'));
		if (!handler) return;

		//cache polyobject lines to save time
		for (int i = 0; i < Level.Lines.Size(); i++) {
			let lspec = Level.Lines[i].special;
			if (lspec == Polyobj_StartLine || lspec == Polyobj_ExplicitLine) {
				Line ln = Level.Lines[i];
				polyLines.Push(ln);
			}
		}

		int highestTag;
		Array<HDPolyObjectInfo> pendingMirror;
		for (uint thing = 0; thing < GetThingCount(); thing++) {
			//for each polyobject start spot...
			let thingType = GetThingEdNum(thing);
			if (thingType < PolyStartSafe || thingType > PolyStartHurt) continue;

			let tag = GetThingAngle(thing);
			highestTag = max(highestTag, tag);

			//find matching polyobject anchor
			int anchorThing = -1;
			for (uint anchor = 0; anchor < GetThingCount(); anchor++) {
				if (GetThingEdNum(anchor) == PolyAnchor && GetThingAngle(anchor) == tag) {
					anchorThing = anchor;
					break;
				}
			}

			//skip anchorless polyobjects
			if (anchorThing < 0) continue;

			//create a polyobject info entry
			let entry = HDPolyObjectInfo.Create(polyLines, GetThingAngle(thing), GetThingPos(anchorThing));
			if (!entry) continue;

			if (!entry.tag && entry.mirrorTag >= 0) {
				HDPolyObjectInfo mirrorEntry;
				if (entry.mirrorTag < handler.polyobjects.Size() && (mirrorEntry = handler.polyobjects[entry.mirrorTag]))
					mirrorEntry.mirrorTag = entry.tag;
				else pendingMirror.Push(entry);
			} else if (entry.tag && entry.mirrorTag < 0) {
				for (int i = 0; i < pendingMirror.Size(); i++) {
					if (pendingMirror[i].mirrorTag == entry.tag) {
						entry.mirrorTag = pendingMirror[i].tag;
						pendingMirror.Delete(i);
						break;
					}
				}
			}

			handler.polyobjects.Resize(highestTag + 1);
			handler.polyobjects[tag] = entry;
		}

	}

	//polyobject map spot ednums
	enum PolyObjMapSpots {
		PolyAnchor = 9300,
		PolyStartSafe,
		PolyStartCrush,
		PolyStartHurt
	}
}

extend class HDHandlers {
	//list of polyobjects by tag
	Array<HDPolyObjectInfo> polyobjects;

	//find the polyobject checkLine belongs to
	HDPolyObjectInfo FindPolyByLine(Line checkLine) {
		for (int i = 0; i < polyobjects.Size(); i++)
			if (polyobjects[i] && polyobjects[i].lines.Find(checkLine) != polyobjects[i].lines.Size())
				return polyobjects[i];

		return null;
	}
}

class HDPolyObjectInfo {
	//the lines belonging to this polyobject
	Array<Line> lines;
	//the offset between the polyobject and its first line's first vertex
	vector2 offset;
	//the starting angle of the first line
	double startAngle;

	int mirrorTag;
	int tag;

	double GetAngle() const {
		let delta = lines[0].delta;
		return VectorAngle(delta.x, delta.y);
	}

	vector2 GetPos() const {
		return lines[0].v1.p - Actor.RotateVector(offset, GetAngle() - startAngle);
	}

	HDPolyObjectInfo GetMirrorPoly() const {
		let handler = HDHandlers(EventHandler.Find('HDHandlers'));
		if (!handler || mirrorTag < 0) return null;

		return handler.polyobjects[mirrorTag];
	}

	static play HDPolyObjectInfo Create(Array<Line> polyLines, int tag, vector3 pos) {
		let this = new('HDPolyObjectInfo');

		this.tag = tag;

		this.FindLines(polyLines);
		if (this.mirrorTag == 0) this.mirrorTag = -1;
		if (this.lines.Size() > 0) {
			let ln = this.lines[0];
			this.offset = ln.v1.p - pos.xy;
			this.startAngle = VectorAngle(ln.delta.x, ln.delta.y);
		}
		else this.Destroy();

		return this;
	}

	play void FindLines(Array<Line> polyLines) {
		//find polyobject start lines
		for (int i = 0; i < polyLines.Size(); i++) {
			let ln = polyLines[i];
			if (ln.Special == Polyobj_StartLine && ln.args[0] == tag) {
				mirrorTag = ln.args[1];

				validcount++;
				IterFindLines(ln, false, ln);

				return;
			}
		}

		//didn't find a start line, look for explicit lines instead
		for (int i = 0; i < polyLines.Size(); i++) {
			let ln = polyLines[i];
			if (ln.Special == Polyobj_ExplicitLine && ln.args[0] == tag)
				lines.Push(ln);
		}

		if (lines.Size() > 0) {
			let mirror = lines[0].args[2];
			if (mirror) mirrorTag = mirror;
		}
	}

	// TODO: use the adjacent line algorithm from gzdoom
	play bool IterFindLines(Line curLine, bool reversed, Line checkLine) {
		let vert = reversed? curLine.v2 : curLine.v1;

		for (int i = 0; i < Level.Lines.Size(); i++) {
			Line ln = Level.Lines[i];

			if (ln.v1 != vert && ln.v2 != vert) continue;
			if (ln.validcount == validcount) continue;
			if (ln == curLine) continue;
			ln.validcount = validcount;

			if (ln == checkLine || IterFindLines(ln, ln.v1 == vert, checkLine)) {
				lines.Push(ln);
				return true;
			}
		}

		return false;
	}
}





//debug thingy
class HDCheatWep:HDWeapon{
	default{
		+inventory.undroppable
		-weapon.no_auto_switch
		+weapon.cheatnotweapon
		+hdweapon.debugonly
		+nointeraction
	}
}
class HDRaiseWep:HDCheatWep{
	default{
		weapon.slotnumber 0;
		hdweapon.refid "rvv";
		tag "monster reviver (cheat!)";
	}
	states{
	ready:
		TNT1 A 1 A_WeaponReady();
		goto readyend;
	fire:
		TNT1 A 0{
			flinetracedata rlt;
			LineTrace(
				angle,128,pitch,
				TRF_ALLACTORS,
				offsetz:height-6,
				data:rlt
			);
			if(rlt.hitactor){
				a_weaponmessage(rlt.hitactor.getclassname().." raised!",30);
				RaiseActor(rlt.hitactor,RF_NOCHECKPOSITION);
			}else a_weaponmessage("click on something\nto raise it.",25);
		}goto nope;
	}
}



//thing that can be spawned to replace a crusher/bossbrain kill script
class NextMap:Actor{
	states{
	spawn:
		TNT1 A 0;
		TNT1 A 35{
			for(int i=0;i<MAXPLAYERS;i++){
				let pmo=players[i].mo;
				if(pmo)pmo.damagemobj(pmo,pmo,TELEFRAG_DAMAGE,"none",DMG_FORCED);
			}
		}
		TNT1 A 1 Exit_Normal(0);
		stop;
	}
}



