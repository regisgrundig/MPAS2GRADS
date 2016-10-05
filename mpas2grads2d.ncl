;------------------------------------------
; 
; MPAS TO GRADS 2
; 
; baseado no script ncl mpas_to_latlon.ncl 
;
; carrega o banco de funcoes 
;
; na verdade so precisa da funcao REGRID 
;
; resultado final é um grid de 1x1 grau.
; modifcar se outra resolucao
;
;
load "./mpas_ncl_regis.ncl"
;
begin
print ("INICIO PROCESSAMENTO")
;
;... read input MPAS files:
;
files = systemfunc("ls GERAR*.nc")
f = addfiles(files,"r")
;
;... get lat/lon coordinates from first input file
;
r2d  = 180.0d/(atan(1)*4.0d) ; conversion from radians to degrees.
mpaslon = f[0]->lonCell * r2d
mpaslat = f[0]->latCell * r2d
;
; Whether to generate remapping weight files, or 
;   to actually regrid fields
;  verify if src_grid.nc dst_grid.nc weights.nc exist
;   if exist OK if not generate weights.
;  to regrid need create some files do work do.  
;
if (isfilepresent("src_grid.nc") .and. isfilepresent("dst_grid.nc") .and. isfilepresent("weights.nc") ) 
   print("regrid OK")
   else
   mpas = f[:]->t2m
   var=regrid(True,mpaslon,mpaslat,mpas) 
end if
;
; select vars 
;
mpas = f[:]->t2m
t2m=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->sst
sst=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->surface_pressure
sp=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->lh
lh=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->rainnc
rainnc=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->rainc
rainc=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->hpbl
hpbl=regrid(False,mpaslon,mpaslat,mpas) 
;
; clean
;
delete(mpas)
;
; get dimensios
;
dims=dimsizes(t2m)
nTime   = dims(0)
nLat    = dims(1)
nLon    = dims(2)
;
;  1x1 grid 
;
lat = fspan(-90.00d,90.00d,nLat)
lon = fspan(-180.00d,180.00,nLon)
;
; create new netcdf file 
;
fout  = addfile ("mpasgrads.nc", "c")
dimNames = (/"Time", "lat" , "lon"/)
dimSizes = (/-1    , nLat  , nLon/)
dimUnlim = (/True  , False , False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)
;
;copy global atttibutes from the input to the output file:
;
fileattdef(fout,f[0])
;
;... predefine the dimensionality of the variables to be written out:
;
filevardef(fout,"latitude" ,typeof(lat)  ,(/"lat"/))
filevardef(fout,"longitude",typeof(lon)  ,(/"lon"/))
filevardef(fout,"sst",typeof(sst),(/"Time","lat","lon"/))
filevardef(fout,"sp",typeof(sp),(/"Time","lat","lon"/))
filevardef(fout,"t2m",typeof(t2m),(/"Time","lat","lon"/))
filevardef(fout,"lh",typeof(lh),(/"Time","lat","lon"/))
filevardef(fout,"rainnc",typeof(rainnc),(/"Time","lat","lon"/))
filevardef(fout,"rainc",typeof(rainc),(/"Time","lat","lon"/))
filevardef(fout,"hpbl",typeof(hpbl),(/"Time","lat","lon"/))
;
;... output data:
;
fout->latitude  = (/lat/)
fout->longitude = (/lon/)
fout->sst = (/sst/)
fout->sp = (/sp/)
fout->t2m = (/t2m/)
fout->lh = (/lh/)
fout->rainnc = (/rainnc/)
fout->rainc = (/rainc/)
fout->hpbl = (/hpbl/)
end

