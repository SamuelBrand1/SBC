# Running scripts

This directory contains scripts that can be used to run the experiments. The scripts are converted into markdown using the `Literate` package. The scripts are written in Julia and can be run using the Julia REPL from the `test` environment. The easiest usage is:

```julia-repl
julia> using TestEnv; TestEnv.activate(); using SBC
julia> Literate.markdown("scripts/README.jl"; flavor = Literate.CommonMarkFlavor(), execute = true)
```

This generates the `README.md` file in the root directory.

Note that this assumes that you have `Literate` installed in your base julia environment, and therefore is available via environmental stacking.
