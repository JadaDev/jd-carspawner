Config = {}

-- Target system configuration: 'qb-target' or 'ox_target'
Config.TargetSystem = 'qb-target'  -- Default to qb-target

Config.TIMER_DEBUG = true -- testing for 10 second - 1 minute - 5 minute - 10 minute.

-- ===============================================
-- JOB PLATE CONFIGURATION
-- ===============================================
-- This table defines the license plate prefixes for different jobs
-- If the plate length exceeds the maximum (8 characters for most games),
-- numbers will be added to make it unique
Config.JobPlates = {
    ["police"] = "POLICE",
    ["ambulance"] = "EMS",
    -- Add more jobs here as needed
}

Config.JobSpawners = {
    ["police"] = { --
        -- This is the police job spawner configuration
        -- It includes the ped model, coordinates, spawn locations, and vehicles available for each grade
        type = "ped",
        ped_model = `s_f_y_cop_01`,
        ped_coords = {
            {
                coords = vec4(442.7396, -1013.6259, 27.6133, 181.9880), -- spawn point for the city police ped
                spawn_locations = {
                    vec4(452.68, -1018.51, 28.45, 91.12), -- spawn points for police vehicles
                    vec4(452.69, -1024.67, 28.52, 91.26) -- more spawn points for police vehicles
                }
            },
            {
                coords = vec4(-459.9629, 6016.2515, 30.4901, 44.5699), -- spawn point for north police station ped
                spawn_locations = {
                    vec4(-482.0124, 6024.3223, 31.3406, 222.3143),
                    vec4(-478.8094, 6027.4258, 31.3406, 222.7369),
                    vec4(-475.1814, 6031.1128, 31.3406, 226.0488),
                    vec4(-471.6501, 6034.5757, 31.3405, 226.3271),
                    vec4(-468.3557, 6038.0010, 31.3405, 222.4684)
                }
            },
            {
                coords = vec4(1852.3652, 2581.9414, 44.6721, 273.1265), -- spawn point for the jail police ped
                spawn_locations = {
                    vec4(1855.3083, 2578.7173, 45.6721, 270.1532),
                    vec4(1855.4283, 2575.0203, 45.6721, 270.7195),
                    vec4(1855.6729, 2571.3181, 45.6721, 271.9933)
                }
            }
        },
        ped_heading = 179.62,
        vehicles = {
            [0] = { -- grade rank 0 = Recruit
                {name = "Police Cruiser", model = "police", image = "https://docs.fivem.net/vehicles/police.webp", extras = {}}, -- recruit vehicles
                {name = "Police Motorcycle", model = "policeb", image = "https://docs.fivem.net/vehicles/policeb.webp", extras = {}}
            },
            [1] = { -- grade rank 1 = Officer
                {name = "Stanier LE Cruiser", model = "police5", image = "https://docs.fivem.net/vehicles/police5.webp", extras = {}}, -- officer vehicles
                {name = "Park Ranger", model = "pranger", image = "https://docs.fivem.net/vehicles/pranger.webp", extras = {}},
                {name = "Police Bus", model = "pbus", image = "https://docs.fivem.net/vehicles/pbus.webp", extras = {}}
            },
            [2] = { -- grade rank 2 = Sergeant
                {name = "Police Cruiser 2", model = "police2", image = "https://docs.fivem.net/vehicles/police2.webp", extras = {}}, -- sergeant vehicles
                {name = "Advanced Police Cruiser", model = "police3", image = "https://docs.fivem.net/vehicles/police3.webp", extras = {}}
            },
            [3] = { -- grade rank 3 = Detective
                {name = "F.B.I Vehicle", model = "fbi", image = "https://docs.fivem.net/vehicles/fbi.webp", extras = {}} -- detective vehicles
            },
            [4] = { -- grade rank 4 = Commander
                {name = "Unmarked Cruiser", model = "police4", image = "https://docs.fivem.net/vehicles/police4.webp", extras = {}}, -- commander vehicles
                {name = "Sheriff SUV", model = "sheriff2", image = "https://docs.fivem.net/vehicles/sheriff2.webp", extras = {}},
                {name = "Police Riot", model = "riot", image = "https://docs.fivem.net/vehicles/riot.webp", extras = {}},
                {name = "Sheriff Cruiser", model = "sheriff", image = "https://docs.fivem.net/vehicles/sheriff.webp", extras = {}}
            },
        }
    },
    ["ambulance"] = { --
        -- This is the ambulance job spawner configuration
        -- It includes the ped model, coordinates, spawn locations, and vehicles available for each grade
        -- The ambulance job has different grades with specific vehicles available for each grade
        -- The ped model is set to a doctor model, and the coordinates are set for various ambulance stations
        -- The spawn locations are defined for each ambulance station, allowing players to spawn vehicles at those locations
        -- The vehicles available for each grade are defined in a table, with each vehicle having a name, model, and image URL
        type = "ped",
        ped_model = `s_m_m_doctor_01`,
        ped_coords = {
            {
                coords = vec4(295.1361, -600.6005, 42.3034, 162.8286),
                spawn_locations = {
                    vec4(294.1553, -604.5334, 43.3170, 69.8393),
                    vec4(291.3707, -611.9408, 43.3895, 66.8373)
                }
            }
        },
        ped_heading = 179.62,
        vehicles = {
            [0] = {
                {name = "Emergency Ambulance", model = "ambulance", image = "https://docs.fivem.net/vehicles/ambulance.webp", extras = {}}
            },
            [1] = {
                {name = "Emergency Ambulance", model = "lguard", image = "https://docs.fivem.net/vehicles/lguard.webp", extras = {}}
            }
        }
    }
}

