-- Require the event module
local Event = require('__kry_stdlib__/stdlib/event/event')

-- Register our hotkeys

-- Pressing the first hotkey will run both functions
Event.register('stdlib-test-hotkey-1', function()
    game.print('Test key 1')
end)

Event.register('stdlib-test-hotkey-1', function()
    game.print('Test key 1 #2')
end)

-- Pressing the second hotkey will run only this function
Event.register('stdlib-test-hotkey-2', function()
    game.print('Test key 2')
end)

-- Any time the player builds something, run this function
Event.register(defines.events.on_built_entity, function(event)
    local entity = event.entity

    if entity and entity.valid then
        game.print(entity.name .. ' was built')
    end
end)
