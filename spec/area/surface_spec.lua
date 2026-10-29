require('spec/setup/busted')()

local Surface = require('__kry_stdlib__/stdlib/area/surface')

describe('Surface Spec', function()
    describe('Surface lookups', function()
        before_each(function()
            _G.game = {
                surfaces = {
                    nauvis = { name = 'nauvis', object_name = 'LuaSurface', valid = true }
                }
            }
        end)

        it('should work with no parameters', function()
            assert.same({ }, Surface.lookup())
        end)

        it('should work with string parameters', function()
            assert.same({ game.surfaces['nauvis'] }, Surface.lookup('nauvis'))

            assert.same({ }, Surface.lookup('foo'))
        end)

        it('should work with object parameters', function()
            assert.same({ game.surfaces['nauvis'] }, Surface.lookup(game.surfaces['nauvis']))
        end)

        it('should work with table parameters', function()
            assert.same({ }, Surface.lookup({}))
            assert.same({ game.surfaces['nauvis'] }, Surface.lookup({ 'nauvis' }))
            assert.same({ game.surfaces['nauvis'] }, Surface.lookup({ 'nauvis', 'foo', 'bar' }))
            assert.same({ game.surfaces['nauvis'] }, Surface.lookup({ game.surfaces['nauvis'] }))
        end)
    end)
end)
