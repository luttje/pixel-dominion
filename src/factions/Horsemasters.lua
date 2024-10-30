local FACTION = {}

FACTION.id = 'horsemasters'
FACTION.name = 'Horsemasters'

FACTION.profileImagePath = 'assets/images/faction-profiles/horsemaster.png'

--- Called when a goal is completed and the faction can say something about it.
--- @param faction Faction
--- @param goal BehaviorGoal
--- @return string[]|nil # A list of strings to be randomly chosen from, or nil if the faction has nothing to say about the goal
function FACTION:onGoalCompleted(faction, goal)
	if (goal.id == 'BuildStructure') then
		if (goal.goalInfo.structureTypeId == 'barracks') then
			return {
				'From here, the riders shall emerge!',
				'Our cavalry grows strong!',
				'We shape legends in this place!',
				'The spirit of the steppe breathes here!',
				'A stable for warriors of the wind!',
				'Horse and rider become one!',
				'The barracks echo with hooves and fury!',
				'We forge champions of the plains!',
				'Our warriors are swift as storms!',
				'Hooves thunder as warriors rise!',
				'We create legends under open skies!',
				'The barracks breathe with purpose!',
				'Let the barracks fill with life!',
				'Our strength flows from this ground!',
			}
		elseif (goal.goalInfo.structureTypeId == 'farmland') then
			return {
				'The fields will sustain our riders!',
				'The land nourishes our spirit!',
				'Our herds and crops grow strong!',
				'The plains provide for us!',
				'Grain and grass, the bounty of the steppe!',
				'The earth yields to our will!',
				'Our riders shall never hunger!',
				'Bounty from the endless plains!',
				'Nourishment for warriors of the plains!',
				'The fields shall serve the tribe!',
				'Our harvest grows as wide as the plains!',
				'We grow strong from soil and sky!',
				'The earth yields to Horsemasters!',
				'Let the land sustain our strength!',
			}
		elseif (goal.goalInfo.structureTypeId == 'lumber_camp') then
			return {
				'Wood to build, wood for the journey!',
				'The forest bends to our needs!',
				'Timber to shelter our warriors!',
				'We shape the forest to our will!',
				'A forest serves the Horsemasters!',
				'Lumber for our yurts and hearths!',
				'We tame the wild for the tribe!',
				'Our firewood piles grow strong!',
				'The trees provide as we conquer!',
				'Wood for riders and warriors!',
				'Our axes bite deep, like hooves!',
				'The forest yields to our strength!',
				'The trees support our journey!',
			}
		elseif (goal.goalInfo.structureTypeId == 'gold_mine') then
			return {
				'Gold to make our warriors gleam!',
				'Treasure for the Horsemasters!',
				'We claim the wealth of the earth!',
				'Our riders shall shine with riches!',
				'The ground yields to our will!',
				'Gold for glory and conquest!',
				'Riches to reward our riders!',
				'Our coffers fill with the earth\'s wealth!',
				'The shine of the plains!',
				'The earth\'s bounty is ours!',
				'Treasure flows into Horsemasters\' hands!',
				'The gold shall empower our horde!',
				'Our wealth grows as vast as the plains!',
			}
		elseif (goal.goalInfo.structureTypeId == 'stone_mine') then
			return {
				'Stone to fortify our paths!',
				'The bones of the earth support us!',
				'We carve strength from stone!',
				'With stone, our hold grows unbreakable!',
				'Sturdy walls for our people!',
				'Our strength is as solid as stone!',
				'Fortress and steppe, united in power!',
				'The stone is shaped by our will!',
				'Stone yields to our command!',
				'Strength of earth binds us!',
				'Our structures stand as mountains!',
				'Our walls are as steadfast as riders!',
				'Stone supports our journey!',
			}
		elseif (goal.goalInfo.structureTypeId == 'house') then
			return {
				'Shelter for our mighty tribe!',
				'The Horsemasters grow in number!',
				'Homes for warriors of the plains!',
				'A place for our people to rest and rise!',
				'Hearths for our fearless people!',
				'The tribe grows under these roofs!',
				'Homes to strengthen our riders!',
				'Here, the heart of the steppe beats!',
				'Shelter for our kin and kind!',
				'Warmth and strength in these halls!',
				'The tribe\'s roots grow deep!',
				'Every home fuels our journey!',
				'A strong tribe begins with strong homes!',
				'Our strength is in every tent and yurt!',
			}
		end
	elseif (goal.id == 'AttackUnits' and goal.goalInfo.units[1]) then
		local isPlayerFaction = goal.goalInfo.units[1]:getFaction() == CurrentPlayer:getFaction()

		if (isPlayerFaction) then
			return {
				'The Horsemasters ride for victory!',
				'Feel the wrath of the steppe!',
				'None shall stand before us!',
				'We bring the fury of the plains!',
				'They shall know the power of riders!',
				'We are the wind and thunder!',
				'Our hooves shall trample all!',
				'The steppe warriors show no mercy!',
				'The plains echo with our power!',
				'Fear the storm of the Horsemasters!',
				'Only defeat awaits them!',
				'We ride without restraint!',
				'Their cries will fill the air!',
				'Victory is ours to seize!',
			}
		else
			return {
				'They tremble as our riders approach!',
				'We bring ruin from the steppe!',
				'Their bones will scatter like dust!',
				'Our blades thirst for their downfall!',
				'Let them know the Horsemasters\' wrath!',
				'Our riders come like a storm!',
				'Their doom is upon them!',
				'Our fury leaves only dust behind!',
				'They face the might of the plains!',
				'Their end is near!',
				'Only ruin shall remain of them!',
				'Their lands shall echo with defeat!',
				'We shall sweep them like leaves!',
				'They are dust in the wind of battle!',
			}
		end
	elseif (goal.id == 'HaveUnitsOfType') then
		if (goal.goalInfo.unitTypeId == 'warrior') then
			return {
				'Our ranks swell with riders!',
				'Warriors of the plains, unmatched!',
				'Our riders are ever-ready!',
				'Strength and skill rise together!',
				'The ground shakes with their might!',
				'Each rider is swift and strong!',
				'Unyielding, fierce as stallions!',
				'Our power fills the plains!',
				'Ready to conquer all who oppose us!',
				'The Horsemasters are mighty!',
				'We are many, we are strong!',
				'Fear us, for we are unbreakable!',
				'The heart of the tribe beats in every rider!',
				'Our warriors are the spirit of the plains!',
			}
		elseif (goal.goalInfo.unitTypeId == 'villager') then
			return {
				'Our people grow strong together!',
				'Every hand builds our strength!',
				'Our people thrive on the plains!',
				'The tribe\'s labor feeds its spirit!',
				'Hands that work, hearts that ride!',
				'Every worker builds our power!',
				'The Horsemasters prosper from their labor!',
				'Our strength comes from every hand!',
				'The people\'s work fuels our might!',
				'We are many, we are unstoppable!',
				'Builders and warriors together!',
				'The tribe grows under every hand!',
				'Our people are the heart of the steppe!',
				'Our strength lies in unity and might!',
			}
		end
	end
end

--- Called when the faction surrenders
--- @param faction Faction
--- @return string[] # A list of strings to be randomly chosen from
function FACTION:onSurrender(faction)
    return {
        'Our spirit is unbroken!',
        'The steppe will echo with our return!',
        'The Horsemasters will not be forgotten!',
        'Our spirit is eternal!',
        'The steppe will know our return!',
    }
end

return FACTION
