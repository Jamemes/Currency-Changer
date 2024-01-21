local data = ExperienceManager.cash_string
function ExperienceManager:cash_string(cash, cash_sign)
	if not cash_sign or cash_sign == "$" then
			local sign = ""
			if cash < 0 then
				sign = "-"
			end

		local final_cash_sign = type(cash_sign) == "string" and (cash_sign or tweak_data.cash_sign) or tweak_data.cash_sign
		return sign .. final_cash_sign .. tweak_data:sep(cash * tweak_data.currency)
	end
	
	return data(self, cash, cash_sign)
end