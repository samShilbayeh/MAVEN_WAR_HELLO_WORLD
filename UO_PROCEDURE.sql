-- UTILISATION : UO (TOUTE EXTRACTION)
  -- Cette fonction renvoie un curseur p_Curseur contenant les donnees UO (hors listes)
  -- p_listeUO : liste des ID_UO dont on veut extraire les UO
  -- p_extractUOFille : indique si on doit extraire les UO filles des UO passees en parametre ('O') ou non ('N')
  -- p_activiteUOFille : indique la validite a prendre en consideration au niveau des relations UO_HIERARCHIQUES
  -- p_listeIDEJ : liste des ID EJ des entites juridiques dont on veut extraire les UO
  -- p_listeCODEISO : liste des CODE_ISO des pays dont on veut extraire les UO
  -- p_listeIDVILLE : liste des ID_VILLE des villes dont on veut extraire les UO
  -- p_validiteUOImmeuble : perimetre des rattachements UO_IMMEUBLE a prendre en compte (actif, inactif ou tous)
  -- p_listeIDROLE : liste des ID des ROLE_PARTICULIER dont on veut extraire les UO
  -- p_listeIDFONCMET : liste des ID des FONCTION_METIER dont on veut extraire les UO
  -- p_DateDebut : Date d'extraction (-> extractions des elements actifs a cette date)
  --               ou Date de debut de periode pour les extractions de modifications
  -- p_DateFin   : Date de fin de periode pour les extractions de modifications
  -- p_Resultat contient en retour : 1 si tout est ok,
  --                                 0 si une erreur a lieu
  -- p_filtreNatureUO : liste des natures UO dont on veut extraire les UO
  PROCEDURE P_GET_UO (p_listeIDUO             t_nvarchar2_tab,
                      p_extractUOFille        CHAR DEFAULT 'N',
                      p_activiteUOFille       VARCHAR2 DEFAULT gk_Actif,
                      p_listeIDEJ             t_nvarchar2_tab,
                      p_listeCODEISO          t_nvarchar2_tab,
                      p_listeIDVILLE          t_number_tab,
                      p_validiteUOImmeuble    VARCHAR2 DEFAULT gk_Actif,
                      p_listeIDROLE           t_number_tab,
                      p_listeIDFONCMET        t_number_tab,
                      p_listeIDFIL            t_number_tab,
                      p_listeIDSFIL           t_number_tab,
                      p_DateDebut             IN OUT VARCHAR2,
                      p_DateFin               IN OUT VARCHAR2,
                      p_Curseur               OUT t_Curseur_RefCur,
                      p_Resultat              OUT INTEGER,
                      p_Requete               OUT VARCHAR2,
                      p_Actif                 VARCHAR2 DEFAULT gk_Actif,
                      p_IdExtract             INTEGER,
                      p_listeIDImmeuble       t_nvarchar2_tab,
                      p_filtreUOJuridique     CHAR DEFAULT NULL,
                      p_filtreNatureUO        t_number_tab
                      )
  IS
    --
    l_filtreUID                       VARCHAR2(32000 CHAR);
    l_filtreUO                        VARCHAR2(32000 CHAR);
    l_filtreIdEj                      VARCHAR2(32000 CHAR);
    l_filtreRole                      VARCHAR2(32000 CHAR);
    l_filtreIdVille                   VARCHAR2(5000 CHAR);
    l_filtreCodeIso                   VARCHAR2(5000 CHAR);
    l_filtreDate                      VARCHAR2(5000 CHAR);
    l_filtreIdFONCMET                 VARCHAR2(32000 CHAR);
    l_filtreIdFIL                     VARCHAR2(32000 CHAR);
    l_filtreIdSFIL                    VARCHAR2(32000 CHAR);
    l_filtreValiditeLOCALISATION      VARCHAR2(1000 CHAR);
    l_resultat                        INTEGER;
    l_EtapeErreur                     VARCHAR2(500 CHAR);
    l_requeteTotale                   VARCHAR2(32000 CHAR);
    l_DateExtract                     VARCHAR2(8 CHAR);
    l_filtreUOJuridique               VARCHAR2(500 CHAR);
    l_filtreIdImmeuble                VARCHAR2(5000 CHAR);
    l_filtreNatureUO                  VARCHAR2(5000 CHAR);
    --
  BEGIN
    --
    -- Si la date de debut est NULL alors on affecte la date du jour
    IF p_Datedebut IS NULL
    THEN
      --
      SELECT TO_CHAR(SYSDATE,'YYYYMMDD')
        INTO p_Datedebut
        FROM dual;
    END IF;
    --
    -- Si la date de debut est NULL alors on affecte la date du jour
    IF p_DateFin IS NULL
    THEN
      l_DateExtract := p_DateDebut;
    ELSE
      l_DateExtract := p_DateFin;
    END IF;

    -- Tests des parametres de validite
    l_EtapeErreur := 'p_activiteUOFille : ' || p_activiteUOFille;
    IF p_activiteUOFille NOT IN ( gk_All, gk_Actif, gk_Inactif, gk_cloture, gk_futur, gk_nonfutur, gk_noncloture )
    THEN
      RAISE e_FlagActifInvalide;
    END IF;

    l_EtapeErreur := 'p_Actif : ' || p_Actif;
    IF p_Actif not in ( gk_All, gk_Actif, gk_Inactif, gk_cloture, gk_futur, gk_nonfutur, gk_noncloture)
    THEN
      RAISE e_FlagActifInvalide;
    END IF;

    l_EtapeErreur := 'p_validiteUOImmeuble : ' || p_validiteUOImmeuble;
    IF p_validiteUOImmeuble not in (gk_All, gk_Actif, gk_Inactif, gk_cloture, gk_futur, gk_nonfutur, gk_noncloture)
    THEN
      RAISE e_FlagActifInvalide;
    END IF;

    l_EtapeErreur := 'p_listeIDUO : ';
    -- On traite le filtre sur les UO
    if p_listeIDUO is not null and p_listeIDUO.Count<>0 then

      P_GET_PARAM_ALPHA(p_listeIDUO, l_filtreUO, l_resultat,p_IdExtract);

      l_EtapeErreur := 'recuperation UO Filles : ';

      -- Est-ce qu'on extrait les UO filles ?
      if p_extractUOFille='O' and p_listeIDUO is not null and p_listeIDUO.Count<>0 then
        P_GET_UO_FILLES(l_filtreUO, p_activiteUOFille,l_DateExtract,l_filtreUO,l_resultat);
      end if;

      l_filtreUO := ' and UO.ID_UO ' || l_filtreUO;
    end if;

    l_EtapeErreur := 'p_filtreUOJuridique : ';
    -- On traite le filtre sur les UO Juridiques
    if p_filtreUOJuridique is not null then
      if p_filtreUOJuridique = 'O' then
      --   l_filtreUOJuridique := ' and UO.UO_TETE_EJ = 1 ';
    l_filtreUOJuridique := ' and UO_HIE_MERE_ACTIVE.UO_RUPTURE = 1 '; --Evol RMO lot2
      else
      --   l_filtreUOJuridique := ' and UO.UO_TETE_EJ = 0 ';
    l_filtreUOJuridique := ' and UO_HIE_MERE_ACTIVE.UO_RUPTURE = 0 '; --Evol RMO lot2
      end if;
    end if;

    l_EtapeErreur := 'p_listeIDImmeuble : ';
    -- On traite le filtre sur les ID_IMMEUBLE
    if p_listeIDImmeuble is not null and p_listeIDImmeuble.Count<>0 then

      P_GET_PARAM_ALPHA(p_listeIDImmeuble, l_filtreIdImmeuble, l_resultat,p_IdExtract);

      l_filtreIdImmeuble := ' and UO_IMMEUBLE.ID_IMMEUBLE ' || l_filtreIdImmeuble;
    end if;

    l_EtapeErreur := 'p_listeIDEJ : ';
    -- On traite le filtre sur les ID_EJ
    if p_listeIDEJ is not null and p_listeIDEJ.Count<>0 then

      P_GET_PARAM_ALPHA(p_listeIDEJ, l_filtreIdEj, l_resultat,p_IdExtract);

      l_filtreIdEj := ' and UO.ID_EJ ' || l_filtreIdEj;
    end if;

    l_EtapeErreur := 'p_listeIDROLE : ';
    -- On traite le filtre sur les ID_ROLE
    if p_listeIDROLE is not null and p_listeIDROLE.Count<>0 then

      P_GET_PARAM_NUM(p_listeIDROLE, l_filtreRole, l_resultat,p_IdExtract);

      l_filtreRole := ' and ROLE_UO.ID_ROLE ' || l_filtreRole;
    end if;

    l_EtapeErreur := 'p_listeCODEISO : ';
    -- On traite le filtre sur les CODE_ISO
    if p_listeCODEISO is not null and p_listeCODEISO.Count<>0 then

      P_GET_PARAM_ALPHA(p_listeCODEISO, l_filtreCodeIso, l_resultat,p_IdExtract);

      l_filtreCodeIso := ' and PAYS.CODE_ISO ' || l_filtreCodeIso;
    end if;

    l_EtapeErreur := 'p_listeIDVILLE : ';
    -- On traite le filtre sur les ID_VILLE
    if p_listeIDVILLE is not null and p_listeIDVILLE.Count<>0 then

      P_GET_PARAM_NUM(p_listeIDVILLE, l_filtreIdVille, l_resultat,p_IdExtract);

      l_filtreIdVille := ' and VILLE.ID_VILLE ' || l_filtreIdVille;
    end if;


    l_EtapeErreur := 'p_listeIDFONCMET : ';
    -- On traite le filtre sur les ID_FONCTIONMETIER
    if p_listeIDFONCMET is not null and p_listeIDFONCMET.Count<>0 then

      P_GET_PARAM_NUM(p_listeIDFONCMET, l_filtreIdFONCMET, l_resultat,p_IdExtract);

      l_filtreIdFONCMET := ' and UO.ID_FONCTION ' || l_filtreIdFONCMET;
    end if;

    -- On traite le filtre sur l'activite des relations UO_IMMEUBLE
    l_EtapeErreur := 'p_validiteUOImmeuble : ' || p_validiteUOImmeuble;
    if p_validiteUOImmeuble = gk_All then
      l_filtreValiditeLOCALISATION := '';
    elsif p_validiteUOImmeuble = gk_Actif then
      l_filtreValiditeLOCALISATION := ' and exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_DEBUT <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') and nvl(UO_IMMEUBLE2.DT_FIN,to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')+ 1) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
    elsif p_validiteUOImmeuble = gk_Inactif then
      l_filtreValiditeLOCALISATION := ' and not exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_DEBUT <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') and nvl(UO_IMMEUBLE2.DT_FIN,to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')+ 1) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
    elsif p_validiteUOImmeuble = gk_cloture then
      l_filtreValiditeLOCALISATION := ' and exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_FIN <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
    elsif p_validiteUOImmeuble = gk_futur then
      l_filtreValiditeLOCALISATION := ' and exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_DEBUT > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
    elsif p_validiteUOImmeuble = gk_noncloture then
      l_filtreValiditeLOCALISATION := ' and not exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_FIN <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
    elsif p_validiteUOImmeuble = gk_nonfutur then
---       correction filtre pour HRR
--      l_filtreValiditeLOCALISATION := ' and not exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_DEBUT > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
      l_filtreValiditeLOCALISATION := ' and exists (select 1 from uo_immeuble uo_immeuble2 where UO_IMMEUBLE2.ID_UO = UO.ID_UO AND UO_IMMEUBLE2.DT_DEBUT <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
    end if;

    -- Generation du filtre sur les dates
    l_EtapeErreur := 'filtre sur les dates : ';

    l_filtreDate := ' and (UO_IMMEUBLE.DT_DEBUT (+) <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') and nvl(UO_IMMEUBLE.DT_FIN (+), to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')+ 1) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ' ||
                    ' and (UO_HIE_MERE_ACTIVE.DT_DEBUT (+) <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') and nvl(UO_HIE_MERE_ACTIVE.DT_FIN (+), to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')+ 1 ) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ' ||
 --                   ' and (UO_HIE_MERE_FUTURE.DT_DEBUT (+) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) ' ||
                    ' and (UO_FON_MERE_ACTIVE.DT_DEBUT (+) <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') and nvl(UO_FON_MERE_ACTIVE.DT_FIN (+), to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')+ 1 ) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') ) ';
 --                   ' and (UO_FON_MERE_FUTURE.DT_DEBUT (+) > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) ';

    if p_DateFin is not null then
      l_filtreDate := l_filtreDate || ' and (UO.DT_MODIF >= to_date(''' || p_DateDebut || ''', ''YYYYMMDD'') and UO.DT_MODIF <= to_date(''' || p_DateFin || ''', ''YYYYMMDD'') ) ';
    end if;

    l_EtapeErreur := 'filtre sur les activite des uo extraites : ';
    if p_Actif = gk_Actif then
      l_filtreDate := l_filtreDate || ' and (UO.DT_DEBUT <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') and nvl(UO.DT_FIN,to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') + 1)  > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) ';
    elsif p_Actif = gk_Inactif then
      l_filtreDate := l_filtreDate || ' and ( (nvl(UO.DT_FIN,to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') + 1)  <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) or (UO.DT_DEBUT > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) )';
    elsif p_Actif = gk_Cloture then
      l_filtreDate := l_filtreDate || ' and ( UO.DT_FIN <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) ';
    elsif p_Actif = gk_Futur then
      l_filtreDate := l_filtreDate || ' and ( UO.DT_DEBUT > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) ';
    elsif p_Actif = gk_NonCloture then
      l_filtreDate := l_filtreDate || ' and ( nvl(UO.DT_FIN,to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') + 1)  > to_date(''' || l_DateExtract || ''', ''YYYYMMDD'')) ';
    elsif p_Actif = gk_NonFutur then
      l_filtreDate := l_filtreDate || ' and ( UO.DT_DEBUT <= to_date(''' || l_DateExtract || ''', ''YYYYMMDD'') )';
    elsif p_Actif = gk_All then
      l_filtreDate := l_filtreDate || ' ';
    end if;

/*    -- Generation du filtre sur les dates
    l_EtapeErreur := 'filtre sur les dates : ';

    if p_Datedebut is not null and p_DateFin is not null then

      l_filtreDate := ' and ( ( UO_IMMEUBLE.DT_DEBUT >= to_date(''' || p_DateDebut || ''', ''YYYYMMDD'') and UO_IMMEUBLE.DT_DEBUT <= to_date(''' || p_DateFin || ''', ''YYYYMMDD'') ) ';
      l_filtreDate := l_filtreDate || ' or ( UO_IMMEUBLE.DT_FIN >= to_date(''' || p_DateDebut || ''', ''YYYYMMDD'') and UO_IMMEUBLE.DT_FIN <= to_date(''' || p_DateFin || ''', ''YYYYMMDD'') ) ';
      l_filtreDate := l_filtreDate || ' or ( UO.DT_MODIF >= to_date(''' || p_DateDebut || ''', ''YYYYMMDD'') and UO.DT_MODIF <= to_date(''' || p_DateFin || ''', ''YYYYMMDD'') ) ) ';

    end if;
*/

    l_EtapeErreur := 'p_filtreNatureUO : ';
    -- On traite le filtre sur les Nature_UO
    IF p_filtreNatureUO IS NOT NULL AND
       p_filtreNatureUO.COUNT <> 0
    THEN
      P_GET_PARAM_NUM(p_filtreNatureUO, l_filtreNatureUO, l_resultat,p_IdExtract);

      l_filtreNatureUO := ' AND UO.ID_NATURE ' || l_filtreNatureUO;
    END IF;


    l_EtapeErreur := 'p_listeIDFIL : ';
    -- On traite le filtre sur les ID_FILIERE
    if p_listeIDFIL is not null and p_listeIDFIL.Count<>0 then

      P_GET_PARAM_NUM(p_listeIDFIL, l_filtreIdFIL, l_resultat,p_IdExtract);

      l_filtreIdFIL := ' and UO_FILIERE.ID_FILIERE ' || l_filtreIdFIL;
    end if;

    l_EtapeErreur := 'p_listeIDSFIL : ';
    -- On traite le filtre sur les ID_S_FILIERE
    if p_listeIDSFIL is not null and p_listeIDSFIL.Count<>0 then

      P_GET_PARAM_NUM(p_listeIDSFIL, l_filtreIdSFIL, l_resultat,p_IdExtract);

      l_filtreIdSFIL := ' and UO_FILIERE.ID_S_FILIERE ' || l_filtreIdSFIL;
    end if;
    --
    --
    --
    --
     l_requeteTotale := 'SELECT distinct UO.ID_UO ID_UO, ' ||
                       '       UO.NOM_FR UO_NOM_FR, ' ||
                       '       UO.NOM_EN UO_NOM_EN, ' ||
                       '       UO.NOM_COURT UO_NOM_COURT, ' ||
                       '       NVL(UO_HIE_MERE_ACTIVE.NPO,UO_HIE_MERE_FUTURE.NPO) UO_NIVEAU, ' ||
                       '       UO.CODE_UO UO_CODE_UO, ' ||
                       '       STATUT_UO.CODE STATUT_UO_CODE, ' ||
                       '       UO.TELEPHONE UO_TEL, ' ||
                       '       UO.TELEPHONE_ACCUEIL UO_TEL_ACC, ' ||
                       '       UO.FAX UO_FAX, ' ||
                       '       UO.TELEX UO_TELEX, ' ||
                       '       UO.EMAIL UO_EMAIL, ' ||
                       '       UO.UID_ADMINISTRATEUR UO_ID_SYNCHRO, ' ||
                       '       UO.DT_MODIF_ADMINISTRATEUR UO_DT_SYNCHRO, ' ||
                       '       TO_CHAR(UO.DT_DEBUT,''YYYYMMDD'') UO_DT_DEBUT, ' ||
                       '       TO_CHAR(UO.DT_FIN,''YYYYMMDD'') UO_DT_FIN, ' ||
                       '       TO_CHAR(UO.DT_MODIF,''YYYYMMDD'') UO_DT_MODIF, ' ||
                       '       UO.UID_ADMIN UO_UID_ADMIN, ' ||
                       '       UO_HIE_MERE_ACTIVE.UO_MERE UO_HIE_MERE_ACT, ' ||
                       '       TO_CHAR(UO_HIE_MERE_ACTIVE.DT_DEBUT,''YYYYMMDD'') UO_HIE_MERE_ACT_DT_DEBUT, ' ||
                       '       TO_CHAR(UO_HIE_MERE_ACTIVE.DT_FIN,''YYYYMMDD'') UO_HIE_MERE_ACT_DT_FIN, ' ||
                       '       TO_CHAR(UO_HIE_MERE_ACTIVE.DT_MODIF,''YYYYMMDD'') UO_HIE_MERE_ACT_DT_MODIF, ' ||
                       '       POLE.ID_POLE POLE_ID_POLE, ' ||
                       '       POLE.NOM_FR POLE_NOM_FR_POLE, ' ||
                       '       POLE.NOM_EN POLE_NOM_EN_POLE, ' ||
					   '       POLE_ORGA.ID_POLE_ORGA POLE_ID_POLE_ORGA, ' ||
                       '       POLE_ORGA.NOM_FR_ORGA POLE_NOM_FR_POLE_ORGA, ' ||
                       '       POLE_ORGA.NOM_EN_ORGA POLE_NOM_EN_POLE_ORGA, ' ||
                       '       METIER.ID_METIER METIER_ID_METIER, ' ||
                       '       METIER.NOM_FR METIER_NOM_FR_METIER, ' ||
                       '       METIER.NOM_EN METIER_NOM_EN_METIER, ' ||
                       '       UO_HIE_MERE_FUTURE.UO_MERE UO_HIE_MERE_FUT, ' ||
                       '       TO_CHAR(UO_HIE_MERE_FUTURE.DT_DEBUT,''YYYYMMDD'') UO_HIE_MERE_FUT_DT_DEBUT, ' ||
                       '       TO_CHAR(UO_HIE_MERE_FUTURE.DT_FIN,''YYYYMMDD'') UO_HIE_MERE_FUT_DT_FIN, ' ||
                       '       TO_CHAR(UO_HIE_MERE_FUTURE.DT_MODIF,''YYYYMMDD'') UO_HIE_MERE_FUT_DT_MODIF, ' ||
                       '       UO_FON_MERE_ACTIVE.UO_MERE UO_FON_MERE_ACT, ' ||
                       '       TO_CHAR(UO_FON_MERE_ACTIVE.DT_DEBUT,''YYYYMMDD'') UO_FON_MERE_ACT_DT_DEBUT, ' ||
                       '       TO_CHAR(UO_FON_MERE_ACTIVE.DT_FIN,''YYYYMMDD'') UO_FON_MERE_ACT_DT_FIN, ' ||
                       '       UO_FON_MERE_FUTURE.UO_MERE UO_FON_MERE_FUT, ' ||
                       '       TO_CHAR(UO_FON_MERE_FUTURE.DT_DEBUT,''YYYYMMDD'') UO_FON_MERE_FUT_DT_DEBUT, ' ||
                       '       TO_CHAR(UO_FON_MERE_FUTURE.DT_FIN,''YYYYMMDD'') UO_FON_MERE_FUT_DT_FIN, ' ||
                       '       UO.ID_FONCTION UO_ID_FONCTION, ' ||
                       '       FONCTION_METIER.NOM_FR UO_NOM_FR_FONCTION, ' ||
                       '       FONCTION_METIER.NOM_EN UO_NOM_EN_FONCTION, ' ||
                       '       UO.ID_EJ UO_ID_EJ, ' ||
                       '       E_JURID.NOM UO_NOM_EJ, ' ||
                       '       IMMEUBLE.ID_IMMEUBLE UO_IMM_PR_ACT_ID_IMM, ' ||
                       '       TO_CHAR(UO_IMMEUBLE.DT_DEBUT,''YYYYMMDD'') UO_IMM_PR_ACT_DT_DEBUT, ' ||
                       '       TO_CHAR(UO_IMMEUBLE.DT_FIN,''YYYYMMDD'') UO_IMM_PR_ACT_DT_FIN, ' ||
                       '       ADRESSES.LIGNE UO_IMM_PR_ACT_LIGNE, ' ||
                       '       pkgutil.F_SUPP_ESPACE( UO.NOM_FR || '' '' || UO_IMMEUBLE.LIBELLE ' ||
                       ' || '' '' || ADRESSES.LIGNE || '' '' || UO_IMMEUBLE.BP || '' '' || ADRESSES.COMPLEMENT_LOCALISATION ' ||
                       ' || '' '' || decode(IMMEUBLE.VAL_CEDEX, null,ZDP.CODE_POSTAL, IMMEUBLE.CODE_CEDEX) || '' '' || decode(IMMEUBLE.VAL_CEDEX, null,VILLE.NOM_LOCAL,IMMEUBLE.VAL_CEDEX)  || '' '' || PAYS.NOM_FR) UO_IMM_PR_ACT_ADR_COMP, ' ||
                       '       ADRESSES.NUMERO_VOIE UO_IMM_PR_ACT_NUM_VOIE, ' ||
                       '       ADRESSES.TYPE_VOIE UO_IMM_PR_ACT_TYPE_VOIE, ' ||
                       '       ADRESSES.NOM_VOIE UO_IMM_PR_ACT_NOM_VOIE, ' ||
                       '       ADRESSES.COMPLEMENT_LOCALISATION UO_IMM_PR_ACT_COMP_LOC, ' ||
                       '       ADRESSES.COMPLEMENT_CONSTRUCTION UO_IMM_PR_ACT_COMP_CON, ' ||
                       '       IMMEUBLE.NOM UO_IMM_PR_ACT_NOM_IMM, ' ||
                       '       IMMEUBLE.NOM_USAGE UO_IMM_PR_ACT_NOM_USAGE_IMM, ' ||
                       '       ZDP.CODE_POSTAL UO_IMM_PR_ACT_CODE_POSTAL, ' ||
                       '       IMMEUBLE.CODE_CEDEX UO_IMM_PR_ACT_CODE_CEDEX, ' ||
                       '       IMMEUBLE.VAL_CEDEX UO_IMM_PR_ACT_CEDEX, ' ||
                       '       VILLE.NOM_FR UO_IMM_PR_ACT_VILLE_NOM_FR, ' ||
                       '       VILLE.NOM_EN UO_IMM_PR_ACT_VILLE_NOM_EN, ' ||
                       '       PAYS.NOM_FR UO_IMM_PR_ACT_PAYS_NOM_FR, ' ||
                       '       PAYS.NOM_EN UO_IMM_PR_ACT_PAYS_NOM_EN, ' ||
                       '       UO.NOM_COURT_FR UO_NOM_COURT_FR, ' ||
                       '       UO.NOM_COURT_EN UO_NOM_COURT_EN, ' ||
                       '       PKGUTIL.F_GET_NIVEAU_BRUT(UO.ID_UO, ''' || l_DateExtract || ''') UO_NIVEAU_BRUT, ' ||
                       '       PKGUTIL.F_GET_NIVEAU_CONSO(UO.ID_UO, ''' || l_DateExtract || ''') UO_NIVEAU_CONSO, ' ||
                       '       UO.ID_NATURE ID_NATURE, ' ||
                       '       NVL(UO_HIE_MERE_ACTIVE.UO_RUPTURE,UO_HIE_MERE_FUTURE.UO_RUPTURE) UO_TETE_EJ, ' ||
                       '       NVL(UO_HIE_MERE_ACTIVE.ID_TYPE_ORGANISATION,UO_HIE_MERE_FUTURE.ID_TYPE_ORGANISATION) ID_TYPE_ORGANISATION ' ||
                       'FROM UO_IMMEUBLE, ' ||
                       '     (select * from uo_hierarchique ' ||
                       '       where (id_uo, dt_debut, nvl(dt_fin, trunc(sysdate)), dt_modif)  ' ||
                       '          in (select id_uo, min(dt_debut) dt_debut, nvl(min(dt_fin),trunc(sysdate)) dt_fin , min(dt_modif) dt_modif ' ||
                       '                from uo_hierarchique  ' ||
                       '               where nvl(dt_fin,to_date(''' || l_DateExtract || ''',''YYYYMMDD'') +1)  > to_date(''' || l_DateExtract || ''',''YYYYMMDD'') ' ||
                       '                 and dt_debut > to_date(''' || l_DateExtract || ''',''YYYYMMDD'')   ' ||
                       '                 and nvl(dt_fin, to_date(''' || l_DateExtract || ''',''YYYYMMDD'') ) <> dt_debut ' ||
                       '                 and id_type_organisation = 0 ' || --Evol RMO LOT2 15032018
                       '               group by id_uo ) ' ||
                       '          and id_type_organisation = 0 ' || -- ASAP-5865 KBE 2018-03-30
                       '     ) UO_HIE_MERE_FUTURE, ' ||
                       --'     UO_HIERARCHIQUE  UO_HIE_MERE_ACTIVE, ' ||
                       '     (select * from UO_HIERARCHIQUE where id_type_organisation = 0 and (dt_fin is null or dt_fin > to_date(''' || l_DateExtract || ''',''YYYYMMDD''))) UO_HIE_MERE_ACTIVE, ' || -- ASAP-5865 KBE 2018-03-30
                       '     UO_FONCTIONNELLE UO_FON_MERE_ACTIVE, ' ||
                       '     (select * from UO_FONCTIONNELLE  ' ||
                       '       where (id_uo, dt_debut, nvl(dt_fin, trunc(sysdate)))  ' ||
                       '          in (select id_uo, min(dt_debut) dt_debut, nvl(min(dt_fin),trunc(sysdate)) dt_fin  ' ||
                       '                from UO_FONCTIONNELLE  ' ||
                       '               where nvl(dt_fin,to_date(''' || l_DateExtract || ''',''YYYYMMDD'') +1)  > to_date(''' || l_DateExtract || ''',''YYYYMMDD'') ' ||
                       '                 and dt_debut > to_date(''' || l_DateExtract || ''',''YYYYMMDD'')   ' ||
                       '                 and nvl(dt_fin, to_date(''' || l_DateExtract || ''',''YYYYMMDD'') ) <> dt_debut ' ||
                       '               group by id_uo ) ' ||
                       '     ) UO_FON_MERE_FUTURE, ' ||
                       '     UO, ' ||
                       '     (SELECT UO2.ID_UO ID_POLE, UO2.NOM_FR NOM_FR, UO2.NOM_EN NOM_EN ' ||
                       '      FROM UO UO2 ' ||
                       '      WHERE UO2.ID_NATURE = 1) POLE, ' ||
					   '     (SELECT UO4.ID_UO ID_POLE_ORGA, UO4.NOM_FR NOM_FR_ORGA, UO4.NOM_EN NOM_EN_ORGA ' ||
                       '      FROM UO UO4 ' ||
                       '      WHERE UO4.ID_NATURE = 1) POLE_ORGA, ' ||
                       '     (SELECT UO3.ID_UO ID_METIER, UO3.NOM_FR NOM_FR, UO3.NOM_EN NOM_EN ' ||
                       '      FROM UO UO3 ' ||
                       '      WHERE UO3.ID_NATURE = 2) METIER, ' ||
                       '     STATUT_UO, ' ||
                       '     IMMEUBLE, ' ||
                       '     ADRESSES, ' ||
                       '     ZDP, ' ||
                       '     VILLE, ' ||
                       '     PAYS, ' ||
                       '     FONCTION_METIER, ' ||
                       '     E_JURID, ' ||
                       '     ROLE_UO, ' ||
                       '     (SELECT * ' ||
                       '     FROM UO_FILIERE ' ||
                       '     WHERE UO_FILIERE.DT_DEBUT < TRUNC(SYSDATE) ' ||
                       '       AND NVL(UO_FILIERE.DT_FIN, TRUNC(SYSDATE) + 1) > TRUNC(SYSDATE)) UO_FILIERE ' ||
                       'WHERE UO.ID_UO = UO_IMMEUBLE.ID_UO (+) ' ||
                       '  AND ROLE_UO.ID_UO (+) = UO.ID_UO  ' ||
                       '  AND UO.URF = 0 ' ||
                       '  AND UO.ID_UO = UO_HIE_MERE_ACTIVE.ID_UO (+) ' ||
                       '  AND UO.ID_UO = UO_HIE_MERE_FUTURE.ID_UO (+) ' ||
                       '  AND UO.ID_UO = UO_FON_MERE_ACTIVE.ID_UO (+) ' ||
                       '  AND UO.ID_UO = UO_FON_MERE_FUTURE.ID_UO (+) ' ||
                       '  AND IMMEUBLE.ID_IMMEUBLE (+) = UO_IMMEUBLE.ID_IMMEUBLE ' ||
                       '  AND ADRESSES.ID_IMMEUBLE  (+) = IMMEUBLE.ID_IMMEUBLE ' ||
                       '  AND ADRESSES.ID_ZDP_CP        = ZDP.ID_ZDP (+) ' ||
                       '  AND ADRESSES.ID_VILLE         = VILLE.ID_VILLE (+) ' ||
                       '  AND ADRESSES.REFERENCE (+)    = 1 ' ||
                       '  AND VILLE.ID_PAYS             = PAYS.ID_PAYS (+) ' ||
                       '  AND POLE.ID_POLE  (+)         = PKG_METIER_UO.RECHERCHE_POLE_UO(UO.ID_UO, 0)' ||
					   '  AND POLE_ORGA.ID_POLE_ORGA  (+)    = PKG_METIER_UO.RECHERCHE_POLE_UO(UO.ID_UO, 1)' ||
                       '  AND METIER.ID_METIER  (+)     = PKG_METIER_UO.RECHERCHE_METIER_UO(UO.ID_UO, 0)' ||
                       '  AND UO.ID_STATUT              = STATUT_UO.ID_STATUT (+) ' ||
                       '  AND UO_IMMEUBLE.LOC_PR (+) = 1 ' ||
                       '  AND FONCTION_METIER.ID_FONCTION (+) = UO.ID_FONCTION ' ||
                       '  AND E_JURID.ID_EJ (+) = UO.ID_EJ ' ||
                       '  AND UO.ID_UO = UO_FILIERE.ID_UO(+) ' ||
                       -- '  AND  (UO_HIE_MERE_ACTIVE.ID_TYPE_ORGANISATION = 0 OR UO_HIE_MERE_FUTURE.ID_TYPE_ORGANISATION = 0 OR UO.DT_FIN < SYSDATE)'  ||
                       l_filtreUID ||
                       l_filtreUO ||
                       l_filtreIdEj  ||
                       l_filtreIdVille  ||
                       l_filtreCodeIso  ||
                       l_filtreDate  ||
                       l_filtreRole ||
                       l_filtreIdFONCMET  ||
                       l_filtreValiditeLOCALISATION ||
                       l_filtreUOJuridique ||
                       l_filtreIdImmeuble ||
                       l_filtreNatureUO ||
                       l_filtreIdFIL ||
                       l_filtreIdSFIL;

    l_EtapeErreur := 'Ouverture du curseur : ';

   open p_Curseur for l_requeteTotale;

    --pkg_rog_extract.P_TERMINE_EXTRACT;

    if p_Curseur%isopen = true  then
      p_Resultat :=1;
      p_Requete := l_requeteTotale;
    else
      p_Resultat :=0;
      p_Requete := l_requeteTotale;
    end if;

  exception
    when e_FlagActifInvalide then
      p_resultat := 0;
      raise_application_error(-20999, 'Flag d''activite inconnu ' || l_EtapeErreur);
    when others then
      p_resultat := 0;
      raise_application_error(-20999, 'Erreur ' || l_EtapeErreur || sqlerrm);
  END P_GET_UO;
