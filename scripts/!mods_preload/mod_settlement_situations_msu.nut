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

::SettlementSituations.HooksMod <- ::Hooks.register(::SettlementSituations.ID, ::SettlementSituations.Version, ::SettlementSituations.Name);
::SettlementSituations.HooksMod.require("mod_msu >= 1.2.0-rc.3");

::SettlementSituations.HooksMod.queue(">mod_msu", function()
{
	::SettlementSituations.Mod <- ::MSU.Class.Mod(::SettlementSituations.ID, ::SettlementSituations.Version, ::SettlementSituations.Name);
	::SettlementSituations.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/Enduriel/Battle-Brothers-Settlement-Situations-MSU");
	::SettlementSituations.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);
	::SettlementSituations.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.NexusMods, "https://www.nexusmods.com/battlebrothers/mods/551");
	local function moreGood( _change )
	{
		return _change < 0 ? ::MSU.Text.colorRed(::Math.abs(_change) + "%") + " less" : ::MSU.Text.colorGreen(::Math.abs(_change) + "%") + " more";
	}

	local function moreBad( _change )
	{
		return _change < 0 ? ::MSU.Text.colorGreen(::Math.abs(_change) + "%") + " less" : ::MSU.Text.colorRed(::Math.abs(_change) + "%") + " more";
	}

	local function moreLessToHigherLower( _str )
	{
		return ::String.replace(::String.replace(_str, "less", "lower"), "more", "higher")
	}

	::SettlementSituations.getStringForPair <- function( _key, _value )
	{
		local change = ::Math.round(_value * 100 - 100);
		switch (_key)
		{
			case "BeastPartsPriceMult":
				return moreGood(change) + " profit from selling beast trophies.";
			case "BuyPriceMult":
				return moreLessToHigherLower(moreBad(change)) + " item costs.";
			case "SellPriceMult":
				return moreGood(change) + " profit from selling items."
			case "FoodPriceMult":
				return moreLessToHigherLower(moreBad(change)) + " food prices.";
			case "MedicalPriceMult":
				return moreLessToHigherLower(moreBad(change)) + " medical supplies prices.";
			case "BuildingPriceMult":
				return moreLessToHigherLower(moreGood(change)) + " building material prices.";
			case "IncensePriceMult":
				return moreLessToHigherLower(moreGood(change)) + " incencse prices."
			case "RarityMult":
				return ::String.replace(moreGood(change), "less", "fewer") + " items for sale.";
			case "FoodRarityMult":
				return moreGood(change) + " food for sale.";
			case "MedicalRarityMult":
				return moreGood(change) + " mediical supplies for sale.";
			case "MineralRarityMult":
				return moreGood(change) + " minerals for sale.";
			case "BuildingRarityMult":
				return ::String.replace(moreGood(change), "less", "fewer") + " building materials for sale.";
			case "RecruitsMult":
				return ::String.replace(moreGood(change), "less", "fewer") + " recruits are available.";
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
		local name = ::String.replace(::new("scripts/skills/backgrounds/" + _backgroundString).getName().tolower(), "background: ", "");
		if (name.find("man") != null)
		{
			name = ::String.replace(name, "man", "men");
		}
		else if (name.find("hief") != null)
		{
			name = ::String.replace(name, "hief", "hieves");
		}
		else if (name.find("killer") != null)
		{
			name = ::String.replace(name, "killer", "killers");
		}
		else
		{
			name += "s";
		}
		return ::MSU.String.capitalizeFirst(name);
	}

	::SettlementSituations.HooksMod.hook("scripts/entity/world/settlements/situations/situation", function (q)
	{
		q.getTooltip = @(__original) function() {
			local ret = __original();

			// first get modifiers
			local modifiers = clone ::SettlementSituations.Modifiers;

			this.onUpdate(modifiers);
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
			this.onUpdateDraftList(draftList);
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
