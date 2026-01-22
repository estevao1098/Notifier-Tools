repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not getgenv().NotifierTools then
    getgenv().NotifierTools = {}
end
local NotifierTools = getgenv().NotifierTools

local function scanPets()
    local animals_data, animals_shared, request_data
    pcall(function() animals_data = require(ReplicatedStorage.Datas.Animals) end)
    pcall(function() animals_shared = require(ReplicatedStorage.Shared.Animals) end)
    request_data = ReplicatedStorage:FindFirstChild("Packages")
        and ReplicatedStorage.Packages:FindFirstChild("Synchronizer")
        and ReplicatedStorage.Packages.Synchronizer:FindFirstChild("RequestData")
    
    if not request_data then return {} end
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return {} end
    
    local found, seen = {}, {}
    
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then
            local ok, data = pcall(function() return request_data:InvokeServer(plot.Name) end)
            if ok and typeof(data) == "table" then
                local ownerName = (typeof(data.Owner) == "Instance" and data.Owner.Name) or (typeof(data.Owner) == "string" and data.Owner) or "Unknown"
                local animals = data.AnimalList or data.Animals or data
                
                if typeof(animals) == "table" then
                    for _, e in ipairs(animals) do
                        if typeof(e) == "table" and e.Index and e.UUID and e.Index ~= "Empty" and not seen[e.UUID] then
                            seen[e.UUID] = true
                            
                            local idx = e.Index
                            local d = animals_data and animals_data[idx]
                            local traits = typeof(e.Traits) == "table" and e.Traits or {}
                            local mut = e.Mutation
                            
                            local gen_val = 0
                            if animals_shared then
                                local ok_gen, res_gen = pcall(animals_shared.GetGeneration, animals_shared, idx, mut, traits, nil)
                                gen_val = (ok_gen and res_gen) or 0
                            end
                            
                            table.insert(found, {
                                name = d and d.DisplayName or idx,
                                rarity = d and d.Rarity or "Unknown",
                                mutation = typeof(mut) == "table" and (mut.Name or "Normal") or (mut or "Normal"),
                                traits = traits,
                                owner = ownerName,
                                uuid = e.UUID,
                                value = gen_val
                            })
                        end
                    end
                end
            end
        end
    end
    
    return found
end

local function filterPets(pets)
    if not pets or #pets == 0 then return {} end
    
    local MIN_GEN_MILLIONS = NotifierTools:GetConfig("MIN_GEN") or 0
    local MIN_GEN = MIN_GEN_MILLIONS * 1000000
    local RARITY = NotifierTools:GetConfig("RARITY") or {}
    local FILTERS = NotifierTools.FILTERS or {}
    
    local rarity_set = {}
    for _, r in ipairs(RARITY) do
        rarity_set[r:lower()] = true
    end
    
    local filtered = {}
    
    for _, pet in ipairs(pets) do
        local pet_name_lower = pet.name and pet.name:lower() or ""
        local pet_mutation = pet.mutation or "Normal"
        local pet_value = pet.value or 0
        local pet_rarity = pet.rarity and pet.rarity:lower() or ""
        
        local should_include = false
        local should_exclude = false
        
        for _, filter in ipairs(FILTERS) do
            if filter.name:lower() == pet_name_lower then
                if filter.type == "EXCLUDE" then
                    should_exclude = true
                    break
                elseif filter.type == "INCLUDE" then
                    if filter.mutations then
                        for _, mut in ipairs(filter.mutations) do
                            if pet_mutation:lower() == mut:lower() then
                                should_include = true
                                break
                            end
                        end
                    end
                    
                    if not should_include and filter.generation then
                        local gen_value_millions = filter.generation[1] or 0
                        local gen_value = gen_value_millions * 1000000
                        local operator = filter.generation[2] or "more_than"
                        
                        if operator == "more_than" and pet_value > gen_value then
                            should_include = true
                        elseif operator == "less_than" and pet_value < gen_value then
                            should_include = true
                        elseif operator == "equal" and pet_value == gen_value then
                            should_include = true
                        elseif operator == "more_equal" and pet_value >= gen_value then
                            should_include = true
                        elseif operator == "less_equal" and pet_value <= gen_value then
                            should_include = true
                        end
                    end
                end
            end
        end
        
        if should_exclude then continue end
        
        if should_include then
            table.insert(filtered, pet)
            continue
        end
        
        local meets_min_gen = pet_value >= MIN_GEN
        local meets_rarity = #RARITY == 0 or rarity_set[pet_rarity]
        
        if meets_min_gen and meets_rarity then
            table.insert(filtered, pet)
        end
    end
    
    return filtered
end

NotifierTools.SetLoaded = function(self, value)
    NotifierTools.isLoaded = value
end

NotifierTools.SetConfig = function(self, name, value)
    if not NotifierTools.CONFIG then
        NotifierTools.CONFIG = {}
    end
    NotifierTools.CONFIG[name] = value
end

NotifierTools.GetConfig = function(self, name)
    if not NotifierTools.CONFIG then
        NotifierTools.CONFIG = {}
    end
    return NotifierTools.CONFIG[name]
end

NotifierTools.SetFilter = function(self, filterType, petName, generation, mutations)
    if not NotifierTools.FILTERS then
        NotifierTools.FILTERS = {}
    end
    
    table.insert(NotifierTools.FILTERS, {
        type = filterType,
        name = petName,
        generation = generation,
        mutations = mutations
    })
end

NotifierTools.ScanPets = function(self)
    return scanPets()
end

return NotifierTools
