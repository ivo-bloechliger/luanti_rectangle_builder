local supported_blocks = {
    "default:cobble",
    "default:glass",
    "default:pine_wood",
    "default:dirt",
    "default:mese",
    "default:diamondblock",
    "default:silversand",
}


for _, blockname in pairs(supported_blocks) do
    -- info on the base block
    local block = core.registered_nodes[blockname]
    if block then  -- fail gracefully for unsupported blocks
        -- simple name suffix for our custom blocks
        local simplename = blockname
        -- remove default: if present
        if (string.sub(blockname,1,8)=="default:") then
            simplename = string.sub(blockname,9)
        end

        -- base tile
        local blocktile = block.tiles[1]
        -- register crafting for non oriented blocks
        minetest.register_craft({
            output = "rectangle_builder:non_oriented_"..simplename,
            recipe = {
                {"default:stick", blockname, "default:stick"},
                {"default:stick", blockname, "default:stick"},
                {"default:stick", blockname, "default:stick"},
            }
        })

        -- make oriented blocks (with arrows in single direction)
        -- todo this does not work correctly for glass
        minetest.register_node("rectangle_builder:oriented_"..simplename, {
            description = "oriented rectangle builder block for "..simplename,
            -- { top, bottom, front, back, left, right }
            tiles = {blocktile.."^rectangle_builder_arrow.png", 
                    blocktile.."^rectangle_builder_arrow.png",
                    blocktile.."^rectangle_builder_kreis.png",
                    blocktile.."^rectangle_builder_hinten.png",
                    blocktile.."^(rectangle_builder_arrow.png^[transformr180)", 
                    blocktile.."^rectangle_builder_arrow.png"},
            paramtype2 = "facedir",
            -- copy drawtype from base block
            drawtype = block.drawtype,
        })  

        -- make the non-oriented blocks, containing all functionality
        minetest.register_node("rectangle_builder:non_oriented_"..simplename, {
            description = "rectangle builder for "..simplename,
            tiles = {blocktile.."^rectangle_builder_neutral.png"},
            --cracky (pickaxe)  choppy (axe)  crumbly (shovel)   3 soft, 2 medium, 1 hard
            groups = {cracky = 3, choppy = 3, crumbly = 3},  
            sounds = block.sounds,  -- copy sounds from base block
            -- sounds = default.node_sound_stone_defaults(),
            -- copy draw type from base block
            drawtype = block.drawtype,

            -- here comes the main functionality            
            after_place_node = function(pos, placer, itemstack, pointed_thing)
                local playername = ""
                local inventory = nil
                if placer and placer:is_player() then
                    playername = placer:get_player_name()
                    inventory = minetest.get_inventory({type="player", name=playername})
                    -- no inventory neccessary if in creative mode
                    if creative and creative.is_enabled_for and creative.is_enabled_for(playername) then
                        inventory = nil
                    end
                end
                -- get meta information on the current block
                local meta = minetest.get_meta(pos)
                -- 6 spacial direction in some weird order 
                local dirs = {vector.new(0,1,0), vector.new(0,0,1), vector.new(0,0,-1), vector.new(1,0,0), vector.new(-1,0,0), vector.new(0,-1,0)}
                -- How to convert from the above order to param2 value
                local dir2param2 = {5, 3, 1, 4, 2, 7}
                -- Index of the opposite direction
                local opposites = {6, 3, 2, 5, 4, 1}
                for dir, vec in pairs(dirs) do
                    local opposite = opposites[dir]
                    -- Check for maximal distance of 30
                    for dist = 1,30 do
                        local otherpos = vector.add(pos, vector.multiply(vec,dist))
                        local otherblock =  core.get_node(otherpos)
                        local othername = otherblock.name
                        if othername ~= "air" then
                            -- About to fill a rectangle?
                            if othername=="rectangle_builder:oriented_"..simplename then
                                local othermeta = core.get_meta(otherpos)
                                -- https://minetest.org/modbook/chapters/node_metadata.html
                                -- minetest.log("found node " .. tostring(nodemeta:to_table()))
                                local otherdir = tonumber(othermeta:to_table().fields.dir)
                                local otherdist = tonumber(othermeta:to_table().fields.dist)
                                local othervec = dirs[otherdir]

                                -- Count needed blocks for this rectangle
                                local placed = 0
                                for x = 0,dist do
                                    for y = 0,otherdist do
                                        local p = vector.add(vector.add(pos, vector.multiply(vec,x)), vector.multiply(othervec, y))
                                        local n = core.get_node(p)
                                        if n.name=="air" then
                                            placed = placed + 1
                                        end
                                    end
                                end
                                -- In case we have an inventory, check if there are sufficient blocks available
                                if inventory ~= nil then
                                    local stack = ItemStack(blockname.." "..placed)
                                    if not inventory:contains_item("main", stack) then
                                        minetest.log("not enough "..simplename)
                                        -- skip to next spacial direction
                                        break
                                    end
                                end
                                -- We have enough blocks available, so fill the rectangle
                                for x = 0,dist do
                                    for y = 0,otherdist do
                                        local p = vector.add(vector.add(pos, vector.multiply(vec,x)), vector.multiply(othervec, y))
                                        local n = core.get_node(p)
                                        if n.name=="air" or 
                                           n.name=="rectangle_builder:oriented_"..simplename or 
                                           n.name=="rectangle_builder:non_oriented_"..simplename then
                                            core.set_node(p, {name=blockname})
                                        end
                                    end
                                end
                                -- Adjust inventory, if we have to
                                if inventory ~= nil then
                                    local stack = ItemStack(blockname.." "..placed)
                                    inventory:remove_item("main", stack)
                                end


                            -- Just filling a line
                            elseif othername=="rectangle_builder:non_oriented_"..simplename and dist>1 then
                                -- Check if enough available blocks in inventory (if neccessary)
                                if inventory ~= nil then
                                    local stack = ItemStack(blockname.." "..(dist-1))
                                    if not inventory:contains_item("main", stack) then
                                        minetest.log("not enough "..simplename)
                                        -- skip to next spacial direction
                                        break
                                    end
                                    inventory:remove_item("main", stack)
                                end
                                -- Fill line
                                for d = 1,dist-1 do
                                    local mpos = vector.add(pos, vector.multiply(vec,d))
                                    core.set_node(mpos, {name=blockname})
                                end
                                -- Change start und end block to oriented blocks
                                -- get param2 for startblock
                                local p2 = dir2param2[dir]
                                core.set_node(pos, {name="rectangle_builder:oriented_"..simplename, param2=p2})
                                -- get new meta data and save direction index and distance information
                                meta = minetest.get_meta(pos)                       
                                meta:set_int("dir", dir)
                                meta:set_int("dist", dist)
                                -- get param2 for endblock
                                p2 = dir2param2[opposite]
                                --minetest.debug(p2)
                                --minetest.log("vec "..tostring(dirs[opposite]).."  -> "..p2)
                                core.set_node(otherpos, {name="rectangle_builder:oriented_"..simplename, param2=p2})
                                meta = minetest.get_meta(otherpos)
                                meta:set_int("dir", opposite)
                                meta:set_int("dist", dist)
                            end
                            -- no more checking in this direction 
                            break
                        end
                    end
                end
            end,
        }) -- end definition of non-oriented block
    end  -- if block exists
end