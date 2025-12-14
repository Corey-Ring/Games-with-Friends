//
//  PlateData.swift
//  GamesWithFriends
//
//  Created by Claude Code
//  Complete license plate data for US states, territories, Canadian provinces/territories, and Mexican states
//

import Foundation

struct PlateData {

    // MARK: - US States (50 + DC)

    static let usStates: [LicensePlate] = [
        LicensePlate(code: "AL", name: "Alabama", region: .usState,
                     capital: "Montgomery", nickname: "The Heart of Dixie",
                     rarityTier: .uncommon,
                     funFact: "Alabama was the first state to declare Christmas a legal holiday (1836)"),

        LicensePlate(code: "AK", name: "Alaska", region: .usState,
                     capital: "Juneau", nickname: "The Last Frontier",
                     rarityTier: .rare,
                     funFact: "Alaska has more coastline than all other US states combined"),

        LicensePlate(code: "AZ", name: "Arizona", region: .usState,
                     capital: "Phoenix", nickname: "The Grand Canyon State",
                     rarityTier: .uncommon,
                     funFact: "Arizona is home to the longest-running Native American community in North America"),

        LicensePlate(code: "AR", name: "Arkansas", region: .usState,
                     capital: "Little Rock", nickname: "The Natural State",
                     rarityTier: .uncommon,
                     funFact: "Arkansas is the only US state that produces diamonds"),

        LicensePlate(code: "CA", name: "California", region: .usState,
                     capital: "Sacramento", nickname: "The Golden State",
                     rarityTier: .common,
                     funFact: "If California were a country, it would have the 5th largest economy in the world"),

        LicensePlate(code: "CO", name: "Colorado", region: .usState,
                     capital: "Denver", nickname: "The Centennial State",
                     rarityTier: .uncommon,
                     funFact: "Colorado has the highest average elevation of any US state"),

        LicensePlate(code: "CT", name: "Connecticut", region: .usState,
                     capital: "Hartford", nickname: "The Constitution State",
                     rarityTier: .uncommon,
                     funFact: "The first hamburger was served in New Haven, Connecticut in 1900"),

        LicensePlate(code: "DE", name: "Delaware", region: .usState,
                     capital: "Dover", nickname: "The First State",
                     rarityTier: .rare,
                     funFact: "Delaware was the first state to ratify the US Constitution"),

        LicensePlate(code: "FL", name: "Florida", region: .usState,
                     capital: "Tallahassee", nickname: "The Sunshine State",
                     rarityTier: .common,
                     funFact: "Florida has the longest coastline in the contiguous United States"),

        LicensePlate(code: "GA", name: "Georgia", region: .usState,
                     capital: "Atlanta", nickname: "The Peach State",
                     rarityTier: .common,
                     funFact: "Georgia is the largest state east of the Mississippi River"),

        LicensePlate(code: "HI", name: "Hawaii", region: .usState,
                     capital: "Honolulu", nickname: "The Aloha State",
                     rarityTier: .rare,
                     funFact: "Hawaii is the only US state made entirely of islands"),

        LicensePlate(code: "ID", name: "Idaho", region: .usState,
                     capital: "Boise", nickname: "The Gem State",
                     rarityTier: .uncommon,
                     funFact: "Idaho grows about 1/3 of all potatoes in the United States"),

        LicensePlate(code: "IL", name: "Illinois", region: .usState,
                     capital: "Springfield", nickname: "The Prairie State",
                     rarityTier: .common,
                     funFact: "Chicago's skyline includes the first skyscraper ever built (1885)"),

        LicensePlate(code: "IN", name: "Indiana", region: .usState,
                     capital: "Indianapolis", nickname: "The Hoosier State",
                     rarityTier: .uncommon,
                     funFact: "The Indianapolis 500 is the largest single-day sporting event in the world"),

        LicensePlate(code: "IA", name: "Iowa", region: .usState,
                     capital: "Des Moines", nickname: "The Hawkeye State",
                     rarityTier: .uncommon,
                     funFact: "Iowa produces more corn than most countries"),

        LicensePlate(code: "KS", name: "Kansas", region: .usState,
                     capital: "Topeka", nickname: "The Sunflower State",
                     rarityTier: .uncommon,
                     funFact: "Kansas is flatter than a pancake (scientifically proven)"),

        LicensePlate(code: "KY", name: "Kentucky", region: .usState,
                     capital: "Frankfort", nickname: "The Bluegrass State",
                     rarityTier: .uncommon,
                     funFact: "Kentucky has more miles of running water than any other state except Alaska"),

        LicensePlate(code: "LA", name: "Louisiana", region: .usState,
                     capital: "Baton Rouge", nickname: "The Pelican State",
                     rarityTier: .uncommon,
                     funFact: "Louisiana is the only state with parishes instead of counties"),

        LicensePlate(code: "ME", name: "Maine", region: .usState,
                     capital: "Augusta", nickname: "The Pine Tree State",
                     rarityTier: .rare,
                     funFact: "Maine is the only state whose name is one syllable"),

        LicensePlate(code: "MD", name: "Maryland", region: .usState,
                     capital: "Annapolis", nickname: "The Old Line State",
                     rarityTier: .uncommon,
                     funFact: "The US National Anthem was written in Baltimore during the War of 1812"),

        LicensePlate(code: "MA", name: "Massachusetts", region: .usState,
                     capital: "Boston", nickname: "The Bay State",
                     rarityTier: .uncommon,
                     funFact: "Basketball was invented in Springfield, Massachusetts in 1891"),

        LicensePlate(code: "MI", name: "Michigan", region: .usState,
                     capital: "Lansing", nickname: "The Great Lakes State",
                     rarityTier: .common,
                     funFact: "Michigan touches four of the five Great Lakes"),

        LicensePlate(code: "MN", name: "Minnesota", region: .usState,
                     capital: "Saint Paul", nickname: "The Land of 10,000 Lakes",
                     rarityTier: .uncommon,
                     funFact: "Minnesota actually has 11,842 lakes"),

        LicensePlate(code: "MS", name: "Mississippi", region: .usState,
                     capital: "Jackson", nickname: "The Magnolia State",
                     rarityTier: .uncommon,
                     funFact: "The world's first heart transplant was performed in Mississippi"),

        LicensePlate(code: "MO", name: "Missouri", region: .usState,
                     capital: "Jefferson City", nickname: "The Show-Me State",
                     rarityTier: .uncommon,
                     funFact: "The ice cream cone was popularized at the 1904 World's Fair in St. Louis"),

        LicensePlate(code: "MT", name: "Montana", region: .usState,
                     capital: "Helena", nickname: "The Treasure State",
                     rarityTier: .rare,
                     funFact: "Montana has the largest migratory elk herd in the nation"),

        LicensePlate(code: "NE", name: "Nebraska", region: .usState,
                     capital: "Lincoln", nickname: "The Cornhusker State",
                     rarityTier: .uncommon,
                     funFact: "Nebraska is the only state with a unicameral (single house) legislature"),

        LicensePlate(code: "NV", name: "Nevada", region: .usState,
                     capital: "Carson City", nickname: "The Silver State",
                     rarityTier: .uncommon,
                     funFact: "Nevada is the driest state in the nation"),

        LicensePlate(code: "NH", name: "New Hampshire", region: .usState,
                     capital: "Concord", nickname: "The Granite State",
                     rarityTier: .rare,
                     funFact: "New Hampshire's state motto is 'Live Free or Die'"),

        LicensePlate(code: "NJ", name: "New Jersey", region: .usState,
                     capital: "Trenton", nickname: "The Garden State",
                     rarityTier: .common,
                     funFact: "New Jersey has the most diners in the world"),

        LicensePlate(code: "NM", name: "New Mexico", region: .usState,
                     capital: "Santa Fe", nickname: "The Land of Enchantment",
                     rarityTier: .uncommon,
                     funFact: "Santa Fe is the oldest capital city in North America (founded 1610)"),

        LicensePlate(code: "NY", name: "New York", region: .usState,
                     capital: "Albany", nickname: "The Empire State",
                     rarityTier: .common,
                     funFact: "New York City was the first capital of the United States"),

        LicensePlate(code: "NC", name: "North Carolina", region: .usState,
                     capital: "Raleigh", nickname: "The Tar Heel State",
                     rarityTier: .common,
                     funFact: "North Carolina was home to the first powered airplane flight"),

        LicensePlate(code: "ND", name: "North Dakota", region: .usState,
                     capital: "Bismarck", nickname: "The Peace Garden State",
                     rarityTier: .rare,
                     funFact: "North Dakota produces more sunflowers than any other state"),

        LicensePlate(code: "OH", name: "Ohio", region: .usState,
                     capital: "Columbus", nickname: "The Buckeye State",
                     rarityTier: .common,
                     funFact: "Ohio has produced more US presidents (8) than any other state"),

        LicensePlate(code: "OK", name: "Oklahoma", region: .usState,
                     capital: "Oklahoma City", nickname: "The Sooner State",
                     rarityTier: .uncommon,
                     funFact: "Oklahoma has the largest Native American population of any state"),

        LicensePlate(code: "OR", name: "Oregon", region: .usState,
                     capital: "Salem", nickname: "The Beaver State",
                     rarityTier: .uncommon,
                     funFact: "Oregon is home to the world's smallest park (Mill Ends Park, 452 sq inches)"),

        LicensePlate(code: "PA", name: "Pennsylvania", region: .usState,
                     capital: "Harrisburg", nickname: "The Keystone State",
                     rarityTier: .common,
                     funFact: "The first computer (ENIAC) was built in Pennsylvania"),

        LicensePlate(code: "RI", name: "Rhode Island", region: .usState,
                     capital: "Providence", nickname: "The Ocean State",
                     rarityTier: .rare,
                     funFact: "Rhode Island is the smallest state but has 400 miles of coastline"),

        LicensePlate(code: "SC", name: "South Carolina", region: .usState,
                     capital: "Columbia", nickname: "The Palmetto State",
                     rarityTier: .uncommon,
                     funFact: "South Carolina was the first state to secede from the Union"),

        LicensePlate(code: "SD", name: "South Dakota", region: .usState,
                     capital: "Pierre", nickname: "The Mount Rushmore State",
                     rarityTier: .rare,
                     funFact: "Mount Rushmore took 14 years to carve"),

        LicensePlate(code: "TN", name: "Tennessee", region: .usState,
                     capital: "Nashville", nickname: "The Volunteer State",
                     rarityTier: .uncommon,
                     funFact: "Nashville is known as the country music capital of the world"),

        LicensePlate(code: "TX", name: "Texas", region: .usState,
                     capital: "Austin", nickname: "The Lone Star State",
                     rarityTier: .common,
                     funFact: "Texas is the only state that was its own independent nation"),

        LicensePlate(code: "UT", name: "Utah", region: .usState,
                     capital: "Salt Lake City", nickname: "The Beehive State",
                     rarityTier: .uncommon,
                     funFact: "Utah has the highest literacy rate of any US state"),

        LicensePlate(code: "VT", name: "Vermont", region: .usState,
                     capital: "Montpelier", nickname: "The Green Mountain State",
                     rarityTier: .ultraRare,
                     funFact: "Vermont produces more maple syrup than any other state"),

        LicensePlate(code: "VA", name: "Virginia", region: .usState,
                     capital: "Richmond", nickname: "Old Dominion",
                     rarityTier: .common,
                     funFact: "Eight US presidents were born in Virginia, more than any other state"),

        LicensePlate(code: "WA", name: "Washington", region: .usState,
                     capital: "Olympia", nickname: "The Evergreen State",
                     rarityTier: .common,
                     funFact: "Washington is the only state named after a president"),

        LicensePlate(code: "WV", name: "West Virginia", region: .usState,
                     capital: "Charleston", nickname: "The Mountain State",
                     rarityTier: .rare,
                     funFact: "West Virginia is the only state entirely within Appalachia"),

        LicensePlate(code: "WI", name: "Wisconsin", region: .usState,
                     capital: "Madison", nickname: "The Badger State",
                     rarityTier: .uncommon,
                     funFact: "Wisconsin produces more cheese than any other state"),

        LicensePlate(code: "WY", name: "Wyoming", region: .usState,
                     capital: "Cheyenne", nickname: "The Equality State",
                     rarityTier: .ultraRare,
                     funFact: "Wyoming was the first state to grant women the right to vote"),

        LicensePlate(code: "DC", name: "District of Columbia", region: .usState,
                     capital: "Washington", nickname: "The Nation's Capital",
                     rarityTier: .uncommon,
                     funFact: "DC license plates read 'Taxation Without Representation'")
    ]

