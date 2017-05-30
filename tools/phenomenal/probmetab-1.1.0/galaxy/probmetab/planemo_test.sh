
# -- Use of conda dependencies
planemo conda_init --conda_prefix /tmp/mc
planemo conda_install --conda_prefix /tmp/mc .
planemo test --install_galaxy --conda_prefix /tmp/mc --conda_dependency_resolution 
