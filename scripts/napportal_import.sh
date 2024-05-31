#!/bin/sh
set -e  # Exit on error
set -u  # Treat unset variables as an error
#set -x

# By default it will import/update all data packages
# If a package name is given in the first parameter, only that package will be imported.

PACKAGE_ONLY=${1:-}

SCHEMA=ext

import () {

  if [ -n "PACKAGE_ONLY" ] && [ "$PACKAGE_ONLY" != $1 ]; then
    return 0
  fi

  echo "$(date --iso-8601=seconds): \t$1"

  PGSERVICEFILE=./.pg_service.conf \
  /usr/bin/ogr2ogr \
  -f "PostgreSQL" \
  -t_srs "EPSG:3857" \
  -nlt ${3:-LINESTRING} \
  -nln "$SCHEMA.$1" \
  --config OGR_TRUNCATE YES \
  PG:"service=osm_hu_service_owner" \
  "https://napphub.kozut.hu/geoserver/nhp_$2/wfs_$2/ows?service=wfs&version=1.0.0&request=GetFeature&resultType=results&typeNames=nhp_$2:wfs_$2&format_options=CHARSET:UTF-8&outputFormat=json" \
  2>&1

}

echo "$(date --iso-8601=seconds): Start importing…"

# Országos közúthálózat
import kozut_halozat 21616037

# Közút neve, kategóriája és kezelője
import kozut_kategoria 23061194

# Lakott területi szakaszok
import kozut_lakott_terulet 112990483

# Sebességkorlátozás
import kozut_sebesseghatar 216279007

# Szelvényjelek
import kozut_szelvenyjel 216411032 POINT

# Autóbusz megállóhelyek
import kozut_buszmegallo 23060426 POINT

# Összes gépjármű forgalmi sávok száma
import kozut_sav 216410505

# Egyirányú útpályák
import kozut_egyiranyu_utpalya 270531444

# Burkolat típusa, szélessége
import kozut_burkolat 23061166

# Éves keresztmetszeti forgalmi adatok
import kozut_forgalom 216414971

# Hídhasználati feltételek
import kozut_hid 23061762 POINT

echo "$(date --iso-8601=seconds): Finished."


