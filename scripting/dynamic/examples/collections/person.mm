#if defined _dynamic_methodmap_person_
  #endinput
#endif
#define _dynamic_methodmap_person_

/*
	This example demonstrates how to easily store data for your
	own methodmaps by inherting Dynamic
*/

methodmap Person < Dynamic
{
	public Person()
	{
		Dynamic person = Dynamic();
		return view_as<Person>(person);
	}
	
	property int Age
	{
		public get()
		{
			return this.GetInt("Age", 0);
		}
		public set(int value)
		{
			this.SetInt("Age", value);
		}
	}
	
	property float Height
	{
		public get()
		{
			return this.GetFloat("Height", 0.0);
		}
		public set(float value)
		{
			this.SetFloat("Height", value);
		}
	}
	
	property bool IsAlive
	{
		public get()
		{
			return this.GetBool("IsAlive", false);
		}
		public set(bool value)
		{
			this.SetBool("IsAlive", value);
		}
	}
	
	public bool GetName(char[] buffer, int length)
	{
		return this.GetString("Name", buffer, length);
	}
	
	public void SetName(const char[] buffer)
	{
		this.SetString("Name", buffer, 1024);
	}
}