local display_hitboxes = true
local display_hurtboxes = true
local display_pushboxes = true
local display_throwboxes = true
local display_throwhurtboxes = true
local display_proximityboxes = true
local changed
local gBattle

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

re.on_draw_ui(function()
    changed, display_hitboxes = imgui.checkbox("Display Hitboxes", display_hitboxes)
    changed, display_hurtboxes = imgui.checkbox("Display Hurtboxes", display_hurtboxes)
    changed, display_pushboxes = imgui.checkbox("Display Pushboxes", display_pushboxes)
    changed, display_throwboxes = imgui.checkbox("Display Throw Boxes", display_throwboxes)
    changed, display_throwhurtboxes = imgui.checkbox("Display Throw Hurtboxes", display_throwhurtboxes)
    changed, display_proximityboxes = imgui.checkbox("Display Proximity Boxes", display_proximityboxes)
end)

re.on_frame(function()
    gBattle = sdk.find_type_definition("gBattle")
    if gBattle then
        local sWork = gBattle:get_field("Work"):get_data(nil)
        local cWork = sWork.Global_work
        for i, obj in pairs(cWork) do
            local actParam = obj.mpActParam
            if actParam then
                local col = actParam.Collision
                for j, rect in reversePairs(col.Infos._items) do
                    if rect ~= nil then
                        local posX = rect.OffsetX.v / 6553600.0
                        local posY = rect.OffsetY.v / 6553600.0
                        local sclX = rect.SizeX.v / 6553600.0 * 2
                        local sclY = rect.SizeY.v / 6553600.0 * 2
                        posX = posX - sclX / 2
                        posY = posY - sclY / 2

                        local screenTL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY + sclY / 2, 0))
                        local screenTR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY + sclY / 2, 0))
                        local screenBL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY - sclY / 2, 0))
                        local screenBR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY - sclY / 2, 0))

                        if screenTL and screenTR and screenBL and screenBR then

                            local finalPosX = (screenTL.x + screenTR.x) / 2
                            local finalPosY = (screenBL.y + screenTL.y) / 2
                            local finalSclX = (screenTR.x - screenTL.x)
                            local finalSclY = (screenTL.y - screenBL.y)

                            if rect:get_field("HitPos") ~= nil then
                                if rect.TypeFlag > 0 and display_hitboxes then 
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF0040C0)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x600040C0)
                                elseif rect.CondFlag & 0x2C0 == 0x2C0 and display_throwboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFD080FF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60D080FF)
                                elseif display_proximityboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0080)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x40FF0080)
                                end
                            elseif rect:get_field("Attr") ~= nil then
                                if display_pushboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FFFF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FFFF)
                                end
                            elseif rect:get_field("HitNo") ~= nil then
                                if display_hurtboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FF00)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FF00)
                                end
                            elseif display_throwboxes then
                                draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0000)
                                draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60FF0000)
                            end
                        end
                    end
                end
            end
        end
        local sPlayer = gBattle:get_field("Player"):get_data(nil)
        local cPlayer = sPlayer.mcPlayer
        for i, player in pairs(cPlayer) do
            local actParam = player.mpActParam
            if actParam then
                local col = actParam.Collision
                for j, rect in reversePairs(col.Infos._items) do
                    if rect ~= nil then
                        local posX = rect.OffsetX.v / 6553600.0
                        local posY = rect.OffsetY.v / 6553600.0
                        local sclX = rect.SizeX.v / 6553600.0 * 2
                        local sclY = rect.SizeY.v / 6553600.0 * 2
                        posX = posX - sclX / 2
                        posY = posY - sclY / 2

                        local screenTL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY + sclY / 2, 0))
                        local screenTR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY + sclY / 2, 0))
                        local screenBL = draw.world_to_screen(Vector3f.new(posX - sclX / 2, posY - sclY / 2, 0))
                        local screenBR = draw.world_to_screen(Vector3f.new(posX + sclX / 2, posY - sclY / 2, 0))

                        if screenTL and screenTR and screenBL and screenBR then

                            local finalPosX = (screenTL.x + screenTR.x) / 2
                            local finalPosY = (screenBL.y + screenTL.y) / 2
                            local finalSclX = (screenTR.x - screenTL.x)
                            local finalSclY = (screenTL.y - screenBL.y)

                            if rect:get_field("HitPos") ~= nil then
                                if rect.TypeFlag > 0 and display_hitboxes then 
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF0040C0)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x600040C0)
                                elseif rect.CondFlag & 0x2C0 == 0x2C0 and display_throwboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFD080FF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60D080FF)
                                elseif display_proximityboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0080)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x40FF0080)
                                end
                            elseif rect:get_field("Attr") ~= nil then
                                if display_pushboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FFFF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FFFF)
                                end
                            elseif rect:get_field("HitNo") ~= nil then
                                if display_hurtboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FF00)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FF00)
                                end
                            elseif display_throwboxes then
                                draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0000)
                                draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60FF0000)
                            end
                        end
                    end
                end
            end
        end
    end
end)
