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



# FUNCTION TO INDENTIFY WHICH ROWS OF A TABLE MEET USER INPUT CRITERIA
getUser_input <- function(path, headers_=FALSE, table){
  # Params
  # -------
  # path : character
  #   File path leading to excel spreadsheet containing unquoted user input
  #   values in the order worksheet code, line number, and column number.
  #
  # headers_ : logical
  #   Whether or not excel spreadsheet being imported contains headers (column
  #   names).
  #
  # table : data.frame
  #   Table which will be filtered, either Numeric table or Alpha-numeric table.
  #   With accurate column names and column classes.
  #
  # Returns
  # -------
  # index_ : vector
  #   locations in table that correspond to userInput values
  
  
  # Read in user input table
  # if spreadsheet contains headers indicate col_names as TRUE
  if(headers_ == TRUE) {
    userInput <- read_excel(path, col_names = TRUE,
                            col_types ="text")
  } else {
    userInput <- read_excel(path, col_names = FALSE,
                            col_types = "text")
  }
  
  
  # cycle through each row of table and create a conditional statement for 
  # each row of userInput table
  s <- matrix()
  vector<-vector()
  
  no_conditions <- dim(userInput)[1]
  for( row in c(1:no_conditions) ){
    WKSHT_CD <- as.character(userInput[[row, 1]])
    LINE_NUM <- as.character(userInput[[row, 2]])
    CLM_NUM <- as.character(userInput[[row, 3]])
    
      vector <- append(vector, 
                 paste(table[,2]==WKSHT_CD, "&",
                 table[,3]==LINE_NUM, "&",
                 table[,4] == CLM_NUM))
  }
  
  # create matrix where each row corresponds to one row of the table
  # and each column corresponds to evaluation of one user condition for that row
  s<-matrix(vector, ncol=no_conditions)
    
  
  # for each row of the matrix identify if the row meets at least one of the userInput criteria...
  index_<-vector()
  for(row in c(1:dim(s)[1])) {
  # start evaluating each column condition
      for(col in c(1:dim(s)[2])){
        # if you encounter a true statement stop examining row and move to the next row
        if(eval(parse(text=s[row,col])) == TRUE){
          index_<-append(index_, row)
          row <- row+1
          break
        }
      }
  }
  
    # return row indices
    return(index_)
}



# FUNCTION TO CREATE LOOK-UP TABLES
createLookup <- function(index_num, numTable, index_alph, alphTable, rptTable,
                         infoTable){
  # Searches numeric and alpha numeric tables for data values which match user input. Returns list of matching 
  # values in alpha, numeric, report, and hospital provider id info tables.
  
  # Params
  # ------
  # index_num : vector
  #   positions to filter primary table on as returned by getUser_input().
  #
  # numTable : data.frame
  #   Numeric HCRIS table which will be searched for 
  #   user input values. With accurate column names and classes.
  #
  # index_alph : vector
  #   positions to filter primary table on as returned by getUser_input().
  #
  # alphTable : data.frame
  #   Alpha-numeric HCRIS table which will be searched for 
  #   user input values. With accurate column names and classes.
  # 
  # rptTable : data.frame
  #   Report table which will be used to create first linking table.
  #   With accurate column names and classes.
  #  
  # infoTable : data.frame
  #   Hospital provider ID Info table which will be used to create  
  #   second linking table. With accurate column names and classes.
  # 
  # 
  # Returns
  # ------
  # tables : list
  #   primary table, first linking table, second linking table saved under list names
  #   "primary table", "report linking table", and "hospital information linking table"
  #
  
  # Generate primary table
  prim_table <- data.frame()
  
  # 1. First, search numeric table 
  table_num <- data.frame()
  
  # if getUser_input() returns values...
  if(!is_empty(index_num)){
    # 1. create filtered numTable
    table_num <- numTable[index_num,]
    # 2. add column to numTable which identifies where values of user_inputs were found 
    # aka (in "nmrc" table)
    table_num$NUM_ALPHA <- as.vector(matrix("nmrc", ncol=1, nrow=dim(table_num)[1]))
    
    # 2. save numeric table as primary table
    prim_table <- table_num
  }
  
  # 2. Second, search alpha-numeric table
  table_alph <- data.frame()
  
  # if getUser_input() returns values update prim_table
  if(!is_empty(index_alph)){
    # 1. create filtered alphTable
    table_alph <- alphTable[index_alph,]
    # 2. add column to table_alph which identifies where values of user_inputs were found
    table_alph$NUM_ALPHA <- as.vector(matrix("alph_nmrc", ncol=1, nrow=dim(table_alph)[1]))
    
    # 3. stack table_alph horizontally to the bottom of prim_table
      prim_table <- rbind(prim_table, table_alph)
      
    }
  
  
  # Generate first linking table using RPT_REC_NUM
  # 1. Find index of which rptTable record numbers are in the prim_table record numbers
  index <- rptTable$RPT_REC_NUM %in% prim_table$RPT_REC_NUM
  # 2. Save linking rpt table with prim_table record numbers only 
  linking_rptTable <- rptTable[index, ]
  
  
  # Generate second linking table
  # 1. Find index of which infoTable table provider numbers are in the linking_rptTable
  index <- infoTable$PROVIDER_NUMBER %in% rptTable$PRVDR_NUM
  # 2. Save linking info table to show prim_table record numbers only 
  linking_infoTable <- infoTable[index, ]
  
  
  return(list("primary table"=prim_table, 
              "report linking table"=linking_rptTable, 
              "hospital information linking table"=linking_infoTable))
}
