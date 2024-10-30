local FACTION = {}

FACTION.id = 'barbarians'
FACTION.name = 'Barbarians'

FACTION.profileImagePath = 'assets/images/faction-profiles/barbarian.png'

--- Called when a goal is completed and the faction can say something about it.
--- @param faction Faction
--- @param goal BehaviorGoal
--- @return string[]|nil # A list of strings to be randomly chosen from, or nil if the faction has nothing to say about the goal
function FACTION:onGoalCompleted(faction, goal)
	if (goal.id == 'BuildStructure') then
		if (goal.goalInfo.structureTypeId == 'barracks') then
			return {
				'Our warriors shall rise from here!',
				'The forge of battle is ready!',
				'The might of the barbarians grows!',
				'Let strength be our legacy!',
				'The barracks stand ready for blood!',
				'The drums of war beat louder!',
				'Here, we create warriors, not walls!',
				'The tribe\'s strength is forged in battle!',
				'Warriors to crush all foes!',
				'Our numbers shall shake the earth!',
				'Let the barracks thunder with fury!',
				'More blades to cleave our enemies!',
				'Blood and iron await!',
				'These walls will breed legends!',
			}
		elseif (goal.goalInfo.structureTypeId == 'farmland') then
			return {
				'The land will feed our strength!',
				'Fields of plenty for the tribe!',
				'Barbarians shall feast!',
				'The earth provides for the strong!',
				'From soil to strength!',
				'We reap to conquer!',
				'Bounty for the fearless!',
				'The land bends to our will!',
				'Our people will be well-fed for the fight!',
				'Harvests for our hordes!',
				'The fields serve the tribe!',
				'Let the grain be plenty!',
				'The crops know our power!',
				'Our strength grows in soil!',
			}
		elseif (goal.goalInfo.structureTypeId == 'lumber_camp') then
			return {
				'The forest falls before us!',
				'Timber for our halls and fires!',
				'The barbarians conquer the woods!',
				'Wood to build, wood to burn!',
				'We fell trees to build empires!',
				'The trees tremble at our axes!',
				'The forest fuels our conquest!',
				'Lumber for the brave!',
				'Our woodpile grows like our power!',
				'We shape the forest to our will!',
				'Wood for warriors and walls!',
				'Axes carve paths to victory!',
				'The forest will yield to us!',
				'More timber, more might!',
			}
		elseif (goal.goalInfo.structureTypeId == 'gold_mine') then
			return {
				'Treasure flows into our hands!',
				'We will gleam in battle!',
				'The barbarians seize riches!',
				'Gold for glory and conquest!',
				'We claim the veins of the earth!',
				'Shining wealth, barbarian strength!',
				'Gold to fuel the horde!',
				'Our coffers fill with power!',
				'Riches for our fearless fighters!',
				'Gold serves the strong!',
				'The glitter of conquest!',
				'We hoard wealth for victory!',
				'Shiny treasures under our grip!',
				'Our gold glimmers with strength!',
			}
		elseif (goal.goalInfo.structureTypeId == 'stone_mine') then
			return {
				'The bones of the earth are ours!',
				'With stone, we stand unbreakable!',
				'The barbarians carve strength from stone!',
				'Rocks to fortify our might!',
				'The stones yield to our hands!',
				'Strength lies within stone!',
				'Walls to crush our foes!',
				'Stone shapes our destiny!',
				'We build strong as the mountains!',
				'The tribe\'s bones are of stone!',
				'Fortress and fury are ours!',
				'The earth is ours to shape!',
				'We will be immovable!',
				'Our stones, our strength!',
			}
		elseif (goal.goalInfo.structureTypeId == 'house') then
			return {
				'The tribe grows strong and many!',
				'Halls for warriors and kin!',
				'Shelter for our mighty people!',
				'The barbarians thrive and multiply!',
				'Homes for our warriors!',
				'The tribe\'s heart grows here!',
				'We build for the brave!',
				'Space for strength and skill!',
				'Hearths for our people!',
				'Walls to protect the future!',
				'Our halls will shake with feasts!',
				'More strength in every home!',
				'Room to grow, room to conquer!',
				'Every home, a legend\'s start!',
			}
		end
	elseif (goal.id == 'AttackUnits' and goal.goalInfo.units[1]) then
		local isPlayerFaction = goal.goalInfo.units[1]:getFaction() == CurrentPlayer:getFaction()

		if (isPlayerFaction) then
			return {
				'The barbarians shall feast on your fear!',
				'You will fall under barbarian might!',
				'None shall survive our wrath!',
				'We will crush every foe!',
				'Prepare to meet the ground!',
				'We are the storm of war!',
				'The earth will tremble beneath us!',
				'Run if you dare, but you will fall!',
				'No mercy for our enemies!',
				'We are their end!',
				'Only death awaits!',
				'Our fury knows no bounds!',
				'Their cries will fill the air!',
				'We will drink their fear!',
			}
		else
			return {
				'They will tremble at our coming!',
				'The barbarians bring ruin upon them!',
				'Their bones shall scatter on the wind!',
				'Our blades thirst for their blood!',
				'Let them feel barbarian wrath!',
				'The ground will drink their blood!',
				'We hunt, we conquer!',
				'Their doom is sealed!',
				'We strike with no mercy!',
				'They face the horde\'s fury!',
				'Their end is near!',
				'We shall trample their land!',
				'Only fire and ash for them!',
				'They fall like leaves in autumn!',
			}
		end
	elseif (goal.id == 'HaveUnitsOfType') then
		if (goal.goalInfo.unitTypeId == 'warrior') then
			return {
				'Our ranks swell with fierce warriors!',
				'Barbarian strength unmatched!',
				'The tribe is battle-ready!',
				'Our warriors stand ready!',
				'Our numbers fill the earth!',
				'Each warrior is a storm!',
				'Unyielding as mountains!',
				'With every warrior, our power grows!',
				'Our strength shakes the ground!',
				'Ready to conquer all!',
				'Our horde is mighty!',
				'Fear us, for we are many!',
				'The heart of the tribe beats stronger!',
				'Our warriors are legends in flesh!',
			}
		elseif (goal.goalInfo.unitTypeId == 'villager') then
			return {
				'The tribe grows strong with many hands!',
				'Barbarian work fuels barbarian might!',
				'Our people toil; our people thrive!',
				'Our villagers work as one!',
				'Hands that build, hearts that fight!',
				'With every worker, our strength grows!',
				'The tribe is fed by its own!',
				'Work and will make us strong!',
				'Villagers fuel our war!',
				'Our tribe prospers!',
				'We are many and mighty!',
				'Builders and warriors, side by side!',
				'The village is the heart of the horde!',
				'Our strength lies in every hand!',
			}
		end
	end
end

return FACTION
