"""
    TuringSBCGenerator

A struct that represents a generator for Simulation-Based Calibration (SBC) using Turing models.

# Fields
- `primary_generator::Turing.Model`: The primary Turing model used for generating samples.
- `secondary_generator::Turing.Model`: The secondary Turing model used for generating samples conditional on some primary sample.
- `condition_names::Tuple{Vararg{Symbol}}`: A tuple of symbols representing the names of the conditional variables.
- `sampler::DynamicPPL.Sampler`: A sampler used for generating secondary samples.

# Constructors
- `sbc_generator(turing_generator::Turing.Model,
                         condition_names::Tuple{Vararg{Symbol}},
                         sampler::DynamicPPL.Sampler; kwargs...)`: Create a `TuringSBCGenerator` with
                         the same primary and secondary generator as a Turing model `turing_generator`.
                         Secondary samples are sampled using the provided `sampler`. `kwargs` are passed to the
                         sampler.

# Generative models
The primary and secondary generators should be compatible in terms of the conditional variables they expect.
However, it is possible to have different generative models for the primary and secondary samples. For example,
the primary generator could be a generative `Distributions.Sampleable` object. This allows for more flexibility
in the generative models used for SBC, and matches the flexibility of the [`SBC` R package](https://hyunjimoon.github.io/SBC/articles/SBC.html#aims-of-the-package).
"""
struct TuringSBCGenerator{A <: Union{Turing.Model, Sampleable}, B <: Turing.Model,
    T <: Tuple{Vararg{Symbol}}, S} <: AbstractDualGenerator where {S}
    primary_generator::A
    secondary_generator::B
    condition_names::T
    sampler::S
    kwargs::Dict{Symbol, Any}
end

function SBC.run_primary_generative(generator::TuringSBCGenerator)
    θ = rand(generator.primary_generator)
    @assert θ isa NamedTuple "Primary generator must return a NamedTuple."
    primary_target, primary_sample = SBC._split_namedtuple(θ, generator.condition_names)

    return (; primary_target, primary_sample)
end

function SBC.run_secondary_generative(generator::TuringSBCGenerator, primary_sample, n::Int)
    conditional_model = condition(generator.secondary_generator, primary_sample)
    samples = Turing.sample(conditional_model, generator.sampler, n; generator.kwargs...)
    return (; samples,)
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
function SBC.run_comparison(generator::TuringSBCGenerator, n::Int, n_comparisons::Int)
    rank_statistics_vector = pmap(1:n_comparisons) do _
        primary = run_primary_generative(generator)
        secondary = run_secondary_generative(generator, primary.primary_sample, n)
        # Collect the rank statistics whilst keeping the variable names
        pairs_form = primary.primary_target |> pairs |> collect
        rank_statistic = map(pairs_form) do P
            name = P.first
            target = P.second
            return (name, sum(secondary.samples[name] .< target))
        end |> NamedTuple
        return rank_statistic
    end
    init_nt = map(rank_statistics_vector[1]) do _
        Int[]
    end
    rank_statistics = foldl(SBC._nt_lfold_fn, rank_statistics_vector; init = init_nt)
    test_results = map(rank_statistics) do rank_stat
        uniformity_test(rank_stat, n)
    end
    return (; test_results, rank_statistics, n)
end
