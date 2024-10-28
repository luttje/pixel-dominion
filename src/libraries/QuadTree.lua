--- @class QuadTree
---
--- @field boundary {x: number, y: number, width: number, height: number}
--- @field capacity number
--- @field objects table
--- @field divided boolean
local QuadTree = DeclareClass('QuadTree')

--- Creates a new QuadTree node
--- @param config table
function QuadTree:initialize(config)
    assert(config.boundary, 'QuadTree boundary is required.')
    assert(config.boundary.x, 'QuadTree boundary X is required.')
	assert(config.boundary.y, 'QuadTree boundary Y is required')
	assert(config.boundary.width, 'QuadTree boundary width is required.')
	assert(config.boundary.height, 'QuadTree boundary height is required.')

	-- TODO: Find a good default capacity
    config.capacity = config.capacity or 4

    table.Merge(self, config)

    self.objects = {}
	self.divided = false
end

--- Subdivides the QuadTree node into four quadrants
function QuadTree:subdivide()
    local x, y, w, h = self.boundary.x, self.boundary.y, self.boundary.width, self.boundary.height

    self.northeast = QuadTree({
		boundary = {x = x + w/2, y = y - h/2, width = w/2, height = h/2},
		capacity = self.capacity
	})
    self.northwest = QuadTree({
		boundary = {x = x - w/2, y = y - h/2, width = w/2, height = h/2},
		capacity = self.capacity
	})
    self.southeast = QuadTree({
		boundary = {x = x + w/2, y = y + h/2, width = w/2, height = h/2},
		capacity = self.capacity
	})
    self.southwest = QuadTree({
		boundary = {x = x - w/2, y = y + h/2, width = w/2, height = h/2},
		capacity = self.capacity
    })

    self.divided = true
end

--- Insert an object into the QuadTree
--- @param object any
function QuadTree:insert(object)
    -- If the object is outside the boundary, skip insertion
    if (not self:contains(object)) then
        return false
    end

    -- If the current node can hold more objects, insert it here
    if (#self.objects < self.capacity) then
        table.insert(self.objects, object)
        return true
    else
        -- Subdivide and redistribute if necessary
        if (not self.divided) then
            self:subdivide()
        end

        -- Try to insert the object into each quadrant
        return self.northeast:insert(object)
            or self.northwest:insert(object)
            or self.southeast:insert(object)
            or self.southwest:insert(object)
    end
end

--- Remove an object from the QuadTree
--- @param object any
--- @return boolean
function QuadTree:remove(object)
	if (not self:contains(object)) then
		return false
	end

	for i, obj in ipairs(self.objects) do
		if (obj == object) then
			table.remove(self.objects, i)
			return true
		end
	end

	if (self.divided) then
		return self.northeast:remove(object)
			or self.northwest:remove(object)
			or self.southeast:remove(object)
			or self.southwest:remove(object)
	end

	return false
end

--- Check if a position is within the boundary
--- @param object any
--- @return boolean
function QuadTree:contains(object)
    local x, y = object.x, object.y

    return x >= (self.boundary.x - self.boundary.width) and
           x < (self.boundary.x + self.boundary.width) and
           y >= (self.boundary.y - self.boundary.height) and
           y < (self.boundary.y + self.boundary.height)
end

--- Query the QuadTree for objects within a given range
--- @param range {x: number, y: number, width: number, height: number}
--- @param found? table
--- @return table
function QuadTree:query(range, found)
    found = found or {}

    -- If the range does not intersect the boundary, return empty
    if not self:intersects(range) then return found end

    -- Check all objects in the current node
    for _, object in ipairs(self.objects) do
        if object.x >= range.x - range.width and object.x < range.x + range.width and
           object.y >= range.y - range.height and object.y < range.y + range.height then
            table.insert(found, object)
        end
    end

    -- Query subdivisions if they exist
    if self.divided then
        self.northeast:query(range, found)
        self.northwest:query(range, found)
        self.southeast:query(range, found)
        self.southwest:query(range, found)
    end

    return found
end

--- Check if a range intersects with the boundary of this node
--- @param range {x: number, y: number, width: number, height: number}
--- @return boolean
function QuadTree:intersects(range)
    return not (range.x - range.width > self.boundary.x + self.boundary.width or
                range.x + range.width < self.boundary.x - self.boundary.width or
                range.y - range.height > self.boundary.y + self.boundary.height or
                range.y + range.height < self.boundary.y - self.boundary.height)
end

return QuadTree
