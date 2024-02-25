using DrWatson, Test
@quickactivate "vkr"

include(srcdir("vkr.jl"))

@testset "mutation tests" begin
    expected = [1, 0, 0, 1, 1]
    actual = VKR.multipoint_core_operation(
        [1, 1, 1, 1, 1],
        [0, 0, 0, 0, 0],
        [1, 3]
    )

    @test expected == actual
end
