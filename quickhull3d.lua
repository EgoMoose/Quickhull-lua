--[[
-- https://github.com/EgoMoose/Quickhull-lua
-- Implementation of quick hull algorithm for Lua
-- EgoMoose

-- ported to lua from
-- https://github.com/maurizzzio/quickhull3d/blob/master/lib/QuickHull.js

NOTE:
THERE ARE MOST CERTAINLY BUGS, BUT SO TREAT THE PROCESS LIKE CSG. 
SOMETIMES THINGS ARE FINICKY AND UNSOLVEABLE. I WOULDN'T RECOMMEND BASING A GAME AROUND THIS!!
YOU MIGHT BE ABLE TO USE IT FOR A PLUGIN OR SOMETHING DEVELOPER BASED, BUT DO NOT, I REPEAT, DO NOT
USE THIS FOR ACTUAL GAMEPLAY!!
	
API:

Constructors:
	quickhull.new(points)
		> Requires at least four points.
		> Creates a quickhull class out of a table of zero-indexed points which are also represented by a table. Eg:
		>	{[0] = x, [1] = y, [2] = z};
		> The points table is also indexed by zer. Eg:
		>	{[0] = point1, [1] = point2, [2] = point3, ...};
	quickhull.fromVector3(points)
		> Creates a quickhull class out of a table of vectors.
		> The points table in this case is 1-index (just like default Lua) for ease of access

Methods:
	quickhull:build()
		> Computes the quickhull of all the points stored in the Instance
	quickhull:collectFaces(skipTriangulation)
		> if skipTriangulation is set to true returns an array of n-element arrays which have the index of the points 
		> in the constructor point table
		> if skipTriangulation is set to false returns an array of 3-element arrays which have the 3 vector3 vertices in them
		> that represent a singular face of the hull polygon.

Functions:
	quickhull.quickrun(points)
		> takes a 1-indexed table of vector3 points and returns the triangular faces of that set of points quick hull.
		
Example of usage:

local model = game.Workspace.Model; -- model full of parts that represent points
local camera = game.Workspace.CurrentCamera;
local qhull = require(game.Workspace.quickhull); -- this module

function update()
	local set = {};
	for i, part in next, model:GetChildren() do
		table.insert(set, part.Position);
	end;
	
	camera:ClearAllChildren();
	for _, face in next, qhull.quickrun(set) do
		-- http://wiki.roblox.com/index.php?title=3D_triangles
		drawTriangle(face[1], face[2], face[3], camera);
	end;
end;

update();


This module was built with the intent of being used in RBX.Lua however, it can also be used for pure Lua with very little modification.
Two things pure Lua users must be aware of:

	+ RBX.Lua has its own vector3 class, which can be used as an input with the quickhull.fromVector3 function. 
	  This function is not relevant to a pure Lua implementation
	+ The collectFaces() method when used without triangulation returns Vector3. It's easy to swap this over to a table
	+ The quickhull.new constructor expects that the points table it recieves is zero-indexed. I would've liked to have ported 
	  this with the default Lua index of 1, however due to the sheer size and complexity of the original JS code I decided to retain 
	  the zero-index. If this really bothers you a simple pass over like in the quickhull.fromVector3 function does wonders.
--]]

-- functions related to vectors

function dot(a, b)
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
end;

function cross(out, a, b)
	out[0] = a[1] * b[2] - a[2] * b[1];
	out[1] = a[2] * b[0] - a[0] * b[2];
	out[2] = a[0] * b[1] - a[1] * b[0];
	return out;
end;

function add(out, a, b)
	out[0] = a[0] + b[0];
	out[1] = a[1] + b[1];
	out[2] = a[2] + b[2];
	return out;
end;

function subtract(out, a, b)
	out[0] = a[0] - b[0];
	out[1] = a[1] - b[1];
	out[2] = a[2] - b[2];
	return out;
end;

function length(a)
	return math.sqrt(dot(a, a));
end;

function squaredLength(a)
	return dot(a, a);
end;

function scale(out, a, b)
	out[0] = a[0] * b;
	out[1] = a[1] * b;
	out[2] = a[2] * b;
	return out;
end;

