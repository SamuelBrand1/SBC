module SBC
using Distributions, DocStringExtensions, HypothesisTests, Interfaces

# Abstract types
export AbstractGenerator, AbstractTrial

include("docstrings.jl")
include("types.jl")

end
