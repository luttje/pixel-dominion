Input = {}

--- Gets the position of the pointer, whether it is a mouse or touch.
--- @return number, number # The x and y coordinates of the pointer.
function Input.GetPointerPosition()
	local pointerX, pointerY = love.mouse.getPosition()

	local touches = love.touch.getTouches()

	if #touches > 0 then
		pointerX, pointerY = love.touch.getPosition(touches[1])
	end

	return pointerX, pointerY
end
