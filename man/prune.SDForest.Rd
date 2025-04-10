% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/prune.R
\name{prune.SDForest}
\alias{prune.SDForest}
\alias{prune}
\title{Prune an SDForest}
\usage{
\method{prune}{SDForest}(object, cp, X = NULL, Y = NULL, Q = NULL, pred = TRUE, ...)
}
\arguments{
\item{object}{an SDForest object}

\item{cp}{Complexity parameter, the higher the value the more nodes are pruned.}

\item{X}{The training data, if NULL the data from the forest object is used.}

\item{Y}{The training response variable, if NULL the data from the forest object is used.}

\item{Q}{The transformation function, if NULL the data from the forest object is used.}

\item{pred}{If TRUE the predictions are calculated, if FALSE only the out-of-bag statistics are calculated.
This can set to FALSE to save computation time if only the out-of-bag statistics are needed.}

\item{...}{Further arguments passed to or from other methods.}
}
\value{
A pruned SDForest object
}
\description{
Prunes all trees in the forest and re-calculates the out-of-bag predictions and performance measures.
The training data is needed to calculate the out-of-bag statistics. Note that the forest is pruned in place.
If you intend to keep the original forest, make a copy of it before pruning.
}
\examples{

set.seed(1)
X <- matrix(rnorm(10 * 20), nrow = 10)
Y <- rnorm(10)
fit <- SDForest(x = X, y = Y, nTree = 2)
pruned_fit <- prune(copy(fit), 0.2)
}
\seealso{
\code{\link{copy}} \code{\link{prune.SDTree}} \code{\link{regPath}}
}
\author{
Markus Ulmer
}
