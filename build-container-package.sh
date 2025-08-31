rm -rf soib-container
mkdir soib-container
mkdir soib-container/x86_64
mkdir soib-container/arm64
mkdir soib-container/output
mkdir -p soib-container/config/localhost
mkdir -p soib-container/data/00_data
mkdir -p soib-container/data/01_analyses_full/dataforsim

cp README-CONTAINER.md soib-container/
cp config/localhost/config.R soib-container/config/localhost
cp run_container_package.sh soib-container/run_container.sh
cp 00_data/analyses_metadata.RData soib-container/data/00_data
cp 01_analyses_full/specieslists.RData soib-container/data/01_analyses_full
cp 00_data/current_soib_migyears.RData soib-container/data/00_data

# The full data, metadata
cp 01_analyses_full/dataforanalyses.RData-data_opt soib-container/data/01_analyses_full
cp 01_analyses_full/dataforanalyses.RData-metadata soib-container/data/01_analyses_full
cp 01_analyses_full/species_names.RData soib-container/data/01_analyses_full
cp 01_analyses_full/timegroups.RData soib-container/data/01_analyses_full_data
# All random groupids
cp 01_analyses_full/rgids-*.RData soib-container/data/01_analyses_full/
# Stats to guide scheduling
cp 01_analyses_full/species_run_stats.RData soib-container/data/01_analyses_full

cp install-x86_64-container.sh soib-container/
cp install-arm64-container.sh soib-container/

# copy container from appropriate arch dir
#
cp `uname -m`/soib.tar soib-container/`uname -m`
rm soib-container.zip
zip -r soib-container.zip soib-container
