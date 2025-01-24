local url = "https://www.investing.com/currencies/usd-"
local path = SavePath .. "currency.txt"
local load_currency = io.open(path, 'r')
if load_currency then
	local save = json.decode(load_currency:read('*all'))
	tweak_data.currency_data = {
		currency = save.currency,
		currency_name = save.currency_name,
		currency_desc = save.currency_desc,
		currency_format = save.currency_format or '[code] cash',
		cash_sign = save.cash_sign,
	}

	load_currency:close()
else
	tweak_data.currency_data = {
		currency_format = '[code] cash'
	}
end

Hooks:Add("LocalizationManagerPostInit", "currency_changer_loc", function(self)
	LocalizationManager:add_localized_strings({
		currency_desc = tweak_data.currency_data.currency_desc or '',
		currency_code = "Currency code",
		currency_format = "Currency format",
		currency_changed_title = "Currency changed to ",
		currency_loading_desc = "Loading data from Investing.com may take some time: from a few seconds to several minutes.\n\nMake sure the currency code is correct.\nWhen the currency changes, you will receive a notification.\n\nYou can close this message while the data is being loaded.",
	})

	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			currency_code = "Код Валюты",
			currency_format = "Формат валюты",
			currency_changed_title = "Валюта изменена на ",
			currency_loading_desc = "Загрузка данных с сайта Investing.com может занять некоторое время: от пары секунд до нескольких минут.\n\nУбедитесь, что код валюты введен верно.\nКогда валюта поменяется вы получите уведомвление.\n\nВы можете закрыть это сообщение пока ждете загрузку данных.",
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
	local _, fst = string.find(str, key1, 0, true)
	local sec, _ = string.find(str, key2, fst, true)
	return string.sub(str, fst + 1, sec - 1)
end

function tweak_data:sep(total, cash_sign)
	cash_sign = cash_sign or ""
	
	local mul = tweak_data.currency_data.currency and cash_sign ~= "" and tweak_data.currency_data.currency or 1
	total = total * mul
	
	local function cash(money, code, name)
		local cash_format = code and name and tweak_data.currency_data.currency_format or ''
		return cash_sign ~= "" and cash_format ~= '' and cash_format:lower():gsub('cash', money):gsub('code', code):gsub('name', name) or cash_sign .. money
	end
	
	if total < 1 then
		return cash(tostring(total):sub(0, 4), tweak_data.currency_data.cash_sign, tweak_data.currency_data.currency_name)
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

	return cash(string.reverse(s), tweak_data.currency_data.cash_sign, tweak_data.currency_data.currency_name)
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
			input_limit = 5,
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
		
		new_item:set_value(tweak_data.currency_data.cash_sign or "")
		table.insert(node._items, pos, new_item)
	
		local params = {
			callback = "change_currency_format_call",
			name = "currency_format",
			text_id = "currency_format",
		}
		
		local vars = {
			"cash",
			"[code] cash",
			"(code) cash",
			"code cash",
			"cash [code]",
			"cash (code)",
			"cash code",
			"[name] cash",
			"(name) cash",
			"name cash",
			"cash [name]",
			"cash (name)",
			"cash name",
			"[code] cash (name)",
			"(code) cash [name]",
			"code cash name",
			"[name] cash (code)",
			"(name) cash [code]",
			"name cash code",
		}
		
		local data_node = {}
		
		for k, v in pairs(vars) do
			table.insert(data_node, {
				value = v,
				text_id = v,
				localize = false,
				_meta = "option"
			})
		end
		
		data_node.type = "MenuItemMultiChoice"
		local new_item = node:create_item(data_node, params)

		new_item.dirty_callback = callback(node, node, "item_dirty")
		if node.callback_handler then
			new_item:set_callback_handler(node.callback_handler)
		end
		new_item:set_value(tweak_data.currency_data.currency_format)
		table.insert(node._items, pos + 1, new_item)
	end
end)

function MenuCallbackHandler:change_currency_format_call(item)
	tweak_data.currency_data.currency_format = item:value()
	if tweak_data.currency_data.currency then
		save_data(tweak_data.currency_data)
		managers.menu_component:refresh_player_profile_gui()
		managers.viewport:resolution_changed()
	end
end

function MenuCallbackHandler:change_currency_call(item)
	if not item._editing then
		if item._input_text ~= "" then
			local google = url .. item:input_text():lower()
			managers.system_menu:show({
				text = managers.localization:text("currency_loading_desc"),
				id = "loading_currency",
				indicator = true,
				button_list = {
					{
						cancel_button = false,
						text = managers.localization:text("menu_back")
					}
				}
			})
			
			dohttpreq(google, function(json_data)
				local xml = json.encode(json_data)
				
				local currency_desc = get_info(xml, [[USD ]], [[title]]):sub(0, -4)
				local currency_code = item:input_text():upper()
				local currency = get_info(xml, [[instrument-price-last]], [[div]]):gsub("(%D+)", function(s)
					if s ~= [[.]] then
						return ""
					end
				end)
				
				if currency and (currency ~= "" or not string.find(currency, "(%D+)")) then
					local _, dollar = string.find(currency_desc, "Dollar ")
					local cash_name = currency_desc:sub(dollar + 1, -17):gsub("to ", "")
					currency_desc = "1 USD = " .. currency .. " " .. currency_desc
					if managers.system_menu:is_active_by_id("loading_currency") then
						managers.system_menu:close("loading_currency")
					end
					managers.system_menu:show({
						title = managers.localization:text("currency_changed_title") .. currency_code,
						text = currency_desc,
						button_list = {
							{
								text = managers.localization:text("dialog_ok"),
								cancel_button = true
							}
						}
					})
					
					local currency_data = {
						currency = currency,
						cash_sign = currency_code,
						currency_name = cash_name,
						currency_format = tweak_data.currency_data.currency_format,
						currency_desc = currency_desc,
					}
					save_data(currency_data)
					tweak_data.currency_data = currency_data
					
					LocalizationManager:add_localized_strings({currency_desc = currency_desc})
					
					item:set_value(currency_code)
					managers.menu_component:refresh_player_profile_gui()
					managers.viewport:resolution_changed()
				end
			end)
		else
			tweak_data.currency_data = {}
			save_data(tweak_data.currency_data)
			LocalizationManager:add_localized_strings({currency_desc = ""})
			managers.menu_component:refresh_player_profile_gui()
			managers.viewport:resolution_changed()
		end
	end
end