# SBC
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package provides tools for performing simulation-based calibration (SBC) on generative models.
Out-of-the-box, it provides tools for comparing generative univariate distributions, but
it can be extended to other types of random sampling, namely full simulation based calibration of `Turing.jl` models.

Extensions have to comply with the `SBCInterface` provided by `SBC.jl` using `Interfaces.jl`.
At the moment this is very lightweight:
Required methods:
- `run_primary_generative` this samples from the primary distribution and returns a tuple of the sample from the target distribution and the auxiliary variable.
- `run_secondary_generative` this samples from the secondary distribution `n` times possibly conditional the auxiliary variable.
- `run_comparison`: This runs both the methods above sequentially `n_comparison` times, and gathers the rank statistics. By default these get
passed to the `uniformity_test` function to return a Chi-squared test result.

## Example
In this example, we define a form of Normal distribution that has no distributional knowledge,
but can be sampled from. We make this a subtype of the `Distributions.Sampleable` type and provide
the necessary methods.

````julia
using SBC, Distributions, HypothesisTests, Random
Random.seed!(1234)

struct SampleNormal{T} <: Sampleable{Univariate,Continuous} where T <: Real
    μ::T
    σ::T
end

function Base.rand(rng::AbstractRNG, s::SampleNormal)
    return s.μ  + s.σ * randn()
end

function Random.rand!(rng::AbstractRNG, s::SampleNormal, x::Vector)
    ϵ = randn(rng, length(x))
    @. x = s.μ + s.σ * ϵ
    return x
end
````

Now we can define a `CompareDistGenerator` that will compare two `SampleNormal` distributions.
As a first pass lets just compare two normal distributions with the same mean and variance.

````julia
compare_dists = CompareDistGenerator(SampleNormal(0.0, 1.0), SampleNormal(0.0, 1.0))
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
    point estimate:          [0.008, 0.0081, 0.0099, 0.0104, 0.0097, 0.0101, 0.0098, 0.0082, 0.0105, 0.0099, 0.0095, 0.0095, 0.0087, 0.0108, 0.0103, 0.0107, 0.0102, 0.0096, 0.0096, 0.0103, 0.0096, 0.0115, 0.0096, 0.0078, 0.0097, 0.0091, 0.0104, 0.01, 0.0092, 0.01, 0.0103, 0.0084, 0.0115, 0.0106, 0.0088, 0.0081, 0.0094, 0.0097, 0.0091, 0.0103, 0.0105, 0.0094, 0.0103, 0.0117, 0.0097, 0.0104, 0.0093, 0.01, 0.0099, 0.0088, 0.0101, 0.0105, 0.0083, 0.0076, 0.0107, 0.0111, 0.0083, 0.0092, 0.01, 0.0097, 0.0106, 0.0097, 0.0097, 0.0099, 0.0105, 0.0091, 0.0107, 0.0106, 0.0098, 0.0082, 0.0107, 0.0103, 0.0099, 0.0106, 0.0095, 0.0097, 0.0098, 0.0111, 0.0105, 0.0103, 0.0087, 0.0097, 0.0098, 0.0114, 0.0101, 0.0118, 0.0115, 0.0097, 0.0103, 0.0127, 0.0098, 0.011, 0.0103, 0.0099, 0.0096, 0.0101, 0.0082, 0.0107, 0.0102, 0.0101, 0.0108]
    95% confidence interval: [(0.0046, 0.01151), (0.0047, 0.01161), (0.0065, 0.01341), (0.007, 0.01391), (0.0063, 0.01321), (0.0067, 0.01361), (0.0064, 0.01331), (0.0048, 0.01171), (0.0071, 0.01401), (0.0065, 0.01341), (0.0061, 0.01301), (0.0061, 0.01301), (0.0053, 0.01221), (0.0074, 0.01431), (0.0069, 0.01381), (0.0073, 0.01421), (0.0068, 0.01371), (0.0062, 0.01311), (0.0062, 0.01311), (0.0069, 0.01381), (0.0062, 0.01311), (0.0081, 0.01501), (0.0062, 0.01311), (0.0044, 0.01131), (0.0063, 0.01321), (0.0057, 0.01261), (0.007, 0.01391), (0.0066, 0.01351), (0.0058, 0.01271), (0.0066, 0.01351), (0.0069, 0.01381), (0.005, 0.01191), (0.0081, 0.01501), (0.0072, 0.01411), (0.0054, 0.01231), (0.0047, 0.01161), (0.006, 0.01291), (0.0063, 0.01321), (0.0057, 0.01261), (0.0069, 0.01381), (0.0071, 0.01401), (0.006, 0.01291), (0.0069, 0.01381), (0.0083, 0.01521), (0.0063, 0.01321), (0.007, 0.01391), (0.0059, 0.01281), (0.0066, 0.01351), (0.0065, 0.01341), (0.0054, 0.01231), (0.0067, 0.01361), (0.0071, 0.01401), (0.0049, 0.01181), (0.0042, 0.01111), (0.0073, 0.01421), (0.0077, 0.01461), (0.0049, 0.01181), (0.0058, 0.01271), (0.0066, 0.01351), (0.0063, 0.01321), (0.0072, 0.01411), (0.0063, 0.01321), (0.0063, 0.01321), (0.0065, 0.01341), (0.0071, 0.01401), (0.0057, 0.01261), (0.0073, 0.01421), (0.0072, 0.01411), (0.0064, 0.01331), (0.0048, 0.01171), (0.0073, 0.01421), (0.0069, 0.01381), (0.0065, 0.01341), (0.0072, 0.01411), (0.0061, 0.01301), (0.0063, 0.01321), (0.0064, 0.01331), (0.0077, 0.01461), (0.0071, 0.01401), (0.0069, 0.01381), (0.0053, 0.01221), (0.0063, 0.01321), (0.0064, 0.01331), (0.008, 0.01491), (0.0067, 0.01361), (0.0084, 0.01531), (0.0081, 0.01501), (0.0063, 0.01321), (0.0069, 0.01381), (0.0093, 0.01621), (0.0064, 0.01331), (0.0076, 0.01451), (0.0069, 0.01381), (0.0065, 0.01341), (0.0062, 0.01311), (0.0067, 0.01361), (0.0048, 0.01171), (0.0073, 0.01421), (0.0068, 0.01371), (0.0067, 0.01361), (0.0074, 0.01431)]

