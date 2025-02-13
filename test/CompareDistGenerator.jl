@testitem "Test SBCInterface for CompareDistGenerator" begin
    using Distributions, Interfaces
    # Define the CompareDistGenerator type
    D1 = CompareDistGenerator(Normal(), Normal(1.0, 1.0))
    D2 = CompareDistGenerator(Normal(), Normal(1.0, 2.0))
    args = [Arguments(model = D1, primary_sample = 0.0, n = 100),
        Arguments(model = D2, primary_sample = 1.0, n = 10)]
    @test Interfaces.test(SBCInterface, CompareDistGenerator, args)
end
