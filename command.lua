
--- Server Shops Chat Commands
--
--  @topic commands


local ss = server_shop
local S = core.get_translator(ss.modname)


local commands = {"reload"}

--- Manages shops config.
--
--  @chatcmd server_shop
core.register_chatcommand(ss.modname, {
	description = S("Manage shops configuration."),
	privs = {server=true},
	params = "<"..S("command")..">",
	func = function(name, param)
		local params = param:split(" ")
		local cmd = params[1]
		table.remove(params, 1)

		if not cmd then
			return false, S("Must provide a command: @1", table.concat(commands, ", "))
		end

		local unknown_cmd = true
		for _, c in ipairs(commands) do
			if cmd == c then
				unknown_cmd = false
				break
			end
		end

		if unknown_cmd then
		end

		if cmd == "reload" then
			if #params > 0 then
				return false, S('"@1" command takes no parameters.', cmd)
			end

			ss.file_load()
			ss.prune_shops()
			return true, S("Shops configuration loaded.")
		end

		return false, S("Unknown command: @1", cmd)
	end,
})
