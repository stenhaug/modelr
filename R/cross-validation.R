#' Generate cross-validated test-training pairs
#'
#' `crossv_kfold` splits the data into `k` exclusive partitions,
#' and uses each partition for a test-training split. `crossv_mc`
#' generates `n` random partitions, holding out `p` of the
#' data for training.
#'
#' @inheritParams resample_partition
#' @param n Number of test-training pairs to generate (an integer).
#' @param test Proportion of observations that should be held out for testing
#'   (a double).
#' @param id Name of variable that gives each model a unique integer id.
#' @return A data frame with `n`/`k` rows and columns `test` and
#'   `train`. `test` and `train` are list-columns containing
#'   [resample()] objects.
#' @export
#' @examples
#' cv1 <- crossv_kfold(mtcars, 5)
#' cv1
#'
#' library(purrr)
#' cv2 <- crossv_mc(mtcars, 100)
#' models <- map(cv2$train, ~ lm(mpg ~ wt, data = .))
#' errs <- map2_dbl(models, cv2$test, rmse)
#' hist(errs)
crossv_mc <- function(data, n, test = 0.2, id = ".id") {
  if (!is.numeric(n) || length(n) != 1) {
    stop("`n` must be a single integer.", call. = FALSE)
  }
  if (!is.numeric(test) || length(test) != 1 || test <= 0 || test >= 1) {
    stop("`test` must be a value between 0 and 1.", call. = FALSE)
  }

  p <- c(train = 1 - test, test = test)
  runs <- purrr::rerun(n, resample_partition(data, p))
  cols <- purrr::transpose(runs)
  cols[[id]] <- id(n)

  tibble::as_data_frame(cols)
}

#' @export
#' @param k Number of folds (an integer).
#' @rdname crossv_mc
crossv_kfold <- function(data, k = 5, id = ".id") {
  if (!is.numeric(k) || length(k) != 1) {
    stop("`k` must be a single integer.", call. = FALSE)
  }

  n <- nrow(data)
  folds <- sample(rep(1:k, length.out = n))

  idx <- seq_len(n)
  fold_idx <- split(idx, folds)

  fold <- function(test) {
    list(
      train = resample(data, setdiff(idx, test)),
      test = resample(data, test)
    )
  }

  cols <- purrr::transpose(purrr::map(fold_idx, fold))
  cols[[id]] <- id(k)

  tibble::as_data_frame(cols)
}