-- ===============================================
-- RENTAL TIME CONFIGURATION
-- ===============================================
-- This new system provides a cleaner way to manage rental times
-- You can easily add/modify rental durations and their fees
-- Debug times are short durations for testing purposes
-- Production times are real-world rental durations
Config.RentalTimes = {
    -- Debug times (short durations for testing)
    debug_times = {
        [0] = { label = "10 Seconds (Debug)", fee = 1, duration_seconds = 10 },
        [1] = { label = "1 Minute (Debug)", fee = 2, duration_seconds = 60 },
        [2] = { label = "5 Minutes (Debug)", fee = 5, duration_seconds = 300 },
        [3] = { label = "10 Minutes (Debug)", fee = 10, duration_seconds = 600 }
    },
    -- Production times (actual rental durations)
    production_times = {
        [4] = { label = "1 Hour", fee = 100, duration_seconds = 3600 },
        [5] = { label = "2 Hours", fee = 190, duration_seconds = 7200 },
        [6] = { label = "3 Hours", fee = 260, duration_seconds = 10800 },
        [7] = { label = "4 Hours", fee = 320, duration_seconds = 14400 },
    }
}

Config.RentalSpawner = {
    type = "ped",
    ped_model = `a_m_y_business_03`,
    ped_coords = {
        {
            coords = vec4(296.9903, -1097.6622, 28.4010, 90.2361),
            spawn_locations = {
                vec4(306.5956, -1103.3065, 29.3869, 119.9967),
                vec4(306.3456, -1098.7588, 29.3963, 118.4245),
                vec4(306.4938, -1094.3430, 29.3922, 119.1316),
                vec4(306.2440, -1090.0374, 29.3987, 117.2126),
                vec4(306.3041, -1085.5701, 29.3973, 114.7513),
                vec4(306.3824, -1081.1294, 29.3966, 113.8759)
            }
        },
        {
            coords = vec4(-685.8924, -1103.6777, 13.5253, 215.7679),
            spawn_locations = {
                vec4(-697.1778, -1120.6873, 14.5251, 33.0995),
                vec4(-694.5698, -1118.9075, 14.5251, 32.5086),
                vec4(-703.4374, -1109.3573, 14.5253, 214.5217),
                vec4(-700.0349, -1107.1342, 14.5253, 213.2854),
                vec4(-696.5562, -1104.9294, 14.5253, 212.0304),
                vec4(-693.1758, -1102.7212, 14.5253, 214.4522)
            }
        },
        {
            coords = vec4(256.9670, -633.7394, 39.8277, 246.4930),
            spawn_locations = {
                vec4(250.1948, -641.6946, 39.9401, 338.6116),
                vec4(246.0242, -651.6160, 39.1506, 335.7545)
            }
        },
        {
            coords = vec4(-619.8452, 20.4972, 40.2536, 358.5268),
            spawn_locations = {
                vec4(-623.7638, 2.2494, 41.4475, 97.6685),
                vec4(-602.7056, 5.2896, 42.8482, 96.4428)
            }
        },
        {
            coords = vec4(-1275.2434, -421.4739, 33.3026, 122.9764),
            spawn_locations = {
                vec4(-1275.8799, -414.4024, 34.5892, 212.6697),
                vec4(-1281.9113, -404.3628, 35.5481, 212.3174)
            }
        },
        {
            coords = vec4(1852.6002, 2590.5503, 44.6721, 273.6723),
            spawn_locations = {
                vec4(1869.1689, 2595.3250, 45.6721, 89.5126),
                vec4(1869.0255, 2591.9546, 45.6720, 87.2543),
                vec4(1868.8809, 2588.3970, 45.6720, 88.5168)
            }
        }
    },
    ped_heading = 179.62,
    vehicles = {
        { name = "Blista Compact", model = "blista", image = "https://docs.fivem.net/vehicles/blista.webp", base_price = 500, extras = {} },
        { name = "Asbo Compact", model = "asbo", image = "https://docs.fivem.net/vehicles/asbo.webp", base_price = 300, extras = {} },
        { name = "Club Compact", model = "club", image = "https://docs.fivem.net/vehicles/club.webp", base_price = 550, extras = {} },
        { name = "Washington Sedan", model = "washington", image = "https://docs.fivem.net/vehicles/washington.webp", base_price = 800, extras = {} },
        { name = "Carbonizzare Sports", model = "carbonizzare", image = "https://docs.fivem.net/vehicles/carbonizzare.webp", base_price = 2500, extras = {} },
        { name = "Faggio Scooter", model = "faggio", image = "https://docs.fivem.net/vehicles/faggio.webp", base_price = 100, extras = {1,2,3,4,5,6,7,8,9,10,11,12} },
        { name = "Faggio (Alt)", model = "faggio2", image = "https://docs.fivem.net/vehicles/faggio2.webp", base_price = 150, extras = {} },
        { name = "Nemesis Bike", model = "nemesis", image = "https://docs.fivem.net/vehicles/nemesis.webp", base_price = 2500, extras = {} }
    },
    payment_options = {"cash", "bank"}
}

