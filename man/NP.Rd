% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/np.R
\name{NP}
\alias{NP}
\title{Near Presence Analysis}
\usage{
NP(chron, chron_ID, periods, tracts, tracts_ID, swl, perms, cut)
}
\arguments{
\item{chron}{A dataframe containing an ID field and one or more fields with
binary data (1 or 0) indicating presence and absence}

\item{chron_ID}{Character, the name of the ID field in \code{chron}}

\item{periods}{Character vector, the names of the binary presence/absence
fields in \code{chron}}

\item{tracts}{A spatial object of class \code{sf}}

\item{tracts_ID}{Character, the name of the ID field in \code{tracts}
corresponding to \code{chron_ID}}

\item{swl}{List of spatial weights with names corresponding to
\code{tracts_ID} and \code{chron_ID}. Output of IDW_nnear or IDW_radius}

\item{perms}{Positive integer, the number of permutations}

\item{cut}{Number < 1, the cutoff value for significance}
}
\value{
Returns an object of class \code{sf} containing an ID field and six
fields describing the results of the near presence analysis (see Details)
}
\description{
Performs Near Presence analysis and generates a variety of descriptive
results
}
\details{
Near presence analysis identifies clustering in irregularly distributed,
areal tracts with presence / absence attribute data. Presence / absence data,
coded as 1 and 0 respectively, are drawn from the fields in \code{chron}
specified in \code{periods}. Every tract's near presence (NP) score is the
average of these presence / absence values in its n nearest neighbors,
weighted by their distance, as defined in the spatial weights list
(\code{swl}) generated by \code{IDW_nnear}. The significance of these scores
is calculated using a permutation test. Because an abundance of either
presence or absence results in many ties, high and low significance are
calculated separately: When most NP scores generated from permuted data are
lower than the observed NP score that score is considered high, and when most
permuted NP scores are greater than the observed NP score it is considered
low. "Most" is defined by multiplying \code{perms} by \code{cut}. This
qualitative data can then be combined with presence / absence data to
visualize clustering. \cr The output of this function is a \code{sf} object
with the same geometry as \code{tracts} and attributes reporting six
different results, named using the character strings in \code{periods}:
\itemize{ \item period: presence / absence data \item period_Res: Descriptive
result of NP analysis easily visualized in mapping software. Consists of
combinations of "Present" or "Absent" and "High NP", "Moderate NP", or "Low
NP" \item period_NP: Numeric observed NP score \item period_PGr: Count of NP
scores from permutation tests greater than observed NP \item period_PLs:
Count of NP scores from permutation tests less than observed NP \item
period_mem: Logical indication of whether a tract forms part of a cluster,
i.e., X_Res == "Present, High NP" OR neighboring tract == "Present, High NP"
}
}
\examples{
# With nearest neighbor distance weighting
NP(chron = chron,
  chron_ID = "Survey_Uni",
  periods = c("Clas", "Hell", "Cl_He", "ER", "MR", "LR", "LR_EB"),
  tracts = tracts,
  tracts_ID = "UnitID",
  swl = IDW_nnear(tracts = tracts, tracts_ID = "UnitID", n = 8),
  perms = 100,
  cut = 0.05)

# With threshold radius distance weighting
NP(chron = chron,
  chron_ID = "Survey_Uni",
  periods = c("Clas", "Hell", "Cl_He", "ER", "MR", "LR", "LR_EB"),
  tracts = tracts,
  tracts_ID = "UnitID",
  swl = IDW_radius(tracts = tracts, tracts_ID = "UnitID", r = 500),
  perms = 100,
  cut = 0.05)
}
\seealso{
\code{\link{IDW_nnear}}, \code{\link{IDW_radius}}
}
\author{
Eli Weaverdyck \email{eweaverdyck@gmail.com}
}
