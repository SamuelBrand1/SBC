"""
Base method for running the true/primary generative model.
"""
function run_primary_generative end
"""
Base method for running the secondary/conditional generative model.
"""
function run_secondary_generative end

components = (
    mandatory = (
        run_primary_generative = (
            "Primary generative model returns a `Tuple`" => args::Arguments -> run_primary_generative(args.model) isa
                                                                               Union{
                Tuple, NamedTuple},
            "Primary generative model returns two elements" => args::Arguments -> length(run_primary_generative(args.model)) ==
                                                                                  2
        ),
        run_secondary_generative = (
            "Secondary generative model returns a `Tuple`" => args::Arguments -> run_secondary_generative(
            args.model, args.primary_sample, args.n) isa Union{Tuple, NamedTuple},
        )
    ),
    optional = (;)
)

description = """
Defines a generic interface for running the simulation-based calibration (SBC). The interface
consists of two methods: `run_primary_generative` and `run_secondary_generative`.

The `run_primary_generative` method is used to run the primary generative model, and must
return a tuple/namedtuple of two elements:

1. A sample of the target distribution.
2. An auxilary random variable that is used to generate the secondary samples.

The `run_secondary_generative` method is used to run the secondary generative model, and must
return a tuple/namedtuple. The method takes two arguments:

1. `model`: The secondary generative model.
2. `primary_sample`: The auxilary sample generated by the primary generative model.
"""

@interface SBCInterface AbstractDualGenerator components description