    // MARK: - US Territories

    static let usTerritories: [LicensePlate] = [
        LicensePlate(code: "PR", name: "Puerto Rico", region: .usTerritory,
                     capital: "San Juan", nickname: "Island of Enchantment",
                     rarityTier: .ultraRare,
                     funFact: "Puerto Rico has been a US territory since 1898"),

        LicensePlate(code: "VI", name: "US Virgin Islands", region: .usTerritory,
                     capital: "Charlotte Amalie", nickname: "America's Paradise",
                     rarityTier: .ultraRare,
                     funFact: "The US Virgin Islands drive on the left side of the road"),

        LicensePlate(code: "GU", name: "Guam", region: .usTerritory,
                     capital: "Hagåtña", nickname: "Where America's Day Begins",
                     rarityTier: .ultraRare,
                     funFact: "Guam is where 'America's Day Begins' (first US sunrise)"),

        LicensePlate(code: "AS", name: "American Samoa", region: .usTerritory,
                     capital: "Pago Pago", nickname: "The Samoan Islands",
                     rarityTier: .ultraRare,
                     funFact: "American Samoa is the southernmost territory of the United States"),

        LicensePlate(code: "MP", name: "Northern Mariana Islands", region: .usTerritory,
                     capital: "Saipan", nickname: "The Marianas",
                     rarityTier: .ultraRare,
                     funFact: "The Mariana Trench, the deepest point on Earth, is nearby")
    ]

