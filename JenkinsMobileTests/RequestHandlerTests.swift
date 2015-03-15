//
//  RequestHandlerTests.swift
//  JenkinsMobile
//
//  Created by Kyle on 1/27/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class RequestHandlerTests: XCTestCase {
    
    let requestHandler = KDBJenkinsRequestHandler()
    let mgr = SyncManager.sharedInstance
    var context: NSManagedObjectContext?
    var jenkinsInstance: JenkinsInstance?
    
    override func setUp() {
        super.setUp()
        
        let modelURL = NSBundle.mainBundle().URLForResource("JenkinsMobile", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let coord = NSPersistentStoreCoordinator(managedObjectModel: model!)
        context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)        
        coord.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        context!.persistentStoreCoordinator = coord
        mgr.mainMOC = context;
        mgr.masterMOC = context;
        mgr.requestHandler = requestHandler
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://jenkins:8080", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        
        context?.performBlockAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues, inManagedObjectContext: self.context)})
        self.jenkinsInstance?.password = "admin"
        
        mgr.currentJenkinsInstanceURL = NSURL(string: jenkinsInstance!.url)
        
        saveContext()
    }
    
    func saveContext () {
        var error: NSError? = nil
        if context == nil {
            return
        }
        if !context!.hasChanges {
            return
        }
        let saveResult: Bool = context!.save(&error)
        
        if (!saveResult) {
            println("Error saving context: \(error?.localizedDescription)\n\(error?.userInfo)")
            abort()
        } else {
            println("Successfully saved test managed object context")
        }
    }
    
    func testJenkinsInstanceDetailRequest() {
        let requestReceivedNotificationExpectation = expectationForNotification(JenkinsInstanceDetailResponseReceivedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let url: String = userInfo[JenkinsInstanceURLKey] as String
            
            if url == "http://jenkins:8080" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let requestFailedNotificationExpectation = expectationForNotification(JenkinsInstanceDetailRequestFailedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as NSError
            let errorUserInfo: Dictionary = requestError.userInfo!
            let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
            
            if url.absoluteString == "http://www.google.com/jenkins" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://jenkins:8080", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        let jenkinsInstanceValues2 = [JenkinsInstanceNameKey: "TestInstance2", JenkinsInstanceURLKey: "http://www.google.com/jenkins", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        let jinstance2 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues2, inManagedObjectContext: self.context)
        jinstance1.password = "admin"
        jinstance2.password = "admin"
        
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        requestHandler.importDetailsForJenkinsInstance(jinstance2)

        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobDetailRequest() {
        let requestReceivedNotificationExpectation = expectationForNotification(JobDetailResponseReceivedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let url: String = userInfo[JobURLKey] as String
            
            if url == "http://jenkins:8080/job/Job3/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let requestFailedNotificationExpectation = expectationForNotification(JobDetailRequestFailedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as NSError
            let errorUserInfo: Dictionary = requestError.userInfo!
            let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
            
            if url.absoluteString == "http://www.google.com/jenkins/job/Job1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        requestHandler.importDetailsForJobWithURL(NSURL(string: "http://jenkins:8080/job/Job3/"), andJenkinsInstance: jenkinsInstance)
        requestHandler.importDetailsForJobWithURL(NSURL(string: "http://www.google.com/jenkins/job/Job1/"), andJenkinsInstance: jenkinsInstance)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testViewDetailRequest() {
        let requestReceivedNotificationExpectation = expectationForNotification(ViewDetailResponseReceivedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let url: String = userInfo[ViewURLKey] as String
            
            if url == "http://jenkins:8080/view/GrandParent/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let requestFailedNotificationExpectation = expectationForNotification(ViewDetailRequestFailedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as NSError
            let errorUserInfo: Dictionary = requestError.userInfo!
            let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
            
            if url.absoluteString == "http://www.google.com/jenkins/view/View1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let viewVals = [ViewNameKey: "View1", ViewURLKey: "http://jenkins:8080/view/GrandParent/", ViewJenkinsInstanceKey: jenkinsInstance!]
        let viewVals2 = [ViewNameKey: "View2", ViewURLKey: "http://www.google.com/jenkins/view/View1/", ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        let view2 = View.createViewWithValues(viewVals2, inManagedObjectContext: context)
        saveContext()
        
        requestHandler.importDetailsForView(view1)
        requestHandler.importDetailsForView(view2)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationDetailRequest() {
        let requestReceivedNotificationExpectation = expectationForNotification(ActiveConfigurationDetailResponseReceivedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let url: String = userInfo[ActiveConfigurationURLKey] as String
            
            if url == "http://jenkins:8080/job/Job6/config1=10,config2=test/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let requestFailedNotificationExpectation = expectationForNotification(ActiveConfigurationDetailRequestFailedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as NSError
            let errorUserInfo: Dictionary = requestError.userInfo!
            let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
            
            if url.absoluteString == "http://www.google.com/jenkins/job/Job1/config1=true/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let jobvals = [JobNameKey: "Job6", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job6/", JobLastSyncKey: NSDate(), JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        let jobvals2 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com/jenkins/job/Job1/", JobLastSyncKey: NSDate(), JobJenkinsInstanceKey: jenkinsInstance!]
        let job2 = Job.createJobWithValues(jobvals2, inManagedObjectContext: context)
        
        let acVals = [ActiveConfigurationNameKey: "config=1", ActiveConfigurationURLKey: "http://jenkins:8080/job/Job6/config1=10,config2=test/", ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let acVals2 = [ActiveConfigurationNameKey: "config=2", ActiveConfigurationURLKey: "http://www.google.com/jenkins/job/Job1/config1=true/", ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        let ac2 = ActiveConfiguration.createActiveConfigurationWithValues(acVals2, inManagedObjectContext: self.context)
        
        requestHandler.importDetailsForActiveConfiguration(ac)
        requestHandler.importDetailsForActiveConfiguration(ac2)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testBuildDetailRequest() {
        let requestReceivedNotificationExpectation = expectationForNotification(BuildDetailResponseReceivedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let url: String = userInfo[BuildURLKey] as String
            
            if url == "http://jenkins:8080/job/Job6/1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let requestFailedNotificationExpectation = expectationForNotification(BuildDetailRequestFailedNotification, object: self.requestHandler, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as NSError
            let errorUserInfo: Dictionary = requestError.userInfo!
            let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
            
            if url.absoluteString == "http://www.google.com/jenkins/job/Job1/1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/TestJob/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let buildVals = [BuildJobKey: job, BuildURLKey: "http://jenkins:8080/job/Job6/1/", BuildNumberKey: 1]
        let buildVals2 = [BuildJobKey: job, BuildURLKey: "http://www.google.com/jenkins/job/Job1/1/", BuildNumberKey: 1]
        let build1 = Build.createBuildWithValues(buildVals, inManagedObjectContext: self.context)
        let build2 = Build.createBuildWithValues(buildVals2, inManagedObjectContext: self.context)
        
        requestHandler.importDetailsForBuild(build1)
        requestHandler.importDetailsForBuild(build2)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
}