// ------------------------------------------------------------
// Backpack
// ------------------------------------------------------------
const HDCONST_BPMAX=1000;
const HDCONST_BPSPAWNPOOLEVENT=-500;

enum HDItemTypes
{
	IType_Invalid,
	IType_Weapon,
	IType_Mag,
	IType_Pickup
}

enum HDStorageItemActions{
	SIIAct_Extract,
	SIIAct_Pocket,
	SIIAct_Insert,
}


enum HDBackpackFlags
{
	BF_FROMCONSOLIDATE = 1,
	BF_SELECT = 1 << 1,
	BF_IGNORECAP = 1 << 2,
	BF_SILENT = 1 << 3
}

class BPSpawnPool : EventHandler {
	private Array<class <Inventory> > ValidItems;
	private bool Initialized;

	override void OnRegister() {
		// Ideally this should have the event handler run BEFORE any others.
		// Modders: Any event handlers meant to run at world load should have
		//          an order number of HDCONST_BPSPAWNPOOLEVENT+1 or higher!
		//          (default is zero so this should almost never be a problem)
		SetOrder(HDCONST_BPSPAWNPOOLEVENT);
		Initialized = false;
	}

	override void WorldLoaded(worldevent e) {
		BuildValidItemList();
	}

	private void BuildValidItemList() {
		if (ValidItems.Size() > 0) { return; } // don't rebuild
		Initialized = true;
		for (int i = 0; i < AllActorClasses.Size(); ++i) {
			let invitem = (class<Inventory>)(AllActorClasses[i]);
			if (!invitem) { continue; }
			AddItem(invitem);
		}
	}

	// Runs all normal checks and adds the passed item class to the spawn pool.
	//   Returns TRUE if the item class was successfully added.
	//   Returns FALSE if the item class could not be added.
	static bool AddItem(class<Inventory> cls) {
		BPSpawnPool sp = BPSpawnPool(EventHandler.Find("BPSpawnPool"));
		if (!(sp && sp.Initialized)) { console.printf("\cgAddItem(): Backpack spawn pool not found or initialized!"); return false; }
		if (CheckNoRandomSpawn(cls)) { return false; }
		let tempSI = ItemStorage(new('ItemStorage'));
		if (tempSI.CheckConditions(null, cls) == IType_Invalid) { return false; }
		if (CheckItem(cls) != -1) {
			if (hd_debug) { console.printf(cls.GetClassName().." already in backpack spawn pool"); }
			return false;
		}
		// All checks passed
		sp.ValidItems.Push(cls);
		if (hd_debug) { console.printf("added "..cls.GetClassName().." to backpack spawn pool"); }
		return true;
	}

	// Removes an item class from the spawn pool if it exists.
	//   Returns TRUE if the item class was successfully removed.
	//   Returns FALSE if for some reason the removal failed.
	static bool RemoveItem(class<Inventory> cls) {
		BPSpawnPool sp = BPSpawnPool(EventHandler.Find("BPSpawnPool"));
		if (!(sp && sp.Initialized)) { console.printf("\cgRemoveItem(): Backpack spawn pool not found or initialized!"); return false; }
		int index = CheckItem(cls);
		if (index != -1) {
			sp.ValidItems.Delete(index);
			if (hd_debug) { console.printf("removed "..cls.GetClassName().." from backpack spawn pool"); }
			return true;
		}
		return false;
	}

	// Checks if an item class already exists in the spawn pool
	//   Returns ARRAY INDEX if the item class is found in the spawn pool
	//   Returns -1 if the item class is not found in the spawn pool
	static int CheckItem(class<Inventory> cls) {
		BPSpawnPool sp = BPSpawnPool(EventHandler.Find("BPSpawnPool"));
		if (!(sp && sp.Initialized)) { console.printf("\cgCheckItem(): Backpack spawn pool not found or initialized!"); return false; }
		for (int i=0; i<sp.ValidItems.Size(); i++) {
			if (sp.ValidItems[i] is cls) { return i; }
		}
		return -1;
	}

	// Returns TRUE if the item class has bNoRandomBackpackSpawn set
	private static bool CheckNoRandomSpawn(class<Inventory> cls) {
		return(
			((class<HDPickup>)(cls)
			&&getdefaultbytype((class<HDPickup>)(cls)).bNoRandomBackpackSpawn
			)
			||(
				(class<HDWeapon>)(cls)
				&&getdefaultbytype((class<HDWeapon>)(cls)).bNoRandomBackpackSpawn
			));
	}

	// Returns a random valid item class from the backpack spawn pool.
	static class<Inventory> GetValidItem() {
		BPSpawnPool sp = BPSpawnPool(EventHandler.Find("BPSpawnPool"));
		if (!(sp && sp.Initialized)) { console.printf("\cgGetValidItem(): Backpack spawn pool not found or initialized!"); return null; }
		if (sp.ValidItems.Size() <= 0) { console.printf("\cgGetValidItem(): Backpack spawn pool empty!"); return null; }
		return sp.ValidItems[random(0, sp.ValidItems.Size() - 1)];;
	}
}


//One of these represents one class of items found in a backpack.
class StorageItem play{
	Inventory InvRef;  //the equivalent item actor in your "real" inventory
	class<Inventory> ItemClass;
	string NiceName;
	string RefId;
	Array<string> Icons;
	Array<double> Bulks;
	Array<int> Amounts; // [Ace] Only one element (index 0) is used for singular items.
	Array<int> WeaponStatus; // [Ace] Every HDWEP_STATUSSLOTS starts a new weapon.

