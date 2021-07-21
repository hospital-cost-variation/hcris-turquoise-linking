import requests
from bs4 import BeautifulSoup
import os
import zipfile

urls = {
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


# create DATA directory in current working directory if not already created 
if os.path.exists(str(os.getcwd()+'/DATA')) == False:
    os.mkdir(str(os.getcwd()+'/DATA'))

# for each link..
for n in range(len(urls)):
    #print(urls[n])
    
    # make http request to get content at url
    reqs = requests.get(list(urls.values())[n])
    soup = BeautifulSoup(reqs.text, 'html.parser')
    # search the page for the link to the zip file (stored in the a tage in a div tag with given class)
    zip_url = [i.attrs.get('href') for i in soup.select('div[class="node__content clearfix"] a')][0]
    #print(zip_url)

    # download zip file from url
        # name file as the text after the last '/' in the url
    file_name_start_pos = zip_url.rfind("/") + 1
    file_name = zip_url[file_name_start_pos:]

        # create directory for the specified year if one does not already exist
        # find all groups of numbers and store as year
    # year = re.findall('[0-9]+', str(zip_url))[0]
    year = list(urls)[n]
    #print(year)
    if os.path.exists(str(os.getcwd()+'/DATA/'+str(year))) == False:
        os.mkdir(str(os.getcwd()+'/DATA/'+str(year)))

        # save zip file
    r = requests.get(zip_url, stream=True)
    if r.status_code == requests.codes.ok:
        with open(str(os.getcwd()+'/DATA/'+str(year)+'/'+file_name), 'wb') as f:
            for data in r:
                f.write(data)
        
    # unzip file
    with zipfile.ZipFile(str(os.getcwd()+'/DATA/'+str(year)+'/'+file_name), 'r') as zip_ref:
        zip_ref.extractall(str(os.getcwd()+'/DATA/'+str(year)))

    # delete zip file
    os.remove(str(os.getcwd()+'/DATA/'+str(year)+'/'+file_name))