module TuringExt
using Distributed, Distributions, Interfaces, SBC, Turing

include("TuringSBCGenerator.jl")

"""
Method for generating a `TuringSBCGenerator` instances for use in SBC.
"""
function SBC.sbc_generator(
        turing_generator::Turing.Model, condition_names::Tuple{Vararg{Symbol}},
        sampler; progress = false, kwargs...)
    Ty = typeof(turing_generator)
    name_type = typeof(condition_names)
    splr_type = typeof(sampler)

    return TuringSBCGenerator{Ty, Ty, name_type, splr_type}(
        turing_generator, turing_generator, condition_names, sampler,
        merge(Dict(kwargs), Dict(:progress => progress)))
end

# Implement the SBCInterface for the CompareDistGenerator type.
TestTuringSBCGenerator = let
    @model function test_model()
        mu ~ Normal(0, 1)
        x ~ Normal(mu, 1)
        return x
    end
    test_sampler = NUTS()
    test_condition_names = (:x,)
    test_turing_model = test_model()
    SBC.sbc_generator(test_turing_model, test_condition_names, test_sampler)
end

@implements SBCInterface TuringSBCGenerator [TestTuringSBCGenerator]

end
