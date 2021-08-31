import requests
from bs4 import BeautifulSoup
import io
import zipfile
import re
from pandas import read_csv
import numpy as np

# create dictionaries of urls with cost report zip files
year_urls = {
'1995' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-1995',
'1996' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-1996',
'1997' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-1997',
'1998' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-1998',
'1999' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-1999',
'2000' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2000',
'2001' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2001',
'2002' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2002',
'2003' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2003',
'2004' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2004',
'2005' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2005',
'2006' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2006',
'2007' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2007',
'2008' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2008',
'2009' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSP-DL-2009',
'2010' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2010',
'2011' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2011',
'2012' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2012',
'2013' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2013',
'2014' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2014',
'2015' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2015',
'2016' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2016',
'2017' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2017',
'2018' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2018',
'2019' : 'https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/Cost-Reports/Cost-Reports-by-Fiscal-Year-Items/HOSPITAL10-DL-2019',
'2020' : 'https://www.cms.gov/research-statistics-data-and-systemsdownloadable-public-use-filescost-reportscost-reports-fiscal/2020'
}

info_urls = {
  "96_form" : 'https://downloads.cms.gov/files/hcris/HOSP-REPORTS.ZIP',
  "10_form" : 'https://downloads.cms.gov/files/hcris/hosp10-reports.zip' 
}

# set table column names
alphNames = ["RPT_REC_NUM", "WKSHT_CD", "LINE_NUM", "CLMN_NUM", "ITM_ALPHNMRC_ITM_TXT"]
nmrcNames = ["RPT_REC_NUM", "WKSHT_CD", "LINE_NUM", "CLMN_NUM", "ITM_VAL_NUM"]
rptNames = ["RPT_REC_NUM", "PRVDR_CTRL_TYPE_CD", "PRVDR_NUM",
            "NPI", "RPT_STUS_CD", "FY_BGN_DT", "FY_END_DT",
            "PROC_DT", "INITL_RPT_SW", "LAST_RPT_SW",
            "TRNSMTL_NUM", "FI_NUM", "ADR_VNDR_CD",
            "FI_CREAT_DT", "UTIL_CD", "NPR_DT",
            "SPEC_IND", "FI_RCPT_DT"]
            
#infoNames = ["PROVIDER_NUMBER", "FYB", "FYE", "STATUS",
#              "CTRL_TYPE", "HOSP_Name", "Street_Addr", "PO_Box",
#              "City", "State", "Zip_Code", "County", "Urban1_Rural2"]

# set table column types         
alphTypes = {"RPT_REC_NUM" : np.int32, 
            "WKSHT_CD" : np.str_, 
            "LINE_NUM" : np.str_, 
            "CLMN_NUM": np.str_, 
            "ITM_ALPHNMRC_ITM_TXT" : np.str_}
            
nmrcTypes = {"RPT_REC_NUM" : np.int32,
            "WKSHT_CD" : np.str_, 
            "LINE_NUM" : np.str_, 
            "CLMN_NUM" : np.str_, 
            "ITM_VAL_NUM" : np.float64}
            
rptTypes = {"RPT_REC_NUM" : np.int32, 
            "PRVDR_CTRL_TYPE_CD" : np.str_, 
            "PRVDR_NUM" : np.str_,
            "NPI" : np.float64, 
            "RPT_STUS_CD" : np.str_, 
            "FY_BGN_DT" : np.str_, 
            "FY_END_DT" : np.str_,
            "PROC_DT" : np.str_, 
            "INITL_RPT_SW" : np.str_, 
            "LAST_RPT_SW" : np.str_,
            "TRNSMTL_NUM" : np.str_, 
            "FI_NUM" : np.str_, 
            "ADR_VNDR_CD" : np.str_,
            "FI_CREAT_DT" : np.str_, 
            "UTIL_CD" : np.str_, 
            "NPR_DT" : np.str_,
            "SPEC_IND" : np.str_, 
            "FI_RCPT_DT" : np.str_}  


infoTypes = {"PROVIDER_NUMBER" : np.str_,
              "FYB" : np.str_,
              "FYE" : np.str_, 
              "STATUS" : np.str_,
              "CTRL_TYPE" : np.str_, 
              "HOSP_Name" : np.str_, 
              "Street_Addr" : np.str_, 
              "PO_Box" : np.str_,
              "City" : np.str_, 
              "State" : np.str_, 
              "Zip_Code" : np.str_, 
              "County" : np.str_, 
              "Urban1_Rural2" : np.str_}

