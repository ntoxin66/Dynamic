/**
 * =============================================================================
 * Dynamic for SourceMod (C)2016 Matthew J Dunn.   All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */
 
public void _Dynamic_SelfTest(any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientConnected(client))
		return;
		
	// Test offset alignments (initialisation offset vs findmemberoffset)
	
	// DynamicType_Int Test
	Dynamic test = Dynamic();
	if (!_Dynamic_IntTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Int test completed");
	
	// DynamicType_Float Test
	test.Reset();
	if (!_Dynamic_FloatTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Float test completed");
	
	// DynamicType_String Test
	test.Reset();
	if (!_Dynamic_StringTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_String test completed");
	
	// DynamicType_Bool Test
	test.Reset();
	if (!_Dynamic_BoolTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Bool test completed");
	
	// DynamicType_Object Test
	test.Reset();
	if (!_Dynamic_ObjectTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Object test completed");
	
	// DynamicType_Handle Test
	test.Reset();
	if (!_Dynamic_HandleTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Handle test completed");
	
	// DynamicType_Vector Test
	test.Reset();
	if (!_Dynamic_VectorTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Vector test completed");
	
	test.Dispose();
}
 
stock bool _Dynamic_IntTest(int client, Dynamic test)
{
	// Test value
	int value = GetRandomInt(0, 32000);
	
	// Offset test
	int offset = test.SetInt("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Int test
	if (test.GetInt("val") != value)
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x2");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Float test
	float fvalue = float(value);
	if (test.GetFloat("val") != fvalue)
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x3");
		PrintToConsole(client, "> %f should equal %f", test.GetFloat("val"), fvalue);
		return false;
	}
	test.SetFloat("val", fvalue);
	if (test.GetInt("val") != value)
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x4");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// String test
	char cvalue[2][16];
	if (!test.GetString("val", cvalue[0], sizeof(cvalue[])))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x5");
		PrintToConsole(client, "> Couldn't read int as string");
		return false;
	}
	IntToString(value, cvalue[1], sizeof(cvalue[]));
	if (!StrEqual(cvalue[0], cvalue[1]))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x6");
		PrintToConsole(client, "> '%s' should equal '%s'", cvalue[0], cvalue[1]);
		return false;
	}
	test.SetString("val", cvalue[1]);
	if (test.GetInt("val") != value)
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x7");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Object not supported - no test required
	
	// Boolean test
	test.SetInt("val", 0);
	if (test.GetBool("val"))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x8");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), false);
		return false;
	}
	test.SetInt("val", 1);
	if (!test.GetBool("val"))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x9");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), true);
		return false;
	}
	test.SetBool("val", false);
	if (test.GetInt("val"))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x10");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), false);
		return false;
	}
	test.SetBool("val", true);
	if (!test.GetInt("val"))
	{
		PrintToConsole(client, "DynamicType_Int test failed: ErrorCode 0x11");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), true);
		return false;
	}
	
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_FloatTest(int client, Dynamic test)
{
	// Test value
	float value = GetRandomFloat(0.0, 32000.0);
	
	// Offset test
	int offset = test.SetFloat("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Float test
	if (test.GetFloat("val") != value)
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x2");
		PrintToConsole(client, "> %f should equal %f", test.GetFloat("val"), value);
		return false;
	}
	
	// Int test
	int ivalue = RoundFloat(value);
	if (test.GetInt("val") != ivalue)
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x3");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), ivalue);
		return false;
	}
	test.SetInt("val", ivalue);
	if (test.GetFloat("val") != RoundFloat(value))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x4");
		PrintToConsole(client, "> %f should equal %f", test.GetFloat("val"), RoundFloat(value));
		return false;
	}
	test.SetFloat("val", value);
	
	// String test
	char cvalue[2][64];
	if (!test.GetString("val", cvalue[0], sizeof(cvalue[])))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x5");
		PrintToConsole(client, "> Couldn't read int as string");
		return false;
	}
	FloatToString(value, cvalue[1], sizeof(cvalue[]));
	if (!StrEqual(cvalue[0], cvalue[1]))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x6");
		PrintToConsole(client, "> '%s' should equal '%s'", cvalue[0], cvalue[1]);
		return false;
	}
	test.SetString("val", cvalue[1]);
	if (test.GetFloat("val") != value)
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x7");
		PrintToConsole(client, "> %f should equal %f", test.GetFloat("val"), value);
		return false;
	}
	
	// Object not supported - no test required
	
	// Boolean test
	test.SetFloat("val", 0.0);
	if (test.GetBool("val"))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x8");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), false);
		return false;
	}
	test.SetFloat("val", 1.0);
	if (!test.GetBool("val"))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x9");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), true);
		return false;
	}
	test.SetBool("val", false);
	if (test.GetInt("val"))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x10");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), false);
		return false;
	}
	test.SetBool("val", true);
	if (!test.GetInt("val"))
	{
		PrintToConsole(client, "DynamicType_Float test failed: ErrorCode 1x11");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), true);
		return false;
	}
	
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_StringTest(int client, Dynamic test)
{
	// Test value
	char value[64];
	char buffer[64];
	for (int i=0; i<sizeof(value); i++)
		value[i] = GetRandomInt(65, 122);
	value[63] = '\0';
	
	// Offset test
	int offset = test.SetString("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// String test
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x2");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Int test
	int ivalue = GetRandomInt(0, 32000);
	IntToString(ivalue, value, sizeof(value));
	test.SetString("val", value);
	if (test.GetInt("val") != ivalue)
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x3");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), ivalue);
		return false;
	}
	test.SetInt("val", ivalue);
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x4");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Float test
	float fvalue = GetRandomFloat(0.0, 32000.0);
	FloatToString(fvalue, value, sizeof(value));
	test.SetString("val", value);
	if (test.GetFloat("val") != fvalue)
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x3");
		PrintToConsole(client, "> %f should equal %f", test.GetFloat("val"), fvalue);
		return false;
	}
	test.SetFloat("val", fvalue);
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x4");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Object not supported - no test required
	// Add support for this as Get/SetString -> Read/WriteKeyValues
	
	// Boolean test
	test.SetString("val", "False");
	if (test.GetBool("val"))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x8");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), false);
		return false;
	}
	test.SetString("val", "True");
	if (!test.GetBool("val"))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x9");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), true);
		return false;
	}
	test.SetBool("val", false);
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual("False", buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x10");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "False");
		return false;
	}
	test.SetBool("val", true);
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual("True", buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x11");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "True");
		return false;
	}
	
	// Handle not supported - no test required
	
	// Vector test
	float vvalue[2][3];
	vvalue[0][0] = GetRandomFloat(0.0, 1.0);
	vvalue[0][1] = GetRandomFloat(0.0, 1.0);
	vvalue[0][2] = GetRandomFloat(0.0, 1.0);
	char vbuffer[2][256];
	Format(vbuffer[0], sizeof(vbuffer[]), "{%f, %f, %f}", vvalue[0][0], vvalue[0][1], vvalue[0][2]);
	test.SetString("val", vbuffer[0]);
	if (!test.GetVector("val", vvalue[1]))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x12");
		PrintToConsole(client, "> %d should equal %d", test.GetVector("val", vvalue[0]), true);
		return false;
	}
	if (!_Dynamic_CompareVectors(vvalue[0], vvalue[1]))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x13");
		PrintToConsole(client, "> {%x, %x, %x} should equal {%x, %x, %x}", vvalue[0][0], vvalue[0][1], vvalue[0][2], vvalue[1][0], vvalue[1][1], vvalue[1][2]);
		// let this continue as i've posted this
		// > https://forums.alliedmods.net/showthread.php?t=286748
		// return false;
	}
	test.SetVector("val", vvalue[0]);
	if (!test.GetString("val", vbuffer[1], sizeof(vbuffer[])))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x14");
		PrintToConsole(client, "> %d should equal %d", test.GetString("val", vbuffer[1], sizeof(vbuffer[])), true);
		return false;
	}
	if (!StrEqual(vbuffer[0], vbuffer[1]))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x15");
		PrintToConsole(client, "> '%s' should equal '%s'", vbuffer[0], vbuffer[1]);
		return false;
	}
	
	// Test setting string length > maxlength
	test.Reset(); // set blocksize to 16
	test.SetString("val", "1234567890", 6); // include eos space
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual("12345", buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x16");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "12345");
		return false;
	}
	
	// Test string length that is > blocksize (array index wrapping test)
	test.Reset(true, 3); // set blocksize to 7 (a nice awkward size) 
	for (int i=0; i<sizeof(value); i++)
		value[i] = GetRandomInt(65, 122);
	value[15] = '\0';
	offset = test.SetString("val", value);
	if (test.GetString("val", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x17");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Test string length returns valid length
	if (test.GetStringLength("val") != 17) // Length expands by one to ensure trailing EOS is added
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x18");
		PrintToConsole(client, "> %d should equal %d", test.GetStringLength("val"), 16);
		return false;
	}
	if (test.GetStringLengthByOffset(offset) != 17) // Length expands by one to ensure trailing EOS is added
	{
		PrintToConsole(client, "DynamicType_String test failed: ErrorCode 2x19");
		PrintToConsole(client, "> %d should equal %d", test.GetStringLengthByOffset(offset), 16);
		return false;
	}
	
	return true;
}