-- ===============================================
-- HELPER FUNCTIONS FOR RENTAL TIMES
-- ===============================================
function GetRentalTimeOptions()
    local timeOptions = {}
    local rentalFees = {}
    local rentalDurations = {}
    
    if Config.TIMER_DEBUG then
        -- Include debug times
        for key, data in pairs(Config.RentalTimes.debug_times) do
            timeOptions[key] = data.label
            rentalFees[key] = data.fee
            rentalDurations[key] = data.duration_seconds
        end
    end
    
    -- Always include production times
    for key, data in pairs(Config.RentalTimes.production_times) do
        timeOptions[key] = data.label
        rentalFees[key] = data.fee
        rentalDurations[key] = data.duration_seconds
    end
    
    return timeOptions, rentalFees, rentalDurations
end

-- ===============================================
-- HELPER FUNCTIONS FOR JOB PLATES
-- ===============================================
function GenerateJobPlate(jobName)
    local platePrefix = Config.JobPlates[jobName] or "JOB"
    local maxPlateLength = 8 -- Standard GTA V plate length
    
    -- If the prefix is already at max length, use it as is
    if string.len(platePrefix) >= maxPlateLength then
        return string.sub(platePrefix, 1, maxPlateLength)
    end
    
    -- Calculate how many digits we can add
    local remainingLength = maxPlateLength - string.len(platePrefix)
    local maxNumber = math.pow(10, remainingLength) - 1
    
    -- Generate a random number to fill the remaining space
    local randomNumber = math.random(1, maxNumber)
    local numberString = string.format("%0" .. remainingLength .. "d", randomNumber)
    
    return platePrefix .. numberString
end

Config.RentalGarage = "rental_garage"
Config.Locale = "en"

Config.GradeNames = { -- This table defines the names for different job grades
    -- Each job has its own set of grades with corresponding names
    -- The police job has grades from Recruit to Commander, each with a specific name
    -- The ambulance job has grades from Trainee to Chief Doctor, each with a specific name
    -- These names are used to display the job grade in the user interface
    -- The police job has different grades with specific names for each grade
    -- The ambulance job has different grades with specific names for each grade
    -- The names are defined in a table format, where each grade is associated with a specific name
    -- This allows for easy customization and addition of new job grades in the future
    -- The police job has different grades with specific names for each grade
    -- The ambulance job has different grades with specific names for each grade
    police = {
        [0] = "Recruit",
        [1] = "Officer",
        [2] = "Sergeant", 
        [3] = "Detective",
        [4] = "Commander"
    },
    ambulance = {
        [0] = "Trainee",
        [1] = "Paramedic",
        [2] = "Senior Paramedic", 
        [3] = "Doctor",
        [4] = "Chief Doctor"
    }
}


