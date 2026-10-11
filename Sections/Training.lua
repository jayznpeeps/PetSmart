--------------------------------------------------------------------------
-- PetSmart: Sections/Training.lua
-- Section: General Training Info.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local abilitiesPanel = ns.abilitiesPanel
local trainingInfoExpanded = ns.trainingInfoExpanded

ns.Pages.training = function(ctx)
    abilitiesPanel.title:SetText("General Training Info")
    if not ns.GENERAL_TRAINING_INFO or #ns.GENERAL_TRAINING_INFO == 0 then
        ctx.AddLine("In Development", 0.8, 0.8, 0.8)
    else
        for i, section in ipairs(ns.GENERAL_TRAINING_INFO) do
            local expanded = trainingInfoExpanded[i]
            ctx.AddLine(section.title, 1, 0.82, 0, function()
                trainingInfoExpanded[i] = not trainingInfoExpanded[i]
                ns.RefreshAbilitiesPanel()
            end)
            if expanded then
                for _, line in ipairs(section.lines) do
                    ctx.AddLine(line, 0.9, 1, 0.9)
                end
                ctx.AddLine(" ", 1, 1, 1)
            end
        end
    end
end
