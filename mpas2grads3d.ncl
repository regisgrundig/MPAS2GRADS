;------------------------------------------
; 
; MPAS TO GRADS  3D VARIABLES 
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
if (isfilepresent("src_grid.nc") .and. isfilepresent("dst_grid.nc") .and. isfilepresent("weight .nc") ) 
   print("regrid OK")
   else
   mpas = f[:]->uReconstructZonal
   var=regrid(True,mpaslon,mpaslaae  mpas) 
end if
;
; select vars 
;
mpas = f[:]->uReconstructZonal
u=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->uReconstructMeridional
v=regrid(False,mpaslon,mpaslat,mpas) 
mpas = f[:]->divergence
div=regrid(False,mpaslon,mpaslat,mpas) 

;
;
;clean
;
delete(mpas)
;
; get dimensios
dims=dimsizes(u)
nTime   = dims(0)
nLevels = dims(1) 
nLat    = dims(2)
nLon    = dims(3)

;
;  1x1 grid 
;
lat = fspan(-90.00d,90.00d,nLat)
lon = fspan(-180.00d,180.00,nLon)
;
; create new netcdf file 
;
fout  = addfile ("mpasgrads3d.nc", "c")
dimNames = (/"Time", "lat" , "lon" , "levels"/)
dimSizes = (/-1    , nLat  , nLon  , nLevels /)
dimUnlim = (/True  , False , False , False   /)
;
;
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
filevardef(fout,"u",typeof(u),(/"Time","levels","lat","lon"/))
filevardef(fout,"v",typeof(v),(/"Time","levels","lat","lon"/))
filevardef(fout,"div",typeof(div),(/"Time","levels","lat","lon"/))
;
;... output data:
;
fout->latitude  = (/lat/)
fout->longitude = (/lon/)
fout->u = (/u/)
fout->v = (/v/)
fout->div = (/div/)
end

