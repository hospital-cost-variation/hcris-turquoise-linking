library(tidyverse)
library(RPostgres)
library(reticulate)
library(DBI)
library(RSQLite)
library(foreach)

# FUNCTION TO SET UP R INSTANCE TO USE PYTHON FUNCTIONS
configure_reticulate <- function(path, virtualenv){
  # Prepares R instance to use pyutils.py file. Run ONCE.
  # 
  # Params
  # ------
  #   path : character
  #     path to path to python binary with libpython on 
  #     user's system.
  #   
  #   virtualenv : character
  #     name of virtual environment that will be created
  #     and used by reticulate
  
  # point reticulate to which python it should use
  reticulate::use_python(path, required = TRUE)
  
  # if a virtual environment with the name inputted already exists
  # prompt user if they want to replace the existing one with a new virtualenv
  # of the same name
  if( any(virtualenv_list()==virtualenv) ){
    response <- rstudioapi::showPrompt(title = "virtualenv prompt",
                             message = paste("The virtual environment",virtualenv,"already exists.[replace/use] this virtual environment?"))
      # if the users opts to replace the virtual environment, remove it before recreating it
      if(response == 'replace'){
        virtualenv_remove(virtualenv)
        virtualenv_create(virtualenv)
        use_virtualenv(virtualenv)
      } else if(response == 'use'){
        use_virtualenv(virtualenv)
      }
  } else {
  # if a virtual environment with the name inputted doesn't exist create virtualenv of inputted name
    virtualenv_create(virtualenv)
    use_virtualenv(virtualenv)
  }
  
  # install python mondules referenced in pyutils.py into virtual environment
  virtualenv_install(virtualenv, 'requests')
  
  # import python modules into R session
  requests <- reticulate::import('requests')
  BeautifulSoup<-py_run_string('from bs4 import BeautifulSoup')
  read_csv<-py_run_string('from pandas import read_csv')
  np <- py_run_string('import numpy as np')
  io <- reticulate::import('io') 
  zipfile <- reticulate::import('zipfile')
  re <- reticulate::import('re')
  
}


# FUNCTION TO CREATE SQL DATABASE FOR HCRIS DATA
createDB <- function(hcris_tables, connection){
  # connect to an in-memory sqlite database which
  # contains HCRIS data for one year in its tabls
  
  # Params
  # ------
  #   hcris_tables : list
  #     list of HCRIS tables. list elements should be
  #     labeled 'alph_df', 'nmrc_df', 'rpt_df', 'info_df'
  #     corresponding to HCRIS alpha_numeric, numeric, report,
  #     and info tables for a given year
  #
  #   connection : RSQLite SQLite Connection
  #     name of connection to in-memory database.
  #
  # Returns
  # -------
  #   open connection to in-memory database with hcris_tables
  
  # create a db table for each HCRIS table
  dbWriteTable(connection, "alph_table", hcris_tables$alph_df)
  dbWriteTable(connection, "nmrc_table", hcris_tables$nmrc_df)
  dbWriteTable(connection, "rpt_table", hcris_tables$rpt_df)
  dbWriteTable(connection, "info_table", hcris_tables$info_df)
  
  print("Connection to in-memory database now open. Remeber to close the connection with dbDisconnect(connection) after completing all queries")
}



# FUNCTION TO ASSEMBLE FISCAL YEAR WEIGHTS
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



