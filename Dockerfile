FROM ubuntu:14.04
MAINTAINER PhenoMeNal-H2020 Project <phenomenal-h2020-users@googlegroups.com>
LABEL Description="Galaxy test for running inside Kubernetes."

ENV GALAXY_RELEASE=release_16.04 \
GALAXY_REPO=https://github.com/phnmnl/galaxy \
GALAXY_REPO_BRANCH=feature/allfeats \
GALAXY_ROOT=/galaxy-central \ 
GALAXY_CONFIG_DIR=/etc/galaxy


ENV GALAXY_CONFIG_FILE=$GALAXY_CONFIG_DIR/galaxy.ini \
GALAXY_CONFIG_JOB_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_conf.xml \
GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_metrics_conf.xml \
GALAXY_VIRTUAL_ENV=/galaxy_venv \
GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_POSTGRES_UID=1550 \
GALAXY_POSTGRES_GID=1550 \
GALAXY_HOME=/home/galaxy \
GALAXY_LOGS_DIR=/home/galaxy/logs \
GALAXY_DEFAULT_ADMIN_USER=admin@galaxy.org \
GALAXY_DEFAULT_ADMIN_PASSWORD=admin \
GALAXY_DEFAULT_ADMIN_KEY=admin \
GALAXY_DESTINATIONS_DEFAULT=local \
EXPORT_DIR=/export \
# The following 2 ENV vars can be used to set the number of uwsgi processes and threads
UWSGI_PROCESSES=2 \
UWSGI_THREADS=4 \
# Set the number of Galaxy handlers
GALAXY_HANDLER_NUMPROCS=2 \
# Setting a standard encoding. This can get important for things like the unix sort tool.
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# Create the postgres user before apt-get does (with the configured UID/GID) to facilitate sharing /export/postgresql with non-Linux hosts
RUN groupadd -r postgres -g $GALAXY_POSTGRES_GID && \
    adduser --system --quiet --home /var/lib/postgresql --no-create-home --shell /bin/bash --gecos "" --uid $GALAXY_POSTGRES_UID --gid $GALAXY_POSTGRES_GID postgres

RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https software-properties-common wget && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y mercurial python-psycopg2 postgresql-9.3 sudo python-virtualenv \
    libyaml-dev libffi-dev libssl-dev \
    curl git python-pip python-gnuplot python-psutil && \
    pip install --upgrade pip && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    mkdir $EXPORT_DIR $GALAXY_HOME $GALAXY_LOGS_DIR && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $EXPORT_DIR $GALAXY_LOGS_DIR

RUN mkdir $GALAXY_ROOT && \
    git clone -b $GALAXY_REPO_BRANCH $GALAXY_REPO $GALAXY_ROOT && \
    virtualenv $GALAXY_VIRTUAL_ENV && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_VIRTUAL_ENV && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT && \
    # Setup Galaxy configuration files.
    mkdir -p $GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR/web && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONFIG_DIR

RUN echo "-e git+https://github.com/pcm32/pykube.git@feature/allMergedFeatures#egg=pykube" >> $GALAXY_ROOT/requirements.txt
RUN su $GALAXY_USER -c "cp $GALAXY_ROOT/config/galaxy.ini.sample $GALAXY_CONFIG_FILE"

ADD roles/ /tmp/ansible/roles
ADD provision.yml /tmp/ansible/provision.yml

RUN apt-get update && apt-get install --no-install-recommends -y software-properties-common && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-add-repository -y ppa:galaxyproject/nginx && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y nginx-extras=1.4.6-1ubuntu3.4ppa1 nginx-common=1.4.6-1ubuntu3.4ppa1 \
    uwsgi uwsgi-plugin-python supervisor python-dev libffi-dev libssl-dev \
    libyaml-dev nodejs-legacy npm ansible gcc && \
ansible-playbook /tmp/ansible/provision.yml \
    --extra-vars galaxy_venv_dir=$GALAXY_VIRTUAL_ENV \
    --extra-vars galaxy_log_dir=$GALAXY_LOGS_DIR \
    --extra-vars galaxy_user_name=$GALAXY_USER \
    --extra-vars galaxy_config_file=$GALAXY_CONFIG_FILE \
    --extra-vars galaxy_config_dir=$GALAXY_CONFIG_DIR \
    --extra-vars galaxy_job_conf_path=$GALAXY_CONFIG_JOB_CONFIG_FILE \
    --extra-vars galaxy_job_metrics_conf_path=$GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE \
    --extra-vars galaxy_extras_config_condor=False \
    --extra-vars galaxy_extras_config_condor_docker=False \
    --extra-vars galaxy_extras_config_proftpd=False \
    --extra-vars galaxy_extras_config_slurm=False \
    --extra-vars galaxy_extras_config_pbs=False \
    --extra-vars galaxy_extras_config_galaxy_job_metrics=False \
    --extra-vars galaxy_extras_galaxy_destination_default=local \
    --extra-vars galaxy_server_dir=$GALAXY_ROOT \
    --extra-vars supervisor_manage_slurm=False \
    --extra-vars supervisor_manage_proftp=False \
    --extra-vars supervisor_manage_reports=False \
    --extra-vars supervisor_manage_docker=False \
    --extra-vars supervisor_manage_nodeproxy=False \
    --extra-vars use_slurm=False \
    --extra-vars use_docker=False \
    --tags=galaxyextras -c local && \
    apt-get purge -y software-properties-common gcc && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /shed_tools && chown $GALAXY_USER:$GALAXY_USER /shed_tools

