// ------------------------------------------------------------
// Raging Erech shun.
// ------------------------------------------------------------
class SquadGhost:HDMobBase{
	default{
		-solid +noclip
		+nonshootable
		-countkill
		+friendly
		+floorhugger
		+nopain
		+nofear
		+noblood
		+notelefrag
		renderstyle "add";
		translation "0:255=%[0,0,0]:[0.3,0.7,0.1]";
		alpha 0.;

		//-shootable
		height 0.;  //because linetrace doesn't respect nonshootable

		speed 10.;
		tag "$TAG_SQUADGHOST";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(damage==TELEFRAG_DAMAGE)return super.damagemobj(inflictor,source,damage,mod,flags,angle);
		return -1;
	}
	override void tick(){
		actor.tick();
		if(isfrozen())return;

		if(frame==4||frame==5)alpha=min(alpha+0.1,0.8);
		else alpha=clamp(alpha+frandom(-0.1,0.1),min(alpha,0.6),0.8);

		if(!(level.time&(1|2|4))){
			if(!random(0,15))A_StartSound("ghost/active",CHAN_VOICE,CHANF_OVERLAP);
			A_Trail();
		}
	}
	void A_SquadGhostAttack(){
		if(!target)return;
		A_StartSound("ghost/attack",CHAN_VOICE,CHANF_OVERLAP);
		bool pained=random(0,127)<target.painchance;
		if(pained)forcepain(target);
		if(
			pained
			||target.target==master
		)target.target=self;
		// else if(!random(0,15))target.target=null;
		target.lastenemy=self;
	}
	void A_SquadGhostTerror(){
		if(!CheckFriendPlayer()){
			A_FadeOut(0.1);
			return;
		}
		A_StartSound("ghost/active",CHAN_VOICE,CHANF_OVERLAP);
		blockthingsiterator it=blockthingsiterator.create(self,256);
		array<actor> enemies;enemies.clear();
		while(it.next()){
			actor itt=it.thing;
			if(
				!itt.bcorpse
				&&(itt.bismonster||itt.player)
				&&itt.ishostile(players[friendplayer-1].mo)
			){
				let hdm=hdmobbase(itt);
				if(hdm)hdm.threat=self;
				else itt.bfrightened=true;
				if(random(0,255)<itt.painchance)itt.target=self;
				else if(
					(
						itt.target==master
						||itt.target==self
					)&&!random(0,3)
				)itt.target=null;
				if(
					target
					&&itt!=target
					&&!random(0,3)
				)itt.target=target;
				enemies.push(itt);
			}
		}
		if(enemies.size()<1)return;
		target=enemies[random(0,enemies.size()-1)];
	}
	void A_SquadGhostWander(){
		A_Wander();
		if(
			!!target
			&&target.health>0
			&&checksight(target)
			&&!target.instatesequence(curstate,target.resolvestate("falldown"))
			&&!random(0,7)
		){
			setstatelabel("missile");
			return;
		}
		if(!CheckFriendPlayer())A_FadeOut(0.1);
	}
	bool CheckFriendPlayer(){
		int fpn=friendplayer;
		if(fpn<1||fpn>MAXPLAYERS)return false;
		fpn--;
		return
			players[fpn].mo
			&&players[fpn].mo.player
			&&players[fpn].mo.health>0
		;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_GiveInventory("ImmunityToFire");
	}
	states{
	spawn:
		PLAY A 0 nodelay A_Jump(80,4);
		POSS A 0 A_Jump(bplayingid?127:40,3);
		CPOS A 0 A_Jump(40,2);
		SPOS A 0;
		#### E 20 A_SetScale(frandom(0.9,1.1));
	see:
		#### A 0 A_SquadGhostTerror();
		#### AABBCCDD 2 A_SquadGhostWander();
		loop;
	missile:
		#### EE 5 A_FaceTarget();
	missile2:
		#### F 1 bright light("SHOT") A_SquadGhostAttack();
		#### E 2;
		#### E 10 A_Jump(170,"missile2");
		goto see;
	}
}

class SquadSummoner:HDPickup{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Summoning Talisman"
		//$Sprite "PRIFA0"

		+forcexybillboard
		-hdpickup.droptranslation
		inventory.icon "PLHELMA0";
		inventory.pickupsound "pickups/talisman";
		inventory.pickupmessage "$PICKUP_TALISMAN";
		hdpickup.bulk ENC_SQUADSUMMONER;
		tag "$TAG_TALISMAN";
	}
	states{
	spawn:
		PRIF A -1;
	use:
		TNT1 A 0{
			A_StartSound("ghost/useitem",CHAN_AUTO,attenuation:ATTN_NONE);
			A_AlertMonsters();
			A_SpawnItemEx("SquadGhost",xvel:-2,yvel:2,angle:180,flags:SXF_NOCHECKPOSITION|SXF_SETMASTER);
			A_SpawnItemEx("SquadGhost",xvel:-2,yvel:-2,angle:180,flags:SXF_NOCHECKPOSITION|SXF_SETMASTER);
			A_SpawnItemEx("SquadGhost",xvel:-3,angle:180,flags:SXF_NOCHECKPOSITION|SXF_SETMASTER);

			string deadawaken;
			int da=random(0,3);
			if(da==0)deadawaken=Stringtable.Localize("$TALISMAN_SUMMON1");
			else if(da==1)deadawaken=Stringtable.Localize("$TALISMAN_SUMMON2");
			else if(da==2)deadawaken=Stringtable.Localize("$TALISMAN_SUMMON3");
			else if(da==3)deadawaken=Stringtable.Localize("$TALISMAN_SUMMON4");

			deadawaken.replace("/","\n\n\cj");

			int msgseconds=max(1,(deadawaken.length()>>5));
			A_PrintBold("\cj"..deadawaken,msgseconds,"newsmallfont");
		}stop;
	}
}
