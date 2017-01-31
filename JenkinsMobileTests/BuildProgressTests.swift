//
//  BuildProgressTests.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 2/24/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class BuildProgressTests: XCTestCase {
    let datamgr = DataManager.sharedInstance
    var jenkinsInstance: JenkinsInstance?
    var context: NSManagedObjectContext?
    
    override func setUp() {
        super.setUp()
        
        //context = self.datamgr.mainMOC
        context = self.datamgr.masterMOC
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://localhost:8081/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://localhost:8081", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        
        context?.performAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues as [AnyHashable: Any], in: self.context!)})
        self.jenkinsInstance?.password = "password"
        self.jenkinsInstance?.allowInvalidSSLCertificate = true
        
        saveContext()
    }
    
    func testUpdateBuildProgress() {
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJob(withValues: jobVals1, in: context!)
        let buildvals = [BuildNumberKey: 1, BuildURLKey: "http://localhost:8080/job/Job1/1/", BuildJobKey: job, BuildEstimatedDurationKey: 120000]
        let build = Build.createBuild(withValues: buildvals, in: context!)
        DataManager.sharedInstance.saveMainContext()
        let buildprogress = BuildProgress(build: build!)
        
        XCTAssertEqual(buildprogress!.fractionCompleted, 0.0)
        
        build!.executor = [BuildExecutorProgressKey: 15]
        DataManager.sharedInstance.saveMainContext()
        DataManager.sharedInstance.saveContext(DataManager.sharedInstance.masterMOC)
        
        XCTAssertEqual(buildprogress!.fractionCompleted, 0.15)
    }
    
    func saveContext () {
        datamgr.saveContext(datamgr.mainMOC)
        datamgr.masterMOC.performAndWait({
            self.datamgr.saveContext(self.datamgr.masterMOC)
        })
    }
}