function scaleAndAdd(out, a, b, scale)
	out[0] = a[0] + (b[0] * scale);
	out[1] = a[1] + (b[1] * scale);
	out[2] = a[2] + (b[2] * scale);
	return out;
end;

function normalize(out, a)
	local l = dot(a, a)
	if l > 0 then
		l = 1 / math.sqrt(l);
		out[0] = a[0] * l;
		out[1] = a[1] * l;
		out[2] = a[2] * l;
	end;
	return out;
end;

function copy(out, a)
	out[0] = a[0];
	out[1] = a[1];
	out[2] = a[2];
	return out;
end;

function squaredDistance(a, b)
	local x = b[0] - a[0];
	local y = b[1] - a[1];
	local z = b[2] - a[2];
	return x*x + y*y + z*z;
end;

function distance(a, b)
	local x = b[0] - a[0];
	local y = b[1] - a[1];
	local z = b[2] - a[2];
	return math.sqrt(x*x + y*y + z*z);
end;

function pointLineDistance(p, a, b)
	local ab, ap, cr = {}, {}, {};
	subtract(ab, b, a);
	subtract(ap, p, a);
	local area = squaredLength(cross(cr, ap, ab));
	local s = squaredLength(ab);
	if s == 0 then
		error("a and b are the same point");
	end;
	return math.sqrt(area / s);
end;

function planeNormal(out, point1, point2, point3)
	local tmp = {[0]=0, 0, 0};
	subtract(out, point1, point2);
	subtract(tmp, point2, point3);
	cross(out, out, tmp);
	return normalize(out, out);
end;

-- zero-index table manipulation 
-- Lua seriously needs to work in better support for this

function getLength(t)
	-- can't get proper length without iteration?
	local tlen = 0;
	for k, v in next, t do tlen = tlen + 1; end;
	return tlen;
end;

function push(t, ...)
	local tlen = getLength(t);
	for i, value in next, {...} do
		t[tlen + (i - 1)] = value;
	end;
end;

-- vertex class

local vertex = {};

function vertex.new(point, index)
	local self = setmetatable({}, {__index = vertex});
	self.point = point;
	self.index = index;
	self.next = nil;
	self.prev = nil;
	self.face = nil; -- face that is able to see the point
	return self;
end;

-- vertex list class

local vertextList = {};

function vertextList.new()
	local self = setmetatable({}, {__index = vertextList});
	self.head = nil;
	self.tail = nil;
	return self;
end;

function vertextList:clear()
	self.head = nil;
	self.tail = nil;
end;

function vertextList:insertBefore(target, node)
	node.prev = target.prev;
	node.next = target;
	if not node.prev then
		self.head = node;
	else
		node.prev.next = node;
	end;
	target.prev = node;
end;

function vertextList:insertAfter(target, node)
	node.prev = target;
	node.next = target.next;
	if not node.next then
		self.tail = node
	else
		node.next.prev = node;
	end;
	target.next = node;
end;

function vertextList:add(node)
	if not self.head then
		self.head = node;
	else
		self.tail.next = node;
	end;
	node.prev = self.tail;
	node.next = nil;
	self.tail = node;
end;

function vertextList:addAll(node)
	if not self.head then
		self.head = node;
	else
		self.tail.next = node;
	end;
	node.prev = self.tail;
	
	while node.next do
		node = node.next;
	end;
	self.tail = node;
end;

function vertextList:remove(node)
	if not node.prev then
		self.head = node.next;
	else
		node.prev.next = node.next;
	end;
	
	if not node.next then
		self.tail = node.prev;
	else
		node.next.prev = node.prev;
	end;
end;

function vertextList:removeChain(a, b)
	if not a.prev then
		self.head = b.next;
	else
		a.prev.next = b.next;
	end;
	
	if not b.next then
		self.tail = a.prev;
	else
		b.next.prev = a.prev;
	end;
end;

function vertextList:first()
	return self.head;
end;

function vertextList:isEmpty()
	return not self.head;
end;

-- half edge class

local halfEdge = {};

function halfEdge.new(vertex, face)
	local self = setmetatable({}, {__index = halfEdge});
	self.vertex = vertex;
	self.face = face;
	self.next = nil;
	self.prev = nil;
	self.opposite = nil;
	return self;
end;

function halfEdge:head()
	return self.vertex;
end;

