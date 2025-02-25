# Model with only scalar distributions
@testsnippet TestModel1 begin
    using Turing
    @model function test_model()
        mu ~ Normal(0, 1)
        x ~ Normal(mu, 1)
        return x
    end
    sampler = NUTS()
    condition_names = (:x,)
    turing_model = test_model()
end

# Model with array distribution
@testsnippet TestModel2 begin
    using Turing
    nd = 10
    @model function test_model()
        mu ~ filldist(Normal(0, 1), nd)
        x ~ arraydist([Normal(m, 1) for m in mu])
        return x
    end
    sampler = NUTS()
    condition_names = (:x,)
    turing_model = test_model()
end
