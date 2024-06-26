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

local function bitand(a, b)
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

local function read_sfix(sfix_obj)
    if sfix_obj.w then
        return Vector4f.new(tonumber(sfix_obj.x:call("ToString()")), tonumber(sfix_obj.y:call("ToString()")), tonumber(sfix_obj.z:call("ToString()")), tonumber(sfix_obj.w:call("ToString()")))
    elseif sfix_obj.z then
        return Vector3f.new(tonumber(sfix_obj.x:call("ToString()")), tonumber(sfix_obj.y:call("ToString()")), tonumber(sfix_obj.z:call("ToString()")))
    elseif sfix_obj.y then
        return Vector2f.new(tonumber(sfix_obj.x:call("ToString()")), tonumber(sfix_obj.y:call("ToString()")))
    end
    return tonumber(sfix_obj:call("ToString()"))
end

--imgui.colored_and_white_text = function(color_text, white_text)
function imgui.multi_color(color_text, white_text)
    imgui.text_colored(color_text, 0xFFAAFFFF) 
    imgui.same_line()
    imgui.text(white_text)
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
			-- Replace start_pos because it can fail to track the actual starting location of an action (e.g., DJ 2MK)
			-- local playerStartPosX = player.start_pos.x.v / 6553600.0
			local playerStartPosX = player.act_root.x.v / 6553600.0
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
		-- ActionIDs
		if sPlayer.move_ctr > 0 then
			-- ActEngine
			local p1Engine = cPlayer[0].mpActParam.ActionPart._Engine
			local p2Engine = cPlayer[1].mpActParam.ActionPart._Engine
			-- P1 ActID, Current Frame, Final Frame, IASA Frame
			p1.mActionId = p1Engine:get_ActionID()
			p1.mActionFrame = p1Engine:get_ActionFrame()
			p1.mEndFrame = p1Engine:get_ActionFrameNum()
			p1.mMarginFrame = p1Engine:get_MarginFrame()
			-- P2 ActID, Current Frame, Final Frame, IASA Frame
			p2.mActionId = p2Engine:get_ActionID()
			p2.mActionFrame = p2Engine:get_ActionFrame()
			p2.mEndFrame = p2Engine:get_ActionFrameNum()
			p2.mMarginFrame = p2Engine:get_MarginFrame()
		end
		-- HitDT
		local p1HitDT = cPlayer[1].pDmgHitDT
		local p2HitDT = cPlayer[0].pDmgHitDT
		
		--[[ DEPRECATED (improved, direct method found)
		-- local p1Engine = gBattle:get_field("Rollback"):get_data():GetLatestEngine().ActEngines[0]._Parent._Engine
		-- local p2Engine = gBattle:get_field("Rollback"):get_data():GetLatestEngine().ActEngines[1]._Parent._Engine
		-- p1.mActionId = cPlayer[0].mActionId
		-- p2.mActionId = cPlayer[1].mActionId
		--]]
		
		-- P1 Data
		p1.HP_cap = cPlayer[0].heal_new
		p1.current_HP = cPlayer[0].vital_new
		p1.HP_cooldown = cPlayer[0].healing_wait
        p1.dir = bitand(cPlayer[0].BitValue, 128) == 128
        p1.curr_hitstop = cPlayer[0].hit_stop
		p1.max_hitstop = cPlayer[0].hit_stop_org
		p1.curr_hitstun = cPlayer[0].damage_time
		p1.max_hitstun = cPlayer[0].damage_info.time
		p1.curr_blockstun = cPlayer[0].guard_time
        p1.stance = cPlayer[0].pose_st
		p1.throw_invuln = cPlayer[0].catch_muteki
		p1.full_invuln = cPlayer[0].muteki_time
        p1.juggle = cPlayer[0].combo_dm_air
        p1.drive = cPlayer[0].focus_new
        p1.drive_cooldown = cPlayer[0].focus_wait
        p1.super = cTeam[0].mSuperGauge
		p1.buff = cPlayer[0].style_timer
		p1.poison_timer = cPlayer[0].damage_cond.timer
		p1.chargeInfo = p1ChargeInfo
		p1.posX = cPlayer[0].pos.x.v / 6553600.0
        p1.posY = cPlayer[0].pos.y.v / 6553600.0
        p1.spdX = cPlayer[0].speed.x.v / 6553600.0
        p1.spdY = cPlayer[0].speed.y.v / 6553600.0
        p1.aclX = cPlayer[0].alpha.x.v / 6553600.0
        p1.aclY = cPlayer[0].alpha.y.v / 6553600.0
		p1.pushback = cPlayer[0].vector_zuri.speed.v / 6553600.0
		p1.self_pushback = cPlayer[0].vs_vec_zuri.zuri.speed.v / 6553600.0
		
		-- P2 Data
		p2.HP_cap = cPlayer[1].heal_new
		p2.current_HP = cPlayer[1].vital_new
		p2.HP_cooldown = cPlayer[1].healing_wait
        p2.dir = bitand(cPlayer[1].BitValue, 128) == 128
        p2.curr_hitstop = cPlayer[1].hit_stop
		p2.max_hitstop = cPlayer[1].hit_stop_org
		p2.curr_hitstun = cPlayer[1].damage_time
		p2.max_hitstun = cPlayer[1].damage_info.time
		p2.curr_blockstun = cPlayer[1].guard_time
        p2.stance = cPlayer[1].pose_st
		p2.throw_invuln = cPlayer[1].catch_muteki
		p2.full_invuln = cPlayer[1].muteki_time
        p2.juggle = cPlayer[1].combo_dm_air
        p2.drive = cPlayer[1].focus_new
        p2.drive_cooldown = cPlayer[1].focus_wait
        p2.super = cTeam[1].mSuperGauge
		p2.buff = cPlayer[1].style_timer
		p2.poison_timer = cPlayer[1].damage_cond.timer
		p2.chargeInfo = p2ChargeInfo
		p2.posX = cPlayer[1].pos.x.v / 6553600.0
        p2.posY = cPlayer[1].pos.y.v / 6553600.0
        p2.spdX = cPlayer[1].speed.x.v / 6553600.0
        p2.spdY = cPlayer[1].speed.y.v / 6553600.0
        p2.aclX = cPlayer[1].alpha.x.v / 6553600.0
        p2.aclY = cPlayer[1].alpha.y.v / 6553600.0
		p2.pushback = cPlayer[1].vector_zuri.speed.v / 6553600.0
		p2.self_pushback = cPlayer[1].vs_vec_zuri.zuri.speed.v / 6553600.0
		
		--[[ DEPRECATED (found a variable that does the same thing)
		-- Max hitstop tracker
		if p1.max_hitstop == nil then
			p1.max_hitstop = 0
		end
		if p1.curr_hitstop > p1.max_hitstop then
			p1.max_hitstop = p1.curr_hitstop
		elseif p1.curr_hitstop == 0 then
			p1.max_hitstop = 0
		end
		if p2.max_hitstop == nil then
			p2.max_hitstop = 0
		end
		if p2.curr_hitstop > p2.max_hitstop then
			p2.max_hitstop = p2.curr_hitstop
		elseif p2.curr_hitstop == 0 then
			p2.max_hitstop = 0
		end
		--]]
		
		-- Max blockstun tracker
		if p1.max_blockstun == nil then
			p1.max_blockstun = 0
		end
		if p1.curr_blockstun > p1.max_blockstun then
			p1.max_blockstun = p1.curr_blockstun
		elseif p1.curr_blockstun == 0 then
			p1.max_blockstun = 0
		end

		if p2.max_blockstun == nil then
			p2.max_blockstun = 0
		end
		if p2.curr_blockstun > p2.max_blockstun then
			p2.max_blockstun = p2.curr_blockstun
		elseif p2.curr_blockstun == 0 then
			p2.max_blockstun = 0
		end

		if display_player_info then
			imgui.begin_window("Player Data", true, 0)
			-- Player 1 Info
			if imgui.tree_node("P1") then
				if imgui.tree_node("General Info") then
					imgui.multi_color("Current HP:", p1.current_HP)
					imgui.multi_color("HP Cap:", p1.HP_cap)
					imgui.multi_color("HP Regen Cooldown:", p1.HP_cooldown)
					imgui.multi_color("Drive Gauge:", p1.drive)
					imgui.multi_color("Drive Cooldown:", p1.drive_cooldown)
					imgui.multi_color("Super Gauge:", p1.super)
					imgui.multi_color("Buff Duration:", p1.buff)
					imgui.multi_color("Poison Duration:", p1.poison_timer)

					imgui.tree_pop()
				end
				if imgui.tree_node("State Info") then
					imgui.multi_color("Action ID:", p1.mActionId)
					imgui.multi_color("Action Frame:", math.floor(read_sfix(p1.mActionFrame)) .. " / " .. math.floor(read_sfix(p1.mMarginFrame)) .. " (" .. math.floor(read_sfix(p1.mEndFrame)) .. ")")
					imgui.multi_color("Current Hitstop:", p1.curr_hitstop .. " / " .. p1.max_hitstop)
					imgui.multi_color("Current Hitstun:", p1.curr_hitstun .. " / " .. p1.max_hitstun)
					imgui.multi_color("Current Blockstun:", p1.curr_blockstun .. " / " .. p1.max_blockstun)
					imgui.multi_color("Throw Protection Timer:", p1.throw_invuln)
					imgui.multi_color("Intangible Timer:", p1.full_invuln)

					imgui.tree_pop()
				end
				if imgui.tree_node("Movement Info") then
					if p1.dir == true then
						imgui.multi_color("Facing:", "Right")
					else
						imgui.multi_color("Facing:", "Left")
					end
					if p1.stance == 0 then
						imgui.multi_color("Stance:", "Standing")
					elseif p1.stance == 1 then
						imgui.multi_color("Stance:", "Crouching")
					else
						imgui.multi_color("Stance:", "Jumping")
					end
					imgui.multi_color("Position X:", p1.posX)
					imgui.multi_color("Position Y:", p1.posY)
					imgui.multi_color("Speed X:", p1.spdX)
					imgui.multi_color("Speed Y:", p1.spdY)
					imgui.multi_color("Acceleration X:", p1.aclX)
					imgui.multi_color("Acceleration Y:", p1.aclY)
					imgui.multi_color("Pushback:", p1.pushback)
					imgui.multi_color("Self Pushback:", p1.self_pushback)
					
					imgui.tree_pop()
				end
				if imgui.tree_node("Attack Info") then
					get_hitbox_range(cPlayer[0], cPlayer[0].mpActParam, p1)
					imgui.multi_color("Absolute Range:", p1.absolute_range)
					imgui.multi_color("Relative Range:", p1.relative_range)
					imgui.multi_color("Juggle Counter:", p2.juggle)
					if imgui.tree_node("Latest Attack Info") then
						if p1HitDT == nil then
							imgui.text_colored("No hit yet", 0xFFAAFFFF)
						else
							imgui.multi_color("Damage:", p1HitDT.DmgValue)
							imgui.multi_color("Self Drive Gain:", p1HitDT.FocusOwn)
							imgui.multi_color("Opponent Drive Gain:", p1HitDT.FocusTgt)
							imgui.multi_color("Self Super Gain:", p1HitDT.SuperOwn)
							imgui.multi_color("Opponent Super Gain:", p1HitDT.SuperTgt)
							imgui.multi_color("Self Hitstop:", p1HitDT.HitStopOwner)
							imgui.multi_color("Opponent Hitstop:", p1HitDT.HitStopTarget)
							imgui.multi_color("Stun:", p1HitDT.HitStun)
							imgui.multi_color("Knockdown Duration:", p1HitDT.DownTime)
							imgui.multi_color("Juggle Limit:", p1HitDT.JuggleLimit)
							imgui.multi_color("Juggle Increase:", p1HitDT.JuggleAdd)
							imgui.multi_color("Juggle Start:", p1HitDT.Juggle1st)
						end
					
						imgui.tree_pop()
					end
					
					imgui.tree_pop()
				end
				if p1.chargeInfo:get_Count() > 0 then
					if imgui.tree_node("Charge Info") then
						for i=0,p1.chargeInfo:get_Count() - 1 do
							local value = p1.chargeInfo:get_Values()._dictionary._entries[i].value
							if value ~= nil then
								imgui.multi_color("Move " .. i + 1 .. " Charge Time:", value.charge_frame)
								imgui.multi_color("Move " .. i + 1 .. " Charge Keep Time:", value.keep_frame)
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
					imgui.multi_color("Current HP:", p2.current_HP)
					imgui.multi_color("HP Cap:", p2.HP_cap)
					imgui.multi_color("HP Regen Cooldown:", p2.HP_cooldown)
					imgui.multi_color("Drive Gauge:", p2.drive)
					imgui.multi_color("Drive Cooldown:", p2.drive_cooldown)
					imgui.multi_color("Super Gauge:", p2.super)
					imgui.multi_color("Buff Duration:", p2.buff)
					imgui.multi_color("Poison Duration:", p2.poison_timer)

					imgui.tree_pop()
				end
				if imgui.tree_node("State Info") then
					imgui.multi_color("Action ID:", p2.mActionId)
					imgui.multi_color("Action Frame:", math.floor(read_sfix(p2.mActionFrame)) .. " / " .. math.floor(read_sfix(p2.mMarginFrame)) .. " (" .. math.floor(read_sfix(p2.mEndFrame)) .. ")")
					imgui.multi_color("Current Hitstop:", p2.curr_hitstop .. " / " .. p2.max_hitstop)
					imgui.multi_color("Current Hitstun:", p2.curr_hitstun .. " / " .. p2.max_hitstun)
					imgui.multi_color("Current Blockstun:", p2.curr_blockstun .. " / " .. p2.max_blockstun)
					imgui.multi_color("Throw Protection Timer:", p2.throw_invuln)
					imgui.multi_color("Intangible Timer:", p2.full_invuln)

					imgui.tree_pop()
				end
				if imgui.tree_node("Movement Info") then
					if p2.dir == true then
						imgui.multi_color("Facing:", "Right")
					else
						imgui.multi_color("Facing:", "Left")
					end
					if p2.stance == 0 then
						imgui.multi_color("Stance:", "Standing")
					elseif p2.stance == 1 then
						imgui.multi_color("Stance:", "Crouching")
					else
						imgui.multi_color("Stance:", "Jumping")
					end
					imgui.multi_color("Position X:", p2.posX)
					imgui.multi_color("Position Y:", p2.posY)
					imgui.multi_color("Speed X:", p2.spdX)
					imgui.multi_color("Speed Y:", p2.spdY)
					imgui.multi_color("Acceleration X:", p2.aclX)
					imgui.multi_color("Acceleration Y:", p2.aclY)
					imgui.multi_color("Pushback:", p2.pushback)
					imgui.multi_color("Self Pushback:", p2.self_pushback)
					
					imgui.tree_pop()
				end
				if imgui.tree_node("Attack Info") then
					get_hitbox_range(cPlayer[1], cPlayer[1].mpActParam, p2)
					imgui.multi_color("Absolute Range:", p2.absolute_range)
					imgui.multi_color("Relative Range:", p2.relative_range)
					imgui.multi_color("Juggle Counter:", p1.juggle)
					if imgui.tree_node("Latest Attack Info") then
						if p2HitDT == nil then
							imgui.text_colored("No hit yet", 0xFFAAFFFF)
						else
							imgui.multi_color("Damage:", p2HitDT.DmgValue)
							imgui.multi_color("Self Drive Gain:", p2HitDT.FocusOwn)
							imgui.multi_color("Opponent Drive Gain:", p2HitDT.FocusTgt)
							imgui.multi_color("Self Super Gain:", p2HitDT.SuperOwn)
							imgui.multi_color("Opponent Super Gain:", p2HitDT.SuperTgt)
							imgui.multi_color("Self Hitstop:", p2HitDT.HitStopOwner)
							imgui.multi_color("Opponent Hitstop:", p2HitDT.HitStopTarget)
							imgui.multi_color("Stun:", p2HitDT.HitStun)
							imgui.multi_color("Knockdown Duration:", p2HitDT.DownTime)
							imgui.multi_color("Juggle Limit:", p2HitDT.JuggleLimit)
							imgui.multi_color("Juggle Increase:", p2HitDT.JuggleAdd)
							imgui.multi_color("Juggle Start:", p2HitDT.Juggle1st)
						end
					
						imgui.tree_pop()
					end
					
					imgui.tree_pop()
				end
				if p2.chargeInfo:get_Count() > 0 then
					if imgui.tree_node("Charge Info") then
						for i=0,p2.chargeInfo:get_Count() - 1 do
							local value = p2.chargeInfo:get_Values()._dictionary._entries[i].value
							if value ~= nil then
								imgui.multi_color("Move " .. i + 1 .. " Charge Time:", value.charge_frame)
								imgui.multi_color("Move " .. i + 1 .. " Charge Keep Time:", value.keep_frame)
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
						local objEngine = obj.mpActParam.ActionPart._Engine
						if imgui.tree_node("Projectile " .. i) then
							imgui.multi_color("Action ID:", obj.mActionId)
							imgui.multi_color("Action Frame:", math.floor(read_sfix(objEngine:get_ActionFrame())) .. " / " .. math.floor(read_sfix(objEngine:get_MarginFrame())) .. " (" .. math.floor(read_sfix(objEngine:get_ActionFrameNum())) .. ")")
							imgui.multi_color("Position X:", obj.pos.x.v / 6553600.0)
							imgui.multi_color("Position Y:", obj.pos.y.v / 6553600.0)
							imgui.multi_color("Speed X:", obj.speed.x.v / 6553600.0)
							imgui.multi_color("Speed Y:", obj.speed.y.v / 6553600.0)
							
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
						local objEngine = obj.mpActParam.ActionPart._Engine
						if imgui.tree_node("Projectile " .. i) then
							imgui.multi_color("Action ID:", obj.mActionId)
							imgui.multi_color("Action Frame:", math.floor(read_sfix(objEngine:get_ActionFrame())) .. " / " .. math.floor(read_sfix(objEngine:get_MarginFrame())) .. " (" .. math.floor(read_sfix(objEngine:get_ActionFrameNum())) .. ")")
							imgui.multi_color("Position X:", obj.pos.x.v / 6553600.0)
							imgui.multi_color("Position Y:", obj.pos.y.v / 6553600.0)
							imgui.multi_color("Speed X:", obj.speed.x.v / 6553600.0)
							imgui.multi_color("Speed Y:", obj.speed.y.v / 6553600.0)
							
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
