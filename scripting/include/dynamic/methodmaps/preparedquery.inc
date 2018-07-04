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
#if defined _dynamic_class_preparedquery_
  #endinput
#endif
#define _dynamic_class_preparedquery_

methodmap PreparedQuery < Dynamic
{
	public PreparedQuery()
	{
		Dynamic myclass = Dynamic(64, 0);
		return view_as<PreparedQuery>(myclass);
	}
	
	public bool Compile(const char[] query)
	{
		return _Dynamic_PreparedQuery_Compile(query, this);
	}
	
	public bool Prepare(Database db, Dynamic parameters, char[] buffer, int buffersize)
	{
		return _Dynamic_PreparedQuery_Prepare(this, db, parameters, buffer, buffersize);
	}
	
	public bool Execute(Database db, Dynamic parameters, SQLQueryCallback callback=INVALID_FUNCTION, any data=0, int buffersize=512)
	{
		return _Dynamic_PreparedQuery_Execute(this, db, parameters, callback, data, buffersize);
	}
}