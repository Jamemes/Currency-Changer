local url = "https://www.google.com/search?q=usd+to+"
local path = SavePath .. "currency.txt"

local load_currency = io.open(path, 'r')
if load_currency then
	local save = json.decode(load_currency:read('*all'))
	tweak_data.currency = save.currency or 1
	tweak_data.cash_sign = save.cash_sign or "$"
	tweak_data.currency_desc = save.currency_desc or ""
	load_currency:close()
else
	tweak_data.currency = 1
	tweak_data.cash_sign = "$"
end

Hooks:Add("LocalizationManagerPostInit", "currency_changer_loc", function(...)
	LocalizationManager:add_localized_strings({
		currency_desc = tweak_data.currency_desc or "",
		currency_code = "Currency",
	})

	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			currency_code = "Валюта",
		})
	end
end)

local function save_data(tbl)
	local file = io.open(path, 'w+')
	if file then
		file:write(json.encode(tbl))
		file:close()
	end	
end

local function get_info(str, key1, key2)
	local _, fst = string.find(str, key1)
	local sec, _ = string.find(str, key2, fst)
	return string.sub(str, fst + 1, sec - 1)
end

function tweak_data:sep(total)
	if total < 1 then
		return tostring(total)
	end
	
	if string.find(math.round(total), "(%D+)") then
		total = tostring(string.format("%d", total))
	else
		total = tostring(math.round(total))
	end
	
	local reverse = string.reverse(total)
	local s = ""

	for i = 1, string.len(reverse) do
		s = s .. string.sub(reverse, i, i) .. (math.mod(i, 3) == 0 and i ~= string.len(reverse) and managers.localization:text("cash_tousand_separator") or "")
	end

	return string.reverse(s)
end

Hooks:Add("MenuManagerBuildCustomMenus", "_add_currency_code_item", function(menu_manager, nodes)
	local node = nodes.options
	if node then
		local data_node = {
			type = "MenuItemInput"
		}
		local params = {
			name = "currency_code",
			text_id = "currency_code",
			help_id = "currency_desc",
			empty_gui_input_limit = 28,
			callback = "change_currency_call"
		}
		local new_item = node:create_item(data_node, params)
		
		new_item.dirty_callback = callback(node, node, "item_dirty")
		if node.callback_handler then
			new_item:set_callback_handler(node.callback_handler)
		end
		
		local pos = 1
		for id, item in pairs(node._items) do
			if item:name() == "edit_game_settings" then
				pos = id
			end
		end
		
		table.insert(node._items, pos, new_item)
	end
end)
	
function MenuCallbackHandler:change_currency_call(item)
	if not item._editing then
		if item._input_text ~= "" then
			local google = url .. item:input_text()
			dohttpreq(google, function(json_data)
				local xml = json.encode(json_data)
				local currency_desc = get_info(xml, [[BNeawe vvjwJb AP7Wnd\">1 USD to ]], [[- Xe]])
				local currency_code = currency_desc:sub(0, 3)
				local currency = get_info(xml, [[<div class=\"BNeawe iBp4i AP7Wnd\"><div><div class=\"BNeawe iBp4i AP7Wnd\">]], [[ ]]):gsub("(%D+)", function(s)
					return s == [[,]] and [[.]] or ""
				end)

				if currency and (currency ~= "" or not string.find(currency, "(%D+)")) then
					tweak_data.currency = currency
					tweak_data.cash_sign = string.format("[%s] ", currency_code)
					item:set_value(currency_code)
					local currency_desc = "1 USD = " .. currency .. " " .. currency_desc
					LocalizationManager:add_localized_strings({currency_desc = currency_desc})
					managers.menu_component:refresh_player_profile_gui()
					managers.viewport:resolution_changed()
					save_data({
						currency = tweak_data.currency,
						cash_sign = tweak_data.cash_sign,
						currency_desc = currency_desc
					})
				end
			end)
		else
			tweak_data.currency = 1
			tweak_data.cash_sign = "$"
			LocalizationManager:add_localized_strings({currency_desc = ""})
			save_data({})
			managers.menu_component:refresh_player_profile_gui()
			managers.viewport:resolution_changed()
		end
	end
end