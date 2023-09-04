// ------------------------------------------------------------
// Death and corpses
// ------------------------------------------------------------
extend class HDPlayerPawn{
	bool silentdeath;
	states{
	death.bleedout:
	death.internal:
		---- A 0{
			if(playercorpse)playercorpse.A_StopSound(CHAN_VOICE);
			A_StopSound(CHAN_VOICE);
		}
	death:
	xdeath:
		---- A 50{
			binvisible=true;
			A_NoBlocking();
		}
		---- A 20 A_CheckPlayerDone();
		wait;
	}
	int deathcounter;
	int respawndelay;
	override void DeathThink(){
		if(player.cheats&CF_PREDICTING){
			super.DeathThink();
			return;
		}

		if(player){
			if(
				respawndelay>0
			){
				if(!hd_disintegrator)player.attacker=null;
				player.cmd.buttons&=~BT_USE;
				if(!(level.time&(1|2|4|8|16))){
					switch(CheckPoF()){
					case -1:
						//start losing sequence
						let hhh=hdlivescounter.get();
						if(hhh.endgametypecounter<-35)hhh.startendgameticker(hdlivescounter.HDEND_WIPE);
						break;
					case 1:
						respawndelay--;
						A_Log(player.getusername().." friend wait time: "..respawndelay);
						break;
					default:
						respawndelay=HDCONST_POFDELAY;
						break;
					}
				}
			}else if(hd_pof){
				player.cmd.buttons|=BT_USE;
			}

			//always get corpsepos in case someone sets PoF midgame
			let hhh=hdhandlers(eventhandler.find("hdhandlers"));
			hhh.corpsepos[playernumber()]=(pos.xy,floor(pos.z)+0.001*angle);

			if(
				deathcounter==144
				&&!(player.cmd.buttons&BT_USE)
			){
				if(!player.bot){
					showgametip();
					if(!hd_pof)specialtip=specialtip.."\n\n\clPress \cdUse\cl to continue.";
				}
				deathcounter=145;
			}else if(
				deathcounter<144
				&&player
			){
				player.cmd.buttons&=~BT_USE;
				deathcounter++;
			}
			if(playercorpse){
				setorigin((playercorpse.pos.xy+angletovector(angle)*3,playercorpse.pos.z),true);
			}
		}

		if(hd_dropeverythingondeath){
			array<inventory> keys;keys.clear();
			for(inventory item=inv;item!=null;item=item.inv){
				if(item is "Key"){
					keys.push(item);
					item.detachfromowner();
				}else if(item is "HDPickup"||item is "HDWeapon"){
					DropInventory(item);
				}
				if(!item||item.owner!=self)item=inv;
			}
			for(int i=0;i<keys.size();i++){
				keys[i].attachtoowner(self);
			}
		}


		viewbob=0;

		double oldangle=angle;
		double oldpitch=pitch;
		super.DeathThink();

		vel=(0,0,0);

		if(hd_disintegrator){
			setz(ceilingz-height);
			if(
				!player.attacker
				||player.attacker.health<1
			){
				player.attacker=null;
				pitch=oldpitch;
			}else{
				vector3 ap=player.attacker.pos;
				A_SetPitch(HDMath.PitchTo(pos,(ap.xy,ap.z+player.attacker.height)),SPF_INTERPOLATE);
			}
			return;
		}

		angle=oldangle;
		A_SetPitch(min(oldpitch+1,45),SPF_INTERPOLATE);

		if(
			!!viewpos
			&&deathcounter<80
		)setviewpos((viewpos.offset.xy+0.02*(80-deathcounter)*heightmult*(cos(angle),sin(angle)),0));
	}
	override void Die(actor source,actor inflictor,int dmgflags,name MeansOfDeath){

		//forced delay for respawn to clear all persistent damagers
		//exemption made for suicide
		if(
			(source==self&&health<-50000)
			||(
				!multiplayer&&!level.allowrespawn
			)
		)deathcounter=145;
		else deathcounter=1;

		bool dogib=
				(
					!inflictor
					||!inflictor.bnoextremedeath
				)&&(
					-health>gibhealth
					||aggravateddamage>40
				)
		;


		if(hd_disintegrator)AddBlackout(256,256,4,16);
		else if(dogib)AddBlackout(256,72,4,70);
		else AddBlackout(256,12,4,24);


		if(hd_pof){
			if(deathmatch){
				cvar.findcvar("hd_pof").setbool(false);
				respawndelay=0;
			}else respawndelay=HDCONST_POFDELAY;
		}else respawndelay=0;


		if(player){
			let www=hdweapon(player.readyweapon);
			if(www)www.OnPlayerDrop();
			if(player.attacker is "HDFire")player.attacker=player.attacker.master;
		}

		playercorpse=HDPlayerCorpse(spawn("HDPlayerCorpse",pos,ALLOW_REPLACE));
		playercorpse.vel=vel;playercorpse.corpsegiver=self;
		if(player)playercorpse.settag(player.getusername());

		playercorpse.translation=translation;
		ApplyUserSkin(true);
		playercorpse.sprite=sprite;
		playercorpse.standsprite=standsprite;
		playercorpse.scale=skinscale;
		playercorpse.master=self;


		if(hd_disintegrator){
			playercorpse.bodydamage=0;
			playercorpse.bshootable=0;
			playercorpse.setstatelabel("deathdisintegrate");
			if(!silentdeath)A_StartSound(deathsound,CHAN_VOICE);
		}else{
			if(dogib){
				playercorpse.bodydamage+=max(-health,aggravateddamage<<2);
			}else{
				if(!silentdeath)A_StartSound(deathsound,CHAN_VOICE);
			}

			//transfer heat to corpse
			let htht=Heat(findinventory("Heat"));
			if(htht){
				playercorpse.A_GiveInventory("Heat",1);
				Heat(playercorpse.findinventory("Heat")).realamount+=htht.realamount;
				htht.destroy();
			}
		}

		if(
			hd_voicepitch
			&&minvpitch>0
			&&maxvpitch>0
		)playercorpse.A_SoundPitch(CHAN_VOICE,clamp(hd_voicepitch.getfloat(),minvpitch,maxvpitch));

		bsolid=false;
		bshootable=false;
		bnointeraction=true;

		double vheight=height*0.9;

		super.die(source,inflictor,dmgflags,MeansOfDeath);

		player.viewheight=vheight;
	}
	//-1 if tpk
	//0 if not gathered
	//1 if gathered
	int CheckPoF(){
		if(!hd_pof)return 1;
		bool everyonedead=true;
		bool someoneoutside=false;
		for(int i=0;i<MAXPLAYERS;i++){
			if(!playeringame[i])continue;
			let ppp=players[i].mo;
			if(
				ppp
				&&ppp.health>0
			){
				everyonedead=false;
				if(
					!checksight(ppp, SF_IGNOREVISIBILITY)
					||distance3d(ppp)>256
				){
					someoneoutside=true;
					break;
				}
			}
		}
		if(everyonedead)return -1;
		if(someoneoutside)return 0;
		return 1;
	}
	void healthreset(){
		hdbleedingwound.clearall(self);
		oldwoundcount=0;
		burncount=0;
		aggravateddamage=0;
		stunned=0;
		bloodloss=0;
	}
}

