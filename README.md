# TEKSI - Wastewater

This repo holds all code related to the TEKSI Wastewater module (formerly QGEP).

It contains:
- the datamodel definition
- a QGIS plugin
- a QGIS project
- the documentation


## Release policy

Teksi-Wastewater follows a *rolling release* model, meaning that the `main` branch always constitutes the latest stable release. **Merging a pull request means deploying a new stable release.**

A yearly release (`YYYY.0`) is created at the same time as QGIS LTR releases (usually in march). Non-backwards compatible changes such as dropping support for dependencies or removing existing workflows can only be merged during a period of 1 month before the yearly release (matching QGIS ).

Two additional tags (`YYYY.1`, `YYYY.2`) are created in august and november. They only serve as milestones for organisational purposes (roadmapping) but otherwise do no differ from rolling release.

To accommodate that release model, the following rules apply:
- all changes happen in pull requests
- automated tests must be successfull before merged
- pull requests must be reviewed and approved by at least 1 other developer
- pull requests must be manually tested and approved by at least 1 user
- non-backwards compatible pull requests (dropping support for dependencies, removing existing workflows, etc.) must be tagged with the `frozen` tag


### Dependency support policy

For each yearly release (`YYYY.0`), the supported versions are updated like this:
- [QGIS](https://www.qgis.org/en/site/getinvolved/development/roadmap.html): support previous LTR, current LTR, current stable, drop anything older
- [Python](https://devguide.python.org/versions/): supported version at release date
- [Postgres](https://www.postgresql.org/support/versioning/): supported version at release date
- [Postgis](https://trac.osgeo.org/postgis/wiki/UsersWikiPostgreSQLPostGIS): keep versions matching a supported version at release date
- Ili2pg and java: not defined yet

Support for new versions of depepdencies can be added at any point in time.

Non-system dependencies (such as pure python libraries) can be upgraded at any time, provided they match the supported versions above.

Developement requiring features unavailable to older versions must be handled gracefully (user message).


### Datamodel support policy

Teksi-wastewater supports the export/important to/from the following interlis datamodels:
- SIA405_ABWASSER_2015_LV95
- VSA_KEK_2019_LV95
