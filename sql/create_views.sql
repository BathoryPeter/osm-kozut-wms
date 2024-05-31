-- Run as schema owner.

CREATE TABLE IF NOT EXISTS ext.kozut_kategoria_nevek
(
  id VARCHAR(1) PRIMARY KEY NOT NULL,
  name text
);

INSERT INTO ext.kozut_kategoria_nevek (id, name) VALUES
('1', 'autópálya'),
('2', 'autóút'),
('3', 'I. rendű főút'),
('4', 'II. rendű főút'),
('5', 'összekötő út'),
('6', 'bekötő út'),
('7', 'állomáshoz vezető bekötő út'),
('8', 'autópálya vagy autóút csomóponti ága'),
('9', 'egyéb csomóponti ág'),
('P', 'gyorsforgalmi utak pihenő útjai');

--
-- Name: kozut_potencialis_city_limit; Type: MATERIALIZED VIEW; Schema: ext;
--

CREATE MATERIALIZED VIEW ext.kozut_potencialis_city_limit AS
 SELECT DISTINCT (((((((((urban.kszam)::text || '_'::text) || (urban.kszelv)::text) || '_'::text) || (rural.kszam)::text) || '_'::text) || (rural.vszelv)::text) || '_'::text) || (urban.pkod)::text) AS id,
    urban.kszam AS u_ref,
    rural.kszam AS r_ref,
    urban_katnev.name AS u_utkat,
    public.st_intersection(public.st_collect(public.st_startpoint(urban.wkb_geometry), public.st_endpoint(urban.wkb_geometry)), public.st_collect(public.st_startpoint(rural.wkb_geometry), public.st_endpoint(rural.wkb_geometry))) AS geom
   FROM ((ext.kozut_lakott_terulet urban
     JOIN ext.kozut_lakott_terulet rural ON ((((rural.szakjel)::text = 'külsőségi'::text) AND (urban.wkb_geometry OPERATOR(public.&&) rural.wkb_geometry) AND public.st_intersects(public.st_collect(public.st_startpoint(urban.wkb_geometry), public.st_endpoint(urban.wkb_geometry)), public.st_collect(public.st_startpoint(rural.wkb_geometry), public.st_endpoint(rural.wkb_geometry))))))
     LEFT JOIN ext.kozut_kategoria_nevek urban_katnev ON (((urban_katnev.id)::text = (urban.kutka)::text)))
  WHERE ((urban.szakjel)::text = 'átkelési'::text)
  WITH NO DATA;

CREATE INDEX kozut_potencialis_city_limit_geom_idx ON ext.kozut_potencialis_city_limit USING gist (geom);
CREATE UNIQUE INDEX kozut_potencialis_city_limit_id_unq ON ext.kozut_potencialis_city_limit USING btree (id);


--
-- Name: osm_kozut_city_limit_egyezes; Type: MATERIALIZED VIEW; Schema: ext;
--

CREATE MATERIALIZED VIEW ext.osm_kozut_city_limit_egyezes AS
 SELECT kcl.id AS kozut_id,
    osm.osm_id,
        CASE
            WHEN (osm.osm_id IS NOT NULL) THEN 'egyezés'::text
            WHEN (osm.osm_id IS NULL) THEN 'csak Közút'::text
            ELSE NULL::text
        END AS egyezes,
    kcl.geom
   FROM (ext.kozut_potencialis_city_limit kcl
     LEFT JOIN ( SELECT planet_osm_point.osm_id,
            planet_osm_point.access,
            planet_osm_point."addr:housename",
            planet_osm_point."addr:housenumber",
            planet_osm_point.admin_level,
            planet_osm_point.aerialway,
            planet_osm_point.aeroway,
            planet_osm_point.amenity,
            planet_osm_point.barrier,
            planet_osm_point.boundary,
            planet_osm_point.building,
            planet_osm_point.highway,
            planet_osm_point.historic,
            planet_osm_point.junction,
            planet_osm_point.landuse,
            planet_osm_point.layer,
            planet_osm_point.leisure,
            planet_osm_point.lock,
            planet_osm_point.man_made,
            planet_osm_point.military,
            planet_osm_point.name,
            planet_osm_point."natural",
            planet_osm_point.oneway,
            planet_osm_point.place,
            planet_osm_point.power,
            planet_osm_point.railway,
            planet_osm_point.ref,
            planet_osm_point.religion,
            planet_osm_point.shop,
            planet_osm_point.tourism,
            planet_osm_point.water,
            planet_osm_point.waterway,
            planet_osm_point.tags,
            planet_osm_point.way
           FROM public.planet_osm_point
          WHERE (((planet_osm_point.tags OPERATOR(public.->) 'traffic_sign'::text) = 'city_limit'::text) AND public.st_contains(( SELECT planet_osm_polygon.way
                   FROM public.planet_osm_polygon
                  WHERE (planet_osm_polygon.osm_id = '-21335'::integer)), planet_osm_point.way))) osm ON (public.st_dwithin(kcl.geom, osm.way, (50)::double precision)))