Config.Colors = {
    { name = "Black", value = 0, hex = "#000000" },
    { name = "White", value = 111, hex = "#ffffff" },
    { name = "Red", value = 39, hex = "#ff0000" },
    { name = "Dark Red", value = 40, hex = "#8b0000" },
    { name = "Orange", value = 41, hex = "#ff8c00" },
    { name = "Bright Orange", value = 138, hex = "#ffa500" },
    { name = "Yellow", value = 42, hex = "#ffff00" },
    { name = "Race Yellow", value = 89, hex = "#ffd700" },
    { name = "Lime Green", value = 55, hex = "#32cd32" },
    { name = "Green", value = 139, hex = "#008000" },
    { name = "Blue", value = 83, hex = "#1e90ff" },
    { name = "Midnight Blue", value = 84, hex = "#00008b" },
    { name = "Bright Purple", value = 145, hex = "#9370db" },
    { name = "Schafter Purple", value = 148, hex = "#800080" },
    { name = "Midnight Purple", value = 149, hex = "#4b0082" },
    { name = "Hot Pink", value = 135, hex = "#ff69b4" },
    { name = "Salmon Pink", value = 136, hex = "#ffa07a" },
    { name = "Wine Red", value = 143, hex = "#800000" },
    { name = "Silver", value = 4, hex = "#c0c0c0" },
    { name = "Bronze", value = 90, hex = "#cd7f32" }
}

Config.UI = {
    theme = "darkblue",
    showPlayerMoney = true -- This option determines whether to show the player's money in the UI
}

-- ===============================================
-- SIREN/ALARM OPTIONS
-- ===============================================
Config.SirenOptions = {
    enableSiren = true,           -- Enable/disable siren/alarm feature
    repeatAlarm = true,           -- Should alarm repeat (loop) until stopped?
    alarmDuration = 15,           -- DON'T CHANGE: Duration (seconds) for alarm to sound before stopping
    alarmRepeatInterval = 10      -- Interval (seconds) to retrigger alarm if repeating
}

-- ===============================================
-- JOB VEHICLE SIREN/ALARM OPTIONS
-- ===============================================
Config.JobSirenOptions = {
    enableSiren = true,           -- Enable/disable siren/alarm feature for job vehicles
    repeatAlarm = true,           -- Should alarm repeat (loop) until stopped?
    alarmDuration = 15,           -- Duration (seconds) for alarm to sound before stopping
    alarmRepeatInterval = 10      -- Interval (seconds) to retrigger alarm if repeating
}

-- ===============================================
-- RENTAL MANAGEMENT CONFIGURATION
-- ===============================================
Config.RentalManagement = {
    enableCheckRentalsCommand = true, -- Enable/disable the /jdvehicle command
    checkRentalsCommand = "jdvehicle", -- The command name for checking rentals
    enableRentalMenu = true, -- Enable/disable the rental management menu
    enableGPSWaypoints = true, -- Enable/disable GPS waypoint functionality
    waypointBlipSprite = 1, -- Blip sprite for rental vehicle waypoints
    waypointBlipColor = 5, -- Blip color for rental vehicle waypoints
    waypointBlipScale = 0.8, -- Blip scale for rental vehicle waypoints
    menuKey = 166, -- F5 key to open rental management menu (set to 0 to disable)
    gpsUpdateInterval = 3000 -- Interval in milliseconds for GPS updates (default: 30 seconds)
}

-- ===============================================
-- JOB VEHICLE MANAGEMENT CONFIGURATION
-- ===============================================
Config.JobVehicleManagement = {
    enableJobVehicleTracking = true, -- Enable/disable job vehicle tracking in rental management
    showJobVehiclesInMenu = true, -- Show job vehicles in the rental management menu
    maxJobVehiclesPerPlayer = 1, -- Maximum number of job vehicles a player can have spawned at once
    jobWaypointBlipSprite = 56, -- Blip sprite for job vehicle waypoints (different from rental)
    jobWaypointBlipColor = 3, -- Blip color for job vehicle waypoints
    jobWaypointBlipScale = 0.8, -- Blip scale for job vehicle waypoints
    gpsUpdateInterval = 3000 -- Interval in milliseconds for GPS updates (default: 30 seconds)
}
-- ===============================================
-- END OF CONFIGURATION
-- ===============================================
