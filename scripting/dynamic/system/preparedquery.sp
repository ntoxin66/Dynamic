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

public bool _Dynamic_PreparedQuery_CompileQuery(const char[] query, Dynamic obj)
{
	PrintToServer("query: %s", query);
	int i=0;
	char byte;
	
	char[] buffer = new char[strlen(query)];
	int bufferpos=0;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	int membernamepos=0;
	bool readingmembername=false;
	
	bool instring=false;
	char stringbyte;
	
	while ((byte=query[i++]) != '\0')
	{
		// "   '   ?   `   =   \			" LOL WITHOUT THIS QUOTE THE COMPILER THROWS AN ERROR
		// 034 039 063 096 061 092
		
		if (byte==96) // `
		{
			buffer[bufferpos++]=byte;
			if (instring)
				continue;
			
			readingmembername=!readingmembername;
			
			if (readingmembername)
				membername[membernamepos=0]='\0';
			else
				membername[membernamepos++]='\0';
		}
		else if (byte==34 || byte==39) // " or '
		{
			buffer[bufferpos++]=byte;
			if (instring)
			{
				if (stringbyte==byte) // same string byte
				{
					if (query[i-2] == 92) // \						" LOL WITHOUT THIS QUOTE THE COMPILER THROWS AN ERROR
						continue; // is escaped
				}
				else
					continue; // different string byte
				
				instring=false;
			}
			else
			{
				instring=true;
				stringbyte=byte;			
			}
		}
		else if (byte==63) // ?
		{
			buffer[bufferpos++]='\0';
			
			PrintToServer("> Section: %s", buffer);
			PrintToServer("> Member: %s", membername);
			
			obj.PushString(buffer);
			obj.PushString(membername);
			buffer[0]='\0';
			bufferpos=0;
		}
		else // any other char
		{
			if (readingmembername)
				membername[membernamepos++]=byte;
			
			buffer[bufferpos++]=byte;
		}	
	}
	return true;
}

public bool _Dynamic_PreparedQuery_SendQuery(Dynamic query, Dynamic parameters, const char[] database, SQLQueryCallback callback, int buffersize)
{
	char[] buffer = new char[buffersize];
	int bufferpos = 0;
	int count = query.MemberCount;
	bool issection=true;
	DynamicOffset offset;
	int length;
	for (int i=0; i<count; i++)
	{
		offset = query.GetMemberOffsetByIndex(i);
		if (issection)
		{
			length=query.GetStringLengthByOffset(offset);
			
		}
		else
		{
			
			
		}
		issection=!issection;
	}
	
	
}