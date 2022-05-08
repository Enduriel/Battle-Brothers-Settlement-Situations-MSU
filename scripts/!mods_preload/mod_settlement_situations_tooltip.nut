::SettlementSituations <- {
	ID = "mod_settlement_situations_tooltip",
	Version = "0.1.0",
	Name = "Settlement Situations Tooltip",
	Icons = [
		"PriceMult", // not sure if this is necessary
		"BuyPriceMult",
		"SellPriceMult",
		"FoodPriceMult",
		"MedicalPriceMult",
		"BuildingPriceMult",
		"IncensePriceMult",
		"RarityMult",
		"FoodRarityMult",
		"MedicalRarityMult",
		"MineralRarityMult",
		"BuildingRarityMult",
		"RecruitsMult"
	]
}
::mods_registerMod(::SettlementSituations.ID, ::SettlementSituations.Version, ::SettlementSituations.Name);

local function green( _value )
{
	return "[color=" + ::Const.UI.Color.PositiveValue + "]" + _value + "[/color]"
}

local function red( _value )
{
	return "[color=" + ::Const.UI.Color.NegativeValue + "]" + _value + "[/color]"
}

local function moreGood( _change );
{
	return _change < 0 ? red(_change + "%") + " less" : green(_change + "%") + " more";
}

local function moreBad( _change )
{
	return _change < 0 ? green(_change + "%") + " less" : red(_change + "%") + " more";
}

::mods_queue(::SettlementSituations.ID, "mod_msu(>=1.0.0-beta)", function()
{
	::SettlementSituations.getStringForPair <- function( _key, _value )
	{
		local change = ::Math.round(_value * 100 - 100);
		switch (_key)
		{
			case "BuyPriceMult":
				return "Selling items for " + moreBad(change) + ".";
			case "SellPriceMult":
				return "Buying items for " + moreGood(change) + ".";
			case "FoodPriceMult":
				return "Trading food for " + moreBad(change) + ".";
			case "MedicalPriceMult":
				return "Selling medical supplies for " + moreBad(change) + ".";
			case "BuildingPriceMult":
				return "Trading building materials for " + moreGood(change) + ".";
			case "IncensePriceMult":
				return "Trading Incense for " + moreGood(change) + ".";
			case "RarityMult":
				return ::MSU.String.replace(moreGood(change), "less", "fewer") + " items for sale.";
			case "FoodRarityMult":
				return moreGood(change) + " food for sale.";
			case "MedicalRarityMult":
				return moreGood(change) + " mediical supplies for sale.";
			case "MineralRarityMult":
				return moreGood(change) + " minerals for sale.";
			case "BuildlingRarityMult":
				return moreGood(change) + " building materials for sale.";
			case "RecruitsMult":
				return ::MSU.String.replace(moreGood(change), "less", "fewer") + " recruits are available.";
			default:
				return _key + " " + change + "%";
		}
	}

	::SettlementSituations.getIconForKey <- function( _key )
	{
		if (Icons.find(_modifierID) != null)
		{
			return "ui/mods/settlement_situations_tooltip/" + _modifierID + ".png"
		}
		return "ui/mods/settlement_situations_tooltip/RarityMult.png";
	}

	::SettlementSituations.getPluralBackgroundName <- function( _backgroundString )
	{
		local name = ::new("scripts/skills/backgrounds/" + _backgroundString).getName().tolower();
		if (name.find("man") != null)
		{
			name = ::MSU.String.replace(name, "man", "men");
		}
		else if (name.find("hief") != null)
		{
			name = ::MSU.String.replace(name, "hief", "hieves");
		}
		else if (name.find("killer") != null)
		{
			name = ::MSU.String.replace(name, "killer", "killers");
		}
		else
		{
			name += "s";
		}
		return name;
	}

	::mods_hookBaseClass("entity/world/settlements/situations/situation", function (o)
	{
		local onUpdate = ::mods_getMember(o, "onUpdate");
		local onUpdateDraftList = ::mods_getMember(o, "onUpdateDraftList");

		o = o[o.SuperName];

		local getTooltip = o.getTooltip;
		o.getTooltip = function()
		{
			local ret = getTooltip();

			// first get modifiers
			local modifiers = ::new("scripts/entity/settlement_modifiers")
			::MSU.Table.apply(modifiers, @(_key, _value) typeof _value == "float" ? 1.0 : _value);
			onUpdate(modifiers);
			modifiers.SellPriceMult *= modifiers.PriceMult;
			modifiers.BuyPriceMult *= modifiers.PriceMult;
			modifiers.rawdelete("PriceMult")

			local changedModifiers = ::MSU.Table.filter(function(_key, _value)
			{
				if (typeof _value == "float") return _value != 1.0;
				return false;
			});

			foreach (key, value in changedModifiers)
			{
				ret.push({
					id = ret.len() + 1,
					type = "text",
					icon = ::SettlementSituations.getIconForKey(key),
					text = ::SettlementSituations.getStringForPair(key, value)
				})
			}

			// then draft list
			local draftList = [];
			onUpdateDraftList(draftList);
			local reducedList = {};
			foreach (value in draftList)
			{
				if (value in reducedList)
				{
					reducedList[value] <- ::SettlementSituations.getPluralBackgroundName(value);
				}
			}

			local draftListSentence = "";
			for (local i = reducedList.len() - 2; i > 0; --i)
			{
				draftListSentence += reducedList.pop() + ", "
			}
			if (draftList.len() == 2)
			{
				draftListSentence += reducedList[1] + " and " + reducedList[0];
			}
			else
			{
				draftListSentence += reducedList[0];
			}

			ret.push({
				id = ret.len() + 1,
				type = "text",
				icon = ::SettlementSituations.getIconForKey("RecruitsMult"),
				text = draftListSentence + " are more likely to be available for hire."
			})

			return ret;
		}
	});
});
