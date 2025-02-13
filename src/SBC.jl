module SBC
using Distributions, DocStringExtensions, HypothesisTests, Interfaces

# Abstract types
export AbstractDualGenerator, AbstractGenerator, AbstractTrial

# Concrete types
export CompareDistGenerator

# Functions
export uniformity_test

# Interfaces
export SBCInterface

# Methods
export run_primary_generative, run_secondary_generative, run_comparison

include("docstrings.jl")
include("types.jl")
include("uniformity_test.jl")
include("interface.jl")
include("CompareDistGenerator.jl")

end
