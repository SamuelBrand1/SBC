@testitem "Test uniformity test" begin
    using Distributions, Random
    using HypothesisTests: pvalue
    Random.seed!(1234)

    n = 100 # number of samples pre comparison
    n_comparisons = 1000 # number of trial comparisons

    # This is the target discrete uniform distribution
    good_counts = rand(0:n, n_comparisons)
    # This is not a uniform distribution
    bad_counts = rand(Poisson(n / 2), n_comparisons)

    # Test the good distribution
    good_t = chisqtest(good_counts)
    @test pvalue(good_t) > 0.05
    bad_t = chisqtest(bad_counts)
    @test pvalue(bad_t) < 0.05
end