UNION ALL
 SELECT kcl.id AS kozut_id,
    osm.osm_id,
    'csak OSM'::text AS egyezes,
    osm.way AS geom
   FROM (ext.kozut_potencialis_city_limit kcl
     RIGHT JOIN ( SELECT planet_osm_point.osm_id,
            planet_osm_point.access,
            planet_osm_point."addr:housename",
            planet_osm_point."addr:housenumber",
            planet_osm_point.admin_level,
            planet_osm_point.aerialway,
            planet_osm_point.aeroway,
            planet_osm_point.amenity,
            planet_osm_point.barrier,
            planet_osm_point.boundary,
            planet_osm_point.building,
            planet_osm_point.highway,
            planet_osm_point.historic,
            planet_osm_point.junction,
            planet_osm_point.landuse,
            planet_osm_point.layer,
            planet_osm_point.leisure,
            planet_osm_point.lock,
            planet_osm_point.man_made,
            planet_osm_point.military,
            planet_osm_point.name,
            planet_osm_point."natural",
            planet_osm_point.oneway,
            planet_osm_point.place,
            planet_osm_point.power,
            planet_osm_point.railway,
            planet_osm_point.ref,
            planet_osm_point.religion,
            planet_osm_point.shop,
            planet_osm_point.tourism,
            planet_osm_point.water,
            planet_osm_point.waterway,
            planet_osm_point.tags,
            planet_osm_point.way
           FROM public.planet_osm_point
          WHERE (((planet_osm_point.tags OPERATOR(public.->) 'traffic_sign'::text) = 'city_limit'::text) AND public.st_contains(( SELECT planet_osm_polygon.way
                   FROM public.planet_osm_polygon
                  WHERE (planet_osm_polygon.osm_id = '-21335'::integer)), planet_osm_point.way))) osm ON (public.st_dwithin(kcl.geom, osm.way, (50)::double precision)))
  WHERE (kcl.id IS NULL)
  WITH NO DATA;

CREATE INDEX osm_kozut_city_limit_egyezes_geom_idx ON ext.osm_kozut_city_limit_egyezes USING gist (geom);
CREATE UNIQUE INDEX osm_kozut_city_limit_egyezes_unq ON ext.osm_kozut_city_limit_egyezes USING btree (kozut_id, osm_id);


--
-- Name: osm_kozut_forgalom; Type: VIEW; Schema: ext;
--

CREATE VIEW ext.osm_kozut_forgalom AS
 SELECT planet_osm_line.osm_id,
    planet_osm_line.bridge,
    planet_osm_line.foot,
    planet_osm_line.highway,
    planet_osm_line.junction,
    planet_osm_line.layer,
    planet_osm_line.name,
    planet_osm_line.oneway,
    planet_osm_line.railway,
    planet_osm_line.ref,
    planet_osm_line.tunnel,
    planet_osm_line.z_order,
    planet_osm_line.tags,
    kf.id AS k_id,
    kf.kszam AS k_ref,
    kf.pkod AS k_dual,
    kf.anf AS avg_daily_traffic,
    kf.oj AS total_daily_vehicle,
    kf.ongj AS total_daily_hgv,
    (@ degrees(sin(public.st_angle(public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (20)::double precision), planet_osm_line.way), public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (20)::double precision), kf.wkb_geometry))))) AS angle_norm,
    planet_osm_line.way
   FROM (public.planet_osm_line
     LEFT JOIN ext.kozut_forgalom kf ON ((kf.id = ( SELECT sub_kf.id
           FROM ext.kozut_forgalom sub_kf
          WHERE (public.st_dwithin(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), sub_kf.wkb_geometry, (15)::double precision) AND (planet_osm_line.highway = ANY (ARRAY['motorway'::text, 'trunk'::text, 'primary'::text, 'secondary'::text, 'tertiary'::text])))
          ORDER BY (public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision) OPERATOR(public.<->) sub_kf.wkb_geometry)
         LIMIT 1))))
  WHERE ((planet_osm_line.highway = ANY (ARRAY['motorway'::text, 'motorway_link'::text, 'trunk'::text, 'trunk_link'::text, 'primary'::text, 'primary_link'::text, 'secondary'::text, 'secondary_link'::text, 'tertiary'::text, 'tertiary_link'::text])) AND (GREATEST((@ degrees(sin(public.st_angle(public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (20)::double precision), planet_osm_line.way), public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (20)::double precision), kf.wkb_geometry))))), (0.0)::double precision) < (30)::double precision));


