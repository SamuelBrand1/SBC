"""
A structure that represents a generator which compares two distribution generators.
The `primary_generator` is used to generate the primary samples, this is the target distribution.
The `secondary_generator` is used to generate the secondary samples, this is the conditional distribution.
"""
struct CompareDistGenerator{A <: Distribution, B <: Distribution} <: AbstractDualGenerator
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

# Implement the SBCInterface for the CompareDistGenerator type.
@implements SBCInterface CompareDistGenerator [CompareDistGenerator(
    Normal(), Normal(1.0, 1.0))]
