"""
A struct that collects all information relevant to a specific counterfactual explanation for a single individual.
"""
mutable struct CounterfactualExplanation <: AbstractCounterfactualExplanation
    x::AbstractArray
    target::RawTargetType
    target_encoded::EncodedTargetType
    s′::AbstractArray
    data::DataPreprocessing.CounterfactualData
    M::Models.AbstractFittedModel
    generator::Generators.AbstractGenerator
    generative_model_params::NamedTuple
    params::Dict
    search::Union{Dict,Nothing}
    convergence::Dict
    num_counterfactuals::Int
    initialization::Symbol
end

"""
	function CounterfactualExplanation(;
		x::AbstractArray,
		target::RawTargetType,
		data::CounterfactualData,
		M::Models.AbstractFittedModel,
		generator::Generators.AbstractGenerator,
		max_iter::Int = 100,
		num_counterfactuals::Int = 1,
		initialization::Symbol = :add_perturbation,
		generative_model_params::NamedTuple = (;),
		min_success_rate::AbstractFloat=0.99,
        converge_when::Symbol=:decision_threshold,
        invalidation_rate::AbstractFloat=0.5,
        learning_rate::AbstractFloat=1.0,
        variance::AbstractFloat=0.01,
	)

Outer method to construct a `CounterfactualExplanation` structure.
"""
function CounterfactualExplanation(
    x::AbstractArray,
    target::RawTargetType,
    data::CounterfactualData,
    M::Models.AbstractFittedModel,
    generator::Generators.AbstractGenerator;
    num_counterfactuals::Int=1,
    initialization::Symbol=:add_perturbation,
    generative_model_params::NamedTuple=(;),
    max_iter::Int=100,
    decision_threshold::AbstractFloat=0.5,
    gradient_tol::AbstractFloat=parameters[:τ],
    min_success_rate::AbstractFloat=parameters[:min_success_rate],
    converge_when::Symbol=:decision_threshold,
    invalidation_rate::AbstractFloat=0.5,
    learning_rate::AbstractFloat=1.0,
    variance::AbstractFloat=0.01,
)

    # Assertions:
    @assert any(predict_label(M, data) .== target) "You model `M` never predicts the target value `target` for any of the samples contained in `data`. Are you sure the model is correctly specified?"
    @assert 0.0 < min_success_rate <= 1.0 "Minimum success rate should be ∈ [0.0,1.0]."
    @assert converge_when ∈ [
        :decision_threshold,
        :generator_conditions,
        :max_iter,
        :invalidation_rate,
        :early_stopping,
    ]

    # Factual:
    x = typeof(x) == Int ? select_factual(data, x) : x

    # Target:
    target_encoded = data.output_encoder(target)

    # Initial Parameters:
    params = Dict{Symbol,Any}(
        :mutability => DataPreprocessing.mutability_constraints(data),
        :latent_space => generator.latent_space,
        :invalidation_rate => invalidation_rate,
        :learning_rate => learning_rate,
        :variance => variance,
    )
    ids = findall(predict_label(M, data) .== target)
    n_candidates = minimum([size(data.y, 2), 1000])
    candidates = select_factual(data, rand(ids, n_candidates))
    params[:potential_neighbours] = reduce(hcat, map(x -> x[1], collect(candidates)))

    # Convergence Parameters:
    convergence = Dict(
        :max_iter => max_iter,
        :decision_threshold => decision_threshold,
        :gradient_tol => gradient_tol,
        :min_success_rate => min_success_rate,
        :converge_when => converge_when,
    )

    # Instantiate: 
    ce = CounterfactualExplanation(
        x,
        target,
        target_encoded,
        x,
        data,
        M,
        deepcopy(generator),
        generative_model_params,
        params,
        nothing,
        convergence,
        num_counterfactuals,
        initialization,
    )

    # Initialization:
    adjust_shape!(ce)                                           # adjust shape to specified number of counterfactuals
    ce.s′ = encode_state(ce)            # encode the counterfactual state
    ce.s′ = initialize_state(ce)        # initialize the counterfactual state

    if generator isa Generators.FeatureTweakGenerator ||
        generator isa Generators.GrowingSpheresGenerator
        ce.search = Dict(
            :iteration_count => 0,
            :times_changed_features => zeros(size(decode_state(ce))),
            :path => [ce.s′],
            :terminated => false,
            :converged => false,
        )
        return ce
    end

    # Initialize search:
    ce.search = Dict(
        :iteration_count => 0,
        :times_changed_features => zeros(size(decode_state(ce))),
        :path => [ce.s′],
        :terminated => threshold_reached(ce, ce.x),
    )

    # This is lifted out of the above ce.search initialization because calling converged(ce) might self-reference
    # the above fields, which are not yet initialized.
    ce.search[:converged] = converged(ce)

    # Check for redundancy:
    if terminated(ce)
        @info "Factual already in target class and probability exceeds threshold γ."
    end

    return ce
end