	clearscope double GetBulk(){
		double Total = 0;
		for(int i=0;i<Bulks.Size();++i){
			Total += Bulks[i];
		}
		return Total;
	}
	clearscope bool HaveNone(){
		return
			Amounts.Size()==0
			||(
				!(ItemClass is 'HDMagAmmo')
				&&Amounts[0]==0
			)
		;
	}
	clearscope string ToLoadoutCode(bool verbose=false){
		string ret=refid;
		if(verbose){
			for(int i=0;i<amounts.Size();++i){
				ret=ret.." "..amounts[i];
			}
		}else ret=ret.." "..amounts.size();
		return ret;
	}
}

//This is the struct that contains the backpack's contents.
class ItemStorage play
{
	double TotalBulk;
	double MaxBulk;
	int SelItemIndex;
	Array<StorageItem> Items;

	clearscope StorageItem Find(class<Inventory> item){
		if(!item)return null;
		for (int i = 0; i < Items.Size(); ++i)
		{
			if(Items[i].ItemClass==item)return Items[i];
		}
		return null;
	}

	void PrevItem(){
		SelItemIndex--;
		if(SelItemIndex<0)SelItemIndex=Items.Size()-1;
	}
	void NextItem(){
		SelItemIndex++;
		if(SelItemIndex>=Items.Size())SelItemIndex=0;
	}
	void ClampIndex(){
		SelItemIndex=clamp(SelItemIndex,0,max(0,Items.Size()-1));
	}

	clearscope StorageItem GetSelectedItem(){
		int iss=Items.Size();
		if(
			iss>0
			&&SelItemIndex<=iss
		)return Items[SelItemIndex];
		return null;
	}

	// [Ace] Can also be used as "ClassifyItem". Multiuse!
	// Fallback to cls if the reference is null.
	// Extendable if more conditions need to be added later on.
	virtual clearscope int CheckConditions(
		Inventory item,
		class<Inventory> cls=null
	){
		if (item)
		{
			let wpn = HDWeapon(item);
			let mag = HDMagAmmo(item);
			let pkp = HDPickup(item);

			if(
				item.bNOINTERACTION
				||item.bUNDROPPABLE
				||item.bUNTOSSABLE
				||(
					//container that is in use
					item is 'HDBackpack'
					&&HDBackpack(item).Storage
					&&HDBackpack(item).Storage.TotalBulk>0
				)||(
					//pickup that does not fit in backpack
					pkp
					&&!pkp.bFITSINBACKPACK
				)
			)return IType_Invalid;

			//some exceptions only apply to weapons
			if(
				wpn
				&&wpn.bFITSINBACKPACK
				&&!wpn.bCHEATNOTWEAPON
			)return IType_Weapon;

			if(mag)return IType_Mag;
			if(pkp)return IType_Pickup;
		}
		else if (cls)
		{
			let dls=GetDefaultByType((class<Inventory>)(cls));
			let wpn = cls is 'HDWeapon' ? GetDefaultByType((class<HDWeapon>)(cls)) : null;
			let mag = cls is 'HDMagAmmo' ? GetDefaultByType((class<HDMagAmmo>)(cls)) : null;
			let pkp = cls is 'HDPickup' ? GetDefaultByType((class<HDPickup>)(cls)) : null;

			if(
				dls.bNOINTERACTION
				||dls.bUNDROPPABLE
				||dls.bUNTOSSABLE
				||dls.GetTag()==dls.GetClassName()
				||(
					pkp
					&&!pkp.bFITSINBACKPACK
				)
			)return IType_Invalid;

			if(
				wpn
				&&!wpn.bCHEATNOTWEAPON
				&&wpn.bFITSINBACKPACK
			)return IType_Weapon;

			if(mag)return IType_Mag;
			if(pkp)return IType_Pickup;
		}

		return IType_Invalid;
	}

	virtual clearscope int GetOperationSpeed(
		class<Inventory> item,
		int operation
	){
		let wpn = (class<HDWeapon>)(item);
		let pkp = (class<HDPickup>)(item);
		bool multipickup=pkp && GetDefaultByType(pkp).bMULTIPICKUP;
		switch (operation){
		case SIIAct_Extract:return wpn ? 10 : multipickup ? 3 : 6;
		case SIIAct_Pocket:return wpn ? 12 : multipickup ? 3 : 8;
		case SIIAct_Insert:return wpn ? 14 : multipickup ? 2 : 10;
		default:break;
		}
		return 10;
	}

	virtual clearscope string GetIcon(Inventory item)
	{
		int Type = CheckConditions(item);
		if (Type == IType_Invalid)return "";

		string Icon = "";
		let wpn = HDWeapon(item);
		let mag = HDMagAmmo(item);

		if(
			!mag
			||mag.Mags.Size()>0
		)switch (Type){
		case IType_Weapon:
			Icon = wpn.GetPickupSprite(); break;
		case IType_Mag:
			Icon = mag.GetMagSprite(mag.Mags[mag.Mags.Size() - 1]); break;
		}

		// [Ace] Still empty? Fallback time.
		if (Icon == "")
		{
			Icon = TexMan.GetName(item.Icon);
			if (Icon == "") // [Ace] Persistent bastard, aren't ya?
			{
				Icon = TexMan.GetName(item.SpawnState.GetSpriteTexture(0));
			}
		}

		return Icon;
	}

	virtual string GetFailMessage() const
	{
		return Stringtable.Localize("$BACKPACK_TOOFULL");
	}

