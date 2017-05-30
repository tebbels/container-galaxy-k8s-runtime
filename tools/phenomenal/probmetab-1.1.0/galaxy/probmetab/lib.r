# lib.r ProbMetab version="1.0.0"
# Author: Misharl Monsoor ABIMS TEAM mmonsoor@sb-roscoff.fr
# Contributors: Yann Guitton and Jean-francois Martin


##Main probmetab function launch by the Galaxy ProbMetab wrapper
probmetab = function(xa, xaP, xaN, variableMetadata, variableMetadataP, variableMetadataN, listArguments){
    ##ONE MODE ACQUISITION##
    if(listArguments[["mode_acquisition"]]=="one") {
        comb=NULL

        #Get the polarity from xa object
        polarity=xa@polarity
        #SNR option
        if ("xsetnofill" %in% names(listArguments)) {
            load(listArguments[["xsetnofill"]])
            xsetnofill=xset
        }
        else{
            xsetnofill=NULL
        }
        #Exclude samples
        if ("toexclude" %in% names(listArguments)) {
            toexclude=listArguments[["toexclude"]]
        }
        else {
            toexclude=NULL
        }
        ionAnnot=get.annot(xa, polarity=polarity, allowMiss=listArguments[["allowMiss"]],xset=xsetnofill,toexclude=toexclude)
        comb=NULL
    }

    ##TWO MODES ACQUISITION##
    #Mode annotatediffreport
    else if(listArguments[["inputs_mode"]]=="two"){
        ##Prepare the objects that will be used for the get.annot function
        comb=1


        xsetPnofill=NULL
        xsetNnofill=NULL
        # TODO: a reactiver
        #if ("xsetPnofill" %in% names(listArguments)) {
        #    load(listArguments[["xsetPnofill"]])
        #    xsetPnofill=xset
        #}
        #if ("xsetNnofill" %in% names(listArguments)) {
        #    load(listArguments[["xsetNnofill"]])
        #    xsetNnofill=xset
        #}
        # include CAMERA non-annotated compounds, and snr retrieval
        # comb 2+ - used on Table 1
        ionAnnotP2plus = get.annot(xaP, allowMiss=listArguments[["allowMiss"]], xset=xsetPnofill,toexclude=listArguments[["toexclude"]])
        ionAnnotN2plus = get.annot(xaN, polarity="negative", allowMiss=listArguments[["allowMiss"]], xset=xsetNnofill,toexclude=listArguments[["toexclude"]])
        ionAnnot = combineMolIon(ionAnnotP2plus, ionAnnotN2plus)
        print(sum(ionAnnot$molIon[,3]==1))
        print(sum(ionAnnot$molIon[,3]==0))
        write.table(ionAnnot[1], sep="\t", quote=FALSE, row.names=FALSE, file="CombineMolIon.tsv")
        #Merge variableMetadata Negative and positive acquisitions mode


        #Mode combinexsannos TODO bug avec tableau issus de combinexsannos
        #else {
            #load(listArguments[["image_combinexsannos"]])
            #image_combinexsannos=cAnnot
            ##Prepare the objects that will be used for the combineMolIon function
            #load(listArguments[["image_pos"]])
            #image_pos=xa
            #ionAnnot=combineMolIon(peaklist=cAnnot, cameraobj=image_pos, polarity="pos")
        #}

    }

    ##DATABASE MATCHING##
    if (listArguments[["kegg_db"]]=="KEGG"){
        DB=build.database.kegg(orgID = NULL)
    }
    else{
        table_list <<- NULL
        ids=strsplit(listArguments[["kegg_db"]],",")
        ids=ids[[1]]
        if(length(ids)>1){
            for(i in 1:length(ids)){
                 table_list[[i]] <- build.database.kegg(ids[i])
            }
            db_table=do.call("rbind",table_list)
            DB=unique(db_table)
        }
        else{
            DB=build.database.kegg(listArguments[["kegg_db"]])
        }
    }
    #Matching des mass exactes mesurees avec les masses des compounds KEGG (pas M+H ou M-H)
    reactionM = create.reactionM(DB, ionAnnot, ppm.tol=listArguments[["ppm_tol"]])
    ##PROBABILITY RANKING##
    # number of masses with candidates inside the fixed mass window
    # and masses with more than one candidate
    length(unique(reactionM[reactionM[,"id"]!="unknown",1]))
    sum(table(reactionM[reactionM[,"id"]!="unknown",1])>1)
    #if (listArguments[["useIso"]]){
        #BUG TODO
        # Calculate the ratio between observed and theoretical isotopic patterns.
        # If you don't have an assessment of carbon offset to carbon number prediction
        # skip this step and use the reactionM as input to weigthM function.
        #isoPatt < incorporate.isotopes(comb2plus, reactionM, , samp=12:23, DB=DB)
        #  calculate   the   likelihood   of   each   mass   to   compound   assignment   using   mass   accuracy,and isotopic pattern, when present
        #wl < weightM(isoPatt,intervals=seq(0,1000,by=500), offset=c(3.115712, 3.434146, 2.350798))

            #isoPatt=incorporate.isotopes(ionAnnot, reactionM,comb=comb,var=listArguments[["var"]],DB=DB)

        #wl = weightM(reactionM, useIso=true)
    #}
    #else {
        #wl = weightM(reactionM, useIso=FALSE)
    #}
    wl =weightM(reactionM, useIso=FALSE)
    w = design.connection(reactionM)
    # Probability calculations
    x = 1:ncol(wl$wm)
    y = 1:nrow(wl$wm)
    conn = gibbs.samp(x, y, 5000, w, wl$wm)
    ansConn = export.class.table(conn, reactionM, ionAnnot, DB=DB,html=listArguments[["html"]],filename="AnalysisExample",prob=listArguments[["prob"]])
    if(listArguments[["html"]]){
        #Zip the EICS plot
        system(paste('zip -r "Analysis_Report.zip" "AnalysisExample_fig"'))
    }

    # calculate the correlations and partial correlations and cross reference then with reactions
    mw=which(w==1,arr.ind=TRUE)
    #reac2cor function : Use the intensity of putative molecules in repeated samples to calculate correlations and partial
    #correlation in a user defined threshold of false discovery rate for significance testing. After the
    #correlation test the function also overlay significant correlations with all putative reactions between
    #two masses.
    #It generates a list of estimated correlations and reactions.
    corList=reac2cor(mw,ansConn$classTable,listArguments[["opt"]],listArguments[["corths"]],listArguments[["corprob"]],listArguments[["pcorprob"]])
    ans=list("ansConn"=ansConn,"corList"=corList)
    #Generate the siff table for CytoScape
    cytoscape_output(corList,ansConn)


    #Execute the merge_probmetab function to merge the variableMetadata table and annotations from ProbMetab results

    if(listArguments[["mode_acquisition"]]=="one") {
        #Retrocompatibility with previous annotateDiffreport variableMetadata dataframe (must replace mzmed column by mz, and rtmed by rt)
        names(variableMetadata)[names(variableMetadata)=="mzmed"] <- "mz"
        names(variableMetadata)[names(variableMetadata)=="rtmed"] <- "rt"
        variableM=merge_probmetab(variableMetadata, ansConn)
        write.table(variableM, sep="\t", quote=FALSE, row.names=FALSE, file="variableMetadata.tsv")
    } else if (listArguments[["mode_acquisition"]]=="two") {
        #Retrocompatibility with previous annotateDiffreport variableMetadata dataframe (must replace mzmed column by mz, and rtmed by rt)
        names(variableMetadataP)[names(variableMetadata)=="mzmed"] <- "mz"
        names(variableMetadataP)[names(variableMetadata)=="rtmed"] <- "rt"
        names(variableMetadataN)[names(variableMetadata)=="mzmed"] <- "mz"
        names(variableMetadataN)[names(variableMetadata)=="rtmed"] <- "rt"
        variableMP=merge_probmetab(variableMetadataP, ansConn)
        write.table(variableMP, sep="\t", quote=FALSE, row.names=FALSE, file="variableMetadata_Positive.tsv")
        variableMN=merge_probmetab(variableMetadataN, ansConn)
        write.table(variableMN, sep="\t", quote=FALSE, row.names=FALSE, file="variableMetadata_Negative.tsv")
    }

    return(ans)

}

