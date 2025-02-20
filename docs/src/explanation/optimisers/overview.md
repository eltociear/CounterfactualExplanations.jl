# Optimisation Rules

``` @meta
CurrentModule = CounterfactualExplanations 
```

Counterfactual search is an optimization problem. Consequently, the choice of the optimisation rule affects the generated counterfactuals. In the short term, we aim to enable users to choose any of the available `Flux` optimisers. This has not been sufficiently tested yet, and you may run into issues.

## Custom Optimisation Rules

`Flux` optimisers are specifically designed for deep learning, and in particular, for learning model parameters. In counterfactual search, the features are the free parameters that we are optimising over. To this end, some custom optimisation rules are necessary to incorporate ideas presented in the literature. In the following, we introduce those rules.