	// [Ace] The difference between AddAmount and TryInsertItem is that AddAmount can be used to create items out of thin air.
	// It can also remove items.
	// Same return as TryInsertItem.
	virtual int AddAmount(class<Inventory> item, int amt, int flags = BF_IGNORECAP)
	{
		int Inserted = 0;

		if (amt >= 0)
		{
			for (int i = 0; i < amt; i++)
			{
				let itb = HDBackpack.SpawnAndConfigure(item);
				Inserted += TryInsertItem(itb, null, flags: flags);
				if (itb) itb.Destroy();
			}
		}
		else
		{
			StorageItem si = Find(item);
			if (si) RemoveItem(si, null, null, -amt, flags: flags);
		}

		return Inserted;
	}

	virtual clearscope int GetAmount(class<Inventory> item)
	{
		StorageItem si = Find(item);
		if (si)
		{
			int Size = si.Amounts.Size();
			if (si.ItemClass is 'HDMagAmmo')
			{
				return Size;
			}
			else if ((si.ItemClass is 'HDWeapon' || si.ItemClass is 'HDPickup') && Size > 0)
			{
				return si.Amounts[0];
			}
		}
		return 0;
	}

	// [Ace] noInsert means the item is only added temporarily and will be removed the next time RemoveNullOrEmpty is called.
	// Assuming you also don't have the item on you.
	// That argument is used to populate the list with all items that are potentially backpackable when you open the backpack interface.
	// Returns the number of items inserted.
	virtual int TryInsertItem(
		Inventory item,
		Actor inserter,
		int amt = 1,
		int index = -1,
		bool noInsert = false,
		int flags = 0
	){

		if(!item)return 0;

		int Type = CheckConditions(item);
		if (Type == IType_Invalid)return 0;

		StorageItem si = Find(item.GetClass());
		if (!si)
		{
			si = new('StorageItem');
			Items.Insert(0, si);
		}

		if (flags & BF_SELECT)
		{
			SelItemIndex = Items.Find(si);
		}

		si.ItemClass = item.GetClass();
		si.NiceName = item.GetTag();
		si.InvRef = item;
		string Icon = GetIcon(item);

		// [Ace] Only insert the icon for the purpose of displaying the item if it's not in the backpack yet.
		if (si.Icons.Size() == 0)
		{
			si.Icons.Push(Icon);
		}
		// [Ace] But do update it if a new item is inserted and you have none in the backpack.
		// Otherwise you can end up inserting a full mag and retaining the previous empty mag icon.
		else if (si.HaveNone())
		{
			si.Icons[0] = Icon;
		}

		if (noInsert)
		{
			return 0;
		}

		let wpn = HDWeapon(item);
		let mag = HDMagAmmo(item);
		let pkp = HDPickup(item);

		int RetVal = 0;
		switch (Type)
		{
			case IType_Weapon:
				double WpnBulk = wpn.WeaponBulk();
				if (!(flags & BF_IGNORECAP) && TotalBulk + WpnBulk >= MaxBulk)
				{
					if (inserter)
					{
						inserter.A_Log(GetFailMessage(), true);
					}
					break;
				}
				si.RefId = wpn.RefId;
				if (index < 0)
				{
					index = si.Bulks.Size();
				}
				if (si.Amounts.Size() > 0 && si.Amounts[0] > 0) // [Ace] An icon already exists for preview purposes. Don't bother adding another one for the first element.
				{
					si.Icons.Insert(index, Icon);
				}
				for (int i = 0; i < HDWEP_STATUSSLOTS; ++i)
				{
					si.WeaponStatus.Insert(HDWEP_STATUSSLOTS * index + i, wpn.WeaponStatus[i]);
				}
				if (wpn.owner)
				{
					inserter = wpn.owner;
					wpn = HDWeapon(wpn.CreateTossable()); // detach from the owner and get a spare ready. DropInventory must not be used here, as the weapon's OnDrop would cause the list to be updated (and pruned!) prematurely resulting in the weapon being deleted.
					si.InvRef = inserter.FindInventory(wpn.GetClass()); // [Ace] Set the reference to the next weapon in your inventory.
				}
				si.Bulks.Insert(index, WpnBulk);
				si.Amounts.Resize(1);
				si.Amounts[0]++;
				wpn.Amount--;
				TotalBulk += WpnBulk;
				RetVal++;
				if (wpn.Amount == 0)
				{
					wpn.Destroy();
				}
				break;

			case IType_Mag:
				int MagCount = mag.Mags.Size();
				si.RefId = mag.RefId;
				for (int i = 0; i < min(amt, MagCount); ++i)
				{
					int mms=mag.Mags.Size();
					double MagBulk = mag.getbulkonemag(mms>=1?mms-1:mag.MaxPerUnit);
					if (MagBulk ~== 0)
					{
						MagBulk = mag.Bulk;
					}
					if (!(flags & BF_IGNORECAP) && TotalBulk + MagBulk >= MaxBulk)
					{
						if (inserter)
						{
							inserter.A_Log(GetFailMessage(), true);
						}
						break;
					}
					if (index < 0)
					{
						index = si.Amounts.Size();
					}
					if (si.Amounts.Size() > 0)
					{
						// [Ace] Gotta fetch the icon for the current magazine in the iteration.
						// The code near the top only does it for the very first inserted mag.
						si.Icons.Insert(index, GetIcon(mag));
					}
					si.Bulks.Insert(index, MagBulk);
					si.Amounts.Insert(index, mag.TakeMag(false));
					TotalBulk += MagBulk;
					RetVal++;
					if (mag.Amount == 0)
					{
						mag.Destroy();
						break;
					}
				}
				break;
			case IType_Pickup:
				int InsAmt = min(amt, pkp.Amount);
				si.RefId = pkp.RefId;
				for (int i = 0; i < InsAmt; ++i)
				{
					if (!(flags & BF_IGNORECAP) && TotalBulk + pkp.Bulk >= MaxBulk)
					{
						if (inserter)
						{
							inserter.A_Log(GetFailMessage(), true);
						}
						break;
					}
					si.Icons.Resize(1);
					si.Icons[0] = Icon;
					si.Bulks.Resize(1);
					si.Bulks[0] += pkp.Bulk;
					si.Amounts.Resize(1);
					si.Amounts[0]++;
					pkp.Amount--;
					TotalBulk += pkp.Bulk;
					RetVal++;
					if (pkp.Amount == 0)
					{
						pkp.Destroy();
						break;
					}
				}
				break;
		}

		ClampIndex();
		CalculateBulk(); // [Ace] Shouldn't really be necessary anymore, but let's do it just in case.
		return RetVal;
	}

