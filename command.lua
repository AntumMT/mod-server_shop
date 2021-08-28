
--- Server Shops Chat Commands
--
--  @topic commands


local ss = server_shop
local S = core.get_translator(ss.modname)


local commands = {
	{
		cmd = "help",
		params = "[" .. S("command") .. "]",
		desc = S("Shows usage info."),
	},
	{
		cmd = "list",
		desc = S("Lists all registered shop IDs."),
	},
	{
		cmd = "info",
		params = "<" .. S("ID") .. ">",
		desc = S("Lists information about a shop."),
	},
	{
		cmd = "register",
		params = "<" .. S("ID") .. ">" .. " <sell/buy> "
			.. " [" .. S("product1=value,product2=value,...") .. "]",
		desc = S("Registers a new shop."),
		persists = true,
	},
	{
		cmd = "unregister",
		params = "<" .. S("ID") .. ">",
		desc = S("Unregisters a shop."),
		persists = true,
	},
	{
		cmd = "add",
		params = "<" .. S("ID") .. "> <" .. S("product1=value,product2=value,...") .. ">",
		desc = S("Adds one or more items to a shop's product list."),
		persists = true,
	},
	{
		cmd = "remove",
		params = "<" .. S("ID") .. "> <" .. S("product") .. ">",
		desc = S("Removes first instance of an item from a shop's product list."),
		persists = true,
	},
	{
		cmd = "removeall",
		params = "<" .. S("ID") .. "> <" .. S("product") .. ">",
		desc = S("Removes all instances of an item from a shop's product list."),
		persists = true,
	},
	{
		cmd = "reload",
		desc = S("Reloads shops configuration."),
	},
}

local format_usage = function(cmd)
	local usage = S("Usage:")
	if cmd then

		local desc, params, persists
		for _, c in ipairs(commands) do
			if c.cmd == cmd then
				desc = c.desc
				params = c.params
				persists = c.persists
				break
			end
		end

		usage = usage .. "\n  /" .. ss.modname .. " " .. cmd
		if params then
			usage = usage .. " " .. params
		end

		if desc then
			if persists then
				desc = desc .. " " .. S("(changes are written to config)")
			end
			usage = desc .. "\n\n" .. usage
		end
	else
		for _, c in ipairs(commands) do
			usage = usage .. "\n  /" .. ss.modname .. " " .. c.cmd

			if c.params then
				usage = usage .. " " .. c.params
			end
		end
	end

	return usage
end


