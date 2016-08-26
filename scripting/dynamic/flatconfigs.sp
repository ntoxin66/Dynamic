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

stock bool _Dynamic_ReadConfig(int index, const char[] path, bool use_valve_fs=false, int valuelength=128)
{
	if (!_Dynamic_IsValid(index))
		return false;
	
	// Check file exists
	if (!FileExists(path, use_valve_fs))
	{
		ThrowNativeError(0, "Filepath '%s' doesn't exist!", path);
		return false;
	}
	
	// Open file for reading
	File stream = OpenFile(path, "r", use_valve_fs);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
	}
		
	// Loop through file in blocks
	char buffer[16];
	bool readingname = true;
	bool readingstring = false;
	bool readingvalue = false;
	int lastchar = 0;
	bool skippingcomment = false;
	ArrayList settingnamearray = CreateArray(1);
	int settingnamelength = 0;
	ArrayList settingvaluearray = CreateArray(1);
	int settingvaluelength = 0;
	int length;
	
	while ((length = stream.ReadString(buffer, sizeof(buffer))) > 0)
	{
		for (int i = 0; i < length; i++)
		{
			int byte = buffer[i];
			
			// space and tabspace
			if (byte == 9 || byte == 32)
			{
				// continue if skipping comments
				if (skippingcomment)
					continue;
					
				if (readingname)
				{
					if (readingstring)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
					}
					else
					{
						readingname = false;
						readingvalue = true;
					}
				}
				
				else if (readingvalue)
				{
					if (readingstring)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
					}
					else
					{
						//if (settingvaluelength > 0)
						//	skippingcomment = true;
					}
				}
			}
			
			// new line
			else if (byte == 10)
			{
				readingname = true;
				readingstring = false;
				readingvalue = false;
				
				if (skippingcomment)
				{
					skippingcomment = false;
					continue;
				}
				
				AddConfigSetting(index, settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, valuelength);
				settingnamelength = 0;
				settingvaluelength = 0;
			}
			
			// quote
			else if (byte == 34)
			{
				readingstring = !readingstring;
				
				if (!readingstring && readingvalue)
				{
					AddConfigSetting(index, settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, valuelength);
					settingnamelength = 0;
					settingvaluelength = 0;
					skippingcomment = true;
				}
			}
			else
			{
				// continue if skipping a comment
				if (skippingcomment)
					continue;
				
				// skip double backslash comments
				if (byte == 92 && lastchar == 92)
				{
					skippingcomment = true;
					settingnamearray.Clear();
					settingnamelength = 0;
					settingvaluelength = 0;
					continue;
				}
				
				lastchar = byte;
				if (readingname)
				{
					settingnamearray.Push(byte);
					settingnamelength++;
				}
				else if (readingvalue)
				{
					settingvaluearray.Push(byte);
					settingvaluelength++;
				}
			}
		}
	}
	
	delete stream;
	delete settingnamearray;
	delete settingvaluearray;
	return true;
}

stock void AddConfigSetting(int index, ArrayList name, int namelength, ArrayList value, int valuelength, int maxlength)
{
	char[] settingname = new char[namelength];
	GetArrayStackAsString(name, settingname, namelength);
	name.Clear();
	
	char[] settingvalue = new char[valuelength];
	GetArrayStackAsString(value, settingvalue, valuelength);
	value.Clear();
	
	CreateMemberFromString(index, settingname, settingvalue, maxlength);
}

