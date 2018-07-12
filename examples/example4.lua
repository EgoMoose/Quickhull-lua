-- same as testcase3, but draws lines instead of triangles

local qhull = require(game.Workspace.qhull.quickHull);
local draw = require(game.Workspace.qhull.draw);
local vertices = require(game.Workspace.qhull.vertices);

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

local parts = gather(model:GetChildren(), "BasePart");
local points = vertices.getAllVertices(parts);

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
	
	local centroid = (a + b + c) / 3;
	local normal = (b - a):Cross(c - a).unit;
	draw.line(centroid, centroid + normal * 5, game.Workspace.Model).BrickColor = BrickColor.White();	
	
	draw.line(a, b, game.Workspace.Model);
	draw.line(b, c, game.Workspace.Model);
	draw.line(c, a, game.Workspace.Model);
end;
--]]