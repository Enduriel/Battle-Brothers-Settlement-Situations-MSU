::SettlementSituations <- {
	ID = "mod_settlement_situations_msu",
	Version = "1.0.1",
	Name = "Settlement Situations Tooltip",
	Modifiers = ::MSU.Class.OrderedMap()
}
::SettlementSituations.Modifiers.PriceMult <- 1.0;
::SettlementSituations.Modifiers.BuyPriceMult <- 1.0;
::SettlementSituations.Modifiers.SellPriceMult <- 1.0;
::SettlementSituations.Modifiers.FoodPriceMult <- 1.0;
::SettlementSituations.Modifiers.MedicalPriceMult <- 1.0;
::SettlementSituations.Modifiers.BuildingPriceMult <- 1.0;
::SettlementSituations.Modifiers.IncensePriceMult <- 1.0;
::SettlementSituations.Modifiers.BeastPartsPriceMult <- 1.0;
::SettlementSituations.Modifiers.RarityMult <- 1.0;
::SettlementSituations.Modifiers.FoodRarityMult <- 1.0;
::SettlementSituations.Modifiers.MedicalRarityMult <- 1.0;
::SettlementSituations.Modifiers.MineralRarityMult <- 1.0;
::SettlementSituations.Modifiers.BuildingRarityMult <- 1.0;
::SettlementSituations.Modifiers.RecruitsMult <- 1.0;

::mods_registerMod(::SettlementSituations.ID, ::SettlementSituations.Version, ::SettlementSituations.Name);

::mods_queue(::SettlementSituations.ID, "mod_msu(>1.0.0-beta.1)", function()
{
	::SettlementSituations.Mod <- ::MSU.Class.Mod(::SettlementSituations.ID, ::SettlementSituations.Version, ::SettlementSituations.Name);
	local function green( _value )
	{
		return "[color=" + ::Const.UI.Color.PositiveValue + "]" + _value + "[/color]";
	}

	local function red( _value )
	{
		return "[color=" + ::Const.UI.Color.NegativeValue + "]" + _value + "[/color]";
	}

	local function moreGood( _change )
	{
		return _change < 0 ? red(::Math.abs(_change) + "%") + " less" : green(::Math.abs(_change) + "%") + " more";
	}

	local function moreBad( _change )
	{
		return _change < 0 ? green(::Math.abs(_change) + "%") + " less" : red(::Math.abs(_change) + "%") + " more";
	}

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
			case "BuildingRarityMult":
				return ::MSU.String.replace(moreGood(change), "less", "fewer") + " building materials for sale.";
			case "RecruitsMult":
				return ::MSU.String.replace(moreGood(change), "less", "fewer") + " recruits are available.";
			default:
				return _key + " " + change + "%";
		}
	}

	::SettlementSituations.getIconForKey <- function( _key )
	{
		if (::SettlementSituations.Modifiers.contains(_key) && _key != "PriceMult")
		{
			return "ui/mods/settlement_situations_tooltip/" + _key + ".png"
		}
		return "ui/mods/settlement_situations_tooltip/RarityMult.png";
	}

	::SettlementSituations.getPluralBackgroundName <- function( _backgroundString )
	{
		local name = ::MSU.String.replace(::new("scripts/skills/backgrounds/" + _backgroundString).getName().tolower(), "background: ", "");
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
		return ::MSU.String.capitalizeFirst(name);
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
			local modifiers = clone ::SettlementSituations.Modifiers;

			onUpdate(modifiers);
			modifiers.SellPriceMult *= modifiers.PriceMult;
			modifiers.BuyPriceMult *= modifiers.PriceMult;
			delete modifiers.PriceMult;

			local changedModifiers = modifiers.filter(function(_key, _value, _idx)
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
				});
			}

			// then draft list
			local draftList = [];
			onUpdateDraftList(draftList);
			if (draftList.len() != 0)
			{
				local reducedList = [];
				local reducedListNames = [];
				foreach (value in draftList)
				{
					if (reducedList.find(value) == null)
					{
						reducedList.push(value)
						reducedListNames.push(::SettlementSituations.getPluralBackgroundName(value))
					}
				}

				local draftListSentence = "";
				for (local i = reducedListNames.len() - 2; i > 0; --i)
				{
					draftListSentence += reducedListNames.pop() + ", "
				}
				::MSU.Log.printData(reducedListNames);
				if (reducedListNames.len() == 2)
				{
					draftListSentence += reducedListNames[1] + " and " + reducedListNames[0];
				}
				else
				{
					draftListSentence += reducedListNames[0];
				}

				ret.push({
					id = ret.len() + 1,
					type = "text",
					icon = ::SettlementSituations.getIconForKey("RecruitsMult"),
					text = draftListSentence + " are more likely to be available for hire."
				})
			}

			return ret;
		}
	});
});