    // MARK: - Canadian Provinces

    static let canadianProvinces: [LicensePlate] = [
        LicensePlate(code: "ON", name: "Ontario", region: .canadianProvince,
                     capital: "Toronto", nickname: "Yours to Discover",
                     rarityTier: .common,
                     funFact: "Ontario contains the most populated city in Canada and the national capital"),

        LicensePlate(code: "QC", name: "Quebec", region: .canadianProvince,
                     capital: "Quebec City", nickname: "Je me souviens",
                     rarityTier: .common,
                     funFact: "Quebec is the largest province by area and the only one with French as sole official language"),

        LicensePlate(code: "BC", name: "British Columbia", region: .canadianProvince,
                     capital: "Victoria", nickname: "Beautiful British Columbia",
                     rarityTier: .uncommon,
                     funFact: "BC has the mildest climate in Canada"),

        LicensePlate(code: "AB", name: "Alberta", region: .canadianProvince,
                     capital: "Edmonton", nickname: "Wild Rose Country",
                     rarityTier: .uncommon,
                     funFact: "Alberta is Canada's largest producer of oil and natural gas"),

        LicensePlate(code: "MB", name: "Manitoba", region: .canadianProvince,
                     capital: "Winnipeg", nickname: "Friendly Manitoba",
                     rarityTier: .rare,
                     funFact: "Manitoba is known as the 'Gateway to the West'"),

        LicensePlate(code: "SK", name: "Saskatchewan", region: .canadianProvince,
                     capital: "Regina", nickname: "Land of Living Skies",
                     rarityTier: .rare,
                     funFact: "Saskatchewan produces more wheat than any other province"),

        LicensePlate(code: "NS", name: "Nova Scotia", region: .canadianProvince,
                     capital: "Halifax", nickname: "Canada's Ocean Playground",
                     rarityTier: .rare,
                     funFact: "Nova Scotia is almost completely surrounded by water"),

        LicensePlate(code: "NB", name: "New Brunswick", region: .canadianProvince,
                     capital: "Fredericton", nickname: "Picture Province",
                     rarityTier: .rare,
                     funFact: "New Brunswick is Canada's only officially bilingual province"),

        LicensePlate(code: "NL", name: "Newfoundland and Labrador", region: .canadianProvince,
                     capital: "St. John's", nickname: "The Rock",
                     rarityTier: .rare,
                     funFact: "St. John's is the oldest city in North America (settled 1497)"),

        LicensePlate(code: "PE", name: "Prince Edward Island", region: .canadianProvince,
                     capital: "Charlottetown", nickname: "Birthplace of Confederation",
                     rarityTier: .ultraRare,
                     funFact: "PEI is Canada's smallest province and birthplace of Confederation")
    ]