# FUNCTION TO LINK HCRIS TO TURQUOISE
hcrisToTurq <- function(hcris_tables=NULL, report_table_name=NULL, test=TRUE){
  # automatically updates turquoise price_transparency_raw_charge,
  # price_transparency_plan, and price_transparency_payer tables to reflect how
  # hcris data has been filtered by user 
  # 
  # Params
  # ------
  #   hcris_tables : list
  #     list containing filtered hcris alpha-numeric,
  #     numeric, report, and provider id info tables
  #     as dataframes
  #
  #   report_table_name : character
  #     name of list element in in hcris_tables list 
  #     containing report table df
  #
  #   test : logical
  #     whether to simulate a situation in which
  #     hcris tables have been filtered on two provider ids
  #
  # Returns
  # -------
  #   tables : list
  #     turquoise dataframes filtered according to how hcris
  #     tables have been filtered
  
  # open connection to database
      # ask for credentials
  con <- dbConnect(RPostgres::Postgres(),
                   dbname = 'da90rd9a0abng1', 
                   host = 'ec2-54-208-159-67.compute-1.amazonaws.com', 
                   port = 5432, 
                   user = rstudioapi::askForPassword("username"),
                   password = rstudioapi::askForPassword("password"))
  
  # 1. price_transparency_provider
      # store provider_ids from HCRIS lookup table
  if(test == TRUE){
    provider_id <- c("132002", "201307") #<- test values
  } else {
    provider_id <- hcris_tables$report_table_name$PRVDR_NUM
  }
      
      # run query
  provider_sql <- glue::glue_sql("SELECT id FROM price_transparency_provider 
                                  WHERE medicare_provider_id IN ({hcris_provider_ids*})",
                                 hcris_provider_ids = provider_id,
                                 .con = con)
  res <- dbSendQuery(con, provider_sql)
      
      # fetch results in chunks and store in dataframe 
  turq_providerDf <- data.frame()
  while(!dbHasCompleted(res)){
    chunk <- dbFetch(res, n = 50000)
    turq_providerDf <- rbind(turq_providerDf, chunk)
  }
  
      # clear result
  dbClearResult(res)
  
  
  # 2. price_transparency_rawcharge
  # store id from price_transparency_provider table
  id_ <- turq_providerDf$id
  
  # run query
  rawcharge_sql <- glue::glue_sql("SELECT * FROM price_transparency_rawcharge
                                  WHERE provider_id IN ({provider_table_ids*})",
                                  provider_table_ids = id_,
                                 .con = con)
  res <- dbSendQuery(con, rawcharge_sql)
  
  # fetch results in chunks and store in dataframe 
  turq_rawchargeDf <- data.frame()
  while(!dbHasCompleted(res)){
    chunk <- dbFetch(res, n = 50000)
    turq_rawchargeDf <- rbind(turq_rawchargeDf, chunk)
  }
  
  # clear result
  dbClearResult(res)
  
  
  # 3. price_transparency_plan
  # store plan_id from price_transparency_rawcharge table
  plan_id <- turq_rawchargeDf$plan_id
  
  # run query
  plan_sql <- glue::glue_sql("SELECT * FROM price_transparency_plan 
                             WHERE id IN ({rawcharge_plan_ids*})",
                             rawcharge_plan_ids = plan_id,
                             .con = con)
  res <- dbSendQuery(con, plan_sql)
  
  # fetch results in chunks and store in dataframe 
  turq_planDf <- data.frame()
  while(!dbHasCompleted(res)){
    chunk <- dbFetch(res, n = 50000)
    turq_planDf <- rbind(turq_planDf, chunk)
  }
  
  # clear result
  dbClearResult(res)
  
  
  # 4. price_transparency_payer
  # store payer_id from price_transparency_plan table
  payer_id <- turq_planDf$payer_id
  
  # run query
  payer_sql <- glue::glue_sql("SELECT * FROM price_transparency_payer 
                             WHERE id IN ({plan_payer_ids*})",
                             plan_payer_ids = payer_id,
                             .con = con)
  res <- dbSendQuery(con, payer_sql)
  
  # fetch results in chunks and store in dataframe 
  turq_payerDf <- data.frame()
  while(!dbHasCompleted(res)){
    chunk <- dbFetch(res, n = 50000)
    turq_payerDf <- rbind(turq_payerDf, chunk)
  }
  
  # clear result
  dbClearResult(res)
  
  
  # close connection
  dbDisconnect(con)
  
  tables <- list('price_transparency_rawcharge' = turq_rawchargeDf,
                 'price_transparency_plan' = turq_planDf,
                 'price_transparency_payer'=turq_payerDf)
  return(tables)
}



