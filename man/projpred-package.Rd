% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/projpred-package.R
\docType{package}
\name{projpred-package}
\alias{projpred}
\alias{projpred-package}
\title{Projection predictive feature selection}
\description{
The \R package \pkg{projpred} performs the projection predictive variable (or
"feature") selection for various regression models. We recommend to read the
\code{README} file (available with enhanced formatting
\href{https://mc-stan.org/projpred/}{online}) and the main vignette (\code{topic = "projpred"}, but also available
\href{https://mc-stan.org/projpred/articles/projpred.html}{online}) before
continuing here.

Throughout the whole package documentation, we use the term "submodel" for
all kinds of candidate models onto which the reference model is projected.
For custom reference models, the candidate models don't need to be actual
\emph{sub}models of the reference model, but in any case (even for custom
reference models), the candidate models are always actual \emph{sub}models of the
full \code{\link{formula}} used by the search procedure. In this regard, it is correct
to speak of \emph{sub}models, even in case of a custom reference model.

The following model type abbreviations will be used at multiple places
throughout the documentation: GLM (generalized linear model), GLMM
(generalized linear multilevel---or "mixed"---model), GAM (generalized
additive model), and GAMM (generalized additive multilevel---or
"mixed"---model). Note that the term "generalized" includes the Gaussian
family as well.

For the projection of the reference model onto a submodel, \pkg{projpred}
currently relies on the following functions (in other words, these are the
workhorse functions used by the default divergence minimizers):
\itemize{
\item Submodel without multilevel or additive terms:
\itemize{
\item For the traditional (or latent) projection (or the augmented-data
projection in case of the \code{\link[=binomial]{binomial()}} or \code{\link[brms:brmsfamily]{brms::bernoulli()}} family): An
internal C++ function which basically serves the same purpose as \code{\link[=lm]{lm()}}
for the \code{\link[=gaussian]{gaussian()}} family and \code{\link[=glm]{glm()}} for all other families.
\item For the augmented-data projection: \code{\link[MASS:polr]{MASS::polr()}} for the
\code{\link[brms:brmsfamily]{brms::cumulative()}} family or \code{\link[rstanarm:stan_polr]{rstanarm::stan_polr()}} fits,
\code{\link[nnet:multinom]{nnet::multinom()}} for the \code{\link[brms:brmsfamily]{brms::categorical()}} family.
}
\item Submodel with multilevel but no additive terms:
\itemize{
\item For the traditional (or latent) projection (or the augmented-data
projection in case of the \code{\link[=binomial]{binomial()}} or \code{\link[brms:brmsfamily]{brms::bernoulli()}} family):
\code{\link[lme4:lmer]{lme4::lmer()}} for the \code{\link[=gaussian]{gaussian()}} family, \code{\link[lme4:glmer]{lme4::glmer()}} for all other
families.
\item For the augmented-data projection: \code{\link[ordinal:clmm]{ordinal::clmm()}} for the
\code{\link[brms:brmsfamily]{brms::cumulative()}} family, \code{\link[mclogit:mblogit]{mclogit::mblogit()}} for the
\code{\link[brms:brmsfamily]{brms::categorical()}} family.
}
\item Submodel without multilevel but additive terms: \code{\link[mgcv:gam]{mgcv::gam()}}.
\item Submodel with multilevel and additive terms: \code{\link[gamm4:gamm4]{gamm4::gamm4()}}.
}

Setting the global option \code{projpred.extra_verbose} to \code{TRUE} will print out
which submodel \pkg{projpred} is currently projecting onto as well as (if
\code{method = "forward"} and \code{verbose = TRUE} in \code{\link[=varsel]{varsel()}} or \code{\link[=cv_varsel]{cv_varsel()}})
which submodel has been selected at those steps of the forward search for
which a percentage (of the maximum submodel size that the search is run up
to) is printed. In general, however, we cannot recommend setting this global
option to \code{TRUE} for \code{\link[=cv_varsel]{cv_varsel()}} with \code{validate_search = TRUE} (simply due
to the amount of information that will be printed, but also due to the
progress bar which will not work anymore as intended).

The projection of the reference model onto a submodel can be run in parallel
(across the projected draws). This is powered by the \pkg{foreach} package.
Thus, any parallel (or sequential) backend compatible with \pkg{foreach} can
be used, e.g., the backends from packages \pkg{doParallel}, \pkg{doMPI}, or
\pkg{doFuture}. Using the global option \code{projpred.prll_prj_trigger}, the
number of projected draws below which no parallelization is applied (even if
a parallel backend is registered) can be modified. Such a "trigger" threshold
exists because of the computational overhead of a parallelization which makes
the projection parallelization only useful for a sufficiently large number of
projected draws. By default, the projection parallelization is turned off,
which can also be achieved by supplying \code{Inf} (or \code{NULL}) to option
\code{projpred.prll_prj_trigger}. Note that we cannot recommend the projection
parallelization on Windows because in our experience, the parallelization
overhead is larger there, causing a parallel run to take longer than a
sequential run. Also note that the projection parallelization works well for
submodels which are GLMs (and hence also for the latent projection if the
submodel has no multilevel or additive predictor terms), but for all other
types of submodels, the fitted submodel objects are quite big, which---when
running in parallel---may lead to excessive memory usage which in turn may
crash the R session (on Unix systems, setting an appropriate memory limit via
\code{\link[unix:rlimit]{unix::rlimit_as()}} may avoid crashing the whole machine). Thus, we currently
cannot recommend parallelizing projections onto submodels which are GLMs (in
this context, the latent projection onto a submodel without multilevel and
without additive terms may be regarded as a projection onto a submodel which
is a GLM). However, for \code{\link[=cv_varsel]{cv_varsel()}}, there is also a \emph{CV} parallelization
(i.e., a parallelization of \pkg{projpred}'s cross-validation) which can be
activated via argument \code{parallel}.

In case of multilevel models, \pkg{projpred} offers two global options for
"integrating out" group-level effects: \code{projpred.mlvl_pred_new} and
\code{projpred.mlvl_proj_ref_new}. When setting \code{projpred.mlvl_pred_new} to \code{TRUE}
(default is \code{FALSE}), then at
\emph{prediction} time, \pkg{projpred} will treat group levels existing in the
training data as \emph{new} group levels, implying that their group-level effects
are drawn randomly from a (multivariate) Gaussian distribution. This concerns
both, the reference model and the (i.e., any) submodel. Furthermore, setting
\code{projpred.mlvl_pred_new} to \code{TRUE} causes \code{\link[=as.matrix.projection]{as.matrix.projection()}} and
\code{\link[=as_draws_matrix.projection]{as_draws_matrix.projection()}} to omit the projected group-level effects (for
the group levels from the original dataset). When setting
\code{projpred.mlvl_proj_ref_new} to \code{TRUE} (default is \code{FALSE}), then at
\emph{projection} time, the reference model's fitted values (that the submodels
fit to) will be computed by treating the group levels from the original
dataset as \emph{new} group levels, implying that their group-level effects will
be drawn randomly from a (multivariate) Gaussian distribution (as long as the
reference model is a multilevel model, which---for custom reference
models---does not need to be the case). This also affects the latent response
values for a latent projection correspondingly. Setting
\code{projpred.mlvl_pred_new} to \code{TRUE} makes sense, e.g., when the prediction
task is such that any group level will be treated as a new one. Typically,
setting \code{projpred.mlvl_proj_ref_new} to \code{TRUE} only makes sense when
\code{projpred.mlvl_pred_new} is already set to \code{TRUE}. In that case, the default
of \code{FALSE} for \code{projpred.mlvl_proj_ref_new} ensures that at projection time,
the submodels fit to the best possible fitted values from the reference
model, and setting \code{projpred.mlvl_proj_ref_new} to \code{TRUE} would make sense if
the group-level effects should be integrated out completely.

By setting the global option \code{projpred.run_gc} to \code{TRUE}, \pkg{projpred} will
call \code{\link[=gc]{gc()}} at some places (e.g., after each size that the forward search
passes through) to free up some memory. These \code{\link[=gc]{gc()}} calls are not always
necessary to reduce the peak memory usage, but they add runtime (hence the
default of \code{FALSE} for that global option).

Technical note: Most examples are not executed when called via \code{\link[=example]{example()}}.
To execute them, you have to copy and paste them manually to the console.
}
\section{Functions}{
\describe{
\item{\code{\link[=init_refmodel]{init_refmodel()}}, \code{\link[=get_refmodel]{get_refmodel()}}}{For setting up an object
containing information about the reference model, the submodels, and how
the projection should be carried out. Explicit calls to \code{\link[=init_refmodel]{init_refmodel()}}
and \code{\link[=get_refmodel]{get_refmodel()}} are only rarely needed.}
\item{\code{\link[=varsel]{varsel()}}, \code{\link[=cv_varsel]{cv_varsel()}}}{For running the \emph{search} part and the
\emph{evaluation} part for a projection predictive variable selection, possibly
with cross-validation (CV).}
\item{\code{\link[=summary.vsel]{summary.vsel()}}, \code{\link[=print.vsel]{print.vsel()}}, \code{\link[=plot.vsel]{plot.vsel()}},
\code{\link[=suggest_size.vsel]{suggest_size.vsel()}}, \code{\link[=ranking]{ranking()}}, \code{\link[=cv_proportions]{cv_proportions()}},
\code{\link[=plot.cv_proportions]{plot.cv_proportions()}}}{For post-processing the results from \code{\link[=varsel]{varsel()}}
and \code{\link[=cv_varsel]{cv_varsel()}}.}
\item{\code{\link[=project]{project()}}}{For projecting the reference model onto submodel(s).
Typically, this follows the variable selection, but it can also be applied
directly (without a variable selection).}
\item{\code{\link[=as.matrix.projection]{as.matrix.projection()}} and \code{\link[=as_draws_matrix.projection]{as_draws_matrix.projection()}}}{For
extracting projected parameter draws.}
\item{\code{\link[=proj_linpred]{proj_linpred()}}, \code{\link[=proj_predict]{proj_predict()}}}{For making predictions from a
submodel (after projecting the reference model onto it).}
}
}

\seealso{
Useful links:
\itemize{
  \item \url{https://mc-stan.org/projpred/}
  \item \url{https://discourse.mc-stan.org}
  \item Report bugs at \url{https://github.com/stan-dev/projpred/issues/}
}

}
\author{
\strong{Maintainer}: Frank Weber \email{fweber144@protonmail.com}

Authors:
\itemize{
  \item Juho Piironen \email{juho.t.piironen@gmail.com}
  \item Markus Paasiniemi
  \item Alejandro Catalina \email{alecatfel@gmail.com}
  \item Aki Vehtari
}

Other contributors:
\itemize{
  \item Jonah Gabry [contributor]
  \item Marco Colombo [contributor]
  \item Paul-Christian Bürkner [contributor]
  \item Hamada S. Badr [contributor]
  \item Brian Sullivan [contributor]
  \item Sölvi Rögnvaldsson [contributor]
  \item  The LME4 Authors (see file 'LICENSE' for details) [copyright holder]
  \item Yann McLatchie [contributor]
  \item Juho Timonen [contributor]
}

}
