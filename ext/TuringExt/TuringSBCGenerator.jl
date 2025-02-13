@kwdef struct TuringGenerator{M <: Turing.Model} <: AbstractGenerator
    model::M
    condition = (;)
end

struct TuringSBCGenerator{A <: Sampleable, B <: Sampleable} <: AbstractDualGenerator
    primary_generator::A
    secondary_generator::B
end

"""
Method for generating primary target values. For `CompareDistGenerator` we do not need to generate
a sample from the primary distribution to pass to the secondary generator, only the target value.

# Returns
- A `NamedTuple` with the following fields:
  - `primary_target`: A randomly generated value from the `primary_generator.dist`.
  - `primary_sample`: Currently set to `nothing`.
"""
function run_primary_generative(generator::CompareDistGenerator)
    return (
        primary_target = rand(generator.primary_generator), primary_sample = nothing)
end

"""
    run_secondary_generative(model::CompareDistGenerator, primary_sample, n::Int)

Generates a secondary sample of length `n` using the provided `model` and conditional on
`primary_sample`. For `CompareDistGenerator` we only need to generate samples from the secondary
distribution. `primary_sample` is not used in this method dispatch.

# Returns
- A named tuple containing the generated samples.
"""
function run_secondary_generative(generator::CompareDistGenerator, primary_sample, n::Int)
    return (samples = rand(generator.secondary_generator, n),)
end

"""
Run a comparison using the provided `generator` for a specified number of comparisons (`n_comparisons`).
For each comparison, generate primary and secondary samples and count how many secondary samples are less than the primary target.
These are rank statistics for each comparison.

# Theoretical basis

If the primary and secondary samples are generated from the same distribution, then the rank
statistics should be uniformly distributed on [0, 1, ..., n].


# Arguments
- `generator::CompareDistGenerator`: An instance of `CompareDistGenerator` used to generate primary and secondary samples.
- `n::Int`: The number of secondary samples to generate for each comparison.
- `n_comparisons::Int`: The number of comparisons to perform.

# Returns
- `Vector{Int}`: A vector containing the rank statistics for each comparison, where each element represents the count of secondary samples that are less than the primary target.
"""
function run_comparison(generator::CompareDistGenerator, n::Int, n_comparisons::Int)
    rank_statistics = map(1:n_comparisons) do _
        primary = run_primary_generative(generator)
        secondary = run_secondary_generative(generator, primary.primary_sample, n)
        return sum(secondary.samples .< primary.primary_target)
    end
    return (; test_results = uniformity_test(rank_statistics, n), rank_statistics, n)
end

# Implement the SBCInterface for the CompareDistGenerator type.
@implements SBCInterface CompareDistGenerator [CompareDistGenerator(
    Normal(), Normal(1.0, 1.0))]
