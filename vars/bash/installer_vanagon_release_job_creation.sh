#!/bin/sh
PE_VERSION=$1
REPO='ci-job-configs'
FAMILY=`echo $PE_VERSION | sed "s/\(.*\..*\)\..*/\1/"`
X_FAMILY=`echo $FAMILY | sed "s/\(.*\)\..*/\1/"`
Y_FAMILY=`echo $FAMILY | sed "s/.*\.\(.*\)/\1/"`
JOB_NAME='installer_vanagon_release_job_creation'
YAML_FILEPATH=./jenkii/enterprise/projects/pe-installer-vanagon.yaml
TEMP_BRANCH="auto/${JOB_NAME}/${PE_VERSION}-release"

rm -rf ./${REPO}
git clone git@github.com:puppetlabs/${REPO} ./${REPO}
cd ${REPO}
git checkout -b $TEMP_BRANCH

# supported_upgrade_defaults logic
# incase we are basing the release branch off of master
upgrade_default_name="p_${X_FAMILY}_${Y_FAMILY}_installer_vanagon_settings"
grep_output=`grep ${upgrade_default_name} jenkii/enterprise/projects/pe-installer-vanagon.yaml`
FAMILY_SETTING="${X_FAMILY}_${Y_FAMILY}"
if [ -z "$grep_output" ]; then
    FAMILY_SETTING="master"
fi

echo "
        - 'pe-installer-vanagon-with-pez-and-ui-acceptance':
            component_scm_branch: '${PE_VERSION}-release'
            vanagon_scm_branch: '${PE_VERSION}-release'
            promote_branch: '${PE_VERSION}-release'
            <<: *p_${FAMILY_SETTING}_installer_vanagon_settings" >> $YAML_FILEPATH

## create a PR and push it
git add $YAML_FILEPATH
git commit -m "${JOB_NAME} for ${PE_VERSION}-release"
git push origin $TEMP_BRANCH
PULL_REQUEST="$(git show -s --pretty='format:%s%n%n%b' | hub pull-request -b master -F -)"
echo "Opened mergeup PR for $(pwd): ${PULL_REQUEST}"