# FUNCTION TO LINK TURQUOISE TO HCRIS
turqToHcris <- function(turquoise_rawcharge = NULL, test=TRUE, hcris_con){
  # automatically updates hcris provider id info, report, 
  # numeric, and alpha-numeric tables to reflect how user 
  # has filtered turquoise raw_charge tables
  # 
  # Params
  # ------
  #   turquoise_rawcharge : data.frame
  #     filtered turquoise price_transparency_rawcharge
  #     file
  #
  #   test : logical   
  #     whether to simulate a situation in which
  #     turquoise rawcharge tables has been filtered on one provide_id
  #     value
  #
  #    hcris_con : RSQLite SQLite Connection
  #     name of open connection to in-memory database containing
  #     unfiltered hcris tables
  #
  # Returns
  # -------
  #   tables : list
  #     hcris provider id info, report, alpha, and alpha-numeric dataframes
  #     filtered according to how turquoise tables are filtered
  
  
  # capture turquoise rawcharge table's provider_ids, dtype=int
  provider_id<-vector()
  if(test==TRUE){
    provider_id <- c(1174) #<- test values
    print(paste("provider id(s):", as.character(provider_id)))
  } else {
    provider_id <- turquoise_rawcharge$provider_id
  }
  
  # open connection to turquoise database
  # ask for credentials
  turq_con <- dbConnect(RPostgres::Postgres(),
                   dbname = 'da90rd9a0abng1', 
                   host = 'ec2-54-208-159-67.compute-1.amazonaws.com', 
                   port = 5432, 
                   user = rstudioapi::askForPassword("username"),
                   password = rstudioapi::askForPassword("password"))
  
  # run query on turquoise database to capture provider_ids corresponding
  # medicare_provider_ids from price_transparency_provider table

  provider_sql <- glue::glue_sql("SELECT medicare_provider_id FROM price_transparency_provider 
                                  WHERE id IN ({price_transparency_rawcharge*})",
                                 price_transparency_rawcharge = provider_id,
                                 .con = turq_con)
  res <- dbSendQuery(turq_con, provider_sql)
  
  # fetch results in chunks and store in dataframe; dtype = character 
  medicare_provider_id <- data.frame()
  while(!dbHasCompleted(res)){
    chunk <- dbFetch(res, n = 50000)
    medicare_provider_id <- rbind(medicare_provider_id, chunk)
  }
  
  # clear result
  dbClearResult(res)
  
  # disconnect from turquoise database
  dbDisconnect(turq_con)
  
  if(test==TRUE){
    print(paste("medicare provider id(s):", medicare_provider_id$medicare_provider_id))
  }
  
  # run query on hcris database
    # 1. filter hcris info table based on
    # medicare_provider_id
  info_sql <- glue::glue_sql("SELECT * FROM info_table 
                             WHERE PROVIDER_NUMBER IN ({turquoise_medicare_provider_id*})",
                             turquoise_medicare_provider_id = medicare_provider_id$medicare_provider_id,
                             .con = hcris_con)
   res <- dbSendQuery(hcris_con, info_sql)
    
      # store result in data frame in chunks
   filtered_info_df <- data.frame()
   while(!dbHasCompleted(res)){
     chunk <- dbFetch(res, n = 50000)
     filtered_info_df <- rbind(filtered_info_df, chunk)
   }
   
      # clear result
   dbClearResult(res)
   
   
    # 2. filter hcris report table based on turquoise medicare_provider_id
  rpt_sql <- glue::glue_sql("SELECT * FROM rpt_table
                            WHERE PRVDR_NUM IN ({turquoise_medicare_provider_id*})",
                            turquoise_medicare_provider_id = medicare_provider_id$medicare_provider_id,
                            .con = hcris_con)
   res <- dbSendQuery(hcris_con, rpt_sql)
   
      # store result in data frame in chunks
   filtered_rpt_df <- data.frame()
   while(!dbHasCompleted(res)){
     chunk <- dbFetch(res, n = 50000)
     filtered_rpt_df <- rbind(filtered_rpt_df, chunk)
   }
   
      # clear result
   dbClearResult(res)
   
      # store RPT_REC_NUM
   rpt_rec_num <- filtered_rpt_df$RPT_REC_NUM
   
   
   # 3a. filter hcris alph table based on filtered_rpt_df RPT_REC_NUM
   alph_sql <- glue::glue_sql("SELECT * FROM alph_table 
                              WHERE RPT_REC_NUM IN ({filtered_rpt_rec_num*})",
                              filtered_rpt_rec_num = rpt_rec_num,
                             .con = hcris_con)
   res <- dbSendQuery(hcris_con, alph_sql)
   
      # store result in data frame in chunks
   filtered_alph_df <- data.frame()
   while(!dbHasCompleted(res)){
     chunk <- dbFetch(res, n = 50000)
     filtered_alph_df <- rbind(filtered_alph_df, chunk)
   }
   
   # clear result
   dbClearResult(res)
   
   
   # 3b. filter hcris nmrc table based on filtered_rpt_df RPT_REC_NUM
   nmrc_sql <- glue::glue_sql("SELECT * FROM nmrc_table 
                              WHERE RPT_REC_NUM IN ({filtered_rpt_rec_num*})",
                              filtered_rpt_rec_num = rpt_rec_num,
                              .con = hcris_con)
   res <- dbSendQuery(hcris_con, nmrc_sql)
   
   # store result in data frame in chunks
   filtered_nmrc_df <- data.frame()
   while(!dbHasCompleted(res)){
     chunk <- dbFetch(res, n = 50000)
     filtered_nmrc_df <- rbind(filtered_nmrc_df, chunk)
   }
   
   # clear result
   dbClearResult(res)
   
   
   # disconnect from hcris db
   dbDisconnect(hcris_con)
   # save filtered hcris tables into list
   tables <- list("filtered_info_df" = filtered_info_df,
                  "filtered_rpt_df" = filtered_rpt_df,
                  "filtered_alph_df" = filtered_alph_df,
                  "filtered_nmrc_df" = filtered_nmrc_df)
   
   print("Connection to HCRIS database now closed")
   # return filtered hcris tables
   return(tables)
  
}


