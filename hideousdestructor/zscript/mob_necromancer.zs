// ------------------------------------------------------------
// Necromancer
// ------------------------------------------------------------
class NecromancerGhost:Thinker{
	int targetplayer;
	int ticker;
	bool bfriendly;
	actor ghoster;
	static void Init(actor caller,int time=-1){
		let nnn=new("NecromancerGhost");
		nnn.bfriendly=caller.bfriendly;
		nnn.targetplayer=caller.friendplayer-1;
		nnn.ghoster=caller;
		if(time<0)nnn.ticker=TICRATE*random(60,600);
	}
	override void tick(){
		if(ticker>0){
			ticker--;
			return;
		}
		if(level.time&(1|2|4|8|16))return;

		if(!multiplayer)targetplayer=0;
		else if(
			targetplayer<0
			||targetplayer>=MAXPLAYERS
			||hdspectator(players[targetplayer].mo)
			||!hdplayerpawn(players[targetplayer].mo)
		){
			array<int> pcs;pcs.clear();
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					hdplayerpawn(players[i].mo)
					&&!hdspectator(players[i].mo)
				)pcs.push(i);
			}targetplayer=pcs[random(0,pcs.size()-1)];
		}

		actor pmo=players[targetplayer].mo;
		if(
			!ticker
			||!random(0,40)
		){
			pmo.A_StartSound("vile/curse",420,CHANF_UI|CHANF_NOPAUSE|CHANF_LOCAL);
			if(!ticker){
				ticker--;
				return;
			}
		}

		if(!random(0,7)){
			actor aaa;
			blockthingsiterator it=blockthingsiterator.create(pmo,HDCONST_ONEMETRE*5);
			while(it.next()){
				aaa=it.thing;
				if(
					aaa.bcorpse
					&&aaa.findstate("raise")
				){
					HDRaiser.Init(aaa,ghoster,random(35,200),bfriendly);
					ticker--;
				}
			}
			if(ticker<-100)destroy();
		}
	}
}
class HDRaiser:Thinker{
	actor corpse,raiser;
	int ticker,friendplayer;
	bool friendly;
	static HDRaiser Init(
		actor cps,
		actor rsr,
		int time,
		bool friendly
	){
		let hdr=HDRaiser(new("HDRaiser"));
		hdr.corpse=cps;
		hdr.raiser=rsr;
		hdr.ticker=time;
		hdr.friendly=friendly;
		return hdr;
	}
	override void Tick(){
		if(!corpse||corpse.health>0){destroy();return;}
		if(ticker>0)ticker--;
		else{
			if(!!raiser){
				corpse.target=raiser.target;
				corpse.master=raiser;
				if(
					friendly
					&&raiser.player
				)corpse.friendplayer=raiser.playernumber()+1;
			}
			corpse.RaiseActor(corpse,RF_NOCHECKPOSITION);
			corpse.bfriendly=friendly;
			destroy();
		}
	}
}
class NecromancerFlame:HDActor{
	default{
		+nointeraction
		+bright
		renderstyle "add";
		height 0;radius 0;
	}
	override void tick(){
		super.tick();
		let trc=tracer;
		if(!trc)return;
		if(!trc){
			if(!isfrozen())A_FadeOut(0.05);
			return;
		}
		if(trc.isfrozen())return;
		double trd=trc.radius*0.6;
		vector3 npos=trc.pos
			+(
				frandom(-trd,trd),
				frandom(-trd,trd),
				frandom(0.1,trc.height*0.6)
			);
		npos.xy+=(target.pos.xy-trc.pos.xy).unit()*frandom(0,trd);
		setorigin(npos,true);
		scale.y=frandom(0.9,1.1);
		scale.x=frandom(0.9,1.1);
		if(!(level.time&1))scale.x=-scale.x;
	}
	void A_BurnTracer(){
		let trc=tracer;
		if(!trc)return;

		if(
			!target
			||target.bcorpse
			||!checksight(target)
			||absangle(target.angle,target.angleto(trc))>40
		){
			setstatelabel("death");
			return;
		}

		trc.damagemobj(self,target,4,"hot");
		A_Immolate(trc,target,4);
		trc.vel.xy+=(trc.pos.xy-pos.xy).unit()*0.1;
		if(trc.pos.z-trc.floorz<HDCONST_ONEMETRE*2.)trc.vel.z+=(HDCONST_GRAVITY*1.4)*tics;
	}
	states{
	spawn:
		FIRE A 2 light("HELL");
		FIRE B 2 A_StartSound("vile/firecrkl",CHAN_VOICE);
		FIRE ABABCDCDEDEF 2 light("HELL");
		FIRE GHGHGHGH 3 light("HELL") A_BurnTracer();
	death:
		FIRE FGFGH 2 light("HELL");
		FIRE GHFGHGHGH 2 A_FadeOut(0.12);
		stop;
	}
}
class Necromancer:HDMobBase replaces ArchVile{
	override void postbeginplay(){
		super.postbeginplay();

		//spawn shards instead if no archvile sprites
		if(Wads.CheckNumForName("VILER0",wads.ns_sprites,-1,false)<0){
			for(int i=0;i<99;i++){
				actor vvv;
				[bmissilemore,vvv]=A_SpawnItemEx("BFGNecroShard",
					frandom(-3,3),frandom(-3,3),frandom(1,6),
					frandom(0,30),0,frandom(1,12),frandom(0,360),
					SXF_SETMASTER|SXF_TRANSFERPOINTERS|SXF_ABSOLUTEPOSITION
				);
				vvv.A_SetFriendly(bfriendly);
			}
			A_AlertMonsters();
			destroy();
			return;
		}

		bsmallhead=bplayingid;
		resize(0.6,0.8);
		voicepitch=frandom(0.3,1.7);
		settag(RandomName());

		lastshieldcount=countinv("HDMagicShield");
	}
	void A_NecromancerFlame(){
		let tgt=target;
		if(
			tgt
			&&absangle(angle,angleto(tgt))<60
			&&checksight(tgt)
		){
			double rd=tgt.radius*0.6;
			let fff=NecromancerFlame(spawn("NecromancerFlame",
				tgt.pos+(frandom(-rd,rd),frandom(-rd,rd),frandom(0,tgt.height*0.3))
			));
			if(fff){
				fff.scale.x=randompick(-1,1)*frandom(0.9,1.1);
				fff.scale.y=frandom(0.8,1.1);
				fff.target=self;
				fff.tracer=tgt;
			}
			HDBleedingWound.findandpatch(self,10,HDBW_FINDPATCHED);
		}
	}
	void A_NecromancerWarp(){
		if(random(0,3))return;
		spawn("TeleFog",pos);
		bfrightened=true;
		speed*=5;
		maxstepheight*=5;
		maxdropoffheight*=5;
		bsolid=false;
		bnogravity=true;
		bfloat=true;
		bdontinterpolate=true;

		for(int i=0;i<10;i++)A_Chase(null,null);

		HealNearbyCorpse(meleerange);
		HDBleedingWound.findandpatch(self,5,HDBW_FINDPATCHED);

		spawn("TeleFog",pos);
		bfrightened=false;
		speed*=0.2;
		maxstepheight*=0.2;
		maxdropoffheight*=0.2;
		bsolid=true;
		bnogravity=false;
		bfloat=false;
		bdontinterpolate=false;
	}
	override actor HealNearbyCorpse(double healradius){
		let ccc=super.HealNearbyCorpse(meleerange);
		if(!ccc)return null;
		let hdt=HDMobBase(ccc);
		if(hdt){
			hdt.bodydamage>>=5;
			hdt.stunned>>=5;
		}
		int hhh=200-ccc.health;
		if(hhh>0)SetInventory("HDMagicShield",countinv("HDMagicShield")+hhh);
		return ccc;
	}
	override void A_HDChase(
		statelabel meleestate,
		statelabel missilestate,
		int flags,
		double speedmult
	){
		if(
			!HealNearbyCorpse(meleerange)
		)super.A_HDChase(meleestate,missilestate,flags,speedmult);

		if(
			!instatesequence(curstate,resolvestate("heal"))
			&&!random(0,63)
		)A_NecromancerWarp();
	}
	override void CheckFootStepSound(){
		if(
			(
				frame==0
				||frame==3
			)
			&&frame!=curstate.nextstate.frame
		){
			if(HDMath.CheckLiquidTexture(self))A_StartSound("humanoid/squishstep",88,CHANF_OVERLAP,volume:0.2);
			else A_StartSound("imp/step",88,CHANF_OVERLAP,
				volume:(HDMath.CheckDirtTexture(self)?0.1:0.2)
			);
		}
	}
	override void Tick(){
		super.Tick();
		if(isfrozen()||health<1)return;
		if(stunned>100)stunned-=20;
		if(!bplayingid&&(
			(
				frame>=26
				&&frame<=28
			)||(
				frame>5
				&&frame<16
			)
		))ZapArc(self,flags:ARC2_SILENT,radius:radius*4,height:height*1.4);
		if(!(level.time&(1|2))){
			if(bodydamage>0)bodydamage--;
			givebody(1);
		}
	}
	default{
		mass 200;
		maxtargetrange 896;
		seesound "vile/sight";
		painsound "vile/pain";
		deathsound "vile/death";
		activesound "vile/active";
		meleesound "vile/stop";
		obituary "$OB_NECROMANCER";
		tag "$CC_ARCH";

		+avoidmelee
		+notarget
		+hdmobbase.chasealert
		+hdmobbase.biped
		+hdmobbase.climber

		radius 16;
		height 56;
		meleerange 64;
		maxstepheight 28;maxdropoffheight 64;
		painchance 42;
		scale 0.8;
		speed 24;
		health 400;
		hdmobbase.shields 1800;
		damagefactor "hot",0.66;
	}
	int lastshieldcount;
	states{
	spawn:
		VILE CD 10 A_HDLook();
		VILE A 0 A_Jump(16,"spwander");
		loop;
	spwander:
		VILE ABCDEF 6 A_HDWander(CHF_LOOK);
		VILE A 0 A_Jump(8,"spawn");
		loop;
	see:
		VILE ABCDEF 3 A_HDChase();
		loop;
	missile:
		VILE A 0 A_Jump(164,2);
		VILE A 0 A_Vocalize(seesound,painsound,deathsound);
		VILE A 0 HealNearbyCorpse(meleerange);
		VILE ABCDEF 3 A_FaceTarget(10,10);
		VILE FG 3 A_FaceTarget(5,5);
		VILE G 3{
			A_FaceTarget(5,5);
			A_StartSound("vile/firestrt",CHAN_WEAPON,CHANF_OVERLAP);
			if(
				target
				&&absangle(angle,angleto(target))<60
				&&checksight(target)
			)target.A_StartSound("vile/firestrt",CHAN_BODY,CHANF_OVERLAP);
		}
		VILE GGHHII 3 bright light("HELL") A_FaceTarget(5,5);
		VILE J 0 A_NecromancerFlame();
		VILE JJJKKKLLL 3 bright light("HELL") A_FaceTarget(5,5);
	missileend:
		VILE L 0 A_StartSound("vile/firestrt",CHAN_WEAPON,CHANF_OVERLAP);
		VILE MMNNOOPP 3 bright light("HELL");
		goto see;
	heal:
		VILE A 0 A_Jump(164,2);
		VILE A 0 A_Vocalize(randompick(activesound,seesound));
		VILE "[\]" 12 bright light("HEAL");
		goto see;
	pain:
		VILE Q 5{
			int shields=countinv("HDMagicShield");
			if(
				lastshieldcount-shields>500
				||!random(0,3)
			)A_NecromancerWarp();
			lastshieldcount=shields;
		}
		VILE Q 5{
			if(target)threat=target;
			A_Vocalize(painsound);
			A_ShoutAlert(0.4,SAF_SILENT);
		}
		goto see;
	xdeath:
		VILE Q 0 A_JumpIf(bplayingid,"idxdeath");
	death:
		VILE Q 0 A_JumpIf(bplayingid,"iddeath");
		VILE QR 6;
		VILE S 5 A_Vocalize(deathsound);
		VILE TUVWXY 4;
		VILE Z 35;
		VILE Z -1{NecromancerGhost.Init(self);}
		stop;


	//id archvile death sequence
	iddeath:
		VILE Q 42 bright{
			A_SetSize(radius,liveheight);
			A_Vocalize(painsound);
			A_UnsetShootable();
			A_FaceTarget();
			accuracy=24;
		}
		VILE Q 0 A_Quake(2,40,0,768,0);
		VILE Q 0 A_SpawnVileDebris(3);
	flicker:
		VILE G 1 bright light("HELL"){
			A_SetRenderStyle(0.8,STYLE_Add);
			A_SetTics((accuracy>>3)+random(0,2));
			if(!random(0,accuracy))A_Vocalize(painsound);
		}
		VILE G 1{
			A_SetRenderStyle(0.4,STYLE_Add);
			A_SetTics((accuracy>>2)+random(0,2));
			accuracy--;
			if(accuracy==20)A_Quake(4,40,0,768,0);
			if(accuracy<1)setstatelabel("flickerend");
		}
		loop;
	flickerend:
		VILE G 0 A_SetRenderStyle(1.,STYLE_Add);
		VILE Q 0 A_Quake(6,8,0,768,0);
		VILE GGG 2 bright light("HELL")A_Vocalize(painsound);
	idxdeath:
		VILE Q 6 bright light("HELL"){
			A_SetSize(radius,liveheight);
			A_Vocalize(painsound);
			A_UnsetShootable();
			A_FaceTarget();

			A_Explode(72,196);
			A_StartSound("weapons/rocklx",CHAN_WEAPON);
			A_SpawnItemEx("NecroDeathLight",flags:SXF_SETTARGET);
			A_Vocalize(deathsound);
			DistantNoise.Make(self,"world/rocketfar",2.);
			A_SpawnVileDebris(3);
		}
		VILE Q 14 bright light("HELL") A_Quake(8,14,0,768,0);
		VILE Q 0 A_SpawnVileDebris();
		VILE Q 2 A_Quake(3,26,0,1024,0);
		VILE Q 2 bright{
			if(
				alpha>0.8
				&&frandom(0,1)>alpha
			)A_SpawnVileDebris();
			else if(frandom(0,1)<alpha)A_SpawnVileDebris(
				1,
				"BossShard",
				1.,
				(angletovector(angle+frandom(135,225),frandom(0.01,0.1)),frandom(0,1))
			);
			A_FadeOut(alpha*0.02);
			if(alpha<0.01){
				NecromancerGhost.Init(self);
				destroy();
			}
		}
		wait;
	}
	void A_SpawnVileDebris(
		int amt=1,
		class<actor> type="VileDeathFire",
		double maxheight=0.6,
		vector3 startvel=(0,0,0)
	){
		double minheight=pos.z;
		maxheight=pos.z+liveheight*maxheight;
		for(int i=0;i<amt;i++){
			actor vdf=spawn(type,(
				pos.xy+(frandom(-radius,radius),frandom(-radius,radius)),
				frandom(minheight,maxheight)
			),ALLOW_REPLACE);
			if(vdf){
				vdf.target=self;
				vdf.vel=startvel;
			}
		}
	}
}

