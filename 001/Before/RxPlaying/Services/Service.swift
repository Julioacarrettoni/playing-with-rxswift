import FakeService
import Foundation

struct Service {
    static func getSystemState(completion: @escaping (GlobalState?) -> () ) {
        FakeServices.shared.getSystemState(completion: completion)
    }
}