# FUNCTION TO LABEL HCRIS TABLE ROWS
labelHcris <- function(path_, form='10', table_type, table) {
  # Cycles through excel spreadsheet which
  # contains labels for HCRIS data table worksheet
  # codes
  # 
  # Params
  # -----
  #   path_ : character
  #     path to excel spreadsheet containing worksheet code
  #     labels
  #
  #   form : character
  #     which HCRIS form  is being labeled, either 10 or 96
  #
  #   table_type : character
  #     name of HCRIS table being labeled. Either 'alpha', 'nmrc',
  #     'info', or 'rpt'
  #
  #   table : data.frame
  #     HCRIS table being labeled. 
  # 
  # Returns
  # -----
  #   labeled_table : data.frame
  #     HCRIS tables with added column "WKSHT_FIELD_DESCRIP"
  #     containing labels for worksheet codes
      
  # load spreadsheet with labels
  sprdsht <- readxl::read_excel(path_, sheet = "CHECKED RECORD LAYOUT") 
  #return(sprdsht)
  
  # select from the spreadsheet only the labels for the table specified
  labels <- data.frame()
  if(table_type == 'alpha'){
    labels <- sprdsht %>%
      filter(sprdsht[,1]=='ALPHANUMERIC')
  }
  
  if(table_type == 'nmrc'){
    labels <- sprdsht %>%
      filter(sprdsht[,1]=='NUMERIC')
  }
  
  colnames(labels) <- c('DATA_TYPE',	'96_FIELD_NAME',	'10_FIELD_NAME',	'FIELD DESCRIPTION', 	'WKSHT_CD',	'LINE_NUM',	'CLMN_NUM')
  
  #depending on whether 96 or 10 form is being referenced
  # only select the rows where the value under 96_FIELD_NAME or 10_FIELD_NAME column
  # value is not missing or not "not in form"
  keep_index<-vector()
  if(form=='96'){
    keep_index <-grep('.*_.*', labels$`96_FIELD_NAME`)
    labels<-labels[keep_index, -3]
  } else {
    keep_index <-grep('.*_.*', labels$`10_FIELD_NAME`)
    labels<-labels[keep_index, -2]
  }
  
  # join the filtered spreadsheet and the hcris table  
  return(left_join(table, labels[,3:6]))
  
  #--------------------------- Test code on one table --------------------------------#
  # select from the spreadsheet only the labels for the table specified
  # alpha_labels <- data.frame()
  # if(is.null(alphaDf)==FALSE){
  #   alpha_labels <- sprdsht %>%
  #     filter(sprdsht[,1]=='ALPHANUMERIC')
  # }
  # colnames(alpha_labels) <- c('DATA_TYPE',	'96_FIELD_NAME',	'10_FIELD_NAME',	'FIELD DESCRIPTION', 	'WKSHT_CD',	'LINE_NUM',	'CLMN_NUM')
  # #return(alpha_labels)
  # 
  # # depending on whether 96 or 10 form is being referenced
  # # only select the rows where the value under 96_FIELD_NAME or 10_FIELD_NAME column
  # # value is not missing or not "not in form"
  # keep_index<-vector()
  # if(form=='96'){
  #   keep_index <-grep('.*_.*', alpha_labels$`96_FIELD_NAME`)
  #   alpha_labels<-alpha_labels[keep_index, -3]
  # } else {
  #   keep_index <-grep('.*_.*', alpha_labels$`10_FIELD_NAME`)
  #   alpha_labels<-alpha_labels[keep_index, -2]
  # }
  #return(keep_index)
  
  # join the filtered spreadsheet and the hcris table  
  #return(left_join(alphaDf, alpha_labels[,3:6]))
  #------------------------------------------------------------------------#
      
}