function halfEdge:tail()
	return self.prev and self.prev.vertex or nil;
end;

function halfEdge:length()
	if self:tail() then
		return distance(
			self:tail().point,
			self:tail().point
		);
	end;
	return -1;
end;

function halfEdge:lengthSquared()
	if self:tail() then
		return squaredDistance(
			self:tail().point,
			self:head().point
		);
	end
	return -1;
end;

function halfEdge:setOpposite(edge)
	-- debug function?
	self.opposite = edge;
	edge.opposite = self;
end;

-- face class

local VISIBLE = 0;
local NON_CONVEX = 1;
local DELETED = 2;

local face = {};

function face.new()
	local self = setmetatable({}, {__index = face});
	self.normal = {};
	self.centroid = {};
	self.offset = 0;
	self.outside = nil;
	self.mark = VISIBLE;
	self.edge = nil;
	self.nVertices = 0;
	return self;
end;

function face:getEdge(i)
	if type(i) ~= "number" then
		error("requires a number");
	end;
	local it = self.edge;
	while i > 0 do
		it = it.next;
		i = i - 1;
	end;
	while i < 0 do
		it = it.prev;
		i = i + 1;
	end;
	return it;
end;

function face:computeNormal()
	local e0 = self.edge;
	local e1 = e0.next;
	local e2 = e1.next;
	local v2 = subtract({}, e1:head().point, e0:head().point);
	local t = {};
	local v1 = {};
	
	self.nVertices = 2;
	self.normal = {[0]=0, 0, 0};
	while e2 ~= e0 do
		copy(v1, v2);
		subtract(v2, e2:head().point, e0:head().point);
		add(self.normal, self.normal, cross(t, v1, v2));
		e2 = e2.next;
		self.nVertices = self.nVertices + 1;
	end;
	self.area = length(self.normal);
	self.normal = scale(self.normal, self.normal, 1 / self.area); -- normalization, cheaper to do this ourselves b/c we already calc'd the area
end;

function face:computeNormalMinArea(minArea)
	self:computeNormal();
	if self.area < minArea then
		local maxEdge;
		local maxSquaredLength = 0;
		local edge = self.edge;
		
		repeat
			local lengthSquared = edge:lengthSquared();
			if lengthSquared > maxSquaredLength then
				maxEdge = edge;
				maxSquaredLength = lengthSquared;
			end;
			edge = edge.next;
		until (edge == self.edge);
		
		local p1 = maxEdge:tail().point;
		local p2 = maxEdge:head().point;
		local maxVector = subtract({}, p2, p1);
		local maxLength = math.sqrt(maxSquaredLength);
		scale(maxVector, maxVector, 1 / maxLength);
		local maxProjection = dot(self.normal, maxVector);
		scaleAndAdd(self.normal, self.normal, maxVector, -maxProjection);
		normalize(self.normal, self.normal);
	end;
end;

function face:computeCentroid()
	self.centroid = {[0]=0, 0, 0};
	local edge = self.edge;
	repeat
		add(self.centroid, self.centroid, edge:head().point);
		edge = edge.next;
	until (edge == self.edge);
	scale(self.centroid, self.centroid, 1 / self.nVertices);
end;

function face:computeNormalAndCentroid(minArea)
	if type(minArea) == "number" then
		self:computeNormalMinArea(minArea);
	else
		self:computeNormal();
	end;
	self:computeCentroid();
	self.offset = dot(self.normal, self.centroid);
end;

function face:distanceToPlane(point)
	return dot(self.normal, point) - self.offset;
end;

function face:connectHalfEdges(prev, next_)
	local discardedFace;
	if prev.opposite.face == next_.opposite.face then
		local oppositeFace = next_.opposite.face;
		local oppositeEdge;
		if prev == self.edge then
			self.edge = next_;
		end;
		if oppositeFace.nVertices == 3 then
			oppositeEdge = next_.opposite.prev.opposite;
			oppositeFace.mark = DELETED;
			discardedFace = oppositeFace;
		else
			oppositeEdge = next_.opposite.next;
			if oppositeFace.edge == oppositeEdge.prev then
				oppositeFace.edge = oppositeEdge;
			end;
			oppositeEdge.prev = oppositeEdge.prev.prev;
			oppositeEdge.prev.next = oppositeEdge;
		end;
		next_.prev = prev.prev;
		next_.prev.next = next_;
		next_:setOpposite(oppositeEdge);
		oppositeFace:computeNormalAndCentroid();
	else
		prev.next = next_;
		next_.prev = prev;
	end;
	return discardedFace;