    // MARK: - Canadian Territories

    static let canadianTerritories: [LicensePlate] = [
        LicensePlate(code: "YT", name: "Yukon", region: .canadianTerritory,
                     capital: "Whitehorse", nickname: "Larger than Life",
                     rarityTier: .ultraRare,
                     funFact: "The Yukon is home to Canada's highest peak, Mount Logan"),

        LicensePlate(code: "NT", name: "Northwest Territories", region: .canadianTerritory,
                     capital: "Yellowknife", nickname: "Spectacular",
                     rarityTier: .ultraRare,
                     funFact: "NWT has polar bear-shaped license plates!"),

        LicensePlate(code: "NU", name: "Nunavut", region: .canadianTerritory,
                     capital: "Iqaluit", nickname: "Our Land",
                     rarityTier: .ultraRare,
                     funFact: "Nunavut is Canada's newest territory (1999) and largest by area")
    ]

    // MARK: - Mexican States (Border States - Most Common)

    static let mexicanStatesBorder: [LicensePlate] = [
        LicensePlate(code: "BCN", name: "Baja California", region: .mexicanState,
                     capital: "Mexicali", nickname: "The Border State",
                     rarityTier: .rare,
                     funFact: "Home to the world's busiest land border crossing (Tijuana-San Diego)"),

        LicensePlate(code: "SON", name: "Sonora", region: .mexicanState,
                     capital: "Hermosillo", nickname: "The Wheat State",
                     rarityTier: .rare,
                     funFact: "Sonora shares more border with the US than any other Mexican state"),

        LicensePlate(code: "CHH", name: "Chihuahua", region: .mexicanState,
                     capital: "Chihuahua", nickname: "The Great State",
                     rarityTier: .rare,
                     funFact: "The largest Mexican state by area; home to Copper Canyon"),

        LicensePlate(code: "COA", name: "Coahuila", region: .mexicanState,
                     capital: "Saltillo", nickname: "The Steel State",
                     rarityTier: .rare,
                     funFact: "Known as the 'Texas of Mexico' for its ranching culture"),

        LicensePlate(code: "NLE", name: "Nuevo León", region: .mexicanState,
                     capital: "Monterrey", nickname: "The Mountain State",
                     rarityTier: .rare,
                     funFact: "Mexico's wealthiest and most industrialized state"),

        LicensePlate(code: "TAM", name: "Tamaulipas", region: .mexicanState,
                     capital: "Ciudad Victoria", nickname: "The Border State",
                     rarityTier: .rare,
                     funFact: "Borders both Texas and the Gulf of Mexico")
    ]

