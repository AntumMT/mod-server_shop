
--- Server Shops API
--
--  @topic api.lua


local ss = server_shop


local shops = {}

ss.get_shops = function()
	return table.copy(shops)
end

local registered_currencies = {}

-- Suffix displayed after deposited amount.
ss.currency_suffix = nil

--- Checks if there are registered currencies in order to give refunds.
--
--  @function server_shop.currency_is_registered
--  @treturn bool `true` if at least one currency item is registered.
ss.currency_is_registered = function()
	for k, v in pairs(registered_currencies) do
		return true
	end

	return false
end

--- Retrieves registered currencies & values.
--
--  @function server_shop.get_currencies
--  @treturn table Registered currencies.
ss.get_currencies = function()
	return table.copy(registered_currencies)
end

--- Registers an item that can be used as currency.
--
--  @function server_shop.register_currency
--  @tparam string item Item name.
--  @tparam int value Value the item should represent.
ss.register_currency = function(item, value)
	if not core.registered_items[item] then
		ss.log("warning", "Registering unrecognized item as currency: " .. item)
	end

	value = tonumber(value)
	if not value then
		ss.log("error", "Currency type for " .. item .. " must be a number. Got \"" .. type(value) .. "\"")
		return
	end

	local old_value = registered_currencies[item]
	if old_value then
		ss.log("warning", "overwriting value for currency " .. item
			.. " from " .. tostring(old_value)
			.. " to " .. tostring(value))
	end

	registered_currencies[item] = value

	ss.log("action", item .. " registered as currency with value of " .. tostring(value))
end

if ss.use_currency_defaults then
	if not core.get_modpath("currency") then
		ss.log("warning", "currency mod not found, not registering default currencies")
	else
		local mg_notes = {
			{"currency:minegeld", 1},
			{"currency:minegeld_5", 5},
			{"currency:minegeld_10", 10},
			{"currency:minegeld_50", 50},
			{"currency:minegeld_100", 100},
		}

		for _, c in ipairs(mg_notes) do
			ss.register_currency(c[1], c[2])
		end

		ss.currency_suffix = "MG"
	end
end

--- Checks ID string for invalid characters.
--
--  @function server_shop.format_id
--  @tparam string id Shop identifier string.
--  @treturn string Formatted string.
ss.format_id = function(id)
	return id:trim():gsub("%s", "_")
end

--- Used for debugging.
--
--  @local
--  @tparam table products
--  @tparam[opt] string delim
local format_shop_list = function(products, delim)
	delim = delim or ", "

	local p_list = {}
	for _, p in ipairs(products) do
		local p_string = tostring(p[1]) .. ": " .. tostring(p[2])
		if ss.currency_suffix then
			p_string = p_string .. " " .. ss.currency_suffix
		end

		table.insert(p_list, p_string)
	end

	return table.concat(p_list, delim)
end

--- Registers a shop.
--
--  **Aliases:**
--
--  - server\_shop.register\_shop
--
--  @function server_shop.register
--  @tparam string id Shop string identifier.
--  @tparam table[string,int] products List of products & prices in format `{item_name, price}`.
--  @tparam[opt] bool buyer
ss.register = function(id, products, buyer, buyer_old)
	if type(id) ~= "string" then
		ss.log("error", ss.modname .. ".register: invalid \"id\" parameter")
		return
	end

	local shop_def = {}

	if type(products) == "string" then
		ss.log("warning", ss.modname .. ".register: string \"products\" parameter deprecated")
		shop_def.products = buyer
		shop_def.buyer = buyer_old == true
	else
		shop_def.products = products
		shop_def.buyer = buyer == true
	end

	if type(shop_def.products) ~= "table" then
		ss.log("error", ss.modname .. ".register: invalid \"products\" list")
		return
	end

	id = ss.format_id(id)

	if shops[id] ~= nil then
		ss.log("warning", "overwriting shop with ID: " .. id)
	end

	shops[id] = shop_def
	ss.log("action", "registered " .. ss.shop_type(id) .. " shop with ID: " .. id)
	ss.log("debug", "product list:\n  " .. format_shop_list(shops[id].products, "\n  "))
end

-- backward compatibility
ss.register_shop = ss.register

--- Unregisters a shop.
--
--  @function server_shop.unregister
--  @tparam string Shop ID.
--  @treturn bool `true` if shop was unregistered.
ss.unregister = function(id)
	if shops[id] ~= nil then
		local stype = ss.shop_type(id)
		shops[id] = nil
		ss.log("action", "unregistered " .. stype .. " shop with ID: " .. id)
		return true
	end

	ss.log("action", "cannot unregister non-registered shop with ID: " .. id)
	return false
end