Test summary:
    outcome with 95% confidence: fail to reject h_0
    one-sided p-value:           0.8192

Details:
    Sample size:        10000
    statistic:          87.03159999999993
    degrees of freedom: 100
    residuals:          [-1.91047, -1.80997, -0.000995037, 0.501499, -0.201993, 0.200002, -0.101494, -1.70947, 0.601998, -0.000995037, -0.40299, -0.40299, -1.20698, 0.903494, 0.401, 0.802995, 0.300501, -0.302491, -0.302491, 0.401, -0.302491, 1.60699, -0.302491, -2.11147, -0.201993, -0.804985, 0.501499, 0.0995037, -0.704486, 0.0995037, 0.401, -1.50848, 1.60699, 0.702496, -1.10648, -1.80997, -0.503489, -0.201993, -0.804985, 0.401, 0.601998, -0.503489, 0.401, 1.80798, -0.201993, 0.501499, -0.603988, 0.0995037, -0.000995037, -1.10648, 0.200002, 0.601998, -1.60898, -2.31247, 0.802995, 1.20499, -1.60898, -0.704486, 0.0995037, -0.201993, 0.702496, -0.201993, -0.201993, -0.000995037, 0.601998, -0.804985, 0.802995, 0.702496, -0.101494, -1.70947, 0.802995, 0.401, -0.000995037, 0.702496, -0.40299, -0.201993, -0.101494, 1.20499, 0.601998, 0.401, -1.20698, -0.201993, -0.101494, 1.50649, 0.200002, 1.90848, 1.60699, -0.201993, 0.401, 2.81297, -0.101494, 1.10449, 0.401, -0.000995037, -0.302491, 0.200002, -1.70947, 0.802995, 0.300501, 0.200002, 0.903494]
    std. residuals:     [-1.92, -1.819, -0.001, 0.504, -0.203, 0.201, -0.102, -1.718, 0.605, -0.001, -0.405, -0.405, -1.213, 0.908, 0.403, 0.807, 0.302, -0.304, -0.304, 0.403, -0.304, 1.615, -0.304, -2.122, -0.203, -0.809, 0.504, 0.1, -0.708, 0.1, 0.403, -1.516, 1.615, 0.706, -1.112, -1.819, -0.506, -0.203, -0.809, 0.403, 0.605, -0.506, 0.403, 1.817, -0.203, 0.504, -0.607, 0.1, -0.001, -1.112, 0.201, 0.605, -1.617, -2.324, 0.807, 1.211, -1.617, -0.708, 0.1, -0.203, 0.706, -0.203, -0.203, -0.001, 0.605, -0.809, 0.807, 0.706, -0.102, -1.718, 0.807, 0.403, -0.001, 0.706, -0.405, -0.203, -0.102, 1.211, 0.605, 0.403, -1.213, -0.203, -0.102, 1.514, 0.201, 1.918, 1.615, -0.203, 0.403, 2.827, -0.102, 1.11, 0.403, -0.001, -0.304, 0.201, -1.718, 0.807, 0.302, 0.201, 0.908]

