# Test the TuringSBCGenerator constructor
@testitem "TuringSBCGenerator Constructor" setup=[TestModel1] begin
    turing_generator = sbc_generator(turing_model, condition_names, sampler)
    @test turing_generator.primary_generator == turing_model
    @test turing_generator.secondary_generator == turing_model
    @test turing_generator.condition_names == condition_names
    @test turing_generator.sampler == sampler
    @test turing_generator.kwargs == Dict(:progress => false)
end

# Test the run_primary_generative function
@testitem "run_primary_generative" setup=[TestModel1] begin
    turing_generator = sbc_generator(turing_model, condition_names, sampler)
    result = run_primary_generative(turing_generator)
    @test isa(result, NamedTuple)
    @test haskey(result, :primary_target)
    @test haskey(result, :primary_sample)
end

# Test the run_secondary_generative function
@testitem "run_secondary_generative" setup=[TestModel1] begin
    turing_generator = sbc_generator(turing_model, condition_names, sampler)
    primary = run_primary_generative(turing_generator)
    n = 10
    secondary = run_secondary_generative(turing_generator, primary.primary_sample, n)
    @test isa(secondary, NamedTuple)
    @test haskey(secondary, :samples)
    @test size(secondary.samples, 1) == n
end

# Test the run_comparison function
@testitem "run_comparison: scalar dists" setup=[TestModel1] begin
    turing_generator = sbc_generator(turing_model, condition_names, sampler)
    n = 10
    n_comparisons = 10
    results = run_comparison(turing_generator, n, n_comparisons)
    rank_length_bools = map(results.rank_statistics) do rank
        length(rank) == n_comparisons
    end
    @test all(rank_length_bools)
end

@testitem "run_comparison: array dists" setup=[TestModel2] begin
    turing_generator = sbc_generator(turing_model, condition_names, sampler)
    n = 10
    n_comparisons = 10
    results = run_comparison(turing_generator, n, n_comparisons)
    rank_length_bools = map(results.rank_statistics) do rank
        length(rank) == n_comparisons
    end
    @test all(rank_length_bools)
end
