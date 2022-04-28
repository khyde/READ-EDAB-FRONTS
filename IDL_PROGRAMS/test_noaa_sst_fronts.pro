; $ID:	TEST_NOAA_SST_FRONTS.PRO,	2022-03-31-11,	USER-KJWH	$
  PRO TEST_NOAA_SST_FRONTS

;+
; NAME:
;   TEST_NOAA_SST_FRONTS
;
; PURPOSE:
;   Program to test the fronts on the geopolar blended SST product from NOAA
;
; PROJECT:
;   READ-EDAB-FRONTS
;
; CALLING SEQUENCE:
;   TEST_NOAA_SST_FRONTS,$Parameter1$, $Parameter2$, $Keyword=Keyword$, ....
;
; REQUIRED INPUTS:
;   Parm1.......... Describe the positional input parameters here. 
;
; OPTIONAL INPUTS:
;   Parm2.......... Describe optional inputs here. If none, delete this section.
;
; KEYWORD PARAMETERS:
;   KEY1........... Document keyword parameters like this. Note that the keyword is shown in ALL CAPS!
;
; OUTPUTS:
;   OUTPUT.......... Decribe the output of this program or function
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS: 
;   None
;
; SIDE EFFECTS:  
;   None
;
; RESTRICTIONS:  
;   None
;
; EXAMPLE:
; 
;
; NOTES:
;   $Citations or any other useful notes$
;   
; COPYRIGHT: 
; Copyright (C) 2022, Department of Commerce, National Oceanic and Atmospheric Administration, National Marine Fisheries Service,
;   Northeast Fisheries Science Center, Narragansett Laboratory.
;   This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made.
;   This routine is provided AS IS without any express or implied warranties whatsoever.
;
; AUTHOR:
;   This program was written on March 31, 2022 by Kimberly J. W. Hyde, Northeast Fisheries Science Center | NOAA Fisheries | U.S. Department of Commerce, 28 Tarzwell Dr, Narragansett, RI 02882
;    
; MODIFICATION HISTORY:
;   Mar 31, 2022 - KJWH: Initial code written
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'TEST_NOAA_SST_FRONTS'
  COMPILE_OPT IDL2
  SL = PATH_SEP()
  
  DIR = !S.READ_EDAB_FRONTS 
  
  SST_2SAVE = ''
  FRONTS = ''
  INDICATORS = 'Y'
  DAILY = ''
  
  DR = '2004'
  DSETS = ['AVHRR','GEOPOLAR','GEOPOLAR_INTERPOLATED','MUR','AT']
  GPROD='GRADSST_INDICATORS-MILLER'
  D3MAP = 'NWA'
  NCMAP = 'NESGRID'
  
  IF KEYWORD_SET(SST_2SAVE) THEN BATCH_L3, DO_GHRSST='YRF[GEOPOLAR_INTERPOLATED]'
  IF KEYWORD_SET(FRONTS) THEN BATCH_L3, DO_FRONTS='Y_'+DR+'[GEOPOLAR,GEOPOLAR_INTERPOLATED,MUR,AVHRR,MODISA,MODIST]'
  IF KEYWORD_SET(INDICATORS) THEN BEGIN
    FOR D=0, N_ELEMENTS(DSETS)-1 DO BEGIN
      DSET = DSETS[D]
      FRONTS_STACKED_FILES, DSET, DATERANGE=DR, PRODS=DPRODS, L3BMAP=D3MAP, LOGLUN=LUN, OVERWRITE=OVERWRITE
      
      GFILES = GET_FILES(DSET, PRODS='GRAD_SST-BOA', DATERANGE=DR, FILE_TYPE='STACKED', PERIOD='DD')      
      D3HASH_FRONT_INDICATORS, GFILES, /INIT, PERIOD_CODE='W', NC_MAP=NCMAP, LOGLUN=LUN    
    ENDFOR
  ENDIF
  IF KEYWORD_SET(DAILY) THEN BEGIN
    
    DTS = CREATE_DATE(GET_DATERANGE(DR))
    
    BUFFER=0
    DIM=200
    SP = 20
    PX = N_ELEMENTS(DSETS)
    PY = 2
    CBSP = 50
    DIMS = [DIM*PX+SP*(PX+1)+CBSP,DIM*(PY+2)]
    
    PDIR = DIR + 'COMPOSITES' + SL + 'DAILY' + SL & DIR_TEST, PDIR
    FOR D=0, N_ELEMENTS(DTS)-1 DO BEGIN
      DT = STRMID(DTS[D],0,8)
      INFILES = []
      FOR S=0, N_ELEMENTS(DSETS)-1 DO BEGIN
        INFILES = [INFILES,GET_FILES(DSETS[S],PRODS='SST',DATERANGE=DT,SUITE='SST')]
        INFILES = [INFILES,GET_FILES(DSETS[S],PRODS='GRAD_SST-BOA',DATERANGE=DT,SUITE='FRONTS')]
      ENDFOR
      IF N_ELEMENTS(INFILES) NE N_ELEMENTS(DSETS)*2 THEN MESSAGE, 'ERROR: Some dataset files are missing.'
      PNGFILE = PDIR + 'D_'+DT+'SST-GRAD_MAG-COMPOSITE.PNG'
      IF FILE_MAKE(INFILES,PNGFILE,OVERWRITE=OVERWRITE) EQ 0 THEN CONTINUE
      W = WINDOW(DIMENSIONS=DIMS,BUFFER=BUFFER)
      
      FOR I=0, N_ELEMENTS(INFILES)-1 DO BEGIN
      ENDFOR
    ENDFOR
    
  ENDIF
    
  

STOP
END ; ***************** End of TEST_NOAA_SST_FRONTS *****************
