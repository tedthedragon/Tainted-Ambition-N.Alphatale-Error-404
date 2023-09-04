// ------------------------------------------------------------
// Sight picture crosshairs
// ------------------------------------------------------------
extend class HDStatusBar{
	virtual void DrawHDXHair(hdplayerpawn hpl,double ticfrac){
		int nscp=hd_noscope.getint();
		if(
			nscp>=4
			||(
				!(cplayer.cmd.buttons&(BT_USE|BT_ZOOM))
				&&(
					nscp>1
					||hd_hudusedelay.getint()<-1
				)
			)
		)return;

		let wp=hdweapon(cplayer.readyweapon);
		bool sightbob=hd_sightbob.getbool();

		vector2 bob=hpl.crossbob;
		vector2 lastbob=hpl.lastcrossbob;
		double fov=cplayer.fov;


		//have no crosshair at all
		if(
			!wp
			||hpl.barehanded
			||hpl.nocrosshair>0
			||(
				!sightbob
				&&hpl.countinv("IsMoving")
			)
			||abs(bob.x)>75
			||abs(bob.y)>80
			||fov<13
		)return;


		// Interpolate
		bob = lastbob + ((bob - lastbob) * TicFrac);


		//don't know why this keeps snapping to arbitrary values
		//turning off forcescaled does NOT help
		double scl=fov/(90.*clamp(hd_crosshairscale.getfloat(),0.1,3.0));

		SetSize(0,int(320.*scl),int(200.*scl));
		BeginHUD(forcescaled:true);


		actor hpc=hpl.scopecamera;
		int buttons=cplayer.cmd.buttons;

		bool scopeview=!!hpc&&(
			!nscp
			||(
				buttons&BT_ZOOM
				&&nscp<3
			)
		);


		wp.DrawSightPicture(self,wp,hpl,sightbob,bob,fov,scopeview,hpc);
	}

	//choose the reticle picture with a fallback.
	//NB: Theoretically this SHOULD NOT desync if someone has more pictures loaded,
	//but if anyone complains later take a look again.
	string ChooseReflexReticle(int which){
		string ret=HDCONST_RETICLEPREFIX..which;
		if(ret.length()>8)ret=ret.left(8);
		if(TexMan.GetName(TexMan.CheckForTexture(ret))!="")return ret;

		//check for deprecated "riflsit" - untested!
		if(which<10){
			ret="riflsit"..which;
			if(TexMan.GetName(TexMan.CheckForTexture(ret))!="")return ret;
		}

		return HDCONST_RETICLEPREFIX..0;
	}
}
