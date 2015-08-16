﻿--------------------------------------------------------
-- UPDATE wastewater structure symbology
-- Argument:
--  * obj_id of wastewater structure or NULL to update all
--------------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.update_wastewater_structure_symbology(_obj_id text)
  RETURNS VOID AS
  $BODY$

UPDATE qgep.od_wastewater_structure ws
SET
  _function_hierarchic = COALESCE(function_hierarchic_from, function_hierarchic_to),
  _usage_current = COALESCE(usage_current_from, usage_current_to)
FROM(
  SELECT ws.obj_id AS ws_obj_id,
    CH_from.function_hierarchic AS function_hierarchic_from,
    CH_to.function_hierarchic AS function_hierarchic_to,
    CH_from.usage_current AS usage_current_from,
    CH_to.usage_current AS usage_current_to,
    rank() OVER( PARTITION BY ws.obj_id ORDER BY vl_fct_hier_from.order_fct_hierarchic ASC NULLS LAST, vl_fct_hier_to.order_fct_hierarchic ASC NULLS LAST,
                              vl_usg_curr_from.order_usage_current ASC NULLS LAST, vl_usg_curr_to.order_usage_current ASC NULLS LAST)
                              AS hierarchy_rank
  FROM
    qgep.od_wastewater_structure ws
    LEFT JOIN qgep.od_wastewater_networkelement ne ON ne.fk_wastewater_structure = ws.obj_id

    LEFT JOIN qgep.od_reach_point rp ON ne.obj_id = rp.fk_wastewater_networkelement

    LEFT JOIN qgep.od_reach re_from                                 ON re_from.fk_reach_point_from = rp.obj_id
    LEFT JOIN qgep.od_wastewater_networkelement ne_from             ON ne_from.obj_id = re_from.obj_id
    LEFT JOIN qgep.od_channel CH_from                               ON CH_from.obj_id = ne_from.fk_wastewater_structure
    LEFT JOIN qgep.vl_channel_function_hierarchic vl_fct_hier_from  ON CH_from.function_hierarchic = vl_fct_hier_from.code
    LEFT JOIN qgep.vl_channel_usage_current vl_usg_curr_from        ON CH_from.usage_current = vl_usg_curr_from.code

    LEFT JOIN qgep.od_reach                       re_to          ON re_to.fk_reach_point_to = rp.obj_id
    LEFT JOIN qgep.od_wastewater_networkelement   ne_to          ON ne_to.obj_id = re_to.obj_id
    LEFT JOIN qgep.od_channel                     CH_to          ON CH_to.obj_id = ne_to.fk_wastewater_structure
    LEFT JOIN qgep.vl_channel_function_hierarchic vl_fct_hier_to ON CH_to.function_hierarchic = vl_fct_hier_to.code
    LEFT JOIN qgep.vl_channel_usage_current       vl_usg_curr_to ON CH_to.usage_current = vl_usg_curr_to.code

    WHERE CASE WHEN _obj_id IS NULL THEN TRUE ELSE ws.obj_id = _obj_id END
) labeled_ws
WHERE labeled_ws.ws_obj_id = ws.obj_id
$BODY$
LANGUAGE sql
VOLATILE;


  -------------------- SYMBOLOGY UPDATE ON CHANNEL TABLE CHANGES ----------------------

CREATE OR REPLACE FUNCTION qgep.ws_symbology_update_by_channel()
  RETURNS trigger AS
$BODY$
DECLARE
  ws_obj_id RECORD;
  ch_obj_id TEXT;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      ch_obj_id = OLD.obj_id;
    WHEN TG_OP = 'INSERT' THEN
      ch_obj_id = NEW.obj_id;
    WHEN TG_OP = 'DELETE' THEN
      ch_obj_id = OLD.obj_id;
  END CASE;

  SELECT ws.obj_id INTO ws_obj_id
    FROM qgep.od_wastewater_structure ws
    LEFT JOIN qgep.od_wastewater_networkelement ne ON ws.obj_id = ne.fk_wastewater_structure
    LEFT JOIN qgep.od_reach_point rp ON ne.obj_id = rp.fk_wastewater_networkelement
    LEFT JOIN qgep.od_reach re ON (re.fk_reach_point_from = rp.obj_id OR re.fk_reach_point_to = rp.obj_id )
    LEFT JOIN qgep.od_wastewater_networkelement rene ON rene.obj_id = re.obj_id
    WHERE rene.fk_wastewater_structure = ch_obj_id;

  EXECUTE qgep.update_wastewater_structure_symbology(ws_obj_id);
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE;




  -------------------- SYMBOLOGY UPDATE ON REACH POINT TABLE CHANGES ----------------------

CREATE OR REPLACE FUNCTION qgep.ws_symbology_update_by_reach_point()
  RETURNS trigger AS