	bool DestroyItem(class<Inventory> item){
		StorageItem si = Find(item);
		if(si){
			RemoveItem(si, null, null, int.Max);
			return true;
		}
		return false;
	}

	// [Ace] Null receiver means the item is dropped/spilled on the ground.
	// Null remover means <amt> amount of the item is destroyed from the backpack. Receiver is ignored.
	virtual Inventory RemoveItem(StorageItem item, Actor remover, Actor receiver, int amt = 1, int index = 0, int flags = 0)
	{
		if (!item || item.Amounts.Size() == 0 || amt < 1)
		{
			return null;
		}

		let wpn = (class<HDWeapon>)(item.ItemClass);
		let mag = (class<HDMagAmmo>)(item.ItemClass);
		let pkp = (class<HDPickup>)(item.ItemClass);

		Inventory Spawned = null;
		vector3 SpawnPos = remover ? (remover.pos.x+5*cos(remover.angle),remover.pos.y+5*sin(remover.angle),remover.pos.z+remover.height*0.8) : (0, 0, 0);
		if (wpn)
		{
			index = min(index, item.Amounts.Size() - 1);
			amt = min(amt, item.Amounts[0]);
			for (int i = 0; i < amt; ++i)
			{
				if (remover)
				{
					Spawned = Inventory(Actor.Spawn(wpn, SpawnPos));
					HDWeapon newwpn = HDWeapon(Spawned);
					newwpn.bdontdefaultconfigure=true;
					for (int i = 0; i < HDWEP_STATUSSLOTS; ++i)
					{
						newwpn.WeaponStatus[i] = item.WeaponStatus[HDWEP_STATUSSLOTS * index + i];
					}
					if (receiver)
					{
						if (flags & BF_FROMCONSOLIDATE)
						{
							newwpn.AttachToOwner(receiver);
						}
						else
						{
							newwpn.ActualPickup(receiver, flags & BF_SILENT);
						}
					}
					if (newwpn.bDROPTRANSLATION)
					{
						newwpn.Translation = remover.Translation;
					}
				}
				item.WeaponStatus.Delete(HDWEP_STATUSSLOTS * index, HDWEP_STATUSSLOTS);
				if (item.Icons.Size() > 1) // [Ace] Don't delete the last icon. It is used for the preview.
				{
					item.Icons.Delete(index);
				}
				item.Bulks.Delete(index);
				item.Amounts[0]--;
				if (item.Amounts[0] == 0)
				{
					item.Amounts.Delete(0);
				}
			}
		}
		else if (mag)
		{
			index = min(index, item.Amounts.Size() - 1);
			amt = min(amt, item.Amounts.Size());
			for (int i = 0; i < amt; ++i)
			{
				if (remover)
				{
					Spawned = Inventory(Actor.Spawn(mag, SpawnPos));
					HDMagAmmo newmag = HDMagAmmo(Spawned);
					newmag.Mags[0]=item.Amounts[0];
					if (receiver)
					{
						newmag.ActualPickup(receiver, true);
					}
				}
				if (item.Icons.Size() > 1)
				{
					item.Icons.Delete(index);
				}
				item.Bulks.Delete(index);
				item.Amounts.Delete(index);
			}
		}
		else if (pkp)
		{
			amt = min(amt, item.Amounts[0]);
			if (remover)
			{
				Spawned = Inventory(Actor.Spawn(pkp, SpawnPos));
				HDPickup newpkp = HDPickup(Spawned);
				newpkp.Amount = amt;
				if (receiver)
				{
					newpkp.ActualPickup(receiver, true);
				}
			}
			item.Bulks[0] -= amt * GetDefaultByType(pkp).Bulk;
			item.Amounts[0] -= amt;
			if (item.Amounts[0] == 0)
			{
				item.Amounts.Delete(0);
			}
		}
		if(Spawned){
			Spawned.angle = remover.angle;
			Spawned.A_ChangeVelocity(1.5*cos(remover.pitch),0,1.-1.5*sin(remover.pitch),CVF_RELATIVE);
			Spawned.vel += remover.vel;
		}

		RemoveNullOrEmpty(remover);
		CalculateBulk();
		return Spawned;
	}


	virtual void CycleMag(StorageItem item,bool backwards=false){
		if(
			!item
			||item.Amounts.Size()<2
		)return;

		let mag=(class<HDMagAmmo>)(item.ItemClass);
		if(!mag)return;

		if(backwards){
			int index=item.Amounts.size()-1;
			item.Icons.insert(0,item.Icons[index]);
			item.Bulks.insert(0,item.Bulks[index]);
			item.Amounts.insert(0,item.Amounts[index]);

			index++;
			item.Icons.delete(index);
			item.Bulks.delete(index);
			item.Amounts.delete(index);
		}else{
			item.Icons.push(item.Icons[0]);
			item.Bulks.push(item.Bulks[0]);
			item.Amounts.push(item.Amounts[0]);

			item.Icons.delete(0);
			item.Bulks.delete(0);
			item.Amounts.delete(0);
		}
		CalculateBulk();
	}



