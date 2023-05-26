#!/bin/bash
export CONFIG_FILE=/appdynamics/agent.config
print_env(){
  echo ${PYTHON_VERSION}
  echo ${CONTROLLER_HOST}
  echo ${CONTROLLER_PORT}
  echo ${ACCOUNT_NAME}
  echo ${ACCESS_KEY}
  echo ${APPLICATION_NAME}
  echo ${TIER_NAME}
  echo ${ADDITIONAL_PROPERTIES}
  echo ${TEST_ARTIFACT_1}
  echo ${WORKDIR}
  echo ${APP_PORT}
}

print_config(){
  cat $CONFIG_FILE
}
verify_artifact(){
  if [ -z "$TEST_ARTIFACT_1" ]; then
 echo "EXECUTABLE JAR ARTIFACT url not present, exiting."
 exit 1
fi
}


# directory for app files
download_artifact(){
  APP_DIR=/appfiles
mkdir -p $APP_DIR

TEST_ARTIFACT_PREFIX="TEST_ARTIFACT_"
BREAK=false
COUNTER=0
# Adding the jar files to class path
while [ $BREAK = false ]
do
        COUNTER=$(( $COUNTER + 1 ))
        VARIABLE="$TEST_ARTIFACT_PREFIX$COUNTER"
        echo ">>>>> $VARIABLE"
        echo "<<<<< ${!VARIABLE}"

        if [ -n "${!VARIABLE}" ]; then
                wget -P $APP_DIR  ${!VARIABLE}
                APP_TAR=`basename ${!VARIABLE}`
                APP_NAME=`echo $APP_TAR| cut -d'.' -f1`
                tar -xf $APP_DIR/${APP_TAR}
        else
                BREAK=true
        fi
done
}

setup_app(){
  wget https://artifactory.bare.appdynamics.com/artifactory/e2e-automation/apmpython/testAppsPython/TornadoMysqlApp/tormysql.tar
  tar -xjvf tormysql.tar
  echo "Entering app set up"
  apt-get update
  apt-get install libpython3.11-dev default-libmysqlclient-dev build-essential -y
cd tormysql
rm -rf alembic
rm alembic.ini
pip install -r requirements.txt
alembic init alembic
cp migration_scripts/env.py alembic
alembic revision --autogenerate -m "generate initial tables"
alembic upgrade head
}
start_agent(){
  set -x;

pyagent run -c $CONFIG_FILE python app.py
set +x;

}
print_env
print_config
verify_artifact
# download_artifact
setup_app
start_agent
