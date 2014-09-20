scriptId = 'com.youtube'

function pauseOrPlay()
    myo.keyboard("space", "press")
end

function framestepForwards()
	myo.keyboard("right_arrow", "press")
end

function framestepBackwards()
	myo.keyboard("left_arrow", "press")
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
end

function extendUnlock()
    unlockedSince = myo.getTimeMilliseconds()
end

-- All timeouts in milliseconds
UNLOCKED_TIMEOUT = 2200               -- Time since last activity before we lock

function onPeriodic()
    local now = myo.getTimeMilliseconds()

    -- ...

    -- Lock after inactivity
    if unlocked then
        -- If we've been unlocked longer than the timeout period, lock.
        -- Activity will update unlockedSince, see extendUnlock() above.
        if now - unlockedSince > UNLOCKED_TIMEOUT then
            unlocked = false
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

            elseif pose == "fist" then
            	myo.debug("fist")
            	pauseOrPlay()

            elseif pose == "waveOut" then
            	framestepForwards()
            end

            -- Initial burst and vibrate
            myo.vibrate("short")
            extendUnlock()
        end
    end
end

-- All timeouts in milliseconds

-- Delay when holding wave left/right before switching to shuttle behaviour
SHUTTLE_CONTINUOUS_TIMEOUT = 600

-- How often to trigger shuttle behaviour
SHUTTLE_CONTINUOUS_PERIOD = 300

function onPeriodic()
    local now = myo.getTimeMilliseconds()

    -- Shuttle behaviour
    if shuttleTimeout then
        extendUnlock()

        -- If we haven't done a shuttle burst since the timeout, do one now
        if (now - shuttleSince) > shuttleTimeout then
            --  Perform a shuttle burst
            shuttleBurst()

            -- Update the timeout. (The first time it will be the longer delay.)
            shuttleTimeout = SHUTTLE_CONTINUOUS_PERIOD

            -- Update when we did the last shuttle burst
            shuttleSince = now
        end
    end

    -- ...
end

function onForegroundWindowChange(app, title)
    -- Here we decide if we want to control the new active app.

    local wantActive = false

    if app == "com.google.Chrome" then
    	wantActive = true
		activeApp = "Chrome"
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


