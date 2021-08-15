
local ss = server_shop
local S = core.get_translator(ss.modname)


local def = {
	base = {
		groups = {oddly_breakable_by_hand=1,},
		paramtype2 = "facedir",
		after_place_node = function(pos, placer)
			-- set node owner
			core.get_meta(pos):set_string("owner", placer:get_player_name())
		end,
		can_dig = function(pos, player)
			return ss.is_shop_owner(pos, player) or ss.is_shop_admin(player)
		end,
	},
	short = {
		drawtype = "normal",
		tiles = {
			"server_shop_side.png",
			"server_shop_side.png",
			"server_shop_side.png",
			"server_shop_side.png",
			"server_shop_side.png",
			"server_shop_front.png",
			"server_shop_side.png",
		},
	},
	tall = {
		drawtype = "mesh",
		mesh = "server_shop.obj",
		tiles = {"server_shop_mesh.png",},
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
		},
		collision_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
		},
	},
	sell = {
		description = S("Seller Shop"),
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			local pmeta = player:get_meta()

			-- store node pos in player meta for retrieval in callbacks
			pmeta:set_string(ss.modname .. ":pos", core.serialize(pos))
			-- store selected index in player meta for retrieval in callbacks
			pmeta:set_int(ss.modname .. ":selected", 1)

			ss.show_formspec(pos, player)
		end,
	},
	buy = {
		description = S("Buyer Shop"),
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			local pmeta = player:get_meta()

			-- store node pos in player meta for retrieval in callbacks
			pmeta:set_string(ss.modname .. ":pos", core.serialize(pos))
			-- store selected index in player meta for retrieval in callbacks
			-- FIXME: may not be necessary for buyers
			pmeta:set_int(ss.modname .. ":selected", 1)

			ss.show_formspec(pos, player, true)
		end,
	},
}


local nodes = {
	["sell"] = {def.short, def.sell},
	["buy"] = {def.short, def.buy},
	["sell_tall"] = {def.tall, def.sell},
	["buy_tall"] = {def.tall, def.buy},
}

for ntype, defs in pairs(nodes) do
	local full_def = table.copy(def.base)
	for _, d in ipairs(defs) do
		for k, v in pairs(d) do
			full_def[k] = v
		end
	end

	core.register_node(ss.modname..":"..ntype, full_def)
end
