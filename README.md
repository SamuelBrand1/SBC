# SBC
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
![GitHub CI](https://github.com/SamuelBrand1/SBC/actions/workflows/test.yaml/badge.svg)

This package provides tools for performing simulation-based calibration (SBC) on generative models.
Out-of-the-box, it provides tools for calibrating generative/simulated univariate distributions to a target distribution.
The key assumption is that the target distribution is _also_ a generative model, i.e. we can only sample from it.
`SBC` is designed to be extensible to other types of generative models via `SBCInterface`.
See [Interfaces.jl](https://github.com/rafaqz/Interfaces.jl) for more information on how interfaces work.

## Installation
The package is not yet registered, so you can install it via the following command:
```julia
] add https://github.com/SamuelBrand1/SBC
```

````julia
# Core theoretical result
````

The core theoretical result is [Theorem 1](https://arxiv.org/abs/1804.06788), given a generative model
for a joint distribution $\pi(\theta, y)$, with $\tilde{\theta} \sim \pi(\theta)$, $\tilde{y} \sim \pi(y|\tilde{\theta})$, and
$\{\theta_1,\dots,\theta_L\} \sim \pi(\theta|y)$, then the rank statistics of the $\theta_i$ are discrete uniformly distributed
on $\{0,\dots,L\}$. The rank statistics are defined as any map $f$ of a (possibly multivariate) sample to a scalar value.
```math
  r(\{f(\theta_1),\dots,f(\theta_L)\}, f(\tilde{\theta})) = \sum_{i=1}^L \mathbb{1}_{f(\theta_i) \leq f(\theta)}.
```

Using `SBCInterface` the simulation-based calibration (SBC) concept can be extended to other types of random sampling.
The most important use case is Bayesian (prior) SBC, where the target distribution is a prior distribution of each
parameter in a Bayesian model, which we can sample from. The generative model is the likelihood function, which is used to generate data.

Extensions have to comply with the `SBCInterface` provided by `SBC.jl` using `Interfaces.jl`.
At the moment this is very lightweight:
Required methods:
- `run_primary_generative` this samples from the primary distribution and returns a tuple of the sample from the target distribution and the auxiliary variable.
- `run_secondary_generative` this samples from the secondary distribution `n` times possibly conditional the auxiliary variable.
- `run_comparison`: This runs both the methods above sequentially `n_comparison` times, and gathers the rank statistics. By default these get
passed to the `uniformity_test` function to return a Chi-squared test result.

## Example: Comparing two distributions via sampling
In this example, we will compare two distributions only by sampling from them. That is we check the
calibration of one sampling distribution against another "true" or target distribution, which we
also can only sample from.

Towards this we define a form of Normal distribution that has no distributional knowledge,
but can be sampled from. We make this a subtype of the `Distributions.Sampleable` type and provide
the necessary methods. Obviously, for Normal distributions we _do_ have distributional knowledge,
but this is for illustrative purposes since often we may not have this knowledge.

````julia
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
````

Now we can define a `CompareDistGenerator` that will compare two `SampleNormal` distributions.
We can use the `sbc_generator` function to generate a `CompareDistGenerator` object.
As a first pass lets just compare two normal distributions with the same mean and variance.

````julia
compare_dists = sbc_generator(SampleNormal(0.0, 1.0), SampleNormal(0.0, 1.0))
n = 100
n_comparisons = 10_000
results = run_comparison(compare_dists, n, n_comparisons)
results.test_results
````

````
Pearson's Chi-square Test
-------------------------
Population details:
    parameter of interest:   Multinomial Probabilities
    value under h_0:         [0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099]
    point estimate:          [0.0091, 0.0092, 0.0093, 0.0088, 0.0089, 0.0103, 0.0097, 0.0107, 0.0118, 0.0104, 0.0095, 0.0083, 0.0103, 0.0103, 0.0109, 0.0092, 0.0112, 0.009, 0.0085, 0.0102, 0.0094, 0.0097, 0.009, 0.0096, 0.0097, 0.0086, 0.0119, 0.0084, 0.0108, 0.0094, 0.0103, 0.011, 0.0104, 0.009, 0.0094, 0.0095, 0.0118, 0.0104, 0.0099, 0.0106, 0.0086, 0.0105, 0.0092, 0.0108, 0.0091, 0.0085, 0.0099, 0.0099, 0.0103, 0.0099, 0.011, 0.0085, 0.0094, 0.0087, 0.0092, 0.0086, 0.0113, 0.0103, 0.0094, 0.0096, 0.0081, 0.0099, 0.0111, 0.0113, 0.0096, 0.0088, 0.0086, 0.01, 0.0094, 0.0101, 0.011, 0.0104, 0.0114, 0.0087, 0.0096, 0.0113, 0.0106, 0.0098, 0.0103, 0.0088, 0.0098, 0.0117, 0.0104, 0.0116, 0.0116, 0.008, 0.0101, 0.0095, 0.012, 0.0105, 0.011, 0.0113, 0.0091, 0.0106, 0.0111, 0.0087, 0.01, 0.0085, 0.0102, 0.0096, 0.0088]
    95% confidence interval: [(0.0057, 0.01262), (0.0058, 0.01272), (0.0059, 0.01282), (0.0054, 0.01232), (0.0055, 0.01242), (0.0069, 0.01382), (0.0063, 0.01322), (0.0073, 0.01422), (0.0084, 0.01532), (0.007, 0.01392), (0.0061, 0.01302), (0.0049, 0.01182), (0.0069, 0.01382), (0.0069, 0.01382), (0.0075, 0.01442), (0.0058, 0.01272), (0.0078, 0.01472), (0.0056, 0.01252), (0.0051, 0.01202), (0.0068, 0.01372), (0.006, 0.01292), (0.0063, 0.01322), (0.0056, 0.01252), (0.0062, 0.01312), (0.0063, 0.01322), (0.0052, 0.01212), (0.0085, 0.01542), (0.005, 0.01192), (0.0074, 0.01432), (0.006, 0.01292), (0.0069, 0.01382), (0.0076, 0.01452), (0.007, 0.01392), (0.0056, 0.01252), (0.006, 0.01292), (0.0061, 0.01302), (0.0084, 0.01532), (0.007, 0.01392), (0.0065, 0.01342), (0.0072, 0.01412), (0.0052, 0.01212), (0.0071, 0.01402), (0.0058, 0.01272), (0.0074, 0.01432), (0.0057, 0.01262), (0.0051, 0.01202), (0.0065, 0.01342), (0.0065, 0.01342), (0.0069, 0.01382), (0.0065, 0.01342), (0.0076, 0.01452), (0.0051, 0.01202), (0.006, 0.01292), (0.0053, 0.01222), (0.0058, 0.01272), (0.0052, 0.01212), (0.0079, 0.01482), (0.0069, 0.01382), (0.006, 0.01292), (0.0062, 0.01312), (0.0047, 0.01162), (0.0065, 0.01342), (0.0077, 0.01462), (0.0079, 0.01482), (0.0062, 0.01312), (0.0054, 0.01232), (0.0052, 0.01212), (0.0066, 0.01352), (0.006, 0.01292), (0.0067, 0.01362), (0.0076, 0.01452), (0.007, 0.01392), (0.008, 0.01492), (0.0053, 0.01222), (0.0062, 0.01312), (0.0079, 0.01482), (0.0072, 0.01412), (0.0064, 0.01332), (0.0069, 0.01382), (0.0054, 0.01232), (0.0064, 0.01332), (0.0083, 0.01522), (0.007, 0.01392), (0.0082, 0.01512), (0.0082, 0.01512), (0.0046, 0.01152), (0.0067, 0.01362), (0.0061, 0.01302), (0.0086, 0.01552), (0.0071, 0.01402), (0.0076, 0.01452), (0.0079, 0.01482), (0.0057, 0.01262), (0.0072, 0.01412), (0.0077, 0.01462), (0.0053, 0.01222), (0.0066, 0.01352), (0.0051, 0.01202), (0.0068, 0.01372), (0.0062, 0.01312), (0.0054, 0.01232)]

Test summary:
    outcome with 95% confidence: fail to reject h_0
    one-sided p-value:           0.5126

Details:
    Sample size:        10000
    statistic:          98.88899999999991
    degrees of freedom: 100
    residuals:          [-0.804985, -0.704486, -0.603988, -1.10648, -1.00598, 0.401, -0.201993, 0.802995, 1.90848, 0.501499, -0.40299, -1.60898, 0.401, 0.401, 1.00399, -0.704486, 1.30549, -0.905484, -1.40798, 0.300501, -0.503489, -0.201993, -0.905484, -0.302491, -0.201993, -1.30748, 2.00898, -1.50848, 0.903494, -0.503489, 0.401, 1.10449, 0.501499, -0.905484, -0.503489, -0.40299, 1.90848, 0.501499, -0.000995037, 0.702496, -1.30748, 0.601998, -0.704486, 0.903494, -0.804985, -1.40798, -0.000995037, -0.000995037, 0.401, -0.000995037, 1.10449, -1.40798, -0.503489, -1.20698, -0.704486, -1.30748, 1.40599, 0.401, -0.503489, -0.302491, -1.80997, -0.000995037, 1.20499, 1.40599, -0.302491, -1.10648, -1.30748, 0.0995037, -0.503489, 0.200002, 1.10449, 0.501499, 1.50649, -1.20698, -0.302491, 1.40599, 0.702496, -0.101494, 0.401, -1.10648, -0.101494, 1.80798, 0.501499, 1.70748, 1.70748, -1.91047, 0.200002, -0.40299, 2.10948, 0.601998, 1.10449, 1.40599, -0.804985, 0.702496, 1.20499, -1.20698, 0.0995037, -1.40798, 0.300501, -0.302491, -1.10648]
    std. residuals:     [-0.809, -0.708, -0.607, -1.112, -1.011, 0.403, -0.203, 0.807, 1.918, 0.504, -0.405, -1.617, 0.403, 0.403, 1.009, -0.708, 1.312, -0.91, -1.415, 0.302, -0.506, -0.203, -0.91, -0.304, -0.203, -1.314, 2.019, -1.516, 0.908, -0.506, 0.403, 1.11, 0.504, -0.91, -0.506, -0.405, 1.918, 0.504, -0.001, 0.706, -1.314, 0.605, -0.708, 0.908, -0.809, -1.415, -0.001, -0.001, 0.403, -0.001, 1.11, -1.415, -0.506, -1.213, -0.708, -1.314, 1.413, 0.403, -0.506, -0.304, -1.819, -0.001, 1.211, 1.413, -0.304, -1.112, -1.314, 0.1, -0.506, 0.201, 1.11, 0.504, 1.514, -1.213, -0.304, 1.413, 0.706, -0.102, 0.403, -1.112, -0.102, 1.817, 0.504, 1.716, 1.716, -1.92, 0.201, -0.405, 2.12, 0.605, 1.11, 1.413, -0.809, 0.706, 1.211, -1.213, 0.1, -1.415, 0.302, -0.304, -1.112]

````

We see that there is no evidence that the two distributions are different.
By contrast is we test whether the sampling distribution is different from a Cauchy distribution
with scale 1.0.

````julia
compare_different_dists = sbc_generator(SampleNormal(0.0, 1.0), Cauchy(1.0))
results_diff = run_comparison(compare_different_dists, n, n_comparisons)
results_diff.test_results
````

````
Pearson's Chi-square Test
-------------------------
Population details:
    parameter of interest:   Multinomial Probabilities
    value under h_0:         [0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099]
    point estimate:          [0.0, 0.0, 0.0004, 0.0002, 0.0013, 0.0027, 0.0051, 0.0073, 0.0116, 0.0161, 0.0202, 0.0238, 0.0274, 0.0309, 0.0296, 0.0326, 0.0334, 0.0334, 0.0371, 0.0357, 0.0286, 0.0265, 0.0302, 0.0256, 0.0252, 0.0221, 0.0224, 0.0235, 0.0222, 0.0196, 0.0189, 0.0159, 0.0179, 0.0164, 0.0174, 0.0146, 0.0117, 0.0129, 0.0133, 0.0124, 0.0122, 0.0103, 0.0103, 0.0093, 0.0096, 0.0113, 0.0093, 0.0078, 0.0078, 0.0069, 0.0084, 0.0072, 0.0049, 0.0067, 0.006, 0.0056, 0.0065, 0.0049, 0.0061, 0.0056, 0.0054, 0.006, 0.0042, 0.0048, 0.005, 0.0061, 0.0045, 0.0056, 0.0045, 0.0048, 0.0049, 0.0033, 0.0034, 0.005, 0.0035, 0.0028, 0.0026, 0.0029, 0.0027, 0.0031, 0.0025, 0.0018, 0.0012, 0.0017, 0.0008, 0.0014, 0.0007, 0.0005, 0.0006, 0.0003, 0.0002, 0.0, 0.0001, 0.0002, 0.0, 0.0, 0.0001, 0.0, 0.0, 0.0, 0.0]
    95% confidence interval: [(0.0, 0.005022), (0.0, 0.005022), (0.0, 0.005422), (0.0, 0.005222), (0.0, 0.006322), (0.0, 0.007722), (0.0001, 0.01012), (0.0023, 0.01232), (0.0066, 0.01662), (0.0111, 0.02112), (0.0152, 0.02522), (0.0188, 0.02882), (0.0224, 0.03242), (0.0259, 0.03592), (0.0246, 0.03462), (0.0276, 0.03762), (0.0284, 0.03842), (0.0284, 0.03842), (0.0321, 0.04212), (0.0307, 0.04072), (0.0236, 0.03362), (0.0215, 0.03152), (0.0252, 0.03522), (0.0206, 0.03062), (0.0202, 0.03022), (0.0171, 0.02712), (0.0174, 0.02742), (0.0185, 0.02852), (0.0172, 0.02722), (0.0146, 0.02462), (0.0139, 0.02392), (0.0109, 0.02092), (0.0129, 0.02292), (0.0114, 0.02142), (0.0124, 0.02242), (0.0096, 0.01962), (0.0067, 0.01672), (0.0079, 0.01792), (0.0083, 0.01832), (0.0074, 0.01742), (0.0072, 0.01722), (0.0053, 0.01532), (0.0053, 0.01532), (0.0043, 0.01432), (0.0046, 0.01462), (0.0063, 0.01632), (0.0043, 0.01432), (0.0028, 0.01282), (0.0028, 0.01282), (0.0019, 0.01192), (0.0034, 0.01342), (0.0022, 0.01222), (0.0, 0.009922), (0.0017, 0.01172), (0.001, 0.01102), (0.0006, 0.01062), (0.0015, 0.01152), (0.0, 0.009922), (0.0011, 0.01112), (0.0006, 0.01062), (0.0004, 0.01042), (0.001, 0.01102), (0.0, 0.009222), (0.0, 0.009822), (0.0, 0.01002), (0.0011, 0.01112), (0.0, 0.009522), (0.0006, 0.01062), (0.0, 0.009522), (0.0, 0.009822), (0.0, 0.009922), (0.0, 0.008322), (0.0, 0.008422), (0.0, 0.01002), (0.0, 0.008522), (0.0, 0.007822), (0.0, 0.007622), (0.0, 0.007922), (0.0, 0.007722), (0.0, 0.008122), (0.0, 0.007522), (0.0, 0.006822), (0.0, 0.006222), (0.0, 0.006722), (0.0, 0.005822), (0.0, 0.006422), (0.0, 0.005722), (0.0, 0.005522), (0.0, 0.005622), (0.0, 0.005322), (0.0, 0.005222), (0.0, 0.005022), (0.0, 0.005122), (0.0, 0.005222), (0.0, 0.005022), (0.0, 0.005022), (0.0, 0.005122), (0.0, 0.005022), (0.0, 0.005022), (0.0, 0.005022), (0.0, 0.005022)]

Test summary:
    outcome with 95% confidence: reject h_0
    one-sided p-value:           <1e-99

Details:
    Sample size:        10000
    statistic:          10397.434799999999
    degrees of freedom: 100
    residuals:          [-9.95037, -9.95037, -9.54838, -9.74937, -8.64389, -7.23691, -4.82494, -2.61396, 1.70748, 6.22993, 10.3504, 13.9683, 17.5863, 21.1037, 19.7973, 22.8122, 23.6162, 23.6162, 27.3347, 25.9277, 18.7923, 16.6818, 20.4003, 15.7773, 15.3753, 12.2599, 12.5613, 13.6668, 12.3604, 9.74738, 9.04389, 6.02893, 8.03891, 6.53142, 7.53641, 4.72245, 1.80798, 3.01397, 3.41596, 2.51147, 2.31048, 0.401, 0.401, -0.603988, -0.302491, 1.40599, -0.603988, -2.11147, -2.11147, -3.01596, -1.50848, -2.71446, -5.02593, -3.21696, -3.92045, -4.32244, -3.41795, -5.02593, -3.81995, -4.32244, -4.52344, -3.92045, -5.72942, -5.12643, -4.92543, -3.81995, -5.42793, -4.32244, -5.42793, -5.12643, -5.02593, -6.63391, -6.53341, -4.92543, -6.43292, -7.13641, -7.3374, -7.03591, -7.23691, -6.83491, -7.4379, -8.14139, -8.74439, -8.24189, -9.14638, -8.54339, -9.24688, -9.44788, -9.34738, -9.64888, -9.74937, -9.95037, -9.84987, -9.74937, -9.95037, -9.95037, -9.84987, -9.95037, -9.95037, -9.95037, -9.95037]
    std. residuals:     [-10.0, -10.0, -9.596, -9.798, -8.687, -7.273, -4.849, -2.627, 1.716, 6.261, 10.402, 14.038, 17.674, 21.209, 19.896, 22.926, 23.734, 23.734, 27.471, 26.057, 18.886, 16.765, 20.502, 15.856, 15.452, 12.321, 12.624, 13.735, 12.422, 9.796, 9.089, 6.059, 8.079, 6.564, 7.574, 4.746, 1.817, 3.029, 3.433, 2.524, 2.322, 0.403, 0.403, -0.607, -0.304, 1.413, -0.607, -2.122, -2.122, -3.031, -1.516, -2.728, -5.051, -3.233, -3.94, -4.344, -3.435, -5.051, -3.839, -4.344, -4.546, -3.94, -5.758, -5.152, -4.95, -3.839, -5.455, -4.344, -5.455, -5.152, -5.051, -6.667, -6.566, -4.95, -6.465, -7.172, -7.374, -7.071, -7.273, -6.869, -7.475, -8.182, -8.788, -8.283, -9.192, -8.586, -9.293, -9.495, -9.394, -9.697, -9.798, -10.0, -9.899, -9.798, -10.0, -10.0, -9.899, -10.0, -10.0, -10.0, -10.0]

````

We do indeed see strong evidence that the two distributions are different.

## Example: Comparing t

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
