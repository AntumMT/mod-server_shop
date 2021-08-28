
local ss = server_shop
local transaction = dofile(ss.modpath .. "/transaction.lua")


local seller_callbacks = {
	allow_put = function(inv, listname, index, stack, player)
		local p_meta = player:get_meta()
		local id = p_meta:get_string(ss.modname .. ":id")
		if id:trim() == "" then return 0 end

		local to_deposit = transaction.calculate_currency_value(stack)
		if to_deposit <= 0 then return 0 end

		local pos = core.deserialize(p_meta:get_string(ss.modname .. ":pos"))
		if not pos then return 0 end

		transaction.set_deposit(id, player, transaction.get_deposit(id, player) + to_deposit)

		-- refresh formspec dialog
		ss.show_formspec(pos, player)

		return -1
	end,
}

local buyer_callbacks = {
	allow_put = function(inv, listname, index, stack, player)
		local p_meta = player:get_meta()
		local id = p_meta:get_string(ss.modname .. ":id")
		if id:trim() == "" then return 0 end

		local to_deposit = transaction.calculate_product_value(stack, id, true)
		if to_deposit <= 0 then return 0 end

		local pos = core.deserialize(p_meta:get_string(ss.modname .. ":pos"))
		if not pos then return 0 end

		local s_name = stack:get_name()
		local s_count = stack:get_count()
		local dep = transaction.get_deposit(id, player, true)
		dep.name = dep.name or s_name
		dep.count = dep.count or 0

		if dep.name ~= s_name then
			dep.name = s_name
			dep.count = s_count
		else
			dep.count = dep.count + s_count
		end

		transaction.set_deposit(id, player, dep, true)

		return s_count
	end,

	allow_take = function(inv, listname, index, stack, player)
		-- clear deposit
		local p_meta = player:get_meta()
		local id = p_meta:get_string(ss.modname .. ":id")
		if id:trim() ~= "" then
			if not transaction.clear_deposit(id, player, true) then
				ss.log("warning", "InvRef.allow_take: could not clear deposit from buyer shop ID: " .. id)
			end
		end

		return stack:get_count()
	end,
}


--- Formats inventory name.
--
--  @local
--  @tparam string p_name Player's name.
--  @tparam[opt] bool buyer
--  @treturn string Inventory name.
local get_inv_name = function(p_name, buyer)
	local inv_type = "sell"
	if buyer then
		inv_type = "buy"
	end

	return ss.modname .. ":" .. inv_type .. ":" .. p_name
end

--- Retrieves a shop inventory.
--
--  If the inventory does not exist, a new one is created.
--
--  @local
--  @tparam string p_name Player's name.
--  @tparam[opt] bool buyer
--  @return Inventory (`InvRef`) & inventory name (`string`).
local get_inv = function(p_name, buyer)
	local inv_name = get_inv_name(p_name, buyer)
	local inv = core.get_inventory({type="detached", name=inv_name})

	if not inv then
		local callbacks = seller_callbacks
		if buyer then
			callbacks = buyer_callbacks
		end

		inv = core.create_detached_inventory(inv_name, callbacks)
		inv:set_size("deposit", 1)
	end

	return inv, inv_name
end


return {
	get_name = get_inv_name,
	get = get_inv,
}
