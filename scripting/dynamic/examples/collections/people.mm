#if defined _dynamic_collection_people_
  #endinput
#endif
#define _dynamic_collection_people_

/*
	This example demonstrates how to easily create a collection
	methodmap by inheriting Dynamic.
*/

methodmap People < Dynamic
{
	public People()
	{
		Dynamic people = Dynamic();
		return view_as<People>(people);
	}
	
	public Dynamic Items(int index)
	{
		return this.GetObjectByIndex(index);
	}
	
	public int FindFreeIndex()
	{
		for (int i = 0; i < this.MemberCount; i++)
		{
			if (this.Items(i).IsValid)
				continue;
				
			return i;
		}
		return -1;
	}
	
	public int AddItem(Dynamic item, bool findfreeindex=true)
	{
		if (findfreeindex)
		{
			int freeindex = this.FindFreeIndex();
			if (freeindex != -1)
			{
				this.SetObjectByIndex(freeindex, item);
				return freeindex;
			}
		}

		return this.PushObject(item);
	}
	
	public void RemoveItem(Dynamic item)
	{
		if (!item.IsValid)
			return;
		
		item.Dispose();
	}
}
