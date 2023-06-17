local gBattle
local p1 = {}
local p2 = {}
local changed
local display_info = true

p1.absolute_range = 0
p1.relative_range = 0
p2.absolute_range = 0
p2.relative_range = 0

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

local abs = function(num)
	if num < 0 then
		return num * -1
	else
		return num
	end
end

local get_hitbox_range = function ( player, actParam, list )
	local facingRight = bitand(player.BitValue, 128) == 128
	local maxHitboxEdgeX = nil
	if actParam ~= nil then
		local col = actParam.Collision
		   for j, rect in reversePairs(col.Infos._items) do
			if rect ~= nil then
				local posX = rect.OffsetX.v / 6553600.0
				local posY = rect.OffsetY.v / 6553600.0
				local sclX = rect.SizeX.v / 6553600.0 * 2
				local sclY = rect.SizeY.v / 6553600.0 * 2
				if rect:get_field("HitPos") ~= nil then
					local hitbox_X
					if rect.TypeFlag > 0 or (rect.TypeFlag == 0 and rect.PoseBit > 0) then
                        if facingRight then
                            hitbox_X = posX + sclX / 2
                        else
                            hitbox_X = posX - sclX / 2
                        end
						if maxHitboxEdgeX == nil then
							maxHitboxEdgeX = hitbox_X
						end
						if maxHitboxEdgeX ~= nil then
							if facingRight and hitbox_X > maxHitboxEdgeX then
								maxHitboxEdgeX = hitbox_X
							elseif hitbox_X < maxHitboxEdgeX then
								maxHitboxEdgeX = hitbox_X
							end
						end
					end
				end
			end
		end
		if maxHitboxEdgeX ~= nil then
			local playerPosX = player.pos.x.v / 6553600.0
			local playerStartPosX = player.start_pos.x.v / 6553600.0
            list.absolute_range = abs(maxHitboxEdgeX - playerStartPosX)
            list.relative_range = abs(maxHitboxEdgeX - playerPosX)
		end
	end
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
		local storageData = gBattle:get_field("Command"):get_data(nil).StorageData
		local p1ChargeInfo = storageData.UserEngines[0].m_charge_infos
		local p2ChargeInfo = storageData.UserEngines[1].m_charge_infos
		
        p1.mActionId = cPlayer[0].mActionId
        p1.posX = cPlayer[0].pos.x.v / 65536.0
        p1.posY = cPlayer[0].pos.y.v / 65536.0
        p1.spdX = cPlayer[0].speed.x.v / 65536.0
        p1.spdY = cPlayer[0].speed.y.v / 65536.0
        p1.aclX = cPlayer[0].alpha.x.v / 65536.0
        p1.aclY = cPlayer[0].alpha.y.v / 65536.0
        p1.dir = bitand(cPlayer[0].BitValue, 128) == 128
        p1.hitstop = cPlayer[0].hit_stop
        p1.stance = cPlayer[0].pose_st
        p1.juggle = cPlayer[0].combo_dm_air
        p1.drive = cPlayer[0].focus_new
        p1.drive_cooldown = cPlayer[0].focus_wait
        p1.super = cTeam[0].mSuperGauge
		p1.buff = cPlayer[0].style_timer
		p1.chargeInfo = p1ChargeInfo

		p2.mActionId = cPlayer[1].mActionId
        p2.posX = cPlayer[1].pos.x.v / 65536.0
        p2.posY = cPlayer[1].pos.y.v / 65536.0
        p2.spdX = cPlayer[1].speed.x.v / 65536.0
        p2.spdY = cPlayer[1].speed.y.v / 65536.0
        p2.aclX = cPlayer[1].alpha.x.v / 65536.0
        p2.aclY = cPlayer[1].alpha.y.v / 65536.0
        p2.dir = bitand(cPlayer[1].BitValue, 128) == 128
        p2.hitstop = cPlayer[1].hit_stop
        p2.stance = cPlayer[1].pose_st
        p2.juggle = cPlayer[1].combo_dm_air
        p2.drive = cPlayer[1].focus_new
        p2.drive_cooldown = cPlayer[1].focus_wait
        p2.super = cTeam[1].mSuperGauge
		p2.buff = cPlayer[1].style_timer
		p2.chargeInfo = p2ChargeInfo

        if imgui.tree_node("P1 Info") then
			imgui.text("P1 Action ID: " .. p1.mActionId)
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
            imgui.text("Drive Cooldown: " .. p1.drive_cooldown)
            imgui.text("Super Gauge: " .. p1.super)
			imgui.text("Buff Timer: " .. p1.buff)
			if p1.chargeInfo:get_Count() > 0 then
				imgui.text("Move 1 Charge Time: " .. p1.chargeInfo:get_Values()._dictionary._entries[0].value.charge_frame)
				imgui.text("Move 1 Charge Keep Time: " .. p1.chargeInfo:get_Values()._dictionary._entries[0].value.keep_frame)
				imgui.text("Move 2 Charge Time: " .. p1.chargeInfo:get_Values()._dictionary._entries[1].value.charge_frame)
				imgui.text("Move 2 Charge Keep Time: " .. p1.chargeInfo:get_Values()._dictionary._entries[1].value.keep_frame)
				imgui.text("Move 3 Charge Time: " .. p1.chargeInfo:get_Values()._dictionary._entries[2].value.charge_frame)
				imgui.text("Move 3 Charge Keep Time: " .. p1.chargeInfo:get_Values()._dictionary._entries[2].value.keep_frame)
			end
			
			get_hitbox_range(cPlayer[0], cPlayer[0].mpActParam, p1)
			
			imgui.text("Absolute Range: " .. p1.absolute_range)
			imgui.text("Relative Range: " .. p1.relative_range)

            imgui.tree_pop()
        end

        if imgui.tree_node("P2 Info") then
			imgui.text("P2 Action ID: " .. p2.mActionId)
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
            imgui.text("Drive Cooldown: " .. p2.drive_cooldown)
            imgui.text("Super Gauge: " .. p2.super)
			imgui.text("Buff Timer: " .. p2.buff)
			if p2.chargeInfo:get_Count() > 0 then
				imgui.text("Move 1 Charge Time: " .. p2.chargeInfo:get_Values()._dictionary._entries[0].value.charge_frame)
				imgui.text("Move 1 Charge Keep Time: " .. p2.chargeInfo:get_Values()._dictionary._entries[0].value.keep_frame)
				imgui.text("Move 2 Charge Time: " .. p2.chargeInfo:get_Values()._dictionary._entries[1].value.charge_frame)
				imgui.text("Move 2 Charge Keep Time: " .. p2.chargeInfo:get_Values()._dictionary._entries[1].value.keep_frame)
				imgui.text("Move 3 Charge Time: " .. p2.chargeInfo:get_Values()._dictionary._entries[2].value.charge_frame)
				imgui.text("Move 3 Charge Keep Time: " .. p2.chargeInfo:get_Values()._dictionary._entries[2].value.keep_frame)
			end
			
			get_hitbox_range(cPlayer[1], cPlayer[1].mpActParam, p2)
			
			imgui.text("Absolute Range: " .. p2.absolute_range)
			imgui.text("Relative Range: " .. p2.relative_range)

            imgui.tree_pop()
        end
        imgui.end_window()
    end
end)
