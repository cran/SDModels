% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/partDependence.R
\name{partDependence}
\alias{partDependence}
\title{Partial dependence}
\usage{
partDependence(object, j, X = NULL, subSample = NULL, mc.cores = 1)
}
\arguments{
\item{object}{A model object that has a predict method that takes newdata as argument 
and returns predictions.}

\item{j}{The variable for which the partial dependence should be calculated.
Either the column index of the variable in the dataset or the name of the variable.}

\item{X}{The dataset on which the partial dependence should be calculated.
Should contain the same variables as the dataset used to train the model.
If NULL, tries to extract the dataset from the model object.}

\item{subSample}{Number of samples to draw from the original data for the empirical 
partial dependence. If NULL, all the observations are used.}

\item{mc.cores}{Number of cores to use for parallel computation. 
Parallel computing is only supported for unix.}
}
\value{
An object of class \code{partDependence} containing
\item{preds_mean}{The average prediction for each value of the variable of interest.}
\item{x_seq}{The sequence of values for the variable of interest.}
\item{preds}{The predictions for each value of the variable of interest for each observation.}
\item{j}{The name of the variable of interest.}
\item{xj}{The values of the variable of interest in the dataset.}
}
\description{
This function calculates the partial dependence of a model on a single variable.
For that predictions are made for all observations in the dataset while varying 
the value of the variable of interest. The overall partial effect is the average
of all predictions. \insertCite{Friedman2001GreedyMachine}{SDModels}
}
\examples{
set.seed(1)
x <- rnorm(100)
y <- sign(x) * 3 + rnorm(100)
model <- SDTree(x = x, y = y, Q_type = 'no_deconfounding')
pd <- partDependence(model, 1, X = x, subSample = 10)
plot(pd)
}
\references{
\insertAllCited{}
}
\seealso{
\code{\link{SDForest}}, \code{\link{SDTree}}
}
\author{
Markus Ulmer
}
