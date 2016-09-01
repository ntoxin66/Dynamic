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

#if defined _dynamic_system_selftest
  #endinput
#endif
#define _dynamic_system_selftest

public void _Dynamic_SelfTest(any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientConnected(client))
		return;
	
	// Test offset alignments (initialisation offset vs findmemberoffset)
	
	// Test dynamic dynamic creation
	Dynamic test;
	if (!_Dynamic_InitialiseTest(client, test))
	{
		test.Dispose();
		return;
	}
	
	// DynamicType_Int Test
	test.Reset();
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
	
	// DynamicType_Dynamic Test
	test.Reset();
	if (!_Dynamic_DynamicTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> DynamicType_Dynamic test completed");
	
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
	
	// Dynamic.GetMemberNameByIndex(Dynamic params) Test
	test.Reset();
	if (!_Dynamic_GetMemberNameByIndexTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> Dynamic_GetMemberNameByIndex test completed");
	
	// Dynamic.FindByMemberValue(Dynamic params) Test
	test.Reset();
	if (!_Dynamic_FindByMemberValueTest(client, test))
	{
		test.Dispose();
		return;
	}
	PrintToConsole(client, "> Dynamic_FindByMemberValue test completed");
	
	test.Dispose();
}

stock bool _Dynamic_InitialiseTest(int client, Dynamic &test)
{
	// Check initial test dynamic is valid
	test = Dynamic();
	if (!test.IsValid)
	{
		PrintToConsole(client, "Dynamic_Initialise test failed: ErrorCode Ax1");
		PrintToConsole(client, "> %d should equal %d", test.IsValid, true);
		PrintToConsole(client, "> test=%d", test);
		return false;
	}
	return true;
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
	
	// Dynamic not supported - no test required
	
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
	
	// Dynamic not supported - no test required
	
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
	
	// Dynamic not supported - no test required
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
	vvalue[0][0] = GetRandomFloat(1.0, 32000.0);
	vvalue[0][1] = GetRandomFloat(1.0, 32000.0);
	vvalue[0][2] = GetRandomFloat(1.0, 32000.0);
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
		return false;
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
	
	// Dynamic not supported - no test required
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_DynamicTest(int client, Dynamic test)
{
	// Test value
	Dynamic value = Dynamic();
	
	// Offset test
	int offset = test.SetDynamic("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x1");
		PrintToConsole(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Dynamic test
	if (test.GetDynamic("val") != value)
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x2");
		PrintToConsole(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Test parent is accurate
	Dynamic child = Dynamic();
	value.SetDynamic("child", child);
	if (child.Parent != value)
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x3");
		PrintToConsole(client, "> %d should equal %d", child.Parent, value);
		return false;
	}
	
	// Test _name is accurate
	char buffer[32];
	if (!child.GetName(buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x4");
		PrintToConsole(client, "> Couldn't read `_name` as string");
		return false;
	}
	if (!StrEqual(buffer, "child"))
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x5");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "child");
	}
	
	// Test parent follows most recent SetDynamic
	Dynamic value2 = Dynamic();
	value2.SetDynamic("child2", child);
	if (child.Parent != value2)
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x6");
		PrintToConsole(client, "> %d should equal %d", child.Parent, value2);
		return false;
	}
	
	// Test _name setter follows most recent change
	if (!child.GetName(buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x7");
		PrintToConsole(client, "> Couldn't read `_name` as string");
		return false;
	}
	if (!StrEqual(buffer, "child2"))
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x8");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "child2");
		return false;
	}
	
	// Test disposal of value - child should still be set as it's owner is value2
	value.Dispose();
	if (!child.IsValid)
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x9");
		PrintToConsole(client, "> '%d' should equal '%d'", child.IsValid, true);
		return false;
	}
	
	// Test disposal of value2 - child should be disposed
	value2.Dispose();
	if (child.IsValid)
	{
		PrintToConsole(client, "DynamicType_Dynamic test failed: ErrorCode 4x10");
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
	// Dynamic not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_VectorTest(int client, Dynamic test)
{
	// Test value
	float value[3];
	value[0] = GetRandomFloat(1.0, 32000.0);
	value[1] = GetRandomFloat(1.0, 32000.0);
	value[2] = GetRandomFloat(1.0, 32000.0);
	
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
		return false; 
	}
	
	// Boolean not supported - no test required
	// Dynamic not supported - no test required
	// Vector not supported - no test required
	
	return true;
}

stock bool _Dynamic_GetMemberNameByIndexTest(int client, Dynamic test)
{
	// Test GetMemberNameByIndex for Set/PushInt
	test.SetInt("index0", 0);
	char buffer[128];
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x1");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushInt(1, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x2");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushFloat
	test.SetFloat("index0", 0.0);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x3");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushFloat(1.0, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x4");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushBool
	test.SetBool("index0", false);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x5");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushBool(true, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x6");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushString
	test.SetString("index0", "0");
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x7");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushString("1", 0, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x8");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushDynamic
	test.SetDynamic("index0", Dynamic());
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x9");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushDynamic(Dynamic(), "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x10");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushHandle
	test.SetHandle("index0", null);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x11");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushHandle(null, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x12");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushVector
	test.SetVector("index0", NULL_VECTOR);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x13");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushVector(NULL_VECTOR, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		PrintToConsole(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x14");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	return true;
}

