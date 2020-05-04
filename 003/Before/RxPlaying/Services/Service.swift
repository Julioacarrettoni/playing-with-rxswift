import FakeService
import Foundation
import RxSwift

enum GetSystemStateError: Error {
    case unknown
}

enum Service {
    static func overrideNetworkMock() {
        var failures = [false, true]
        FakeService.Current.failNext = {
            let next = failures.removeFirst()
            failures.append(next)
            return next
        }
    }
    
    static var systemSingle: Single<GlobalState> = {
        Single<GlobalState>.create { single in
            FakeServices.shared.getSystemState { globalState in
                if let globalState = globalState {
                    single(.success(globalState))
                } else {
                    single(.error(GetSystemStateError.unknown))
                }
            }
            
            return Disposables.create()
        }
        .do(onSuccess: { _ in
            print("[\(#function)] ✅ Success")
        }, onError: { error in
            print("[\(#function)] ❌ request error: \(error)")
        })
    }()
}
