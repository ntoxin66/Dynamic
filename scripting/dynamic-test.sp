#include <sourcemod>
#include <dynamic>

public Plugin myinfo =
{
	name = "Dynamic Test",
	author = "Neuro Toxin",
	description = "Benchmarks and Tests all Dynamic Object aspects",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

public void OnPluginStart()
{
    BenchmarkTest();
}

stock void BenchmarkTest()
{
	int objectcount = 1000;
	int membercount = 100; // must be a multiple of 4

	PrintToServer("[SM] Preparing benchmark Test...");
	Dynamic someoject;
	char membernames[100][DYNAMIC_MEMBERNAME_MAXLEN];
	int memberoffsets[100];
	char buffer[DYNAMIC_MEMBERNAME_MAXLEN];
	int ival; float fval; char sval[DYNAMIC_MEMBERNAME_MAXLEN];
	int offset;
    
	// Make member names
	for (int x = 0; x < membercount; x++)
	{
		Format(membernames[x], DYNAMIC_MEMBERNAME_MAXLEN, "m_Field_%d", x);
	}
	PrintToServer("[SM] Starting Benchmark Tests...");

	// Create objectcount objects with 100 fields in each
	float start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = Dynamic(16, 0);
		//someoject.HookChanges(OnDynamicMemberChanged);
	}
	PrintToServer("Created %d dynamic object(s) in %f second(s)", objectcount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 5; p++)
			{
				if (p == 1)
				{
					memberoffsets[x] = someoject.SetInt(membernames[x], x+i+p);
					x++;
				}
				else if (p==2)
				{
					memberoffsets[x] = someoject.SetFloat(membernames[x], float(x+i+p));
					x++;
				}
				else if (p==3)
				{
					memberoffsets[x] = someoject.SetBool(membernames[x], true);
					x++;
				}
				else if (p==4)
				{
					memberoffsets[x] = someoject.SetString(membernames[x], "Some nice string that has some data", 128);
				}
			}
		}
	}
	PrintToServer("Created %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 5; p++)
			{
				if (p == 1)
				{
					someoject.GetInt(membernames[x]);
					x++;
				}
				else if (p==2)
				{
					someoject.GetFloat(membernames[x]);
					x++;
				}
				else if (p==3)
				{
					someoject.GetBool(membernames[x]);
					x++;
				}
				else if (p==4)
				{
					someoject.GetString(membernames[x], buffer, sizeof(buffer));
				}
			}
		}
	}
	PrintToServer("Read %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 5; p++)
			{
				if (p == 1)
				{
					someoject.GetIntByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==2)
				{
					someoject.GetFloatByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==3)
				{
					someoject.GetBoolByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==4)
				{
					someoject.GetStringByOffset(memberoffsets[x], buffer, sizeof(buffer));
				}
			}
		}
	}
	PrintToServer("Read %d dynamic member(s) using offsets in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 5; p++)
			{
				ival = x+i+p;
				fval = float(x+i+p);

				if (p == 1)
				{
					if (someoject.GetInt(membernames[x]) != ival)
						PrintToServer("!! Member data INVALID! (Int)");
					if (someoject.GetFloat(membernames[x]) != fval)
						PrintToServer("!! Conversion error (Int2Float)");
					if (someoject.GetBool(membernames[x]) != true)
						PrintToServer("!! Conversion error (Int2Bool)");
	
					someoject.GetString(membernames[x], buffer, sizeof(buffer));
					IntToString(ival, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Int2String)");
					x++;
				}
				else if (p==2)
				{
					if (someoject.GetFloat(membernames[x]) != fval)
						PrintToServer("!! Member data INVALID! (Float)");
					if (someoject.GetInt(membernames[x]) != ival)
						PrintToServer("!! Conversion error (FloatToInt)");
					if (someoject.GetBool(membernames[x]) != true)
						PrintToServer("!! Conversion error (FloatToBool)");

					someoject.GetString(membernames[x], buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Float2String)");
					x++;
				}
				else if (p == 3)
				{
					if (someoject.GetBool(membernames[x]) != true)
						PrintToServer("!! Conversion error (Bool)");
					if (someoject.GetFloat(membernames[x]) != 1.0)
						PrintToServer("!! Member data INVALID! (BoolToFloat)");
					if (someoject.GetInt(membernames[x]) != 1)
						PrintToServer("!! Conversion error (BoolToInt)");
					

					someoject.GetString(membernames[x], buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, "True"))
						PrintToServer("!! Conversion error (Bool2String)");
					x++;
				}
				else if (p==4)
				{
					someoject.GetString(membernames[x], buffer, sizeof(buffer));
					if (!StrEqual(buffer, "Some nice string that has some data"))
						PrintToServer("!! Member data INVALID! (String)");
				}
			}
		}
	}
	PrintToServer("Verified %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 5; p++)
			{
				if (p == 1)
				{
					someoject.SetInt(membernames[x], x+i+p);
					x++;
				}
				else if (p==2)
				{
					someoject.SetFloat(membernames[x], float(x+i+p));
					x++;
				}
				else if (p==3)
				{
					someoject.SetBool(membernames[x], false);
					x++;
				}
				else if (p==4)
				{
					someoject.SetString(membernames[x], "Some nice string that has some data");
				}
			}
		}
	}
	PrintToServer("Updated %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 5; p++)
			{
				ival = x+i+p;
				fval = float(x+i+p);
				offset = someoject.GetMemberOffset(membernames[x]);

				if (p == 1)
				{
					if (someoject.GetIntByOffset(offset) != ival)
						PrintToServer("!! Member data INVALID! (Int)");
					if (someoject.GetFloatByOffset(offset) != fval)
						PrintToServer("!! Conversion error (Int2Float)");
					if (someoject.GetBoolByOffset(offset) != true)
						PrintToServer("!! Member data INVALID! (IntToBool)");

					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					IntToString(ival, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Int2String)");
					x++;
				}
				else if (p==2)
				{
					if (someoject.GetFloatByOffset(offset) != fval)
						PrintToServer("!! Member data INVALID! (Float)");
					if (someoject.GetIntByOffset(offset) != ival)
						PrintToServer("!! Conversion error (FloatToInt)");
					if (someoject.GetBoolByOffset(offset) != true)
						PrintToServer("!! Member data INVALID! (FloatToBool)");

					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Float2String)");
					x++;
				}
				else if (p==3)
				{
					if (someoject.GetBoolByOffset(offset) != false)
						PrintToServer("!! Member data INVALID! (Bool)");
					if (someoject.GetFloatByOffset(offset) != 0.0)
						PrintToServer("!! Member data INVALID! (BoolToFloat)");
					if (someoject.GetIntByOffset(offset) != 0)
						PrintToServer("!! Conversion error (BoolToInt)");
					
					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, "False"))
						PrintToServer("!! Conversion error (Bool2String)");
					x++;
				}
				else if (p==4)
				{
					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					if (!StrEqual(buffer, "Some nice string that has some data"))
						PrintToServer("!! Member data INVALID! (String)");
				}
			}
		}
	}
	PrintToServer("Offset verification with %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);
	
	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		someoject.Dispose();
	}
	PrintToServer("Disposed %d dynamic object(s) in %f second(s)", objectcount, GetEngineTime() - start);
}

public void OnDynamicMemberChanged(Dynamic obj, int offset, const char[] member, Dynamic_MemberType type)
{
	switch (type)
	{
		case DynamicType_Int:
		{
			PrintToServer("[%d] <int>obj.%s = %d", offset, member, obj.GetIntByOffset(offset));
		}		
		case DynamicType_Float:
		{
			PrintToServer("[%d] <float>obj.%s = %f", offset, member, obj.GetFloatByOffset(offset));
		}
		case DynamicType_String:
		{
			char somestring[64];
			obj.GetStringByOffset(offset, somestring, sizeof(somestring));
			PrintToServer("[%d] <string>obj.%s = '%s'", offset, member, somestring);
		}
	}
}
