#!/bin/sh
PE_VERSION=$1
CODENAME=$2
REPO='ci-job-configs'
FAMILY=`echo $PE_VERSION | sed "s/\(.*\..*\)\..*/\1/"`
X_FAMILY=`echo $FAMILY | sed "s/\(.*\)\..*/\1/"`
Y_FAMILY=`echo $FAMILY | sed "s/.*\.\(.*\)/\1/"`
JOB_NAME='integration_release_job_creation'
YAML_FILEPATH=./jenkii/enterprise/projects/pe-integration.yaml
TEMP_BRANCH="auto/${JOB_NAME}/${PE_VERSION}-release"

rm -rf ./${REPO}
git clone git@github.com:puppetlabs/${REPO} ./${REPO}
cd ${REPO}
git pull
git checkout -b $TEMP_BRANCH

# supported_upgrade_defaults logic
# incase we are basing the release branch off of master
upgrade_default_name="p_${X_FAMILY}_${Y_FAMILY}_supported_upgrade_defaults"
grep_output=`grep ${upgrade_default_name} $YAML_FILEPATH`
FAMILY_SETTING="${X_FAMILY}_${Y_FAMILY}"
if [ -z "$grep_output" ]; then
    FAMILY_SETTING="master"
fi

# Renames the usual p_scm_alt_code_name, which is used by pe-backup-tools, in order to avoid duplicate job declerations
`sed -i "s/p_scm_alt_code_name: '${CODENAME}'/p_scm_alt_code_name: '${CODENAME}_replacement'/" $YAML_FILEPATH`

echo "
        - '{value_stream}_{name}_workspace-creation_{qualifier}':
            scm_branch: ${PE_VERSION}-release
            qualifier: '{scm_branch}'

        - 'pe-integration-smoke-upgrade':
            pe_family: ${FAMILY}
            scm_branch: ${PE_VERSION}-release
            cinext_preserve_resources: 'true'
            beaker_helper: 'lib/beaker_helper.rb'
            beaker_tag: 'risk:high,risk:medium'
            upgrader_smoke_platform_axis_flatten_split:
              - centos6-64mcd-64agent%2Cpe_postgres.
            <<: *p_${FAMILY_SETTING}_supported_upgrade_defaults

        - 'pe-integration-non-standard-agents':
            pe_family: ${FAMILY}
            scm_branch: ${PE_VERSION}-release
            pipeline_scm_branch: ${PE_VERSION}-release
            <<: *p_${FAMILY_SETTING}_non_standard_settings

        - 'pe-integration-full-release':
            pe_family: ${FAMILY}
            scm_branch: ${PE_VERSION}-release
            p_scm_alt_code_name: '${CODENAME}'
            <<: *p_${FAMILY_SETTING}_settings" >> $YAML_FILEPATH


## create a PR and push it
git add $YAML_FILEPATH
git commit -m "${JOB_NAME} for ${PE_VERSION}-release"
git push origin $TEMP_BRANCH
PULL_REQUEST="$(git show -s --pretty='format:%s%n%n%b' | hub pull-request -b master -F -)"
echo "Opened mergeup PR for $(pwd): ${PULL_REQUEST}"
