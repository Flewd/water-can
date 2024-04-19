import "CoreLibs/timer"

local lastTime = 0
local deltaTimeMS = 0
local deltaTimeSeconds = 0

function TimeMS()
	return playdate.getCurrentTimeMilliseconds()
end

function TimeSeconds()
	return playdate.getCurrentTimeMilliseconds() / 1000
end

function UpdateTimers()
    playdate.timer.updateTimers()

	if lastTime == 0 then
		lastTime = TimeMS()
    else
		local curTime = TimeMS()
		deltaTimeMS = curTime - lastTime
		deltaTimeSeconds = deltaTimeMS / 1000
		lastTime = curTime
	end

end


function DeltaTimeMS()
	return deltaTimeMS
end	

function DeltaTimeSeconds()
	return deltaTimeSeconds
end	
