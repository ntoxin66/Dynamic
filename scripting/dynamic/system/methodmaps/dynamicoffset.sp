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

methodmap DynamicOffset
{
	public DynamicOffset(int index, int cell)
	{
		int offset = index << 16 | cell;
		offset ^= (-((index >> 32) & 1) ^ offset) & (1 << 32);
		offset ^= (-((cell >> 32) & 1) ^ offset) & (1 << 16);
		return view_as<DynamicOffset>(offset); 
	}
	
	property int Index
	{
		public get()
		{
			int index = view_as<int>(this) >> 16 & 0xFFFF;
			index ^= (-((view_as<int>(this) >> 32) & 1) ^ index) & (1 << 32);
			index ^= (-0 ^ index) & (1 << 16);
			return index;
		}
	}
	
	property int Cell
	{
		public get()
		{
			int cell = view_as<int>(this) & 0xFFFF;
			cell ^= (-((view_as<int>(this) >> 16) & 1) ^ cell) & (1 << 32);
			cell ^= (-0 ^ cell) & (1 << 16);
			return cell;
		}
	}
	
	public DynamicOffset Clone(int blocksize, int addcells=0)
	{
		int index = this.Index;
		int cell = this.Cell + addcells;
		
		while (cell >= blocksize)
		{
			index++;
			cell-=blocksize;
		}
		
		return DynamicOffset(index, cell);
	}
}