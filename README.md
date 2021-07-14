# hcris-file-rendering  
## 20210705
### generating-lookup folder
Contains:  
1.  utils.R file with functions to (a) load hcris cost report tables, (b) get user input from excel spreadsheet,
(c) create lookup tables  
2. R notebook with example workflow  

### generating-fy folder
Contains:  
1.  utils.R file with functions to calculate weighted fiscal years  
2. R notebook with example workflow  

### supplementary folder
Contains supplementary files referenced while writing functions.   
Specifically contains HCRIS Data Dictionary and HCRIS database diagram. Used to (a) appropriately set the column names of the Report, Numeric, and Alpha-numeric tables, (b) appropriately set the column types for the Report, Numeric, and Alpha-numeric tables, (c) determine how to link tables for lookup table function.

### data
Contains HCRIS cost report tables organized by fiscal year. Each year's folder contains Report, Numeric, and Alpha-numeric tables. There is one Hospital Provider ID Info table for the years 1995-2009 and Hospital Provider ID Info table for the years 2010-2020.
