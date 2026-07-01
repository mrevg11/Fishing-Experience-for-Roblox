-- FishData
-- Спільна таблиця риби (ціни, рідкість, умови) — використовується
-- FishingSystem (лов), EconomySystem (продаж) і HubBuilder (NPC-магазин)

local FishData = {
	-- ZONE 1 — SHALLOWS
	["Perch"]           = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 10,   museumIncome = 1.0,  spoilTime = 1800 },
	["Pond Lurker"]     = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 12,   museumIncome = 1.2,  spoilTime = 1800 },
	["Roach"]           = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 10,   museumIncome = 1.0,  spoilTime = 1800 },
	["Goby"]            = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 11,   museumIncome = 1.1,  spoilTime = 1800 },
	["Surf Crab"]       = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 13,   museumIncome = 1.3,  spoilTime = 1800 },
	["Serpent Crawler"] = { rarity = "Uncommon",  zone = 1, condition = "anytime", basePrice = 32,   museumIncome = 3.0,  spoilTime = 3600 },
	["Silver Bream"]    = { rarity = "Uncommon",  zone = 1, condition = "anytime", basePrice = 38,   museumIncome = 3.5,  spoilTime = 3600 },
	["Copper Eel"]      = { rarity = "Rare",      zone = 1, condition = "anytime", basePrice = 110,  museumIncome = 8.5,  spoilTime = 10800 },
	["Goldfin Pike"]    = { rarity = "Rare",      zone = 1, condition = "anytime", basePrice = 120,  museumIncome = 9.0,  spoilTime = 10800 },
	["Guardian Crab"]   = { rarity = "Epic",      zone = 1, condition = "day",     basePrice = 360,  museumIncome = 20.0, spoilTime = 43200 },
	["Armored Catfish"] = { rarity = "Epic",      zone = 1, condition = "day",     basePrice = 400,  museumIncome = 22.0, spoilTime = 43200 },
	["Sun Ray"]         = { rarity = "Legendary", zone = 1, condition = "day",     basePrice = 1300, museumIncome = 65.0, spoilTime = math.huge },
	["Moon Serpent"]    = { rarity = "Legendary", zone = 1, condition = "night",   basePrice = 1800, museumIncome = 80.0, spoilTime = math.huge },
	["Misty Tench"]     = { rarity = "Epic",      zone = 1, condition = "fog",     basePrice = 420,  museumIncome = 25.0, spoilTime = 43200 },
	["Thunder Jaw"]     = { rarity = "Legendary", zone = 1, condition = "storm",   basePrice = 2200, museumIncome = 90.0, spoilTime = math.huge },

	-- ZONE 2 — THE REEFS
	["Pearl Grouper"]       = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 14,   museumIncome = 1.4,  spoilTime = 1800 },
	["Painted Wrasse"]      = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 13,   museumIncome = 1.3,  spoilTime = 1800 },
	["Red Mullet"]          = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 11,   museumIncome = 1.1,  spoilTime = 1800 },
	["Spiny Drifter"]       = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 12,   museumIncome = 1.2,  spoilTime = 1800 },
	["Sea Urchin"]          = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 10,   museumIncome = 1.0,  spoilTime = 1800 },
	["Tiger Moray"]         = { rarity = "Uncommon",  zone = 2, condition = "anytime", basePrice = 40,   museumIncome = 3.8,  spoilTime = 3600 },
	["Blue Scorpionfish"]   = { rarity = "Uncommon",  zone = 2, condition = "anytime", basePrice = 45,   museumIncome = 4.0,  spoilTime = 3600 },
	["Reef Loach"]          = { rarity = "Rare",      zone = 2, condition = "anytime", basePrice = 105,  museumIncome = 8.0,  spoilTime = 10800 },
	["Clownfish"]           = { rarity = "Rare",      zone = 2, condition = "anytime", basePrice = 130,  museumIncome = 9.5,  spoilTime = 10800 },
	["Flame Anemone"]       = { rarity = "Epic",      zone = 2, condition = "day",     basePrice = 370,  museumIncome = 21.0, spoilTime = 43200 },
	["Coral Jellyfish"]     = { rarity = "Epic",      zone = 2, condition = "day",     basePrice = 420,  museumIncome = 23.0, spoilTime = 43200 },
	["Crystal Shark"]       = { rarity = "Legendary", zone = 2, condition = "day",     basePrice = 1500, museumIncome = 70.0, spoilTime = math.huge },
	["Reef Phantom"]        = { rarity = "Legendary", zone = 2, condition = "night",   basePrice = 2000, museumIncome = 85.0, spoilTime = math.huge },
	["Milky Chimera"]       = { rarity = "Legendary", zone = 2, condition = "fog",     basePrice = 2400, museumIncome = 95.0, spoilTime = math.huge },
	["Lightning Barracuda"] = { rarity = "Legendary", zone = 2, condition = "storm",   basePrice = 2600, museumIncome = 100.0, spoilTime = math.huge },
}

return FishData
