
server_shop = {}

local shops = {}

local function register_shop(name, id, def)
	local shop = {}
	shop.name = name
	shop.id = id
	shop.def = def
	table.insert(shops, shop)
end

local function get_shop(id)
	for _, s in pairs(shops) do
		if s.id == id then
			return s
		end
	end
end

-- shop definition
local products = {
	{"default:cobble", 1},
	{"default:dirt"},
	{"pear", 2},
}


register_shop("Cobble", "cobble", products)


local fs_width = 14
local fs_height = 11
local btn_w = 1.75
local btn_y = 4.6

local function get_products(id)
	local products = ""
	local shop = get_shop(id)

	if shop and shop.def then
		for _, p in ipairs(shop.def) do
			local item = core.registered_items[p[1]]

			if not item then
				core.log("warning", "Unknown item \"" .. p[1] .. "\" for shop ID \"" .. id .. "\"")
				goto continue
			end

			local item_name = item.short_description
			if not item_name then
				item_name = item.description
				if not item_name then
					item_name = p[1]
				end
			end

			local item_price = p[2]
			if not item_price then
				core.log("warning", "Price not set for item \"" .. p[1] .. "\" for shop ID \"" .. id .. "\"")
				goto continue
			end

			if products == "" then
				products = item_name .. ": " .. tostring(item_price) .. " MG"
			else
				products = products .. "," .. item_name .. ": " .. tostring(item_price) .. " MG"
			end

			::continue::
		end
	end

	return products
end

local function get_formspec(pos, player_name)
		local meta = core.get_meta(pos)
		local id = meta:get_string("id")
		local deposited = meta:get_int("deposited")

		local formspec = "formspec_version[4]size[" .. tostring(fs_width) .. "," .. tostring(fs_height) .."]"
		if meta:get_string("owner") == player_name then
			formspec = formspec
				.. "button[" .. tostring(fs_width-6.2) .. ",0.2;" .. tostring(btn_w) .. ",0.75;btn_id;Set ID]"
				.. "field[" .. tostring(fs_width-4.3) .. ",0.2;4.1,0.75;input_id;;" .. id .. "]"
		end

		formspec = formspec
			.. "label[0.2,1;Deposited: " .. tostring(deposited) .. " MG]"
			.. "list[context;deposit;0.2,1.5;1,1;0]"
			.. "textlist[2.15,1.5;9.75,3;products;" .. get_products(id) .. ";1;false]"
			.. "button[0.2," .. tostring(btn_y) .. ";" .. tostring(btn_w) .. ",0.75;btn_refund;Refund]"
			.. "button[" .. tostring(fs_width-(btn_w+0.2)) .. "," .. tostring(btn_y) .. ";" .. tostring(btn_w) .. ",0.75;btn_buy;Buy]"
			.. "list[current_player;main;2.15,5.5;8,4;0]"

		local formname = "server_shop"
		if id and id ~= "" then
			formname = formname .. "_" .. id
		end

		formspec = formspec .. formname

		return formspec
end


local currencies = {
	{"currency:minegeld", 1,},
	{"currency:minegeld_5", 5,},
	{"currency:minegeld_10", 10,},
	{"currency:minegeld_50", 50,},
	{"currency:minegeld_100", 100,},
}

--- Calculates how much money is being deposited.
local function calculate_value(stack)
	local value = 0
	for _, c in ipairs(currencies) do
		if stack:get_name() == c[1] then
			value = stack:get_count() * c[2]
			break
		end
	end

	return value
end

--- Calculates money to be returned to player.
--
--  FIXME: not very intuitive
local function calculate_refund(total)
	local refund = 0

	local hun = math.floor(total / 100)
	total = total - (hun * 100)

	local fif = math.floor(total / 50)
	total = total - (fif * 50)

	local ten = math.floor(total / 10)
	total = total - (ten * 10)

	local fiv = math.floor(total / 5)
	total = total - (fiv * 5)

	-- at this point, 'total' should always be divisible by whole number
	local one = total / 1
	total = total - one

	if total ~= 0 then
		core.log("warning", "Refund did not result in 0 deposited balance")
	end

	local refund = {}
	for _, c in ipairs(currencies) do
		local iname = c[1]
		local ivalue = c[2]
		local icount = 0

		if ivalue == 1 then
			icount = one
		elseif ivalue == 5 then
			icount = fiv
		elseif ivalue == 10 then
			icount = ten
		elseif ivalue == 50 then
			icount = fif
		elseif ivalue == 100 then
			icount = hun
		end

		if icount > 0 then
			local stack = ItemStack(iname)
			stack:set_count(icount)
			table.insert(refund, stack)
		end
	end

	return refund
end

core.register_node("server_shop:shop", {
	description = "Shop",
	drawtype = "nodebox",
	tiles = {
		"server_shop_side.png",
		"server_shop_side.png",
		"server_shop_side.png",
		"server_shop_side.png",
		"server_shop_side.png",
		"server_shop_front.png",
		"server_shop_side.png",
	},
	--[[
	drawtype = "mesh",
	mesh = "server_shop.obj",
	tiles = {"server_shop_mesh.png",},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
	},
	collision_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.45, 0.5},
	},
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
	},
	]]
	groups = {oddly_breakable_by_hand=1,},
	paramtype2 = "facedir",
	after_place_node = function(pos, placer)
		local meta = core.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Owned by: " .. meta:get_string("owner"))
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = core.get_meta(pos)
		meta:set_string("formspec", get_formspec(pos, player:get_player_name()))
		local inv = meta:get_inventory()
		inv:set_size("deposit", 1)
	end,
	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		if player:get_player_name() == meta:get_string("owner") and meta:get_int("deposited") == 0 then
			return true
		end

		return false
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = core.get_meta(pos)
		local pname = sender:get_player_name()

		if fields.btn_id and pname == meta:get_string("owner") then
			local new_id = fields.input_id:trim()
			if new_id ~= "" then
				core.log("action", "Setting shop ID to \"" .. new_id .. "\"")
				meta:set_string("id", new_id)
				fields.input_id = meta:get_string("id")
			end
		elseif fields.btn_refund then
			local pinv = sender:get_inventory()
			local refund = calculate_refund(meta:get_int("deposited"))
			for _, istack in ipairs(refund) do
				print("Refunding " .. tostring(istack:get_count()) .. " of " .. istack:get_name())

				if not pinv:room_for_item("main", istack) then
					-- FIXME: should amount be left in machine & player warned instead of dropping on ground?
					core.chat_send_player(pname, "WARNING: " .. tostring(istack:get_count())
						.. " " .. istack:get_description() .. " was dropped on the ground")
					core.item_drop(istack, sender, sender:get_pos())
				else
					pinv:add_item("main", istack)
				end
			end

			-- reset deposited amount after refund
			meta:set_int("deposited", 0)
		end

		-- refresh formspec dialog
		meta:set_string("formspec", get_formspec(pos, pname))
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local deposited = calculate_value(stack)
		if deposited > 0 then
			local meta = core.get_meta(pos)
			meta:set_int("deposited", meta:get_int("deposited") + deposited)

			-- refresh formspec dialog
			meta:set_string("formspec", get_formspec(pos, player:get_player_name()))

			return -1
		end

		return 0
	end
})
