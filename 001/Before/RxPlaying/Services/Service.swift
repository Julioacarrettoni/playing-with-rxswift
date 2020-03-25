import FakeService
import Foundation
import RxSwift

struct Service {
    static func getSystemState(completion: @escaping (GlobalState?) -> () ) {
        FakeServices.shared.getSystemState(completion: completion)
    }
    
    static func getSystemState() -> Single<GlobalState?> {
        Single<GlobalState?>.create { single in
            FakeServices.shared.getSystemState { globalState in
                single(.success(globalState))
            }
            
            return Disposables.create()
        }
    }
}
