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
}
