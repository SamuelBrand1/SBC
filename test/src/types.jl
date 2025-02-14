# Test if abstract types are exported.
@testitem "types exist" begin
    ty1 = AbstractGenerator
    ty2 = AbstractTrial
    ty3 = AbstractDualGenerator
    @test ty1 == AbstractGenerator
    @test ty2 == AbstractTrial
    @test ty3 == AbstractDualGenerator
end
