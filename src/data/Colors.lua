local Colors = {}

--- Easily create a color table from RGB values ranging from 0 to 255.
function Colors.fromRgb(r, g, b, a)
	a = a or 255
	return setmetatable({ r, g, b, a }, {
		-- Unpack the color table into three values by calling the table.
		-- Specify byte (or not calling the color) to get a range from 0 to 255, byteTable to get that in a table
		-- Specify table to get a range from 0 to 1 in a table
		-- Just call the table to get the range from 0 to 1
		__call = function(self, mode)
			if (mode == 'byte') then
				return self[1], self[2], self[3], self[4]
			elseif (mode == 'byteTable') then
				return { self[1], self[2], self[3], self[4] }
			elseif (mode == 'table') then
				return { self[1] / 255, self[2] / 255, self[3] / 255, self[4] / 255 }
			end

			return self[1] / 255, self[2] / 255, self[3] / 255, self[4] / 255
		end
	})
end

--[[
	UI colors
--]]

Colors.backgroundLight = Colors.fromRgb(216, 216, 198)

Colors.primary = Colors.fromRgb(141, 65, 77)
Colors.primaryBright = Colors.fromRgb(150, 80, 91)

Colors.secondary = Colors.fromRgb(50, 67, 89)
Colors.secondaryBright = Colors.fromRgb(60, 77, 99)

Colors.bright = Colors.fromRgb(217, 182, 163)

Colors.text = Colors.fromRgb(255, 255, 255)
Colors.hintText = Colors.fromRgb(0, 0, 0)
Colors.hintHighlight = Colors.fromRgb(24, 54, 145)

Colors.summaryHeadingText = Colors.fromRgb(0, 0, 0)
Colors.summaryText = Colors.summaryHeadingText

-- Colors.selectedFriendly = Colors.fromRgb(47, 236, 108)
Colors.selectedMarker = Colors.fromRgb(193, 0, 78)

return Colors
