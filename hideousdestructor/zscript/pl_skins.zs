// ------------------------------------------------------------
// Custom skin system
// ------------------------------------------------------------
const HDMUGSHOT_DEFAULT="*";
extend class HDWeapon{
	action void A_PlaySkinSound(int which,sound fallback,int channel=CHAN_VOICE,int flags=0){
		HDPlayerPawn.PlaySkinSound(self, which, fallback, channel, flags);
	}
}
extend class HDPlayerPawn{
	string lastskin;
	string mugshot;
	int standsprite;
	int fistsprite;
	vector2 skinscale;
	double minvpitch,maxvpitch;
	sound
		tauntsound,
		xdeathsound,
		gruntsound,
		landsound,
		stepsound,
		stepsoundwet,
		medsound,
		gibbedsound;
		//painsound
		//deathsound

	enum HDSkinVals{
		HDSKIN_SPRITE=0,
		HDSKIN_VOICE=1,
		HDSKIN_MUG=2,
		HDSKIN_FIST=3,
	}
	//to be called in the ticker
	void ApplyUserSkin(bool forced=false){
		if(!player)return;

		//voodoo dolls don't have direct access to cvars
		if(player.mo!=self)hd_skin=CVar.GetCVar("hd_skin",player);
		if(!hd_skin)return; //this shouldn't happen

		//apply sprite
		if(player.crouchfactor<0.75)sprite=crouchsprite;else sprite=standsprite;
		if(standsprite==crouchsprite)scale.y=skinscale.y*player.crouchfactor;

		//retrieve values from cvar
		string skinput=hd_skin.getstring();
		if(!forced&&skinput==lastskin)return;
		lastskin=skinput;  //update old for future comparisons

		skinput=skinput.makelower();
		skinput.replace(" ","");
		skinput.replace("none","");
		skinput.replace("default","");

		array<string> skinname;skinname.clear();
		skinput.split(skinname,",");

		//I'd rather do this than to spam up everything below with null checks
		while(skinname.size()<4){
			skinname.push("");
		}

		class<HDSkin> skinclass="HDSkin";  //initialize default

		//find an actor class that matches
		if(skinname[HDSKIN_SPRITE]!=""){
			for(int i=0;i<allactorclasses.size();i++){
				let aac=allactorclasses[i];
				if(
					(class<HDSkin>)(aac)
					&&aac.getclassname()==skinname[HDSKIN_SPRITE]
				){
					skinclass=(class<HDSkin>)(aac);
					break;
				}
			}
		}


		//set the sprites
		let defskinclass=getdefaultbytype(skinclass);
		let dds=defskinclass.spawnstate;
		standsprite=dds.sprite;
		dds=defskinclass.resolvestate("crouch");
		crouchsprite=dds.sprite;
		skinscale=defskinclass.scale;
		scale=skinscale*heightmult;
		minvpitch=defskinclass.minvpitch?defskinclass.minvpitch:0.7;
		maxvpitch=defskinclass.maxvpitch?defskinclass.maxvpitch:1.3;
		translation=defskinclass.translate?65536+playernumber():0;

		//set blood colour if different
		if(defskinclass.bloodcolor!=bloodcolor){
			let aaa=spawn(skinclass,(32000,32000,0));
			if(aaa){
				copybloodcolor(aaa);
				aaa.destroy();
			}
		}

		//set the fist sprites
		if(skinname[HDSKIN_FIST].length()==4)skinname[HDSKIN_FIST]=skinname[HDSKIN_FIST].."A0";
		fistsprite=getspriteindex(skinname[HDSKIN_FIST]);
		if(fistsprite<0){
			dds=defskinclass.resolvestate("fist");
			if(dds.sprite==getspriteindex("SHTFA0"))fistsprite=-1;  //this is the default for HDSkin
			else fistsprite=dds.sprite;
		}


		//test if this sound exists
		//otherwise you can cheat by defining an invalid name to get a silent character
		sound testsound="player/"..skinname[HDSKIN_VOICE].."/pain";

		//set the sounds
		if(
			int(testsound)<=0
			||skinname[HDSKIN_VOICE]==""
		){
			tauntsound=defskinclass.tauntsound;
			xdeathsound=defskinclass.xdeathsound;
			gruntsound=defskinclass.gruntsound;
			landsound=defskinclass.landsound;
			stepsound=defskinclass.stepsound;
			stepsoundwet=defskinclass.stepsoundwet;
			medsound=defskinclass.medsound;
			gibbedsound=defskinclass.gibbedsound;
			deathsound=defskinclass.deathsound;
			painsound=defskinclass.painsound;
		}else{
			tauntsound="player/"..skinname[HDSKIN_VOICE].."/taunt";
			xdeathsound="player/"..skinname[HDSKIN_VOICE].."/xdeath";
			gruntsound="player/"..skinname[HDSKIN_VOICE].."/grunt";
			landsound="player/"..skinname[HDSKIN_VOICE].."/land";
			stepsound="player/"..skinname[HDSKIN_VOICE].."/step";
			stepsoundwet="player/"..skinname[HDSKIN_VOICE].."/squishstep";
			medsound="player/"..skinname[HDSKIN_VOICE].."/meds";
			gibbedsound="player/"..skinname[HDSKIN_VOICE].."/gibbed";
			deathsound="player/"..skinname[HDSKIN_VOICE].."/death";
			painsound="player/"..skinname[HDSKIN_VOICE].."/pain";
		}


		//set the mugshot
		if(
			TexMan.CheckForTexture(skinname[HDSKIN_MUG].."st00",TexMan.Type_Any).Exists()
		)mugshot=skinname[HDSKIN_MUG];
		else if(
			TexMan.CheckForTexture(defskinclass.mug.."st00",TexMan.Type_Any).Exists()
		)mugshot=defskinclass.mug;
		else mugshot=HDMUGSHOT_DEFAULT;
	}
	static void PlaySkinSound(actor plr,int which,sound fallback,int channel=CHAN_VOICE,int flags=0){
		let ppp=hdplayerpawn(plr);
		sound sss;
		if(ppp)switch(which){
		case SKINSOUND_TAUNT:sss=ppp.tauntsound;break;
		case SKINSOUND_XDEATH:sss=ppp.xdeathsound;break;
		case SKINSOUND_GRUNT:sss=ppp.gruntsound;break;
		case SKINSOUND_LAND:sss=ppp.landsound;break;
		case SKINSOUND_MEDS:sss=ppp.medsound;break;
		case SKINSOUND_GIBBED:sss=ppp.gibbedsound;break;
		default:return;
		}
		else sss=fallback;
		plr.A_StartSound(sss,channel,flags);
	}
}