//these two actors are only used by the id archvile.
class VileDeathFire:Actor{
	default{
		+bright
		+nointeraction
		renderstyle "add";
	}
	override void postbeginplay(){
		super.postbeginplay();
		vel.z+=frandom(0.1,2.);
		scale.x=frandom(0.6,1.);
		scale.y=frandom(0.8,1.5);
		if(!random(0,1))scale.x=-scale.x;
	}
	states{
	spawn:
		FIRE ABABCDCDEFEFGHGH 2 A_FadeOut(0.05);
		wait;
	}
}
class NecroDeathLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=255;
		args[1]=200;
		args[2]=100;
		args[3]=256;
		args[4]=0;
	}
	override void tick(){
		if(isfrozen())return;
		if(!target||target.bnointeraction){destroy();return;}
		args[3]=int(target.alpha*randompick(1,3,7)*frandom(12,16));
		setorigin(target.pos,true);
	}
}

class GhostlyNecromancer:Necromancer{
	default{
		+noclip
		+floorhugger
		+friendly
		+noblood
		+noblockmonst
		-solid
		-shootable
		renderstyle "add";
		translation "0:255=%[0,0,0]:[0.3,0.7,0.1]";
		speed 10;
	}
	override void CheckFootStepSound(){}
	override void tick(){
		super.tick();
		if(isfrozen())return;

		if(!level.ispointinlevel(pos)){
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					players[i].mo
					&&players[i].mo.health>0
				){
					movepos=players[i].mo.pos;
					break;
				}
			}
			return;
		}

		if(frame>5)alpha=min(alpha+0.1,frandom(0.95,1.));
		else alpha=min(alpha+frandom(!!target?-0.099:-0.101,0.1),0.8);

		if(!(level.time&(1|2|4))){
			A_Trail();
		}

		if(alpha<-1.){
			string msg[]={
				StringTable.Localize("$Necromancer1"),
				StringTable.Localize("$Necromancer2"),
				StringTable.Localize("$Necromancer3"),
				StringTable.Localize("$Necromancer4"),
				StringTable.Localize("$Necromancer5"),
				StringTable.Localize("$Necromancer6"),
				StringTable.Localize("$Necromancer7"),
				StringTable.Localize("$Necromancer8"),
				StringTable.Localize("$Necromancer9"),
				StringTable.Localize("$NecromancerA"),
				StringTable.Localize("$NecromancerB"),
				StringTable.Localize("$NecromancerC")
			};
			for(int i=0;i<MAXPLAYERS;i++){
				if(players[i].mo)players[i].mo.A_StartSound("misc/chat",420,CHANF_UI|CHANF_NOPAUSE|CHANF_LOCAL);
			}
			console.printf("\cd"..gettag()..": "..msg[random(0,random(0,msg.size()-1))]);
			destroy();
		}
	}
}

