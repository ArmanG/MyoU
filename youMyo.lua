scriptId = 'com.youtube'

-- All timeouts in milliseconds
UNLOCKED_TIMEOUT = 2000               -- Time since last activity before we lock

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

function resetFist()
    fistMade = false
    referenceRoll = myo.getRoll()
    currentRoll = referenceRoll
  --  myo.keyboard("up_arrow","up")
  --  myo.keyboard("down_arrow","up")
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
        -- If we've been unlocked longer than the timeout period, lock.
        -- Activity will update unlockedSince, see extendUnlock() above.
		-- myo.debug(now - unlockedSince)
        if now - unlockedSince > UNLOCKED_TIMEOUT then
            unlocked = false
			myo.vibrate("short")
        end
    end

    currentRoll = myo.getRoll()
    if myo.getXDirection() == "towardElbow" and fistMade then
        currentRoll = currentRoll * -1
        extendUnlock()
    end

    if unlocked and fistMade then -- Moves page when fist is held and Myo is rotated
        extendUnlock()
        subtractive = currentRoll - referenceRoll
        if subtractive > 0.2  then
            scrollUp()
        elseif subtractive < -0.2 then
            scrollDown() 
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
            extendUnlock()
        end
    end
    if pose == "waveIn" or pose == "waveOut" or pose == "fist" then
        local now = myo.getTimeMilliseconds()

        if unlocked and edge == "on" then
            -- Deal with direction and arm.
            pose = conditionallySwapWave(pose)

            -- Determine direction based on the pose.
            if pose == "waveIn" then
                framestepBackwards()

            elseif pose == "fist" then -- Sets up fist movement
            	pauseOrPlay()
                if not fistMade then
                    referenceRoll = myo.getRoll()
                    fistMade = true
                    if myo.getXDirection() == "towardElbow" then -- Adjusts for Myo orientation
                        referenceRoll = referenceRoll * -1
                    end
                end

            elseif pose == "waveOut" then
            	framestepForwards()
            end

            if pose ~= "fist" then -- Reset call
                resetFist()
            end

            -- Initial burst and vibrate
            myo.vibrate("short")
            extendUnlock()
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
		wantActive = string.match(title, " *%- YouTube %- Google Chrome$")
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


