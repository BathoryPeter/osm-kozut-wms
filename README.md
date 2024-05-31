# OSM-Közút WMS

QA tool and QGIS WMS server for comparing OpenStreetMap and Magyar Közút datasets.

## Requirements

At first you need an up to date extract of Hungary from OSM, loaded into PostgreSQL by osm2pgsql. If you don't know how to do it, install [Overv/openstreetmap-tile-server](https://github.com/Overv/openstreetmap-tile-server).

You will also need docker, psql and ogr2ogr installed.

## Install

### Credentials
Create `.pg_service.conf` file in the root directory of the project using template `.pg_service.conf.tmpl`. Create separate blocks for importer and WMS server. In the `[osm_hu_service_owner]` block enter the user who is the owner of the DB (usually the same as used in osm2pgsql).

### Preparing the DB

Create schema and user, and set permissions. You can enter into psql using the service file: `psql -d 'service=osm_hu_service'

```SQL
CREATE SCHEMA ext;

CREATE USER osm_hu WITH ENCRYPTED PASSWORD '';

ALTER DEFAULT PRIVILEGES FOR ROLE <db_owner> IN SCHEMA ext GRANT SELECT ON TABLES TO osm_hu;
```

Run the importer script manually:
```
./scripts/napportal_import.sh
```

Create materialized views:
```
psql -d 'service=osm_hu_service -f sql/create_views.sql
```

### Starting the server

Last step is to start the QGIS WMS server:
```
docker compose up -d
```

### Post-install

* You can set up nginx reverse proxy using the example configuration in `nginx.tmpl.
* To keep the DB up to date, regularly refresh materialized views and update the Közút datasets. An example cron file can be found in `cron.tmpl`
* If you want to modify the QGIS project, copy the the projects/osm-kozut.qgs to yor local machine, do the modifications and replace the file on the server.
