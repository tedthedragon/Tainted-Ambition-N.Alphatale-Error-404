// ------------------------------------------------------------
// Respawn, including bot replacements and endgame
// ------------------------------------------------------------
extend class HDPlayerPawn{
	void ReplaceBot(){
		BotBot bb=BotBot(spawn("BotBot",pos));
		if(!bb)return;
		bb.translation=translation;
		bb.bfriendly=true;
		bb.master=self;
		bb.friendplayer=playernumber()+1;

		setz(pos.z+50);
		A_Log(string.format("Bot %s replaced with rifleman.",player.getusername()));
		A_Morph("HDBotSpectator",int.MAX,MRF_FULLHEALTH,"CheckPuff","CheckPuff");
	}


	override void GiveDefaultInventory(){
		super.GiveDefaultInventory();

		//because when called on map this usually implies resetting other stuff
		//would be nice to make this conditional on the level change actually resetting health, but oh well
		healthreset();
	}
}


//respawn event
extend class HDHandlers{
	vector3 corpsepos[MAXPLAYERS];
	override void PlayerRespawned(PlayerEvent e){
		let hde=HDPlayerPawn(players[e.playernumber].mo);
		if(!hde)return;

		//revived with the Power of Friendship
		if(hd_pof){
			hde.incaptimer=140;
			hde.incapacitated=20;
			hde.damagemobj(null,null,hde.health-10,"maxhpdrain",DMG_FORCED);
			hde.stunned=700;
			hde.bloodloss=500;
			hde.setorigin(corpsepos[e.playernumber],false);
			hde.angle=(corpsepos[e.playernumber].z%1.)*1000;
			hde.pitch=80;
			hde.A_StartSound(hde.painsound,CHAN_VOICE);
			if(hd_disintegrator)hde.spawn("TeleFog",hde.pos,ALLOW_REPLACE);

			hde.GetOverlayGivers(hde.OverlayGivers);

			//For some reason the player, only in PoF where they burned to death,
			//will be given a lethal amount of heat upon respawn.
			//I have no idea what causes this.
			//Until the source is discovered here is a gross hack.
			hde.A_GiveInventory("heat",1);
			heat(hde.findinventory("heat")).realamount=-999;
			return;
		}

		//force clear heat
		hde.A_TakeInventory("Heat");

		//mitigate spawncamping: don't respawn holding a reloader or something
		if(
			hde.player
			&&(
				!hde.player.readyweapon
				||hde.player.readyweapon.bwimpy_weapon
			)
		)hde.A_SelectWeapon("HDFist");

		//mitigate spawncamping: replenish ammo
		if(!hd_dropeverythingondeath){
			for(inventory hdww=hde.inv;hdww!=null;hdww=hdww.inv){
				let hdw=hdweapon(hdww);
				if(hdw&&!hdbackpack(hdw))hdw.initializewepstats(true);
				let hdm=hdmagammo(hdww);
				if(hdm)hdm.maxcheat();
			}
		}
		if(hdlivescounter.wiped(e.playernumber)){
			hde.A_GiveInventory("SpecMorph"); //keep as an inv for ease of testing
			hde.A_GiveInventory("InvReset");
		}else{
			if(
				teamplay&&deathmatch
			){
				vector3 tmspn=teamspawns[players[e.playernumber].getteam()];
				if(tmspn!=(0,0,0)){
					hde.setorigin(tmspn,false);
					hde.angle=teamspawnangle[players[e.playernumber].getteam()];
					if(
						!hde.trymove(hde.pos.xy,true)
						&&hde.blockingmobj&&hde.blockingmobj.bshootable
					)hde.blockingmobj.damagemobj(hde,hde,hde.TELEFRAG_DAMAGE,"Balefire",DMG_FORCED);
					hde.A_Recoil(-15);
				}
			}

			hde.spawn("TeleFog",hde.pos,ALLOW_REPLACE); //HDPP only sets telefog in postbeginplay
		}
	}

	vector3 teamspawns[255]; //how do you get # of teams
	double teamspawnangle[255];
	void MoveToTeamSpawn(hdplayerpawn ppp,int team,int cmd){
		string messagesubject=string.format("\cl%s has",ppp.player.getusername());
		string message;
		if(cmd==666){
			if(ppp.player.crouchfactor<1.||!ppp.checkmove(ppp.pos.xy,PCM_NOACTORS)){
				ppp.A_Log("\crThere is not enough room to set a spawnpoint.");
				return;
			}else{
				teamspawns[team]=ppp.pos;
				teamspawnangle[team]=ppp.angle;
				message=string.format(" changed the team spawnpoint to [\cx%i\cl,\cy%i\cl,\cz%i\cl]",
					teamspawns[team].x,teamspawns[team].y,teamspawns[team].z
				);
			}
		}else if(cmd<0||cmd==999){
			teamspawns[team]=(0,0,0);
			message=(" \cyCLEARED\cl the team spawnpoint! You will respawn randomly!\n\cu(Type \crteamspawn 666\cu to set a new spawnpoint.)");
		}else{
			if(teamspawns[team]==(0,0,0))ppp.A_Log("\clNo team spawnpoint has been set. Type \crteamspawn 666\cl to set it.",true);
			else ppp.A_Log(string.format("\clThe team spawnpoint is [\cx%i\cl,\cy%i\cl,\cz%i\cl]",
				teamspawns[team].x,teamspawns[team].y,teamspawns[team].z
			),true);
			return;
		}
		for(int i=0;i<MAXPLAYERS;i++){
			if(players[i].getteam()==team&&players[i].mo)
			players[i].mo.A_Print(
				string.format("%s\cl%s",
					i==ppp.playernumber()?"\clYou have":messagesubject,
					message
				)
			);
		}
	}
}




