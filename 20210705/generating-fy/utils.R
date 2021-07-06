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