enum skinsoundtype{
	SKINSOUND_TAUNT,
	SKINSOUND_XDEATH,
	SKINSOUND_GRUNT,
	SKINSOUND_LAND,
	SKINSOUND_MEDS,
	SKINSOUND_GIBBED,
};

extend class HDStaticHandlers{
	ui void ShowSkins(){
		string bbb="\ccSyntax:  \cdhd_skin skinclass,soundclass,mug,fist\cc\nAvailable player skins (classname, soundclass (if any), mugshot (if any)):\cg";
		for(int i=0;i<allactorclasses.size();i++){
			if(
				allactorclasses[i] is "HDSkin"
				&&allactorclasses[i]!="HDSkin"
			){
				let aac=getdefaultbytype((class<hdskin>)(allactorclasses[i]));
				bbb=bbb.."\n  "..aac.getclassname()
				.."  "..aac.soundclass
				.."  "..aac.mug;
				
			}
		}
		bbb=bbb.."\cc\nType  '\cdhd_skin \"\"\cc' in the console to reset.";
		console.printf(bbb,true);
	}
}

//base skin actor
class HDSkin:Actor{
	sound
		tauntsound,
		xdeathsound,
		gruntsound,
		landsound,
		stepsound,
		stepsoundwet,
		medsound,
		gibbedsound;
	property tauntsound:tauntsound;
	property xdeathsound:xdeathsound;
	property gruntsound:gruntsound;
	property landsound:landsound;
	property stepsound:stepsound;
	property stepsoundwet:stepsoundwet;
	property medsound:medsound;
	property gibbedsound:gibbedsound;
	string mug;
	property mug:mug;
	string soundclass;
	property soundclass:soundclass;
	bool translate;
	property translate:translate;
	double minvpitch,maxvpitch;  //if either is below zero, the voice pitch setting is skipped entirely;
	property minvpitch:minvpitch;  //setting one to zero makes it use the default value (0.7 or 1.3)
	property maxvpitch:maxvpitch;
	default{
		hdskin.translate true;
		hdskin.tauntsound "*taunt";
		hdskin.xdeathsound "*xdeath";
		hdskin.gruntsound "*grunt";
		hdskin.landsound "*land";
		hdskin.stepsound "humanoid/step";
		hdskin.stepsoundwet "humanoid/squishstep";
		hdskin.medsound "*usemeds";
		hdskin.gibbedsound "*gibbed";
		deathsound "*death";
		painsound "*pain";
		hdskin.mug "<none>";
		hdskin.soundclass "<none>";
		hdskin.minvpitch 0;
		hdskin.maxvpitch 0;
		FloatBobPhase 0;
	}
	states{
	spawn:PLAY A 0;stop;
	crouch:PLYC A 0;stop;
	fist:SHTF A 0;stop;  //intentional garbage value
	}
}