//Spectator playerpawn
class SpecMorph:ActionItem{
	states{
	pickup:
		TNT1 A 0{
			setz(pos.z+50);
			A_Morph("HDSpectator",int.MAX,MRF_FULLHEALTH,"CheckPuff","TeleportFog");
			if(!multiplayer)return;
			if(player)A_Log(string.format("%s is now a spectator.",player.getusername()));
		}fail;
	}
}
class HDBotSpectator:HDSpectator{
	default{
		+nointeraction
	}
}
class HDSpectator:HDPlayerPawn{
	default{
		-solid -shootable +invisible +notarget +nogravity +noblockmap
		-telestomp +alwaystelefrag -pickup +notrigger
		+specialfiredamage
		+nointeraction
		telefogsourcetype "";
		telefogdesttype "";
		player.viewbob 0;
		player.soundclass "spectator";
		player.userange 0;player.jumpz 0;maxstepheight 1;
		player.morphweapon "NullWeapon";
		player.forwardmove 0.3;player.sidemove 0.3;
		player.startitem "NullWeapon";
		player.viewheight 1;player.attackzoffset 0;
		height 1;radius 1;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(damage!=TELEFRAG_DAMAGE)return -1;
		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}
	override void DeathThink(){
		if(!!player)player.cmd.buttons|=BT_USE;
		PlayerPawn.DeathThink();
	}
	override void Die(actor source,actor inflictor,int dmgflags,name MeansOfDeath){
		PlayerPawn.Die(source,inflictor,dmgflags,MeansOfDeath);
	}
	override void postbeginplay(){
		super.postbeginplay();
		invsel=null;
		setz(min(floorz+64,ceilingz-4));
		textalpha=0;
		titleticker=0;
		viewheight=height*0.5;
		lastgoodpoint=pos;
	}
	override bool cancollidewith(actor other,bool passive){return false;}
	override void checkcrouch(bool totallyfrozen){}
	override void CrouchMove(int direction){}
	override void MovePlayer(){PlayerPawn.MovePlayer();}
	override void CheckPitch(){PlayerPawn.CheckPitch();}
	int destplayer;
	double textalpha;
	string spectitle;
	int titleticker;
	vector3 lastgoodpoint;
	override void tick(){
		playerpawn.tick();
		if(!player||player.bot||player.mo!=self)return;
		A_TakeInventory("HDFist");
		player.readyweapon=null;

		int oldinput=getplayerinput(MODINPUT_OLDBUTTONS);
		int buttons=player.cmd.buttons;
		vel*=0.9;

		invsel=null;
		player.morphtics=10;

		if(level.ispointinlevel(pos))lastgoodpoint=pos;
		else setorigin((lastgoodpoint.xy,pos.z),true);

		if(hd_pof){
			setorigin(spawnpoint,false);
			A_SetShootable();
			damagemobj(null,null,TELEFRAG_DAMAGE,"internal");
		}

		if(
			floorz>=pos.z
			||ceilingz-pos.z<=height
		){
			vel.z=0;
			setz(clamp(pos.z,floorz,ceilingz));
		}
		if(buttons&BT_CROUCH)vel.z-=speed;
		if(buttons&BT_JUMP)vel.z+=speed;

		if(textalpha<0.7)textalpha+=0.02;
		if(!titleticker){
			if(hdlivescounter.owndeaths(playernumber())>fraglimit%100)spectitle="O u t   o f   l i v e s.";
			else spectitle="Now spectating.";
			titleticker=-1;
		}else if(titleticker>0)titleticker--;

		//warp to players
		int chosenplayer=-1;int choosedir;
		if(
			(buttons&BT_ATTACK)&&!(oldinput&BT_ATTACK)
			||(buttons&BT_ALTATTACK)&&!(oldinput&BT_ALTATTACK)
		){
			if(buttons&BT_ATTACK)choosedir=1;
			else choosedir=-1;
	
			for(int i=0;i<MAXPLAYERS&&chosenplayer<0;i++){
				destplayer+=choosedir;
				if(destplayer<0)destplayer=MAXPLAYERS-1;
				else if(destplayer==MAXPLAYERS)destplayer=0;

				if(!playeringame[destplayer])continue;

				actor pmo=players[destplayer].mo;
				if(
					pmo
					&&!(pmo is "HDSpectator")
					&&(
						!teamplay
						||bot_allowspy
						||players[destplayer].getteam()==player.getteam()
					)
				){
					titleticker=70;
					spectitle="\cx"..players[destplayer].getusername();
					setorigin(pmo.pos,true);
					angle=pmo.angle;pitch=10;
					A_ChangeVelocity(-6,0,12,CVF_RELATIVE|CVF_REPLACE);
					break;
				}
			}
		}
	}
	states{
	spawn:
	see:
	melee:
	missile:
	pain:
		TNT1 A -1;
		loop;
	death:
	xdeath:
		TNT1 A 0 A_NoBlocking();
		TNT1 A 10 A_CheckPlayerDone();
		wait;
	}
}
