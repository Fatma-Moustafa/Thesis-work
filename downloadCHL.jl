using PyCall  # To use Python modules and functions in Julia
using Dates   # To play with dates
os = pyimport("os")

username = "fmoustafa"
password ="Fatoom88"

startDate = Date(2018, 1, 1)
endDate = Date(2019, 12, 31)

# Geographic area and depth level 
lon = (6,36.5)     # longitude min/max ##check is it 6 or -6!!!!
lat = (30, 46)      #latitude min/max

output_dir = pwd()
out_name = "MED_CHL_$(startDate)_$endDate.nc"


#query= "python3 -m motuclient --motu http://my.cmems-du.eu/motu-web/Motu --service-id OCEANCOLOUR_MED_BGC_L3_MY_009_143-TDS --product-id cmems_obs-oc_med_bgc-plankton_my_l3-multi-1km_P1D --longitude-min $(lon[1]) --longitude-max $(lon[2]) --latitude-min $(lat[1]) --latitude-max $(lat[2]) --date-min $startDate --date-max $endDate --variable CHL --out-dir $output_dir --out-name $out_name --user $username --pwd $password"
query= "python3 -m motuclient --motu http://my.cmems-du.eu/motu-web/Motu --service-id OCEANCOLOUR_GLO_BGC_L3_MY_009_107-TDS --product-id c3s_obs-oc_glo_bgc-plankton_my_l3-multi-4km_P1D --longitude-min -6 --longitude-max 36.5 --latitude-min 30 --latitude-max 46 --date-min $startDate --date-max $endDate --variable CHL --out-dir $output_dir --out-name $out_name --user $username --pwd $password"

os.system(query)