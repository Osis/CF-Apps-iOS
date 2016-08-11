import Foundation
import XCTest
import Alamofire

@testable import CF_Apps

class CFRequestTests: XCTestCase {
    let baseApiURL = CFAccountFactory.target
    let baseLoginURL = CFAccountFactory.info().loggingEndpoint
    let baseLoggingURL = CFAccountFactory.info().loggingEndpoint
    
    var account: CFAccount?
    
    override func setUp() {
        super.setUp()
        
        account = CFAccountFactory.account()
        CFSession.account(account!)
        try! CFAccountStore.create(account!)
    }
    
    override func tearDown() {
        super.tearDown()
        
        CFSession.reset()
        try! CFAccountStore.delete(account!)
    }   
    
    func testLoginAuthToken() {
        XCTAssertEqual(CFSession.loginAuthToken, "Y2Y6", "Login auth token is Y2Y6")
    }
    
    func testNilOAuthToken() {
        let oauthHeaderValue = CFRequest.Info(baseApiURL).URLRequest.valueForHTTPHeaderField("Authorization")
        
        XCTAssertNil(CFSession.oauthToken, "OAuth token initializes as nil")
        XCTAssertNil(oauthHeaderValue, "OAuth header should be nil")
    }
    
    func testOAuthToken() {
        CFSession.oauthToken = "testToken"
        let oauthHeaderValue = CFRequest.Info(baseApiURL).URLRequest.valueForHTTPHeaderField("Authorization")
        
        XCTAssertEqual(CFSession.oauthToken!, "testToken", "token should not be nil when set")
        XCTAssertEqual(oauthHeaderValue!, "Bearer testToken", "token should be entered into header when not nil")
    }
    
    func testInfoMember() {
        let path = "/v2/info"
        let request: NSURLRequest = CFRequest.Info(baseApiURL).URLRequest
        
        XCTAssert((CFRequest.Info(baseApiURL) as Any) is CFRequest, "Info is a member")
        XCTAssertEqual(CFRequest.Info(baseApiURL).baseURLString, baseApiURL, "Info returns api URL")
        XCTAssertEqual(CFRequest.Info(baseApiURL).path, path, "Info returns info path")
        XCTAssertEqual(CFRequest.Info(baseApiURL).method, Alamofire.Method.GET, "Info request method is GET")
        
        XCTAssertEqual(CFRequest.Info(baseApiURL).URLRequest.URLString, baseApiURL + path, "Info urlrequest returns the info url")
        XCTAssertNil(request.valueForHTTPHeaderField("Authorization"), "Info doesn't use basic auth")
    }
    
    func testLoginMember() {
        let path = "/oauth/token"
        let request: NSURLRequest = CFRequest.Login(baseLoginURL, "testUser", "testPassword").URLRequest
        
        XCTAssert((CFRequest.Login(baseLoginURL, "", "") as Any) is CFRequest, "Login is a member")
        XCTAssertEqual(CFRequest.Login(baseLoginURL, "", "").baseURLString, baseLoginURL, "Login returns login URL")
        XCTAssertEqual(CFRequest.Login(baseLoginURL, "", "").path, path, "Login returns login path")
        XCTAssertEqual(CFRequest.Login(baseLoginURL, "", "").method, Alamofire.Method.POST, "Login request method is POST")
        
        XCTAssertEqual(request.URLString, baseLoginURL + path, "Login urlrequest returns the login URL")
        
        let authHeader = request.valueForHTTPHeaderField("Authorization")!
        XCTAssertEqual(authHeader, "Basic \(CFSession.loginAuthToken)")
        
        let contentTypeHeader = request.valueForHTTPHeaderField("Content-Type")!
        XCTAssertEqual(contentTypeHeader, "application/x-www-form-urlencoded")
        
        let acceptHeader = request.valueForHTTPHeaderField("Accept")!
        XCTAssertEqual(acceptHeader, "application/json")


        let requestBody = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)
        
        let grantLocation = requestBody!.rangeOfString("grant_type=password").location
        XCTAssertNotEqual(grantLocation, NSNotFound, "Login should have a grant_type param")
        
        let usernameLocation = requestBody!.rangeOfString("username=testUser").location
        XCTAssertNotEqual(usernameLocation, NSNotFound, "Login should have a grant_type param")
        
        let passwordLocation = requestBody!.rangeOfString("password=testPassword").location
        XCTAssertNotEqual(passwordLocation, NSNotFound, "Login should have a grant_type param")
        
        let scopeLocation = requestBody!.rangeOfString("scope=&").location
        XCTAssertNotEqual(scopeLocation, NSNotFound, "Login should have an empty scope param")
    }
    
    func testOrgsMember() {
        let path = "/v2/organizations"
        let request: NSURLRequest = CFRequest.Orgs().URLRequest
        
        XCTAssert((CFRequest.Orgs() as Any) is CFRequest, "Orgs is a member")
        XCTAssertEqual(CFRequest.Orgs().baseURLString, baseApiURL, "Orgs returns api URL")
        XCTAssertEqual(CFRequest.Orgs().path, path, "Orgs returns organizations path")
        XCTAssertEqual(CFRequest.Orgs().method, Alamofire.Method.GET, "Orgs urlrequest method is GET")
        
        XCTAssertEqual(request.URLString, baseApiURL + path, "URLRequest returns the orgs url")
        XCTAssertNil(request.valueForHTTPHeaderField("Authorization"), "Orgs doesn't use basic auth")
    }
    
    func testAppsMember() {
        let path = "/v2/apps"
        let orgGuid = "abc123"
        let currentPage: Int = 1
        let request: NSURLRequest = CFRequest.Apps(orgGuid, currentPage).URLRequest
        
        XCTAssert((CFRequest.Apps(orgGuid, currentPage) as Any) is CFRequest, "Apps is a member")
        XCTAssertEqual(CFRequest.Apps(orgGuid, currentPage).baseURLString, baseApiURL, "Apps returns api URL")
        XCTAssertEqual(CFRequest.Apps(orgGuid, currentPage).path, "/v2/apps", "Apps returns applications path")
        XCTAssertEqual(CFRequest.Apps(orgGuid, currentPage).method, Alamofire.Method.GET, "Apps request method is GET")
        XCTAssertEqual(request.URLString, baseApiURL + path + "?order-direction=desc&page=1&q=organization_guid%3Aabc123&results-per-page=25", "Apps urlrequest returns the apps url with the right params")
        XCTAssertNil(request.valueForHTTPHeaderField("Authorization"), "Apps doesn't use basic auth")
    }
    
    func testEventsMember() {
        let path = "/v2/events"
        let appGuid = "abc123"
        let request: NSURLRequest = CFRequest.Events(appGuid).URLRequest
        
        XCTAssert((CFRequest.Events(appGuid) as Any) is CFRequest, "Events is a member")
        XCTAssertEqual(CFRequest.Events(appGuid).baseURLString, baseApiURL, "Events returns api URL")
        XCTAssertEqual(CFRequest.Events(appGuid).path, path, "Events returns applications path")
        XCTAssertEqual(CFRequest.Events(appGuid).method, Alamofire.Method.GET, "Events request method is GET")
        XCTAssertEqual(request.URLString, baseApiURL + path + "?order-direction=desc&q=actee%3Aabc123&results-per-page=50")
        XCTAssertNil(request.valueForHTTPHeaderField("Authorization"), "Events doesn't use basic auth")
    }
    
    func testURLRequestMethod() {
        let request = CFRequest.Login(baseLoginURL, "", "").URLRequest
        XCTAssertEqual(request.HTTPMethod, "POST", "URLRequest method should be set")
    }
}
