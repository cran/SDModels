% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/print.R
\name{print.SDAM}
\alias{print.SDAM}
\title{Print SDAM}
\usage{
\method{print}{SDAM}(x, ...)
}
\arguments{
\item{x}{Fitted object of class \code{SDAM}.}

\item{...}{Further arguments passed to or from other methods.}
}
\value{
No return value, called for side effects
}
\description{
Print number of covariates and number of active covariates for SDAM object.
}
\examples{

set.seed(1)
X <- matrix(rnorm(10 * 5), ncol = 5)
Y <- sin(X[, 1]) -  X[, 2] + rnorm(10)
model <- SDAM(x = X, y = Y, Q_type = "trim", trim_quantile = 0.5, nfold = 2, n_K = 1)
print(model)
}
\seealso{
\code{\link{SDAM}}
}
\author{
Cyrill Scheidegger
}
