local gBattle
local p1 = {}
local p2 = {}
local changed
local display_info = true

local reversePairs = function ( aTable )
	local keys = {}

	for k,v in pairs(aTable) do keys[#keys+1] = k end
	table.sort(keys, function (a, b) return a>b end)

	local n = 0

	return function ( )
		n = n + 1
		return keys[n], aTable[keys[n] ]
	end
end

function bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

re.on_draw_ui(function()
    if imgui.tree_node("Battle Info Display") then
        changed, display_info = imgui.checkbox("Display Battle Info", display_info)
        imgui.tree_pop()
    end
end)

re.on_frame(function()
    if display_info == false then return end
    gBattle = sdk.find_type_definition("gBattle")
    if gBattle then
        imgui.begin_window("Battle Data", true, 0)
        
        local sPlayer = gBattle:get_field("Player"):get_data(nil)
        local cPlayer = sPlayer.mcPlayer
        local BattleTeam = gBattle:get_field("Team"):get_data(nil)
        local cTeam = BattleTeam.mcTeam
        
        p1.posX = cPlayer[0].pos.x.v / 65336.0
        p1.posY = cPlayer[0].pos.y.v / 65336.0
        p1.spdX = cPlayer[0].speed.x.v / 65336.0
        p1.spdY = cPlayer[0].speed.y.v / 65336.0
        p1.aclX = cPlayer[0].alpha.x.v / 65336.0
        p1.aclY = cPlayer[0].alpha.y.v / 65336.0
        p1.dir = bitand(cPlayer[0].BitValue, 128) == 128
        p1.hitstop = cPlayer[0].hit_stop
        p1.stance = cPlayer[0].pose_st
        p1.juggle = cPlayer[0].combo_dm_air
        p1.drive = cPlayer[0].focus_new
        p1.super = cTeam[0].mSuperGauge

        p2.posX = cPlayer[1].pos.x.v / 65336.0
        p2.posY = cPlayer[1].pos.y.v / 65336.0
        p2.spdX = cPlayer[1].speed.x.v / 65336.0
        p2.spdY = cPlayer[1].speed.y.v / 65336.0
        p2.aclX = cPlayer[1].alpha.x.v / 65336.0
        p2.aclY = cPlayer[1].alpha.y.v / 65336.0
        p2.dir = bitand(cPlayer[1].BitValue, 128) == 128
        p2.hitstop = cPlayer[1].hit_stop
        p2.stance = cPlayer[1].pose_st
        p2.juggle = cPlayer[1].combo_dm_air
        p2.drive = cPlayer[1].focus_new
        p2.super = cTeam[1].mSuperGauge

        if imgui.tree_node("P1 Info") then
            imgui.text("Position X: " .. p1.posX)
            imgui.text("Position Y: " .. p1.posY)
            imgui.text("Speed X: " .. p1.spdX)
            imgui.text("Speed Y: " .. p1.spdY)
            imgui.text("Acceleration X: " .. p1.aclX)
            imgui.text("Acceleration Y: " .. p1.aclY)
            if p1.dir == true then
                imgui.text("Direction: Right")
            else
                imgui.text("Direction: Left")
            end
            imgui.text("Hitstop: " .. p1.hitstop)
            if p1.stance == 0 then
                imgui.text("Stance: Standing")
            elseif p1.stance == 1 then
                imgui.text("Stance: Crouching")
            else
                imgui.text("Stance: Jumping")
            end
            imgui.text("Juggle Counter: " .. p2.juggle)
            imgui.text("Drive Gauge: " .. p1.drive)
            imgui.text("Super Gauge: " .. p1.super)
            imgui.tree_pop()
        end

        if imgui.tree_node("P2 Info") then
            imgui.text("Position X: " .. p2.posX)
            imgui.text("Position Y: " .. p2.posY)
            imgui.text("Speed X: " .. p2.spdX)
            imgui.text("Speed Y: " .. p2.spdY)
            imgui.text("Acceleration X: " .. p2.aclX)
            imgui.text("Acceleration Y: " .. p2.aclY)
            if p2.dir == true then
                imgui.text("Direction: Right")
            else
                imgui.text("Direction: Left")
            end
            imgui.text("Hitstop: " .. p2.hitstop)
            if p2.stance == 0 then
                imgui.text("Stance: Standing")
            elseif p2.stance == 1 then
                imgui.text("Stance: Crouching")
            else
                imgui.text("Stance: Jumping")
            end
            imgui.text("Juggle Counter: " .. p1.juggle)
            imgui.text("Drive Gauge: " .. p2.drive)
            imgui.text("Super Gauge: " .. p2.super)
            imgui.tree_pop()
        end
        imgui.end_window()
    end
end)