--- Manages shops & config.
--
--  @chatcmd server_shop
--  @param command Command to execute.
--  @param[opt] params Parameters associated with command.
--  @usage
--  /server_shop <command> [<params>]
--
--  Commands:
--  - help
--    - Shows usage info.
--    - parameters: [command]
--  - list
--    - Lists all registered shop IDs.
--  - info
--    - Lists information about a shop.
--    - parameters: <id>
--  - register
--    - Registers new shop & updates configuration.
--    - parameters: <id> <sell/buy> [product1=value,product2=value,...]
--  - unregister
--    - Unregisters shop & updates configuration.
--    - parameters: <id>
--  - add
--    - Adds 1 or more items to a shop's product list.
--    - parameters: <id> <product1=value,product2=value,...>
--  - remove
--    - Removes the first instance of an item from a shop's product list.
--    - parameters: <id> <product>
--  - removeall
--    - Removes all instances of an item from a shop's product list.
--    - parameters: <id> <product>
--  - reload
--    - Reloads shops configuration.
core.register_chatcommand(ss.modname, {
	description = S("Manage shops configuration.") .. "\n\n"
		.. format_usage(),
	privs = {server=true},
	params = "<" .. S("command") .. "> [" .. S("params") .. "]",
	func = function(name, param)
		local params = param:split(" ")
		local cmd = params[1]
		table.remove(params, 1)

		if not cmd then
			return false, S("Must provide a command:") .. "\n\n" .. format_usage()
		end

		local shop_id = params[1]

		if cmd == "help" then
			if #params > 1 then
				return false, S("Too many parameters.") .. "\n\n"
					.. format_usage(cmd)
			end

			if params[1] then
				local sub_cmd
				for _, c in ipairs(commands) do
					if params[1] == c.cmd then
						sub_cmd = c.cmd
						break
					end
				end

				if sub_cmd then
					return true, format_usage(sub_cmd)
				else
					return false, S("Unknown command: @1", sub_cmd)
				end
			end

			return true, S("Manage shops configuration.") .. "\n\n" .. format_usage()
		elseif cmd == "reload" then
			if #params > 0 then
				return false, S('"@1" command takes no parameters.', cmd) .. "\n\n"
					.. format_usage(cmd)
			end

			ss.file_load()
			ss.prune_shops()
			return true, S("Shops configuration loaded.")
		elseif cmd == "register" then
			if #params > 3 then
				return false, S("Too many parameters.") .. "\n\n"
					.. format_usage(cmd)
			end

			local shop_type = params[2]
			local shop_products = params[3]

			if not shop_id then
				return false, S("Must provide ID.") .. "\n\n" .. format_usage(cmd)
			elseif not shop_type then
				return false, S("Must provide type.") .. "\n\n" .. format_usage(cmd)
			end

			if shop_type ~= "sell" and shop_type ~= "buy" then
				return false, S('Shop type must be "@1" or "@2".', "sell", "buy")
					.. "\n\n" .. format_usage(cmd)
			end

			local products = {}
			if shop_products then
				shop_products = shop_products:split(",")
				for _, p in ipairs(shop_products) do
					local item = p:split("=")
					local item_name = item[1]
					local item_value = tonumber(item[2])

					if not core.registered_items[item_name] then
						return false, S('"@1" is not a recognized item.', item_name)
							.. "\n\n" .. format_usage(cmd)
					elseif not item_value then
						return false, S("Item value must be a number.")
							.. "\n\n" .. format_usage(cmd)
					end

					table.insert(products, {item_name, item_value})
				end
			end

			ss.register_persist(shop_id, products, shop_type == "buy")
			return true, S("Registered shop with ID: @1", shop_id)
		elseif cmd == "unregister" then
			if #params > 1 then
				return false, S("Too many parameters.") .. "\n\n"
					.. format_usage(cmd)
			end

			if not shop_id then
				return false, S("Must provide ID.") .. "\n\n" .. format_usage(cmd)
			end

			if not ss.unregister_persist(shop_id) then
				return false, S("Cannot unregister shop with ID: @1", shop_id)
			end

			return true, S("Unregistered shop with ID: @1", shop_id)
		elseif cmd == "add" then
			if #params > 2 then
				return false, S("Too many parameters.") .. "\n\n"
					.. format_usage(cmd)
			end

			if not shop_id then
				return false, S("Must provide ID.") .. "\n\n" .. format_usage(cmd)
			end

			if not ss.is_registered(shop_id) then
				return false, S("Shop ID @1 is not registered.", shop_id)
			end

			local shop_products = params[2]
			if not shop_products then
				return false, S("Must provide product.") .. "\n\n" .. format_usage(cmd)
			end

			local products = {}
			shop_products = shop_products:split(",")
			for _, p in ipairs(shop_products) do
				local item = p:split("=")
				local item_name = item[1]
				local item_value = tonumber(item[2])

				if not core.registered_items[item_name] then
					return false, S('"@1" is not a recognized item.', item_name)
						.. "\n\n" .. format_usage(cmd)
				elseif not item_value then
					return false, S("Item value must be a number.")
						.. "\n\n" .. format_usage(cmd)
				end

				table.insert(products, {item_name, item_value})
			end

			ss.add_product_persist(shop_id, products)
			if #products == 1 then
				return true, S("Added 1 item to shop ID @1.", shop_id)
			else
				return true, S("Added @1 items to shop ID @2.", #products, shop_id)
			end
		elseif cmd == "remove" or cmd == "removeall" then
			if #params > 2 then
				return false, S("Too many parameters.") .. "\n\n"
					.. format_usage(cmd)
			end

			if not shop_id then
				return false, S("Must provide ID.").. "\n\n" .. format_usage(cmd)
			end

			local product = params[2]
			if not product then
				return false, S("Must provide product.") .. "\n\n" .. format_usage(cmd)
			end

			local count = 0
			if cmd == "remove" then
				count = ss.remove_product_persist(shop_id, product, false)
			else
				count = ss.remove_product_persist(shop_id, product, true)
			end

			if count then
				if count == 1 then
					return true, S("Removed 1 item from shop ID @1.", shop_id)
				elseif count > 1 then
					return true, S("Removed @1 items from shop ID @2.", count, shop_id)
				end
			end

			return false, S("Shop ID @1 does not contain @2 in its product list.", shop_id, product)
		elseif cmd == "list" then
			if #params > 0 then
				return false, S('"@1" command takes no parameters.', cmd) .. "\n\n"
			end

			local shops_list = {}
			for id in pairs(ss.get_shops()) do
				table.insert(shops_list, id)
			end

			local msg
			local id_count = #shops_list
			if id_count > 0 then
				if id_count == 1 then
					msg = S("There is 1 shop registered: @1", table.concat(shops_list, ", "))
				else
					msg = S("There are @1 shops registered: @2", id_count, table.concat(shops_list, ", "))
				end
			else
				msg = S("There are no shops registered.")
			end

			return true, msg
		elseif cmd == "info" then
			if #params > 1 then
				return false, S("Too many parameters.") .. "\n\n"
					.. format_usage(cmd)
			end

			if not shop_id then
				return false, S("Must provide ID.").. "\n\n" .. format_usage(cmd)
			end

			local shop = ss.get_shop(shop_id)
			if not shop then
				return false, S("Shop ID @1 is not registered.", shop_id)
			end

			local s_type = S("seller")
			if shop.buyer then
				s_type = S("buyer")
			end

			local product_list = {}
			for _, p in ipairs(shop.products) do
				p = p[1] .. " (" .. p[2]
				if ss.currency_suffix then
					p = p .. " " .. ss.currency_suffix
				end
				p = p .. ")"

				table.insert(product_list, p)
			end

			return true, S("Information about shop ID: @1", shop_id)
				.. "\n" .. S("Type: @1", s_type)
				.. "\n" .. S("Products: @1", table.concat(product_list, ", "))
		end

		return false, S("Unknown command: @1", cmd)
	end,
})
