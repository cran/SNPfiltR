#' Vizualise missing data per SNP, remove SNPs above a missing data cutoff
#'
#' This function can be run in two ways: 1) Without 'cutoff' specified. This will vizualise the
#' amount of missing data in each sample across a variety of potential missing data cutoffs.
#' Additionally, it will show you dotplots visualizing the number of total SNPs retained across
#' a variety of filtering cutoffs, and the total proportion of missing data.
#' Based on these visualizations, you can make an informed decision on what you think might be an
#' optimal cutoff to minimize the overall missingness of your dataset while still retaining an
#' appropriate amount of SNPs for the downstream inferences you hope to make 2) with 'cutoff'
#' specified. This option will show you the dotplots with the cutoff you set,
#' and then remove SNPs above the missing data cutoff.
#'
#' @param vcfR a vcfR object
#' @param cutoff a numeric value between 0-1 specifying the maximum proportion of missing data
#' allowed in a SNP to be retained for downstream analyses
#' @return if 'cutoff' is not specified, will return a dataframe containing the proportion
#' missing data and the total SNPs retained across each filtering level. If 'cutoff' is
#' specified, SNPs falling above the missing data cutoff will be removed,
#' and the filtered vcfR object will be returned.
#' @examples
#' missing_by_snp(vcfR = SNPfiltR::vcfR.example)
#' missing_by_snp(vcfR = SNPfiltR::vcfR.example, cutoff = .6)
#' @export
missing_by_snp <- function(vcfR,
                           cutoff=NULL){

  #bind global variables
  dp<- NULL

  #if specified vcfR is not class 'vcfR', fail gracefully
  if (!inherits(vcfR, what = "vcfR")){
    stop("specified vcfR object must be of class 'vcfR'")
  }

  #if cutoff is NOT null, start here
  if (!is.null(cutoff)) {

    #if specified cutoff is not numeric fail gracefully
    if (!inherits(cutoff, what = "numeric")){
      stop("specified cutoff must be class 'numeric'")
    }

    #if specified cutoff is not between 0-1 fail gracefully
    if (cutoff < 0 | cutoff > 1){
      stop("specified cutoff must be a proportion between 0 and 1")
    }

    #print user message
    message("cutoff is specified, filtered vcfR object will be returned")

    #do basic vis to show cutoff
    #extract genotype matrix from the vcfR object
    dp.matrix<- vcfR::extract.gt(vcfR,
                                 as.numeric=TRUE)

    #calculate the proportion of individuals successfully genotyped at each SNP
    miss<-rowSums(is.na(dp.matrix))/ncol(dp.matrix)

    #IF this for loop is going to fail, alert user and skip visualizations
    if(is.null(nrow(dp.matrix[1-miss >= 1,]))){
      message("0 SNPs passing 100% completeness threshold, visualizations cannot be generated, returning filtered vcf")
      #calc # of SNPs filtered
      p<-round(sum(miss > 1-cutoff)/length(miss)*100, 2)

      #report # of SNPs filtered
      message(p,"% of SNPs fell below a completeness cutoff of ", cutoff, " and were removed from the VCF")

      #do filtering
      vcfR <- vcfR[miss <= 1-cutoff, ]

      #return filtered vcfR
      return(vcfR)
    }

    #else, give visualizations alongside filtering
    else{
    #loop that stores a vector of # non-missing SNPs retained for each individual
    #looped over all possible completeness filter values
    #initialize df.x
    df.x<- data.frame(filt=numeric(),
                      missingness=numeric(),
                      snps.retained=numeric())
    #loop
    for (i in c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1)){
      #subset the matrix to only snps passing a given filter level
      gen.z.mat<-dp.matrix[1-miss >= i,]
      #calc the total number of snps retained at the given filter level
      snps.retained<-nrow(gen.z.mat)
      #calculate the total missing data % for the given cutoff
      missingness<-sum(is.na(gen.z.mat))/(ncol(gen.z.mat)*nrow(gen.z.mat))
      #calculate the completeness cutoff for each snp to be retained
      filt<-i
      df.x<-rbind(df.x, as.data.frame(cbind(filt, missingness, snps.retained)))
      #close for loop
      }

    #make necessary columns numeric for plotting
    df.x$filt<-as.numeric(as.character(df.x$filt))
    df.x$missingness<-as.numeric(as.character(df.x$missingness))
    df.x$snps.retained<-as.numeric(as.character(df.x$snps.retained))

    #visualize dotplot for total loci retained at each filter level
    plot1<-ggplot2::ggplot(df.x,
                           ggplot2::aes(x=filt)
                           )+
      ggplot2::scale_x_continuous(breaks=c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1))+
      ggplot2::geom_point(ggplot2::aes(y=snps.retained))+
      ggplot2::theme_bw()+
      ggplot2::labs(x = "SNP completeness cutoff",
                    y = "total SNPs retained")+
      ggplot2::geom_vline(xintercept = cutoff,
                          color = "red")

    #visualize dotplot for missing data % at each filter level
    plot2<-ggplot2::ggplot(df.x,
                           ggplot2::aes(x=filt)
                           )+
      ggplot2::scale_x_continuous(breaks=c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1))+
      ggplot2::geom_point(ggplot2::aes(y=missingness))+
      ggplot2::theme_bw() +
      ggplot2::labs(x = "SNP completeness cutoff",
                    y = "total proportion missing data")+
      ggplot2::geom_vline(xintercept = cutoff,
                          color = "red")

    gridExtra::grid.arrange(plot1,plot2)

    #calc # of SNPs filtered
    p<-round(sum(miss > 1-cutoff)/length(miss)*100, 2)

    #report # of SNPs filtered
    message(p,"% of SNPs fell below a completeness cutoff of ", cutoff, " and were removed from the VCF")

    #do filtering
    vcfR <- vcfR[miss <= 1-cutoff, ]

    #return filtered vcfR
    return(vcfR)

    } #close else statement

  #close if statement
  }

  #if cutoff IS null
  else {

    #print user message
    message("cutoff is not specified, exploratory visualizations will be generated")

    ###Part 1
    #Vis to understand the interplay between retaining samples and setting a missing data cutoff
    #extract genotype from the vcf
    dp.matrix<- vcfR::extract.gt(vcfR,
                                 as.numeric=TRUE)

    #calculate vector containing the proportion of individuals successfully genotyped at each SNP
    miss<-rowSums(is.na(dp.matrix))/ncol(dp.matrix)

    #IF this for loop over filtering cutoffs is going to fail, alert user:
    if(is.null(nrow(dp.matrix[1-miss >= 1,]))){
      message("0 SNPs passing 100% completeness threshold, low-data samples must be removed before creating visualizations")
      #calculate missingness by individual
      miss<-colSums(is.na(dp))/nrow(dp)
      samples<-colnames(dp)
      #create df
      df.x<-data.frame(id=samples,
                       missingness=miss,
                       row.names = NULL)
      #return df
      return(df.x)
    }

    #otherwise generate visualizations
    else{
    #initialize df.x
    df.y<- data.frame(filt=numeric(), snps=numeric())
    #loop
    for (i in c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1)){
      #subset matrix to only SNPs retained at given filter level
      gen.z.mat<-dp.matrix[1-miss >= i,]
      #calc the total number of snps retained at the given filter level in each sample
      snps<-colSums(is.na(gen.z.mat) == TRUE)/nrow(gen.z.mat)
      #calculate the completeness cutoff for each snp to be retained
      filt<-rep(i, times= length(snps))
      df.y<-rbind(df.y, as.data.frame(cbind(filt, snps)))
    }      #close for loop


    #make columns numeric for plotting
    df.y$filt<-as.numeric(as.character(df.y$filt))
    df.y$snps<-as.numeric(as.character(df.y$snps))

    #visualize filtering levels as stacked histograms
    print(
      ggplot2::ggplot(df.y,
                      ggplot2::aes(x = snps,
                                   y = as.character(filt),
                                   fill = filt,
                                   color = filt)
                      )+
        ggridges::geom_density_ridges(jittered_points = TRUE,
                                      position = "raincloud",
                                      alpha = .25,
                                      cex=.5)+
        ggplot2::theme_classic() +
        ggplot2::labs(x = "missing data proportion in each sample",
                      y = "SNP completeness cutoff")+
        ggplot2::theme(legend.position = "none")
      )

    ###Part 2
    #Vis to make decision on cutoff
    #calculate the proportion of individuals successfully genotyped at each SNP
    miss<-rowSums(is.na(dp.matrix))/ncol(dp.matrix)

    #loop that stores a vector of # non-missing loci retained for each individual
    #looped over all possible completeness filter values
    #initialize df.x
    df.x<- data.frame(filt=numeric(),
                      missingness=numeric(),
                      snps.retained=numeric())
    #loop
    for (i in c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1)){
      #subset the matrix to only snps passing a given filter level
      gen.z.mat<-dp.matrix[1-miss >= i,]
      #calc the total number of snps retained at the given filter level
      snps.retained<-nrow(gen.z.mat)
      #calculate the total missing data % for the given cutoff
      missingness<-sum(is.na(gen.z.mat))/(ncol(gen.z.mat)*nrow(gen.z.mat))
      #calculate the completeness cutoff for each snp to be retained
      filt<-i
      df.x<-rbind(df.x, as.data.frame(cbind(filt, missingness, snps.retained)))
    }   #close for loop

    #make columns numeric for plotting
    df.x$filt<-as.numeric(as.character(df.x$filt))
    df.x$missingness<-as.numeric(as.character(df.x$missingness))
    df.x$snps.retained<-as.numeric(as.character(df.x$snps.retained))

    #visualize dotplot for total loci retained at each filter level
    plot1<-ggplot2::ggplot(df.x,
                           ggplot2::aes(x=filt)
                           )+
      ggplot2::scale_x_continuous(breaks=c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1))+
      ggplot2::geom_point(ggplot2::aes(y=snps.retained))+
      ggplot2::theme_bw()+
      ggplot2::labs(x = "SNP completeness cutoff",
                    y = "total SNPs retained")

    #visualize dotplot for missing data % at each filter level
    plot2<-ggplot2::ggplot(df.x,
                           ggplot2::aes(x=filt)
                           )+
      ggplot2::scale_x_continuous(breaks=c(.3,.5,.6,.65,.7,.75,.8,.85,.9,.95,1))+
      ggplot2::geom_point(ggplot2::aes(y=missingness)) +
      ggplot2::theme_bw() +
      ggplot2::labs(x = "SNP completeness cutoff",
                    y = "total proportion missing data")

    #plot together
    gridExtra::grid.arrange(plot1,plot2)

    #return
    return(df.x)

    } #end else statement beginning with: #calculate vector containing the proportion of individuals successfully genotyped at each SNP

  } #end broader else statement

} #close function
