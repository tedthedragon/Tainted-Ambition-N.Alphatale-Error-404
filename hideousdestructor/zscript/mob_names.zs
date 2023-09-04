// ------------------------------------------------------------
// Making up names.
// ------------------------------------------------------------
extend class HDMobBase{
	static string RandomName(int syls=0){
		static const string vwl[]={"a","i","u","e","o","y"};
		static const string cns[]={"p","t","k","f","c","s","b","d","g","th","v","z","kh","x","ph","h","j","l","n","m","r","ch","w","rh","y","kw","q","ts","ng","st","gh","bh","dh"};
		int vwlend=vwl.size()-1;
		int cnsend=cns.size()-1;

		if(syls<1)syls=random(2,5);

		string nnn="";
		bool hyphenated=false;
		bool hasheavy=false;

		for(int i=0;i<syls||nnn.length()<=3;i++){
			string newsyl=vwl[random(0,vwlend)];

			//onset
			if(random(0,2))newsyl=cns[random(0,random(0,cnsend))]..newsyl;

			//long nucleus
			if(!hasheavy){
				hasheavy=true;
				if(!random(0,4))newsyl=newsyl..vwl[random(0,vwlend)];
			}

			//coda
			if(!random(0,hasheavy?6:3))newsyl=newsyl..cns[random(0,cnsend)];

			//punctuation
			if(
				!hyphenated
				&&i
				&&!random(0,7)
			){
				newsyl="-"..newsyl.left(1).makeupper()..newsyl.mid(1);
				hyphenated=random(0,3);
			}

			nnn=nnn..newsyl;
		}
		nnn=nnn.left(1).makeupper()..nnn.mid(1);
		return nnn;
	}

	static string GenerateUserName(int flags=0){
		array<string>namebases;namebases.clear();
		string mmmn=Wads.ReadLump(Wads.CheckNumForName("opnames",0));
		mmmn.Replace("\r","");
		mmmn=mmmn.left(mmmn.indexof("\n---"));
		mmmn.split(namebases,"\n");

		string nnn;
		int nbs=namebases.size()-1;
		do{
			if(
				flags&SNN_RECURSING
				||!random(0,15)
			)nnn=HDMobBase.RandomName(random(1,SNN_RECURSING?5:3));
			else nnn=namebases[random(0,nbs)];
		}
		while(nnn=="");


		//titles
		if(!random(0,3)){
			array<string>titles;titles.clear();
			string titleset=Wads.ReadLump(Wads.CheckNumForName("opnames",0));
			titleset.Replace("\r","");

			//there are three sections and we want the middle one
			titleset=titleset.mid(titleset.indexof("\n---")+5);
			titleset=titleset.left(titleset.indexof("\n---"));

			titleset.split(titles,"\n");
			string title="";
			do{title=titles[random(0,titles.size()-1)];}
			while(title=="");

			title.replace("NNN",nnn);

			nnn=HDMath.BuildVariableString(title);
		}

		//1337sp34k
		if(!random(0,15)){
			if(random(0,2)){
				if(random(0,7))nnn.replace("E","3");
				nnn.replace("e","3");
			}
			if(random(0,2)){
				if(random(0,7))nnn.replace("A","4");
				nnn.replace("a","4");
			}
			if(random(0,2)){
				if(random(0,7))nnn.replace("O","0");
				nnn.replace("o","0");
			}
			if(random(0,2)){
				if(random(0,3))nnn.replace("I","1");
				nnn.replace("i","1");
			}
			if(!random(0,2)){
				if(random(0,7))nnn.replace("B","8");
				nnn.replace("b","8");
			}
			if(!random(0,2)){
				if(random(0,7))nnn.replace("G","6");
				nnn.replace("g","6");
			}
			if(random(0,7)){
				if(random(0,7))nnn.replace("S","5");
				nnn.replace("s","5");
			}
			if(!random(0,15)){
				if(!random(0,3))nnn.replace("T","+");
				nnn.replace("t","+");
			}else if(!random(0,7)){
				if(random(0,3))nnn.replace("T","7");
				nnn.replace("t","7");
			}

			nnn.replace(".3X3",".EXE");
		}

		//I can't believe I put this much effort into this
		if(!random(0,31)){
			string uuu=random(0,2)?"u":"o";

			//find all "u"s and pick one at random
			array<int> uposes;uposes.clear();
			int nnl=nnn.length();
			int upos=-1;
			do{
				upos=nnn.indexof(uuu,upos+1);
				if(upos>=0){
					uposes.push(upos);
				}
			}while(upos>=0);
			if(uposes.size()>0){
				upos=uposes[random(0,uposes.size()-1)];
				string preuwu=nnn.left(upos);
				string postuwu=nnn.mid(upos+1);
				if(!random(0,3))uuu=uuu.makeupper();
				nnn=preuwu..uuu.."w"..uuu..postuwu;
			}
		}

		//decorations
		if(!random(0,7)){
			array<string>titles;titles.clear();
			string titleset=Wads.ReadLump(Wads.CheckNumForName("opnames",0));
			titleset.Replace("\r","");
			titleset=titleset.mid(titleset.indexof("\n---")+5);
			titleset=titleset.mid(titleset.indexof("\n---")+5);
			if(titleset!=""){
				titleset.split(titles,"\n");
				do{
					string title="";
					do{title=titles[random(0,titles.size()-1)];}
					while(title=="");
					title.replace("NNN",nnn);
					nnn=title;
				}while(!random(0,15));
			}
		}

		if(!random(0,31))nnn=nnn.makeupper();
		else if(!random(0,15))nnn=nnn.makelower();

		if(!random(0,2)){
			nnn.replace(" ","");
			if(random(0,2))nnn.replace("-","");
		}
		if(!random(0,2))nnn.replace(" ","_");
		if(!random(0,2))nnn.replace("_","");

		return nnn;
	}
}
enum NicknameSetterFlags{
	SNN_RECURSING=1,
}


class RandomUsernames:ActionItem{
	default{inventory.maxamount 2;}
	states{
	pickup:
		TNT1 A 0{
			int which=invoker.amount;
			string sss=((which==2)?HDMobBase.RandomName():HDMobBase.GenerateUserName());
			for(int i=0;i<49;i++){
				sss=sss.."  "..((which==2)?HDMobBase.RandomName():HDMobBase.GenerateUserName());
			}
			A_Log(sss,true);
		}fail;
	}
}