````

We see that there is no evidence that the two distributions are different.
By contrast is we test whether the sampling distribution is different from a Cauchy distribution
with scale 1.0.

````julia
compare_different_dists = CompareDistGenerator(SampleNormal(0.0, 1.0), Cauchy(1.0))
results_diff = run_comparison(compare_different_dists, n, n_comparisons)
results_diff.test_results
````

````
Pearson's Chi-square Test
-------------------------
Population details:
    parameter of interest:   Multinomial Probabilities
    value under h_0:         [0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099, 0.00990099]
    point estimate:          [0.0, 0.0001, 0.0001, 0.0004, 0.0007, 0.002, 0.004, 0.0079, 0.0104, 0.0142, 0.0197, 0.0224, 0.0261, 0.0284, 0.03, 0.0328, 0.0324, 0.0339, 0.0318, 0.0331, 0.0316, 0.0309, 0.0282, 0.0269, 0.0281, 0.0242, 0.0211, 0.0215, 0.0193, 0.021, 0.019, 0.0199, 0.0171, 0.0153, 0.0161, 0.0133, 0.0141, 0.0125, 0.0129, 0.0117, 0.0123, 0.0106, 0.0106, 0.011, 0.0105, 0.0101, 0.0078, 0.0086, 0.0072, 0.0068, 0.0086, 0.0078, 0.0055, 0.007, 0.0073, 0.0073, 0.0056, 0.0069, 0.0076, 0.0069, 0.0052, 0.0047, 0.0066, 0.0059, 0.0039, 0.0049, 0.0043, 0.0045, 0.0053, 0.0038, 0.0057, 0.004, 0.0037, 0.0035, 0.0041, 0.0034, 0.003, 0.0031, 0.0024, 0.0018, 0.0023, 0.0022, 0.002, 0.0019, 0.0012, 0.002, 0.001, 0.001, 0.0003, 0.0005, 0.0003, 0.0002, 0.0001, 0.0001, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    95% confidence interval: [(0.0, 0.005047), (0.0, 0.005147), (0.0, 0.005147), (0.0, 0.005447), (0.0, 0.005747), (0.0, 0.007047), (0.0, 0.009047), (0.003, 0.01295), (0.0055, 0.01545), (0.0093, 0.01925), (0.0148, 0.02475), (0.0175, 0.02745), (0.0212, 0.03115), (0.0235, 0.03345), (0.0251, 0.03505), (0.0279, 0.03785), (0.0275, 0.03745), (0.029, 0.03895), (0.0269, 0.03685), (0.0282, 0.03815), (0.0267, 0.03665), (0.026, 0.03595), (0.0233, 0.03325), (0.022, 0.03195), (0.0232, 0.03315), (0.0193, 0.02925), (0.0162, 0.02615), (0.0166, 0.02655), (0.0144, 0.02435), (0.0161, 0.02605), (0.0141, 0.02405), (0.015, 0.02495), (0.0122, 0.02215), (0.0104, 0.02035), (0.0112, 0.02115), (0.0084, 0.01835), (0.0092, 0.01915), (0.0076, 0.01755), (0.008, 0.01795), (0.0068, 0.01675), (0.0074, 0.01735), (0.0057, 0.01565), (0.0057, 0.01565), (0.0061, 0.01605), (0.0056, 0.01555), (0.0052, 0.01515), (0.0029, 0.01285), (0.0037, 0.01365), (0.0023, 0.01225), (0.0019, 0.01185), (0.0037, 0.01365), (0.0029, 0.01285), (0.0006, 0.01055), (0.0021, 0.01205), (0.0024, 0.01235), (0.0024, 0.01235), (0.0007, 0.01065), (0.002, 0.01195), (0.0027, 0.01265), (0.002, 0.01195), (0.0003, 0.01025), (0.0, 0.009747), (0.0017, 0.01165), (0.001, 0.01095), (0.0, 0.008947), (0.0, 0.009947), (0.0, 0.009347), (0.0, 0.009547), (0.0004, 0.01035), (0.0, 0.008847), (0.0008, 0.01075), (0.0, 0.009047), (0.0, 0.008747), (0.0, 0.008547), (0.0, 0.009147), (0.0, 0.008447), (0.0, 0.008047), (0.0, 0.008147), (0.0, 0.007447), (0.0, 0.006847), (0.0, 0.007347), (0.0, 0.007247), (0.0, 0.007047), (0.0, 0.006947), (0.0, 0.006247), (0.0, 0.007047), (0.0, 0.006047), (0.0, 0.006047), (0.0, 0.005347), (0.0, 0.005547), (0.0, 0.005347), (0.0, 0.005247), (0.0, 0.005147), (0.0, 0.005147), (0.0, 0.005047), (0.0, 0.005047), (0.0, 0.005047), (0.0, 0.005047), (0.0, 0.005047), (0.0, 0.005047), (0.0, 0.005047)]

Test summary:
    outcome with 95% confidence: reject h_0
    one-sided p-value:           <1e-99

Details:
    Sample size:        10000
    statistic:          10048.237399999996
    degrees of freedom: 100
    residuals:          [-9.95037, -9.84987, -9.84987, -9.54838, -9.24688, -7.9404, -5.93042, -2.01097, 0.501499, 4.32045, 9.84788, 12.5613, 16.2798, 18.5913, 20.1993, 23.0132, 22.6112, 24.1187, 22.0082, 23.3147, 21.8072, 21.1037, 18.3903, 17.0838, 18.2898, 14.3703, 11.2549, 11.6569, 9.44589, 11.1544, 9.14439, 10.0489, 7.23492, 5.42594, 6.22993, 3.41596, 4.21995, 2.61197, 3.01397, 1.80798, 2.41098, 0.702496, 0.702496, 1.10449, 0.601998, 0.200002, -2.11147, -1.30748, -2.71446, -3.11646, -1.30748, -2.11147, -4.42294, -2.91546, -2.61396, -2.61396, -4.32244, -3.01596, -2.31247, -3.01596, -4.72444, -5.22693, -3.31745, -4.02095, -6.03092, -5.02593, -5.62893, -5.42793, -4.62394, -6.13142, -4.22194, -5.93042, -6.23192, -6.43292, -5.82992, -6.53341, -6.93541, -6.83491, -7.5384, -8.14139, -7.6389, -7.7394, -7.9404, -8.0409, -8.74439, -7.9404, -8.94538, -8.94538, -9.64888, -9.44788, -9.64888, -9.74937, -9.84987, -9.84987, -9.95037, -9.95037, -9.95037, -9.95037, -9.95037, -9.95037, -9.95037]
    std. residuals:     [-10.0, -9.899, -9.899, -9.596, -9.293, -7.98, -5.96, -2.021, 0.504, 4.342, 9.897, 12.624, 16.361, 18.684, 20.3, 23.128, 22.724, 24.239, 22.118, 23.431, 21.916, 21.209, 18.482, 17.169, 18.381, 14.442, 11.311, 11.715, 9.493, 11.21, 9.19, 10.099, 7.271, 5.453, 6.261, 3.433, 4.241, 2.625, 3.029, 1.817, 2.423, 0.706, 0.706, 1.11, 0.605, 0.201, -2.122, -1.314, -2.728, -3.132, -1.314, -2.122, -4.445, -2.93, -2.627, -2.627, -4.344, -3.031, -2.324, -3.031, -4.748, -5.253, -3.334, -4.041, -6.061, -5.051, -5.657, -5.455, -4.647, -6.162, -4.243, -5.96, -6.263, -6.465, -5.859, -6.566, -6.97, -6.869, -7.576, -8.182, -7.677, -7.778, -7.98, -8.081, -8.788, -7.98, -8.99, -8.99, -9.697, -9.495, -9.697, -9.798, -9.899, -9.899, -10.0, -10.0, -10.0, -10.0, -10.0, -10.0, -10.0]

````

We do indeed see strong evidence that the two distributions are different.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
