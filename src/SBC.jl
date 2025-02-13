module SBC
using Distributions, DocStringExtensions, HypothesisTests, Interfaces

# Abstract types
export AbstractDualGenerator, AbstractGenerator, AbstractTrial

include("docstrings.jl")
include("types.jl")
include("interface.jl")

end