    // MARK: - Mexican States (Interior)

    static let mexicanStatesInterior: [LicensePlate] = [
        LicensePlate(code: "AGU", name: "Aguascalientes", region: .mexicanState,
                     capital: "Aguascalientes", nickname: "The Hot Springs",
                     rarityTier: .ultraRare,
                     funFact: "One of Mexico's smallest states; known for hot springs"),

        LicensePlate(code: "BCS", name: "Baja California Sur", region: .mexicanState,
                     capital: "La Paz", nickname: "The Southern Peninsula",
                     rarityTier: .ultraRare,
                     funFact: "Home to Cabo San Lucas, famous for whale watching"),

        LicensePlate(code: "CAM", name: "Campeche", region: .mexicanState,
                     capital: "San Francisco de Campeche", nickname: "The Walled City",
                     rarityTier: .ultraRare,
                     funFact: "Has extensive Mayan ruins"),

        LicensePlate(code: "CHP", name: "Chiapas", region: .mexicanState,
                     capital: "Tuxtla Gutiérrez", nickname: "The Green State",
                     rarityTier: .ultraRare,
                     funFact: "Contains the ancient Mayan city of Palenque"),

        LicensePlate(code: "CMX", name: "Ciudad de México", region: .mexicanState,
                     capital: "Mexico City", nickname: "The Capital",
                     rarityTier: .rare,
                     funFact: "Mexico's capital; built on a former lake bed"),

        LicensePlate(code: "DUR", name: "Durango", region: .mexicanState,
                     capital: "Durango", nickname: "The Movie State",
                     rarityTier: .ultraRare,
                     funFact: "Popular filming location for Western movies"),

        LicensePlate(code: "GUA", name: "Guanajuato", region: .mexicanState,
                     capital: "Guanajuato", nickname: "The Cradle of Independence",
                     rarityTier: .ultraRare,
                     funFact: "The birthplace of Mexican independence"),

        LicensePlate(code: "GRO", name: "Guerrero", region: .mexicanState,
                     capital: "Chilpancingo", nickname: "The Beach State",
                     rarityTier: .ultraRare,
                     funFact: "Home to Acapulco"),

        LicensePlate(code: "HID", name: "Hidalgo", region: .mexicanState,
                     capital: "Pachuca", nickname: "The Silver State",
                     rarityTier: .ultraRare,
                     funFact: "Known for silver mining"),

        LicensePlate(code: "JAL", name: "Jalisco", region: .mexicanState,
                     capital: "Guadalajara", nickname: "The Mariachi State",
                     rarityTier: .rare,
                     funFact: "Birthplace of tequila and mariachi music"),

        LicensePlate(code: "MEX", name: "Estado de México", region: .mexicanState,
                     capital: "Toluca", nickname: "The Central State",
                     rarityTier: .rare,
                     funFact: "Surrounds Mexico City on three sides"),

        LicensePlate(code: "MIC", name: "Michoacán", region: .mexicanState,
                     capital: "Morelia", nickname: "The Butterfly State",
                     rarityTier: .ultraRare,
                     funFact: "Monarch butterflies migrate here every winter"),

        LicensePlate(code: "MOR", name: "Morelos", region: .mexicanState,
                     capital: "Cuernavaca", nickname: "City of Eternal Spring",
                     rarityTier: .ultraRare,
                     funFact: "Known as the 'City of Eternal Spring'"),

        LicensePlate(code: "NAY", name: "Nayarit", region: .mexicanState,
                     capital: "Tepic", nickname: "The Riviera State",
                     rarityTier: .ultraRare,
                     funFact: "Home to the Riviera Nayarit resort area"),

        LicensePlate(code: "OAX", name: "Oaxaca", region: .mexicanState,
                     capital: "Oaxaca de Juárez", nickname: "The Mezcal State",
                     rarityTier: .ultraRare,
                     funFact: "Famous for mezcal and indigenous cultures"),

        LicensePlate(code: "PUE", name: "Puebla", region: .mexicanState,
                     capital: "Puebla de Zaragoza", nickname: "The Mole State",
                     rarityTier: .ultraRare,
                     funFact: "Birthplace of mole poblano"),

        LicensePlate(code: "QUE", name: "Querétaro", region: .mexicanState,
                     capital: "Santiago de Querétaro", nickname: "The Constitution State",
                     rarityTier: .ultraRare,
                     funFact: "Site where the Mexican Constitution was signed"),

        LicensePlate(code: "ROO", name: "Quintana Roo", region: .mexicanState,
                     capital: "Chetumal", nickname: "The Caribbean State",
                     rarityTier: .rare,
                     funFact: "Home to Cancún and the Mayan Riviera"),

        LicensePlate(code: "SLP", name: "San Luis Potosí", region: .mexicanState,
                     capital: "San Luis Potosí", nickname: "The Surrealist State",
                     rarityTier: .ultraRare,
                     funFact: "Has a famous surrealist garden (Las Pozas)"),

        LicensePlate(code: "SIN", name: "Sinaloa", region: .mexicanState,
                     capital: "Culiacán", nickname: "The Breadbasket",
                     rarityTier: .ultraRare,
                     funFact: "Known for agriculture and seafood"),

        LicensePlate(code: "TAB", name: "Tabasco", region: .mexicanState,
                     capital: "Villahermosa", nickname: "The Emerald State",
                     rarityTier: .ultraRare,
                     funFact: "Not actually where Tabasco sauce is from!"),

        LicensePlate(code: "TLA", name: "Tlaxcala", region: .mexicanState,
                     capital: "Tlaxcala de Xicohténcatl", nickname: "The Smallest State",
                     rarityTier: .ultraRare,
                     funFact: "Mexico's smallest state"),

        LicensePlate(code: "VER", name: "Veracruz", region: .mexicanState,
                     capital: "Xalapa", nickname: "The First Settlement",
                     rarityTier: .ultraRare,
                     funFact: "Site of the first Spanish settlement in Mexico"),

        LicensePlate(code: "YUC", name: "Yucatán", region: .mexicanState,
                     capital: "Mérida", nickname: "The Mayan State",
                     rarityTier: .rare,
                     funFact: "Home to Chichén Itzá, one of the New Seven Wonders"),

        LicensePlate(code: "ZAC", name: "Zacatecas", region: .mexicanState,
                     capital: "Zacatecas", nickname: "The Silver State",
                     rarityTier: .ultraRare,
                     funFact: "Historic silver mining center")
    ]