//test
class HDTestSkin:HDSkin{
	default{
		hdskin.tauntsound "grunt/sight";
		hdskin.xdeathsound "grunt/death3";
		hdskin.gruntsound "grunt/active";
		hdskin.landsound "player/hdguy/land";
		hdskin.stepsound "cyber/walk";
		hdskin.stepsoundwet "cyber/hoof";
		hdskin.medsound "grunt/pain";
		hdskin.gibbedsound "player/hdguy/taunt";//"misc/gibbed";
		deathsound "grunt/death";
		painsound "grunt/pain";
		hdskin.mug "STC";
		bloodcolor "ff cc 22";
xscale 0.4;
yscale 1.3;
hdskin.maxvpitch 2.;
hdskin.minvpitch 2.;
	}
	states{
	spawn:crouch:POSS A 0;stop;
	fist:PUNC A 0;stop;
	}
}



/*
//example syntax for a custom skin
//assets not included
class HDQuakeSkin:HDSkin{
	default{
		hdskin.tauntsound "player/quakeguy/taunt";
		hdskin.xdeathsound "player/quakeguy/xdeath";
		hdskin.gruntsound "player/quakeguy/grunt";
		hdskin.landsound "player/quakeguy/land";
		hdskin.medsound "player/quakeguy/meds";
		hdskin.gibbedsound "player/quakeguy/gibbed";
		hdskin.soundclass "quakeguy";
		deathsound "player/quakeguy/death";
		painsound "player/quakeguy/pain";
		//hdskin.mug "QGF";
	}
	states{
	spawn:QGUY A 0;stop;
	crouch:QGUY A 0;stop;
	fist:PUNG A 0;stop;
	}
}

//and a SNDINFO
player/quakeguy/taunt   dstauntm
player/quakeguy/xdeath  dsqdiehi
player/quakeguy/grunt   dsqnoway
player/quakeguy/land    dsland
$alias player/quakeguy/step humanoid/step
$alias player/quakeguy/squishstep humanoid/squishstep
player/quakeguy/meds    dsqpain
player/quakeguy/gibbed  dsqgib
player/quakeguy/death   dsqdeth
player/quakeguy/pain    dsqpain
*/

