# # SBC
# [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
# ![GitHub CI](https://github.com/SamuelBrand1/SBC/actions/workflows/test.yaml/badge.svg)

# This package provides tools for performing simulation-based calibration (SBC) on generative models.
# Out-of-the-box, it provides tools for comparing generative univariate distributions, but
# it can be extended to other types of random sampling, namely full simulation based calibration of `Turing.jl` models.

# Extensions have to comply with the `SBCInterface` provided by `SBC.jl` using `Interfaces.jl`.
# At the moment this is very lightweight:
# Required methods:
# - `run_primary_generative` this samples from the primary distribution and returns a tuple of the sample from the target distribution and the auxiliary variable.
# - `run_secondary_generative` this samples from the secondary distribution `n` times possibly conditional the auxiliary variable.
# - `run_comparison`: This runs both the methods above sequentially `n_comparison` times, and gathers the rank statistics. By default these get
# passed to the `uniformity_test` function to return a Chi-squared test result.

# ## Example: Comparing two distributions via sampling
# In this example, we will compare two distributions only by sampling from them. That is we check the
# calibration of one sampling distribution against another "true" or target distribution, which we
# also can only sample from.
#
# Towards this we define a form of Normal distribution that has no distributional knowledge,
# but can be sampled from. We make this a subtype of the `Distributions.Sampleable` type and provide
# the necessary methods. Obviously, for Normal distributions we _do_ have distributional knowledge,
# but this is for illustrative purposes since often we may not have this knowledge.

using SBC, Distributions, HypothesisTests, Random
Random.seed!(1234)

struct SampleNormal{T} <: Sampleable{Univariate, Continuous} where {T <: Real}
    μ::T
    σ::T
end

function Base.rand(rng::AbstractRNG, s::SampleNormal)
    return s.μ + s.σ * randn()
end

function Random.rand!(rng::AbstractRNG, s::SampleNormal, x::Vector)
    ϵ = randn(rng, length(x))
    @. x = s.μ + s.σ * ϵ
    return x
end

# Now we can define a `CompareDistGenerator` that will compare two `SampleNormal` distributions.
# We can use the `sbc_generator` function to generate a `CompareDistGenerator` object.
# As a first pass lets just compare two normal distributions with the same mean and variance.

compare_dists = sbc_generator(SampleNormal(0.0, 1.0), SampleNormal(0.0, 1.0))
n = 100
n_comparisons = 10_000
results = run_comparison(compare_dists, n, n_comparisons)
results.test_results

# We see that there is no evidence that the two distributions are different.
# By contrast is we test whether the sampling distribution is different from a Cauchy distribution
# with scale 1.0.

compare_different_dists = sbc_generator(SampleNormal(0.0, 1.0), Cauchy(1.0))
results_diff = run_comparison(compare_different_dists, n, n_comparisons)
results_diff.test_results

# We do indeed see strong evidence that the two distributions are different.

# ## Example: Comparing t