stock Dynamic_MemberType CreateMemberFromString(int index, const char[] membername, const char[] value, int maxlength)
{
	bool canbeint = true;
	bool canbefloat = true;
	int byte;
	int val;
	
	for (int i = 0; (byte = value[i]) != 0; i++)
	{
		// 48 = `0`, 57 = `9`, 46 = `.`, 45 = `-`
		if (byte < 48 || byte > 57)
		{
			if (byte == 45 && i == 0)
				continue;
			
			canbeint = false;
			
			if (byte != 46)
				canbefloat = false;
		}
		
		if (!canbeint && !canbefloat)
			break;
	}
	
	if (canbeint)
	{
		// Longs need to be stored as strings
		val = StringToInt(value);
		if (val == -1 && StrEqual(value, "-1"))
		{
			_Dynamic_SetInt(index, membername, val);
			return DynamicType_Int;
		}
		else
		{
			_Dynamic_SetString(index, membername, value, maxlength, maxlength);
			return DynamicType_String;
		}
	}
	else if (canbefloat)
	{
		_Dynamic_SetFloat(index, membername, StringToFloat(value));
		return DynamicType_Float;
	}
	else
	{
		// make regex if required
		if (g_sRegex_Vector == null)
			g_sRegex_Vector = CompileRegex("^\\{ ?+([-+]?[0-9]*\\.?[0-9]+) ?+, ?+([-+]?[0-9]*\\.?[0-9]+) ?+, ?+([-+]?[0-9]*\\.?[0-9]+) ?+\\}$");
		
		// check for vector
		int count = MatchRegex(g_sRegex_Vector, value);
		if (count == 4)
		{
			float vec[3];
			char matchbuffer[64];
			
			GetRegexSubString(g_sRegex_Vector, 1, matchbuffer, sizeof(matchbuffer));
			vec[0] = StringToFloat(matchbuffer);
			
			GetRegexSubString(g_sRegex_Vector, 2, matchbuffer, sizeof(matchbuffer));
			vec[1] = StringToFloat(matchbuffer);
			
			GetRegexSubString(g_sRegex_Vector, 3, matchbuffer, sizeof(matchbuffer));
			vec[2] = StringToFloat(matchbuffer);
			
			_Dynamic_SetVector(index, membername, vec);
			return DynamicType_Vector;
		}
		
		// check for bool last
		if (StrEqual(value, "true", false))
		{
			_Dynamic_SetBool(index, membername, true);
			return DynamicType_Bool;
		}
		else if (StrEqual(value, "false", false))
		{
			_Dynamic_SetBool(index, membername, false);
			return DynamicType_Bool;
		}
		
		_Dynamic_SetString(index, membername, value, maxlength, maxlength);
		return DynamicType_String;
	}	
}

stock bool GetVectorFromString(const char[] input, float output[3])
{
	// make regex if required
	if (g_sRegex_Vector == null)
		g_sRegex_Vector = CompileRegex("^\\{ ?+([-+]?[0-9]*\\.?[0-9]+) ?+, ?+([-+]?[0-9]*\\.?[0-9]+) ?+, ?+([-+]?[0-9]*\\.?[0-9]+) ?+\\}$");
	
	// check for vector
	int count = MatchRegex(g_sRegex_Vector, input);
	if (count == 4)
	{
		char buffer[64];
		
		GetRegexSubString(g_sRegex_Vector, 1, buffer, sizeof(buffer));
		output[0] = StringToFloat(buffer);
		
		GetRegexSubString(g_sRegex_Vector, 2, buffer, sizeof(buffer));
		output[1] = StringToFloat(buffer);
		
		GetRegexSubString(g_sRegex_Vector, 3, buffer, sizeof(buffer));
		output[2] = StringToFloat(buffer);
		return true;
	}
	return false;
}

stock void GetArrayStackAsString(ArrayList stack, char[] buffer, int length)
{
	for (int i = 0; i < length; i++)
	{
		buffer[i] = view_as<int>(stack.Get(i));
	}
}

stock bool _Dynamic_WriteConfig(int index, const char[] path)
{
	if (!_Dynamic_IsValid(index))
		return false;

	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
	}
	
	int count = _Dynamic_GetMemberCount(index);
	int memberoffset;
	int length;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = _Dynamic_GetMemberOffsetByIndex(index, i);
		_Dynamic_GetMemberNameByIndex(index, i, membername, sizeof(membername));
		length = _Dynamic_GetStringLengthByOffset(index, memberoffset);
		char[] membervalue = new char[length];
		_Dynamic_GetStringByOffset(index, memberoffset, membervalue, length);
		stream.WriteLine("%s\t\"%s\"", membername, membervalue);
	}
	
	delete stream;
	return true;
}