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