##Function that generates a siff table for CytoScape
cytoscape_output=function(corList,ansConn){
    signif_cor=as.data.frame(corList$signif.cor)
    classTable=as.data.frame(ansConn$classTable)
    #Siff table
    siff_table=cbind(signif_cor["node1"],signif_cor["cor"],signif_cor["node2"])
    #attribute table output for Cytoscape

    ## START  Code part from the export2cytoscape function of ProbMetab written by Ricardo R. Silva
    for (i in 1:nrow(classTable)) if (classTable[i, 1] == ""){
        classTable[i, c(1, 4, 6, 7)] <- classTable[i - 1, c(1, 4, 6, 7)]
    }
     msel <- as.matrix(classTable[, 1:7])
     msel <- cbind(msel[, 6], msel[,-6])
     colnames(msel)[1] <- "Id"
     msel[, 1] <- sub("^\\s+", "", msel[, 1])
     colnames(msel)[1] <- "Id"
    ids <- unique(msel[, 1])
     attrMatrix <- matrix("", nrow = length(ids), ncol = ncol(msel)-1)
    for (i in 1:length(ids)) {
            attrMatrix[i, 1] <- unique(msel[msel[, 1] == ids[i],
                2])
            attrMatrix[i, 2] <- paste("[", paste(msel[msel[,
                1] == ids[i], 3], collapse = ", "), "]", sep = "")
            attrMatrix[i, 3] <- paste("[", paste(msel[msel[,
                1] == ids[i], 4], collapse = ", "), "]", sep = "")
            attrMatrix[i, 4] <- unique(msel[msel[, 1] == ids[i],
                5])
            attrMatrix[i, 5] <- paste("[", paste(msel[msel[,
                1] == ids[i], 6], collapse = ", "), "]", sep = "")
            attrMatrix[i, 6] <- unique(msel[msel[, 1] == ids[i],
                7])
        }
    ids <- as.numeric(unique(msel[, 1]))
    attrMatrix <- cbind(ids, attrMatrix)
    colnames(attrMatrix) <- colnames(msel)
    ## END Code part from the export2cytoscape function of ProbMetab writieen by Ricardo R. Silva
    write.table(attrMatrix, sep="\t", quote=FALSE, row.names=FALSE, file="Analysis_Report.tsv")
    write.table(siff_table, sep="\t", quote=FALSE, row.names=FALSE, file="sif.tsv")

    return(attrMatrix)
}

