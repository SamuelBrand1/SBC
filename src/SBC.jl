module SBC
using Distributions, DocStringExtensions, HypothesisTests, Interfaces

# Abstract types
export AbstractDualGenerator, AbstractGenerator, AbstractTrial

# Concrete types
export CompareDistGenerator

# Interfaces
export SBCInterface

# Methods
export run_primary_generative, run_secondary_generative

include("docstrings.jl")
include("types.jl")
include("interface.jl")
include("CompareDistGenerator.jl")

end
