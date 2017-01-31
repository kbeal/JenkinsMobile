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
    
    let adminUserName     = "kbeal"
    let adminUserPassword = "changeme"
    let requestHandler = KDBJenkinsRequestHandler()
    let mgr = SyncManager.sharedInstance
    let datamgr = DataManager.sharedInstance
    var context: NSManagedObjectContext!
    var jenkinsInstance: JenkinsInstance?
    
    override func setUp() {
        super.setUp()
        
        self.context = self.datamgr.mainMOC
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://localhost:8081/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "PrimaryTestInstance", JenkinsInstanceURLKey: "http://localhost:8081/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: self.adminUserName, JenkinsInstancePrimaryViewKey: primaryView] as [String : Any]
        
        context.performAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues as [AnyHashable: Any], in: self.context)})
        self.jenkinsInstance?.password = self.adminUserPassword
        
        saveContext()
    }
    
    func saveContext () {
        self.datamgr.saveMainContext()
    }
    
    func testJenkinsPing() {
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstancePingResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            return true
        })
        
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstancePingRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            if (url.absoluteString == "http://www.google.com/api/json/") {
                expectationFulfilled = true
            }

            return expectationFulfilled
        })
        
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "JIPingRequestTestInstance", JenkinsInstanceURLKey: "http://localhost:8080", JenkinsInstanceEnabledKey: true] as [String : Any]
        let jenkinsInstanceValues2 = [JenkinsInstanceNameKey: "JIPingRequestTestInstance", JenkinsInstanceURLKey: "http://www.google.com/api/json/", JenkinsInstanceEnabledKey: true] as [String : Any]
        let jinstance = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues1 as [AnyHashable: Any], in: self.context)
        let jinstance2 = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues2 as [AnyHashable: Any], in: self.context)
        
        jinstance.allowInvalidSSLCertificate = true

        saveContext()
        requestHandler.pingJenkinsInstance(jinstance)
        requestHandler.pingJenkinsInstance(jinstance2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testJenkinsAuthentication() {
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceAuthenticationResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            return true
        })
        
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceAuthenticationRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if (url.absoluteString == "http://localhost:8080/") {
                expectationFulfilled = true
            }
            
            return expectationFulfilled
        })
        
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "JIAuthRequestTestInstance", JenkinsInstanceURLKey: "http://localhost:8080", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "kbeal", JenkinsInstanceShouldAuthenticateKey: true] as [String : Any]
        let jinstance = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues1, in: self.context)
        jinstance.password = "changeme"
        
        saveContext()
        
        requestHandler.authenticateJenkinsInstance(jinstance)
        
        jinstance.username = "user"
        
        requestHandler.authenticateJenkinsInstance(jinstance)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceViewsRequest() {
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceViewsResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let viewsData = userInfo[JenkinsInstanceViewsKey]
            let jinstance: JenkinsInstance = userInfo[RequestedObjectKey] as! JenkinsInstance
            if jinstance.url == "http://localhost:8080/" && (viewsData as AnyObject).count == 3 {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceViewsRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "JIDetailRequestTestInstance", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: self.adminUserName] as [String : Any]
        let jenkinsInstanceValues2 = [JenkinsInstanceNameKey: "JIDetailRequestFailure", JenkinsInstanceURLKey: "http://www.google.com/jenkins", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: self.adminUserName] as [String : Any]
        let jinstance1 = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues1 as [AnyHashable: Any], in: self.context)
        let jinstance2 = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues2 as [AnyHashable: Any], in: self.context)
        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.password = self.adminUserPassword
        jinstance2.password = "admin"
        saveContext()
        
        requestHandler.importViews(for: jinstance1)
        requestHandler.importViews(for: jinstance2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testViewChildViewsRequest() {
        _ = expectation(forNotification: NSNotification.Name.ViewChildViewsResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let viewsData = userInfo[ViewViewsKey]
            let view: View = userInfo[RequestedObjectKey] as! View
            
            if view.url == "http://localhost:8080/view/Test%20View/" && (viewsData as AnyObject).count == 3 {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.ViewChildViewsRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/view/View1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let viewVals = [ViewNameKey: "View1", ViewURLKey: "http://localhost:8080/view/Test%20View/", ViewJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let viewVals2 = [ViewNameKey: "View2", ViewURLKey: "http://www.google.com/jenkins/view/View1/", ViewJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let view1 = View.createView(withValues: viewVals, in: context)
        let view2 = View.createView(withValues: viewVals2, in: context)
        jenkinsInstance?.allowInvalidSSLCertificate = true
        jenkinsInstance?.username = self.adminUserName
        jenkinsInstance?.password = self.adminUserPassword
        saveContext()
        
        requestHandler.importChildViews(for: view1)
        requestHandler.importChildViews(for: view2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testInvalidSSLCertificate() {
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstancePingResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            return true
        })
        
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            return true
        })
        
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "snowman", JenkinsInstanceURLKey: "https://snowman.normans.local:8443/jenkins/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "jenkinsadmin"] as [String : Any]

        let jinstance1 = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues1 as [AnyHashable: Any], in: self.context)

        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.password = "changeme"

        saveContext()
        
        requestHandler.pingJenkinsInstance(jinstance1)
        requestHandler.importDetails(for: jinstance1)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceDetailRequest() {
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let viewsData = userInfo[JenkinsInstanceViewsKey]
            let jinstance: JenkinsInstance = userInfo[RequestedObjectKey] as! JenkinsInstance
            if jinstance.url == "http://localhost:8080/" && (viewsData as AnyObject).count == 3 {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.JenkinsInstanceDetailRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://localhost:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "JIDetailRequestTestInstance", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: self.adminUserName, JenkinsInstancePrimaryViewKey: primaryView] as [String : Any]
        let jenkinsInstanceValues2 = [JenkinsInstanceNameKey: "JIDetailRequestFailure", JenkinsInstanceURLKey: "http://www.google.com/jenkins", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: self.adminUserName, JenkinsInstancePrimaryViewKey: primaryView] as [String : Any]
        let jinstance1 = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues1 as [AnyHashable: Any], in: self.context)
        let jinstance2 = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues2 as [AnyHashable: Any], in: self.context)
        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.password = self.adminUserPassword
        jinstance2.password = "admin"
        saveContext()
        
        requestHandler.importDetails(for: jinstance1)
        requestHandler.importDetails(for: jinstance2)

        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testJobDetailRequest() {
        _ = expectation(forNotification: NSNotification.Name.JobDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let job: Job = userInfo[RequestedObjectKey] as! Job
            
            if job.url == "http://localhost:8080/job/twominute/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.JobDetailRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/job/Job1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let jobvals = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/twominute/", JobLastSyncKey: Date(), JobJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let jobvals2 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com/jenkins/job/Job1/", JobLastSyncKey: Date(), JobJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let job = Job.createJob(withValues: jobvals, in: context)
        let job2 = Job.createJob(withValues: jobvals2, in: context)
        jenkinsInstance?.allowInvalidSSLCertificate = true
        jenkinsInstance?.username = self.adminUserName
        jenkinsInstance?.password = self.adminUserPassword
        saveContext()
        
        requestHandler.importDetails(for: job)
        requestHandler.importDetails(for: job2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testViewWithSpacesRequest() {
        _ = expectation(forNotification: NSNotification.Name.ViewDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let view: View = userInfo[RequestedObjectKey] as! View
            
            if view.url == "http://localhost:8080/view/Test%20View/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let viewVals = [ViewNameKey: "View1", ViewURLKey: "http://localhost:8080/view/Test%20View/", ViewJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let view1 = View.createView(withValues: viewVals, in: context)
        jenkinsInstance?.username = self.adminUserName
        jenkinsInstance?.password = self.adminUserPassword
        saveContext()
        
        requestHandler.importDetails(for: view1)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testViewDetailRequest() {
        _ = expectation(forNotification: NSNotification.Name.ViewDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let view: View = userInfo[RequestedObjectKey] as! View
            
            if view.url == "http://localhost:8080/view/All/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.ViewDetailRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/view/View1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let viewVals = [ViewNameKey: "View1", ViewURLKey: "http://localhost:8080/view/All/", ViewJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let viewVals2 = [ViewNameKey: "View2", ViewURLKey: "http://www.google.com/jenkins/view/View1/", ViewJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let view1 = View.createView(withValues: viewVals, in: context)
        let view2 = View.createView(withValues: viewVals2, in: context)
        jenkinsInstance?.allowInvalidSSLCertificate = true
        jenkinsInstance?.username = self.adminUserName
        jenkinsInstance?.password = self.adminUserPassword
        saveContext()
        
        requestHandler.importDetails(for: view1)
        requestHandler.importDetails(for: view2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationDetailRequest() {
        _ = expectation(forNotification: NSNotification.Name.ActiveConfigurationDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let ac: ActiveConfiguration = userInfo[RequestedObjectKey] as! ActiveConfiguration
            
            if ac.url == "http://localhost:8080/job/hasconfigs/axis1=1,axis2=a,axis3=red/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.ActiveConfigurationDetailRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/job/Job1/config1=true,config2=test/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let jobvals = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/hasconfigs/", JobLastSyncKey: Date(), JobJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let job = Job.createJob(withValues: jobvals, in: context)
        
        let acVals = [ActiveConfigurationNameKey: "axis1=1", ActiveConfigurationURLKey: "http://localhost:8080/job/hasconfigs/axis1=1,axis2=a,axis3=red/", ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"] as [String : Any]
        let acVals2 = [ActiveConfigurationNameKey: "axis2=a", ActiveConfigurationURLKey: "http://www.google.com/jenkins/job/Job1/config1=true,config2=test/", ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"] as [String : Any]
        let ac = ActiveConfiguration.createActiveConfiguration(withValues: acVals, in: self.context)
        let ac2 = ActiveConfiguration.createActiveConfiguration(withValues: acVals2, in: self.context)
        jenkinsInstance?.allowInvalidSSLCertificate = true
        jenkinsInstance?.username = self.adminUserName
        jenkinsInstance?.password = self.adminUserPassword
        saveContext()
        
        requestHandler.importDetails(for: ac)
        requestHandler.importDetails(for: ac2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
    
    func testBuildDetailRequest() {
        _ = expectation(forNotification: NSNotification.Name.BuildDetailResponseReceived.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo = notification.userInfo!
            let build: Build = userInfo[RequestedObjectKey] as! Build
            
            if build.url == "http://localhost:8080/job/hasconfigs/1/" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        _ = expectation(forNotification: NSNotification.Name.BuildDetailRequestFailed.rawValue, object: self.requestHandler, handler: {
            (notification: Notification!) -> Bool in
            var expectationFulfilled = false
            let userInfo: Dictionary = notification.userInfo!
            let requestError: NSError = userInfo[RequestErrorKey] as! NSError
            let errorUserInfo: Dictionary = requestError.userInfo
            let url: URL = errorUserInfo[NSErrorFailingURLKey] as! URL
            
            if url.absoluteString == "http://www.google.com/jenkins/job/Job1/1/api/json" {
                expectationFulfilled=true
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/TestJob/", JobJenkinsInstanceKey: jenkinsInstance!] as [String : Any]
        let job = Job.createJob(withValues: jobVals1, in: context)
        
        let buildVals = [BuildJobKey: job, BuildURLKey: "http://localhost:8080/job/hasconfigs/1/", BuildNumberKey: 1] as [String : Any]
        let buildVals2 = [BuildJobKey: job, BuildURLKey: "http://www.google.com/jenkins/job/Job1/1/", BuildNumberKey: 1] as [String : Any]
        let build1 = Build.createBuild(withValues: buildVals, in: self.context)
        let build2 = Build.createBuild(withValues: buildVals2, in: self.context)
        jenkinsInstance?.allowInvalidSSLCertificate = true
        jenkinsInstance?.username = self.adminUserName
        jenkinsInstance?.password = self.adminUserPassword
        saveContext()
        
        requestHandler.importDetails(for: build1)
        requestHandler.importDetails(for: build2)
        
        // wait for expectations
        waitForExpectations(timeout: 3, handler: { error in
            
        })
    }
}
