local FACTION = {}

FACTION.id = 'warlords'
FACTION.name = 'Warlords'

FACTION.profileImagePath = 'assets/images/faction-profiles/warlord.png'

--- Called when a goal is completed and the faction can say something about it.
--- @param faction Faction
--- @param goal BehaviorGoal
--- @return string[]|nil # A list of strings to be randomly chosen from, or nil if the faction has nothing to say about the goal
function FACTION:onGoalCompleted(faction, goal)
	if (goal.id == 'BuildStructure') then
		if (goal.goalInfo.structureTypeId == 'barracks') then
			return {
				'Warriors of wrath arise here!',
				'This ground shall breed champions of war!',
				'The Warlords\' forge stands strong!',
				'Power is born within these walls!',
				'Our barracks are ready to conquer!',
				'The drums of conquest thunder louder!',
				'Here, we craft warriors of fury!',
				'Strength is forged in blood and battle!',
				'Warriors to devastate all who oppose us!',
				'Our numbers will shatter the earth!',
				'The barracks roar with deadly purpose!',
				'Blades will carve the future!',
				'Blood and iron fuel our might!',
				'Legends rise from these halls!',
			}
		elseif (goal.goalInfo.structureTypeId == 'farmland') then
			return {
				'The earth feeds our power!',
				'Fields will fuel our bloodlust!',
				'The Warlords feast and grow!',
				'The soil yields strength to the fierce!',
				'From ground to glory!',
				'We harvest to conquer!',
				'Bounty for those who dare!',
				'The land submits to our will!',
				'The strong shall feed and fight!',
				'Harvests feed our hungry horde!',
				'Fields serve the Warlords!',
				'Let the bounty be plentiful!',
				'The earth bends to our might!',
				'Strength grows in every crop!',
			}
		elseif (goal.goalInfo.structureTypeId == 'lumber_camp') then
			return {
				'The forest falls to our axes!',
				'Timber for strength and siege!',
				'We conquer the forest, as all things!',
				'Wood to burn, wood to build!',
				'Trees fall for our dominion!',
				'Axes strike with relentless force!',
				'The forest yields to Warlords!',
				'Lumber for our fires of war!',
				'Wood feeds our fury!',
				'We shape the forest to our will!',
				'The Warlords carve paths to victory!',
				'The trees fall; our power grows!',
				'The forest bows before us!',
				'Our horde\'s might rises with each timber!',
			}
		elseif (goal.goalInfo.structureTypeId == 'gold_mine') then
			return {
				'Treasures fuel our rage!',
				'Our strength shines like gold!',
				'The Warlords claim all riches!',
				'Gold fuels the fires of conquest!',
				'We take the veins of the earth!',
				'Golden wealth for warriors!',
				'Riches feed our relentless horde!',
				'Our coffers brim with fury!',
				'Treasures strengthen our warriors!',
				'The Warlords hold the wealth!',
				'We glitter with the gleam of conquest!',
				'Our vaults overflow with power!',
				'We claim the wealth of the world!',
				'Our gold glimmers with violence!',
			}
		elseif (goal.goalInfo.structureTypeId == 'stone_mine') then
			return {
				'The bones of the earth belong to us!',
				'We rise, unbreakable as stone!',
				'Strength is carved from the earth!',
				'Stone fortifies our fury!',
				'The earth yields its bones to us!',
				'Rock forms our unyielding power!',
				'Fortress walls for Warlords!',
				'Our destiny is forged in stone!',
				'Strong as mountains, we stand!',
				'The tribe\'s walls are made of stone!',
				'Stone fuels our relentless force!',
				'The earth bends to Warlords!',
				'Immovable as the mountains!',
				'Our stones form our fury!',
			}
		elseif (goal.goalInfo.structureTypeId == 'house') then
			return {
				'The tribe grows in power and number!',
				'Halls for our ruthless kin!',
				'Our people gather in strength!',
				'The Warlords grow and multiply!',
				'Homes for warriors and beasts alike!',
				'Our heart beats in these walls!',
				'Strength rises in every house!',
				'Space for battle and blood!',
				'Hearths for the fearless!',
				'Walls that protect and prepare!',
				'Our halls echo with feasts of the strong!',
				'Strength multiplies in every home!',
				'Each home a forge for fury!',
				'Our kin thrive to conquer!',
			}
		end
	elseif (goal.id == 'AttackUnits' and goal.goalInfo.units[1]) then
		local isPlayerFaction = goal.goalInfo.units[1]:getFaction() == CurrentPlayer:getFaction()

		if (isPlayerFaction) then
			return {
				'The Warlords feast on your terror!',
				'You will crumble before us!',
				'None shall withstand our might!',
				'Prepare to be annihilated!',
				'The ground shall be your grave!',
				'Our fury is the storm of war!',
				'Tremble as the earth quakes!',
				'Run if you dare, but you will fall!',
				'No escape, no mercy!',
				'Your end has come!',
				'Only death greets our foes!',
				'Our wrath knows no end!',
				'The air will echo with your screams!',
				'Fear fuels our victory!',
			}
		else
			return {
				'They will crumble under our assault!',
				'Ruin shall follow the Warlords!',
				'Their bones will scatter like leaves!',
				'Our blades thirst for their defeat!',
				'Warlord wrath knows no mercy!',
				'The ground shall drink deep of their blood!',
				'We hunt to conquer all!',
				'Their doom is certain!',
				'Mercy is not our way!',
				'They face the Warlords\' fury!',
				'Their end is upon them!',
				'Their lands will burn!',
				'Ash and ruin await them!',
				'They fall like withered leaves!',
			}
		end
	elseif (goal.id == 'HaveUnitsOfType') then
		if (goal.goalInfo.unitTypeId == 'warrior') then
			return {
				'The ranks swell with warriors of fury!',
				'Warlord strength unmatched!',
				'The tribe stands ready for war!',
				'Our warriors are ready to conquer!',
				'Our numbers shake the earth!',
				'Each warrior is a force of nature!',
				'Unyielding, relentless, unstoppable!',
				'With each warrior, our might grows!',
				'The ground trembles with our strength!',
				'Prepared to crush all opposition!',
				'Our horde is fierce and many!',
				'The world will fear our numbers!',
				'Warlords in flesh and blood!',
				'Legends rise within our ranks!',
			}
		elseif (goal.goalInfo.unitTypeId == 'villager') then
			return {
				'The tribe grows with fierce hands!',
				'Warlords work, Warlords fight!',
				'The people labor; the people thrive!',
				'Villagers build our dominion!',
				'Every hand strengthens our wrath!',
				'With each worker, our power grows!',
				'The tribe feeds its own strength!',
				'Hard work fuels our conquest!',
				'Villagers prepare us for war!',
				'Our people live and prosper!',
				'Warlords are many and mighty!',
				'Builders and warriors side by side!',
				'The village is the horde\'s heart!',
				'Every hand fuels our future victories!',
			}
		end
	end
end

--- Called when the faction surrenders
--- @param faction Faction
--- @return string[] # A list of strings to be randomly chosen from
function FACTION:onSurrender(faction)
	return {
		'The Warlords will not be forgotten!',
		'The tribe will rise from the ashes!',
		'We will return to claim our vengeance!',
		'The tribe will not be broken!',
	}
end

return FACTION
