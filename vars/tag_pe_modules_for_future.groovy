def call(String release_branch) {

  if (release_branch =~ '^20[0-9]{2}[.]([0-9]*)[.]([0-9]*)-release') {
    println "${release_branch} is a valid release_branch"
  } else {
    println "${release_branch} is an invalid release branch. Input must be in form `x.y.z-release`"
    throw new Exception("Invalid release branch")
  }
  //Execute bash script, catch and print output and errors
  node {
    sh "curl -O https://raw.githubusercontent.com/puppetlabs/puppet_jenkins_shared_libraries/master/vars/bash/tag_pe_modules_for_future.sh"
    sh "chmod +x tag_pe_modules_for_future.sh"
    sh "./tag_pe_modules_for_future.sh $release_branch"
  }
}
