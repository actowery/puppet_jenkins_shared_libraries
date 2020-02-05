#!/bin/sh
PE_VERSION=$1
REPO='ci-job-configs'
JOB_NAME='init_release_job_creation'
TEMP_BRANCH="auto/${JOB_NAME}/${PE_VERSION}-release"
rm -rf ./${REPO}
git clone git@github.com:puppetlabs/${REPO} ./${REPO}
cd ${REPO}
git checkout -b $TEMP_BRANCH

sed -i "/init release anchor point/a \
\        - pm_conditional-step:\n\
\            m_scm_branch: '${PE_VERSION}-release'\n\
\            m_name: '{name}'\n\
\            m_value_stream: '{value_stream}'\n\
\            m_projects: '{value_stream}_pe-acceptance-tests_packaging_promotion_${PE_VERSION}-release,{value_stream}_{name}_init-cinext_smoke-upgrade_${PE_VERSION}-release,{value_stream}_{name}_init-cinext_split-smoke-upgrade_${PE_VERSION}-release,{value_stream}_jar-jar_component-update_${PE_VERSION}-release'" resources/job-templates/init.yaml

## create a PR and push it
git add ./resources/job-templates/init.yaml
git commit -m "${JOB_NAME} for ${PE_VERSION}-release"
git push origin $TEMP_BRANCH
PULL_REQUEST="$(git show -s --pretty='format:%s%n%n%b' | hub pull-request -b master -F -)"
echo "Opened mergeup PR for $(pwd): ${PULL_REQUEST}"
