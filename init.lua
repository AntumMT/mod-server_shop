
server_shop = {}
local ss = server_shop

ss.modname = core.get_current_modname()
ss.modpath = core.get_modpath(ss.modname)

function ss.log(lvl, msg)
	if not msg then
		msg = lvl
		lvl = nil
	end

	msg = "[" .. ss.modname .. "] " .. msg
	if not lvl then
		core.log(msg)
	else
		core.log(lvl, msg)
	end
end

local scripts = {
	"settings",
	"api",
	"deposit",
	"formspec",
	"node",
}

for _, script in ipairs(scripts) do
	dofile(ss.modpath .. "/" .. script .. ".lua")
end


ss.file_load()

core.register_on_mods_loaded(function()
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

	-- prune unregistered items
	for id, def in pairs(ss.get_shops()) do
		local pruned = false
		for idx = #def.products, 1, -1 do
			local pname = def.products[idx][1]
			local value = def.products[idx][2]
			if not core.registered_items[pname] then
				ss.log("warning", "removing unregistered item \"" .. pname
					.. "\" from seller shop id \"" .. id .. "\"")
				table.remove(def.products, idx)
				pruned = true
			elseif not value then
				-- FIXME: this should be done in registration method
				ss.log("warning", "removing item \"" .. pname
					.. "\" without value from seller shop id \"" .. id .. "\"")
				table.remove(def.products, idx)
				pruned = true
			end

			-- check aliases
			local alias_of = core.registered_aliases[pname]
			if alias_of then
				ss.log("action", "replacing alias \"" .. pname .. "\" with \"" .. alias_of
					.. "\" in seller shop id \"" .. id .. "\"")
				table.remove(def.products, idx)
				table.insert(def.products, idx, {alias_of, value})
				pruned = true
			end
		end

		if pruned then
			ss.unregister(id)
			ss.register(id, def)
		end
	end
end)
