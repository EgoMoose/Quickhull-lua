local qhull = require(game.Workspace.qhull.quickHull);
local draw = require(game.Workspace.qhull.draw);


local model = game.Workspace.ModelTest;

local function gather(t, class, nt)
	local nt = nt or {};
	for i = 1, #t do
		if (t[i]:IsA(class)) then
			table.insert(nt, t[i]);
		end;
		nt = gather(t[i]:GetChildren(), class, nt);
	end;
	return nt;
end;

local function addCorners(cf, size, t)
    local size = size / 2;
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                table.insert(t, (cf * CFrame.new(size * Vector3.new(x, y, z))).p);
            end;
        end;
    end;
end;

local parts = gather(model:GetChildren(), "BasePart");
local points = {};
for i = 1, #parts do
	addCorners(parts[i].CFrame, parts[i].Size, points);
end;

local test = qhull.new(points);
test:build();
local faces = test:collectFaces(false);

--[[
for i = 1, #points do
	local p = points[i];
	draw.point(p, game.Workspace.Model);
end;
--]]

---[[
for i = 1, #faces do
	local f = faces[i];
	local a = test.vertices[f[1]].point;
	local b = test.vertices[f[2]].point;
	local c = test.vertices[f[3]].point;
	draw.triangle(a, b, c, game.Workspace.Model, 0.7);
end;
--]]