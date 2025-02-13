
@testitem "Aqua.jl" begin
    using Aqua
    Aqua.test_all(SBC, ambiguities = false, persistent_tasks = false)
    Aqua.test_ambiguities(SBC)
end
