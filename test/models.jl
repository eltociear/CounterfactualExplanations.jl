using CounterfactualExplanations
using CounterfactualExplanations.Models
using Random
using LinearAlgebra
using NNlib

@testset "Exceptions" begin
    @testset "LogisticModel" begin
        w = [1,2] # vector instead of matrix
        b = 0 # scalar instead of array
        @test_throws MethodError LogisticModel(w, b)
    end

    @testset "BayesianLogisticModel" begin

        μ = [0, 1.0, -2.0] # vector instead of matrix
        Σ = Symmetric(reshape(randn(9),3,3).*0.1 + UniformScaling(1.0)) # MAP covariance matrix
        @test_throws MethodError BayesianLogisticModel(μ, Σ)

        # Dimensions not matching:
        μ = [0 1.0] 
        Σ = Symmetric(reshape(randn(9),3,3).*0.1 + UniformScaling(1.0)) 
        @test_throws DimensionMismatch BayesianLogisticModel(μ, Σ)

    end

    @testset "logits" begin
        M(x) = [2 1] * x # model not declared as subtype of AbstractFittedModel
        x = [1,1]
        @test_throws MethodError logits(M, x)
    end

    @testset "probs" begin
        M(x) = [2 1] * x # model not declared as subtype of AbstractFittedModel
        x = [1,1]
        @test_throws MethodError probs(M, x)
    end
end

@testset "Predictions" begin

    @testset "LogisticModel" begin
        M = LogisticModel([1 1],[0])
        x = [1,1]
        @test logits(M, x)[1] == 2
        @test probs(M, x)[1] == σ(2) 
    end

    @testset "BayesianLogisticModel" begin

        # MLE:
        μ = [0 1.0 1.0] # vector instead of matrix
        Σ = zeros(3,3) # MAP covariance matrix
        M = BayesianLogisticModel(μ, Σ)
        x = [1,1]
        @test logits(M, x)[1] == 2
        @test probs(M, x)[1] == σ(2)

        # Not MLE:
        μ = [0 1.0 1.0] # vector instead of matrix
        Σ = zeros(3,3) + UniformScaling(1) # MAP covariance matrix
        M = BayesianLogisticModel(μ, Σ)
        x = [1,1]
        @test logits(M, x)[1] == 2
        @test probs(M, x)[1] != σ(2) # posterior predictive using probit link function

    end
    
end