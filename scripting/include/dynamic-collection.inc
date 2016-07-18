#if defined _dynamic_collection_included
  #endinput
#endif
#define _dynamic_collection_included

methodmap Collection < ArrayList
{
	public Collection()
	{
		return new ArrayList();
	}
	
	public void Dispose(bool disposemembers=false)
	{
		if (disposemembers)
		{
			int count = this.Length;
			Dynamic member;
			for (int i = 0; i < count; i++)
			{
				member = view_as<Dynamic>(i);
				if (!member.IsValid)
					continue;
					
				member.Dispose();
			}
		}
		
		CloseHandle(this);
	}
	
	public Dynamic Items(int index)
	{
		return this.Get(index);
	}
	
	property int Count
	{
		public get()
		{
			return this.Length;
		}
	}
	
	public int AddItem(Dynamic item)
	{
		this.Push(item);
	}
	
	public int FindItem(Dynamic item)
	{
		int count = this.Length;
		for (int i = 0; i < count; i++)
		{
			if (this.Get(i) == item)
				return i;
		}
		return -1;
	}
	
	public void RemoveItem(Dynamic item)
	{
		int index = this.FindItem(item);
		if (index == -1)
			return;
			
		this.Erase(index);
	}
}
