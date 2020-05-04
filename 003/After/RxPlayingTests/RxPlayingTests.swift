@testable import RxPlaying
import FakeService
import XCTest

class RxPlayingTests: XCTestCase {

    override func setUpWithError() throws {
        FakeService.Current.delay =  { 0 }
    }

    func testSystemSingleWhenFailsReturnsError() throws {
        FakeService.Current.failNext = { true }
        
        let expectation = XCTestExpectation(description: "We get an error if the request fails")
        
        let disposeBag = Service.systemSingle
            .subscribe(onSuccess: { _ in
                XCTFail("We shouldn't get a result")
            }, onError: { _ in
                expectation.fulfill()
            })
        
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 0.1), .completed)
        disposeBag.dispose()
    }
    
    func testSystemSingleInternallyRetries3TimesWhenFailsReturnsError() throws {
        let failNextExpectation = XCTestExpectation(description: "FailNext gets executed 3 times")
        failNextExpectation.expectedFulfillmentCount = 3
        failNextExpectation.assertForOverFulfill = true
        
        let onErrorExpectation = XCTestExpectation(description: "We get an error if the request fails")
        onErrorExpectation.expectedFulfillmentCount = 1
        onErrorExpectation.assertForOverFulfill = true
        
        FakeService.Current.failNext = {
            failNextExpectation.fulfill()
            return true
        }
        
        let disposeBag = Service.systemSingle
            .subscribe(onSuccess: { _ in
                XCTFail("We shouldn't get a result")
            }, onError: { _ in
                onErrorExpectation.fulfill()
            })
        
        XCTAssertEqual(XCTWaiter.wait(for: [failNextExpectation, onErrorExpectation], timeout: 0.1), .completed)
        disposeBag.dispose()
    }
    
    func testSystemSingleSucceedsWhenRetrySucceeds() throws {
        let failNextExpectation = XCTestExpectation(description: "FailNext gets executed 2 times")
        failNextExpectation.expectedFulfillmentCount = 2
        failNextExpectation.assertForOverFulfill = true
        
        let successExpectation = XCTestExpectation(description: "We get a success event")
        successExpectation.expectedFulfillmentCount = 1
        successExpectation.assertForOverFulfill = true
        
        var failNext = false
        FakeService.Current.failNext = {
            failNextExpectation.fulfill()
            failNext.toggle()
            return failNext
        }
        
        let disposeBag = Service.systemSingle
            .subscribe(onSuccess: { _ in
                successExpectation.fulfill()
            }, onError: { _ in
                XCTFail("It shouldn't fail.")
            })
        
        XCTAssertEqual(XCTWaiter.wait(for: [failNextExpectation, successExpectation], timeout: 0.1), .completed)
        disposeBag.dispose()
    }
}
