// ------------------------------------------------------------
// Helpful? tips???
// ------------------------------------------------------------
extend class hdplayerpawn{
	double specialtipalpha;
	string specialtip;
	static void gametip(actor caller,string message){
		let hdp=hdplayerpawn(caller);
		if(hdp)hdp.usegametip(message);
		else caller.A_Log(message,true);
	}
	void usegametip(string arbitrarystring){
		arbitrarystring.replace("\r","");
		arbitrarystring.replace("\n\n\n","\n");
		arbitrarystring.replace("\n\n","\n");
		specialtipalpha=1001.;
		specialtip=arbitrarystring;
	}
	static void massgametip(string arbitrarystring){
		for(int i=0;i<MAXPLAYERS;i++){
			let hdp=hdplayerpawn(players[i].mo);
			if(hdp)hdp.usegametip(arbitrarystring);
		}
	}
	void showgametip(){
		if(
			!player
			||!hd_helptext
			||!hd_helptext.getbool()
		)return;
		/*static const*/ string specialtips[]={
			StringTable.Localize("$TIP_TIP1"),//"Read the manual!\n(open the pk7 with 7Zip and look for \cdhd_manual.md\cu)",
			StringTable.Localize("$TIP_TIP2"),//"Hold \cdUse\cu to check what options are available for a given weapon.",
			StringTable.Localize("$TIP_TIP3"),//"Make sure you bind keys for \cdall weapon \"User\" buttons\cu\n\cdDrop Weapon\cu, \cdZoom\cu and \cdReload\cu!",
			StringTable.Localize("$TIP_TIP4"),//"Check the menu for additional keybinds unique to HD!",
			StringTable.Localize("$TIP_TIP5"),//"To stop bleeding, hit \cd9\cu or use the \cdmedikit\cu.\nThen, if needed, take off your armour\nby hitting \cdReload\cu.",
			StringTable.Localize("$TIP_TIP6"),//"Hold \cdJump\cu and move forwards into a ledge to try to clamber over it.",
			StringTable.Localize("$TIP_TIP7"),//"Hit \cdUser3\cu to access the magazine manager on most weapons.",
			StringTable.Localize("$TIP_TIP8"),//"Hit \cdUser4\cu to unload most weapons.",
			StringTable.Localize("$TIP_TIP9"),//"If you are carrying too much useless ammo,\nhit the \cdPurge Useless Ammo\cu key\nor use the \cdhd_purge\cu command.",
			StringTable.Localize("$TIP_TIP10"),//"\cvTr\caan\cjs ri\cagh\cvts\cu are human rights, the same way guns are weapons.\nIf you're having trouble with this, one stopgap measure\nis to think of this in the same way guns are loaded.",
			StringTable.Localize("$TIP_TIP11"),//"Hit \cdUse\cu on a ladder to start climbing, and again or \cdJump\cu to dismount.\nHit \cdJump\cu while \cdcrouching\cu to take down the ladder.",

			StringTable.Localize("$TIP_TIP12"),//"Your movement and turning affect your punches and grenades.\nGo to the range and practice!",
			StringTable.Localize("$TIP_TIP13"),//"Use stimpacks to slow down bleeding.",

			StringTable.Localize("$TIP_TIP14"),//"If the sight picture is getting in your way when you're on the move,\ntry changing the \cdhd_noscope\cu and \cdhd_sightbob\cu settings to taste.",
			StringTable.Localize("$TIP_TIP15"),//"Holding \cdZoom\cu will greatly stabilize your aim,\nand implicitly brace your weapon\nagainst nearby map geometry.",
			StringTable.Localize("$TIP_TIP16"),//"Hold \cdZoom\cu when firing an airburst rocket or grenade\nto prevent the airburst value from resetting.",
			StringTable.Localize("$TIP_TIP17"),//"Hit the \cdDrop One\cu key or use the \cdhd_dropone\cu command\nto drop a single unit of each ammo type used by your current weapon.",
			StringTable.Localize("$TIP_TIP18"),//"If you don't want the diving action when you hit \cdCrouch\cu while running,\nset \cdhd_noslide\cu to 1 or use the menu.",
			StringTable.Localize("$TIP_TIP19"),//"If you don't want \cdZoom\cu to make you lean,\nset \cdhd_nozoomlean\cu to true.",

			StringTable.Localize("$TIP_TIP20"),//"Set \cdfraglimit\cu to 100+ to enable HD's elimination mode.\nIn co-op, a positive fraglimit under 100\nalso serves as a lives limit.",
			StringTable.Localize("$TIP_TIP21"),//"Turn on \cdhd_pof\cu in co-op or teamplay for a one-life mode where\nyou can only be raised in the presence of all living teammates.",
			StringTable.Localize("$TIP_TIP22"),//"Turn on \cdhd_flagpole\cu in multiplayer to create an objective!\n(Move AWAY from the flagpole to program the flag.)",
			StringTable.Localize("$TIP_TIP23"),//"Turn on \cdhd_nobots\cu to cause the bots to be replaced by HD riflemen.",

			StringTable.Localize("$TIP_TIP24"),//"To remote activate a switch or door,\ntype \cdderp 555\cu to stick a D.E.R.P. on to it,\nthen \cdderp 556\cu to make it flick the switch.",
			StringTable.Localize("$TIP_TIP25"),//"Hold \cdZoom\cu and/or \cdUse\cu when you use the goggles to set the amplitude.\nBoth together decrements; \cdUse\cu alone increments.\n\cdZoom\cu alone toggles red/green mode.",

			StringTable.Localize("$TIP_TIP26"),//"If a downed monster is still twitching,\nthey may be able to recover and attack again.",

			StringTable.Localize("$TIP_TIP27")//"If a map contains a mandatory drop that is harmless\nin vanilla but absolutely cannot be survived in HD,\nit is socially acceptable to cheat past it with \cdiddqd\cu or \cdfly\cu."
		};
		int newtip=random[tiprand](0,specialtips.size()-1);

//		newtip=specialtips.size()-1;

		specialtip=StringTable.Localize("$TIP_TIP")..specialtips[newtip];
		specialtipalpha=1001.;
		A_Log(specialtip,true);
	}
}