	virtual void Consolidate(Actor owner){
		// [Ace] Items don't magically move themselves themselves, y'know.
		if(!owner)return;

		for (int i = 0; i < Items.Size(); ++i)
		{
			if(Items[i].HaveNone())continue;

			StorageItem CurItem = Items[i];
			if (CurItem.ItemClass is 'HDWeapon')
			{
				// [Ace] This seems to work for *ERPs but I am not sure if it works properly for everything due to how weapons are stored.
				for (int j = 0; CurItem.Amounts.Size( ) > 0 && j < CurItem.Amounts[0]; ++j)
				{
					let wpn = HDWeapon(RemoveItem(CurItem, owner, owner, flags: BF_FROMCONSOLIDATE | BF_SILENT));

					wpn.Consolidate();
					TryInsertItem(wpn, owner, flags: BF_IGNORECAP | BF_SILENT);
				}
			}
			else if(
				CurItem.ItemClass is 'HDPickup'
				&&(
					CurItem.ItemClass is 'HDMagAmmo'
					||!(CurItem.ItemClass is 'HDAmmo')
				)
			){
				HDPickup Ref = HDPickup(owner.FindInventory(CurItem.ItemClass));
				int OnPerson = 0;
				if (Ref)
				{
					OnPerson = Ref is 'HDMagAmmo' ? HDMagAmmo(Ref).Mags.Size() : Ref.Amount;
				}
				RemoveItem(CurItem, owner, owner, int.Max, flags: BF_FROMCONSOLIDATE);
				Ref = HDPickup(owner.FindInventory(CurItem.ItemClass)); // [Ace] There should definitely be a ref now.
				if (Ref)
				{
					Ref.Consolidate();
					TryInsertItem(ref, owner, int.Max, flags: BF_IGNORECAP);
					if (OnPerson > 0)
					{
						RemoveItem(CurItem, owner, owner, OnPerson, flags: BF_FROMCONSOLIDATE);
					}
				}
			}
		}
	}

	void CalculateBulk()
	{
		TotalBulk = 0;
		for (int i = 0; i < Items.Size(); ++i)
		{
			TotalBulk += Items[i].GetBulk();
		}
	}

	// [Ace] Owner is the person who is holding the storage. Usually the player.
	protected void RemoveNullOrEmpty(Actor owner){
		for (int i = 0; i < Items.Size();){
			if(!Items[i]){
				Items.Delete(i);
				continue;
			}

			bool deletethis=true;

			if(owner){
				// [Ace] Remove backpacks because you can always have only 1 on person so there's no point in showing it if you don't have one in the backpack either.
				let item = owner.FindInventory(Items[i].ItemClass);

				if(item is 'HDBackpack'){
					if(
						!HDBackpack(item).Storage
						||HDBackpack(item).Storage.TotalBulk<=0
					){
						deletethis=false;
					}
				}else if(
					item
					&&item.amount>0
				){
					deletethis=false;
				}
			}

			if(
				deletethis
				&&Items[i].Amounts.Size()==0
			){
				Items.Delete(i);
				continue;
			}
			i++;
		}
		ClampIndex();
	}

	void UpdateStorage(
		Inventory interface,
		Actor owner
	){
		if(owner){
			Inventory Next = owner.Inv;
			while(Next){
				// [Ace] Don't display the interface itself if it's the only item. You can't put it in itself anyway.
				if(Next==interface){
					Next=Next.Inv;
					continue;
				}
				TryInsertItem(Next,owner,noInsert:true);
				Next=Next.Inv;
			}
		}

		// [Ace] Just in case you dropped something or the storage has changed.
		// Not in the check because null owner has a purpose.
		RemoveNullOrEmpty(owner);
	}
}

class HDBackpack:HDWeapon{

	override void BeginPlay(){
		Super.BeginPlay();
		Storage = new('ItemStorage');
		UpdateCapacity();
	}

	protected action void A_UpdateStorage(){
		invoker.Storage.UpdateStorage(invoker, invoker.owner);
		invoker.UpdateCapacity();
	}

	protected virtual void UpdateCapacity(){
		MaxCapacity = default.MaxCapacity;
		Storage.MaxBulk = MaxCapacity;
	}

	override Inventory CreateTossable(int amt){
		Storage.UpdateStorage(self, null);
		if(
			!player
			||player.ReadyWeapon!=self
		){
			return Super.CreateTossable(amt);
		}
		if(!HDPlayerPawn.CheckStrip(owner,self)){
			return null;
		}
		return Super.CreateTossable(amt);
	}

	override bool IsBeingWorn() { return true; }
	override string, double GetPickupSprite() { return "BPAKA0", 1.0; }
	override double WeaponBulk() { return max((Storage ? Storage.TotalBulk * 0.70 : 0), 100); }
	override int DisplayAmount() { return int(Storage.TotalBulk); }
	override int GetSbarNum(){
		int Percent = 0;
		if (Storage.MaxBulk > 0)
		{
			Percent = int(Storage.TotalBulk * 100 / Storage.MaxBulk);
		}
		let sb = HDStatusBar(StatusBar);
		if (sb)
		{
			if (Percent > 80)
			{
				sb.savedcolour = Font.CR_RED;
			}
			else if (Percent > 60)
			{
				sb.savedcolour = Font.CR_YELLOW;
			}
			else if (Percent > 0)
			{
				sb.savedcolour = Font.CR_WHITE;
			}
		}
		return Percent;
	}
	override string GetHelpText(){
		let sss=Storage.GetSelectedItem();
		bool ssss=sss&&sss.ItemClass&&sss.ItemClass is "HDMagAmmo";
		LocalizeHelp();
		return LWPHELP_FIRE.."/"..LWPHELP_ALTFIRE..StringTable.Localize("$BPWH_PNI")
		..(
			ssss?
			LWPHELP_ZOOM.."+"..LWPHELP_FIRE.."/"..LWPHELP_ALTFIRE..StringTable.Localize("$BPWH_ZPF")
			:""
		)
		..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN..StringTable.Localize("$BPWH_FMODPUD")
		..LWPHELP_RELOAD..StringTable.Localize("$BPWH_RELOAD")
		..LWPHELP_UNLOAD..StringTable.Localize("$BPWH_UNLOAD")
		..LWPHELP_DROPONE..StringTable.Localize("$BPWH_DROPO")
		..LWPHELP_ALTRELOAD..StringTable.Localize("$BPWH_ALTRELOAD");
	}