    // MARK: - Aggregated Collections

    static var allMexicanStates: [LicensePlate] {
        mexicanStatesBorder + mexicanStatesInterior
    }

    static var allUSPlates: [LicensePlate] {
        usStates + usTerritories
    }

    static var allCanadianPlates: [LicensePlate] {
        canadianProvinces + canadianTerritories
    }

    static var allPlates: [LicensePlate] {
        usStates + usTerritories + canadianProvinces + canadianTerritories + allMexicanStates
    }

    static func plates(for regions: Set<PlateRegion>) -> [LicensePlate] {
        allPlates.filter { regions.contains($0.region) }
    }

    static func plate(forCode code: String) -> LicensePlate? {
        allPlates.first { $0.code == code }
    }

    // MARK: - Regional Groupings for Achievements

    static let regionalGroups: [String: [String]] = [
        "New England": ["CT", "MA", "ME", "NH", "RI", "VT"],
        "Mid-Atlantic": ["NJ", "NY", "PA"],
        "South Atlantic": ["DE", "FL", "GA", "MD", "NC", "SC", "VA", "WV", "DC"],
        "East South Central": ["AL", "KY", "MS", "TN"],
        "West South Central": ["AR", "LA", "OK", "TX"],
        "East North Central": ["IL", "IN", "MI", "OH", "WI"],
        "West North Central": ["IA", "KS", "MN", "MO", "ND", "NE", "SD"],
        "Mountain": ["AZ", "CO", "ID", "MT", "NM", "NV", "UT", "WY"],
        "Pacific": ["AK", "CA", "HI", "OR", "WA"],
        "Four Corners": ["AZ", "CO", "NM", "UT"],
        "Great Lakes": ["IL", "IN", "MI", "MN", "NY", "OH", "PA", "WI"],
        "Gulf Coast": ["AL", "FL", "LA", "MS", "TX"]
    ]
}
