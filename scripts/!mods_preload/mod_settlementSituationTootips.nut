::mods_hookBaseClass("entity/world/settlements/situations/situation", function (o) {
	// copy modifiers from individual event
	local modifiersFunction = o.onUpdate;
	local recruitsFunction = null;
	if ("onUpdateDraftList" in o){
		recruitsFunction = o.onUpdateDraftList;
	}
	
	
	while(!("getTooltip" in o)) o = o[o.SuperName];
	
	local _situation_modifiers = {
		"PriceMult" : 1.0, 			//buying & selling prices
		"BuyPriceMult" : 1.0,		//buying price
		"SellPriceMult" : 1.0,		//selling price
		"FoodPriceMult" : 1.0,		//food price
		"MedicalPriceMult" : 1.0,	//medical supplies price
		"BuildingPriceMult" : 1.0,	//wood price
		"IncensePriceMult" : 1.0,	//incense price
		"RarityMult" : 1.0,			//amount sale items
		"FoodRarityMult" : 1.0,		//amount of food for sale
		"MedicalRarityMult" : 1.0,	//amount of medical supplies for sale
		"MineralRarityMult" : 1.0,	//amount of minerals for sale
		"BuildingRarityMult" : 1.0,	//amount of wood for sale
		"RecruitsMult" : 1.0		//amount of recruits available
	};

	// calculate the effects of the event's modifiers
	local getModifiers = function ( _mods )
	{
		modifiersFunction( _mods );

		local changedMultipliers = []

		foreach (key, value in _mods) {
			if (value != 1.0) {
				if (key == "PriceMult"){
					changedMultipliers.append( { name = "BuyPriceMult", amount = value } );
					changedMultipliers.append( { name = "SellPriceMult", amount = value } );
				}
				else {
					changedMultipliers.append( { name = key, amount = value } );
				}
			}
		}

		return changedMultipliers
	};

	local generateColoredString = function ( nameAmountPair ) {

		//convert float into integer %
		local difference = nameAmountPair.amount > 1 ? (nameAmountPair.amount - 1) * 100 : (nameAmountPair.amount - 1) * -100
		local diffPct = difference.tostring() + "% "
		local lessOrMore = nameAmountPair.amount > 1 ? "more" : "less"
		local badColor = this.Const.UI.Color.NegativeValue + "]"
		local goodColor = this.Const.UI.Color.PositiveValue + "]"
		local color = lessOrMore == "less" ? badColor : goodColor

		//this could use cleanup :/
		switch(nameAmountPair.name) {
			case "BuyPriceMult":
				color = lessOrMore == "more" ? badColor : goodColor
				return "Selling items for [color=" + color + diffPct + "[/color]" + lessOrMore
			case "SellPriceMult":
				return "Buying items for [color=" + color + diffPct + "[/color]" + lessOrMore
			case "FoodPriceMult":
				color = lessOrMore == "more" ? badColor : goodColor
				return "Buying and selling food for [color=" + color + diffPct + "[/color]" + lessOrMore
			case "MedicalPriceMult":
				color = lessOrMore == "more" ? badColor : goodColor
				return "Selling medical supplies for [color=" + color + diffPct + "[/color]" + lessOrMore
			case "BuildingPriceMult":
				return "Buying and selling building materials for [color=" + color + diffPct + "[/color]" + lessOrMore
			case "IncensePriceMult":
				return "Buying and selling incense for [color=" + color + diffPct + "[/color]" + lessOrMore
			case "RarityMult":
				if (lessOrMore == "less") { lessOrMore = "fewer"; }
				return "[color=" + color + diffPct + "[/color]" + lessOrMore + " items for sale"
			case "FoodRarityMult":
				return "[color=" + color + diffPct + "[/color]" + lessOrMore + " food for sale"
			case "MedicalRarityMult":
				return "[color=" + color + diffPct + "[/color]" + lessOrMore + " medical supplies for sale"
			case "MineralRarityMult":
				return "[color=" + color + diffPct + "[/color]" + lessOrMore + " minerals for sale"
			case "BuildingRarityMult":
				return "[color=" + color + diffPct + "[/color]" + lessOrMore + " building materials for sale"
			case "RecruitsMult":
				if (lessOrMore == "less") { lessOrMore = "fewer"; }
				return "[color=" + color + diffPct + "[/color]" + lessOrMore + " recruits are available"
		}

		// failover, should ever be needed
		return nameAmountPair.name + " " + difference + "%."
	}

	local getIconPath = function ( name ) {
		switch(name) {
			case "PriceMult":
				return "ui/icons/PriceMult.png"
			case "BuyPriceMult":
				return "ui/icons/BuyPriceMult.png"
			case "SellPriceMult":
				return "ui/icons/SellPriceMult.png"
			case "FoodPriceMult":
				return "ui/icons/FoodPriceMult.png"
			case "MedicalPriceMult":
				return "ui/icons/MedicalPriceMult.png"
			case "BuildingPriceMult":
				return "ui/icons/BuildingPriceMult.png"
			case "IncensePriceMult":
				return "ui/icons/IncensePriceMult.png"
			case "RarityMult":
				return "ui/icons/RarityMult.png"
			case "FoodRarityMult":
				return "ui/icons/FoodRarityMult.png"
			case "MedicalRarityMult":
				return "ui/icons/MedicalRarityMult.png"
			case "MineralRarityMult":
				return "ui/icons/MineralRarityMult.png"
			case "BuildingRarityMult":
				return "ui/icons/BuildingRarityMult.png"
			case "RecruitsMult":
				return "ui/icons/RecruitsMult.png"
		}
		return "ui/icons/RarityMult.png"
	}

	local capitalizeFirst = function ( stringIn ) {
		return stringIn.slice(0, 1).toupper() + stringIn.slice(1);
	}

	local pluralizeBackground = function ( background ) {

		if (background.find("man") == background.len() - 3) {
			return background.slice(0, background.len() - 3) + "men"
		}
		if (background.find("hief") == background.len() - 4) {
			return background.slice(0, background.len() - 4) + "hieves"
		}
		if (background == "Killer On The Run") {
			return "Killers On The Run"
		}
		return background + "s"
	}

	local createAddedRecruitsSentence = function ( parsedBackgroundNames ) {

		if (parsedBackgroundNames.len() == 1) {
			return pluralizeBackground(parsedBackgroundNames[0]) + " are more likely to be available for hire"
		}
		else if (parsedBackgroundNames.len() == 2) {
			return pluralizeBackground(parsedBackgroundNames[0]) + " and " + pluralizeBackground(parsedBackgroundNames[1]) + " are more likely to be available for hire"
		}
		else {
			local sentence = "";
			local numNames = parsedBackgroundNames.len()
			for (local i = 0; i < numNames - 2; i++) {
				sentence += pluralizeBackground(parsedBackgroundNames[i]) + ", "
			}
			return sentence + pluralizeBackground(parsedBackgroundNames[numNames - 2]) + " and "+ pluralizeBackground(parsedBackgroundNames[numNames - 1]) + " are more likely to be available for hire"
		}
		return ""
	}

	//returns array of parsed, singluar background names
	local formatBackgroundNames = function ( uniqueBackgrounds ) {
		// FOR TESTING, REMOVE LATER
		// uniqueBackgrounds.append("killer_on_the_run_background")
		// uniqueBackgrounds.append("adventurous_noble_background")
		// uniqueBackgrounds.append("fisherman_background")
		// uniqueBackgrounds.append("thief_background")
		// uniqueBackgrounds.append("hedge_knight_background")

		local parsedBackgroundNames = []

		//remove "_background" and fix capitalization
		foreach (background in uniqueBackgrounds) {
			local backgroundNameArray = split(background, "_");
			local backgroundNameString = "";
			for (local j = 0; j < backgroundNameArray.len() - 1; j++) {
				backgroundNameString += capitalizeFirst( strip(backgroundNameArray[j]) )
				if (backgroundNameArray.len() > 2 && j < backgroundNameArray.len() - 2) {
					backgroundNameString += " ";
				}
			}
			parsedBackgroundNames.append( backgroundNameString )
		}
		return parsedBackgroundNames
	}

	local parseBackgrounds = function () {	
		local backgrounds = []
		local uniqueBackgrounds = []
		
		recruitsFunction( backgrounds );

		//TODO: slave revolt, no slaves 
		if (backgrounds.len() == 0 ) {
			
		} 
		else {
			//parse backgrounds added by event
			foreach (background in backgrounds) {
				if (uniqueBackgrounds.find(background) == null) {
					uniqueBackgrounds.append(background)
				}
			}
		}
		return uniqueBackgrounds
	}

	// this function creates the tooltip info objects that are inserted into the main tooltip
	local addSituationInfo = function () {

		local situationInfo = []
		local mods = clone( _situation_modifiers )
		local changedMultipliers = getModifiers( mods )

		foreach (pair in changedMultipliers) {
			local detailText = generateColoredString( pair )
			local iconPath = getIconPath ( pair.name )
			situationInfo.append({
				id = 10,
				type = "text",
				icon = iconPath,
				text = detailText
			})
		}
		return situationInfo
	}

	// "main" function that generates tooltip
	o.getTooltip = function()
	{
		local tooltip_contents = [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			}
		];

		tooltip_contents.extend(addSituationInfo())

		if (recruitsFunction) {
			local names = formatBackgroundNames(parseBackgrounds())
			if (names.len() > 0 ) {
				tooltip_contents.append({
					id = 10,
					type = "text",
					icon = "ui/icons/RecruitsMult.png",
					text = createAddedRecruitsSentence( names )
				})
			}
		}

		return tooltip_contents
	}
});