$BODY$
DECLARE
  ws_obj_id RECORD;
  rp_obj_id TEXT;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      rp_obj_id = OLD.obj_id;
    WHEN TG_OP = 'INSERT' THEN
      rp_obj_id = NEW.obj_id;
    WHEN TG_OP = 'DELETE' THEN
      rp_obj_id = OLD.obj_id;
  END CASE;

  SELECT ws.obj_id INTO ws_obj_id
    FROM qgep.od_wastewater_structure ws
    LEFT JOIN qgep.od_wastewater_networkelement ne ON ws.obj_id = ne.fk_wastewater_structure
    LEFT JOIN qgep.od_reach_point rp ON ne.obj_id = rp.fk_wastewater_networkelement
    WHERE rp.obj_id = rp_obj_id;

  EXECUTE qgep.update_wastewater_structure_symbology(ws_obj_id);
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE;

  -------------------- SYMBOLOGY UPDATE ON REACH TABLE CHANGES ----------------------

CREATE OR REPLACE FUNCTION qgep.ws_symbology_update_by_reach()
  RETURNS trigger AS
$BODY$
DECLARE
  ws_obj_id RECORD;
  symb_attribs RECORD;
  re_obj_id TEXT;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      re_obj_id = OLD.obj_id;
    WHEN TG_OP = 'INSERT' THEN
      re_obj_id = NEW.obj_id;
    WHEN TG_OP = 'DELETE' THEN
      re_obj_id = OLD.obj_id;
  END CASE;

  SELECT ws.obj_id INTO ws_obj_id
    FROM qgep.od_wastewater_structure ws
    LEFT JOIN qgep.od_wastewater_networkelement ne ON ws.obj_id = ne.fk_wastewater_structure
    LEFT JOIN qgep.od_reach_point rp ON ne.obj_id = rp.fk_wastewater_networkelement
    LEFT JOIN qgep.od_reach re ON ( rp.obj_id = re.fk_reach_point_from OR rp.obj_id = re.fk_reach_point_to )
    WHERE re.obj_id = re_obj_id;
  EXECUTE qgep.update_wastewater_structure_symbology(ws_obj_id);

  RETURN NEW;
END; $BODY$
LANGUAGE plpgsql VOLATILE;













































--------------------------------------------------------
-- UPDATE wastewater structure label
-- Argument:
--  * obj_id of wastewater structure or NULL to update all
--------------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.update_wastewater_structure_label(_obj_id text)
  RETURNS VOID AS
  $BODY$

UPDATE qgep.od_wastewater_structure ws
SET _label = label
FROM (
  SELECT ws_obj_id,
       array_to_string(
         array_agg( 'C' || '=' || co_level::text ORDER BY co_level DESC),
         E'\n'
       ) ||
       E'\n' ||
       ws_identifier ||
       E'\n' ||
       array_to_string(
         array_agg(lbl_type || idx || '=' || rp_level ORDER BY lbl_type, idx)
           , E'\n'
         ) AS label
  FROM (
    SELECT ws.obj_id AS ws_obj_id, ws.identifier AS ws_identifier, parts.lbl_type, parts.co_level, parts.rp_level, parts.obj_id, idx
    FROM qgep.od_wastewater_structure WS

    RIGHT JOIN (
      SELECT 'C' as lbl_type, CO.level AS co_level, NULL AS rp_level, SP.fk_wastewater_structure ws, SP.obj_id, row_number() OVER(PARTITION BY SP.fk_wastewater_structure) AS idx
      FROM qgep.od_structure_part SP
      RIGHT JOIN qgep.od_cover CO ON CO.obj_id = SP.obj_id
      WHERE CASE WHEN _obj_id IS NULL THEN TRUE ELSE SP.fk_wastewater_structure = _obj_id END
      UNION
      SELECT 'I' as lbl_type, NULL, RP.level AS rp_level, NE.fk_wastewater_structure ws, RP.obj_id, row_number() OVER(PARTITION BY RP.fk_wastewater_networkelement ORDER BY ST_Azimuth(RP.situation_geometry,ST_LineInterpolatePoint(ST_GeometryN(RE_to.progression_geometry,1),0.99))/pi()*180 ASC)
      FROM qgep.od_reach_point RP
      LEFT JOIN qgep.od_wastewater_networkelement NE ON RP.fk_wastewater_networkelement = NE.obj_id
      INNER JOIN qgep.od_reach RE_to ON RP.obj_id = RE_to.fk_reach_point_to
      WHERE CASE WHEN _obj_id IS NULL THEN TRUE ELSE NE.fk_wastewater_structure = _obj_id END
      UNION
      SELECT 'O' as lbl_type, NULL, RP.level AS rp_level, NE.fk_wastewater_structure ws, RP.obj_id, row_number() OVER(PARTITION BY RP.fk_wastewater_networkelement ORDER BY ST_Azimuth(RP.situation_geometry,ST_LineInterpolatePoint(ST_GeometryN(RE_from.progression_geometry,1),0.99))/pi()*180 ASC)
      FROM qgep.od_reach_point RP
      LEFT JOIN qgep.od_wastewater_networkelement NE ON RP.fk_wastewater_networkelement = NE.obj_id
      INNER JOIN qgep.od_reach RE_from ON RP.obj_id = RE_from.fk_reach_point_from
      WHERE CASE WHEN _obj_id IS NULL THEN TRUE ELSE NE.fk_wastewater_structure = _obj_id END
    ) AS parts ON ws = ws.obj_id
  ) parts
  GROUP BY ws_obj_id, ws_identifier
) labeled_ws
WHERE ws.obj_id = labeled_ws.ws_obj_id
$BODY$
LANGUAGE sql
VOLATILE;

