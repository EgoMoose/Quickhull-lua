-- 3D drawing functions
-- contains a few basic 3D shapes that are useful when testing, etc
-- EgoMoose

local wedge = Instance.new("WedgePart");
wedge.Anchored = true;
wedge.TopSurface = Enum.SurfaceType.Smooth;
wedge.BottomSurface = Enum.SurfaceType.Smooth;

local part = Instance.new("Part");
part.Size = Vector3.new(0.1, 0.1, 0.1);
part.Anchored = true;
part.TopSurface = Enum.SurfaceType.Smooth;
part.BottomSurface = Enum.SurfaceType.Smooth;
part.Material = Enum.Material.Neon;

local function drawPoint(p, parent)
	local point = part:Clone();
	point.CFrame = CFrame.new(p);
	point.BrickColor = BrickColor.Blue();
	point.Parent = parent;
	return point;
end;

local function drawLine(a, b, parent)
	local v = (b - a);
	local cf = CFrame.new(a + v * 0.5, b);
	local line = part:Clone();
	line.CFrame = cf;
	line.Size = Vector3.new(0.1, 0.1, v.magnitude);
	line.BrickColor = BrickColor.Red();
	line.Parent = parent;
	return line;
end

local function drawTriangle(a, b, c, parent, transparency)
	local edges = {
		{longest = (c - b), other = (a - b), position = b};
		{longest = (a - c), other = (b - c), position = c};
		{longest = (b - a), other = (c - a), position = a};
	};
	table.sort(edges, function(a, b) return a.longest.magnitude > b.longest.magnitude end);
	local edge = edges[1];
	local theta = math.acos(edge.longest.unit:Dot(edge.other.unit));
	local s1 = Vector2.new(edge.other.magnitude * math.cos(theta), edge.other.magnitude * math.sin(theta));
	local s2 = Vector2.new(edge.longest.magnitude - s1.x, s1.y);
	local p1 = edge.position + edge.other * 0.5;
	local p2 = edge.position + edge.longest + (edge.other - edge.longest) * 0.5;
	local right = edge.longest:Cross(edge.other).unit;
	local up = right:Cross(edge.longest).unit;
	local back = edge.longest.unit;
	local cf1 = CFrame.new(
		p1.x, p1.y, p1.z,
		-right.x, up.x, back.x,
		-right.y, up.y, back.y,
		-right.z, up.z, back.z
	);
	local cf2 = CFrame.new(
		p2.x, p2.y, p2.z,
		right.x, up.x, -back.x,
		right.y, up.y, -back.y,
		right.z, up.z, -back.z
	);
	local w1 = wedge:Clone();
	local w2 = wedge:Clone();
	w1.Size = Vector3.new(0.2, s1.y, s1.x);
	w2.Size = Vector3.new(0.2, s2.y, s2.x);
	w1.Transparency = transparency or 0;
	w2.Transparency = transparency or 0;
	w1.CFrame = cf1;
	w2.CFrame = cf2;
	w1.Parent = parent;
	w2.Parent = parent;
end;

return {
	triangle = drawTriangle;
	point = drawPoint;
	line = drawLine;
};