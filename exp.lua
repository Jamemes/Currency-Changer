function ExperienceManager:cash_string(cash, cash_sign)
	local sign = ""
	if cash < 0 then
		sign = "-"
	end
	
	local final_cash_sign = type(cash_sign) == "string" and (cash_sign or self._cash_sign) or self._cash_sign
	return sign .. tweak_data:sep(cash, final_cash_sign)
end