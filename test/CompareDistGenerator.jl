using Distributions: Random
@testitem "Test SBCInterface for CompareDistGenerator" begin
    using Distributions, Interfaces
    # Define the CompareDistGenerator type
    D1 = CompareDistGenerator(Normal(), Normal(1.0, 1.0))
    D2 = CompareDistGenerator(Normal(), Normal(1.0, 2.0))
    args = [Arguments(model = D1, primary_sample = 0.0, n = 100, n_comparisons = 10),
        Arguments(model = D2, primary_sample = 1.0, n = 10, n_comparisons = 100)]
    @test Interfaces.test(SBCInterface, CompareDistGenerator, args)
end

@testitem "Test the run_comparison method for CompareDistGenerator" begin
    using Distributions, HypothesisTests, Interfaces, Random
    Random.seed!(1234)
    n = 100
    n_comparisons = 10_000
    # Try with same distribution
    D_same_dist = CompareDistGenerator(Normal(), Normal())
    results = run_comparison(D_same_dist, n, n_comparisons)
    @test pvalue(results.test_results) > 0.05

    # Try with different distribution
    D_diff_dist = CompareDistGenerator(Normal(), Normal(2.0, 1.0))
    results2 = run_comparison(D_diff_dist, n, n_comparisons)
    @test pvalue(results2.test_results) < 0.05
end
