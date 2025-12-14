## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----core1, eval=FALSE--------------------------------------------------------
# # fits the individual SDTrees in parallel on 22 cores
# fit <- SDForest(x = X, y = Y, mc.cores = 22)
# 
# # predicts with the individual SDTrees in parallel
# predict(fit, newdata = data.frame(X), mc.cores = 10)
# 
# # evaluates different strengths of regularization in parallel
# paths <- regPath(fit, mc.cores = 10)
# 
# # predicts potential outcomes for different values of covariate one in parallel
# pd <- partDependence(model, 1, mc.cores = 10)
# 
# # performs cross validation in parallel
# model <- SDAM(X, Y, cv_k = 5, mc.cores = 5)

## ----core2, eval=FALSE--------------------------------------------------------
# # predefined plan
# future::plan(multisession, workers = 2)
# # fits the individual SDTrees in parallel on 2 cores
# fit <- SDForest(x = X, y = Y)

## ----candidates, eval=FALSE---------------------------------------------------
# # approximation of candidate splits
# fit <- SDForest(x = X, y = Y, max_candidates = 100)
# tree <- SDTree(x = X, y = Y, max_candidates = 50)

## ----subsample, eval=FALSE----------------------------------------------------
# # draws maximal 500 samples from the data for each tree
# fit <- SDForest(x = X, y = Y, max_size = 500)