##Functions written by Jean-Francois Martin

deter_ioni <- function (aninfo, pm)
{
  # determine ionisation in ProbMetab result file, used in function merge_probmetab
  # input : for 1 ion, aninfo = string with m/z rt and CAMERA annotation from ProbMetab result file
  # if the difference between m/z and the probmetab proposed mass is ~1 we use the sign (positive or negative) of this diference
  # to define the type of ionisation
  # If adduct or fragment was detected, therefore diff >>1 and so, we search for substring "+" ou "2+" ou "3+" ou "-"...
  # to define the type of ionisation
  # aninfo : vecteur of character resulting of the parsing(sep="#") of the probmetab annotation
  if (round(abs(as.numeric(aninfo[1]) - pm),0) ==1) {
    if (as.numeric(aninfo[1]) - pm <0) {esi <- "n"} else {esi <- "p"}
  } else
    if (!is.na(aninfo[4])) {
      anstr <- aninfo[4]
      # cat(anstr)
      if ((grepl("]+",anstr,fixed=T)==T) || (grepl("]2+",anstr,fixed=T)==T) || (grepl("]3+",anstr,fixed=T)==T)) { esi <- "p"}
      else
        if ((grepl("]-",anstr,fixed=T)==T) || (grepl("]2-",anstr,fixed=T)==T) || (grepl("]3-",anstr,fixed=T)==T)) { esi <- "n"}
      # cat(" ioni ",esi,"\n")
    } else
    { esi <- "u"}

  return(esi)
}