--------------------------------------------------
-- ON COVER CHANGE
--------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.ws_label_update_by_cover()
  RETURNS trigger AS
$BODY$
DECLARE
  co_obj_id TEXT;
  affected_sp RECORD;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      co_obj_id = OLD.obj_id;
    WHEN TG_OP = 'INSERT' THEN
      co_obj_id = NEW.obj_id;
    WHEN TG_OP = 'DELETE' THEN
      co_obj_id = OLD.obj_id;
  END CASE;

  SELECT SP.fk_wastewater_structure INTO affected_sp
  FROM qgep.od_structure_part SP
  WHERE obj_id = co_obj_id;

  EXECUTE qgep.update_wastewater_structure_label(affected_sp.fk_wastewater_structure);
  RETURN NEW;
END; $BODY$
LANGUAGE plpgsql VOLATILE;




--------------------------------------------------
-- ON STRUCTURE PART / NETWORKELEMENT CHANGE
--------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.ws_label_update_by_structure_part_networkelement()
  RETURNS trigger AS
$BODY$
DECLARE
  _ws_obj_ids TEXT[];
  _ws_obj_id TEXT;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      _ws_obj_ids = ARRAY[OLD.fk_wastewater_structure, NEW.fk_wastewater_structure];
    WHEN TG_OP = 'INSERT' THEN
      _ws_obj_ids = ARRAY[NEW.fk_wastewater_structure];
    WHEN TG_OP = 'DELETE' THEN
      _ws_obj_ids = ARRAY[OLD.fk_wastewater_structure];
  END CASE;

  FOREACH _ws_obj_id IN ARRAY _ws_obj_ids
  LOOP
    EXECUTE qgep.update_wastewater_structure_label(_ws_obj_id);
  END LOOP;

  RETURN NEW;
END; $BODY$
LANGUAGE plpgsql VOLATILE;



--------------------------------------------------
-- ON WASTEWATER STRUCTURE CHANGE
--------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.ws_label_update_by_wastewater_structure()
  RETURNS trigger AS
$BODY$
DECLARE
  _ws_obj_id TEXT;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      -- Prevent recursion
      IF OLD.identifier = NEW.identifier THEN
        RETURN NEW;
      END IF;
      _ws_obj_id = OLD.obj_id;
    WHEN TG_OP = 'INSERT' THEN
      _ws_obj_id = NEW.obj_id;
  END CASE;
  SELECT qgep.update_wastewater_structure_label(_ws_obj_id) INTO NEW._label;

  RETURN NEW;
END; $BODY$
LANGUAGE plpgsql VOLATILE;

--------------------------------------------------
-- ON REACH CHANGE
--------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.ws_label_update_by_reach()
  RETURNS trigger AS
$BODY$
DECLARE
  rp_obj_ids TEXT[];
  _ws_obj_id TEXT;
  rps RECORD;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      rp_obj_ids = ARRAY[OLD.fk_reach_point_from, OLD_fk_reach_point_to];
    WHEN TG_OP = 'INSERT' THEN
      rp_obj_ids = ARRAY[NEW.fk_reach_point_from, NEW_fk_reach_point_to];
    WHEN TG_OP = 'DELETE' THEN
      rp_obj_ids = ARRAY[OLD.fk_reach_point_from, OLD_fk_reach_point_to];
  END CASE;

  FOR _ws_obj_id IN
    SELECT ws.obj_id
      FROM qgep.od_wastewater_structure ws
      LEFT JOIN qgep.od_wastewater_networkelement ne ON ws.obj_id = ne.fk_wastewater_structure
      LEFT JOIN qgep.od_reach_point rp ON ne.obj_id = rp.fk_wastewater_networkelement
      WHERE rp.obj_id = ANY ( rp_obj_ids )
  LOOP
    EXECUTE qgep.update_wastewater_structure_label(_ws_obj_id);
  END LOOP;

  RETURN NEW;
