#' Near Presence Analysis
#'
#' Performs Near Presence analysis and generates a variety of descriptive
#' results
#'
#' Near presence analysis identifies clustering in irregularly distributed,
#' areal tracts with presence / absence attribute data. Presence / absence data,
#' coded as 1 and 0 respectively, are drawn from the fields in \code{chron}
#' specified in \code{periods}. Every tract's near presence (NP) score is the
#' average of these presence / absence values in its n nearest neighbors,
#' weighted by their distance, as defined in the spatial weights list
#' (\code{swl}) generated by \code{IDW_nnear}. The significance of these scores
#' is calculated using a permutation test. Because an abundance of either
#' presence or absence results in many ties, high and low significance are
#' calculated separately: When most NP scores generated from permuted data are
#' lower than the observed NP score that score is considered high, and when most
#' permuted NP scores are greater than the observed NP score it is considered
#' low. "Most" is defined by multiplying \code{perms} by \code{cut}. This
#' qualitative data can then be combined with presence / absence data to
#' visualize clustering. \cr The output of this function is a \code{sf} object
#' with the same geometry as \code{tracts} and attributes reporting six
#' different results, named using the character strings in \code{periods}:
#' \itemize{ \item period: presence / absence data \item period_Res: Descriptive
#' result of NP analysis easily visualized in mapping software. Consists of
#' combinations of "Present" or "Absent" and "High NP", "Moderate NP", or "Low
#' NP" \item period_NP: Numeric observed NP score \item period_PGr: Count of NP
#' scores from permutation tests greater than observed NP \item period_PLs:
#' Count of NP scores from permutation tests less than observed NP \item
#' period_mem: Logical indication of whether a tract forms part of a cluster,
#' i.e., X_Res == "Present, High NP" OR neighboring tract == "Present, High NP"
#' }
#'
#' @export
#' @param chron A dataframe containing an ID field and one or more fields with
#'   binary data (1 or 0) indicating presence and absence
#' @param chron_ID Character, the name of the ID field in \code{chron}
#' @param periods Character vector, the names of the binary presence/absence
#'   fields in \code{chron}
#' @param tracts A spatial object of class \code{sf}
#' @param tracts_ID Character, the name of the ID field in \code{tracts}
#'   corresponding to \code{chron_ID}
#' @param swl List of spatial weights with names corresponding to
#'   \code{tracts_ID} and \code{chron_ID}. Output of IDW_nnear or IDW_radius
#' @param perms Positive integer, the number of permutations
#' @param cut Number < 1, the cutoff value for significance
#' @return Returns an object of class \code{sf} containing an ID field and six
#'   fields describing the results of the near presence analysis (see Details)
#' @seealso \code{\link{IDW_nnear}}, \code{\link{IDW_radius}}
#' @author Eli Weaverdyck \email{eweaverdyck@@gmail.com}
#' @examples
#' # With nearest neighbor distance weighting
#' NP(chron = chron,
#'   chron_ID = "Survey_Uni",
#'   periods = c("Clas", "Hell", "Cl_He", "ER", "MR", "LR", "LR_EB"),
#'   tracts = tracts,
#'   tracts_ID = "UnitID",
#'   swl = IDW_nnear(tracts = tracts, tracts_ID = "UnitID", n = 8),
#'   perms = 100,
#'   cut = 0.05)
#'
#' # With threshold radius distance weighting
#' NP(chron = chron,
#'   chron_ID = "Survey_Uni",
#'   periods = c("Clas", "Hell", "Cl_He", "ER", "MR", "LR", "LR_EB"),
#'   tracts = tracts,
#'   tracts_ID = "UnitID",
#'   swl = IDW_radius(tracts = tracts, tracts_ID = "UnitID", r = 500),
#'   perms = 100,
#'   cut = 0.05)

