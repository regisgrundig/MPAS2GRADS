load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "./shapefile_utils.ncl"



function grafico (  var , shpfile , mode , nome , opcao)   
  ;shpfile   = "GSHHS_shp/c/GSHHS_c_L1.shp"
;----------------------------------------------------------------------
;  grafico
;
;   var = variavel from MPAS
;  shpfile = shapefile do mundo 
;  mode  =  x11 png pdf 
;  opcao (1) = mapa comum
;  opcao (2) = mapa landmask
;  opcao (1) = mapa oceanlandmask
;  opcao (1) = 3 mapas 
;
; Concepts illustrated:
;   - Using a worldwide shapefile to create a land/ocean mask
;   - Masking a data array based on a geographical area
;   - Attaching shapefile polylines to a map plot
;   - Attaching lat/lon points to a map using gsn_coordinates
;----------------------------------------------------------------------
; Downloaded GSHHS shapefiles from:
;
;  http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhg/latest/
;
; Used the "coarsest" one: "GSHHS_shp/c/GSHHS_c_L1.shp".
;----------------------------------------------------------------------
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file, being a user-created file, is not automatically loaded
;----------------------------------------------------------------------
; Main code
;----------------------------------------------------------------------
begin 
  WRITE_MASK = True
  DEBUG      = False

;
; Create a mask array the same size as "u", using
; lat/lon data read off a shapefile.
;
  opt             = True
  opt@return_mask = True
  u=var

  land_mask = shapefile_mask_data(u,shpfile,opt)

;---Mask "u" against land and ocean.
  u_land_mask  = where(land_mask.eq.1,u,u@_FillValue)
  u_ocean_mask = where(land_mask.eq.0,u,u@_FillValue)
  copy_VarMeta(u,u_land_mask)
  copy_VarMeta(u,u_ocean_mask)

;---Start the graphics
  wks = gsn_open_wks(mode,nome)           ; send graphics to PNG file

  res                       = True

  res@gsnMaximize           = True           ; maximize plot in frame
  res@gsnDraw               = False          ; don't draw plot yet
  res@gsnFrame              = False          ; don't advance frame yet

  res@cnFillOn              = True
  res@cnLineLabelsOn        = False
  res@cnLinesOn             = False

;---Make sure both plots have same contour levels
  mnmxint                   = nice_mnmxintvl(min(u),max(u),25,False)
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = mnmxint(0)
  res@cnMaxLevelValF        = mnmxint(1)
  res@cnLevelSpacingF       = mnmxint(2)

  res@lbLabelBarOn          = False
  res@gsnAddCyclic          = False

  res@mpFillOn              = False
  res@mpOutlineOn           = False

  res@gsnRightString        = ""
  res@gsnLeftString         = ""

;---Create plot of original data and attach shapefile outlines
  res@tiMainString         = nome 
  map_data = gsn_csm_contour_map(wks,u,res)
  dum1     = gsn_add_shapefile_polylines(wks,map_data,shpfile,False)

;---Create plots of masked data

  res@tiMainString         = nome
  map_land_mask  = gsn_csm_contour_map(wks,u_land_mask,res)
  res@tiMainString         = nome 
  map_ocean_mask = gsn_csm_contour_map(wks,u_ocean_mask,res)

  if(DEBUG) then
    mkres                 = True
;    mkres@gsMarkerSizeF   = 0.007
    mkres@gsnCoordsAttach = True
    gsn_coordinates(wks,map_data,u,mkres)
    mkres@gsnCoordsNonMissingColor = "yellow"
    mkres@gsnCoordsMissingColor    = "black"
    gsn_coordinates(wks,map_land_mask,u_land_mask,mkres)
    gsn_coordinates(wks,map_ocean_mask,u_ocean_mask,mkres)
  end if

;---Add shapefile outlines
  dum2 = gsn_add_shapefile_polylines(wks,map_land_mask,shpfile,False)
  dum3 = gsn_add_shapefile_polylines(wks,map_ocean_mask,shpfile,False)

;---Draw all three plots on one page
  pres                  = True
  pres@gsnMaximize      = True
  pres@gsnPanelLabelBar = True
  ;gsn_panel(wks,(/map_data,map_land_mask,map_ocean_mask/),(/1,1/),pres)
  ;gsn_panel(wks,(/map_data,map_land_mask,map_ocean_mask/),(/1,1/),pres)
  
  if (opcao .eq. 1 )
  gsn_panel(wks,(/map_data/),(/1,1/),pres)
  end if

  if (opcao .eq. 2 )
  gsn_panel(wks,(/map_land_mask/),(/1,1/),pres)
  end if

  if (opcao .eq. 3 )
  gsn_panel(wks,(/map_ocean_mask/),(/1,1/),pres)
  end if

  if (opcao .eq. 4 )
  gsn_panel(wks,(/map_data,map_land_mask,map_ocean_mask/),(/3,1/),pres)
  end if

 return(1)