--- Registers a seller shop.
--
--  @function server_shop.register_seller
--  @tparam table[string,int] products List of products & prices in format `{item_name, price}`.
ss.register_seller = function(id, products, old_products)
	if type(products) == "string" then
		ss.log("warning", ss.modname .. ".register_seller: string \"products\" parameter deprecated")
		products = old_products
	end

	return ss.register(id, products)
end

--- Registers a buyer shop.
--
--  @function server_shop.register_buyer
--  @tparam string id Shop string identifier.
--  @tparam table[string,int] products List of products & prices in format `{item_name, price}`.
ss.register_buyer = function(id, products, old_products)
	if type(products) == "string" then
		ss.log("warning", ss.modname .. ".register_buyer: string \"products\" parameter deprecated")
		products = old_products
	end

	return ss.register(id, products, true)
end

--- Retrieves shop product list.
--
--  @function server_shop.get_shop
--  @tparam string id String identifier of shop.
--  @tparam bool buyer Denotes whether seller or buyer shops will be parsed (default: false) (deprecated).
--  @treturn table Table of shop contents.
ss.get_shop = function(id, buyer)
	if buyer ~= nil then
		ss.log("warning", "get_shop: \"buyer\" parameter is deprecated")
	end

	local s = shops[id]
	if s then
		s = table.copy(s)
	end

	return s
end

--- Checks if a shop is registered.
--
--  @function server_shop.is_registered
--  @tparam string id Shop string identifier.
--  @tparam bool buyer Denotes whether to check seller or buyer shops (default: false) (deprecated).
--  @treturn bool `true` if the shop ID is found.
ss.is_registered = function(id, buyer)
	if buyer ~= nil then
		ss.log("warning", "is_registered: \"buyer\" parameter is deprecated")
	end

	return ss.get_shop(id) ~= nil
end

---
--
--  @function server_shop.shop_type
--  @tparam string id
ss.shop_type = function(id)
	local shop = ss.get_shop(id)
	if shop == nil then
		return "unregistered"
	end

	if shop.buyer then
		return "buyer"
	end

	return "seller"
end

--- Checks if a player has admin rights to for managing shop.
--
--  @function server_shop.is_shop_admin
--  @tparam ObjectRef player Player requesting permissions.
--  @return `true` if player has *server* priv.
ss.is_shop_admin = function(player)
	if not player then
		return false
	end

	return core.check_player_privs(player, "server")
end

--- Checks if a player is the owner of node.
--
--  @function server_shop.is_shop_owner
--  @tparam vector pos Position of shop node.
--  @tparam ObjectRef player Player to be checked.
--  @treturn bool `true` if player is owner.
ss.is_shop_owner = function(pos, player)
	if not player then
		return false
	end

	local meta = core.get_meta(pos)
	return player:get_player_name() == meta:get_string("owner")
end

local shops_file = core.get_worldpath() .. "/server_shops.json"

local function shop_file_error(msg)
	ss.log("error", shops_file .. ": " .. msg)
end

--- Loads configuration from world path.
--
--  Configuration file is <world\_path>/server\_shops.json
--
--  @function server_shop.file_load
ss.file_load = function()
	ss.log("debug", "loading server_shops.json")

	local shops_data = wdata.read("server_shops") or {}

	-- update from legacy format
	if #shops_data > 0 then
		ss.log("action", "updating server_shops.json from legacy format ...")

		local new_shops_data = {shops={}, currencies={}}

		for _, entry in ipairs(shops_data) do
			if entry.type == "currency" then
				ss.log("warning", "using \"currency\" key in server_shops.json is deprecated,"
					.. " please use \"currencies\"")

				new_shops_data.currencies[entry.name] = entry.value
			elseif entry.type == "currencies" then
				-- allow "value" to be used instead of "currencies"
				if not entry.currencies then entry.currencies = entry.value end

				for k, v in pairs(entry.currencies) do
					new_shops_data.currencies[k] = v
				end
			elseif entry.type == "suffix" then
				new_shops_data.suffix = entry.value
			elseif entry.type == "sell" or entry.type == "buy" then
				if type(entry.id) ~= "string" or entry.id:trim() == "" then
					shop_file_error("invalid or undeclared \"id\"; must be non-empty string")
				end

				new_shops_data.shops[entry.id] = {products=entry.products, type=entry.type}
			elseif not entry.type then
				shop_file_error("mandatory \"type\" parameter not set for shop ID: "
					.. tostring(entry.id))
			else
				shop_file_error("unrecognized type \"" .. entry.type
					.. "\" for shop ID: " .. tostring(entry.id))
			end
		end

		shops_data = new_shops_data

		-- backup legacy file
		os.rename(shops_file, shops_file .. ".bak")
		-- update config
		wdata.write("server_shops", shops_data)
	end

	if shops_data.suffix ~= nil then
		if type(shops_data.suffix) == "string" then
			ss.currency_suffix = shops_data.suffix
		else
			shop_file_error("\"suffix\" must be a string")
		end
	end

	if shops_data.currencies ~= nil then
		if type(shops_data.currencies) == "table" then
			for k, v in pairs(shops_data.currencies) do
				ss.register_currency(k, v)
			end
		else
			shop_file_error("\"currencies\" must be a table")
		end
	end

	if shops_data.shops ~= nil then
		if type(shops_data.shops) == "table" then
			for id, def in pairs(shops_data.shops) do
				if def.type ~= "sell" and def.type ~= "buy" then
					shop_file_error("shop \"type\" must by either \"sell\" or \"buy\" for ID: " .. id)
				else
					ss.register(id, def.products, def.type == "buy")
				end
			end
		else
			shop_file_error("\"shops\" must be a table")
		end
	end
