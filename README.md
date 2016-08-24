# MPAS2GRADS
how  view MPAS on the GRADS

## 2D VARIABLES
These examples extract only those variables . But it is easy to extract other variables following what was done.

sst  sea surface temperature
surface_pressure surface pressure
t2m     temperature at 2 meters
lh      leaft heat
rainnc  rain from microphysics
rainc   rain from convective
hpbl    hight pbl 

###STEP 1 
edit mpas_to_grads2d.ncl 

edit line  12 

gen_weights =  True

edit line 17  

 files = systemfunc("ls ../06_MPAS/GERAR_CLIMA*.nc")  ;;; where are MAPS outputs file 
 
 edit line 18 (if necessary...is the name of output) 
 
     fout  = addfile ("latlon2d.nc", "c")
     
 
 ###STEP 2 
 run script ncl mpas_to_grads2d.ncl 

ncl mpas_to_grads2d.ncl 

###STEP 3 
After finish, edit again ncl mpas_to_grads2d.ncl 

edit line  12 

gen_weights =  False 

run again script ncl mpas_to_grads2d.ncl 

ncl mpas_to_grads2d.ncl 

###STEP 4 

edit ctl file 

dset ^latlon2d.nc
title xxx
undef 9.999e+20
dtype netcdf
xdef 361 linear 0 1
ydef 181 linear -90 1
zdef 1   linear 1 1 

tdef 837 linear  12Z01JAN1981 1dy    ======>> edit this line as your data

vars 7
sst 0 t,y,x  sea surface temperature
surface_pressure 0 t,y,x  surface pressure
t2m 0 t,y,x  temperature at 2 meters
lh 0 t,y,x  leaft heat
rainnc 0 t,y,x  rain from microphysics
rainc 0 t,y,x  rain from convective
hpbl 0 t,y,x   hight pbl 
endvars 







