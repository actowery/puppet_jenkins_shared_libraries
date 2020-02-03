#USAGE: ./tag_pe_modules_for_future.sh <release_branch>

RELEASE_BRANCH=$1
VANAGON='pe-modules-vanagon'
MODULES='puppet-enterprise-modules'
MODULES_JSON_PATH='configs/components/puppet-enterprise-modules.json'

prepare_repo() {
    REPO=$1
    rm -rf ./${REPO}
    git clone git@github.com:puppetlabs/${REPO} ./${REPO}
}

verify_digits() {
    re='^[0-9]+$'
    input=$1
    if ! [[ $input =~ $re ]] ; then
        echo "error: Something went wrong validating version or current tag. VERSION should be in 2019.3.1 style format, current tag should be in 2019.3.1.0(-sha) format" >&2; exit 1
    fi
}

checkout_branch() {
    BRANCH=$1
    if ! git checkout $BRANCH; then
    echo "error: Something went wrong checing out ${BRANCH}. Check that this branch/sha exists." >&2; exit 1
    fi
}

get_tag_and_validate() {
    CURRENT_TAG=`git describe`
    echo "Current release tag on branch ${RELEASE_BRANCH} is ${CURRENT_TAG}"
    TAG_X_NUMBER=`echo $CURRENT_TAG | sed 's/\([[:digit:]]\+\)\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-\?.*/\1/'`
    TAG_Y_NUMBER=`echo $CURRENT_TAG | sed 's/[[:digit:]]\+\.\([[:digit:]]\+\)\.[[:digit:]]\+\.[[:digit:]]\+-\?.*/\1/'`
    TAG_Z_NUMBER=`echo $CURRENT_TAG | sed 's/[[:digit:]]\+\.[[:digit:]]\+\.\([[:digit:]]\+\)\.[[:digit:]]\+-\?.*/\1/'`

    num_ary=($TAG_X_NUMBER $TAG_Y_NUMBER $TAG_Z_NUMBER)
    for i in "${num_ary[@]}"
    do
        verify_digits $i
    done
}

tag_and_push() {
    if ! git tag -a $CURRENT_TAG -m "$CURRENT_TAG"; then
    echo "error: Tag ${CURRENT_TAG} already exists in ${MODULES} " >&2; exit 1
    fi
    
    git push git@github.com:puppetlabs/$MODULES.git $CURRENT_TAG
}

# Prep vanagon repo for scraping
prepare_repo $VANAGON
cd $VANAGON
checkout_branch $RELEASE_BRANCH
get_tag_and_validate

# Cat the json config, query ref, remove quotes so var will work in git command
SHA_TO_TAG=`cat $MODULES_JSON_PATH | jq '.ref' | tr -d \"`
if [ -z $SHA_TO_TAG ]; then
   echo "error: Parse error identifying reference SHA at ${VANAGON}/${MODULES_JSON_PATH}. Check that this file exists and is valid JSON." >&2; exit 1
fi

# Prep and tag puppet-enterprise-modules
cd ..
prepare_repo ${MODULES}
cd ${MODULES}
checkout_branch $SHA_TO_TAG
tag_and_push

# Cleanup
cd ..
rm -rf ${VANAGON} ${MODULES}