def getCostReport(year):
    '''
    Saves cost reports for a given year found at CMS.gov  
    (alphanumeric, numeric, and report tables) as dataframes.

    Params
    ------
    year : str
        Which year to download HCRIS cost reports from.

    Returns
    ------
    alpha_df : dataframe
        alpha-numeric dataframe for selected year

    nmrc_df : dataframe
        numeric dataframe for selected year

    rpt_df : dataframe
        report dataframe for selected year
    '''

    if year in list(year_urls):
        # get content from web page that contains download url
        web_r = requests.get(year_urls[year])
        web_soup = BeautifulSoup(web_r.text, 'html.parser')
        
        # seach the page content for the link to download cost report zip file (stored in a tag within div with class "node__content clearfix")
        download_url = [i.attrs.get('href') for i in web_soup.select('div[class="node__content clearfix"] a')][0]
        #print(download_url)

        # get content from download link
        dload_r = requests.get(download_url, stream=True)
        
        # download zipfile in chunks from download url into binary stream (file-like object) in memory
        filebytes = io.BytesIO()
        for chunk in dload_r.iter_content(chunk_size=500_000):
            if chunk:
                filebytes.write(chunk)
        
        # create zipfile object
        zipfile_ = zipfile.ZipFile(filebytes)
        #return(zipfile_)
        # print(zipfile_.namelist()) # => ['HOSP_1995_ALPHA.CSV', 'HOSP_1995_NMRC.CSV', 'HOSP_1995_ROLLUP.CSV', 'HOSP_1995_RPT.CSV']

        # identify indices of target contents (alpha, nmrc, and rpt) in zipfile list of contents
        contents = zipfile_.namelist()
        alph_index = list()
        nmrc_index = list()
        rpt_index = list()


        for file_ in range(len(contents)):
            match = re.search(pattern = '.*ALPH.*', string=contents[file_])

            if match:
                alph_index.append(file_)

        for file_ in range(len(contents)):
            match = re.search(pattern = '.*NMRC.*', string=contents[file_])

            if match:
                nmrc_index.append(file_)

        for file_ in range(len(contents)):
            match = re.search(pattern = '.*RPT.*', string=contents[file_])

            if match:
                rpt_index.append(file_)

        # return target zipfile contents
        #items_file  = io.TextIOWrapper(zipfile_.open(zipfile_.namelist()[1]))
        #print(type(items_file))
        alpha_file  = io.TextIOWrapper(zipfile_.open(contents[alph_index[0]]))
        nmrc_file  = io.TextIOWrapper(zipfile_.open(contents[nmrc_index[0]]))
        rpt_file  = io.TextIOWrapper(zipfile_.open(contents[rpt_index[0]]))
        
        #return csv files with correct column names and column types
        alpha_df = read_csv(alpha_file, header=None, names=alphNames, dtype=alphTypes)
        nmrc_df = read_csv(nmrc_file, header=None, names=nmrcNames, dtype=nmrcTypes)
        rpt_df = read_csv(rpt_file, header=None, names=rptNames, dtype=rptTypes)
        
        # replace NaN with blank spaces (so databases can be constructed in R; they don't recognize np.nan)
        alpha_df.replace(np.nan, '', inplace=True)
        nmrc_df.replace(np.nan, '', inplace=True)
        rpt_df.replace(np.nan, '', inplace=True)
              
        return alpha_df, nmrc_df, rpt_df
        #print(type(zipfile_.open(contents[alph_index[0]])))
        #return zipfile_.open(contents[alph_index[0]]).read(), zipfile_.open(contents[nmrc_index[0]]).read(), zipfile_.open(contents[rpt_index[0]]).read()
        #return zipfile_.open(contents[alph_index[0]]), zipfile_.open(contents[nmrc_index[0]]), zipfile_.open(contents[rpt_index[0]])
        
    else:
        print("Cost reports not found for this year.")


def getHospInfo(hospital_form):
  '''
  Saves the hospital provider id info table from either the hosp10 or the hosp95 form
  found at CMS.gov as a dataframe.
  
  Params
  ------
  hospital_form : str
    Either '10' or '95'.
    Which hospital form to download 
    provider id info table from
    
    
  Returns
  ------
  info_df : dataframe
    hospital provider id info table
  '''
  download_url = str()
  if hospital_form == '10':
    download_url = info_urls['10_form']
  
  else:
    download_url = info_urls['96_form']
    
  # get content of download url (aka zip file)
  r = requests.get(download_url, stream=True) 
  
  # open byte stream and write download filebytes (zipfile) into byte stream in memory
  filebytes = io.BytesIO()
  for chunk in r.iter_content(chunk_size=500_000):
    if chunk:
      filebytes.write(chunk)
  
  # save downloaded file bytes (zipfile) into zipfile object
  zipfile_ = zipfile.ZipFile(filebytes)
  
  # save the name of the csv file that has hospital provider ids
  zip_contents = zipfile_.namelist()
  target_file_name = str()
  
  for element in zip_contents:
    match = re.search(pattern='.*PROVIDER_ID.*', string=element)
    # if match is found (aka match evaluates to True) save the whole string as the target file's name
    if match:
      target_file_name = match.group(0)
  
  # open target file's bytes in text wrapper and save
  info_file = io.TextIOWrapper(zipfile_.open(target_file_name))
  
  # read file as csv, where column names are taken from first row
  # also set all columns' types to string
  info_df = read_csv(info_file, header=0, dtype=np.str_)
  
  # replace missing values (np.nan) with blank spaces so dfWriteTable doens't draw an error
  info_df.replace(np.nan, '', inplace=True)
  
  return info_df
  
 
