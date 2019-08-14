local orig_print = print
if Mods.mrudat_TestingMods then
  print = orig_print
else
  print = empty_func
end

local CurrentModId = rawget(_G, 'CurrentModId') or rawget(_G, 'CurrentModId_X')
local CurrentModDef = rawget(_G, 'CurrentModDef') or rawget(_G, 'CurrentModDef_X')
if not CurrentModId then

  -- copied shamelessly from Expanded Cheat Menu
  local Mods, rawset = Mods, rawset
  for id, mod in pairs(Mods) do
    rawset(mod.env, "CurrentModId_X", id)
    rawset(mod.env, "CurrentModDef_X", mod)
  end

  CurrentModId = CurrentModId_X
  CurrentModDef = CurrentModDef_X
end

orig_print("loading", CurrentModId, "-", CurrentModDef.title)

function find_method(class_name, method_name, seen)
  seen = seen or {}
  local class = _G[class_name]
  local method = class[method_name]
  if method then return method end
  local find_method = mrudat_AllowBuildingInDome.find_method
  for _, parent_class_name in ipairs(class.__parents or empty_table) do
    if not seen[parent_class_name] then
      method = find_method(parent_class_name, method_name, seen)
      if method then return method end
      seen[parent_class_name] = true
    end
  end
end

function wrap_method(class_name, method_name, wrapper)
  local orig_method = _G[class_name][method_name]
  if not orig_method then
    if RecursiveCallOrder[method_name] ~= nil or AutoResolveMethods[method_name] then
      orig_method = empty_func
    else
      orig_method = find_method(class_name, method_name)
    end
  end
  if not orig_method then orig_print("Error: couldn't find method to wrap for", class_name, method_name, "refusing to proceed") return end
  _G[class_name][method_name] = function(self, ...)
    return wrapper(self, orig_method, ...)
  end
end

function InjectParent(class, parent_class)
  if IsKindOf(class, parent_class) then return end
  local parents = class.__parents
  parents[#parents + 1] = parent_class
end

InjectParent(Farm, 'AirProducer')

Farm.air_production = 0

wrap_method('Farm', 'CreateLifeSupportElements', function(self,orig_func)
  orig_func(self)
  AirProducer.CreateLifeSupportElements(self)
end)

function Farm:ApplyOxygenProductionMod(crop)
	if not self.parent_dome then return end
	local cropdef = crop and CropPresets[crop]
	if cropdef then
		local amount = MulDivRound(cropdef.OxygenProduction, self.oxygen_production_efficiency, 100)
		self:SetModifier("air_production", self.farm_id, amount, 0, T{663, "<amount> from <crop_name>", crop_name = cropdef.DisplayName})
	else
		self:SetModifier("air_production", self.farm_id, 0, 0)
	end
  if self.air then
    self.air:SetProduction(self.air_production or 0)
  end
end

function Farm:NeedsAir()
  return self.air.consumption and LifeSupportConsumer:NeedsAir()
end

orig_print("loaded", CurrentModId, "-", CurrentModDef.title)