end

 
   




;------------------------------------------------------------------------
;
;  funcao REGRID MAPS 
;
;  transforma variavel MPAS nao estruturado em LATLON 
;
;   regrid( gen_weights, lon, lat ,var )
;
;   gen_weights =  True => gera mapa de pesos
;                  False => faz o regrid
;
;   lon e lat -> lon e lat não estruturado do MPAS 
;
;  var  -> variavel  MPAS
;
;
function  regrid (gen_weights  , lon ,  lat ,  var)   
begin

   ;
   ; Whether to generate remapping weight files, or 
   ;   to actually regrid fields
   ;
   ;
   ; gen_weights = peso 
   ;
   ;
   ;... interpolation to 1-deg latitude-longitude grid:
   ;
   opt = True
   opt@ForceOverwrite = True
   opt@SrcGridLon = lon ; source grid lon input.
   opt@SrcGridLat = lat ; source grid lat input.
   opt@SrcGridType = "unstructured"
   opt@DstGridType = "1.0x1.0" ; destination grid
   opt@DstLLCorner = (/-89.50d, -179.50d /)
   opt@DstURCorner = (/ 89.50d,  179.50d /)
   opt@DstLLCorner = (/-90.00d, -180.00d /)
   opt@DstURCorner = (/ 90.00d,  180.00d /)
   opt@SrcFileName = "src_grid.nc"
   opt@DstFileName = "dst_grid.nc"
   opt@WgtFileName = "weights.nc"
   ;
   ;... get dimension sizes and predefine the coordinate variables and their dimensionality:
   ;
   dims = dimsizes(var)
   rank = dimsizes(dims)
   nTime   = dims(0)
   nCells  = dims(1)
   if (rank .eq. 3) then
      nLevels = dims(2)
   end if
   ;print(" INSEDE REGRID--------")
   ;print("nTime   = "+nTime  )
   ;print("nCells  = "+nCells )
   if (rank .eq. 3) then
      print("nLevels = "+nLevels)
   end if
   ;print("          ")
   delete(dims)

   ; 3-d fields need to have the nCells and nVertLevels dimensions swapped
   if (gen_weights) then

      print("Generating remapping weights...")

         var_final = ESMF_regrid(var(0,:),opt)

   else

      print("Remapping fields...")

      var_final = ESMF_regrid_with_weights(var,opt@WgtFileName,False)
   end if
return(var_final)
end


;---------------------------------------------------------------
;
;  funcao para plotar mapa 
;
;
function prota( variavel , lat , lon , nome) 
begin 
  xwks = gsn_open_wks("x11","prota porra do mapa")      ; Open an X11 workstation.
;----------- Begin second plot -----------------------------------------

  resources                 = True       ; Indicate you want to set some
  resources@cnMonoLineColor = True      ; Turn off the drawing of
  resources@tiMainString    =  nome    ; Create a title.
  resources@cnFillOn          = True        ; Turn on contour line fill.
  resources@cnMonoFillPattern = False       ; Turn off using a single fill
  resources@cnMonoFillColor   = False
  resources@cnMonoLineColor   = False
  resources@tiXAxisString    = "longitude"
  resources@tiYAxisString    = "latitude"
  resources@sfXArray         = lon
  resources@sfYArray         = lat 
  resources@cnMonoFillPattern     = True     ; Turn solid fill back on.
  resources@cnMonoFillColor       = False    ; Use multiple colors.
  resources@cnLineLabelsOn        = False    ; Turn off line labels.
  resources@cnInfoLabelOn         = False    ; Turn off informational
  resources@cnLinesOn             = False    ; Turn off contour lines.
  resources@pmLabelBarDisplayMode = "Always" ; Turn on label bar.
  resources@lbPerimOn             = False    ; Turn off perimeter on
  resources@tiMainFont      = 26
  resources@tiXAxisFont     = 26
  resources@tiYAxisFont     = 26

  plot = gsn_contour(xwks,variavel,resources)   ; Draw a contour plot.
  return(xwks)
end 

