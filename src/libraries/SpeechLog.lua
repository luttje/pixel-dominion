--- A speech log where text can be added and displayed for a certain amount of time
--- @class SpeechLog
local SpeechLog = DeclareClass('SpeechLog')

local WORDS_READ_PER_SECOND = 3
local AVERAGE_WORD_LENGTH = 5

--- Creates a new speech log instance
--- @param config table
function SpeechLog:initialize(config)
	config = config or {}

	self.maxSpeeches = 1
	self.speeches = {}

	table.Merge(self, config)

end

--- Adds a new speech to the log
--- @param text string
--- @param duration? number
function SpeechLog:addSpeech(text, duration)
	if (#self.speeches >= self.maxSpeeches) then
		table.remove(self.speeches, 1)
	end

	duration = duration or self:getDurationForText(text)

	table.insert(self.speeches, {
		text = text,
		expiresAt = love.timer.getTime() + duration
	})
end

--- Guesses the duration for a certain text so there's enough time to read it
--- @param text string
--- @return number
function SpeechLog:getDurationForText(text)
	return math.max(2, (#text / AVERAGE_WORD_LENGTH) / WORDS_READ_PER_SECOND)
end

--- Gets the current speech (cleans up old speeches)
--- @return string?, number|0
function SpeechLog:getCurrentSpeech()
	local currentTime = love.timer.getTime()

	while (#self.speeches > 0 and self.speeches[1].expiresAt < currentTime) do
		table.remove(self.speeches, 1)
	end

	if (#self.speeches > 0) then
		local alphaFactor = 1

		if (self.speeches[1].expiresAt - currentTime < 1) then
			alphaFactor = (self.speeches[1].expiresAt - currentTime)
		end

		return self.speeches[1].text, alphaFactor
	end

	return nil, 0
end

return SpeechLog
