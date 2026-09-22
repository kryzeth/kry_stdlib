local Event = require('__kry_stdlib__/stdlib/event/event')

--- Makes monolithic Factorio GUI events more manageable.
---@class StdLib.Event.Gui : StdLib.Core
---@usage local Gui = require('__kry_stdlib__/stdlib/event/gui')
local Gui = {
   __class = 'Gui',
   __index = require('__kry_stdlib__/stdlib/core')
}
setmetatable(Gui, Gui)

local function register_filtered_gui_event(event_id, gui_element_pattern, handler)
    Event.register(event_id, function(event)
        local match = Event.Filters.gui(event, gui_element_pattern)
        if match then
            return handler(event, match)
        end
    end)

    return Gui
end

--- Registers a function for a given gui element name or pattern when the element is clicked.
---@param gui_element_pattern string the name or string regular expression to match the gui element
---@param handler function the function to call when gui element is clicked
---@return StdLib.Event.Gui
function Gui.on_click(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_click, gui_element_pattern, handler)
end

--- Registers a function for a given GUI element name or pattern when the element checked state changes.
---@param gui_element_pattern string the name or string regular expression to match the GUI element
---@param handler function the function to call when GUI element checked state changes
---@return StdLib.Event.Gui
function Gui.on_checked_state_changed(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_checked_state_changed, gui_element_pattern, handler)
end

--- Registers a function for a given GUI element name or pattern when the element text changes.
---@param gui_element_pattern string the name or string regular expression to match the GUI element
---@param handler function the function to call when GUI element text changes
---@return StdLib.Event.Gui
function Gui.on_text_changed(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_text_changed, gui_element_pattern, handler)
end

--- Registers a function for a given GUI element name or pattern when the element selection changes.
---@param gui_element_pattern string the name or string regular expression to match the GUI element
---@param handler function the function to call when GUI element selection changes
---@return StdLib.Event.Gui
function Gui.on_elem_changed(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_elem_changed, gui_element_pattern, handler)
end

--- Registers a function for a given GUI element name or pattern when the element state changes (drop down).
---@param gui_element_pattern string the name or string regular expression to match the GUI element
---@param handler function the function to call when GUI element state changes
---@return StdLib.Event.Gui
function Gui.on_selection_state_changed(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_selection_state_changed, gui_element_pattern, handler)
end

--- Registers a function for a given GUI element name or pattern when the element value changes (slider).
---@param gui_element_pattern string the name or string regular expression to match the GUI element
---@param handler function the function to call when GUI element state changes
---@return StdLib.Event.Gui
function Gui.on_value_changed(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_value_changed, gui_element_pattern, handler)
end

--- Registers a function for a given GUI element name or pattern when the element is confirmed.
---@param gui_element_pattern string the name or string regular expression to match the GUI element
---@param handler function the function to call when GUI element state changes
---@return StdLib.Event.Gui
function Gui.on_confirmed(gui_element_pattern, handler)
    return register_filtered_gui_event(defines.events.on_gui_confirmed, gui_element_pattern, handler)
end

return Gui
