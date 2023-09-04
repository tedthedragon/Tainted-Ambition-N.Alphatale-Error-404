// ------------------------------------------------------------
// AI stuff related to aiming and targeting.
// ------------------------------------------------------------
const FLTP_TOP=-999;
enum LeadTargetFlags{
	HDLT_RANDOMIZE=1,
	HDLT_DONTABORT=2,
}
extend class HDMobBase{
	void A_LeadTarget(
		double tics,
		int flags=HDLT_RANDOMIZE,
		double maxturn=100
	){
		if(
			!targetinsight
			||!target
			||lasttargetvel==(0,0,0)
		)return;
		if(flags&HDLT_RANDOMIZE)tics=frandom(0,tics*1.3);

		let ltp=lasttargetpos-lasttargetvel;
		let lsp=prev;

		double ach=deltaangle(
			hdmath.angleto(lsp.xy,ltp.xy),
			hdmath.angleto(pos.xy,lasttargetpos.xy)
		);
		double pch=hdmath.pitchto(lsp,ltp)-hdmath.pitchto(pos,lasttargetpos);

		ach=angle+clamp(ach*tics,-maxturn,maxturn);
		pch=clamp(pitch+pch*tics,-90,90);

		if(HDMobAI.TryShoot(self,angle:ach,pitch:pch,flags:HDMobAI.TS_GEOMETRYOK)){
			angle=ach;
			pitch=pch;
		}else if(!(flags&HDLT_DONTABORT))setstatelabel("see");
	}
	void A_FaceLastTargetPos(
		double maxturn=180,
		double attackheight=-1,
		double targetheight=-1
	){
		if(!target)return;
		if(attackheight<0)attackheight=gunheight;
		if(targetheight<0){
			if(targetheight==FLTP_TOP)targetheight=lasttargetheight;
			targetheight=lasttargetheight*0.6;
		}

		double targetpitch=hdmath.pitchto(
			(pos.xy,pos.z+attackheight),
			(lasttargetpos.xy,lasttargetpos.z+targetheight)
		);
		targetpitch-=pitch;
		pitch=clamp(pitch+clamp(targetpitch,-maxturn,maxturn),-90,90);

		double targetangle=hdmath.angleto(pos.xy,lasttargetpos.xy);
		targetangle=deltaangle(angle,targetangle);
		angle+=clamp(targetangle,-maxturn,maxturn);
	}
	void A_TurnToAim(
		double maxturn=180,
		double attackheight=-1,
		double targetheight=-1,
		statelabel shootstate="shoot",
		bool musthaveactualsight=false
	){
		if(!target)return;
		if(attackheight<0)attackheight=gunheight;
		if(targetheight<0)targetheight=lasttargetheight*0.6;

		A_FaceLastTargetPos(maxturn,attackheight,targetheight);

		double targetpitch=hdmath.pitchto(
			(pos.xy,pos.z+attackheight),
			(lasttargetpos.xy,lasttargetpos.z+targetheight)
		);
		double targetangle=hdmath.angleto(pos.xy,lasttargetpos.xy);

		if(
			absangle(angle,targetangle)<1
			&&pitch-targetpitch<1
			&&(
				!musthaveactualsight
				||checksight(target)
			)
		){
			if(!HDMobAI.TryShoot(self,flags:HDMobAI.TS_GEOMETRYOK)){
				setstatelabel("see");
				return;
			}else{
				TriggerPullAdjustments();
				setstatelabel(shootstate);
			}
		}
	}

	//returns whether a state was changed
	bool A_Watch(
		double randomturn=5.,
		statelabel seestate="see",
		statelabel missilestate="missile",
		statelabel meleestate="melee"
	){
		if(!target){
			target=lastenemy;
			if(target)OnAlert(seestate);
			else setidle();
			return true;
		}
		let lastltp=lasttargetpos;
		if(CheckTargetInSight()){
			setstatelabel(
				findstate(meleestate)
				&&lasttargetdist<meleerange+lasttargetradius+radius
			?meleestate:missilestate);
			return true;
		}
		A_FaceLastTargetPos(2);
		if(randomturn)angle+=frandom(-randomturn,randomturn);
		return false;
	}
	//points at lasttargetpos, checks for target, fires if no LOS anyway
	void A_Coverfire(
		statelabel shootstate="shoot",
		double randomturn=0
	){
		if(A_Watch(randomturn))return;
		if(frandom(0,1)<0.2){
			TriggerPullAdjustments();
			setstatelabel(shootstate);
		}else if(frandom(0,1)<0.1)setstatelabel("see");
		A_FaceLastTargetPos(10);
	}

	double spread;
	virtual void TriggerPullAdjustments(){
		if(
			vel.z
			||floorz>=pos.z
		)spread+=max(abs(vel.x),abs(vel.y))*0.4;
		if(spread){
			angle+=frandom(-spread,spread);
			pitch+=frandom(-spread,spread);
		}
	}


	//take a moment to stabilize a shot and actually point the gun where you're looking
	//returns the amount of time taken
	int A_StartAim(
		//20max 0.9rate 30tics = best accuracy ~0.8 degrees
		double maxspread=20,
		double rate=0.9,
		int mintics=3,
		int maxtics=30,
		bool dontlead=false
	){
		if(!target)return tics;
		double silh=atan2(lasttargetradius,lasttargetdist);
		int lag=maxtics;
		for(int i=0;i<lag;i++){
			if(
				silh>maxspread
			){
				lag=min(lag,i);
				break;
			}
			maxspread*=rate;
		}
		A_SetTics(lag);
		if(!dontlead)A_LeadTarget(lag,false);
		spread=maxspread;
		return lag;
	}
}