stock bool _Dynamic_FindByMemberValueTest(int client, Dynamic test)
{
	// Create some stuff to find
	Dynamic child = Dynamic();
	child.SetString("class", "Plant");
	child.SetString("name", "Tree");
	test.PushDynamic(child, "Tree");
	child = Dynamic();
	child.SetString("class", "Plant");
	child.SetString("name", "Shrub");
	test.PushDynamic(child, "Shrub");
	child = Dynamic();
	child.SetString("class", "Animal");
	child.SetString("name", "Cat");
	test.PushDynamic(child, "Cat");
	child = Dynamic();
	child.SetString("class", "Animal");
	child.SetString("name", "Dog");
	test.PushDynamic(child, "Dog");
	
	// Search for plants
	Dynamic params = Dynamic();
	Dynamic param = Dynamic();
	param.SetString("MemberName", "class");
	param.SetInt("Operator", view_as<int>(DynamicOperator_Equals));
	param.SetString("Value", "Plant");
	params.PushDynamic(param);
	Collection results = view_as<Collection>(test.FindByMemberValue(params));
	params.Reset(true);
	
	// Check plant results
	if (results == null)
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x1");
		PrintToConsole(client, "> null should equal notnull", results.Length, 2);
		return false;
	}
	if (results.Length != 2)
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x1");
		PrintToConsole(client, "> %d should equal %d", results.Length, 2);
		return false; 
	}
	char buffer[32];
	if (!results.Items(0).GetString("name", buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x2");
		PrintToConsole(client, "> %d should equal %d", results.Items(0).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Tree"))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x3");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	if (!results.Items(1).GetString("name", buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x4");
		PrintToConsole(client, "> %d should equal %d", results.Items(1).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Shrub"))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x5");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	delete results;
	
	// Search for animals
	params = Dynamic();
	param = Dynamic();
	param.SetString("MemberName", "class");
	param.SetInt("Operator", view_as<int>(DynamicOperator_NotEquals));
	param.SetString("Value", "Plant");
	params.PushDynamic(param);
	results = view_as<Collection>(test.FindByMemberValue(params));
	params.Reset(true);
	
	// Check animal results
	if (results == null)
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x6");
		PrintToConsole(client, "> null should equal notnull", results.Length, 2);
		return false;
	}
	if (results.Length != 2)
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x7");
		PrintToConsole(client, "> %d should equal %d", results.Length, 2);
		return false; 
	}
	if (!results.Items(0).GetString("name", buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x8");
		PrintToConsole(client, "> %d should equal %d", results.Items(0).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Cat"))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x9");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	if (!results.Items(1).GetString("name", buffer, sizeof(buffer)))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x10");
		PrintToConsole(client, "> %d should equal %d", results.Items(1).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Dog"))
	{
		PrintToConsole(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x11");
		PrintToConsole(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	delete results;
	
	params.Dispose();
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