enum HDPlayerDeath{
	HDCONST_POFDELAY=11,
}



//call the lives counter thinker when someone dies
extend class HDHandlers{
	override void PlayerDied(PlayerEvent e){
		hdlivescounter.playerdied(e.playernumber);
	}
}


//corpse substituter
class HDPlayerCorpse:HDHumanoid{
	hdplayerpawn corpsegiver;
	int standsprite;
	default{
		-countkill +friendly +nopain +activatepcross
		+masternosee
		health 100;mass 160;
	}
	override bool CanResurrect(actor other,bool passive){
		if(hd_pof)return false;
		return super.CanResurrect(other,passive);
	}
	override void Tick(){
		super.Tick();
		if(
			hd_pof
			&&(
				!corpsegiver
				||corpsegiver.health>0
			)
		){
			destroy();
			return;
		}
		if(
			corpsegiver
			&&corpsegiver.health>0
			&&!hd_pof
		){
			bmasternosee=false;
			corpsegiver.playercorpse=null;
			corpsegiver.healthreset();
			corpsegiver.levelreset();
			corpsegiver=null;
		}
		if(
			health>0
			&&!instatesequence(curstate,resolvestate("raise"))
			&&!instatesequence(curstate,resolvestate("ungib"))
		)A_Die();
	}
	states{
	spawn:
		#### AA -1;
		PLAY A 0;
	forcexdeath:
		#### A -1;
	deathdisintegrate:
		#### H 0{
			bsolid=false;
			bshootable=false;
			bodydamage=0;
			A_NoBlocking();
			A_SetRenderStyle(1.,STYLE_Add);
		}
		---- A 1 bright{
			for(int i=0;i<3;i++)HDF.Particle(self,"ff fa 99",
				pos+(frandom(-radius,radius),frandom(-radius,radius),frandom(0,liveheight)),
				16,
				20*alpha,
				vel+(frandom(-4,4),frandom(-4,4),frandom(-1,4)),
				fullbright:true
			);
			A_FadeOut(0.05);
		}
		wait;
	death:
		#### H 0 A_JumpIf(hd_disintegrator,"deathdisintegrate");
		#### H 10 A_JumpIf(
			!!corpsegiver
			&&corpsegiver.incapacitated>(4<<2)
		,"dead");
		#### IJ 8;
		#### K 3;
	deadfall:
		#### K 2;
		#### LM 4 A_JumpIf(abs(vel.z)>1,"deadfall");
	dead:
		#### M 1; //used for bleeding out
		#### N 2 canraise{
			if(abs(vel.z)>2)setstatelabel("deadfall");
			if(hdmath.deathmatchclutter())damagemobj(null,null,10,"maxhpdrain",flags:DMG_NO_ARMOR);
		}
		wait;
	xdeath:
		#### O 0 A_JumpIf(hd_disintegrator,"deathdisintegrate");
		#### O 5{
			if(corpsegiver)A_StartSound(corpsegiver.gibbedsound,CHAN_BODY,CHANF_OVERLAP);
			else A_XScream();
			scale.x=abs(scale.x);
		}
		#### OPQRSTUV 5;
	xdead:
		#### W 0 A_JumpIf(hdmath.deathmatchclutter(),"xdeadfade");
		#### W 10 A_JumpIf(!hd_pof,1);
		wait;
		#### W -1 canraise;
		stop;
	xdeadfade:
		#### W 10 A_FadeOut(0.1);
		wait;
	xxxdeath:
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		goto xdead;
	ungib:
		---- A 0{
			let aaa=HDOperator(spawn("ReallyDeadRifleman",pos));
			RaiseActor(aaa,RF_NOCHECKPOSITION);
			aaa.settag(gettag());
			aaa.angle=angle;
			aaa.translation=translation;
			aaa.master=master;
			aaa.target=target;
			aaa.sprite=standsprite;
			aaa.givensprite=sprite;
			aaa.A_SetFriendly(bfriendly);
			aaa.scale=scale;
			bnotargetswitch=false;
		}
		stop;
	raise:
		#### MLKJIH 5;
		---- A 0{
			let aaa=HDOperator(spawn("UndeadRifleman",pos));
			aaa.settag(gettag());
			aaa.angle=angle;
			aaa.translation=translation;
			aaa.master=master;
			aaa.target=target;
			aaa.sprite=standsprite;
			aaa.givensprite=sprite;
			aaa.A_SetFriendly(bfriendly);
			aaa.scale=scale;
		}
	falldown:
		stop;
	}
}

