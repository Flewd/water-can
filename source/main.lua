import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/math"
import "CoreLibs/sprites"
import "time"

local gfx <const> = playdate.graphics
local vector2 <const> = playdate.geometry.vector2D

local playerSprite = nil

local playerSpeed = 5;

local score = 0;


local waterSpawnTimer = 0
local waterSpawnDuration = 0.1

local dropAccelertation = 5
local drops = {}
local dropVelocity = {}

local potSprites = {}
local flowerSprites = {}
local potProgress = {}
local potDropRequirement = 15

local function RotatePoint(point, centerPoint, degrees)

    local angleInRadians = degrees * (math.pi / 180);
    local cosTheta = math.cos(angleInRadians);
    local sinTheta = math.sin(angleInRadians);
    
	return vector2.new(
		--X
		(cosTheta * (point.dx - centerPoint.dx) -
		sinTheta * (point.dy - centerPoint.dy) + centerPoint.dx),
		--Y
		(sinTheta * (point.dx - centerPoint.dx) +
		cosTheta * (point.dy - centerPoint.dy) + centerPoint.dy)
	)
end

local function PourWater()

	local rot = playerSprite:getRotation()
	if rot >= 45 and rot <= 140 then
		
		 waterSpawnTimer -= DeltaTimeSeconds()

		if waterSpawnTimer <= 0 then
			waterSpawnTimer = waterSpawnDuration

			local dropImage = gfx.image.new("images/drop")
			dropSprite = gfx.sprite.new(dropImage)
			dropSprite:setCollideRect(0,0, dropSprite:getSize())

			local origin = vector2.new(playerSprite.x, playerSprite.y)
			local point = vector2.new(playerSprite.x + (playerSprite.width/2), playerSprite.y - playerSprite.height/2)
			local dropPos = RotatePoint(point, origin, playerSprite:getRotation())
			
			local randOffsetX = math.random(35, 55) * -1
			local randOffsetY = math.random(25, 30)
			
			--hack because the method of rotating the drop spawn point isn't accurate. so shift it a bit
			--when the pot is facing straight down the drops y pos is way off
			--local normalizedRot = (rot - 45) / (140 - 45)
			--local yOffset = playdate.math.lerp(0, randOffsetY, normalizedRot)

			dropPos.dx += randOffsetX;
			dropPos.dy += randOffsetY;


			dropSprite:moveTo(dropPos.x, dropPos.y)
			dropSprite:add()

			table.insert(drops, dropSprite)
			table.insert(dropVelocity, 1 )
		end
	else
		waterSpawnTimer = 0
	end
end

local function MoveDrops()
	for i=1, #drops do
		local drop = drops[i]
		local velocity = dropVelocity[i]
		drop:moveTo(drop.x, drop.y + velocity)
		dropVelocity[i] += dropAccelertation * DeltaTimeSeconds()
	end
end

local function DestroyDrops()
	for i=#drops, 1, -1 do
		local drop = drops[i]
		
		if drop.y >= 260 then
			drop:remove()	-- unregister sprite?
			table.remove(drops, i)
			table.remove(dropVelocity, i)			
		end

	end
end

local function MoveCan()
	if playdate.buttonIsPressed(playdate.kButtonUp) then
		playerSprite:moveBy(0, -playerSpeed)
	end

	if playdate.buttonIsPressed(playdate.kButtonDown) then
		playerSprite:moveBy(0, playerSpeed)
	end

	if playdate.buttonIsPressed(playdate.kButtonLeft) then
		playerSprite:moveBy(-playerSpeed, 0)
	end

	if playdate.buttonIsPressed(playdate.kButtonRight) then
		playerSprite:moveBy(playerSpeed,0)
	end

	
end

local function RotateCan()
	playerSprite:setRotation( playerSprite:getRotation() + playdate.getCrankChange())
end

local function loadGame()
	playdate.display.setRefreshRate(50) -- Sets framerate to 50 fps
	math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

	local playerImage = gfx.image.new("images/can")
	playerSprite = gfx.sprite.new(playerImage)
	playerSprite:moveTo(200, 120)
	--playerSprite:setCollideRect(0,0, playerSprite:getSize())
	playerSprite:add();


	local sectorWidth = 133
	for i = 1, 3, 1 do

		local xMin = math.max(sectorWidth * (i-1), 20)
		local xMax = math.min(sectorWidth * i, 380)
		local randX = math.random(xMin, xMax)
		
		print(i .. " " .. xMin .. " - " .. xMax .. " = " .. randX)

		local potImage = gfx.image.new("images/pot")
		local potSprite = gfx.sprite.new(potImage)
		potSprite:moveTo(randX, 240 - (potSprite.height/2) )
		potSprite:setCollideRect(0,0, potSprite:getSize())
	
		potSprite:add();
		table.insert(potSprites, potSprite)
		table.insert(potProgress, 0)


		local flowerImage = gfx.image.new("images/flower")
		local flowerSprite = gfx.sprite.new(flowerImage)
		flowerSprite:moveTo(randX, 500)
		flowerSprite:add();
		table.insert(flowerSprites, flowerSprite)
		
	end

	

--[[ 
	local bgImage = gfx.image.new("images/bg")
	gfx.sprite.setBackgroundDrawingCallback(
		function(x, y, width, height)
			gfx.setClipRect(x,y, width, height)
			bgImage:draw(0,0)
			gfx.clearClipRect()
		end
	)
	]]

end

local function DropCollision()

	for i = 1, #potSprites, 1 do
		local pot = potSprites[i]
		
		local overlapping = pot:overlappingSprites()
		for d = 1, #overlapping, 1 do
			potProgress[i] += 1
			overlapping[d]:moveTo(overlapping[d].x, 400)	-- move it so it dies to the killbox
		end
	end
end

local function CheckPotProgress()
	
	for i = 1, #potProgress, 1 do
		local progress = potProgress[i]
		if progress >= potDropRequirement then
			local pot = potSprites[i]
			local flower = flowerSprites[i]
			flower:moveTo(pot.x, 240 - pot.height - (flower.height/2) + 6)
		end
	end
end

local function update()

	MoveCan()
	RotateCan()
	PourWater()
	MoveDrops()
	DropCollision()
	DestroyDrops()
	CheckPotProgress()

--	local collisions = dropSprite:overlappingSprites()
--	if #collisions >= 1 then
--		score += 1
--	end

	gfx.sprite.update()
	--gfx.drawText("Time: " .. math.ceil(TimeSeconds()), 10, 10)
	--gfx.drawText("Score: " .. score, 315, 10)

end

loadGame()

function playdate.update()
	UpdateTimers()
	update()
	playdate.drawFPS(0,0) -- FPS widget
end