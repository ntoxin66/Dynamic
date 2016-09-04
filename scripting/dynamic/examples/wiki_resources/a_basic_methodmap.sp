#include <dynamic>
#pragma newdecls required
#pragma semicolon 1

methodmap MyPluginPlayerInfo < Dynamic
{
	public MyPluginPlayerInfo()
	{
		Dynamic playerinfo = Dynamic();
		return view_as<MyPluginPlayerInfo>(playerinfo);
	}
	
	property int Points
	{
		public get()
		{
			return this.GetInt("Points");
		}
		public set(int value)
		{
			this.SetInt("Points", value);
		}
	}
	
	property float KDR
	{
		public get()
		{
			return this.GetFloat("KDR");
		}
		public set(float value)
		{
			this.SetFloat("KDR", value);
		}
	}
	
	property int Rank
	{
		public get()
		{
			return this.GetInt("Rank");
		}
		public set(int value)
		{
			this.SetInt("Rank", value);
		}
	}
}

public void OnClientConnected(int client)
{
	MyPluginPlayerInfo playerinfo = MyPluginPlayerInfo();
	playerinfo.Points = 2217;
	playerinfo.KDR = 2.69;
	playerinfo.Rank = 1;
}