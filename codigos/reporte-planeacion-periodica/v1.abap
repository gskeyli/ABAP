#TOP INCLUDE TOP PARA DECLARACIÓN DE TABLAS
************************** DB TABLES/STRUCTURES ************************
TABLES: pgmi,
        pbim,
        t001w,
        adrc,
        MDLV,
        PBID.

*$*$
******************************** RANGES ********************************
RANGES: r_versb FOR pbim-versb,
        r_vervs FOR pbim-vervs.

*$*$
***************************** DEFINE TYPES *****************************
TYPES: BEGIN OF t_pgmi,
         pgtyp LIKE pgmi-pgtyp,
         prgrp LIKE pgmi-prgrp,
         werks LIKE pgmi-werks,
         nrmit LIKE pgmi-nrmit,
         wemit LIKE pgmi-wemit,
         datum LIKE pgmi-datum,
         vsnda LIKE pgmi-vsnda,
       END OF t_pgmi,

       BEGIN OF t_makt,
         matnr LIKE makt-matnr,
         spras LIKE makt-spras,
         maktx LIKE makt-maktx,
       END OF t_makt,

       BEGIN OF t_pbid,
         pbdnr LIKE pbid-pbdnr,
         matnr LIKE pbid-matnr,
         berid LIKE pbid-berid,
         versb LIKE pbid-versb,
         werks LIKE pbid-werks,
         bedae LIKE pbid-bedae,
         bdzei LIKE pbid-bdzei,
         vervs LIKE pbid-vervs,
       END OF t_pbid,

       BEGIN OF t_pbim,
         matnr LIKE pbim-matnr,
         werks LIKE pbim-werks,
         bedae LIKE pbim-bedae,
         versb LIKE pbim-versb,
         vervs LIKE pbim-vervs,
         pbdnr LIKE pbim-pbdnr,
         bdzei LIKE pbim-bdzei,
       END OF t_pbim,

       BEGIN OF t_pbed,
         bdzei LIKE pbed-bdzei,
         pdatu LIKE pbed-pdatu,
         meins LIKE pbed-meins,
         plnmg LIKE pbed-plnmg,
         entli LIKE pbed-entli,
         perxx LIKE pbed-perxx,
         fixmg LIKE pbed-fixmg,
         loevr LIKE pbed-loevr,
       END OF t_pbed,

       BEGIN OF t_despm,
         prgrp LIKE pgmi-prgrp,
         nrmit LIKE pgmi-nrmit,
         maktx LIKE makt-maktx,
         gjahr LIKE bkpf-gjahr,
         total LIKE pbed-plnmg,
         ene   LIKE pbed-plnmg,
         feb   LIKE pbed-plnmg,
         mar   LIKE pbed-plnmg,
         abr   LIKE pbed-plnmg,
         may   LIKE pbed-plnmg,
         jun   LIKE pbed-plnmg,
         jul   LIKE pbed-plnmg,
         ago   LIKE pbed-plnmg,
         sep   LIKE pbed-plnmg,
         oct   LIKE pbed-plnmg,
         nov   LIKE pbed-plnmg,
         dic   LIKE pbed-plnmg,
       END OF t_despm,

       BEGIN OF t_despa,
         gjahr LIKE bkpf-gjahr,
         prgrp LIKE pgmi-prgrp,
         nrmit LIKE pgmi-nrmit,
         maktx LIKE makt-maktx,
         total LIKE pbed-plnmg,
         ene   LIKE pbed-plnmg,
         feb   LIKE pbed-plnmg,
         mar   LIKE pbed-plnmg,
         abr   LIKE pbed-plnmg,
         may   LIKE pbed-plnmg,
         jun   LIKE pbed-plnmg,
         jul   LIKE pbed-plnmg,
         ago   LIKE pbed-plnmg,
         sep   LIKE pbed-plnmg,
         oct   LIKE pbed-plnmg,
         nov   LIKE pbed-plnmg,
         dic   LIKE pbed-plnmg,
       END OF t_despa,

       BEGIN OF t_help_infos.
        INCLUDE STRUCTURE help_info.
TYPES: END OF t_help_infos,

       BEGIN OF t_rsmdy_ret.
        INCLUDE STRUCTURE rsmdy.
TYPES: END OF t_rsmdy_ret,

       BEGIN OF t_dselc.
        INCLUDE STRUCTURE dselc.
TYPES: END OF t_dselc,

       BEGIN OF t_dval.
        INCLUDE STRUCTURE dval.
TYPES: END OF t_dval,

       BEGIN OF t_weeks,
         week   LIKE scal-week,
         monday LIKE sy-datum,
         sunday LIKE sy-datum,
         month  LIKE bkpf-monat,
       END OF t_weeks.
###############################################################
#INLUDE F01 
Subrutina para selección de materiales
FORM sel_material.

  SELECT pgtyp prgrp werks nrmit wemit datum vsnda
         FROM pgmi INTO TABLE i_pgmi
         WHERE nrmit IN s_matnr
           AND prgrp IN s_prgrp
           AND werks EQ p_werks
           AND datum GT sy-datum.
  IF sy-subrc EQ 0.

    PERFORM sel_descrip.
    PERFORM sel_neces.
  ENDIF.
ENDFORM.                    " sel_material

