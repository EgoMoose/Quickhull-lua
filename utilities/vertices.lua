-- calculate corners and points on shape
-- useful for a lot of 3D math, eg convex hull, GJK, etc.
-- EgoMoose

local cos = math.cos;
local sin = math.sin;
local insert = table.insert;

local cornerMultipliers = {
	Vector3.new(1, 1, 1);
	Vector3.new(1, 1, -1);
	Vector3.new(1, -1, -1);
	Vector3.new(-1, -1, -1);
	Vector3.new(-1, -1, 1);
	Vector3.new(-1, 1, 1);
	Vector3.new(-1, 1, -1);
	Vector3.new(1, -1, 1);
}

-- the functions that get the vertices

local function block(cf, size, t)
	for i = 1, #cornerMultipliers do
		insert(t, cf * (size * cornerMultipliers[i]));
	end
	return t;
end;

local WEDGE = {1, 3, 4, 5, 6, 8};
local function wedge(cf, size, t)
	for i = 1, #WEDGE do
		insert(t, cf * (size * cornerMultipliers[WEDGE[i]]));
	end;
	return t;
end;

local CORNERWEDGE = {2, 3, 4, 5, 8};
local function cornerWedge(cf, size, t)
	for i = 1, #CORNERWEDGE do
		insert(t, cf * (size * cornerMultipliers[CORNERWEDGE[i]]));
	end;
	return t;
end;

local PI2 = math.pi * 2;
local function cylinder(cf, size, t, amt)
	local amt = amt or 10;
	local div = PI2 / amt;
	local c1, c2 = cf * (size * Vector3.new(1, 0, 0)), cf * (size * Vector3.new(-1, 0, 0));
	local up, axis = cf * (size * Vector3.new(1, 1, 0)) - c1, (c1 - cf.p).unit;
	for i = 1, amt do
		local theta = div * i;
		-- vector axis angle rotation
		local v = up * cos(theta) + up:Dot(axis) * axis * (1 - cos(theta)) + axis:Cross(up) * sin(theta);
		insert(t, c1 + v);
		insert(t, c2 + v);
	end;
	return t;
end;

local function ball(cf, size, t, amt1, amt2)
	local right, forward, up = cf.rightVector * size.x, cf.lookVector * size.z, cf.upVector * size.y;
	local amt1, amt2 = amt1 or 8, amt2 or 8;
	local div1, div2 = PI2 / amt1, PI2 / amt2;
	for i = 1, amt1 do
		local theta = i * div1;
		local horizontal = forward * cos(theta) + right * sin(theta);
		for j = 1, amt2 do
			local theta2 = j * div2;
			local p = cf.p + horizontal * cos(theta2) + up * sin(theta2);
			insert(t, p)
		end;
	end;
	return t;
end;

-- special functions

local function getAllVertices(parts, t)
	local t = t or {};
	for i = 1, #parts do
		local part = parts[i];
		if (part.ClassName == "Part") then
			if (part.Shape == Enum.PartType.Block) then
				block(part.CFrame, part.Size*0.5, t);
			elseif (part.Shape == Enum.PartType.Cylinder) then
				cylinder(part.CFrame, part.Size*0.5, t);
			elseif (part.Shape == Enum.PartType.Ball) then
				ball(part.CFrame, part.Size*0.5, t);
			end;
		elseif (part.ClassName == "WedgePart") then
			wedge(part.CFrame, part.Size*0.5, t);
		elseif (part.ClassName == "CornerWedgePart") then
			cornerWedge(part.CFrame, part.Size*0.5, t);
		elseif (part:IsA("BasePart")) then -- mesh, CSG, truss, etc... just use block
			block(part.CFrame, part.Size*0.5, t);
		end;
	end;
	return t;
end;

-- module

return {
	block = block;
	wedge = wedge;
	cornerWedge = cornerWedge;
	cylinder = cylinder;
	ball = ball;
	getAllVertices = getAllVertices;
};