end;

function face:mergeAdjacentFaces(adjacentEdge, discardedFaces)
	local oppositeEdge = adjacentEdge.opposite;
	local oppositeFace = oppositeEdge.face;
	
	push(discardedFaces, oppositeFace);
	oppositeFace.mark = DELETED;
	
	local adjacentEdgePrev = adjacentEdge.prev;
	local adjacentEdgeNext = adjacentEdge.next;
	local oppositeEdgePrev = oppositeEdge.prev;
	local oppositeEdgeNext = oppositeEdge.next;
	
	while adjacentEdgeNext.opposite.face == oppositeFace do
		adjacentEdgePrev = adjacentEdgePrev.prev;
		oppositeEdgeNext = oppositeEdgeNext.next;
	end;
	
	while adjacentEdgeNext.opposite.face == oppositeFace do
		adjacentEdgeNext = adjacentEdgeNext.next;
		oppositeEdgePrev = oppositeEdgePrev.prev;
	end;
	
	local edge = oppositeEdgeNext;
	while edge ~= oppositeEdgePrev.next do
		edge.face = self;
		edge = edge.next;
	end;
	
	self.edge = adjacentEdgeNext;
	
	local discardedFace = self:connectHalfEdges(oppositeEdgePrev, adjacentEdgeNext);
	if discardedFace then
		push(discardedFaces, discardedFace);
	end;
	
	discardedFace = self:connectHalfEdges(adjacentEdgePrev, oppositeEdgeNext);
	if discardedFace then
		push(discardedFaces, discardedFace);
	end;
	
	self:computeNormalAndCentroid();
	return discardedFaces;
end;

function face:collectIndices()
	local indices = {};
	local edge = self.edge;
	repeat
		push(indices, edge:head().index);
		edge = edge.next;
	until (edge == self.edge);
	return indices;
end;

function face.createTriangle(v0, v1, v2, minArea)
	local minArea = minArea or 0;
	local face = face.new();
	local e0 = halfEdge.new(v0, face);
	local e1 = halfEdge.new(v1, face);
	local e2 = halfEdge.new(v2, face);
	
	e0.next = e1; e2.prev = e1;
	e1.next = e2; e0.prev = e2;
	e2.next = e0; e1.prev = e0;
	
	face.edge = e0;
	face:computeNormalAndCentroid(minArea);
	return face;
end;

-- quickhull class

local EPSILON = 2^-52;
local MERGE_NON_CONVEX_WRT_LARGER_FACE = 1;
local MERGE_NON_CONVEX = 2;

local quickhull = {};

function quickhull.new(points)
	if type(points) ~= "table" then
		error("input is not a valid set of points");
	elseif getLength(points) < 4 then
		error("cannot build a simplex out of less than four points");
	end;
	
	local self = setmetatable({}, {__index = quickhull});
	self.tolerance = -1;
	self.nFaces = 0;
	self.nPoints = getLength(points);
	self.points = points;
	self.faces = {};
	self.newFaces = {};
	self.claimed = vertextList.new();
	self.unclaimed = vertextList.new();
	self.vertices = {};
	for i = 0, self.nPoints-1 do
		push(self.vertices, vertex.new(points[i], i));
	end;
	self.discardedFaces = {};
	self.vertexPointIndices = {};
	return self;
end;

function quickhull:addVertexToFace(vertex, face)
	vertex.face = face;
	if not face.outside then
		self.claimed:add(vertex);
	else
		self.claimed:insertBefore(face.outside, vertex);
	end;
	face.outside = vertex;
end;

function quickhull:removeVertexFromFace(vertex, face)
	if vertex == face.outside then
		if vertex.next and vertex.next.face == face then
			face.outside = vertex.next;
		else
			face.outside = nil;
		end;
	end;
	self.claimed:remove(vertex);
end;

function quickhull:removeAllVerticesFromFace(face)
	if face.outside then
		local end_ = face.outside;
		while end_.next and end_.next.face == face do
			end_ = end_.next;
		end;
		self.claimed:removeChain(face.outside, end_);
		end_.next = nil;
		return face.outside;
	end;
