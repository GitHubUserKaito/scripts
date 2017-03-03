---user settings---
local WaitTime = 2 --how long until we try to enter "fast" mode
local lookAhead = 2 --how far ahead to look for subtitles when trying to enter "fast" mode
local fast = 1.2 --how fast "fast" mode is by default
local rewind = 0 --how far to rewind when entering normal mode; note that if this is more than or equal to WaitTime + lookAhead you will probably enter an infinite loop
---
local searchtimer
local checktimer
local waitTimer
local normal = mp.get_property("speed")
local subDelay = mp.get_property("options/sub-delay")
local checked = 0
local timer = 0
local searching = false

local function wait()
    fast = tonumber(mp.get_property("speed"))
    if mp.get_property("sub-text") ~= "" and mp.get_property("sub-text") ~= nil then
        mp.set_property("speed", normal)
        waitTimer:kill()
        checktimer:resume()
        mp.command("no-osd seek -"..tostring(0.05 + rewind).." exact")
    end
end

local function search()
    if timer < (lookAhead/2) then --half of how far ahead we want to search, because
        if mp.get_property("sub-text") ~= "" then
            timer = 0
            mp.set_property("options/sub-delay", subDelay)
            mp.set_property("speed", normal)
            mp.set_property("options/sub-scale", 1)
            searchtimer:kill()
            searching = false
            return
        end
        timer = timer + 0.1
        mp.set_property("options/sub-delay", subDelay - (timer*2)) --we multiply it here
        searchtimer = mp.add_timeout(0.05, search)
    else
        mp.set_property("options/sub-delay", subDelay)
        mp.set_property("speed", fast)
        searchtimer:kill()
        checktimer:kill()
        waitTimer = mp.add_periodic_timer(0.05, wait)
        searching = false
    end
end

local function check()
    if mp.get_property("sub-text") == "" or mp.get_property("sub-text") == nil then
        checked = checked + 0.1
    elseif searching == false then
        --        print(checked)
        if tonumber(mp.get_property("speed")) ~= fast then
            normal = mp.get_property("speed")
        end
        mp.set_property("options/sub-delay", subDelay)
        mp.set_property("speed", normal)
        mp.set_property("options/sub-scale", 1)
        checked = 0
    else
        checked = 0
    end
    if checked >= WaitTime and searching == false then
        subDelay = mp.get_property("options/sub-delay")
        if tonumber(mp.get_property("speed")) < fast then
            normal = mp.get_property("speed")
        else
            fast = tonumber(mp.get_property("speed"))
        end
        checked = 0
        timer = 0.1
        mp.set_property("options/sub-scale", 0.001)
        mp.set_property("options/sub-delay", subDelay-0.5)
        searching = true
        searchtimer = mp.add_timeout(0.1, search)
    end
end

local function toggle()
    if checktimer == nil or (checktimer:is_enabled() == false and waitTimer:is_enabled() == false) then
        checktimer = mp.add_periodic_timer(0.1, check)
        print("enabled")
    elseif checktimer:is_enabled() or waitTimer:is_enabled() then
        checktimer:kill()
        waitTimer:kill()
        mp.set_property("speed", normal)
        print("disabled")
    end
end

mp.add_key_binding("Ctrl+j", "toggle_speedsub", toggle)
