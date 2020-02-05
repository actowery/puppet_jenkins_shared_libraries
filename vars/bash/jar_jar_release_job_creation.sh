#!/bin/sh
PE_VERSION=$1
REPO='ci-job-configs'
FAMILY=`echo $PE_VERSION | sed "s/\(.*\..*\)\..*/\1/"`
X_FAMILY=`echo $FAMILY | sed "s/\(.*\)\..*/\1/"`
Y_FAMILY=`echo $FAMILY | sed "s/.*\.\(.*\)/\1/"`
JOB_NAME='jar_jar_release_job_creation'
YAML_FILEPATH=./jenkii/enterprise/projects/jar-jar.yaml
TEMP_BRANCH="auto/${JOB_NAME}/${PE_VERSION}-release"

rm -rf ./${REPO}
git clone git@github.com:puppetlabs/${REPO} ./${REPO}
cd ${REPO}
git pull
git checkout -b $TEMP_BRANCH

echo "
        # ---- ${PE_VERSION}-release ----
        # this is triggered by the PE compose hook and is not part of the normal pipeline
        - '{value_stream}_jar-jar_component-update_{qualifier}':
            scm_branch: '${PE_VERSION}-release'
            pe_family: '${FAMILY}'
            pgdb_user: 'jar_jar'
            pgdb_password: 'how_wude'
            tpb_projects:
                - '{value_stream}_{name}_release-clj_{scm_branch}'
            tpb_property_file: release.props

        - '{value_stream}_{name}_release-clj_{qualifier}':
            slnotifier_notify_success: True
            scm_branch: '${PE_VERSION}-release'" >> $YAML_FILEPATH


## create a PR and push it
git add $YAML_FILEPATH
git commit -m "${JOB_NAME} for ${PE_VERSION}-release"
git push origin $TEMP_BRANCH
PULL_REQUEST="$(git show -s --pretty='format:%s%n%n%b' | hub pull-request -b master -F -)"
echo "Opened mergeup PR for $(pwd): ${PULL_REQUEST}"