end;

function quickhull:deleteFaceVertices(face, absorbingFace)
	local faceVertices = self:removeAllVerticesFromFace(face);
	if faceVertices then
		if not absorbingFace then
			self.unclaimed:addAll(faceVertices);
		else
			local nextVertex = faceVertices;
			while vertex do
				nextVertex = vertex.next;
				local distance = absorbingFace:distanceToPlane(vertex.point);
				if distance >= self.tolerance then
					self:addVertexToFace(vertex, absorbingFace);
				else
					self.unclaimed:add(vertex);
				end;
				vertex = nextVertex;
			end;
		end;
	end;
end;

function quickhull:resolveUnclaimedPoints(newFaces)
	local vertexNext = self.unclaimed:first();
	local vertex = vertexNext;
	while vertex do
		vertexNext = vertex.next;
		local maxDistance = self.tolerance;
		local maxFace;
		for i = 0, getLength(newFaces)-1 do
			local face = newFaces[i];
			if face.mark == VISIBLE then
				local dist = face:distanceToPlane(vertex.point);
				if dist >= maxDistance then
					maxDistance = dist;
					maxFace = face;
				end;
				if maxDistance > 1000 * self.tolerance then
					break;
				end;
			end;
		end;
		if maxFace then
			self:addVertexToFace(vertex, maxFace);
		end;
		vertex = vertexNext;
	end;
end;

function quickhull:computeExtremes()
	local min = {};
	local max = {};
	
	local minVertices = {};
	local maxVertices = {};
	
	for i = 0, 2 do
		minVertices[i] = self.vertices[0];
		maxVertices[i] = self.vertices[0];
	end;

	for i = 0, 2 do
		min[i] = self.vertices[0].point[i];
		max[i] = self.vertices[0].point[i];
	end;
	
	for i = 0, getLength(self.vertices)-1 do
		local vertex = self.vertices[i];
		local point = vertex.point;
		for j = 0, 2 do
			if point[j] < min[j] then
				min[j] = point[j];
				minVertices[j] = vertex;
			end;
		end;
		for j = 0, 2 do
			if point[j] > max[j] then
				max[j] = point[j];
				maxVertices[j] = vertex;
			end;
		end;
	end;
	
	self.tolerance = 3 * EPSILON * (
		math.max(math.abs(min[0]), math.abs(max[0])) +
		math.max(math.abs(min[1]), math.abs(max[1])) +
		math.max(math.abs(min[2]), math.abs(max[2]))
	);
	return minVertices, maxVertices;
end;

function quickhull:createInitialSimplex()
	local vertices = self.vertices;
	local min, max = self:computeExtremes();
	
	local maxDistance = 0;
	local indexMax = 0;
	for i = 0, 2 do
		local distance = max[i].point[i] - min[i].point[i];
		if distance >= maxDistance then
			maxDistance = distance;
			indexMax = i;
		end;
	end;
	local v0 = min[indexMax];
	local v1 = max[indexMax];
	local v2, v3;
	
	maxDistance = 0;

	for i = 0, getLength(self.vertices)-1 do
		local vertex = self.vertices[i];
		if vertex ~= v0 and vertex ~= v1 then
			local distance = pointLineDistance(vertex.point, v0.point, v1.point);
			if distance >= maxDistance then
				maxDistance = distance;
				v2 = vertex;
			end;
		end;
	end;
	
	local normal = planeNormal({}, v0.point, v1.point, v2.point);
	local distPO = dot(v0.point, normal);
	maxDistance = 0;

	for i = 0, getLength(self.vertices)-1 do
		local vertex = self.vertices[i];
		if vertex ~= v0 and vertex ~= v1 and vertex ~= v2 then
			local distance = math.abs(dot(normal, vertex.point) - distPO);
			if distance >= maxDistance then
				maxDistance = distance;
				v3 = vertex;
			end;
		end;
	end;
	
	local faces = {};
	if dot(v3.point, normal) - distPO < 0 then
		push(faces, 
			face.createTriangle(v0, v1, v2),
			face.createTriangle(v3, v1, v0),
			face.createTriangle(v3, v2, v1),
			face.createTriangle(v3, v0, v2)
		);
		for i = 0, 2 do
			local j = (i + 1) % 3;
			faces[i+1]:getEdge(2):setOpposite(faces[0]:getEdge(j));
			faces[i+1]:getEdge(1):setOpposite(faces[j+1]:getEdge(0));
		end;
	else
		push(faces, 
			face.createTriangle(v0, v2, v1),
			face.createTriangle(v3, v0, v1),
			face.createTriangle(v3, v1, v2),
			face.createTriangle(v3, v2, v0)
		);
		for i = 0, 2 do
			local j = (i + 1) % 3;
			faces[i+1]:getEdge(2):setOpposite(faces[0]:getEdge((3 - i) % 3));
			faces[i+1]:getEdge(0):setOpposite(faces[j+1]:getEdge(1));
		end;
	end;
	
	for i = 0, 3 do
		push(self.faces, faces[i]);
	end;
	
	for i = 0, getLength(self.vertices)-1 do
		local vertex = self.vertices[i];
		if vertex ~= v0 and vertex ~= v1 and vertex ~= v3 and vertex ~= v3 then --??
			maxDistance = self.tolerance;
			local maxFace;
			for j = 0, 3 do
				local distance = faces[j]:distanceToPlane(vertex.point);
				if distance >= maxDistance then
					maxDistance = distance;
					maxFace = faces[j];
				end;
			end
			if maxFace then
				self:addVertexToFace(vertex, maxFace);
			end;
		end;
	end;