--
-- Name: osm_kozut_halozat; Type: VIEW; Schema: ext;
--

CREATE VIEW ext.osm_kozut_halozat AS
 SELECT planet_osm_line.osm_id,
    planet_osm_line.bridge,
    planet_osm_line.foot,
    planet_osm_line.highway,
    planet_osm_line.junction,
    planet_osm_line.layer,
    planet_osm_line.name,
    planet_osm_line.oneway,
    planet_osm_line.railway,
    planet_osm_line.ref,
    planet_osm_line.tunnel,
    planet_osm_line.z_order,
    planet_osm_line.tags,
    koz.gid AS k_gid,
    koz.kszam AS k_ref,
    koz.szak_street AS k_ref2,
    replace((koz.szak_label)::text, '/'::text, ';'::text) AS k_label,
    koz.kutka AS k_utkategoria,
    koz.pkod AS k_osztott,
    (koz.szak_tipus = 2) AS k_kozos_szak,
    koz.szak_irany AS k_kozos_szak_irany,
    (@ degrees(sin(public.st_angle(public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (20)::double precision), planet_osm_line.way), public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (20)::double precision), koz.wkb_geometry))))) AS angle_norm,
    planet_osm_line.way,
    koz.wkb_geometry AS k_geom
   FROM (public.planet_osm_line
     JOIN ext.kozut_halozat koz ON ((koz.gid = ( SELECT sub_koz.gid
           FROM ext.kozut_halozat sub_koz
          WHERE public.st_dwithin(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), sub_koz.wkb_geometry, (25)::double precision)
          ORDER BY (public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision) OPERATOR(public.<->) sub_koz.wkb_geometry)
         LIMIT 1))))
  WHERE ((planet_osm_line.highway = ANY (ARRAY['motorway'::text, 'motorway_link'::text, 'trunk'::text, 'trunk_link'::text, 'primary'::text, 'primary_link'::text, 'secondary'::text, 'secondary_link'::text, 'tertiary'::text, 'tertiary_link'::text, 'cycleway'::text])) AND (((koz.kutka)::text <> 'K'::text) OR (planet_osm_line.highway = 'cycleway'::text)) AND (((koz.kutka)::text = 'K'::text) OR (planet_osm_line.highway <> 'cycleway'::text)) AND ((@ degrees(sin(public.st_angle(public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (30)::double precision), planet_osm_line.way), public.st_intersection(public.st_buffer(public.st_lineinterpolatepoint(planet_osm_line.way, (0.5)::double precision), (30)::double precision), koz.wkb_geometry))))) < (30)::double precision) AND public.st_contains(( SELECT planet_osm_polygon.way
           FROM public.planet_osm_polygon
          WHERE (planet_osm_polygon.osm_id = '-21335'::integer)), planet_osm_line.way));


--
-- Name: osm_kozut_geom_diff; Type: MATERIALIZED VIEW; Schema: ext;
--

