import Foundation
import XCTest
import SwiftWebSocket
import Mockingjay

@testable import CF_Apps

class CFLogsTests: XCTestCase {
    let testAppGuid = "50e5b89b-83a7-46c2-ba8b-7be656029238"
    
    class FakeLogger: NSObject, CFLogger {
        var appGuid: String
        var assertString: String?
        var expectation: XCTestExpectation
        
        init(appGuid: String, expectation: XCTestExpectation) {
            self.appGuid = appGuid
            self.expectation = expectation
            super.init()
        }
        
        convenience init(appGuid: String, assertString: String, expectation: XCTestExpectation) {
            self.init(appGuid: appGuid, expectation: expectation)
            self.assertString = assertString
        }
        
        func connect() {
            expectation.fulfill()
        }
        
        func reconnect() {
            expectation.fulfill()
        }
        
        func logsMessage(text: NSMutableAttributedString) {
            XCTAssertEqual(text.string, assertString!)
            expectation.fulfill()
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        CFSession.reset()
        removeAllStubs()
    }
    
    func testInit() {
        let logs = CFLogs(appGuid: testAppGuid)
        
        XCTAssertEqual(logs.appGuid, testAppGuid)
    }
    
    func testTail() {
        // TODO: Injest and test
    }
    
    func testCreateSocket() {
        let logs = CFLogs(appGuid: testAppGuid)
        
        KeychainTests.setCredentials()
        CFSession.oauthToken = "testToken"
        
        do {
            let socket = try logs.createSocket()
            XCTAssertEqual(socket.binaryType, WebSocketBinaryType.NSData)
        } catch {
            XCTFail()
        }
    }
    
    func testCreateSocketRequest() {
        let logs = CFLogs(appGuid: testAppGuid)
        
        KeychainTests.setCredentials()
        CFSession.oauthToken = "testToken"
        
        do {
            let request = try logs.createSocketRequest()
            XCTAssertEqual(request.URLString, "wss://loggregator.capi.test/tail/?app=\(testAppGuid)")
            XCTAssertEqual(request.valueForHTTPHeaderField("Authorization"), "bearer testToken")
        } catch {
            XCTFail()
        }
    }
    
    func testLogsConnected() {
        let expectation = expectationWithDescription("Logs Connected")
        let logs = CFLogs(appGuid: testAppGuid)
        
        logs.delegate = FakeLogger(appGuid: testAppGuid, assertString: "[]: Connected\n\n", expectation: expectation)
        logs.opened()
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testLogsError() {
        let expectation = expectationWithDescription("Logs Error")
        let logs = CFLogs(appGuid: testAppGuid)
        
        logs.delegate = FakeLogger(appGuid: testAppGuid, assertString: "[]: Network(test error)\n\n", expectation: expectation)
        logs.error(WebSocketError.Network("test error"))
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testLogsAuthRecovery() {
        stub(everything, builder: json([], status: 200))
        class FakeCFLogs: CFLogs {
            let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
                super.init(appGuid: "")
            }
            
            override func tail() {
                expectation.fulfill()
            }
        }
        
        KeychainTests.setCredentials()
        let expectation = expectationWithDescription("Logs Error")
        let logs = FakeCFLogs(expectation: expectation)
        
        logs.error(WebSocketError.InvalidResponse("HTTP/1.1 401 Unauthorized"))
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testLogsAuthFail() {
        stub(everything, builder: json([], status: 500))
        class FakeCFLogs: CFLogs {
            let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
                super.init(appGuid: "")
            }
            
            override func handleAuthFail() {
                expectation.fulfill()
            }
        }
        
        KeychainTests.setCredentials()
        CFSession.oauthToken = ""
        XCTAssertFalse(CFSession.isEmpty())
        
        let expectation = expectationWithDescription("Logs Error")
        let logs = FakeCFLogs(expectation: expectation)
        logs.error(WebSocketError.InvalidResponse("HTTP/1.1 401 Unauthorized"))
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}
