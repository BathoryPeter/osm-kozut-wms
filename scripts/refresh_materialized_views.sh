#!/bin/sh

PARAMS="CONCURRENTLY"
if [ "$1" = "init" ]; then
  PARAMS=""
fi

echo "$(date --iso-8601=seconds): Start updating…"

run () {

  SQL="REFRESH MATERIALIZED VIEW $PARAMS $1"

  RESULT=$(PGSERVICEFILE=./.pg_service.conf /usr/bin/psql service=osm_hu_service_owner -c "$SQL" 2>&1)

  if [ $? -ne 0 ]; then
    STATUS="FAILED"
  else
    STATUS="OK"
  fi

  echo "$(date --iso-8601=seconds): $STATUS: $1 ($RESULT)"

}

run "ext.osm_kozut_geom_diff"
run "ext.kozut_potencialis_city_limit"
run "ext.osm_kozut_city_limit_egyezes"


echo "$(date --iso-8601=seconds): Finished."