end;

function quickhull:reindexFaceAndVertices()
	local activeFaces = {};
	for i = 0, getLength(self.faces)-1 do
		local face = self.faces[i];
		if face.mark == VISIBLE then
			push(activeFaces, face);
		end;
	end;
	self.faces = activeFaces;
end;

function quickhull:collectFaces(skipTriangulation)
	local faceIndices = {};
	for i = 0, getLength(self.faces)-1 do
		if self.faces[i].mark ~= VISIBLE then
			error("attempt to include a destroyed face in the hull");
		end;
		local indices = self.faces[i]:collectIndices();
		if skipTriangulation then
			--push(faceIndices, indices);
			table.insert(faceIndices, indices);
		else
			for j = 0, getLength(indices)-3 do
				--push(faceIndices, {[0]=indices[0], indices[j+1], indices[j+2]});
				local a = self.points[indices[0]];
				local b = self.points[indices[j+1]];
				local c = self.points[indices[j+2]];
				table.insert(faceIndices, {
					Vector3.new(a[0], a[1], a[2]),
					Vector3.new(b[0], b[1], b[2]),
					Vector3.new(c[0], c[1], c[2])
				});
			end;
		end;
	end;
	return faceIndices;
end;

function quickhull:nextVertexToAdd()
	if not self.claimed:isEmpty() then
		local eyevertex;
		local maxDistance = 0;
		local eyeFace = self.claimed:first().face;
		local vertex = eyeFace.outside;
		while vertex and vertex.face == eyeFace do
			local distance = eyeFace:distanceToPlane(vertex.point);
			if distance >= maxDistance then
				maxDistance = distance;
				eyevertex = vertex;
			end;
			vertex = vertex.next;
		end;
		return eyevertex;
	end;
end;

function quickhull:computeHorizon(eyePoint, crossEdge, face, horizon)
	self:deleteFaceVertices(face);
	face.mark = DELETED;
	local edge;
	if not crossEdge then
		edge = face:getEdge(0);
		crossEdge = edge;
	else
		edge = crossEdge.next;
	end;
	
	repeat
		local oppositeEdge = edge.opposite;
		local oppositeFace = oppositeEdge.face;
		if oppositeFace.mark == VISIBLE then
			if oppositeFace:distanceToPlane(eyePoint) > self.tolerance then
				self:computeHorizon(eyePoint, oppositeEdge, oppositeFace, horizon);
			else
				push(horizon, edge);
			end;
		end;
		edge = edge.next;
	until (edge == crossEdge);
end;

function quickhull:addAdjoiningFace(eyeVertex, horizonEdge)
	local Face = face.createTriangle(eyeVertex, horizonEdge:tail(), horizonEdge:head());
	push(self.faces, Face);
	Face:getEdge(-1):setOpposite(horizonEdge.opposite);
	return Face:getEdge(0);
