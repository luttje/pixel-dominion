local FACTION = {}

FACTION.id = 'emperials'
FACTION.name = 'Emperials'

FACTION.profileImagePath = 'assets/images/faction-profiles/emperial.png'

--- Called when a goal is completed and the faction can say something about it.
--- @param faction Faction
--- @param goal BehaviorGoal
--- @return string[]|nil # A list of strings to be randomly chosen from, or nil if the faction has nothing to say about the goal
function FACTION:onGoalCompleted(faction, goal)
    if (goal.id == 'BuildStructure') then
        if (goal.goalInfo.structureTypeId == 'barracks') then
            return {
                'Our warriors are forged here.',
                'Strength rises from these walls.',
                'From here, valor shall march.',
                'The barracks stand, unwavering.',
                'Where blades meet discipline.',
                'Our legacy begins here.',
                'Through these doors, warriors emerge.',
                'Honor the training grounds.',
                'A sanctuary for the brave.',
                'The path to victory is paved here.',
            }
        elseif (goal.goalInfo.structureTypeId == 'farmland') then
            return {
                'The land answers our call.',
                'Fields of prosperity for our people.',
                'Our strength lies in the harvest.',
                'Bounty blesses the loyal.',
                'The soil is our silent ally.',
                'Nourishment for future battles.',
                'The fields serve the Emperial cause.',
                'From soil, strength shall grow.',
                'Food for our people; power for our empire.',
                'Let the harvest be plentiful.',
            }
        elseif (goal.goalInfo.structureTypeId == 'lumber_camp') then
            return {
                'The forest yields to our will.',
                'Wood for our mighty empire.',
                'Our hands shape the trees.',
                'Timber strengthens our walls.',
                'The forest serves the Emperial cause.',
                'Each log builds our future.',
                'A kingdom of stone and wood.',
                'Lumber fuels our ambition.',
                'The empire grows with each tree felled.',
                'Our people, one with the land.',
            }
        elseif (goal.goalInfo.structureTypeId == 'gold_mine') then
            return {
                'Treasure for our people.',
                'The empire\'s wealth grows.',
                'Our coffers swell with prosperity.',
                'Gold strengthens our resolve.',
                'The veins of the earth are ours.',
                'Riches to fuel our legacy.',
                'Our empire gleams with fortune.',
                'Gold feeds the empire\'s might.',
                'Our wealth knows no bounds.',
                'Shining prosperity is ours.',
            }
        elseif (goal.goalInfo.structureTypeId == 'stone_mine') then
            return {
                'The strength of stone is ours.',
                'Our empire is built upon rock.',
                'Stone solidifies our rule.',
                'The mountains lend us their strength.',
                'Rock to shield our people.',
                'Fortress foundations forged in stone.',
                'Strength carved from the earth.',
                'Stone secures our legacy.',
                'The land offers its bones.',
                'With stone, we rise unbreakable.',
            }
        elseif (goal.goalInfo.structureTypeId == 'house') then
            return {
                'Homes for our loyal subjects.',
                'A sanctuary for the Emperial heart.',
                'Our empire grows in strength and number.',
                'Shelter for those who serve.',
                'Our people find peace here.',
                'The foundation of the empire lies here.',
                'The empire\'s heart beats in each home.',
                'Strong walls for a strong people.',
                'Homes for the loyal and brave.',
                'The empire\'s strength starts here.',
            }
        end
    elseif (goal.id == 'AttackUnits' and goal.goalInfo.units[1]) then
        local isPlayerFaction = goal.goalInfo.units[1]:getFaction() == CurrentPlayer:getFaction()

        if (isPlayerFaction) then
            return {
                'Your resistance is futile.',
                'We are the unyielding storm.',
                'None shall withstand the empire.',
                'The Emperial fury is upon you.',
                'Prepare to face your end.',
                'Our blades show no mercy.',
                'You will fall before us.',
                'Fear the Emperial might.',
                'We are unstoppable.',
                'Victory is inevitable.',
            }
        else
            return {
                'Our enemies will tremble.',
                'They face the empire\'s wrath.',
                'Their defeat is certain.',
                'The Emperial strike is swift and sure.',
                'They will bow before us.',
                'We bring ruin to their gates.',
                'Their lands shall know our strength.',
                'The empire\'s justice is relentless.',
                'Their cries will fade in the wind.',
                'Let them feel our might.',
            }
        end
    elseif (goal.id == 'HaveUnitsOfType') then
        if (goal.goalInfo.unitTypeId == 'warrior') then
            return {
                'Our warriors stand unwavering.',
                'The Emperial force is ready.',
                'Strength swells in our ranks.',
                'Disciplined and unbreakable.',
                'Our warriors are our honor.',
                'Each soldier, a testament to the empire.',
                'Our power is unmatched.',
                'The empire grows in strength.',
                'Warriors uphold the empire\'s name.',
                'Ready to bring glory to our cause.',
            }
        elseif (goal.goalInfo.unitTypeId == 'villager') then
            return {
                'The people build our legacy.',
                'Each hand strengthens the empire.',
                'Villagers support our ambition.',
                'Our people are our strength.',
                'The empire thrives by their work.',
                'Labor for the empire\'s future.',
                'Our people form our foundation.',
                'Strength in every hand.',
                'The empire grows through toil and unity.',
                'The villagers fuel our prosperity.',
            }
        end
    end
end

--- Checks if we should surrender
--- @param faction Faction
--- @return boolean # True if the faction should surrender, false otherwise
function FACTION:checkShouldSurrender(faction)
	-- local units = self:getUnits()
	-- local resourceInventory = self:getResourceInventory()
	-- local townHall = self:getTownHall()
	-- local nearlyDead = not townHall and #units < 2 and resourceInventory:getValue('food') < 20
end

--- Called when the faction surrenders
--- @param faction Faction
--- @return string[] # A list of strings to be randomly chosen from
function FACTION:onSurrender(faction)
    return {
        'The empire bows to your might.',
        'Our strength is yours to command.',
        'The Emperial cause is yours.',
        'Our empire is yours to shape.',
        'Your victory is our surrender.',
        'The empire yields to your power.',
        'Our fate is in your hands.',
        'The Emperial legacy is yours.',
        'Our empire is yours to rule.',
    }
end

return FACTION
