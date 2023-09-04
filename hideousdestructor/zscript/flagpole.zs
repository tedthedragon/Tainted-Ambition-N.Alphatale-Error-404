// ------------------------------------------------------------
// Flagpole mode
// ------------------------------------------------------------
extend class HDHandlers{
	int flagcaps[MAXPLAYERS];
	void SpawnFlagpole(){
		vector3 spawnfirst=getrandomspawnpoint();
		vector3 spawnsecond;
		do{
			spawnsecond=getrandomspawnpoint(spawnfirst);
		}while(spawnsecond==spawnfirst);
		actor.spawn("HDCapFlagpole",spawnfirst,ALLOW_REPLACE);
		actor.spawn("HDCapFlag",spawnsecond,ALLOW_REPLACE);
		actor.spawn("TeleFog",spawnsecond,ALLOW_REPLACE);
		if(hd_debug){
			console.printf("Flagpole spawned at ["
				..spawnfirst.x..", "
				..spawnfirst.y..", "
				..spawnfirst.z.."]\nFlag spawned at ["
				..spawnsecond.x..", "
				..spawnsecond.y..", "
				..spawnsecond.z.."]"
			);
		}
	}
	vector3 GetRandomSpawnPoint(
		vector3 compare1=(0,0,32000),
		vector3 compare2=(0,0,32000),
		vector3 compare3=(0,0,32000)
	){
		let hhh=hdhandlers(eventhandler.find("hdhandlers"));

		//if all (0,0,32k) simply pick a random point and be done with it
		if(
			compare1.z==32000
			&&compare2.z==32000
			&&compare3.z==32000
		){
			int whch=random(0,invposx.size()-1);
			return (hhh.invposx[whch],hhh.invposy[whch],hhh.invposz[whch]);
		}

		//pick 5 random points and get the furthest one
		vector3 candidatepoint[10];
		int highestcandidate=0;
		double highestdist=0;
		for(int i=0;i<candidatepoint.size();i++){
			//obtain a random point
			int whch=random(0,invposx.size()-1);
			candidatepoint[i]=(hhh.invposx[whch],hhh.invposy[whch],hhh.invposz[whch]);

			//determine the lowest distance from each of the comparison points
			double lowestdist=(65000.*65000.);
			for(int j=0;j<3;j++){
				vector3 ddd;
				if(j==0)ddd=compare1;
				else if(j==0)ddd=compare2;
				else ddd=compare3;
				if(ddd.z==32000)continue;

				ddd=level.vec3offset(candidatepoint[i],ddd);
				double compdist=ddd dot ddd;
				if(compdist<lowestdist)lowestdist=compdist;
			}
			//if the above result is higher, update best candidate
			if(lowestdist>highestdist){
				highestdist=lowestdist;
				highestcandidate=i;
			}
		}
		return candidatepoint[highestcandidate];
	}
}


