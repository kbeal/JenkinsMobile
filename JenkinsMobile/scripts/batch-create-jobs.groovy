def jobCount = 10
def configXml = "<?xml version='1.0' encoding='UTF-8'?><project><actions/><description></description><keepDependencies>false</keepDependencies><properties/><scm class=\"hudson.scm.NullSCM\"/><canRoam>true</canRoam><disabled>false</disabled><blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding><blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding><triggers/><concurrentBuild>false</concurrentBuild><builders><hudson.tasks.Shell><command>echo \$JOB_NAME &quot; - &quot; \$BUILD_NUMBER</command></hudson.tasks.Shell></builders><publishers/><buildWrappers/></project>"

for (i=0; i<jobCount; i++) {
jobName = "Job"+i
xmlStream = new ByteArrayInputStream( configXml.getBytes() )
newJob = Jenkins.instance.createProjectFromXML(jobName, xmlStream)

if ( (i%2) == 0 ) {
Jenkins.instance.getView("HalfJobs").add(newJob)
}
}