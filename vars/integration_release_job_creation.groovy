def call(String version, String codename) {

  if (version =~ '^20[0-9]{2}[.]([0-9]*)[.]([0-9]*)$') {
    println "${version} is a valid version"
  } else {
    println "${version} is an invalid version"
    throw new Exception("Invalid version")
  }
  //Execute bash script, catch and print output and errors
  node {
    sh "curl -O https://raw.githubusercontent.com/puppetlabs/puppet_jenkins_shared_libraries/master/vars/bash/integration_release_job_creation.sh"
    sh "chmod +x integration_release_job_creation.sh"
    sh "./integration_release_job_creation.sh $version $codename"
  }
}
