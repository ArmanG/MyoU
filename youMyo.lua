scriptId = 'com.youtube'

-- All timeouts in milliseconds
UNLOCKED_TIMEOUT = 2200		-- Time since last activity before we lock
ROLL_SENS = 0.2					-- Roll bellow this number will be ignored
VEL_SENS = 10000				-- Combination of those two numbers will set velocity sensitivity and responsiveness
VEL_COUNT = 30

function pauseOrPlay()
    myo.keyboard("space", "press")
end

function framestepForwards()
	myo.keyboard("right_arrow", "press")
end

function framestepBackwards()
	myo.keyboard("left_arrow", "press")
end

function scrollUp()
    myo.keyboard("up_arrow","press")
end

function scrollDown()
    myo.keyboard("down_arrow","press")
end


-- Makes use of myo.getArm() to swap wave out and wave in when the armband is being worn on
-- the left arm. This allows us to treat wave out as wave right and wave in as wave
-- left for consistent direction. The function has no effect on other poses.
function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

function unlock()
    unlocked = true
    extendUnlock()
	--myo.debug("unlock")
end

function extendUnlock()
    unlockedSince = myo.getTimeMilliseconds()
end


function onPeriodic()
    local now = myo.getTimeMilliseconds()

    -- ...

    -- Lock after inactivity
    if unlocked then
        -- If we've been unlocked longer then the timeout period, lock.
        -- Activity will update unlockedSince, see extendUnlock() above.
		-- myo.debug(now - unlockedSince)
        if now - unlockedSince > UNLOCKED_TIMEOUT then
            unlocked = false
			myo.vibrate("short")
        end
    end

    currentRoll = myo.getRoll()
    if myo.getXDirection() == "towardElbow" and fistMade then
        currentRoll = -currentRoll
        extendUnlock()
    end

    if unlocked and fistMade then -- Moves page when fist is held and Myo is rotated
       ndeltaRoll=currentRoll-referenceRoll
	   if math.abs(deltaRoll-ndeltaRoll)>4 then --detecting rolls over 180 deg
			turnover=not turnover				--flipping a 180 deg bit
	   end
	   deltaRoll=ndeltaRoll
	   if turnover then
			vel=vel+100
		elseif not turnover then
			vel=vel+(math.floor(0.5+(VEL_SENS^(math.abs(deltaRoll/3.1415926535897)))))
			--myo.debug(math.floor(0.5+(VEL_SENS^(math.abs(deltaRoll/3.1415926535897)))))
		end
		--myo.debug(vel)
		--myo.debug(referenceRoll)
		--myo.debug(currentRoll)
		--myo.debug(deltaRoll)
		if vel>VEL_COUNT then
			vel=0
			--myo.debug("Volume Controll")
			extendUnlock()
			if deltaRoll > ROLL_SENS  then
				scrollUp()
				--myo.debug("+")
			elseif deltaRoll < -ROLL_SENS then
				scrollDown() 
				--myo.debug("-")
			end
		end
	end
end

function onPoseEdge(pose, edge)
    -- ...
    -- Forward/backward and shuttle.
	
    if pose == "thumbToPinky" then
        if edge == "off" then
            -- Unlock when pose is released in case the user holds it for a while.
            unlock()
        elseif edge == "on" and not unlocked then
            -- Vibrate twice on unlock.
            -- We do this when the pose is made for better feedback.
            myo.vibrate("short")
            myo.vibrate("short")
        end
    end
	
	local now = myo.getTimeMilliseconds()

	if unlocked and edge == "on" then
		-- Deal with direction and arm.
		pose = conditionallySwapWave(pose)

		-- Determine direction based on the pose.
		if pose == "waveIn" then
			framestepBackwards()
		elseif pose == "waveOut" then
			framestepForwards()
		end
		-- Initial burst and vibrate
		myo.vibrate("short")
		extendUnlock()
	end
    if unlocked and pose=="fist" then
		if edge=="on" then
			pauseOrPlay()
			referenceRoll = myo.getRoll()
			fistMade = true			--getting ready for roll control
			deltaRoll=0
			turnover=false
			vel=0
			if myo.getXDirection() == "towardElbow" then -- Adjusts for Myo orientation
				referenceRoll = -referenceRoll
			end
		elseif edge=="off" then
			fistMade=false
		end
	end
end

function onForegroundWindowChange(app, title)
    -- Here we decide if we want to control the new active app.

    local wantActive = false
	--myo.debug("App change ,title:")
	--myo.debug(title)
	
	if platform == "MacOS" then --Chrome on Mac OS
		if app == "com.google.Chrome" then
			activeApp = "Chrome"
			wantActive = true
		end
	elseif platform == "Windows" then --Chrome on Windows
		wantActive = string.match(title, " *YouTube %- Google Chrome$")
		if wantActive then
			activeApp = "Chrome"
			--myo.debug("Active")
		end
	end
  
    return wantActive
end

function activeAppName()
    -- Return the active app name determined in onForegroundWindowChange
    return activeApp
end

function onActiveChange(isActive)
    if not isActive then
        unlocked = false
    end
end