	//configure from loadout
	//syntax: bak item1. item2. item3 (basically use dots instead of commas)
	override void LoadoutConfigure(string input){
		input.Replace(".", ",");
		if(hd_debug)
		{
			console.printf("Backpack Loadout: "..input);
		}
		InitializeAmount(input);
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			StorageItem si = Storage.GetSelectedItem();
			if (si)
			{
				amt=clamp(amt,1,10);
				int DropAmt=
					si.ItemClass is "HDPickup"
					&&GetDefaultByType((class<HDPickup>)(si.ItemClass)).bMULTIPICKUP
				?int(max(1,ENC_426MAG/GetDefaultByType((class<HDPickup>)(si.ItemClass)).bulk))
				:1;

				Storage.RemoveItem(si, owner, null, DropAmt * amt);
			}
		}
	}

	override void DefaultConfigure(PlayerInfo whichplayer, string weapondefaults)
	{
		if (whichplayer)
		{
			weapondefaults = HDWeapon.GetDefaultCVar(whichplayer);
		}
		else
		{
			StoreWeaponDefaults = "";
		}

		if (weapondefaults == "")
		{
			return;
		}

		weapondefaults.Replace(" ", "");
		StoreWeaponDefaults = weapondefaults.MakeLower();
	}

	// [Ace] This static should probably be moved elsewhere.
	static class<Inventory> FindByRefId(string id)
	{
		for (int i = 0; i < AllActorClasses.Size(); ++i)
		{
			let wpn = (class<HDWeapon>)(AllActorClasses[i]);
			let pkp = (class<HDPickup>)(AllActorClasses[i]);
			if (wpn && GetDefaultByType(wpn).RefId ~== id)
			{
				return wpn;
			}
			else if (pkp && GetDefaultByType(pkp).RefId ~== id)
			{
				return pkp;
			}
		}

		return null;
	}

	static Inventory SpawnAndConfigure(class<Inventory> item, string cfg1 = "", string cfg2 = "")
	{
		if (!item)
		{
			return null;
		}

		if (item is 'HDWeapon')
		{
			let wpn = HDWeapon(Spawn(item));
			wpn.LoadoutConfigure(cfg1);
			wpn.LoadoutConfigure(cfg2);
			return wpn;
		}
		if (item is 'HDWeaponGiver')
		{
			let wpng = HDWeaponGiver(Spawn(item));
			wpng.SpawnActualWeapon();
			wpng.ActualWeapon.LoadoutConfigure(cfg1);
			wpng.ActualWeapon.LoadoutConfigure(cfg2);
			return wpng.ActualWeapon;
		}

		Inventory Spawned = null;
		if (item is 'HDPickupGiver')
		{
			let pkpg = HDPickupGiver(Spawn(item));
			pkpg.SpawnActualItem();
			pkpg.ActualItem.LoadoutConfigure(cfg1);
			pkpg.ActualItem.LoadoutConfigure(cfg2);
			Spawned = pkpg.ActualItem;
		}

		if (!Spawned) Spawned = Inventory(Spawn(item));
		if (HDMagAmmo(Spawned))
		{
			HDMagAmmo(Spawned).SyncAmount();
		}

		return Spawned;
	}

	virtual void InitializeAmount(string loadlist){
		Array<string> LItems;
		loadlist.Replace(" ", "");
		loadlist.Split(LItems, ",");
		for (int i = 0; i < LItems.Size(); ++i)
		{
			string config = LItems[i].Mid(3, LItems[i].Length());
			LItems[i] = LItems[i].Left(3);

			class<Inventory> cls = FindByRefId(LItems[i]);
			if (!cls)
			{
				continue;
			}

			for (int j = 0; j < max(1, config.ToInt()); ++j)
			{
				let Spawned = SpawnAndConfigure(cls, StoreWeaponDefaults, config);
				Storage.TryInsertItem(Spawned, null, flags: BF_IGNORECAP);
			}
		}
	}

	virtual void RandomContents(bool clear = false){
		if (clear){
			Storage.Destroy();
			Storage = new('ItemStorage');
			UpdateCapacity();
		}

		if (hd_debug)A_Log("\n*  Backpack:  *");

		int MaxItems = clamp(int(7 * hd_encumbrance), 1, 7);
		for(int i = 0; i < MaxItems; ++i){
			int amt;
			class<Inventory> Picked = BPSpawnPool.GetValidItem();
			switch(Storage.CheckConditions(null, Picked)){
				case IType_Weapon:
					amt = 1;
					Storage.AddAmount(Picked, amt, flags: 0);
					break;
				case IType_Mag:
					let mag = GetDefaultByType((class<HDMagAmmo>)(Picked));
					amt = int(min(random(1, random(1, 20)), mag.MaxAmount, MaxCapacity / (max(1.0, mag.RoundBulk) * max(1.0, mag.MagBulk) * 5)));
					Storage.AddAmount(Picked, amt, flags: 0);
					break;
				case IType_Pickup:
					let pkp = GetDefaultByType((class<HDPickup>)(Picked));
					amt = int(min(random(1, pkp.bMULTIPICKUP ? random(1, 80) : random(1, random(1, 20))), pkp.MaxAmount, MaxCapacity / (max(1.0, pkp.bulk) * 5.0)));
					if (pkp.RefId == "")
					{
						amt = random(-2, amt);
					}
					if (amt > 0)
					{
						Storage.AddAmount(Picked, amt, flags: 0);
					}
					break;
			}
			if(hd_debug)A_Log(Picked.GetClassName().."  "..amt);
		}
	}

	virtual bool CanGrabInsert(Inventory item, class<Inventory> cls, Actor inserter){return true;}

	override void Consolidate(){Storage.Consolidate(owner);}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl){
		int BaseOffset = -80;

		sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_TOP"), (0, BaseOffset), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);
		sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_TOTALBULK")..int(Storage.TotalBulk).."\c-", (0, BaseOffset + 10), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);

		int ItemCount = Storage.Items.Size();

		if(!ItemCount){
			sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_NOITEMS"), (0, BaseOffset + 30), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_DARKGRAY);
			return;
		}

		StorageItem SelItem = Storage.GetSelectedItem();
		if(!SelItem)return;

		for(int i = 0; i < (ItemCount > 1 ? 5 : 1); ++i){
			int RealIndex = (Storage.SelItemIndex + (i - 2)) % ItemCount;
			if (RealIndex < 0)
			{
				RealIndex = ItemCount - abs(RealIndex);
			}

			vector2 Offset = ItemCount > 1 ? (-100, 8) : (0, 0);
			switch (i)
			{
				case 1: Offset = (-50, 4);  break;
				case 2: Offset = (0, 0); break;
				case 3: Offset = (50, 4); break;
				case 4: Offset = (100, 8); break;
			}

			StorageItem CurItem = Storage.Items[RealIndex];
			bool CenterItem = Offset ~== (0, 0);
			sb.DrawImage(CurItem.Icons[0], (Offset.x, BaseOffset + 40 + Offset.y), sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, CenterItem && !CurItem.HaveNone() ? 1.0 : 0.6, CenterItem ? (50, 30) : (30, 20), getdefaultbytype(CurItem.ItemClass).scale*(CenterItem?4.0:3.0));
		}

		sb.DrawString(sb.pSmallFont, SelItem.NiceName, (0, BaseOffset + 60), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_FIRE);

		int AmountInBackpack = SelItem.ItemClass is 'HDMagAmmo' ? SelItem.Amounts.Size() : (SelItem.Amounts.Size() > 0 ? SelItem.Amounts[0] : 0);
		sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_INBAG")..sb.FormatNumber(AmountInBackpack, 1, 6), (0, BaseOffset + 70), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountInBackpack > 0 ? Font.CR_BROWN : Font.CR_DARKBROWN);

		int AmountOnPerson = GetAmountOnPerson(hpl.FindInventory(SelItem.ItemClass));
		sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_ONPERSON")..sb.FormatNumber(AmountOnPerson, 1, 6), (0, BaseOffset + 78), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountOnPerson > 0 ?  Font.CR_WHITE : Font.CR_DARKGRAY);

		// [Ace] Don't display the first item. It's already in the preview.
		if (SelItem.ItemClass is 'HDArmour')
		{
			for (int i = 1; i < SelItem.Amounts.Size(); ++i)
			{
				vector2 Off = (-140 + 35 * ((i - 1) % 8), BaseOffset + 110 + 35 * ((i - 1) / 8));
				sb.DrawImage(SelItem.Icons[i], Off, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, 1.0, (30, 20), (4.0, 4.0));
			}
		}
		else if (SelItem.ItemClass is 'HDMagAmmo' && !(SelItem.ItemClass is 'HDInjectorMaker'))
		{
			for (int i = 1; i < SelItem.Amounts.Size(); ++i)
			{
				vector2 Off = (-140 + 20 * ((i - 1) / 10) - 2 * ((i - 1) % 10), BaseOffset + 110 + 10 * ((i - 1) % 10));
				sb.DrawImage(SelItem.Icons[i], Off, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, 1.0, (16, 16), (4.0, 4.0));
			}
		}
		else if (SelItem.ItemClass is 'HDWeapon' && SelItem.Amounts.Size() > 0 && SelItem.Amounts[0] > 1)
		{
			for (int i = 1; i < SelItem.Amounts[0]; ++i)
			{
				vector2 Off = (-120 + 60 * ((i - 1) % 5), BaseOffset + 110 + 30 * ((i - 1) / 5));
				sb.DrawImage(SelItem.Icons[i], Off, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, 1.0, (50, 20), (4.0, 4.0));
			}
		}
	}

	clearscope int GetAmountOnPerson(Inventory item)
	{
		let wpn = HDWeapon(item);
		let pkp = HDPickup(item);

		return wpn ? wpn.ActualAmount : pkp ? pkp.Amount : 0;
	}

	action void A_NextItem(bool forwards=true){
		if(forwards)invoker.Storage.NextItem();
		else invoker.Storage.PrevItem();
	}

	protected action void A_BPReady()
	{
		if(pressinguse())invoker.A_SetHelpText();

		if (
			PressingAltReload()
			||invoker.Storage.TotalBulk>invoker.Storage.MaxBulk
		){
			StorageItem si=invoker.Storage.GetSelectedItem();
			int DropAmt=(
				(
					si
					&&si.ItemClass is "HDAmmo"
					&&GetDefaultByType((class<HDAmmo>)(si.ItemClass)).bMULTIPICKUP
				)
				? random(10,50) : 1
			);
			invoker.Storage.RemoveItem(si, self, null, DropAmt);
			if (invoker.Storage.TotalBulk ~== 0)
			{
				DropInventory(invoker);
				return;
			}
			si=invoker.Storage.GetSelectedItem();
			while(
				!si
				||si.HaveNone()
			){
				A_NextItem();
				si=invoker.Storage.GetSelectedItem();
			}
		}
		else if (PressingFiremode())
		{
			int InputAmount = GetMouseY(true);
			if (InputAmount != 0)
			{
				if (InputAmount < -5)
				{
					A_NextItem(false);
				}
				else if (InputAmount > 5)
				{
					A_NextItem();
				}
			}
		}
		else
		{
			invoker.RepeatTics--;
			A_WeaponReady(WRF_ALLOWUSER3);

			if (JustPressed(BT_ATTACK))
			{
				A_UpdateStorage();
				if(PressingZoom()){
					StorageItem SelItem = invoker.Storage.GetSelectedItem();
					invoker.Storage.CycleMag(SelItem);
				}else{
					A_NextItem(false);
				}
			}
			else if (JustPressed(BT_ALTATTACK))
			{
				A_UpdateStorage();
				if(PressingZoom()){
					StorageItem SelItem = invoker.Storage.GetSelectedItem();
					invoker.Storage.CycleMag(SelItem,true);
				}else{
					A_NextItem();
				}
			}

			if (invoker.RepeatTics <= 0)
			{
				if (PressingReload())
				{
					A_UpdateStorage();
					StorageItem SelItem = invoker.Storage.GetSelectedItem();
					if (SelItem)
					{
						invoker.Storage.TryInsertItem(SelItem.InvRef, self, index:0);
						invoker.RepeatTics = invoker.Storage.GetOperationSpeed(SelItem.ItemClass, true);
					}
				}
				else if (PressingUnload())
				{
					A_UpdateStorage();
					StorageItem SelItem = invoker.Storage.GetSelectedItem();
					if (SelItem)
					{
						invoker.Storage.RemoveItem(SelItem, self, self);
						invoker.RepeatTics = invoker.Storage.GetOperationSpeed(SelItem.ItemClass, false);
					}
				}
			}
		}
	}

	ItemStorage Storage;
	protected int RepeatTics;
	protected string StoreWeaponDefaults;

	double MaxCapacity;
	property MaxCapacity: MaxCapacity;


	//called from outside to force reset the interface if inventory is affected
	static void ForceUpdate(actor owner){
		if(!owner||!owner.player)return;
		let bp=HDBackpack(owner.player.readyweapon);
		if(bp&&bp.storage)bp.Storage.UpdateStorage(bp,owner);
	}


	Default{
		+INVENTORY.INVBAR
		+WEAPON.WIMPY_WEAPON
		+WEAPON.NO_AUTO_SWITCH
		+HDWEAPON.DROPTRANSLATION
		+HDWEAPON.FITSINBACKPACK
		+HDWEAPON.ALWAYSSHOWSTATUS
		+HDWEAPON.IGNORELOADOUTAMOUNT
		+hdweapon.hinderlegs
		Weapon.SelectionOrder 1010;
		Inventory.Icon "BPAKA0";
		Inventory.PickupMessage "$PICKUP_BACKPACK";
		Inventory.PickupSound "weapons/pocket";
		Tag "$TAG_BACKPACK";
		HDWeapon.RefId HDLD_BACKPAK;
		HDBackpack.MaxCapacity HDCONST_BPMAX;
		HDWeapon.wornlayer STRIP_BACKPACK;
	}
	States{
	Spawn:
		BPAK ABC -1 NoDelay{
			if (invoker.Storage.TotalBulk ~== 0)
			{
				frame = 1;
			}
			else if (target)
			{
				translation = target.translation;
				frame = 2;
			}
			invoker.bNO_AUTO_SWITCH = false;
		}
		Stop;
	Select0:
		TNT1 A 10{
			A_UpdateStorage(); // [Ace] Populates items.
			A_StartSound("weapons/pocket", CHAN_WEAPON);
			if (invoker.Storage.TotalBulk > (HDCONST_BPMAX * 0.7))
			{
				A_SetTics(20);
			}
		}
		TNT1 A 0 A_Raise(999);
		Wait;
	Deselect0:
		TNT1 A 0 A_Lower(999);
		Wait;
	Ready:
		TNT1 A 1 A_BPReady();
		Goto ReadyEnd;
	User3:
		TNT1 A 0{
			StorageItem si = invoker.Storage.GetSelectedItem();
			if (si && si.ItemClass is 'HDMagAmmo')
			{
				let mag = GetDefaultByType((class<HDMagAmmo>)(si.ItemClass));
				if(
					mag.MustShowInMagManager
					||mag.RoundType!=""
				){
					A_MagManager(mag.GetClassName());
				}else{
					A_SelectWeapon("PickupManager");
				}
			}else{
				A_SelectWeapon("PickupManager");
			}
		}
		Goto Ready;
	}
}

//semi-filled backpacks at random
class WildBackpack:IdleDummy replaces Backpack{
		//$Category "Items/Hideous Destructor/Gear"
		//$Title "Backpack (Random Spawn)"
		//$Sprite "BPAKC0"
	override void postbeginplay(){
		super.postbeginplay();
		let aaa=HDBackpack(spawn("HDBackpack",pos,ALLOW_REPLACE));
		aaa.RandomContents();
		HDF.TransferSpecials(self, aaa);
		destroy();
	}
}