CREATE MATERIALIZED VIEW ext.osm_kozut_geom_diff AS
 SELECT x_dump.osm_id,
    (array_agg(x_dump.highway))[1] AS highway,
    (array_agg(x_dump.k_utkategoria))[1] AS k_utkategoria,
    (array_agg(x_dump.osm_ref))[1] AS osm_ref,
    (array_agg(x_dump.k_ref))[1] AS k_ref,
    round((min(x_dump.point_dists))::numeric, 3) AS min,
    round((max(x_dump.point_dists))::numeric, 3) AS max,
    round((percentile_cont((0.25)::double precision) WITHIN GROUP (ORDER BY x_dump.point_dists))::numeric, 3) AS q1,
    round((percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY x_dump.point_dists))::numeric, 3) AS q2,
    round((percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY x_dump.point_dists))::numeric, 3) AS q3,
    round((stddev_samp(x_dump.point_dists))::numeric, 3) AS stddev,
    round((var_samp(x_dump.point_dists))::numeric, 3) AS variance,
    (((array_agg(x_dump.oneway))[1] AND (var_samp(x_dump.point_dists) > percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY x_dump.point_dists)) AND (var_samp(x_dump.point_dists) > (4)::double precision) AND ((array_agg(x_dump.k_osm_length))[1] < (150)::double precision)) OR ((array_agg(x_dump.highway))[1] = ANY (ARRAY['primary_link'::text, 'secondary_link'::text, 'tertiary_link'::text])) OR (var_samp(x_dump.point_dists) > (1000)::double precision)) AS model_error,
    (array_agg(x_dump.oneway))[1] AS oneway,
    array_agg(x_dump.point_dists ORDER BY x_dump.point_path DESC) AS point_dists,
    round(((array_agg(x_dump.osm_length))[1])::numeric, 1) AS osm_length,
    round(((array_agg(x_dump.k_osm_length))[1])::numeric, 1) AS k_chunk_length,
    public.st_transform(public.st_setsrid((array_agg(x_dump.k_chunk_geom))[1], 23700), 3857) AS k_way,
    public.st_astext(public.st_transform(public.st_setsrid((array_agg(x_dump.osm_centroid))[1], 23700), 3857)) AS osm_centroid
   FROM ( WITH k_chunk AS (
                 SELECT osm_kozut_halozat.osm_id,
                    (osm_kozut_halozat.oneway = 'yes'::text) AS oneway,
                    osm_kozut_halozat.highway,
                    osm_kozut_halozat.k_utkategoria,
                    osm_kozut_halozat.ref AS osm_ref,
                    osm_kozut_halozat.k_label AS k_ref,
                    public.st_transform(osm_kozut_halozat.way, 23700) AS osm_way,
                    public.st_transform(public.st_linesubstring(osm_kozut_halozat.k_geom, (LEAST((public.st_linelocatepoint(osm_kozut_halozat.k_geom, public.st_startpoint(osm_kozut_halozat.way)))::numeric, (public.st_linelocatepoint(osm_kozut_halozat.k_geom, public.st_endpoint(osm_kozut_halozat.way)))::numeric))::double precision, (GREATEST((public.st_linelocatepoint(osm_kozut_halozat.k_geom, public.st_startpoint(osm_kozut_halozat.way)))::numeric, (public.st_linelocatepoint(osm_kozut_halozat.k_geom, public.st_endpoint(osm_kozut_halozat.way)))::numeric))::double precision), 23700) AS k_chunk_geom
                   FROM ext.osm_kozut_halozat
                )
         SELECT k_chunk.osm_id,
            public.st_length(k_chunk.osm_way) AS osm_length,
            public.st_length(k_chunk.k_chunk_geom) AS k_osm_length,
            k_chunk.highway,
            kozut_kategoria_nevek.name AS k_utkategoria,
            k_chunk.osm_ref,
            k_chunk.k_ref,
            k_chunk.k_chunk_geom,
            COALESCE(k_chunk.oneway, false) AS oneway,
            public.st_lineinterpolatepoint(k_chunk.osm_way, (0.5)::double precision) AS osm_centroid,
            (public.st_dumppoints(k_chunk.k_chunk_geom)).path AS point_path,
            public.st_distance((public.st_dumppoints(k_chunk.k_chunk_geom)).geom, k_chunk.osm_way) AS point_dists
           FROM (k_chunk
             LEFT JOIN ext.kozut_kategoria_nevek ON (((kozut_kategoria_nevek.id)::text = (k_chunk.k_utkategoria)::text)))
          WHERE ((public.geometrytype(k_chunk.k_chunk_geom) = 'LINESTRING'::text) AND (public.geometrytype(k_chunk.osm_way) = 'LINESTRING'::text))) x_dump
  GROUP BY x_dump.osm_id
  ORDER BY (((array_agg(x_dump.oneway))[1] AND (var_samp(x_dump.point_dists) > percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY x_dump.point_dists)) AND (var_samp(x_dump.point_dists) > (4)::double precision) AND ((array_agg(x_dump.k_osm_length))[1] < (150)::double precision)) OR ((array_agg(x_dump.highway))[1] = ANY (ARRAY['primary_link'::text, 'secondary_link'::text, 'tertiary_link'::text])) OR (var_samp(x_dump.point_dists) > (1000)::double precision)) DESC, (round((percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY x_dump.point_dists))::numeric, 3)) DESC
  WITH NO DATA;

CREATE INDEX osm_kozut_geom_diff_k_way_idx ON ext.osm_kozut_geom_diff USING gist (k_way);
CREATE UNIQUE INDEX osm_kozut_geom_diff_osm_id_idx ON ext.osm_kozut_geom_diff USING btree (osm_id);


CREATE INDEX kozut_lakott_terulet_atkelesi_geom_idx ON ext.kozut_lakott_terulet USING gist (wkb_geometry) WHERE ((szakjel)::text = 'átkelési'::text);
CREATE INDEX kozut_lakott_terulet_kulsosegi_geom_idx ON ext.kozut_lakott_terulet USING gist (wkb_geometry) WHERE ((szakjel)::text = 'külsőségi'::text);