merge_probmetab <- function(metaVar,ansConn) {
  ## Parse ProbMetab information result file and merge in variable_metaData initial file
  ##  inputs :
  ##      metaVar : data.frame of metadataVariable input of probmetab function
  ##     ansConn  : data.frame of ProbMetab result
  ## output : dataframe with Probmetab results merge with variableMetadata
  ## Constante
  ## iannot : indice de la colonne annotation dans le resultat de probMetab
  iannot <- 4

  ## definition of an unique identification of ions mz with 3 decimals and rt(sec) with 1 decimal to avoid
  ## duplicate ions name in the diffreport result file
  ions <- paste ("M",round(metaVar$mz,3),"T",round(metaVar$rt,1),sep="")
  metaVar <- data.frame(ions,metaVar)

  ###### Result data.frame from ProbMetab result list
  an_ini <- ansConn$classTable

  ## Suppression of rows without  mz and rt or unknown and columns of intensities
  ## COLUMNS SUBSCRIPTS HAVE TO BE CHECKED WITh DIFFERENT RESULTS FILES
  an <- an_ini[(an_ini[,2]!="unknown"),c(1,2,3,7)]
  ## initialisation of vectors receiving the result of the parse of the column annotation (subscrip iannot)
  mz <- rep(0,dim(an)[1])
  rt <- rep(0,dim(an)[1])
  propmz <- rep(0,dim(an)[1])
  ioni <- rep("u",dim(an)[1])

  ## parse the column annotation and define ionisation mode
  for (i in 1:dim(an)[1]) {
    if (an[i,1] != "") {
      info_mzrt <- unlist(strsplit(an[i,iannot],"#"))
      propmz[i] <- as.numeric(an[i,1])
      mz[i] <- as.numeric(info_mzrt[1])
      rt[i] <- as.numeric(info_mzrt[2])
      ioni[i] <- deter_ioni(info_mzrt,as.numeric(an[i,1]))
    }
    else {
      propmz[i] <- as.numeric(propmz[i-1])
      mz[i] <- as.numeric(mz[i-1])
      rt[i] <- as.numeric(rt[i-1])
      ioni[i] <- ioni[i-1]
    }
  }

  ## definition of an unique identification of ions : mz with 3 decimals and rt(sec) with 1 decimal
  ## The same as for the metadataVariable data.frame to match with.
  ions <- paste ("M",round(mz,3),"T",round(rt,1),sep="")
  an <- data.frame(ions,ioni,propmz,mz,rt,an)

  ## transposition of the different probmetab annotations which are in different rows in the initial result data.frame
  ## on only 1 row separated with a ";"
  li <- as.matrix(table(an$propmz))
  li <- data.frame(dimnames(li)[1],li)
  dimnames(li)[[2]][1] <- "propmz"
  ions   <- rep("u",dim(li)[1])
  propmz <- rep(0,dim(li)[1])
  mpc    <- rep("c",dim(li)[1])
  proba  <- rep("p",dim(li)[1])
  c <- 0
  while (c < dim(li)[1]) {
    c <- c + 1
    suban     <- an[an$propmz==li[c,1],]
    ions[c]   <- as.character(suban[1,1])
    propmz[c] <- as.numeric(suban[1,3])
    mpc[c]    <- paste(suban[,7],collapse=";")
    proba[c]  <- paste(as.character(suban[,8]),collapse=";")
  }

  ## Creation of the data.frame with 1 row per ions
  anc <- data.frame(ions,propmz,mpc,proba)
  anc <- anc[order(anc[,1]),]

  metaVarFinal <- merge(metaVar, anc, by.x=1, by.y=1, all.x=T, all.y=T)
  metaVarFinal <- metaVarFinal[,-1]
  #write.table(metaVarFinal,file="res.txt", sep="\t", row.names=F, quote=F)

  return (metaVarFinal)
}

