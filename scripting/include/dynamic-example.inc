#if defined _dynamic_class_myclass_
  #endinput
#endif
#define _dynamic_class_myclass_

methodmap MyClass < Dynamic
{
	public MyClass()
	{
		// First we make a new dymanic object
		Dynamic myclass = Dynamic(64, 0);

		// Next we will define all the members
		// -> We do this to force the offsets to always be in the same location
		//    over multiple instances of the same class.
		myclass.SetInt("SomeInt", 0);
		myclass.SetFloat("SomeFloat", 0.0);
		myclass.SetString("SomeString", "", 1024);

		return view_as<MyClass>(myclass);
	}

	// Note that I use static offsets to access members.
	// -> This improves performance by caching member offsets
	// -> This is why we force the members in during the contructor
	// -> Failure to force members in the constructor will cause corruption

	property int SomeInt
	{
		public get()
		{
			static int offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("SomeInt");
				if (offset == INVALID_DYNAMIC_OFFSET)
					return 0;
			}
			return this.GetIntByOffset(offset, 0);
		}
		public set(int value)
		{
			static int offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("SomeInt");
				if (offset == INVALID_DYNAMIC_OFFSET)
				{
					offset = this.SetInt("SomeInt", value);
					return;
				}
			}
			this.SetIntByOffset(offset, value);
		}
	}

	property float SomeFloat
	{
		public get()
		{
			static int offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("SomeFloat");
				if (offset == INVALID_DYNAMIC_OFFSET)
					return 0.0;
			}
			return this.GetFloatByOffset(offset, 0.0);
		}
		public set(float value)
		{
			static int offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("SomeFloat");
				if (offset == INVALID_DYNAMIC_OFFSET)
				{
					offset = this.SetFloat("SomeFloat", value);
					return;
				}
			}
			this.SetFloatByOffset(offset, value);
		}
	}

	public bool GetSomeString(char[] buffer, int length)
	{
		static int offset = INVALID_DYNAMIC_OFFSET;
		if (offset == INVALID_DYNAMIC_OFFSET)
		{
			offset = this.GetMemberOffset("SomeString");
			if (offset == INVALID_DYNAMIC_OFFSET)
				return false;
		}
		this.GetStringByOffset(offset, buffer, length);
		return true;
	}

	public void SetSomeString(const char[] buffer)
	{
		static int offset = INVALID_DYNAMIC_OFFSET;
		if (offset == INVALID_DYNAMIC_OFFSET)
		{
			offset = this.GetMemberOffset("SomeString");
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.SetString("SomeString", buffer);
				return;
			}
		}
		this.SetStringByOffset(offset, buffer);
	}
}