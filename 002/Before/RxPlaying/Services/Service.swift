import FakeService
import Foundation
import RxSwift

enum GetSystemStateError: Error {
    case unknown
}

protocol ServiceEnpoints {
    func getSystemState(completion: @escaping (GlobalState?) -> ())
}

struct Environment {
    var provider: ServiceEnpoints
}

extension FakeServices: ServiceEnpoints {}

var Current = RxPlaying.Environment(provider: FakeServices.shared)

struct Service {
    static func overrideNetworkMock() {
        self.overrideNetworkMock_V1()
    }
    
    static func overrideNetworkMock_V1() {
        var failures = [false, true]
        FakeService.Current.failNext = {
            let next = failures.removeFirst()
            failures.append(next)
            return next
        }
    }
    
    static func overrideNetworkMock_V2() {
        var conditions = [
            (fails: true, delay: 3.0),
            (fails: true, delay: 3.0),
            (fails: false, delay: 3.0),
        ]
        
        FakeService.Current.failNext = { conditions.first!.fails }
        FakeService.Current.delay = {
            let current = conditions.removeFirst()
            conditions.append(current)
            return current.delay
        }
    }
    
    static func getSystemState(completion: @escaping (GlobalState?) -> () ) {
        Current.provider.getSystemState(completion: completion)
    }
    
    static var systemSingleV1: Single<GlobalState?> = {
        Single<GlobalState?>.create { single in
            FakeServices.shared.getSystemState { globalState in
                single(.success(globalState))
            }
            
            return Disposables.create()
        }
    }()
    
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
//        .timeout(.seconds(5), scheduler: MainScheduler.instance)
        .do(onSuccess: { _ in
            print("[\(#function)] ✅ Success")
        }, onError: { error in
            print("[\(#function)] ❌ request error: \(error)")
        })
//            .retry(3)
    }()
    
    static var systemSingle_FINAL: Single<GlobalState> = {
        Single<GlobalState>.create { single in
            Current.provider.getSystemState { globalState in
                if let globalState = globalState {
                    single(.success(globalState))
                } else {
                    single(.error(GetSystemStateError.unknown))
                }
            }
            
            return Disposables.create()
        }
        .retry(3)
    }()
}
