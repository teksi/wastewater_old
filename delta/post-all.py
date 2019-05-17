#!/usr/bin/env python3

import sys, os
import psycopg2
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from pum.core.deltapy import DeltaPy
from view.create_views import create_views


class CreateViews(DeltaPy):

    def run(self):
        qgep_wastewater_structure_extra = self.variable('qgep_wastewater_structure_extra', None)
        qgep_reach_extra = self.variable('qgep_reach_extra', None)

        create_views(srid=self.variable('SRID'),
                     pg_service=self.pg_service,
                     qgep_wastewater_structure_extra=qgep_wastewater_structure_extra,
                     qgep_reach_extra=qgep_reach_extra)

        # refresh network views
        conn = psycopg2.connect("service={0}".format(self.pg_service))
        cursor = conn.cursor()
        cursor.execute('REFRESH MATERIALIZED view qgep_od.vw_network_node;')
        cursor.execute('REFRESH MATERIALIZED view qgep_od.vw_network_segment;')
        conn.commit()
        conn.close()
