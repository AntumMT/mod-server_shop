
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


core.register_node("server_shop:shop", {
	description = "Shop",
	tiles = {
		"server_shop.png",
		"server_shop.png",
		"server_shop.png",
		"server_shop.png",
		"server_shop.png",
		"server_shop_front.png",
		"server_shop.png"},
	drawtype = "normal",
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
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = core.get_meta(pos)

		if fields.btn_id and sender:get_player_name() == meta:get_string("owner") then
			local new_id = fields.input_id:trim()
			if new_id ~= "" then
				core.log("action", "Setting shop ID to \"" .. new_id .. "\"")
				meta:set_string("id", new_id)
				-- FIXME: update input field text
				fields.input_id = meta:get_string("id")
			end
		end
	end,
})
