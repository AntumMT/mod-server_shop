
server_shop = {}
server_shop.modname = core.get_current_modname()
server_shop.modpath = core.get_modpath(server_shop.modname)

function server_shop.log(lvl, msg)
	if not msg then
		msg = lvl
		lvl = nil
	end

	if not lvl then
		core.log("[" .. server_shop.modname .. "] " .. msg)
	else
		core.log(lvl, "[" .. server_shop.modname .. "] " .. msg)
	end
end

local scripts = {
	"api",
	"formspec",
	"node",
}

for _, script in ipairs(scripts) do
	dofile(server_shop.modpath .. "/" .. script .. ".lua")
end


-- load configured shops from world directory
local shops_file = core.get_worldpath() .. "/server_shops.lua"
local fopen = io.open(shops_file, "r")
if fopen ~= nil then
	io.close(fopen)
	dofile(shops_file)
end
