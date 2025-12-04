## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----core, eval=FALSE---------------------------------------------------------
# # fits the individual SDTrees in parallel on 22 cores
# fit <- SDForest(x = X, y = Y, mc.cores = 22)
# 
# # performs cross validation in parallel
# model <- SDAM(X, Y, cv_k = 5, mc.cores = 5)

## ----candidates, eval=FALSE---------------------------------------------------
# # approximation of candidate splits
# fit <- SDForest(x = X, y = Y, max_candidates = 100)
# tree <- SDTree(x = X, y = Y, max_candidates = 50)

## ----subsample, eval=FALSE----------------------------------------------------
# # draws maximal 500 samples from the data for each tree
# fit <- SDForest(x = X, y = Y, max_size = 500)

