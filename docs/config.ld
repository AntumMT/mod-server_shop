title = "Shops for Minetest"
project = "server_shop"
format = "markdown"
not_luadoc = true
boilerplate = false

file = {"api.lua", "formspec.lua", "settings.lua",}


local function italic(value)
	return "<span style=\"font-style:italic;\">" .. value .. "</span>"
end

new_type("setting", "Settings")
new_type("chatcmd", "Chat Commands", false, "chatparam")
custom_tags = {
	{"type2",
		title = "Type",
		format = italic,
	},
	{"dfield",
		title = "Definition Fields",
	},
	{"chatparam",
		title = "Parameters",
	},
	{"option",
		title = "Options",
	},
	{"settype",
		title = "Type",
		format = italic,
	},
	{"default",
		title = "Default",
		format = italic,
	},
	{"note",
		title = "Notes",
		format = italic,
	},
}

local function chatcmd_handler(item)
	local output = item.name
	for i, p in ipairs(item.tags.chatparam) do
		output = output .. " " .. p
	end

	return output
end

local function setting_handler(item)
	if item.tags.settype and #item.tags.settype > 1 then
		error("Setting can have only one type")
	end
	if item.tags.default and #item.tags.default > 1 then
		error("Setting can have only one default")
	end

	return item.name
end

function custom_display_name_handler(item, default_handler)
	if item.type == "chatcmd" then
		return chatcmd_handler(item)
	end

	return default_handler(item)
end