class HDCapFlagpole:Actor{
	default{
		+flatsprite
		+nointeraction
		+rollsprite
		+rollcenter
		renderstyle "add";
		height 56;radius 8;
	}
	states{
	spawn:
		BAL2 DE 1 bright light("EX1"){
			alpha=frandom(0.,0.3);
			for(int i=0;i<5;i++)A_SpawnParticle(
				"ff ca 00",SPF_FULLBRIGHT,35,frandom(2.,8.),
				xoff:frandom(-2,2),yoff:frandom(-2,2),zoff:frandom(0,128),
				accelx:frandom(-0.01,0.01),accely:frandom(-0.01,0.01),accelz:frandom(-0.005,0.03)
			);
			A_SetAngle(angle+frandom(6,18),SPF_INTERPOLATE);
			scale=(1.,1.)*clamp(scale.x+frandom(-0.3,0.3),0.4,3.6);
			setz(floorz+frandom(0,4));
			if(
				!deathmatch
				&&!random(0,3)
				&&!(level.time%1024)
			){
				spawn("telefog",pos,ALLOW_REPLACE);
				class<actor>baddie;
				switch(random(0,random(0,7))){
				case 1:baddie="ardentipede";break;
				case 2:baddie="regentipede";break;
				case 3:baddie="trilobite";break;
				case 4:baddie="painbringer";break;
				case 5:baddie="ninjapirate";break;
				case 6:baddie="undeadrifleman";break;
				case 7:baddie="baronofhell";break;
				default:baddie="serpentipede";break;
				}
				actor badnotyetdead=spawn(baddie,pos,ALLOW_REPLACE);
				array<actor>candidatetargets;candidatetargets.clear();
				for(int i=0;i<MAXPLAYERS;i++){
					if(
						playeringame[i]
						&&hdplayerpawn(players[i].mo)
					){
						candidatetargets.push(players[i].mo);
					}
				}
				badnotyetdead.target=candidatetargets[random(0,candidatetargets.size()-1)];
				badnotyetdead.A_AlertMonsters(0,AMF_EMITFROMTARGET);
			}
		}
		---- A 0{
			stamina++;
			if(stamina<(TICRATE*180))return;
			stamina=0;
			let hhh=hdhandlers(eventhandler.find("hdhandlers"));
			vector3 dest=hhh.getrandomspawnpoint();
			spawn("telefog",pos,ALLOW_REPLACE);
			spawn("telefog",dest,ALLOW_REPLACE);
			setorigin(dest,false);
			if(hd_debug)A_Log("Flagpole moved to ["..dest.x..", "..dest.y..", "..dest.z.."]");
			else A_Log("The flagpole has moved!");
		}
		loop;
	}
}
class HDFlagBanner:Actor{
	default{
		+nointeraction
		+wallsprite
		+bright
		renderstyle "add";
		height 0;radius 0;
		alpha 0.8;
		scale 0.6;
		translation 0;
	}
	double trackalpha;
	int selectedteam;
	void CheckBannerSprite(){
		trackalpha=alpha;
		if(selectedteam<0||selectedteam>8){
			selectedteam=8;
		}
		frame=selectedteam;
	}
	virtual void BannerSpin(){
		alpha=frandom(0.3,1.);
		A_SetAngle(angle+2,SPF_INTERPOLATE);
	}
	states{
	spawn:
		CBAN A 0 nodelay CheckBannerSprite();
		---- A 1 BannerSpin();
		wait;
		CBAN ABCDEFGHI 0;
		stop;
	}
}
class HDFlagCappedBanner:HDFlagBanner{
	default{
		scale 1.8;
		alpha 1.;
		friction 30.;
	}
	override void BannerSpin(){
		double newangle=angle+0.3;

		if(friction>0.0001){
			speed-=24.;
			newangle+=friction;
			friction*=0.98;
			if(accuracy<100){
			accuracy++;
				A_SpawnParticle(
					"ff ca 00",SPF_FULLBRIGHT|SPF_RELVEL|SPF_RELPOS,
					30,frandom(5,15),speed,
					yoff:15,
					zoff:accuracy*0.6,
					velx:2.8,vely:2.,velz:1.
				);
			}
		}

		setz(floorz+26+sin(level.time)*5-trackalpha*10.);
		trackalpha-=0.0005;
		alpha=frandom(trackalpha,trackalpha+0.1);
		A_SetAngle(newangle,SPF_INTERPOLATE);
		if(alpha<0.001)destroy();
	}
}
class HDCapFlag:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.cheatnotweapon
		-weapon.no_auto_switch
		+inventory.invbar
		inventory.pickupsound "pickups/flagpole";
		inventory.pickupmessage "You got the flag!";
		translation 0;
		scale 0.6;
	}
	override void ownerdied(){
		owner.dropinventory(self);
		weaponstatus[CAPFS_PROGRESS]=0;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[CAPFS_TEAM]=-1;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		string bannername="CBAN";
		int bannernum=hdw.weaponstatus[CAPFS_TEAM];
		switch(bannernum){
		case 0:bannername=bannername.."A";break;
		case 1:bannername=bannername.."B";break;
		case 2:bannername=bannername.."C";break;
		case 3:bannername=bannername.."D";break;
		case 4:bannername=bannername.."E";break;
		case 5:bannername=bannername.."F";break;
		case 6:bannername=bannername.."G";break;
		case 7:bannername=bannername.."H";break;
		default:
			bannername=bannername.."I";
			bannernum=-1;
			break;
		}

		if(bannernum<0)sb.drawimage(bannername.."0",(-32,-22),sb.DI_SCREEN_CENTER_BOTTOM,
			alpha:0.3,
			scale:(1.,1.),
			translation:2
		);
		else sb.drawimage(bannername.."0",(-32,-22),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TRANSLATABLE,scale:(1.,1.));

		int progress=hdw.weaponstatus[CAPFS_PROGRESS];
		if(progress>0){
			sb.drawwepnum(progress,100,alwaysprecise:true);
			sb.drawstring(
				sb.mAmountFont,sb.formatnumber(progress),
				(-16,-16),sb.DI_TEXT_ALIGN_RIGHT|sb.DI_SCREEN_CENTER_BOTTOM,
				progress<35?Font.CR_RED:progress<70?Font.CR_ORANGE:Font.CR_GREEN
			);
		}
	}
	override void ondestroy(){
		super.ondestroy();
		if(banner)banner.destroy();
	}
	HDFlagBanner banner;
	override void tick(){
		super.tick();
		if(!banner){
			banner=HDFlagBanner(spawn("HDFlagBanner",pos));
			banner.selectedteam=weaponstatus[CAPFS_TEAM];
			if(weaponstatus[CAPFS_TEAM]<0)banner.translation=0;
			else banner.translation=translation;
		}
		bool owned=!!owner;

		if(owned){
			banner.binvisible=false;
			banner.setorigin((owner.pos.xy,owner.pos.z+owner.height+10),!owner.bteleport);
			if(
				!(level.time%4)
				&&abs(owner.vel.x)>0.6
				&&abs(owner.vel.y)>0.6
				&&weaponstatus[CAPFS_TEAM]!=((deathmatch&&teamplay)?owner.player.getteam():owner.playernumber())
			){
				if(
					!owner.CheckProximity("HDCapFlagpole",256)
					&&!owner.CheckProximity("HDCapFlagpole",512,flags:CPXF_CHECKSIGHT)
				){
					let player=owner.player;
					weaponstatus[CAPFS_PROGRESS]++;
					if(weaponstatus[CAPFS_PROGRESS]>=CAPF_PROGRESSMAX){
						string planter;
						if(
							deathmatch
							&&teamplay
						)planter=HDLivesCounter.teamcolour(player.getteam())..teams[player.getteam()].mname.."\cr team!";
						else planter=player.getusername().."\cr!";
						A_PrintBold("\crFlag programmed\n\crto \cd"..planter,3,"BIGFONT");
						weaponstatus[CAPFS_TEAM]=((deathmatch&&teamplay)?player.getteam():owner.playernumber());
						weaponstatus[CAPFS_PROGRESS]=0;
						translation=owner.translation;
						if(banner)banner.destroy();
					}
				}
			}
		}else{
			if(floorz<pos.z)banner.binvisible=true;else{
				banner.translation=translation;
				banner.setorigin((pos.xy,pos.z+10),!banner.binvisible);
				banner.binvisible=false;
				weaponstatus[CAPFS_PROGRESS]=0;
			}
			if(
				weaponstatus[CAPFS_TEAM]>=0
			){
				if(!(level.time&(1|2))){
					angle-=36.;
					A_SpawnParticle(
						"ff ca 00",SPF_FULLBRIGHT|SPF_RELVEL|SPF_RELPOS,
						30,5,angle,
						yoff:2,
						zoff:6,
						velx:0.8,vely:0.3,velz:1.
					);
				}
			}else if(!(random(0,31))){
				angle+=frandom(-10,10);
				double frx=frandom(0.1,2.);
				double frz=frandom(3.,7.);
				for(int i=0;i<5;i++)A_SpawnParticle(
					"ff ca 00",SPF_FULLBRIGHT|SPF_RELVEL|SPF_RELACCEL,
					30,frz,angle,
					zoff:frandom(0,20),
					velx:frx*frandom(0.8,1.2),vely:frandom(-0.1,0.1),velz:frz*frandom(0.8,1.2),
					accelx:frandom(-0.1,0.1),accely:frandom(0.1,0.1),accelz:-HDCONST_GRAVITY
				);
			}
		}
	}
	states{
	spawn:
		HCAP A 1400;
		HCAP A 0{
			let hhh=hdhandlers(eventhandler.find("hdhandlers"));
			vector3 dest=hhh.getrandomspawnpoint();
			while(dest==invoker.pos){dest=hhh.getrandomspawnpoint();}
			spawn("telefog",invoker.pos,ALLOW_REPLACE);
			spawn("telefog",dest,ALLOW_REPLACE);
			if(hd_debug)invoker.A_Log("Flag moved to ["..dest.x..", "..dest.y..", "..dest.z.."]");
			else invoker.A_Log("The flag has moved!");
			invoker.weaponstatus[CAPFS_TEAM]=-1;
			invoker.setorigin(dest,false);
			invoker.translation=default.translation;
			if(invoker.banner)invoker.banner.destroy();
		}
		loop;
	select:
		TNT1 A 0{
			if(countinv("NulledWeapon"))return;
			string whatdo;
			if(
				invoker.weaponstatus[CAPFS_TEAM]==(
					(deathmatch&&teamplay)?player.getteam():playernumber()
				)
			)whatdo="Get to the flagpole and\nhold \cdFire\cx to plant it!";
			else whatdo="Move around outside of range of\nthe flagpole to program it\nfor yourself.";
			A_WeaponMessage("You have the flag!\n\n"..whatdo,144);
		}
		goto super::select;
	ready:
		TNT1 A 1 A_WeaponReady();
		goto readyend;
	fire:
		TNT1 A 0{
			if(
				invoker.weaponstatus[CAPFS_TEAM]!=(
					(deathmatch&&teamplay)?player.getteam():playernumber()
				)
			){
				A_WeaponMessage("\n\n\n\caFlag not yet attuned!\n\cjKeep moving away\n\cjthe flagpole!",70);
				setweaponstate("nope");
			}else{
				if(CheckProximity("HDCapFlagpole",96,flags:CPXF_CHECKSIGHT|CPXF_SETTRACER)){
					setweaponstate("holdplant");
				}else{
					A_WeaponMessage("\n\n\n\cgOut of range!\n\cjFind the flagpole!",70);
					tracer=null;
					setweaponstate("nope");
				}
			}
		}
		goto nope;
	holdplant:
		TNT1 A 1{
			if(!CheckProximity("HDCapFlagpole",96,flags:CPXF_CHECKSIGHT|CPXF_SETTRACER)){
				if(HDCapFlagpole(tracer)){
					A_WeaponMessage("\n\n\n\cgOut of range!\n\cjGo back in there and restart.",70);
				}
				tracer=null;
			}
			let fp=HDCapFlagpole(tracer);
			if(!fp){
				invoker.weaponstatus[CAPFS_PROGRESS]=0;
				setweaponstate("nope");
				return;
			}

			fp.stamina=0;
			invoker.weaponstatus[CAPFS_PROGRESS]++;
			A_WeaponMessage("\n\n\nPlanting flag...\n\cd"..invoker.weaponstatus[CAPFS_PROGRESS].." %",10);
			if(invoker.weaponstatus[CAPFS_PROGRESS]>=CAPF_PROGRESSMAX){
				string planter;
				if(
					deathmatch
					&&teamplay
				)planter=HDLivesCounter.teamcolour(player.getteam())..teams[player.getteam()].mname.."\cx team!";
				else planter=player.getusername().."\cx!";
				A_PrintBold("\cxFlag planted\n\cxby \cd"..planter,5,"BIGFONT");
				let hhh=hdhandlers(eventhandler.find("hdhandlers"));

				//nothing is being done with this yet...
				hhh.flagcaps[playernumber()]++;

				//if in lives mode, undo deaths
				//else add points
				if(!deathmatch){
					let hdlc=hdlivescounter.get();
					for(int i=0;i<MAXPLAYERS;i++){
						if(!playeringame[i])continue;
						if(fraglimit>0)hdlc.deaths[i]--;

						if(players[i].mo&&players[i].mo!=self)players[i].mo.UndoPlayerMorph(players[i],0,true);
						let hdp=hdplayerpawn(players[i].mo);
						if(hdp){
							if(hdp.bnogravity){
								//kill spectators to let them rejoin the game
								//I have no idea why checking for class doesn't work here
								hdlc.deaths[i]--;
								hdp.damagemobj(null,null,TELEFRAG_DAMAGE,"internal");
							}else{
								hdp.aggravateddamage=0;
								hdp.oldwoundcount=0;
								hdp.burncount=0;
								hdp.stunned=0;
								hdp.fatigue=0;
								hdbleedingwound.clearall(hdp);
								hdp.givebody(100);
							}
						}

						let hdw=hdweapon(players[i].readyweapon);
						if(hdw)hdw.initializewepstats(true);
					}
				}else if(teamplay){
					if(fraglimit<100){
						int inc=hd_instagib?10:5;
						for(int i=0;i<MAXPLAYERS;i++){
							if(
								playeringame[i]
								&&player.getteam()==players[i].getteam()
							)players[i].fragcount+=inc;
						}
					}else{
						let hdlc=hdlivescounter.get();
						for(int i=0;i<MAXPLAYERS;i++){
							if(!playeringame[i])continue;
							if(players[i].mo&&players[i].mo!=self)players[i].mo.UndoPlayerMorph(player,0,true);
							let hdp=hdplayerpawn(players[i].mo);
							bool flip=(level.time%2);
							if(
								player.getteam()==players[i].getteam()
							){
								hdlc.deaths[i]--;
								if(hdp&&flip&&hdp!=self){
									hdp.aggravateddamage=0;
									hdp.oldwoundcount=0;
									hdp.burncount=0;
									hdbleedingwound.clearall(hdp);
								}
							}else{
								if(flip)hdlc.deaths[i]++;
								if(
									hdp
									&&!hdp.checksight(self)
								)hdbleedingwound.inflict(hdp,30,source:self);
							}
						}
						hdlc.updatefragcounts(hdlc);
					}
				}else{
					let hdp=hdplayerpawn(self);
					if(hdp){
						hdp.givebody(100);
						hdbleedingwound.clearall(hdp);
					}
					if(fraglimit<100){
						player.fragcount+=10;
					}else{
						let hdlc=hdlivescounter.get();
						int pn=playernumber();
						for(int i=0;i<MAXPLAYERS;i++){
							if(
								playeringame[i]
								&&i!=pn
							){
								hdlc.deaths[i]++;
								hdlc.deaths[pn]--;
								if(level.time%2){
									actor yyy=spawn("YokaiSpawner",players[i].mo.pos,ALLOW_REPLACE);
									yyy.target=players[i].mo;
									players[i].mo.A_AlertMonsters();
								}
							}
						}
						hdlc.updatefragcounts(hdlc);
					}
				}

				//reset the flag and pole
				hhh.SpawnFlagpole();

				//destroy the old ones
				spawn("HDExplosion",(fp.pos.xy,fp.pos.z+16),ALLOW_REPLACE);
				let capban=HDFlagCappedBanner(
					spawn("HDFlagCappedBanner",fp.pos,ALLOW_REPLACE)
				);
				int cst=invoker.weaponstatus[CAPFS_TEAM];
				if(cst<0)cst=playernumber();
				capban.selectedteam=cst;
				capban.translation=translation;
				fp.destroy();
				invoker.weaponstatus[CAPFS_PROGRESS]=0;
				invoker.goawayanddie();
			}
		}
		TNT1 A 0 A_Refire("holdplant");
		goto readyend;
	altfire:
		TNT1 A 1 A_DropInventory("HDCapFlag");
		TNT1 A 1 A_ClearRefire();
		goto ready;
	}
}
enum HDCapFlagNums{
	CAPFS_TEAM=1,
	CAPFS_PROGRESS=2,

	CAPF_PROGRESSMAX=100,
}
