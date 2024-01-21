function MoneyManager:total_string()
	return tweak_data.cash_sign .. tweak_data:sep(self:total() * tweak_data.currency)
end

function MoneyManager:total_string_no_currency()
	return (tweak_data.cash_sign == "$" and "" or tweak_data.cash_sign) .. tweak_data:sep(self:total() * tweak_data.currency)
end

function MoneyManager:total_collected_string()
	return tweak_data.cash_sign .. tweak_data:sep(self:total_collected() * tweak_data.currency)
end

function MoneyManager:total_collected_string_no_currency()
	return (tweak_data.cash_sign == "$" and "" or tweak_data.cash_sign) .. tweak_data:sep(self:total_collected() * tweak_data.currency)
end