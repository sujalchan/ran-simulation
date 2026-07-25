local FrequencyData = {}

-- store all available frequency options
FrequencyData.Options = {
	{ 
		name = "4G 700 MHz", 
		band = "700 MHz", 
		divisor = 1.2, 
		maxDistance = 45 
	},
	{ 
		name = "4G 1800 MHz", 
		band = "1800 MHz", 
		divisor = 0.9, 
		maxDistance = 40 
	},
	{ 
		name = "4G 2100 MHz", 
		band = "2100 MHz", 
		divisor = 0.7, 
		maxDistance = 35 
	},
	{ 
		name = "5G 3500 MHz", 
		band = "3500 MHz", 
		divisor = 0.5, 
		maxDistance = 30 
	},
}

-- create a lookup table by band name
FrequencyData.ByBand = {}
for _, option in ipairs(FrequencyData.Options) do
	FrequencyData.ByBand[option.band] = option
end

-- use 3500 mhz as the default option
FrequencyData.Default = FrequencyData.ByBand["3500 MHz"]

return FrequencyData