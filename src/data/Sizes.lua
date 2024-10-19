local Sizes = {}

--- Easily return a size that will will scale to the screen size in the future.
--- @param size number
--- @return fun(): number
local function scaled(size)
	return function(scaleFactor)
		-- TODO: Implement scaling based on screen
		scaleFactor = scaleFactor or 1
		return size * scaleFactor
	end
end

Sizes.margin = scaled(16)
Sizes.padding = scaled(8)

Sizes.lineMargin = scaled(4)

Sizes.buttonHeight = scaled(48)

local function getSafeArea()
	if (DEBUG_FAKE_STATUS_BAR) then
		local debugTestStatusBarHeight = 64
		return 0, debugTestStatusBarHeight, love.graphics.getWidth(), love.graphics.getHeight() - debugTestStatusBarHeight
	end

	return love.window.getSafeArea()
end

Sizes.safeScreenMargins = function(scaleFactor)
	local x, y, width, height = getSafeArea()
	local margin = Sizes.margin(scaleFactor)

	local heightDifference = love.graphics.getHeight() - (y + height)
	local widthDifference = love.graphics.getWidth() - (x + width)

	return {
		top = y + margin,
		bottom = heightDifference + margin,
		left = x + margin,
		right = widthDifference + margin,
	}
end

--[[
	Helper functions
--]]

local lastScreenWidth = 0
local lastScreenHeight = 0

--- Use this function in an update function to update a value based on the screen height.
--- For example:
--- function InGameState:update(dt)
--- 	Sizes.updateOnScreenHeightAtLeast({
--- 		[600] = function()
--- 			self.selectedCards:setHeight('50%')
--- 		end,
--- 		[800] = function()
--- 			self.selectedCards:setHeight('45%')
--- 		end,
--- 		[1000] = function()
--- 			self.selectedCards:setHeight('40%')
--- 		end,
--- 		[1200] = function()
--- 			self.selectedCards:setHeight(400)
--- 		end,
--- 	})
--- end
function Sizes.updateOnScreenHeightAtLeast(heightConfigs)
	local screenWidth, screenHeight = love.graphics.getDimensions()

	if (screenWidth == lastScreenWidth and screenHeight == lastScreenHeight) then
		return
	end

	lastScreenWidth = screenWidth
	lastScreenHeight = screenHeight

	local largestMatchConfig
	local largestMatchHeight = 0

	for height, heightConfig in pairs(heightConfigs) do
		if (screenHeight >= height and height >= largestMatchHeight) then
			largestMatchConfig = heightConfig
			largestMatchHeight = height
		end
	end

	if (not largestMatchConfig) then
		error('No height found for screen height ' .. screenHeight)
	end

	largestMatchConfig()
end

return Sizes
