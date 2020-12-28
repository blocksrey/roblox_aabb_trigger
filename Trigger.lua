local Signal = _G.require("Signal")
local Toilet = _G.require("Toilet")

local function outBox(p, v, r)
	local px = p.x
	local py = p.y
	local pz = p.z

	local vx = v.x
	local vy = v.y
	local vz = v.z

	local rx = r.x
	local ry = r.y
	local rz = r.z

	return
		px > vx + rx or
		px < vx - rx or
		py > vy + ry or
		py < vy - ry or
		pz > vz + rz or
		pz < vz - rz
end

local Trigger = {}
Trigger.__index = Trigger

function Trigger.new(position, radius, ignore)
	local self = setmetatable({}, Trigger)

	self._position   = position or Vector3.new()
	self._radius     = radius   or Vector3.new()
	self._ignore     = ignore   or {}
	self._parts      = Toilet.new()
	self.partEntered = Signal.new()
	self.partExited  = Signal.new()

	return self
end

function Trigger:Update()
	local parts = workspace:FindPartsInRegion3WithIgnoreList(
		Region3.new(
			self._position - self._radius,
			self._position + self._radius
		),
		self._ignore,
		math.huge
	)

	for _, part in next, parts do
		if not outBox(part.Position, self._position, self._radius) then
			self._parts:Dump(part)
		end
	end

	for _, part in next, self._parts:Clean() do
		self.partEntered:Fire(part)
	end

	for _, part in next, self._parts:Flush() do
		self.partExited:Fire(part)
	end
end

function Trigger:GetActive()
	return self._parts.contents
end

function Trigger:Destroy()
	self._position   = nil
	self._radius     = nil
	self._ignore     = nil

	self._parts:Destroy()
	self._parts      = nil

	self.partEntered:Destroy()
	self.partEntered = nil

	self.partExited:Destroy()
	self.partExited  = nil

	setmetatable(self, nil)
end

return Trigger