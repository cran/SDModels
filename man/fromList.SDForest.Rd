% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/List.R
\name{fromList.SDForest}
\alias{fromList.SDForest}
\alias{fromList}
\title{SDForest fromList method}
\usage{
\method{fromList}{SDForest}(object, ...)
}
\arguments{
\item{object}{an SDForest object with the trees in list format}

\item{...}{Further arguments passed to or from other methods.}
}
\value{
an SDForest object with the trees in Node format
}
\description{
Converts the trees in an SDForest object from
class \code{list} to class \code{Node} \insertCite{Glur2023Data.tree:Structure}{SDModels}.
}
\examples{
set.seed(1)
n <- 10
X <- matrix(rnorm(n * 5), nrow = n)
y <- sign(X[, 1]) * 3 + rnorm(n)
model <- SDForest(x = X, y = y, Q_type = 'no_deconfounding', cp = 0.5, nTree = 2)
fromList(toList(model))
}
\references{
\insertAllCited{}
}
\seealso{
\code{\link{fromList}} \code{\link{fromList.SDTree}}
}
\author{
Markus Ulmer
}
