--- The Build menu that shows structures that can be built
--- @class BuildMenu: InterfaceFragment
local BuildMenu = DeclareClassWithBase('BuildMenu', InterfaceFragment)

function BuildMenu:initialize(config)
    self.width = '100%'
    self.height = '100%'
    self.x = 0
	self.y = 0
	self.isClippingDisabled = true

    table.Merge(self, config)

    self.structures = {}

    self:refreshStructures()

    return self
end

function BuildMenu:refreshStructures()
    self.structures = {}

    local faction = CurrentPlayer:getFaction()
    local availableStructures = faction:getAvailableStructures()

    for i, structureType in ipairs(availableStructures) do
		local text = structureType.name

        -- Append required resources
        if (structureType.requiredResources) then
			text = text .. " ("

			for resourceName, resourceAmount in pairs(structureType.requiredResources) do
				text = text .. resourceName .. ": " .. resourceAmount .. ", "
			end

			text = text:sub(1, -3)
			text = text .. ")"
		end

        local button = Button({
            text = text,
            icon = structureType.imagePath,
            isClippingDisabled = true,
            x = 0,
            y = 0,
            width = 64,
            height = 64,
            onClick = function()
                CurrentPlayer:setCurrentStructureToBuild(structureType, table.Copy(CurrentPlayer:getSelectedInteractables()))
				CurrentPlayer:clearSelectedInteractables()
            end
        })

        function button:updateEnabledByResources()
			self:setEnabled(structureType:canBeBuilt(faction))
		end

        self.childFragments:add(button)
        self.structures[i] = button
    end
end

function BuildMenu:performDraw(x, y, width, height)
    -- TODO: At some point we need to fix that childFragments is causing us to not have the correct size if we use anchors
	-- TODO: For now we just hackily draw ourselves using isClippingDisabled
    width = love.graphics.getWidth()
    height = #self.structures * 64 + Sizes.padding(2 + #self.structures) + Fonts.defaultHud:getHeight()

	x, y = width * .25, (love.graphics.getHeight() - height) * 0.5
    width = width * 0.5

	local shadowHeight = Sizes.padding()

    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle('fill', x, y, width, height)
    love.graphics.setColor(0.2, 0.5, 0.5, 0.5)
	love.graphics.rectangle('fill', x, y, width, height - shadowHeight)

    -- Draw the title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.defaultHud)
    love.graphics.print('Build', x + Sizes.padding(), y + Sizes.padding())

	local buttonX = x + Sizes.padding()
	local buttonY = y + Fonts.defaultHud:getHeight() + Sizes.padding()

    for i, button in ipairs(self.structures) do
		button:updateEnabledByResources()
		button:setWidth(width - Sizes.padding() * 2)
        button:setPosition(buttonX, buttonY)

        buttonY = buttonY + button.height + Sizes.padding()
    end
end

return BuildMenu
