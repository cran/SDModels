#' Spectrally Deconfounded Tree
#' 
#' Estimates a regression tree using spectral deconfounding. 
#' A regression tree is part of the function class of step functions
#' \eqn{f(X) = \sum_{m = 1}^M 1_{\{X \in R_m\}} c_m}, where (\eqn{R_m}) with 
#' \eqn{m = 1, \ldots, M} are regions dividing the space of \eqn{\mathbb{R}^p} 
#' into \eqn{M} rectangular parts. Each region has response level \eqn{c_m \in \mathbb{R}}.
#' For the training data, we can write the step function as \eqn{f(\mathbf{X}) = \mathcal{P} c} 
#' where \eqn{\mathcal{P} \in \{0, 1\}^{n \times M}} is an indicator matrix encoding 
#' to which region an observation belongs and \eqn{c \in \mathbb{R}^M} is a vector 
#' containing the levels corresponding to the different regions. This function then minimizes
#' \deqn{(\hat{\mathcal{P}}, \hat{c}) = \text{argmin}_{\mathcal{P}' \in \{0, 1\}^{n \times M}, c' \in \mathbb{R}^ {M}} \frac{||Q(\mathbf{Y} - \mathcal{P'} c')||_2^2}{n}}
#' We find \eqn{\hat{\mathcal{P}}} by using the tree structure and repeated splitting of the leaves, 
#' similar to the original cart algorithm \insertCite{Breiman2017ClassificationTrees}{SDModels}.
#' Since comparing all possibilities for \eqn{\mathcal{P}} is impossible, we let a tree grow greedily. 
#' Given the current tree, we iterate over all leaves and all possible splits. 
#' We choose the one that reduces the spectral loss the most and estimate after each split 
#' all the leave estimates
#' \eqn{\hat{c} = \text{argmin}_{c' \in \mathbb{R}^M} \frac{||Q\mathbf{Y} - Q\mathcal{P} c'||_2^2}{n}} 
#' which is just a linear regression problem. This is repeated until the loss decreases 
#' less than a minimum loss decrease after a split. 
#' The minimum loss decrease equals a cost-complexity parameter \eqn{cp} times 
#' the initial loss when only an overall mean is estimated. 
#' The cost-complexity parameter \eqn{cp} controls the complexity of a regression tree 
#' and acts as a regularization parameter.
#' @references
#'  \insertAllCited{}
#' @author Markus Ulmer
#' @param formula Object of class \code{formula} or describing the model to fit 
#' of the form \code{y ~ x1 + x2 + ...} where \code{y} is a numeric response and 
#' \code{x1, x2, ...} are vectors of covariates. Interactions are not supported.
#' @param data Training data of class \code{data.frame} containing the variables in the model.
#' @param x Matrix of covariates, alternative to \code{formula} and \code{data}.
#' @param y Vector of responses, alternative to \code{formula} and \code{data}.
#' @param max_leaves Maximum number of leaves for the grown tree.
#' @param cp Complexity parameter, minimum loss decrease to split a node. 
#' A split is only performed if the loss decrease is larger than \code{cp * initial_loss}, 
#' where \code{initial_loss} is the loss of the initial estimate using only a stump.
#' @param min_sample Minimum number of observations per leaf. 
#' A split is only performed if both resulting leaves have at least 
#' \code{min_sample} observations.
#' @param mtry Number of randomly selected covariates to consider for a split, 
#' if \code{NULL} all covariates are available for each split.
#' @param fast If \code{TRUE}, only the optimal splits in the new leaves are 
#' evaluated and the previously optimal splits and their potential loss-decrease are reused. 
#' If \code{FALSE} all possible splits in all the leaves are reevaluated after every split.
#' @param Q_type Type of deconfounding, one of 'trim', 'pca', 'no_deconfounding'. 
#' 'trim' corresponds to the Trim transform \insertCite{Cevid2020SpectralModels}{SDModels} 
#' as implemented in the Doubly debiased lasso \insertCite{Guo2022DoublyConfounding}{SDModels}, 
#' 'pca' to the PCA transformation\insertCite{Paul2008PreconditioningProblems}{SDModels}. 
#' See \code{\link{get_Q}}.
#' @param trim_quantile Quantile for Trim transform, 
#' only needed for trim, see \code{\link{get_Q}}.
#' @param q_hat Assumed confounding dimension, only needed for pca, 
#' see \code{\link{get_Q}}.
#' @param Qf Spectral transformation, if \code{NULL} 
#' it is internally estimated using \code{\link{get_Q}}.
#' @param A Numerical Anchor of class \code{matrix}. See \code{\link{get_W}}.
#' @param gamma Strength of distributional robustness, \eqn{\gamma \in [0, \infty]}. 
#' See \code{\link{get_W}}.
#' @param gpu If \code{TRUE}, the calculations are performed on the GPU. 
#' If it is properly set up.
#' @param mem_size Amount of split candidates that can be evaluated at once.
#' This is a trade-off between memory and speed can be decreased if either
#' the memory is not sufficient or the gpu is to small.
#' @param max_candidates Maximum number of split points that are 
#' proposed at each node for each covariate.
#' @param Q_scale Should data be scaled to estimate the spectral transformation? 
#' Default is \code{TRUE} to not reduce the signal of high variance covariates, 
#' and we do not know of a scenario where this hurts.
#' @param predictors Subset of colnames(X) or numerical indices of the covariates 
#' for which an effect on y should be estimated. All the other covariates are only
#' used for deconfounding.
#' @return Object of class \code{SDTree} containing
#' \item{predictions}{Predictions for the training set.}
#' \item{tree}{The estimated tree of class \code{Node} from \insertCite{Glur2023Data.tree:Structure}{SDModels}. 
#' The tree contains the information about all the splits and the resulting estimates.}
#' \item{var_names}{Names of the covariates in the training data.}
#' \item{var_importance}{Variable importance of the covariates. 
#' The variable importance is calculated as the sum of the decrease in the loss 
#' function resulting from all splits that use this covariate.}
#' @seealso \code{\link{simulate_data_nonlinear}}, \code{\link{regPath.SDTree}}, 
#' \code{\link{prune.SDTree}}, \code{\link{partDependence}}
#' @examples
#' set.seed(1)
#' n <- 10
#' X <- matrix(rnorm(n * 5), nrow = n)
#' y <- sign(X[, 1]) * 3 + rnorm(n)
#' model <- SDTree(x = X, y = y, cp = 0.5)
#' 
#' ###### subset of predictors
#' # if we know, that only the first covariate has an effect on y,
#' # we can estimate only its effect and use the others just for deconfounding
#' model <- SDTree(x = X, y = y, cp = 0.5, predictors = c(1))
#' 
#' \donttest{
#' set.seed(42)
#' # simulation of confounded data
#' sim_data <- simulate_data_step(q = 2, p = 15, n = 100, m = 2)
#' X <- sim_data$X
#' Y <- sim_data$Y
#' train_data <- data.frame(X, Y)
#' # causal parents of y
#' sim_data$j
#' 
#' tree_plain_cv <- cvSDTree(Y ~ ., train_data, Q_type = "no_deconfounding")
#' tree_plain <- SDTree(Y ~ ., train_data, Q_type = "no_deconfounding", cp = 0)
#' 
#' tree_causal_cv <- cvSDTree(Y ~ ., train_data)
#' tree_causal <- SDTree(y = Y, x = X, cp = 0)
#' 
#' # check regularization path of variable importance
#' path <- regPath(tree_causal)
#' plot(path)
#' 
#' tree_plain <- prune(tree_plain, cp = tree_plain_cv$cp_min)
#' tree_causal <- prune(tree_causal, cp = tree_causal_cv$cp_min)
#' plot(tree_causal)
#' plot(tree_plain)
#' }
#' @export
SDTree <- function(formula = NULL, data = NULL, x = NULL, y = NULL, max_leaves = NULL, 
                   cp = 0.01, min_sample = 5, mtry = NULL, fast = TRUE,
                   Q_type = 'trim', trim_quantile = 0.5, q_hat = 0, Qf = NULL, 
                   A = NULL, gamma = 0.5, gpu = FALSE, mem_size = 1e+7, max_candidates = 100, 
                   Q_scale = TRUE, predictors = NULL){
  if(gpu) ifelse(GPUmatrix::installTorch(), 
                 gpu_type <- 'torch', 
                 gpu_type <- 'tensorflow')
  
  input_data <- data.handler(formula = formula, data = data, x = x, y = y)
  X <- input_data$X
  Y <- input_data$Y

  # number of observations
  n <- nrow(X)

  if(is.null(max_leaves)) max_leaves <- n

  max_leaves <- max_leaves - 1

  mem_size <- mem_size / n
  # check validity of input
  if(n != length(Y)) stop('X and Y must have the same number of observations')
  if(max_leaves < 0) stop('max_leaves must be larger than 1')
  if(min_sample < 1) stop('min_sample must be larger than 0')
  if(cp < 0) stop('cp must be at least 0')
  if(!is.null(mtry) && mtry < 1) stop('mtry must be larger than 0')
  if(n < 2 * min_sample) stop('n must be at least 2 * min_sample')
  if(max_candidates < 1) stop('max_candidates must be at least 1')

  # estimate spectral transformation

  if(!is.null(A)){
    if(is.null(gamma)) stop('gamma must be provided if A is provided')
    if(is.vector(A)) A <- matrix(A)
    if(!is.matrix(A)) stop('A must be a matrix')
    if(nrow(A) != n) stop('A must have n rows')
    Wf <- get_Wf(A, gamma, gpu)
  }else {
    Wf <- function(v) v
  }

  if(is.null(Qf)){
    if(!is.null(A)){
      Qf <- function(v) get_Qf(Wf(X), Q_type, trim_quantile, q_hat, gpu, Q_scale)(Wf(v))
    }else{
      Qf <- get_Qf(X, Q_type, trim_quantile, q_hat, gpu, Q_scale)
    }
  }else{
    if(!is.function(Qf)) stop('Q must be a function')
    if(length(Qf(rnorm(n))) == n) stop('Q must map from n to n')
  }
  
  #selection of predictors
  if(!is.null(predictors)){
    if(is.character(predictors)){
      if(!all(predictors %in% colnames(X)))
        stop("predictors must either be numeric columne index or in colnames of X")
      predictors <- which(colnames(X) %in% predictors)
    }
    if(is.numeric(predictors)){
      if(!all(predictors > 0 & predictors <= ncol(X)))
        stop("predictors must either be numeric columne index or in colnames of X")
    }
    pred_names <- colnames(X)
    X <- matrix(X[, predictors], ncol = length(predictors))
    if(!is.null(pred_names)){
      colnames(X) <- pred_names[predictors]
    }
  }
  
  # number of covariates
  p <- ncol(X)
  
  if(!is.null(mtry) && mtry > p) stop('mtry must be at most p')

  # calculate first estimate
  E <- matrix(1, n, 1)
  E_tilde <- Qf(E)

  if(gpu){
    E_tilde <- gpu.matrix(E_tilde, type = gpu_type)
  }

  Ue <- E_tilde / sqrt(sum(E_tilde ** 2))
  Y_tilde <- Qf(Y)

  # solve linear model
  if(gpu && gpu_type == 'tensorflow'){
    c_hat <- lm.fit(as.matrix(E_tilde), as.matrix(Y_tilde))$coefficients
  }else{
    c_hat <- qr.coef(qr(E_tilde), Y_tilde)
    c_hat <- as.numeric(c_hat)
  }

  loss_start <- as.numeric(sum((Y_tilde - c_hat) ** 2) / n)
  loss_temp <- loss_start

  # initialize tree
  tree <- data.tree::Node$new(name = '1', value = as.numeric(c_hat), 
                              dloss = as.numeric(loss_start), 
                              cp = 10, n_samples = n)

  # memory for optimal splits
  memory <- list()
  potential_splits <- 1

  # variable importance
  var_imp <- rep(0, p)
  names(var_imp) <- colnames(X)

  after_mtry <- 0

  for(i in 1:max_leaves){
    # iterate over all possible splits every time
    # for slow but slightly better solution
    if(!fast){
      potential_splits <- 1:i
      to_small <- sapply(potential_splits, 
                         function(x){sum(E[, x]) < min_sample*2})
      potential_splits <- potential_splits[!to_small]
    }
    
    #iterate over new to estimate splits
    for(branch in potential_splits){
      E_branch <- E[, branch]
      index <- which(E_branch == 1)
      X_branch <- matrix(X[index, ], nrow = length(index))

      s <- find_s(X_branch, max_candidates = max_candidates)
      n_splits <- nrow(s)

      if(min_sample > 1) {
        s <- s[-c(0:(min_sample - 1), (n_splits - min_sample + 2):(n_splits+1)), ]
      }
      s <- matrix(s, ncol = p)

      all_n_splits <- apply(s, 2, function(x) length(unique(x)))
      all_idx <- cumsum(all_n_splits)

      eval <- matrix(-Inf, nrow(s), p)
      done_splits <- 0
      p_top <- 0
      while(p_top < p){
        c_all_idx <- all_idx - done_splits
        p_low <- p_top + 1
        possible <- which(c_all_idx < mem_size)
        p_top <- possible[length(possible)]

        c_n_splits <- sum(all_idx[p_top], -all_idx[p_low-1])
        E_next <- matrix(0, n, c_n_splits)
        for(j in p_low:p_top){
          s_j <- s[, j]
          s_j <- unique(s_j)
          for(i_s in 1:all_n_splits[j]){
            E_next[index[X_branch[, j] > s_j[i_s]], sum(c_all_idx[j-1], i_s)] <- 1
          }
        }
        if(gpu) E_next <- gpu.matrix(E_next, type = gpu_type)

        U_next_prime <- Qf_temp(E_next, Ue, Qf)
        U_next_size <- colSums(U_next_prime ** 2)
        dloss <- as.numeric(crossprod(U_next_prime, Y_tilde))**2 / U_next_size
        dloss[is.na(dloss)] <- 0
        
        for(m in p_low:p_top){
          eval[1:all_n_splits[m], m] <- dloss[sum(c_all_idx[m-1], 1):c_all_idx[m]]
        }
        done_splits <- done_splits + c_n_splits
      }
      is_opt <- apply(eval, 2, which.max)
      memory[[branch]] <- t(sapply(1:p, function(j) 
        c(eval[is_opt[j], j], j, unique(s[, j])[is_opt[j]], branch)))
    }

    if(i > after_mtry && !is.null(mtry)){
      Losses_dec <- lapply(memory, function(branch){
        branch[sample(1:p, mtry), ]})
      Losses_dec <- do.call(rbind, Losses_dec)
    }else {
       Losses_dec <- do.call(rbind, memory)
    }

    loc <- which.max(Losses_dec[, 1])
    best_branch <- Losses_dec[loc, 4]
    j <- Losses_dec[loc, 2]
    s <- Losses_dec[loc, 3]

    if(Losses_dec[loc, 1] <= 0){
      break
    }
    
    # divide observations in leave
    index <- which(E[, best_branch] == 1)
    index_n_branches <- index[X[index, j] > s]
    
    # new indicator matrix
    E <- cbind(E, matrix(0, n, 1))
    E[index_n_branches, best_branch] <- 0
    E[index_n_branches, i+1] <- 1

    E_tilde_branch <- E_tilde[, best_branch]
    suppressWarnings({
      E_tilde[, best_branch] <- Qf(E[, best_branch])
    })
    E_tilde <- cbind(E_tilde, matrix(E_tilde_branch - E_tilde[, best_branch]))

    if(gpu && gpu_type == 'tensorflow'){
      c_hat <- lm.fit(as.matrix(E_tilde), as.matrix(Y_tilde))$coefficients
    }else{
      c_hat <- qr.coef(qr(E_tilde), Y_tilde)
    }

    u_next_prime <- Qf_temp(E[, i + 1], Ue, Qf)
    Ue <- cbind(Ue, u_next_prime / sqrt(sum(u_next_prime ** 2)))
    
    # check if loss decrease is larger than minimum loss decrease
    # and if linear model could be estimated
    if(sum(is.na(as.matrix(c_hat))) > 0){
      warning('singulaer matrix QE, tree might be to large, consider increasing cp')
      break
    }

    loss_dec <- as.numeric(loss_temp - loss(Y_tilde, E_tilde %*% c_hat))
    loss_temp <- loss_temp - loss_dec

    if(loss_dec <= cp * loss_start){
      break
    }
    # add loss decrease to variable importance
    var_imp[j] <- var_imp[j] + loss_dec

    # select leave to split
    if(tree$height == 1){
      leave <- tree
    }else{
      leaves <- tree$leaves
      leave <- leaves[[which(tree$Get('name', filterFun = data.tree::isLeaf) == best_branch)]]
    }

    # save split rule
    leave$j <- j
    leave$s <- s

    leave$res_dloss <- loss_dec

    # add new leaves
    leave$AddChild(best_branch, value = 0, dloss = loss_dec, 
                   cp = loss_dec / loss_start, decision = 'yes', 
                   n_samples = sum(E[, best_branch] == 1))
    leave$AddChild(i + 1, value = 0, dloss = loss_dec, 
                   cp = loss_dec / loss_start, decision = 'no', 
                   n_samples = sum(E[, i + 1] == 1))

    # add estimates to tree leaves
    c_hat <- as.numeric(c_hat)
    for(l in tree$leaves){
      l$value <- c_hat[as.numeric(l$name)]
    }

    # the two new partitions need to be checked for optimal splits in next iteration
    potential_splits <- c(best_branch, i + 1)

    # a partition with less than min_sample observations or unique samples 
    # are not available for further splits
    to_small <- sapply(potential_splits, function(x){
      new_samples <- nrow(unique(matrix(X[as.logical(E[, x]),], nrow = sum(E[, x]))))
      if(is.null(new_samples)) new_samples <- 0
      (new_samples < min_sample * 2)
      })
    if(sum(to_small) > 0){
      for(el in potential_splits[to_small]){
        # to small partitions cannot decrease the loss
        memory[[el]] <- matrix(0, p, 4)
      }
      potential_splits <- potential_splits[!to_small]
    }
  }

  if(i == max_leaves){
    warning('maximum number of iterations was reached, consider increasing m!')
  }

  # predict the test set
  f_X_hat <- predict_outsample(tree, X)

  var_names <- colnames(data.frame(X))
  names(var_imp) <- var_names

  # labels for the nodes
  tree$Do(split_names, filterFun = data.tree::isNotLeaf, var_names = var_names)
  tree$Do(leave_names, filterFun = data.tree::isLeaf)

  # cp max of all splits after
  tree$Do(function(node) node$cp_max <- max(node$Get('cp')))
  tree$Do(function(node) {
    cp_max <- data.tree::Aggregate(node, 'cp_max', max)
    node$children[[1]]$cp_max <- cp_max
    node$children[[2]]$cp_max <- cp_max
    }, filterFun = data.tree::isNotLeaf
  )

  res <- list(predictions = f_X_hat, tree = tree, 
              var_names = var_names, var_importance = var_imp)
  class(res) <- 'SDTree'
  res
}