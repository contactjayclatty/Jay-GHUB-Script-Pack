-- SPDX-License-Identifier: MIT
-- Operator: Thermite
-- Script pack 1.2.0; roster checked 2026-10-22.

-- NEUTRAL STARTING VALUES: these are not operator-specific recoil presets.
-- USER TUNING: adjust these two values after testing your weapon and sensitivity.
RcCustomStrength = 0       -- Downward movement per vertical step; 0 means none.
HorizontalStrength = 0     -- Negative = left, positive = right; 0 means none.

-- ADVANCED CONTROLS: leave these unchanged unless you understand their effect.
EnableRCS = true
RecoilControlMode = "Custom"
VerticalFrequency = 2
HorizontalFrequency = 4
RequireToggle = true
ToggleKey = "CapsLock"
DelayRate = 7

-- INTERNAL LOGIC: leave unchanged. Burst resets, idle waits and aim-release checks
-- are included. The firing loops remain separate.
if RecoilControlMode == "Low" then
  RecoilControlStrength = 2
elseif RecoilControlMode == "Medium" then
  RecoilControlStrength = 6
elseif RecoilControlMode == "High" then
  RecoilControlStrength = 8
elseif RecoilControlMode == "Ultra" then
  RecoilControlStrength = 12
elseif RecoilControlMode == "Insanity" then
  RecoilControlStrength = 31
elseif RecoilControlMode == "Custom" then
  RecoilControlStrength = RcCustomStrength
end

local h_counter = 0 -- Counter for horizontal frequency
local v_counter = 0 -- Counter for vertical frequency
EnablePrimaryMouseButtonEvents(true);

function OnEvent(event,arg)
if EnableRCS ~= false then
if RequireToggle ~= false then
    if IsKeyLockOn(ToggleKey)then
        if IsMouseButtonPressed(3)then
            repeat
                if IsMouseButtonPressed(1) then
                    v_counter = 0
                    h_counter = 0
                    repeat
                        -- EDITED LOGIC --
                        v_counter = v_counter + 1
                        h_counter = h_counter + 1
                        local dx = 0
                        local dy = 0

                        if v_counter >= VerticalFrequency then
                            dy = RecoilControlStrength
                            v_counter = 0
                        end
                        if h_counter >= HorizontalFrequency then
                            dx = HorizontalStrength
                            h_counter = 0
                        end

                        MoveMouseRelative(dx, dy)
                        Sleep(DelayRate)
                    until not IsMouseButtonPressed(1) or not IsMouseButtonPressed(3)
                else
                    Sleep(1)
                end
            until not IsMouseButtonPressed(3)
        end
    end

else
        if IsMouseButtonPressed(3)then
            repeat
                if IsMouseButtonPressed(1) then
                    v_counter = 0
                    h_counter = 0
                    repeat
                        -- EDITED LOGIC --
                        v_counter = v_counter + 1
                        h_counter = h_counter + 1
                        local dx = 0
                        local dy = 0

                        if v_counter >= VerticalFrequency then
                            dy = RecoilControlStrength
                            v_counter = 0
                        end
                        if h_counter >= HorizontalFrequency then
                            dx = HorizontalStrength
                            h_counter = 0
                        end

                        MoveMouseRelative(dx, dy)
                        Sleep(DelayRate)
                    until not IsMouseButtonPressed(1) or not IsMouseButtonPressed(3)
                else
                    Sleep(1)
                end
            until not IsMouseButtonPressed(3)
        end
    end
else
end
end