# RETROCOMPATIBILITE avec ancienne version de annotate
getVariableMetadata = function(xa) {
    # --- variableMetadata ---
    peakList=getPeaklist(xa)
    peakList=cbind(groupnames(xa@xcmsSet),peakList); colnames(peakList)[1] = c("name");
    variableMetadata=peakList[,!(colnames(peakList) %in% c(sampnames(xa@xcmsSet)))]
    variableMetadata$name= groupnames(xa@xcmsSet)
    return (variableMetadata)
}


# This function get the raw file path from the arguments
getRawfilePathFromArguments <- function(singlefile, zipfile, listArguments) {
    if (!is.null(listArguments[["zipfile"]]))           zipfile = listArguments[["zipfile"]]
    if (!is.null(listArguments[["zipfilePositive"]]))   zipfile = listArguments[["zipfilePositive"]]
    if (!is.null(listArguments[["zipfileNegative"]]))   zipfile = listArguments[["zipfileNegative"]]

    if (!is.null(listArguments[["singlefile_galaxyPath"]])) {
        singlefile_galaxyPaths = listArguments[["singlefile_galaxyPath"]];
        singlefile_sampleNames = listArguments[["singlefile_sampleName"]]
    }
    if (!is.null(listArguments[["singlefile_galaxyPathPositive"]])) {
        singlefile_galaxyPaths = listArguments[["singlefile_galaxyPathPositive"]];
        singlefile_sampleNames = listArguments[["singlefile_sampleNamePositive"]]
    }
    if (!is.null(listArguments[["singlefile_galaxyPathNegative"]])) {
        singlefile_galaxyPaths = listArguments[["singlefile_galaxyPathNegative"]];
        singlefile_sampleNames = listArguments[["singlefile_sampleNameNegative"]]
    }
    if (exists("singlefile_galaxyPaths")){
        singlefile_galaxyPaths = unlist(strsplit(singlefile_galaxyPaths,","))
        singlefile_sampleNames = unlist(strsplit(singlefile_sampleNames,","))

        singlefile=NULL
        for (singlefile_galaxyPath_i in seq(1:length(singlefile_galaxyPaths))) {
            singlefile_galaxyPath=singlefile_galaxyPaths[singlefile_galaxyPath_i]
            singlefile_sampleName=singlefile_sampleNames[singlefile_galaxyPath_i]
            singlefile[[singlefile_sampleName]] = singlefile_galaxyPath
        }
    }
    return(list(zipfile=zipfile, singlefile=singlefile))
}


# This function retrieve the raw file in the working directory
#   - if zipfile: unzip the file with its directory tree
#   - if singlefiles: set symlink with the good filename
retrieveRawfileInTheWorkingDirectory <- function(singlefile, zipfile) {

    if(!is.null(singlefile) && (length("singlefile")>0)) {
        for (singlefile_sampleName in names(singlefile)) {
            singlefile_galaxyPath = singlefile[[singlefile_sampleName]]
            if(!file.exists(singlefile_galaxyPath)){
                error_message=paste("Cannot access the sample:",singlefile_sampleName,"located:",singlefile_galaxyPath,". Please, contact your administrator ... if you have one!")
                print(error_message); stop(error_message)
            }

            file.symlink(singlefile_galaxyPath,singlefile_sampleName)
        }
        directory = "."

    }
    if(!is.null(zipfile) && (zipfile!="")) {
        if(!file.exists(zipfile)){
            error_message=paste("Cannot access the Zip file:",zipfile,". Please, contact your administrator ... if you have one!")
            print(error_message)
            stop(error_message)
        }

        #list all file in the zip file
        #zip_files=unzip(zipfile,list=T)[,"Name"]

        #unzip
        suppressWarnings(unzip(zipfile, unzip="unzip"))

        #get the directory name
        filesInZip=unzip(zipfile, list=T);
        directories=unique(unlist(lapply(strsplit(filesInZip$Name,"/"), function(x) x[1])));
        directories=directories[!(directories %in% c("__MACOSX")) & file.info(directories)$isdir]
        directory = "."
        if (length(directories) == 1) directory = directories

        cat("files_root_directory\t",directory,"\n")

    }
}