*&---------------------------------------------------------------------*
*&      Form  cal_producc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM cal_producc.
  CLEAR: vd_fecht, vi_week, vd_monday, vd_sunday, vi_daytm.
  MOVE p_datve TO vd_fecht.
  WHILE vd_fecht LT p_datbe.
    CALL FUNCTION 'GET_WEEK_INFO_BASED_ON_DATE'
         EXPORTING
              date   = vd_fecht
         IMPORTING
              week   = vi_week
              monday = vd_monday
              sunday = vd_sunday.
    MOVE: vi_week   TO i_weeks-week,
          vd_monday TO i_weeks-monday,
          vd_sunday TO i_weeks-sunday.
    IF vd_monday(6) EQ vd_sunday(6).
      MOVE vd_monday+4(2) TO i_weeks-month.
    ELSE.
      CONCATENATE vd_sunday(6) '01' INTO vd_sunday.
      CALL FUNCTION 'DATE_COMPUTE_DAY'
           EXPORTING
                date = vd_sunday
           IMPORTING
                day  = vi_daytm.
      IF vi_daytm GT 3.                                   "#EC PORTABLE
        MOVE vd_monday+4(2) TO i_weeks-month.
      ELSE.
        MOVE vd_sunday+4(2) TO i_weeks-month.
      ENDIF.
    ENDIF.
    APPEND i_weeks.
    vd_fecht = i_weeks-sunday + 1.
    CLEAR: vi_week, vd_monday, vd_sunday, vi_daytm, i_weeks.
  ENDWHILE.
ENDFORM.                    " cal_producc

*&---------------------------------------------------------------------*
*&      Form  sel_descrip
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM sel_descrip.
  i_temp[] = i_pgmi[].
  SORT i_temp BY nrmit.
  DELETE ADJACENT DUPLICATES FROM i_temp COMPARING nrmit.
  SELECT matnr spras maktx
         FROM makt INTO TABLE i_makt
         FOR ALL ENTRIES IN i_temp
         WHERE matnr EQ i_temp-nrmit
           AND spras EQ sy-langu.
ENDFORM.                    " sel_descrip

*&---------------------------------------------------------------------*
*&      Form  sel_neces
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM sel_neces.

  DATA: lv_perxx_mb   LIKE scal-date,         "Periodo Mensual inicial
        lv_perxx_me   LIKE scal-date,         "Periodo Mensual Final
        lv_perxx_wb   LIKE scal-week,         "Periodo Semanal Inicial
        lv_perxx_we   LIKE scal-week.         "Periodo Semanal Final


*
  refresh: r_versb, r_vervs.
  IF r_veraw EQ 'X'.
    MOVE: 'I'     TO r_versb-sign,
          'EQ'    TO r_versb-option,
          p_versb TO r_versb-low.
    APPEND r_versb.
    MOVE: 'I'  TO r_vervs-sign,
          'EQ' TO r_vervs-option,
          'X'  TO r_vervs-low.
    APPEND r_vervs.
    MOVE: 'I'   TO r_vervs-sign,
          'EQ'  TO r_vervs-option,
          space TO r_vervs-low.
    APPEND r_vervs.
  ELSEIF r_verak EQ 'X'.
    MOVE: 'I'  TO r_vervs-sign,
          'EQ' TO r_vervs-option,
          'X'  TO r_vervs-low.
    APPEND r_vervs.
  ELSEIF r_verai EQ 'X'.
  ENDIF.
  IF p_berid is initial.

    SELECT matnr werks bedae versb vervs pbdnr bdzei
           FROM pbim INTO TABLE i_pbim
           FOR ALL ENTRIES IN i_temp
           WHERE matnr EQ i_temp-nrmit
             AND werks EQ p_werks
             AND versb IN r_versb
             AND vervs IN r_vervs.

    IF sy-subrc EQ 0.
      SELECT bdzei
             pdatu
             meins
             plnmg
             entli
             perxx
             fixmg
             loevr
        FROM pbed INTO TABLE i_pbed
          FOR ALL ENTRIES IN i_pbim
            WHERE bdzei EQ i_pbim-bdzei.
*           AND ( pdatu GE p_datve            "CJOG110308
*           AND   pdatu LE p_datbe ).         "CJOG110308
      IF sy-subrc EQ 0.
        DELETE i_pbed WHERE plnmg EQ 0.
      ENDIF.
    ENDIF.

  ELSE.

    SELECT pbdnr matnr berid versb werks bedae bdzei vervs
           FROM pbid INTO TABLE i_pbid
           FOR ALL ENTRIES IN i_temp
           WHERE matnr eq i_temp-nrmit
             AND berid EQ p_berid
             AND werks EQ p_werks
             AND versb IN r_versb
             AND vervs IN r_vervs.

    IF sy-subrc EQ 0.
      SELECT bdzei
             pdatu
             meins
             plnmg
             entli
             perxx
             fixmg
             loevr
        FROM pbed INTO TABLE i_pbed
*        FOR ALL ENTRIES IN i_pbim
*          WHERE bdzei EQ i_pbim-bdzei.
          FOR ALL ENTRIES IN i_pbid
            WHERE bdzei EQ i_pbid-bdzei.
*           AND ( pdatu GE p_datve            "CJOG110308
*           AND   pdatu LE p_datbe ).         "CJOG110308
      IF sy-subrc EQ 0.
        DELETE i_pbed WHERE plnmg EQ 0.
      ENDIF.
    ENDIF.
