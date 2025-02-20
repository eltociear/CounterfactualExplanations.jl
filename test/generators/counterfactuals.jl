# NOTE:
# This is probably the most important/useful test script, because it runs through the whole process of: 
# - loading artifacts
# - setting up counterfactual search for various models and generators
# - running counterfactual search

# LOOP:
for (key, generator_) in generators
    name = uppercasefirst(string(key))

    # Feature Tweak and Growing Spheres will be tested separately
    if generator_() isa Generators.FeatureTweakGenerator ||
        generator_() isa Generators.GrowingSpheresGenerator
        continue
    end

    @testset "$name" begin

        # Generator:
        generator = deepcopy(generator_())

        @testset "Models for synthetic data" begin
            for (key, value) in synthetic
                name = string(key)
                @testset "$name" begin
                    counterfactual_data = value[:data]
                    X = counterfactual_data.X
                    ys_cold = vec(counterfactual_data.y)

                    for (likelihood, model) in value[:models]
                        name = string(likelihood)
                        @testset "$name" begin
                            M = model[:model]
                            # Randomly selected factual:
                            Random.seed!(123)
                            x = DataPreprocessing.select_factual(
                                counterfactual_data, rand(1:size(X, 2))
                            )
                            multiple_x = DataPreprocessing.select_factual(
                                counterfactual_data, rand(1:size(X, 2), 5)
                            )
                            # Choose target:
                            y = Models.predict_label(M, counterfactual_data, x)
                            target = get_target(counterfactual_data, y[1])
                            # Single sample:
                            counterfactual = CounterfactualExplanations.generate_counterfactual(
                                x, target, counterfactual_data, M, generator
                            )
                            # Multiple samples:
                            counterfactuals = CounterfactualExplanations.generate_counterfactual(
                                multiple_x, target, counterfactual_data, M, generator
                            )

                            @testset "Predetermined outputs" begin
                                if generator.latent_space
                                    @test counterfactual.params[:latent_space]
                                end
                                @test counterfactual.target == target
                                @test counterfactual.x == x &&
                                    CounterfactualExplanations.factual(counterfactual) ==
                                      x
                                @test CounterfactualExplanations.factual_label(
                                    counterfactual
                                ) == y
                                @test CounterfactualExplanations.factual_probability(
                                    counterfactual
                                ) == Models.probs(M, x)
                            end

                            @testset "Convergence" begin
                                @testset "Non-trivial case" begin
                                    counterfactual_data.generative_model = nothing
                                    # Threshold reached if converged:
                                    γ = 0.9
                                    max_iter = 1000
                                    counterfactual = CounterfactualExplanations.generate_counterfactual(
                                        x,
                                        target,
                                        counterfactual_data,
                                        M,
                                        generator;
                                        max_iter=max_iter,
                                        decision_threshold=γ,
                                    )
                                    using CounterfactualExplanations:
                                        counterfactual_probability
                                    @test !CounterfactualExplanations.converged(
                                        counterfactual
                                    ) ||
                                        CounterfactualExplanations.target_probs(
                                        counterfactual
                                    )[1] >= γ # either not converged or threshold reached
                                    @test !CounterfactualExplanations.converged(
                                        counterfactual
                                    ) || length(path(counterfactual)) <= max_iter
                                end

                                @testset "Trivial case (already in target class)" begin
                                    counterfactual_data.generative_model = nothing
                                    # Already in target and exceeding threshold probability:
                                    y = Models.predict_label(M, counterfactual_data, x)
                                    target = y[1]
                                    γ = minimum([
                                        1 / length(counterfactual_data.y_levels), 0.5
                                    ])
                                    counterfactual = CounterfactualExplanations.generate_counterfactual(
                                        x,
                                        target,
                                        counterfactual_data,
                                        M,
                                        generator;
                                        decision_threshold=γ,
                                        initialization=:identity,
                                    )
                                    x′ = CounterfactualExplanations.decode_state(
                                        counterfactual
                                    )
                                    if counterfactual.generator.latent_space == false
                                        @test isapprox(counterfactual.x, x′; atol=1e-6)
                                        @test CounterfactualExplanations.converged(
                                            counterfactual
                                        )
                                        @test CounterfactualExplanations.terminated(
                                            counterfactual
                                        )
                                    end
                                    @test CounterfactualExplanations.total_steps(
                                        counterfactual
                                    ) == 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
