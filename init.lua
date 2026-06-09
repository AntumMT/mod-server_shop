
server_shop = {
	modname = core.get_current_modname(),
	log = function() end
}
server_shop.modpath = core.get_modpath(server_shop.modname)

if core.global_exists("register_mod_logger") then
	register_mod_logger(server_shop)
end

local ss = server_shop

local scripts = {
	"settings",
	"api",
	"deposit",
	"formspec",
	"node",
	"command",
}

for _, script in ipairs(scripts) do
	dofile(ss.modpath .. "/" .. script .. ".lua")
end


ss.file_load()
core.register_on_mods_loaded(function()
	ss.prune_shops(true)
end)
