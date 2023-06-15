local display_hitboxes = true
local display_hurtboxes = true
local display_pushboxes = true
local display_throwboxes = true
local display_throwhurtboxes = true
local display_proximityboxes = true
local display_properties = true
local hide_p2 = false
local changed
local gBattle

local reversePairs = function ( aTable )
	local keys = {}

	for k,v in pairs(aTable) do keys[#keys+1] = k end
	table.sort(keys, function (a, b) return a>b end)

	local n = 0

    return function ( )
        n = n + 1
        if n > #keys then return nil, nil end
        return keys[n], aTable[keys[n] ]
    end
end

re.on_draw_ui(function()
    if imgui.tree_node("Hitbox Viewer") then
        changed, display_hitboxes = imgui.checkbox("Display Hitboxes", display_hitboxes)
        changed, display_hurtboxes = imgui.checkbox("Display Hurtboxes", display_hurtboxes)
        changed, display_pushboxes = imgui.checkbox("Display Pushboxes", display_pushboxes)
        changed, display_throwboxes = imgui.checkbox("Display Throw Boxes", display_throwboxes)
        changed, display_throwhurtboxes = imgui.checkbox("Display Throw Hurtboxes", display_throwhurtboxes)
        changed, display_proximityboxes = imgui.checkbox("Display Proximity Boxes", display_proximityboxes)
		changed, display_properties = imgui.checkbox("Display Properties", display_properties)
        changed, hide_p2 = imgui.checkbox("Hide P2 Boxes", hide_p2)
        imgui.tree_pop()
    end
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
                                elseif ((rect.TypeFlag == 0 and rect.PoseBit > 0) or rect.CondFlag == 0x2C0) and display_throwboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFD080FF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60D080FF)
                                elseif display_proximityboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF5b5b5b)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x405b5b5b)
                                end
                            elseif rect:get_field("Attr") ~= nil then
                                if display_pushboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FFFF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FFFF)
                                end
                            elseif rect:get_field("HitNo") ~= nil then
                                if display_hurtboxes then
									if rect.Type == 2 or rect.Type == 1 then
										draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0080)
										draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x40FF0080)
									else
										draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FF00)
										draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FF00)
									end
									if rect.TypeFlag == 1 and rect.Immune == 4 and display_properties then
										draw.text("Air Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
										draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFF00)
									elseif rect.TypeFlag == 2 and rect.Immune == 4 and display_properties then
										draw.text("Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
										draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFF00)
									elseif rect.TypeFlag == 1 and display_properties then
										draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
									elseif rect.Immune == 4 and display_properties then
										draw.text("Air Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
									elseif rect.TypeFlag == 2 and display_properties then
										draw.text("Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
									end
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
            if hide_p2 and i % 2 > 0 then return end
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
								elseif ((rect.TypeFlag == 0 and rect.PoseBit > 0) or rect.CondFlag == 0x2C0) and display_throwboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFD080FF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x60D080FF)
                                elseif display_proximityboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF5b5b5b)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x405b5b5b)
                                end
                            elseif rect:get_field("Attr") ~= nil then
                                if display_pushboxes then
                                    draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FFFF)
                                    draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FFFF)
                                end
                            elseif rect:get_field("HitNo") ~= nil then
                                if display_hurtboxes then
                                    if rect.Type == 2 or rect.Type == 1 then
										draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFFFF0080)
										draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x40FF0080)
									else
										draw.outline_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0xFF00FF00)
										draw.filled_rect(finalPosX, finalPosY, finalSclX, finalSclY, 0x4000FF00)
									end
									if rect.TypeFlag == 1 and rect.Immune == 4 and display_properties then
										draw.text("Air Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
										draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFF00)
									elseif rect.TypeFlag == 2 and rect.Immune == 4 and display_properties then
										draw.text("Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
										draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2) - 10, 0xFFFFFF00)
									elseif rect.TypeFlag == 1 and display_properties then
										draw.text("Projectile Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
									elseif rect.Immune == 4 and display_properties then
										draw.text("Air Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
									elseif rect.TypeFlag == 2 and display_properties then
										draw.text("Strike Inv", finalPosX, finalPosY + (finalSclY / 2), 0xFFFFFF00)
									end
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
