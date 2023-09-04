// ------------------------------------------------------------
// Radius damage effect combos!
// ------------------------------------------------------------

//need to do a new explosion to immolate things properly
//...can we do a combo exploder (blast, frags and immolate)?
extend class HDActor{
	void A_HDBlast(
		double blastradius=0,int blastdamage=0,double fullblastradius=0,name blastdamagetype="bashing",
		double pushradius=0,double pushamount=0,double fullpushradius=0,bool pushmass=true,
		double fragradius=0,class<HDBulletActor> fragtype="HDB_frag",int fragments=HDEXPL_FRAGS,
		double immolateradius=0,int immolateamount=1,int immolatechance=100,
		bool hurtspecies=true,
		actor source=null,
		bool passwalls=false,
		double anglespread=180
	){
		hdactor.HDBlast(self,
			blastradius,blastdamage,fullblastradius,blastdamagetype,
			pushradius,pushamount,fullpushradius,pushmass,
			fragradius,fragtype,fragments,
			immolateradius,immolateamount,immolatechance,
			hurtspecies,
			source,
			passwalls,
			anglespread
		);
	}
	enum FragConst{
		//imagine a ball 80mm wide
		//area = 2*[tau]*(40^2) = 20106.19298297468
		//fragments start out 4x4mm
		//2*[tau]*(40^2)/16 = 1257 rounded up :(
		//for 3x3, that count goes up to 2234
		HDEXPL_FRAGS=2234,
		HDEXPL_MAXFRAGS=20,
	}
	enum UpperMidLower{
		FTIER_TOP=1,
		FTIER_MID=2,
		FTIER_MIDL=4, //left and right relative to the grenade, facing the victim
		FTIER_MIDR=8,
		FTIER_BOTTOM=16
	}
	static void HDBlast(actor caller,
		double blastradius=0,int blastdamage=0,double fullblastradius=0,name blastdamagetype="None",
		double pushradius=0,double pushamount=0,double fullpushradius=0,bool pushmass=true,
		double fragradius=0,class<HDBulletActor> fragtype="HDB_frag",int fragments=HDEXPL_FRAGS,
		double immolateradius=0,int immolateamount=1,int immolatechance=100,
		bool hurtspecies=true,
		actor source=null,
		bool passwalls=false,
		double anglespread=180
	){
		//get the biggest radius
		double bigradius=max(
			blastradius,
			fragradius,
			pushradius,
			immolateradius
		);

		//initialize things to be used in the iterator
		if(!source){
			if(caller.target)source=caller.target;
			else if(caller.master)source=caller.master;
			else source=caller;
		}

		//do all this from the centre
		double callerhalfheight=caller.height*0.5;
		caller.addz(callerhalfheight);

		blockthingsiterator itt=blockthingsiterator.createfrompos(
			caller.pos.x,
			caller.pos.y,
			clamp(caller.pos.z,caller.floorz,caller.ceilingz),
			0,
			bigradius,
			false
		);

		while(itt.Next()){
			actor it=itt.thing;

			//abort all checks if no hurt species
			if(
				!it
				||it==caller
				||(
					!hurtspecies
					&&it.species==source.species
					&&!it.ishostile(source)
				)
			)continue;


			//abort all checks if outside fan of effect
			if(
				absangle(caller.angle,caller.angleto(it))>anglespread
			)continue;

			double ithalfheight=it.height*0.5;
			it.addz(ithalfheight); //get the middle not the bottom
			double dist=caller.distance3d(it);
			double dist2=caller.distance2d(it);
			it.addz(-ithalfheight); //reset "it"'s position

			//some variables that will be reused
			double difz=it.pos.z-caller.pos.z;
			double pitchtotop=-atan2(difz+it.height,dist2);
			double pitchtomid=-atan2(difz+ithalfheight,dist2);
			double pitchtobottom=-atan2(difz,dist2);
			double angletomid=caller.angleto(it);
			double edgeshot=atan2(it.radius-0.1,dist-it.radius);

			//check how much of the actor is exposed
			double losmul=0.;
			int tiers=0;
			if(passwalls){
				losmul=1.;
				tiers=FTIER_TOP|FTIER_MIDL|FTIER_MIDR|FTIER_BOTTOM;
			}else if(
				caller.pos.z>caller.ceilingz
				&&caller.ceilingpic==skyflatnum
			){
				if(it.ceilingpic==skyflatnum){
					tiers=(FTIER_TOP|FTIER_MIDR);
					losmul=frandom(0.6,0.9);
				}else{
					if(!random(0,2))tiers=FTIER_MIDR;
					losmul=frandom(0,0.3);
				}
				if(!!tiers){
					if(random(0,2))tiers=FTIER_MIDL;
					losmul+=frandom(0,0.3);
				}
			}else if(
				caller.pos.z<caller.floorz
				&&caller.floorpic==skyflatnum
			){
				if(it.floorpic==skyflatnum){
					tiers=(FTIER_TOP|FTIER_MIDR);
					losmul=frandom(0.6,0.9);
				}else{
					if(!random(0,2))tiers=FTIER_MIDR;
					losmul=frandom(0,0.3);
				}
				if(!!tiers){
					if(random(0,2))tiers=FTIER_MIDL;
					losmul+=frandom(0,0.3);
				}
			}else{
				//shoot lines to the top, middle, bottom and sides
				//if some of these fail, target is partially covered
				//assumes legs that have smaller profile than upper body
				flinetracedata blt;
				double biggerradius=bigradius+it.radius;  //2021-10-25 why tho

				//top
				caller.linetrace(angletomid,biggerradius,pitchtotop,
					TRF_NOSKY,0,data:blt);
				if(blt.hitactor==it){
					tiers|=FTIER_TOP;
					losmul+=0.25;
				}

				//bottom
				caller.linetrace(angletomid,
					biggerradius,pitchtobottom,
					TRF_NOSKY,0,data:blt);
				if(blt.hitactor==it){
					tiers|=FTIER_BOTTOM;
					losmul+=0.16;
				}

				//middle line
				caller.linetrace(angletomid,
					biggerradius,pitchtomid,TRF_NOSKY,0,data:blt);
				if(blt.hitactor==it){
					tiers|=FTIER_MID;
					losmul+=0.25;
				}
				caller.linetrace(angletomid+edgeshot,
					biggerradius,pitchtomid,TRF_NOSKY,0,data:blt);
				if(blt.hitactor==it){
					tiers|=FTIER_MIDL;
					losmul+=0.17;
				}
				caller.linetrace(angletomid-edgeshot,
					biggerradius,pitchtomid,
					TRF_NOSKY,0,data:blt);
				if(blt.hitactor==it){
					tiers|=FTIER_MIDR;
					losmul+=0.17;
				}

				//the final multiplier should not exceed 1
				if(losmul>1.)losmul=1.;
			}
//			if(losmul)caller.A_Log(string.format("%s  %f",it.getclassname(),losmul));


			if(!tiers)continue;


			//immolate
			if(
				immolateamount
				&&dist<=immolateradius
				&&!it.countinv("ImmunityToFire")
			){
				if(immolateamount<0){
					HDF.Give(it,"Heat",-immolateamount+random(-immolatechance,immolatechance));
				}else if(
					frandom(0,100)*losmul<immolatechance
				){
					if(hdactor(caller))hdactor(caller).A_Immolate(it,caller.target,immolateamount);
					else HDF.Give(it,"Heat",immolateamount*2);
				}
			}

			//push
			if(!it)continue;
			if(
				dist<=pushradius
				&&it.bshootable
				&&!it.bdontthrust
			){
				if(it.radiusdamagefactor)pushamount*=it.radiusdamagefactor;
				double divdist=(!dist||dist<min(it.radius,ithalfheight))?1:clamp(1./dist,0.,1.);
				vector3 push=(it.pos-caller.pos)*divdist
					*clamp(pushamount-clamp(dist-fullpushradius,0,dist),0,pushamount);
				if(pushmass){
					if(pushamount<it.mass)push=(0,0,0);
					else if(it.mass)push/=it.mass;
				}
				if(push.length()>0)it.vel+=push;
			}

			//concussive
			if(!it)continue;
			if(
				dist<=blastradius
				&&(
					it.bshootable
					||it.bvulnerable
				)
			){
				if(it.radiusdamagefactor)blastdamage=int(it.radiusdamagefactor*blastdamage);
				int dmg=int((dist>fullblastradius)?
					blastdamage-clamp(dist-fullblastradius,0,dist)
					:blastdamage
				);
				it.DamageMobj(
					caller,source,int(dmg*losmul),blastdamagetype,
					DMG_THRUSTLESS|(source&&source.player?DMG_PLAYERATTACK:0)
				);
			}

			//fragmentation
			if(!it)continue;
			if(
				dist<=fragradius
				&&(
					it.bshootable
					||it.bvulnerable
				)
				&&it.radius
				&&it.height
			){
				int fragged=fragments;
				if(dist>0){
					//"A=[tau]rh" for sector area, divided by "A=[2tau]r^2" for total area of sphere
					//we're solving for r=1 so r is omitted
					//[tau]h/[2tau] = 2h/4 = h/2 = h*0.5
					//solving for h: h+adjacent=hypotenuse
					//sohCAHtoa: adjacent/hypotenuse=cosine
					//therefore cos(angcover)*hypotenuse=adjacent
					//hypotenuse-cos(angcover*hypotenuse)=h
					//collapse into (1.-cos(angcover))*0.5

					//double angcover=(abs(pitchtotop-pitchtomid)+edgeshot)*0.5;
					//double angcover=max(abs(pitchtotop-pitchtomid),edgeshot);
					double proportionfragged=(1.-cos(
						max(abs(pitchtotop-pitchtomid),edgeshot)
					))*0.5;

					//NOW incorporate the cover
					proportionfragged*=losmul;

					fragged=int(proportionfragged*fragged);
				}


				//randomize count and abort if none end up hitting
				fragged=int(frandom(0.9,1.1)*fragged);

				if(fragged>0){
					if(hd_debug){
						string nm;if(it.player)nm=it.player.getusername();else nm=it.getclassname();
						console.printf(nm.." fragged "..fragged.." times");
					}

					//resolve the impacts using a single bullet
					vector3 callerpos=caller.pos;
					let bbb=hdbulletactor(spawn(fragtype,(
							callerpos.xy,
							clamp(callerpos.z,caller.floorz+1,caller.ceilingz-1)
					)));
					bbb.angle=angletomid;
					bbb.pitch=pitchtomid;
					bbb.target=source;
					bbb.bcanblast=true; //checks if the bullet actor should be destroyed on impact

					vector3 vu=(cos(bbb.pitch)*(cos(angletomid),sin(angletomid)),sin(bbb.pitch));

					//resolve the impacts using the same bullet, resetting each time
					double dist2a=dist2-it.radius;
					for(
						int i=0;
						i<fragged
						&&!!it
						&&it.bshootable
						&&(
							//limit number of frags
							fragged<HDEXPL_MAXFRAGS
							||it.health>0
							||hdmobbase(it)  //still needed for bodydamage calculation
						);
						i++
					){
						bbb.resetrandoms();
						if(bbb.speed>=dist){
							if(i>7)bbb.bbloodlessimpact=true;

							double fragtop=it.height;
							double fragbottom=0;
							if(!(tiers&FTIER_BOTTOM))fragbottom=fragtop*0.3;
							if(!(tiers&FTIER_TOP))fragtop*=0.7;

							bbb.setxyz((callerpos.xy+(
								rotatevector((dist2a,0),angletomid+frandom(-edgeshot,edgeshot))),
								it.pos.z+frandom(fragbottom,fragtop)
							));

							bbb.angle=caller.angleto(bbb);
							bbb.pitch=HDMath.PitchTo(caller.pos,bbb.pos);

							bbb.onhitactor(it,bbb.pos,vu,hdbulletactor.BLAF_DONTFRAGMENT);
						}
					}
					bbb.setorigin(callerpos,false);
					bbb.bulletdie();
				}
			}
		}
		//reset position
		if(caller)caller.addz(-callerhalfheight);
	}
}
