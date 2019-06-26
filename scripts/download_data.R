######################################################
##   download data for BFAST workshop 26 Feb 2019   ##
##  and activity data working session 06 May 2019   ##
######################################################

####################################################################################################
####################################################################################################
## DOWNLOAD DATA
## Contact yelena.finegold@fao.org
####################################################################################################
####################################################################################################

## user parameters to get directory names
source('~/uga_activity_data/scripts/get_parameters.R')
## download data 
# system(sprintf("wget -O %s  https://www.dropbox.com/s/wd31qdkzgee062f/bfast_westlbert_co.tif", paste0(bfast_dir,'bfast_westlbert_co.tif')))
# system(sprintf("wget -O %s  https://www.dropbox.com/s/ubqidvnpcwu9blv/Ug2017_CW_gEdits4_co.tif", paste0(lc_dir,'Ug2017_CW_gEdits4_co.tif')))
# system(sprintf("wget -O %s  https://www.dropbox.com/s/z9lvjyttxy04i2q/field_points_feb.zip", paste0(ref_dir,'field_points_feb.zip')))
# system(sprintf("unzip -o %s -d %s ",paste0(ref_dir,'field_points_feb.zip'),paste0(ref_dir,'field_points_feb/')))
# system(sprintf("rm %s",paste0(ref_dir,'field_points_feb.zip')))

system(sprintf("wget -O %s  https://www.dropbox.com/s/mt7oylcqp90hweh/TOTAL_collectedData_earthuri_ce_changes1517_on_080319_151929_CSV.csv", paste0(ref_dir,'TOTAL_collectedData_earthuri_ce_changes1517_on_080319_151929_CSV.csv')))
system(sprintf("wget -O %s  https://www.dropbox.com/s/3ag33hnqsm2if5u/TOTAL_collectedData_earthuri_ce_changes1517_on_080319_151929_CSV_check_potential_XLS_ok_csv.csv", paste0(ref_dir,'ref_data_changes1517_080319.csv')))

system(sprintf("wget -O %s  https://www.dropbox.com/s/v9j05wo4ruyndda/sieved_LC_2015.tif", paste0(lc15_dir,'sieved_LC_2015.tif')))
system(sprintf("wget -O %s  https://www.dropbox.com/s/9k0dfy1up0h5jcm/LC_2017_18012019.tif", paste0(lc17_dir,'LC_2017_18012019.tif')))
system(sprintf("wget -O %s  https://www.dropbox.com/s/d4n1ks7usibtmly/Protected_Areas.zip", paste0(mgmt_dir,'Protected_Area.zip')))
system(sprintf("unzip -o %s -d %s ",paste0(mgmt_dir,'Protected_Area.zip'), mgmt_dir))
system(sprintf("rm %s",paste0(mgmt_dir,'Protected_Area.zip')))
system(sprintf("wget -O %s https://www.dropbox.com/s/j08tv54kr0bay0f/usernames_uga.csv", paste0(mgmt_dir,'usernames_uga.csv')))

## updated shapefile with 2015 and 2017 maps
system(sprintf("wget -O %s https://www.dropbox.com/s/kas4zcxuo6sdb8t/LULC_2017_as_at_10_May_2019_by_edward.zip", paste0(lc17_dir,'LULC_2017_as_at_10_May_2019_by_edward.zip')))
system(sprintf("unzip -o %s -d %s ",paste0(lc17_dir,'LULC_2017_as_at_10_May_2019_by_edward.zip'), lc17_dir))
system(sprintf("rm %s",paste0(lc17_dir,'LULC_2017_as_at_10_May_2019_by_edward.zip')))

## dowload the national scale BFAST output
## this is 5.6 GB and the download will take a long time
system(sprintf("wget -O %s https://www.dropbox.com/s/bg0fqoz1fwu4emc/all_bfast.tif", paste0(bfast_dir,'all_bfast.tif')))

##read the uganda district mask
system(sprintf("wget -O %s https://www.dropbox.com/s/icti0c6pghrb34v/UG_districts_Mask.zip", paste0(ug_mask_dir,'UG_districts_Mask.zip')))
system(sprintf("unzip -o %s -d %s ",paste0(ug_mask_dir,'UG_districts_Mask.zip'), ug_mask_dir))
system(sprintf("rm %s",paste0(ug_mask_dir,'UG_districts_Mask.zip')))

