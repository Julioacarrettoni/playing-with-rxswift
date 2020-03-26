import FakeService
import Foundation
import RxSwift

final class Service {
    static var shared = Service()
    
    let globalStateUpdates = PublishSubject<GlobalState?>().asObserver()
    let disposeBag = DisposeBag()
    
    private init() {
        let ticksPerSecond = 30
        let referenceDate = Date.init(timeIntervalSinceNow: 0)
        FakeService.Current.tick = { -referenceDate.timeIntervalSinceNow * Double(ticksPerSecond)}
        FakeService.Current.delay = { 0 }
        
        Observable<Int>.interval(.milliseconds(1000/ticksPerSecond), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                self?.refreshGlobalState()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func refreshGlobalState() {
        FakeServices.shared.getSystemState { globalState in
            self.globalStateUpdates.onNext(globalState)
        }
    }
}
