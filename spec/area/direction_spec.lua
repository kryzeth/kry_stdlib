require('spec/setup/busted')()

local Direction = require('__kry_stdlib__/stdlib/area/direction')
local Orientation = require('__kry_stdlib__/stdlib/area/orientation')

describe('Direction Functions', function()
    local d = defines.direction

    describe('.next', function()
        local nd = Direction.next

        it('returns the next 4-way direction clockwise', function()
            assert.same(d.east, nd(d.north))
            assert.same(d.south, nd(d.east))
            assert.same(d.west, nd(d.south))
            assert.same(d.north, nd(d.west))
        end)

        it('returns the next 8-way direction clockwise', function()
            assert.same(d.northeast, nd(d.north, true))
            assert.same(d.east, nd(d.northeast, true))
            assert.same(d.north, nd(d.northwest, true))
        end)
    end)

    describe('.previous', function()
        local previous = Direction.previous

        it('returns the previous 4-way direction counter-clockwise', function()
            assert.same(d.west, previous(d.north))
            assert.same(d.south, previous(d.west))
            assert.same(d.east, previous(d.south))
            assert.same(d.north, previous(d.east))
        end)

        it('returns the previous 8-way direction counter-clockwise', function()
            assert.same(d.northwest, previous(d.north, true))
            assert.same(d.west, previous(d.northwest, true))
            assert.same(d.north, previous(d.northeast, true))
        end)
    end)

    describe('.to_orientation', function()
        it('converts a direction to an orientation', function()
            local dto = Direction.to_orientation
            assert.same(0, dto(d.north))
            assert.same(.25, dto(d.east))
            assert.same(.5, dto(d.south))
            assert.same(.75, dto(d.west))
            assert.same(.125, dto(d.northeast))
            assert.same(.375, dto(d.southeast))
            assert.same(.625, dto(d.southwest))
            assert.same(.875, dto(d.northwest))
        end)
    end)

    describe('.opposite', function()
        it('returns the opposite direction', function()
            local opposite = Direction.opposite
            assert.same(d.west, opposite(d.east))
            assert.same(d.southwest, opposite(d.northeast))
        end)
    end)
end)

describe('Orientation Functions', function()
    local d = defines.direction

    describe('.to_direction', function()
        it('rounds an orientation to a 4-way direction', function()
            assert.same(d.north, Orientation.to_direction(.124))
            assert.same(d.east, Orientation.to_direction(.125))
            assert.same(d.south, Orientation.to_direction(.624))
            assert.same(d.north, Orientation.to_direction(.875))
        end)

        it('rounds an orientation to an 8-way direction', function()
            assert.same(d.north, Orientation.to_direction(.06, true))
            assert.same(d.northeast, Orientation.to_direction(.0625, true))
            assert.same(d.southwest, Orientation.to_direction(.628, true))
            assert.same(d.south, Orientation.to_direction(.501, true))
        end)
    end)
end)
