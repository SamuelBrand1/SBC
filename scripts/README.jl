# # SBC
# [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
# ![GitHub CI](https://github.com/SamuelBrand1/SBC/actions/workflows/test.yaml/badge.svg)

# ## Overview
# This package provides tools for performing simulation-based calibration (SBC) on generative models.
# Out-of-the-box, it provides tools for calibrating generative/simulated univariate distributions to a target distribution.
# The key assumption is that the target distribution is _also_ a generative model, i.e. we can only sample from it.
# `SBC` is designed to be extensible to other types of generative models via `SBCInterface`.
# See [Interfaces.jl](https://github.com/rafaqz/Interfaces.jl) for more information on how interfaces work.
#
# ## Installation
# The package is not yet registered, so you can install it via the following command:
#
# ```julia
# ] add https://github.com/SamuelBrand1/SBC
# ```
#
# ## Core theoretical result
# The core theoretical result is [Theorem 1](https://arxiv.org/abs/1804.06788). Theorem 1 states that given a generative model
# for a joint distribution $\pi(\theta, y)$, with $\tilde{\theta} \sim \pi(\theta)$, $\tilde{y} \sim \pi(y|\tilde{\theta})$, and
# $\{\theta_1,\dots,\theta_L\} \sim \pi(\theta|y)$, then the rank statistics of the $\theta_i$ are _discrete uniformly distributed_
# on $\{0,\dots,L\}$. The rank statistics are defined as any map $f$ of a (possibly multivariate) sample to a scalar value.
# ```math
#   r(\{f(\theta_1),\dots,f(\theta_L)\}, f(\tilde{\theta})) = \sum_{i=1}^L \mathbb{1}_{f(\theta_i) \leq f(\theta)}.
# ```
# Note that this includes the case where `y` is _not observed_, and this is the base case for SBC.
# ## SBC interface
# Using `SBCInterface` the simulation-based calibration (SBC) concept can be extended to other types of random sampling.
# The most important use case is Bayesian (prior) SBC, where the target distribution is a prior distribution of each
# parameter in a Bayesian model, which we can sample from. The generative model is the likelihood function, which is used to generate data.
# Extensions have to comply with the `SBCInterface` provided by `SBC.jl` using `Interfaces.jl`.
# At the moment this is very lightweight:
# Required methods:
# - `run_primary_generative` this samples from the primary distribution and returns a tuple of the sample from the target distribution and the auxiliary variable.
# this is equivalent to sampling $(\tilde{\theta}, \tilde{y}) \sim \pi(\theta, y)$.
# - `run_secondary_generative` this samples from the secondary distribution `n` times possibly conditional the auxiliary variable.
# this is equivalent to sampling $\{\theta_i\}_{i =1,\dots,n} \sim \pi(\theta|\tilde{y})$.
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

# ## Example: using SBC with a Turing model
# We use the `Turing` extension to `SBC` which has an interface for running SBC on a `Turing` model.
# This is a Bayesian model, where the target distribution is the prior distribution of the parameters.

using Turing

J = 8
sigma = [15.0, 10.0, 16.0, 11.0, 9.0, 11.0, 10.0, 18.0]
@model function eight_schools(J, sigma)
    mu ~ Normal(0, 5)
    tau ~ truncated(Normal(0, 5), lower = 0)
    theta ~ filldist(Normal(mu, tau), J)
    y ~ MvNormal(theta, sigma)
end

model = eight_schools(J, sigma)
condition_names = (:y,)
sampler = NUTS()

eight_school_generator = sbc_generator(model, condition_names, sampler)
n = 10
n_comparisons = 100
results = run_comparison(eight_school_generator, n, n_comparisons)
results.test_results.mu
