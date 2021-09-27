library(tidyverse)  

#Download the Hospital_General_Infor df for ratings from CMS AND the price_transparency_provider df from the turquoise data

#Rename the column name in Hospital General Info df so it matches the PT Provider df
colnames(Hospital_General_Information)[1] = "medicare_provider_id"

#merge the two df's by the medicare provider id
RatingSystemdf = merge(Hospital_General_Information, price_transparency_provider, by="medicare_provider_id")

#Write the csv file
write.csv(RatingSystemdf,"/Users/ronyochakovski/OneDrive - Duke University/Research//CMSRatingSystemProviderLink.csv")
