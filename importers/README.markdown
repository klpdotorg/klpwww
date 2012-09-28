#Order of running the databases

* Run the scripts on an existing www database
* ang_infa, libinfra, klpsys amd update_dise have a dependency on klpwww_ver2
* Should probably re-write those scripts to run without other db dependency

APP_DIR/importers/coord/klp-coord.sh

APP_DIR/importers/sys/klpsys.sh 

APP_DIR/importers/dise_db/db_scripts/dise_all.sh

APP_DIR/importers/ang_infra/db_scripts/ang_infra.sh

APP_DIR/importers/libinfra/libinfra.sh

APP_DIR/importers/klpwww.sh

APP_DIR/importers/dise_db/db_scripts/update_dise.sh
