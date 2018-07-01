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

methodmap DBScheme < Dynamic
{
	public DBScheme()
	{
		Dynamic myclass = Dynamic(64, 0);
		myclass.SetString("Query", "", 5120);
		myclass.SetObject("Objects", view_as<Dynamic>(INVALID_DYNAMIC_OBJECT));
		return view_as<DBScheme>(myclass);
	}
	
	public bool GetQuery(char[] buffer, int length)
	{
		static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
		if (offset == INVALID_DYNAMIC_OFFSET)
		{
			offset = this.GetMemberOffset("Query");
			if (offset == INVALID_DYNAMIC_OFFSET)
				SetFailState("A serious error occured in Dynamic!");
		}
		this.GetStringByOffset(offset, buffer, length);
		return true;
	}
	
	public void SetQuery(const char[] buffer)
	{
		static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
		if (offset == INVALID_DYNAMIC_OFFSET)
		{
			offset = this.GetMemberOffset("Query");
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.SetString("Query", buffer);
				return;
			}
		}
		this.SetStringByOffset(offset, buffer);
	}
	
	property Dynamic Objects
	{
		public get()
		{
			static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("Objects");
				if (offset == INVALID_DYNAMIC_OFFSET)
					SetFailState("A serious error occured in Dynamic!");
			}
			return this.GetObjectByOffset(offset);
		}
		public set(Dynamic value)
		{
			static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("Objects");
				if (offset == INVALID_DYNAMIC_OFFSET)
				{
					offset = this.SetObject("Objects", value);
					return;
				}
			}
			this.SetObjectByOffset(offset, value);
		}
	}
	
	public bool AddObject(Dynamic object)
	{
		// Get Objects from class
		
		// Loop members in Objects
		{
			// Make sure the member type is Dynamic incase script adds other members
			
			// If object parameter matches objects member in loop
			{
				// Exit function as this is a duplicate entry
				// Return false
			}
			
			// Check if the member is not a valid dynamic object (!instance.IsValid)
			{
				// Store the free index and resuse it to stop leaking
			}
		}
		
		// Add DBScheme_UpdateRequired member to object
		// Note: Hook Changes callback will set this to true to flag an update is required
		
		// Hook changes; instance.HookChanges(DBScheme_Objects_MemberChanged);
		
		// Add object to Objects list (use .PushObject as we dont have member names)
		// Note reuse an index if available to stop leaking
		
		// Return true
	}
	
	public bool RemoveObject(Dynamic object)
	{
		// Get Objects from class
		
		// Loop members in Objects
		{
			// Make sure the member type is Dynamic incase script adds other members
			
			// Continue if object parameter doesnt match objects member in loop
			
			// Set value to INVALID_DYNAMIC_OBJECT in objects loop
			// Note: This stops leaking as .IsValid will return false
			
			// Remove hooks
			
			// Return true
		}
		
		// Return false
	}
	
	public bool BeginUpdateObject(Dynamic object, SQLQueryCallback callback)
	{
		// Can probably parse a database name from the database.cfg file
		
		// Get query string from class
		
		// Create buffer string to send to db query
		
		// Loop object members
		{
			// Replace all instances of `membername`=? with `membername`=sql escaped value
			// Note: We need to check every type to update ? properly
			//			Eg: String should be in ''
			//				> String values need to be escaped
			//				Int/Float should not be in
			//				Bool needs to be converted to 1 or 0
		}
		
		// Set the DBScheme_UpdateRequired member to false as we are about to send the query to update it
		
		// Send the query to the database engine
		// Note: Parse the callback parameter through
	}
}

static void DBScheme_Objects_MemberChanged(Dynamic obj, DynamicOffset offset, const char[] member, Dynamic_MemberType type)
{
	// Set the DBScheme_UpdateRequired member to true so the DBScheme methodmap knows to .BeginUpdateObject this member
}