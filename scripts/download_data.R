######################################################
##   download data for BFAST workshop 26 Feb 2019   ##
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
system(sprintf("wget -O %s  https://www.dropbox.com/s/v9j05wo4ruyndda/sieved_LC_2015.tif", paste0(lc15_dir,'sieved_LC_2015.tif')))
system(sprintf("wget -O %s  https://www.dropbox.com/s/9k0dfy1up0h5jcm/LC_2017_18012019.tif", paste0(lc17_dir,'LC_2017_18012019.tif')))
system(sprintf("wget -O %s  https://www.dropbox.com/s/rw995ccinclebws/Protected_Areas_UTMWGS84_dslv.zip", paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.zip')))
system(sprintf("unzip -o %s -d %s ",paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.zip'), mgmt_dir))
system(sprintf("rm %s",paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.zip')))
