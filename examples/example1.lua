local qhull = require(game.Workspace.qhull.quickHull);
local draw = require(game.Workspace.qhull.draw);

math.randomseed(tick());

local points = {};
for i = 1, 20 do
	table.insert(points, Vector3.new(
		math.random(-10, 10),
		math.random(-10, 10),
		math.random(-10, 10)
	));
end;

local test = qhull.new(points);
test:build();
local faces = test:collectFaces(false);

---[[
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
	
	--draw.triangle(a, b, c, game.Workspace.Model);
	---[[
	draw.line(a, b, game.Workspace.Model);
	draw.line(b, c, game.Workspace.Model);
	draw.line(c, a, game.Workspace.Model);
	--]]
end;
--]]