NP<-function(chron, chron_ID, periods, tracts, tracts_ID, swl, perms, cut){
  checkmate::assert_data_frame(chron)
  checkmate::assert_names(chron_ID, subset.of = names(chron))
  checkmate::assert_names(periods, subset.of = names(chron))
  checkmate::assert_class(tracts, "sf")
  checkmate::assert_names(tracts_ID, subset.of = names(tracts))
  checkmate::assert_list(swl)
  checkmate::assert_count(perms)
  checkmate::assert_number(cut, upper = 1)

  u<-sf::st_drop_geometry(tracts)[,tracts_ID] # character vector with tract IDs
  n<-length(sf::st_drop_geometry(tracts)[,tracts_ID]) # number of tracts
  NP.results<-tracts
  row.names(chron)<-chron[,chron_ID]
  chron<-chron[which(chron[,chron_ID] %in% u),]
  for (p in periods){
    print(p)
    print("Calculating observed NP")

    #observed near presence
    obs.np<-list()
    length(obs.np)<-n
    names(obs.np)<-u
    data<-chron[,c(chron_ID, p)]
    #names(data)<-chron[,chron_ID]
    obs.np<-lapply(swl, FUN=function(x) mean(data[match(names(x),data[,chron_ID]),p]*x))

    # Permutations
    print("Calculating permuted NPs")
    progress_bar = utils::txtProgressBar(min=0, max=perms, style=1, char="=")
    perm.np<-data.frame(matrix(nrow=n, ncol=perms))
    row.names(perm.np)<-u
    for(v in 1:perms){
      utils::setTxtProgressBar(progress_bar, value=v)
      data[,p]<-sample(as.vector(chron[,p]), size = n)
      perm.np[,v]<-unlist(lapply(swl, FUN=function(x) mean(data[match(names(x),data[,chron_ID]),p]*x)))
    }
    # Results
    print("Compiling results")
    all.np<-merge(unlist(obs.np), perm.np, by=0)
    row.names(all.np)<-all.np$Row.names
    perm.great<-apply(X=all.np[grep("X",names(all.np))]>all.np$x, MARGIN=1, FUN=sum)
    perm.less<-apply(X=all.np[grep("X",names(all.np))]<all.np$x, MARGIN=1, FUN=sum)
    Hi.NP<-perm.less>perms-(cut*perms)
    Lo.NP<-perm.great>perms-(cut*perms)
    HiLo.NP<-merge(Hi.NP,Lo.NP,by=0)
    colnames(HiLo.NP)<-c(tracts_ID, "HiNP","LoNP")
    chron.HiLo.NP<-merge(chron[,c(chron_ID, p)], HiLo.NP, by.x=chron_ID, by.y=tracts_ID)
    chron.HiLo.NP[,paste(p,"_Res",sep="")]<-ifelse(
      chron.HiLo.NP[,p]==1 & chron.HiLo.NP$HiNP==TRUE,
      "Present, High NP",
      ifelse(chron.HiLo.NP[,p]==1 & chron.HiLo.NP$HiNP==FALSE & chron.HiLo.NP$LoNP==FALSE,
             "Present, Moderate NP",
             ifelse(chron.HiLo.NP[,p]==1 & chron.HiLo.NP$LoNP==TRUE,
                    "Present, Low NP",
                    ifelse(chron.HiLo.NP[,p]==0 & chron.HiLo.NP$HiNP==TRUE,
                           "Absent, High NP",
                           ifelse(chron.HiLo.NP[,p]==0 & chron.HiLo.NP$HiNP==FALSE & chron.HiLo.NP$LoNP==FALSE,
                                  "Absent, Moderate NP",
                                  ifelse(chron.HiLo.NP[,p]==0 & chron.HiLo.NP$LoNP==TRUE,
                                         "Absent, Low NP","ERROR")))))
    )

    chron.HiLo.NP<-merge(chron.HiLo.NP, unlist(obs.np), by.x=chron_ID, by.y=0)
    names(chron.HiLo.NP)[names(chron.HiLo.NP)=="y"] <- paste(p, "_NP", sep="")
    ranks<-merge(perm.great, perm.less, by=0)
    names(ranks)<-c(chron_ID, paste(p, "_PGr", sep=""), paste(p, "_PLs", sep=""))
    chron.HiLo.NP<-merge(chron.HiLo.NP, ranks)
    cores<-chron.HiLo.NP[chron.HiLo.NP[,paste(p, "_Res", sep="")] == "Present, High NP", chron_ID]
    near.core<-unlist(lapply(swl, FUN=function(x) any(names(x) %in% cores)))
    near.core<-merge(near.core, chron[,c(chron_ID,p)], by.x=0, by.y=chron_ID)
    near.core[paste(p,"_mem",sep="")]<-near.core[,p]==1 & near.core$x
    chron.HiLo.NP<-merge(chron.HiLo.NP, near.core[c("Row.names",paste(p,"_mem",sep=""))], by.x=chron_ID, by.y="Row.names")
    row.names(chron.HiLo.NP)<-chron.HiLo.NP[,chron_ID]
    NP.results<-merge(NP.results, chron.HiLo.NP[, grep(p, names(chron.HiLo.NP))], by.x=tracts_ID, by.y=0)
  }
  return(NP.results)
}