end;

function quickhull:addNewFaces(eyeVertex, horizon)
	self.newFaces = {};
	local firstSideEdge, previousSideEdge;
	for i = 0, getLength(horizon)-1 do
		local horizonEdge = horizon[i];
		local sideEdge = self:addAdjoiningFace(eyeVertex, horizonEdge);
		if not firstSideEdge then
			firstSideEdge = sideEdge;
		else
			sideEdge.next:setOpposite(previousSideEdge);
		end;
		push(self.newFaces, sideEdge.face);
		previousSideEdge = sideEdge;
	end;
	firstSideEdge.next:setOpposite(previousSideEdge);
end;

function quickhull:getTriangulatedFaces()
	local faces = {};
	for i = 0, getLength(self.faces)-1 do
		for j, t in next, self.faces[i]:triangulate() do
			push(faces, t);
		end;
	end;
	return faces;
end;

function quickhull:oppositeFaceDistance(edge)
	return edge.face:distanceToPlane(edge.opposite.face.centroid);
end;

function quickhull:doAdjacentMerge(face, mergeType)
	local edge = face.edge;
	local convex = true;
	local it = 0;
	repeat
		if it >= face.nVertices then
			error("merge recursion limit exceeded");
		end;
		local oppositeFace = edge.opposite.face;
		local merge = false;
		
		if mergeType == MERGE_NON_CONVEX then
			if self:oppositeFaceDistance(edge) > -self.tolerance or self:oppositeFaceDistance(edge.opposite) > -self.tolerance then
				merge = true;
			end;
		else
			if face.area > oppositeFace.area then
				if self:oppositeFaceDistance(edge) > -self.tolerance then
					merge = true;
				elseif self:oppositeFaceDistance(edge.opposite) > -self.tolerance then
					convex = false;
				end;
			else
				if self:oppositeFaceDistance(edge.opposite) > -self.tolerance then
					merge = true;
				elseif self:oppositeFaceDistance(edge) > -self.tolerance then
					convex = false;
				end;
			end;
			
			if merge then
				local discardedFaces = face:mergeAdjacentFaces(edge, {});
				for i = 0, getLength(discardedFaces)-1 do
					self:deleteFaceVertices(discardedFaces[i], face);
				end;
				return true;
			end;
		end;
		
		edge = edge.next;
		it = it + 1;
	until (edge == face.edge);
	
	if not convex then
		face.mark = NON_CONVEX;
	end;
	return false;
end;

function quickhull:addVertexToHull(eyeVertex)
	local horizon = {};
	
	self.unclaimed:clear();
	
	self:removeVertexFromFace(eyeVertex, eyeVertex.face);
	self:computeHorizon(eyeVertex.point, nil, eyeVertex.face, horizon);
	self:addNewFaces(eyeVertex, horizon);
	
	for i = 0, getLength(self.newFaces)-1 do
		local face = self.newFaces[i];
		if face.mark == VISIBLE then
			while (self:doAdjacentMerge(face, MERGE_NON_CONVEX_WRT_LARGER_FACE)) do
			end;
		end;
	end;
	
	for i = 0, getLength(self.newFaces)-1 do
		local face = self.newFaces[i];
		if face.mark == NON_CONVEX then
			face.mark = VISIBLE;
			while (self:doAdjacentMerge(face, MERGE_NON_CONVEX)) do
			end;
		end;
	end;
	
	self:resolveUnclaimedPoints(self.newFaces);
end;

function quickhull:build()
	local iterations = 0;
	self:createInitialSimplex();
	local eyeVertex = self:nextVertexToAdd();
	while eyeVertex do
		iterations = iterations + 1;
		self:addVertexToHull(eyeVertex);
		eyeVertex = self:nextVertexToAdd();
	end;
	self:reindexFaceAndVertices();
end;

function quickhull.fromVector3(points)
	local set = {};
	for i, p in next, points do
		set[i-1] = {[0]=p.x, p.y, p.z};
	end;
	return quickhull.new(set);
end;

function quickhull.quickrun(points)
	local qh = quickhull.fromVector3(points);
	qh:build();
	return qh:collectFaces();
end;

return quickhull;