END; $BODY$
LANGUAGE plpgsql VOLATILE;

--------------------------------------------------
-- ON REACH POINT CHANGE
--------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.ws_label_update_by_reach_point()
  RETURNS trigger AS
$BODY$
DECLARE
  rp_obj_id TEXT;
  _ws_obj_id TEXT;
BEGIN
  CASE
    WHEN TG_OP = 'UPDATE' THEN
      rp_obj_id = OLD.obj_id;
    WHEN TG_OP = 'INSERT' THEN
      rp_obj_id = NEW.obj_id;
    WHEN TG_OP = 'DELETE' THEN
      rp_obj_id = OLD.obj_id;
  END CASE;

  SELECT ws.obj_id INTO _ws_obj_id
  FROM qgep.od_wastewater_structure ws
  LEFT JOIN qgep.od_wastewater_networkelement ne ON ws.obj_id = ne.fk_wastewater_structure
  LEFT JOIN qgep.od_reach_point rp ON ne.obj_id = rp_obj_id;

  EXECUTE qgep.update_wastewater_structure_label(_ws_obj_id);

  RETURN NEW;
END; $BODY$
LANGUAGE plpgsql VOLATILE;

-----------------------------------------------------------------------
-- Drop Symbology Triggers
-- To temporarily disable these cache refreshes for batch jobs like migrations
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.drop_symbology_triggers() RETURNS VOID AS $$
BEGIN
  DROP TRIGGER IF EXISTS ws_label_update_by_reach_point ON qgep.od_reach_point;
  DROP TRIGGER IF EXISTS ws_label_update_by_reach ON qgep.od_reach;
  DROP TRIGGER IF EXISTS ws_label_update_by_wastewater_structure ON qgep.od_wastewater_structure;
  DROP TRIGGER IF EXISTS ws_label_update_by_wastewater_networkelement ON qgep.od_wastewater_networkelement;
  DROP TRIGGER IF EXISTS ws_label_update_by_structure_part ON qgep.od_structure_part;
  DROP TRIGGER IF EXISTS ws_label_update_by_cover ON qgep.od_cover;
  DROP TRIGGER IF EXISTS ws_symbology_update_by_reach ON qgep.od_reach;
  DROP TRIGGER IF EXISTS ws_symbology_update_by_channel ON qgep.od_channel;
  DROP TRIGGER IF EXISTS ws_symbology_update_by_reach_point ON qgep.od_reach_point;
  RETURN;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------
-- Create Symbology Triggers
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION qgep.create_symbology_triggers() RETURNS VOID AS $$
BEGIN
  -- only update -> insert and delete are handled by reach trigger
  CREATE TRIGGER ws_label_update_by_reach_point
  AFTER UPDATE
    ON qgep.od_reach_point
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_label_update_by_reach_point();

  CREATE TRIGGER ws_label_update_by_reach
  AFTER INSERT OR UPDATE OR DELETE
    ON qgep.od_reach
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_label_update_by_reach();

  CREATE TRIGGER ws_label_update_by_wastewater_structure
  AFTER INSERT OR UPDATE
    ON qgep.od_wastewater_structure
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_label_update_by_wastewater_structure();

  CREATE TRIGGER ws_label_update_by_wastewater_networkelement
  AFTER INSERT OR UPDATE OR DELETE
    ON qgep.od_wastewater_networkelement
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_label_update_by_structure_part_networkelement();

  CREATE TRIGGER ws_label_update_by_structure_part
  AFTER INSERT OR UPDATE OR DELETE
    ON qgep.od_structure_part
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_label_update_by_structure_part_networkelement();

  CREATE TRIGGER ws_label_update_by_cover
  AFTER INSERT OR UPDATE OR DELETE
    ON qgep.od_cover
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_label_update_by_cover();

  CREATE TRIGGER ws_symbology_update_by_reach
  AFTER INSERT OR UPDATE OR DELETE
    ON qgep.od_reach
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_symbology_update_by_reach();

  CREATE TRIGGER ws_symbology_update_by_channel
  AFTER INSERT OR UPDATE OR DELETE
  ON qgep.od_channel
  FOR EACH ROW
  EXECUTE PROCEDURE qgep.ws_symbology_update_by_channel();

  -- only update -> insert and delete are handled by reach trigger
  CREATE TRIGGER ws_symbology_update_by_reach_point
  AFTER UPDATE
    ON qgep.od_reach_point
  FOR EACH ROW
    EXECUTE PROCEDURE qgep.ws_symbology_update_by_reach_point();


  RETURN;
END;
$$ LANGUAGE plpgsql;