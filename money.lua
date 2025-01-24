function MoneyManager:total_string()
	return tweak_data:sep(self:total(), "$")
end

function MoneyManager:total_string_no_currency()
	return tweak_data:sep(self:total())
end

function MoneyManager:total_collected_string()
	return tweak_data:sep(self:total_collected(), "$")
end

function MoneyManager:total_collected_string_no_currency()
	return tweak_data:sep(self:total_collected(), "$")
end