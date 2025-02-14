module SBC
using Distributions, DocStringExtensions, HypothesisTests, Interfaces

## Turing Extension

ext = Base.get_extension(@__MODULE__, :TuringExt)
if !isnothing(ext)
    TuringSBCGenerator = ext.TuringSBCGenerator
end

# Abstract types
export AbstractDualGenerator, AbstractGenerator, AbstractTrial

# Concrete types
export CompareDistGenerator, TuringSBCGenerator

# Functions
export uniformity_test

# Interfaces
export SBCInterface

# Methods
export run_primary_generative, run_secondary_generative, run_comparison
export sbc_generator

include("docstrings.jl")
include("utils.jl")
include("types.jl")
include("uniformity_test.jl")
include("interface.jl")
include("CompareDistGenerator.jl")



end