stock bool _Dynamic_BoolTest(int client, Dynamic test)
{
	// Test value
	bool value = GetRandomInt(0, 1) == 0 ? false : true;
	
	// Offset test
	int offset = test.SetBool("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Bool test
	if (test.GetBool("val") != value)
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x2");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), value);
		return false;
	}
	
	// Float test
	float fvalue = float(value);
	if (test.GetFloat("val") != fvalue)
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x3");
		PrintToConsole(client, "> %f should equal %f", test.GetFloat("val"), fvalue);
		return false;
	}
	test.SetFloat("val", fvalue);
	if (test.GetBool("val") != value)
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x4");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), value);
		return false;
	}
	
	// String test
	char cvalue[2][16];
	if (!test.GetString("val", cvalue[0], sizeof(cvalue[])))
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x5");
		PrintToConsole(client, "> Couldn't read int as string");
		return false;
	}
	if (value)
		Format(cvalue[1], sizeof(cvalue[]), "True");
	else
		Format(cvalue[1], sizeof(cvalue[]), "False");
	if (!StrEqual(cvalue[0], cvalue[1]))
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x6");
		PrintToConsole(client, "> '%s' should equal '%s'", cvalue[0], cvalue[1]);
		return false;
	}
	test.SetString("val", cvalue[1]);
	if (test.GetBool("val") != value)
	{
		PrintToConsole(client, "DynamicType_Bool test failed: ErrorCode 3x7");
		PrintToConsole(client, "> %d should equal %d", test.GetBool("val"), value);
		return false;
	}
	
	// Object not supported - no test required
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_ObjectTest(int client, Dynamic test)
{
	// Test value
	Dynamic value = Dynamic();
	
	// Offset test
	int offset = test.SetObject("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Object test
	if (test.GetObject("val") != value)
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x2");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Test parent is accurate
	Dynamic child = Dynamic();
	value.SetObject("child", child);
	if (child.Parent != value)
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x3");
		PrintToConsole(client, "> %d should equal %d", child.Parent, value);
		return false;
	}
	
	// Test _name is accurate
	char buffer[32];
	if (!child.GetName(buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x4");
		PrintToConsole(client, "> Couldn't read `_name` as string");
		return false;
	}
	if (!StrEqual(buffer, "child"))
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x5");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "child");
	}
	
	// Test parent follows most recent SetObject
	Dynamic value2 = Dynamic();
	value2.SetObject("child2", child);
	if (child.Parent != value2)
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x6");
		PrintToConsole(client, "> %d should equal %d", child.Parent, value2);
		return false;
	}
	
	// Test _name setter follows most recent change
	if (!child.GetName(buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x7");
		PrintToConsole(client, "> Couldn't read `_name` as string");
		return false;
	}
	if (!StrEqual(buffer, "child2"))
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x8");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "child2");
		return false;
	}
	
	// Test disposal of value - child should still be set as it's owner is value2
	value.Dispose();
	if (!child.IsValid)
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x9");
		PrintToConsole(client, "> '%d' should equal '%d'", child.IsValid, true);
		return false;
	}
	
	// Test disposal of value2 - child should be disposed
	value2.Dispose();
	if (child.IsValid)
	{
		PrintToConsole(client, "DynamicType_Object test failed: ErrorCode 4x10");
		PrintToConsole(client, "> '%d' should equal '%d'", child.IsValid, false);
		return false;
	}
	
	// Int not supported - no test required
	// Float not supported - no test required
	// String not supported - no test required
	// Boolean not supported - no test required
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_HandleTest(int client, Dynamic test)
{
	// Test value
	ArrayList value = new ArrayList();
	
	// Offset test
	int offset = test.SetHandle("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Handle test failed: ErrorCode 5x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Handle test
	if (test.GetHandle("val") != value)
	{
		PrintToConsole(client, "DynamicType_Handle test failed: ErrorCode 5x2");
		PrintToConsole(client, "> %d should equal %d", test.GetHandle("val"), value);
		return false;
	}
	
	// Test handle conversion - create, add item, store member, get member, get value, does it match?
	delete value;
	value = new ArrayList();
	int ivalue = GetRandomInt(0, 32000);
	value.Push(ivalue);
	test.SetHandle("val", value);
	value = view_as<ArrayList>(test.GetHandle("val"));
	if (value.Get(0) != ivalue)
	{
		PrintToConsole(client, "DynamicType_Handle test failed: ErrorCode 5x3");
		PrintToConsole(client, "> %d should equal %d", value.Get(0), ivalue);
		return false;
	}
	
	// We must set the handle to null!
	delete value;
	test.SetHandle("val", null);

	// Int not supported - no test required
	// Float not supported - no test required
	// String not supported - no test required
	// Boolean not supported - no test required
	// Object not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_VectorTest(int client, Dynamic test)
{
	// Test value
	float value[3];
	value[0] = GetRandomFloat(0.0, 1.0);
	value[1] = GetRandomFloat(0.0, 1.0);
	value[2] = GetRandomFloat(0.0, 1.0);
	
	// Offset test
	int offset = test.SetVector("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Vector test
	float vector[3];
	if (!test.GetVector("val", vector))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x2");
		PrintToConsole(client, "> %d should equal %d", test.GetVector("val", vector), true);
		return false;
	}
	if (!_Dynamic_CompareVectors(vector, value))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x3");
		PrintToConsole(client, "> %d should equal %d", _Dynamic_CompareVectors(vector, value), true);
		return false;
	}
	
	// Int not supported - no test required
	// Float not supported - no test required
	
	// String test
	char buffer[2][256];
	if (!test.GetString("val", buffer[0], sizeof(buffer[])))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x4");
		PrintToConsole(client, "> %d should equal %d", test.GetString("val", buffer[0], sizeof(buffer[])), true);
		return false;
	}
	Format(buffer[1], sizeof(buffer[]), "{%f, %f, %f}", value[0], value[1], value[2]);
	if (!StrEqual(buffer[0], buffer[1]))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x5");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer[0], buffer[1]);
		return false;
	}
	test.SetString("val", buffer[0]);
	if (!test.GetVector("val", vector))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x6");
		PrintToConsole(client, "> %d should equal %d", test.GetVector("val", vector), true);
		return false;
	}
	if (!_Dynamic_CompareVectors(vector, value))
	{
		PrintToConsole(client, "DynamicType_Vector test failed: ErrorCode 6x7");
		PrintToConsole(client, "> {%x, %x, %x} should equal {%x, %x, %x}", vector[0], vector[1], vector[2], value[0], value[1], value[2]);
		// let this continue as i've posted this
		// > https://forums.alliedmods.net/showthread.php?t=286748
		// return false; 
	}
	
	// Boolean not supported - no test required
	// Object not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_CompareVectors(const float value1[3], const float value2[3])
{
	if (value1[0] != value2[0])
		return false;
	if (value1[1] != value2[1])
		return false;
	if (value1[2] != value2[2])
		return false;
	return true;
}