# The following commands will be executed as User galaxy
USER galaxy

WORKDIR $GALAXY_ROOT

# Configure Galaxy to use the Tool Shed
RUN mkdir $GALAXY_ROOT/tool_deps

ENV GALAXY_CONFIG_DATABASE_CONNECTION=postgresql://galaxy:galaxy@localhost:5432/galaxy?client_encoding=utf8 \
GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=./tool_deps \
GALAXY_CONFIG_ADMIN_USERS=admin@galaxy.org \
GALAXY_CONFIG_MASTER_API_KEY=HSNiugRFvgT574F43jZ7N9F3 \
GALAXY_CONFIG_BRAND="Galaxy Docker Build" \
GALAXY_CONFIG_STATIC_ENABLED=False \
GALAXY_CONFIG_JOB_WORKING_DIRECTORY=/export/galaxy-central/database/job_working_directory \
GALAXY_CONFIG_FILE_PATH=/export/galaxy-central/database/files \
GALAXY_CONFIG_NEW_FILE_PATH=/export/galaxy-central/database/files \
GALAXY_CONFIG_TEMPLATE_CACHE_PATH=/export/galaxy-central/database/compiled_templates \
GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=/export/galaxy-central/database/citations/data \
GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=/export/galaxy-central/database/pbs \
GALAXY_CONFIG_FTP_UPLOAD_DIR=/export/galaxy-central/database/ftp \
GALAXY_CONFIG_FTP_UPLOAD_SITE=galaxy.docker.org \
GALAXY_CONFIG_USE_PBKDF2=False \
GALAXY_CONFIG_NGINX_X_ACCEL_REDIRECT_BASE=/_x_accel_redirect \
GALAXY_CONFIG_NGINX_X_ARCHIVE_FILES_BASE=/_x_accel_redirect \
GALAXY_CONFIG_NGINX_UPLOAD_STORE=/tmp/nginx_upload_store \
GALAXY_CONFIG_NGINX_UPLOAD_PATH=/_upload \
GALAXY_CONFIG_DYNAMIC_PROXY_MANAGE=False \
GALAXY_CONFIG_VISUALIZATION_PLUGINS_DIRECTORY=config/plugins/visualizations \
GALAXY_CONFIG_TRUST_IPYTHON_NOTEBOOK_CONVERSION=True \
GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
GALAXY_CONFIG_SANITIZE_ALL_HTML=False \
GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
GALAXY_CONFIG_WELCOME_URL=$GALAXY_CONFIG_DIR/web/welcome.html \
GALAXY_CONFIG_OVERRIDE_DEBUG=False \
# Define the default postgresql database path
PG_DATA_DIR_DEFAULT=/var/lib/postgresql/9.3/main/ \
PG_DATA_DIR_HOST=/export/postgresql/9.3/main/ \
# We need to set $HOME for some Tool Shed tools (e.g Perl libs with $HOME/.cpan)
HOME=$GALAXY_HOME

# prefetch Python wheels
RUN ./scripts/common_startup.sh && \
    # Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
    cd $GALAXY_ROOT/lib/galaxy/web/proxy/js && npm install

# Switch back to User root
USER root

# Include all needed scripts from the host
ADD ./setup_postgresql.py /usr/local/bin/setup_postgresql.py

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'

RUN rm $PG_DATA_DIR_DEFAULT -rf && \
    python /usr/local/bin/setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT && \
    service postgresql start && \
    . $GALAXY_VIRTUAL_ENV/bin/activate && \
    sh create_db.sh -c $GALAXY_CONFIG_FILE && \
    python /usr/local/bin/create_galaxy_user.py --user $GALAXY_DEFAULT_ADMIN_USER --password $GALAXY_DEFAULT_ADMIN_PASSWORD -c $GALAXY_CONFIG_FILE --key $GALAXY_DEFAULT_ADMIN_KEY && \
    service postgresql stop

RUN chmod +x /usr/bin/startup

# This needs to happen here and not above, otherwise the Galaxy start
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG /export/galaxy-central/integrated_tool_panel.xml


#COPY config/galaxy.ini $GALAXY_CONFIG_FILE
COPY config/job_conf.xml $GALAXY_CONFIG_JOB_CONFIG_FILE
COPY config/tool_conf.xml $GALAXY_ROOT/config/tool_conf.xml
#COPY other_xml/integrated_tool_panel.xml integrated_tool_panel.xml
COPY tools/phenomenal $GALAXY_ROOT/tools/phenomenal

# Galaxy runs on python < 3.5, so https://github.com/kelproject/pykube/issues/29 recommends
ENV PYKUBE_KUBERNETES_SERVICE_HOST kubernetes

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9002 (supvisord web app)
EXPOSE :80
EXPOSE :21
EXPOSE :8800
EXPOSE :9002


VOLUME ["/export/", "/data/" ]

CMD ["/usr/bin/startup"]
