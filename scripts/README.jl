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

# ## Example: using SBC with `Turing.jl` for the eight schools model
# We use the `Turing` extension to `SBC` which has an interface for running SBC on a `Turing` model.
# This is a Bayesian model, where the target distribution is the prior distribution of the parameters.
#
# The eight schools example is a classic example of using partial pooling to share inferential strength between groups, cf Gelman *et al* [@gelman2013]:
#
# > *A study was performed for the Educational Testing Service to analyze the effects of special coaching programs for SAT-V (Scholastic Aptitude Test-Verbal) in each of eight high schools. The outcome variable in each study was the score on a special administration of the SAT-V, a standardized multiple choice test administered by the Educational Testing Service and used to help colleges make admissions decisions; the scores can vary between 200 and 800, with mean about 500 and standard deviation about 100. The SAT examinations are designed to be resistant to short-term efforts directed specifically toward improving performance on the test; instead they are designed to reflect knowledge acquired and abilities developed over many years of education. Nevertheless, each of the eight schools in this study considered its short-term coaching program to be very successful at increasing SAT scores. Also, there was no prior reason to believe that any of the eight programs was more effective than any other or that some were more similar in effect to each other than to any other.*
#
# The statistical model for the SAT scores in each of the $J=8$ schools $y_j$ is:
# ```math
# \begin{aligned}
# \mu & \sim \mathcal{N}(0, 5), \\
# \tau & \sim \text{HalfCauchy}(5),\\
# \theta_j & \sim \mathcal{N}(\mu, \tau),~ j = 1,\dots,J, \\
# y_j & \sim \mathcal{N}(\theta_j,\sigma_j),~ j = 1,\dots,J.
# \end{aligned}
# ```
#
# Where the the SAT standard deviations per high school $\sigma_j$ are treated as known along with the scores.
#
# Gelman *et al* _Bayesian Data Analysis_ (2013) use the eight schools example to illustrate partial pooling, and to demonstrate the importance of choosing the variance priors carefully.

using Turing

J = 8
sigma = [15.0, 10.0, 16.0, 11.0, 9.0, 11.0, 10.0, 18.0]
@model function eight_schools(J, sigma, tau_prior)
    mu ~ Normal(0, 5)
    tau ~ tau_prior
    theta ~ filldist(Normal(mu, tau), J)
    y ~ MvNormal(theta, sigma)
end

model_bad_prior = eight_schools(J, sigma, truncated(Cauchy(0, 5), 0, Inf))

# Where we have chosen the prior for $\tau$ to be a half-Cauchy distribution with scale 5.0.
# as per [here](https://github.com/pyro-ppl/numpyro#a-simple-example---8-schools).
# We also have to define the condition names, which are the names of the random variables that
# will be treated as observed data. In this case, we only have one, the `y` variable.

condition_names = (:y,)

# We also specify the sampler to use, in this case, we will use the No-U-Turn Sampler (NUTS)
# with Turing defaults.

sampler = NUTS()

# We can now generate a `SBCGenerator` object for the eight schools model with the bad prior.

eight_school_generator = sbc_generator(model_bad_prior, condition_names, sampler)
n = 100
n_comparisons = 100
results = run_comparison(eight_school_generator, n, n_comparisons)
results.test_results.tau

# We can see that the SBC has identified a problem with the model. The Bayesian inference highly likely to be mis-estimating the inter-school variation parameter $\tau$.
# This is probably due to sensitivity of the model to the prior on $\tau$ (cf Gelman *et al*).
#
# Lets use a more informative prior from [this implementation](https://www.tensorflow.org/probability/examples/Eight_Schools).

model_better_prior = eight_schools(J, sigma, LogNormal(5, 1))
eight_school_generator = sbc_generator(model_better_prior, condition_names, sampler)
n = 100
n_comparisons = 100
results = run_comparison(eight_school_generator, n, n_comparisons)
results.test_results.tau

# We see that the SBC has not identified a problem with recovering the inter-group variation parameter in the model.