end

--- Permanently registers a shop.
--
--  @function server_shop.file_register
--  @tparam string id Shop identifier.
--  @tparam ProductList products List of products & values.
--  @tparam[opt] bool buyer
ss.file_register = function(id, products, buyer)
	local shops_data = wdata.read("server_shops") or {}
	shops_data.shops = shops_data.shops or {}

	local s_type = "sell"
	if buyer then
		s_type = "buy"
	end

	shops_data.shops[id] = {products=products, type=s_type}
	wdata.write("server_shops", shops_data)
end

--- Permanently adds a product to a shop.
--
--  @function server_shop.file_add_product
--  @tparam string id Shop identifier.
--  @tparam string name Item technical name.
--  @tparam int value Item value.
--  @tparam[opt] int idx Shop index for item placement.
ss.file_add_product = function(id, name, value, idx)
	local shops_data = wdata.read("server_shops") or {}
	shops_data.shops = shops_data.shops or {}
	local target_shop = shops_data[id]

	if not target_shop then
		ss.log("error", "file_add_product: cannot add item to unknown shop ID: " .. tostring(id))
		return false
	elseif type(name) ~= "string" then
		ss.log("error", "file_add_product: \"name\" must be a string for shop ID: " .. id)
		return false
	elseif type(value) ~= "number" then
		ss.log("error", "file_add_product: \"value\" must be a number for shop ID: " .. id)
		return false
	end

	-- FIXME: check for duplicates

	if not idx or idx > #target_shop.products then
		table.insert(target_shop.products, {name, value})
	else
		table.insert(target_shop.products, idx, {name, value})
	end

	ss.register(id, target_shop)
	wdata.write("server_shops", shops_data)
end

--- Unregisters a shop & updates configuration.
--
--  @function server_shop.file_unregister
--  @tparam string id Shop identifier.
--  @treturn bool
ss.file_unregister = function(id)
	local shops_data = wdata.read("server_shops") or {}
	shops_data.shops = shops_data.shops or {}

	if not shops_data.shops[id] then
		ss.log("warning", "cannot unregister unknown shop ID: " .. id)
		return false
	end

	shops_data.shops[id] = nil
	ss.unregister(id)
	wdata.write("server_shops", shops_data)
	return true
end

--- Prunes unknown items & updates aliases in shops.
--
--  @function server_shop.prune_shops
ss.prune_shops = function()
	-- show warning if no currencies are registered
	if not ss.currency_is_registered() then
		ss.log("warning", "no currencies registered")
	else
		local have_ones = false
		for k, v in pairs(ss.get_currencies()) do
			have_ones = v == 1
			if have_ones then break end
		end

		if not have_ones then
			ss.log("warning", "no currency registered with value 1, players may not be refunded all of their money")
		end
	end

	-- prune unregistered items & items without value
	for id, def in pairs(ss.get_shops()) do
		local s_type = def.buyer and "buyer" or "seller"

		local pruned = false
		for idx = #def.products, 1, -1 do
			local product = def.products[idx][1]
			local value = def.products[idx][2]

			if not value then
				ss.log("warning", "pruning item \"" .. product
					.. "\" without value from " .. s_type .. " shop ID: " .. id)
				table.remove(def.products, idx)
				pruned = true
			elseif not core.registered_items[product] then
				local alias_of = core.registered_aliases[product]
				if not alias_of then
					ss.log("warning", "pruning unregistered item \"" .. product
						.. "\" from " .. s_type .. " shop ID: " .. id)
				end

				table.remove(def.products, idx)
				pruned = true

				if alias_of then
					ss.log("action", "replacing alias \"" .. product .. "\" with \""
						.. alias_of .. "\" in seller shop ID: " .. id)
					table.insert(def.products, idx, {alias_of, value})
				end
			end
		end

		if pruned then
			ss.register(id, def.products, def.buyer)
		end
	end
end
