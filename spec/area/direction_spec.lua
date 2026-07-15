require('spec/setup/busted')()

local Direction = require('__kry_stdlib__/stdlib/area/direction')

describe('Direction Functions', function()
    local d = defines.direction

    describe('.next_direction', function()
        local nd = Direction.next_direction

        it('returns the next 4-way direction clockwise', function()
            assert.same(d.east, nd(d.north))
            assert.same(d.south, nd(d.east))
            assert.same(d.west, nd(d.south))
            assert.same(d.north, nd(d.west))
        end)

        it('returns the next 8-way direction clockwise', function()
            assert.same(d.northeast, nd(d.north, false, true))
            assert.same(d.east, nd(d.northeast, false, true))
            assert.same(d.north, nd(d.northwest, false, true))
        end)

        it('returns the next 4-way direction counter-clockwise', function()
            assert.same(d.west, nd(d.north, true))
            assert.same(d.south, nd(d.west, true))
            assert.same(d.east, nd(d.south, true))
            assert.same(d.north, nd(d.east, true))
        end)

        it('returns the next 8-way direction counter-clockwise', function()
            assert.same(d.northwest, nd(d.north, true, true))
            assert.same(d.west, nd(d.northwest, true, true))
            assert.same(d.north, nd(d.northeast, true, true))
        end)
    end)

    describe('.direction_to_orientation', function()
        it('converts a direction to an orientation', function()
            local dto = Direction.direction_to_orientation
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

    describe('.opposite_direction', function()
        it('returns the opposite direction', function()
            local opposite = Direction.opposite_direction
            assert.same(d.west, opposite(d.east))
            assert.same(d.southwest, opposite(d.northeast))
        end)
    end)

    describe('.orientation_to_4way', function()
        it('rounds an orientation to a 4-way direction', function()
            assert.same(d.north, Direction.orientation_to_4way(.124))
            assert.same(d.east, Direction.orientation_to_4way(.125))
            assert.same(d.south, Direction.orientation_to_4way(.624))
            assert.same(d.north, Direction.orientation_to_4way(.875))
        end)
    end)

    describe('.orientation_to_8way', function()
        it('rounds an orientation to an 8-way direction', function()
            assert.same(d.north, Direction.orientation_to_8way(.06))
            assert.same(d.northeast, Direction.orientation_to_8way(.0625))
            assert.same(d.southwest, Direction.orientation_to_8way(.628))
            assert.same(d.south, Direction.orientation_to_8way(.501))
        end)
    end)
end)
