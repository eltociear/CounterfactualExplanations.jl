# Report: Integrating MLJ models into the package


## Generator compatibility analysis for each MLJ model

The tables below will present an overview of the compatibility of models from the [MLJ general registry](https://alan-turing-institute.github.io/MLJ.jl/dev/list_of_supported_models/) with ``CounterfactualExplanations.jl``, organized by the interface library.


### BetaML.jl

| **Model** | **Analysis** |
| -------- | ------- |
| DecisionTreeClassifier, RandomForestClassifier | Currently incompatible with gradient-based generators. However, counterfactual explanations can be generated for this model using the Feature Tweak generator we implemented. The models could also be made compatible with gradient-based generators in the future, possibly through the use of [probability calibration](https://scikit-learn.org/stable/modules/calibration.html). |
| NeuralNetworkClassifier, LinearPerceptron | Currently incompatible with all generators. However, it should be possible to make these models compatible with all gradient-based generators once the best way to access their gradients has been figured out. |
| KernelPerceptron | Currently incompatible with all generators, since the model is not differentiable. The possibility of using probability calibration should be explored. |

The package also contains various regressors and unsupervised models which are incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers.


### CatBoost.jl

| **Model** | **Analysis** |
| CatBoostClassifier | Currently incompatible with all generators. However, the model relies on gradient-boosted decision trees in a way that is seemingly highly similar to EvoTrees, so the possibility of supporting the model should be explored after implementing support for EvoTrees. |
| CatBoostRegressor | Incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers. |


### MLJClusteringInterface.jl, OutlierDetectionNeighbors.jl, OutlierDetectionNetworks.jl, OutlierDetectionPython.jl, ParallelKMeans.jl, TSVD.jl

All models from these packages are incompatible with all generators, since the packages only offer unsupervised models for which counterfactual explanations don't apply.


### MLJDecisionTreeInterface.jl

| **Model** | **Analysis** |
| DecisionTreeClassifier, RandomForestClassifier | Currently incompatible with gradient-based generators. However, counterfactual explanations can be generated for this model using the Feature Tweak generator we implemented. The models could also be made compatible with gradient-based generators in the future, possibly through the use of [probability calibration](https://scikit-learn.org/stable/modules/calibration.html). |
| DecisionTreeRegressor, RandomForestRegressor | Incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers. |
| AdaBoostClassifier | Currently not supported, but the compatibility of the model with both gradient-based generators as well as with Feature Tweak is worth exploring. |


### EvoTrees.jl

| **Model** | **Analysis** |
| EvoTreeClassifier | We are currently in the process of implementing support for this model. |
| EvoTreeRegressor, EvoTreeCount, EvoTreeGaussian, EvoTreeMLE | Incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers. |


### OneRule.jl, MLJText.jl, MLJNaiveBayesInterface.jl, PartialLeastSquaresRegressor.jl

As the maturity of each of these packages is marked as either low or experimental in the [MLJ model registry](https://alan-turing-institute.github.io/MLJ.jl/dev/list_of_supported_models/), the compatibility of models from these libraries with CounterfactualExplanations.jl will not be explored during the software project, as these libraries are expected to change a lot in the near future and this could require constant changes of the code in our library to maintain the compatibility with these models. Instead, it is better to wait until the libraries become more mature.


### MLJFlux.jl

Though the maturity of this library is also marked to be low, we think that it's nevertheless worth an attempt to make our package compatible with models from this library. This is because the models are compatible with Zygote.jl, which is the library currently used for automatic differentiation for the models already implemented in our package.

| **Model** | **Analysis** |
| NeuralNetworkClassifier, ImageClassifier | Currently incompatible with the package, but [the client has already explored the possibility of incorporating these models into the package](https://github.com/FluxML/MLJFlux.jl/issues/220). We are planning to build upon that progress. |
| NeuralNetworkRegressor, MultitargetNeuralNetworkRegressor | Incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers. |


### MLJLinearModels.jl

| **Model** | **Analysis** |
| LogisticClassifier, MultinomialClassifier | Both models are differentiable and it should be possible to make them compatible with the package. |

The package also contains various regressors which are incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers.


### MLJGLMInterface.jl

| **Model** | **Analysis** |
| LinearBinaryClassifier | The model is differentiable, but given that linear classifiers are offered by other MLJ-supported libraries with higher maturity and that this is the only model from this library compatible with our package, it is unclear whether we should offer support for this model. |

The package also contains various regressors which are incompatible with all generators, as the package currently only supports generating counterfactual explanations for classifiers.


### MLJLIBSVMInterface.jl

| **Model** | **Analysis** |
| LinearSVC | Support vector classifiers are generally not differentiable, but there seem to be some recent attempts to propose methods for producing counterfactual explanations for SVCs: see, e.g., ["Counterfactual Explanations for Support Vector Machine Models"](https://arxiv.org/abs/2212.07432) by Salazar et al. However, it seems to be an active field of research and exploring it would take a long time, so we probably can't fit implementing support for this model into the scope of the software project. |
| SVC, NuSVC, NuSVR, EpsilonSVR |  |
| OneClassSVM | OneClassSVM is an unsupervised anomaly detection model, so it will not be supported by this package. |


### MLJMultivariateStatsInterface.jl

| **Model** | **Analysis** |
| LinearSVC | Support vecto


### NearestNeighborModels.jl

| **Model** | **Analysis** |
| LinearSVC | Support vecto


### EvoLinear.jl, PartialLeastSquaresRegressor.jl

All models from the package are incompatible with all generators, since the package only offers regression models, which the generators don't currently support.


### ScikitLearn.jl, LightGBM.jl

Since the models offered by these library are not native to Julia (both libraries are implemented in Python) and the task of generating counterfactuals for them is thus expected to be more difficult compared to native Julia models, we will explore the possible compatibility of models from this library once we have finished working on MLJ models natively implemented in Julia.


### MLJMultivariateStatsInterface.jl, NearestNeighborModels.jl

The compatibility of models from these packages has not been evaluated yet, but will be evaluated soon.


### MLJModels.jl

This is the base MLJ package from which all the other MLJ-supported models can be loaded. Support for the models that can be loaded through this library has been documented in the whole document above. The package also offers some models on its own, but the generation of counterfactuals for these models is not supported, as they are mostly helper models such as OneHotEncoder and UnivariateBoxCoxTransformer that don't make class predictions on their own.