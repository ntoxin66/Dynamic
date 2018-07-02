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
#if defined _dynamic_class_dbscheme_
  #endinput
#endif
#define _dynamic_class_dbscheme_

static Regex s_hRegex = null;

methodmap PreparedQuery < Dynamic
{
	public PreparedQuery()
	{
		Dynamic myclass = Dynamic(64, 0);
		return view_as<PreparedQuery>(myclass);
	}
	
	public bool PrepareQuery(const char[] query, int bufferlength=512)
	{
		/*
			I've relised that regex in Sourcemod doesn't support the global flag
			which means only the first match is returned through the regex API.
			
			https://forums.alliedmods.net/showthread.php?t=308751
			
			I highly doubt that any updates will be completed in Sourcemod to
			allow the global flag to be supported.
			
			As a result, this solution to prepare queries is not suitable and I
			am forced into writting my own parser to process query strings.
		*/
		RegexError regexerr;
		PrintToServer("PrepareQuery(query='%s', bufferlength=%d)", query, bufferlength);
		
		if (s_hRegex == null)
		{
			char errmsg[256];
			s_hRegex = new Regex("`([^`]*)`\\s*=\\s*\\?(?![^,\\s])", 10, errmsg, sizeof(errmsg), regexerr);
			
			if (regexerr > REGEX_ERROR_NONE)
				SetFailState("Error encountered while compiling regex for DBScheme.PrepareQuery. Error Code: %d. Error Message: %s", regexerr, errmsg);
		}
		
		int count = s_hRegex.Match(query, regexerr);
		
		if (regexerr > REGEX_ERROR_NONE)
		{
			LogError("Error encountered while matching regex for DBScheme.PrepareQuery. Error Code: %d", regexerr);
			return false;
		}
		
		if (count == 0)
		{
			LogError("Error encountered while matching regex for DBScheme.PrepareQuery. Error Message: No matches returned from query parameter.");
			return false;
		}
		
		char[] buffer = new char[bufferlength];
		for (int i=0; i<count; i++)
		{
			if (!s_hRegex.GetSubString(i, buffer, bufferlength))
				continue;
			
			PrintToServer("> Parameter %d: %s", i, buffer);
		}
		
		// expected match results
		/*
			Match 1
			Full match	19-32	``name_test`=?`
			Group 1.	20-29	`name_test`
			Group 2.	31-32	`?`
			
			Match 2
			Full match	34-44	``email2`=?`
			Group 1.	35-41	`email2`
			Group 2.	43-44	`?`
			
			Match 3
			Full match	46-58	``password`=?`
			Group 1.	47-55	`password`
			Group 2.	57-58	`?`
			
			Match 4
			Full match	65-71	``ID`=?`
			Group 1.	66-68	`ID`
			Group 2.	70-71	`?`
		*/
		
		return false;
	}
	
	public bool SendQuery(Dynamic parameters, const char[] database, SQLQueryCallback callback)
	{
		
	}
}

