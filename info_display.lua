local gBattle
local p1 = {}
local p2 = {}
local changed
local display_player_info = true
local display_projectile_info = true

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
    if imgui.tree_node("Info Display") then
        changed, display_player_info = imgui.checkbox("Display Battle Info", display_player_info)
		changed, display_projectile_info = imgui.checkbox("Display Projectile Info", display_projectile_info)
        imgui.tree_pop()
    end
end)

re.on_frame(function()
    gBattle = sdk.find_type_definition("gBattle")
    if gBattle then
        local sPlayer = gBattle:get_field("Player"):get_data(nil)
        local cPlayer = sPlayer.mcPlayer
        local BattleTeam = gBattle:get_field("Team"):get_data(nil)
        local cTeam = BattleTeam.mcTeam
		-- Charge Info
		local storageData = gBattle:get_field("Command"):get_data(nil).StorageData
		local p1ChargeInfo = storageData.UserEngines[0].m_charge_infos
		local p2ChargeInfo = storageData.UserEngines[1].m_charge_infos
		-- Fireball
		local sWork = gBattle:get_field("Work"):get_data(nil)
		local cWork = sWork.Global_work
		
		p1.mActionId = cPlayer[0].mActionId
		p1.HP_cap = cPlayer[0].vital_old
		p1.current_HP = cPlayer[0].vital_new
		p1.HP_cooldown = cPlayer[0].healing_wait
        p1.dir = bitand(cPlayer[0].BitValue, 128) == 128
        p1.hitstop = cPlayer[0].hit_stop
		p1.hitstun = cPlayer[0].damage_time
		p1.blockstun = cPlayer[0].guard_time
        p1.stance = cPlayer[0].pose_st
        p1.juggle = cPlayer[0].combo_dm_air
        p1.drive = cPlayer[0].focus_new
        p1.drive_cooldown = cPlayer[0].focus_wait
        p1.super = cTeam[0].mSuperGauge
		p1.buff = cPlayer[0].style_timer
		p1.chargeInfo = p1ChargeInfo
		p1.posX = cPlayer[0].pos.x.v / 6553600.0
        p1.posY = cPlayer[0].pos.y.v / 6553600.0
        p1.spdX = cPlayer[0].speed.x.v / 6553600.0
        p1.spdY = cPlayer[0].speed.y.v / 6553600.0
        p1.aclX = cPlayer[0].alpha.x.v / 6553600.0
        p1.aclY = cPlayer[0].alpha.y.v / 6553600.0
		p1.pushback = cPlayer[0].vector_zuri.speed.v / 6553600.0
		
		p2.mActionId = cPlayer[1].mActionId
		p2.HP_cap = cPlayer[1].vital_old
		p2.current_HP = cPlayer[1].vital_new
		p2.HP_cooldown = cPlayer[1].healing_wait
        p2.dir = bitand(cPlayer[1].BitValue, 128) == 128
        p2.hitstop = cPlayer[1].hit_stop
		p2.hitstun = cPlayer[1].damage_time
		p2.blockstun = cPlayer[1].guard_time
        p2.stance = cPlayer[1].pose_st
        p2.juggle = cPlayer[1].combo_dm_air
        p2.drive = cPlayer[1].focus_new
        p2.drive_cooldown = cPlayer[1].focus_wait
        p2.super = cTeam[1].mSuperGauge
		p2.buff = cPlayer[1].style_timer
		p2.chargeInfo = p2ChargeInfo
		p2.posX = cPlayer[1].pos.x.v / 6553600.0
        p2.posY = cPlayer[1].pos.y.v / 6553600.0
        p2.spdX = cPlayer[1].speed.x.v / 6553600.0
        p2.spdY = cPlayer[1].speed.y.v / 6553600.0
        p2.aclX = cPlayer[1].alpha.x.v / 6553600.0
        p2.aclY = cPlayer[1].alpha.y.v / 6553600.0
		p2.pushback = cPlayer[1].vector_zuri.speed.v / 6553600.0

		if display_player_info then
			imgui.begin_window("Player Data", true, 0)
			-- Player 1 Info
			if imgui.tree_node("P1") then
				if imgui.tree_node("General Info") then
					imgui.text("Action ID: " .. p1.mActionId)
					if p1.stance == 0 then
						imgui.text("Stance: Standing")
					elseif p1.stance == 1 then
						imgui.text("Stance: Crouching")
					else
						imgui.text("Stance: Jumping")
					end
					imgui.text("Current HP: " .. p1.current_HP)
					imgui.text("HP Cap: " .. p1.HP_cap)
					imgui.text("HP Regen Cooldown: " .. p1.HP_cooldown)
					imgui.text("Drive Gauge: " .. p1.drive)
					imgui.text("Drive Cooldown: " .. p1.drive_cooldown)
					imgui.text("Super Gauge: " .. p1.super)
					imgui.text("Buff Duration: " .. p1.buff)

					imgui.tree_pop()
				end
				if imgui.tree_node("Movement Info") then
					if p1.dir == true then
						imgui.text("Facing: Right")
					else
						imgui.text("Facing: Left")
					end
					imgui.text("Position X: " .. p1.posX)
					imgui.text("Position Y: " .. p1.posY)
					imgui.text("Speed X: " .. p1.spdX)
					imgui.text("Speed Y: " .. p1.spdY)
					imgui.text("Acceleration X: " .. p1.aclX)
					imgui.text("Acceleration Y: " .. p1.aclY)
					imgui.text("Pushback: " .. p1.pushback)
					
					imgui.tree_pop()
				end
				if imgui.tree_node("Attack Info") then
					imgui.text("Hitstop: " .. p1.hitstop)
					imgui.text("Hitstun: " .. p1.hitstun)
					imgui.text("Blockstun: " .. p1.blockstun)
					imgui.text("Juggle Counter: " .. p2.juggle)
					get_hitbox_range(cPlayer[0], cPlayer[0].mpActParam, p1)
					imgui.text("Absolute Range: " .. p1.absolute_range)
					imgui.text("Relative Range: " .. p1.relative_range)
					
					imgui.tree_pop()
				end
				if p1.chargeInfo:get_Count() > 0 then
					if imgui.tree_node("Charge Info") then
						for i=0,p1.chargeInfo:get_Count() - 1 do
							local value = p1.chargeInfo:get_Values()._dictionary._entries[i].value
							if value ~= nil then
								imgui.text("Move " .. i + 1 .. " Charge Time: " .. value.charge_frame)
								imgui.text("Move " .. i + 1 .. " Charge Keep Time: " .. value.keep_frame)
							end
						end
						imgui.tree_pop()
						
					end
				end
					
				imgui.tree_pop()
			end
			
			-- Player 2 Info
			if imgui.tree_node("P2") then
				if imgui.tree_node("General Info") then
					imgui.text("Action ID: " .. p2.mActionId)
					if p2.stance == 0 then
						imgui.text("Stance: Standing")
					elseif p2.stance == 1 then
						imgui.text("Stance: Crouching")
					else
						imgui.text("Stance: Jumping")
					end
					imgui.text("Current HP: " .. p2.current_HP)
					imgui.text("HP Cap: " .. p2.HP_cap)
					imgui.text("HP Regen Cooldown: " .. p2.HP_cooldown)
					imgui.text("Drive Gauge: " .. p2.drive)
					imgui.text("Drive Cooldown: " .. p2.drive_cooldown)
					imgui.text("Super Gauge: " .. p2.super)
					imgui.text("Buff Duration: " .. p2.buff)

					imgui.tree_pop()
				end
				if imgui.tree_node("Movement Info") then
					if p2.dir == true then
						imgui.text("Facing: Right")
					else
						imgui.text("Facing: Left")
					end
					imgui.text("Position X: " .. p2.posX)
					imgui.text("Position Y: " .. p2.posY)
					imgui.text("Speed X: " .. p2.spdX)
					imgui.text("Speed Y: " .. p2.spdY)
					imgui.text("Acceleration X: " .. p2.aclX)
					imgui.text("Acceleration Y: " .. p2.aclY)
					imgui.text("Pushback: " .. p2.pushback)
					
					imgui.tree_pop()
				end
				if imgui.tree_node("Attack Info") then
					imgui.text("Hitstop: " .. p2.hitstop)
					imgui.text("Hitstun: " .. p2.hitstun)
					imgui.text("Blockstun: " .. p2.blockstun)
					imgui.text("Juggle Counter: " .. p1.juggle)
					get_hitbox_range(cPlayer[0], cPlayer[0].mpActParam, p2)
					imgui.text("Absolute Range: " .. p2.absolute_range)
					imgui.text("Relative Range: " .. p2.relative_range)
					
					imgui.tree_pop()
				end
				if p2.chargeInfo:get_Count() > 0 then
					if imgui.tree_node("Charge Info") then
						for i=0,p2.chargeInfo:get_Count() - 1 do
							local value = p2.chargeInfo:get_Values()._dictionary._entries[i].value
							if value then
								imgui.text("Move " .. i + 1 .. " Charge Time: " .. value.charge_frame)
								imgui.text("Move " .. i + 1 .. " Charge Keep Time: " .. value.keep_frame)
							end
						end
						imgui.tree_pop()
						
					end
				end
				
				imgui.tree_pop()
			end
		
		imgui.end_window()
		end
		
		if display_projectile_info then
			-- Fireball UI
			imgui.begin_window("Projectile Data", true, 0)
			-- P1 Fireball
			if imgui.tree_node("P1 Projectile Info") then		
				for i, obj in pairs(cWork) do
					if obj.owner_add ~= nil and obj.pl_no == 0 then
						if imgui.tree_node("Projectile " .. i) then
							imgui.text("Action ID: " .. obj.mActionId)
							imgui.text("Position X: " .. obj.pos.x.v / 6553600.0)
							imgui.text("Position Y: " .. obj.pos.y.v / 6553600.0)
							imgui.text("Speed X: " .. obj.speed.x.v / 6553600.0)
							imgui.tree_pop()
						end
					end
				end
					
				imgui.tree_pop()
			end
			-- P2 Fireball
			if imgui.tree_node("P2 Projectile Info") then		
				for i, obj in pairs(cWork) do
					if obj.owner_add ~= nil and obj.pl_no == 1 then
						if imgui.tree_node("Projectile " .. i) then
							imgui.text("Action ID: " .. obj.mActionId)
							imgui.text("Position X: " .. obj.pos.x.v / 6553600.0)
							imgui.text("Position Y: " .. obj.pos.y.v / 6553600.0)
							imgui.text("Speed X: " .. obj.speed.x.v / 6553600.0)
							imgui.tree_pop()
						end
					end
				end
					
				imgui.tree_pop()
			end
			
			imgui.end_window()
		end
    end
end)
