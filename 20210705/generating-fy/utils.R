# FUNCTION TO LOAD A TABLE AS DATA FRAME
loadTables <- function(paths){
  # Saves table as a dataframe in list which is returned.
  
  # Params 
  # ------
  # paths : list
  #   Where each list element is labeled as "rpt", "num", "alph", or "info" and contains
  #   paths to report table, numeric table, alpha-numeric, hospital provider id table csv files.
  # 
  # Returns
  # -------
  # tables : list
  #   Where each list element corresponds to inputted file path saved as data frame and 
  #   list names are "report_table", "alphaNumeric_table", and "info_table"
  
  rpt_df <- data.frame()
  num_df <- data.frame()
  alph_df <- data.frame()
  info_df <- data.frame()
  
  # For each list element...
  foreach(element=(1:length(paths))) %do% {
    # identify whether list element is labeled as report table, numeric table, alpha-numeric table
    # and set column classes depending on type of table
    
    if(names(paths)[element] == "rpt"){
      # 1. write function to convert strings in rpt table to dates w/ format MM/DD/YYYY
      # convert function to method which can be called from colClasses
      setClass("rpt_tableDates") 
      setAs( from="character", to="rpt_tableDates", 
             def=function(from){as.Date(from, format="%m/%d/%Y")} )
      
      colClasses_ <- c("integer", rep("character", 2), "numeric", "factor",
                       rep("rpt_tableDates", 3), rep("factor", 2), 
                       rep("character", 2), "factor", "rpt_tableDates", "factor",
                       "rpt_tableDates", "character", "rpt_tableDates")
      
      # 2. if column names/headers are absent set column names depending on type of table
      # and indicate that header= FALSE
      if(colnames(read.csv(paths$rpt))[1] != "RPT_REC_NUM"){
        colnames_ <- c("RPT_REC_NUM", "PRVDR_CTRL_TYPE_CD", "PRVDR_NUM",
                       "NPI", "RPT_STUS_CD", "FY_BGN_DT", "FY_END_DT",
                       "PROC_DT", "INITL_RPT_SW", "LAST_RPT_SW",
                       "TRNSMTL_NUM", "FI_NUM", "ADR_VNDR_CD",
                       "FI_CREAT_DT", "UTIL_CD", "NPR_DT",
                       "SPEC_IND", "FI_RCPT_DT")
        
        rpt_df<-read.csv(file=paths$rpt, header=FALSE,
                         colClasses=colClasses_, col.names=colnames_)
        
        # make sure there are four levels of UTIL_CD column (L,N,F,NA)
        # ...
        # ...
        
        # otherwise indicate that headers are present 
      }else{rpt_df<-read.csv(file=paths$rpt, header=TRUE, colClasses=colClasses_)}}
    
    
    if(names(paths)[element] == "num"){
      colClasses_ <- c("integer", "factor", rep("character", 2), "numeric")
      
      # if column names/headers are absent set column names depending on type of table
      # and indicate that header=FALSE
      if(colnames(read.csv(paths$num))[1] != "RPT_REC_NUM"){
        colnames_ <- c("RPT_REC_NUM", "WKSHT_CD", "LINE_NUM",
                       "CLMN_NUM", "ITM_VAL_NUM")
        num_df<-read.csv(file=paths$num, header=FALSE,
                         colClasses=colClasses_, col.names=colnames_)
      }else{num_df<-read.csv(file=paths$num, header=TRUE, colClasses=colClasses_)}}
    
    
    if(names(paths)[element] == "alph"){
      colClasses_ <- c("integer", "factor", rep("character", 3))
      
      # if column names/headers are absent set column names depending on type
      # of table
      if(colnames(read.csv(paths$alph))[1] != "RPT_REC_NUM"){
        colnames_ <- c("RPT_REC_NUM", "WKSHT_CD", "LINE_NUM",
                       "CLMN_NUM", "ITM_ALPHNMRC_ITM_TXT")
        alph_df<-read.csv(file=paths$alph, header=FALSE,
                          colClasses=colClasses_, col.names=colnames_)
      }else{alph_df<-read.csv(file=paths$alph, header=TRUE, colClasses=colClasses_)}} 
    
    
    if(names(paths)[element] == "info"){
      # write function to convert strings in rpt table to dates w/ format DD-MON-YY
      # convert function to method which can be called from colClasses
      setClass("info_tableDates") 
      setAs( from="character", to="info_tableDates", 
             def=function(from){as.Date(from, format="%d-%b-%y")} )
      
      colClasses_ <- c("character", rep("info_tableDates", 2), "factor", 
                       rep("character", 8), "factor")
      
      info_df<-read.csv(file=paths$info, colClasses=colClasses_)}
  }
  
  # assemble list of dataframes
  tables <- list()
  if(!is_empty(rpt_df)){
    tables$report_table <- rpt_df
  }
  
  if(!is_empty(num_df)){
    tables$numeric_table <- num_df
  }
  
  if(!is_empty(alph_df)){
    tables$alphaNumeric_table <- alph_df
  }
  
  if(!is_empty(info_df)){
    tables$info_table <- info_df
  }
  
  return(tables)
}



fy_weight <- function(infoTable){
# Create columns that identify the fraction of hospital's fiscal year spent in each year
# reported
# 
# Params
# ------
# infoTable : data.frame
#   hospital provider id info data table with correct column names and 
#   column classes (namely identifying FYB and FYE columns as having the class "Date")
# 
# Returns
# -------
# infoTable_copy : data.frame
#   copy of inputted table with columns identifying year weights in columns
#   "fraction_fy1" and "fraction_fy2"
#
  
  infoTable_copy <- infoTable
  fyb <- infoTable_copy$FYB
  fye <- infoTable_copy$FYE
  
  # vectorized approach
  year1 <- format(fyb, format="%Y")
  date1 <- as.Date(paste(year1, "12","31", sep="-"), format="%Y-%m-%d")
  diff1 <- as.integer(date1 - fyb)
  
  year2 <- format(fye, format="%Y")
  date2 <- as.Date(paste(year2, "01","01", sep="-"), format="%Y-%m-%d")
  diff2 <- as.integer(fye - date2)
    # note some of these reported fiscal years are greater than a year...
  
    # calculate fraction of fiscal year which takes place in year 1
  fraction_fy1 <- diff1/(diff1+diff2)
    # calculate fraction of fiscal year which takes place in year 2
  fraction_fy2 <- diff2/(diff1+diff2)
  
  
  # Save fraction vectors to infoTABLE
  infoTable_copy$fraction_fy1 <- fraction_fy1
  infoTable_copy$fraction_fy2 <- fraction_fy2
  
  # return copy of inputted table with columns containing year weights
  return(infoTable_copy)
}
