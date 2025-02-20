module Models

using ..CounterfactualExplanations
using ..DataPreprocessing
using Parameters
using Flux
using MLJBase
using NearestNeighborModels
using Plots
using LazyArtifacts
using Serialization
using LaplaceRedux
using MLUtils
using ProgressMeter
using Statistics
using EvoTrees
using SliceMap
using DataFrames
using MLJDecisionTreeInterface
using RCall
using PythonCall

include("utils.jl")

include("differentiable/differentiable.jl")
include("nondifferentiable/nondifferentiable.jl")

include("visualization/plotting/default.jl")
include("visualization/plotting/voronoi.jl")

include("pretrained/pretrained.jl")

export AbstractFittedModel
export AbstractDifferentiableModel
export Linear
export FluxModel
export FluxEnsemble
export LaplaceReduxModel
export EvoTreeModel
export DecisionTreeModel
export RandomForestModel
export PyTorchModel
export RTorchModel
export flux_training_params
export probs, logits

"""
    logits(M::AbstractFittedModel, X::AbstractArray)

Generic method that is compulsory for all models. It returns the raw model predictions. In classification this is sometimes referred to as *logits*: the non-normalized predictions that are fed into a link function to produce predicted probabilities. In regression (not currently implemented) raw outputs typically correspond to final outputs. In other words, there is typically no normalization involved.
"""
function logits(M::AbstractFittedModel, X::AbstractArray) end

"""
    probs(M::AbstractFittedModel, X::AbstractArray)

Generic method that is compulsory for all models. It returns the normalized model predictions, so the predicted probabilities in the case of classification. In regression (not currently implemented) this method is redundant. 
"""
function probs(M::AbstractFittedModel, X::AbstractArray) end

"""
    standard_models_catalogue

A dictionary containing all trainable machine learning models.
"""
const standard_models_catalogue = Dict(
    :Linear => Linear, :MLP => FluxModel, :DeepEnsemble => FluxEnsemble
)

"""
    all_models_catalogue

A dictionary containing both trainable and non-trainable machine learning models.
"""
const all_models_catalogue = Dict(
    :Linear => Linear,
    :MLP => FluxModel,
    :DeepEnsemble => FluxEnsemble,
    :LaplaceRedux => LaplaceReduxModel,
    :EvoTree => EvoTreeModel,
    :DecisionTree => DecisionTreeModel,
    :RandomForest => RandomForestModel,
    :PyTorchModel => PyTorchModel,
    :RTorchModel => RTorchModel,
)

"""
    mlj_models_catalogue

A dictionary containing all machine learning models from the MLJ model registry that the package supports.
"""
const mlj_models_catalogue = Dict(
    :EvoTree => EvoTreeModel,
    :DecisionTree => DecisionTreeModel,
    :RandomForest => RandomForestModel,
)

"""
    fit_model(
        counterfactual_data::CounterfactualData, model::Symbol=:MLP;
        kwrgs...
    )

Fits one of the available default models to the `counterfactual_data`. The `model` argument can be used to specify the desired model. The available values correspond to the keys of the [`all_models_catalogue`](@ref) dictionary.
"""
function fit_model(counterfactual_data::CounterfactualData, model::Symbol=:MLP; kwrgs...)
    @assert model in keys(all_models_catalogue) "Specified model does not match any of the models available in the `all_models_catalogue`."

    # Set up:
    M = all_models_catalogue[model](counterfactual_data; kwrgs...)
    train(M, counterfactual_data)

    return M
end

export standard_models_catalogue
export all_models_catalogue
export mlj_models_catalogue
export fit_model
export model_evaluation
export predict_label
export predict_proba
export pytorch_model_loader
export rtorch_model_loader
export reset!

end
