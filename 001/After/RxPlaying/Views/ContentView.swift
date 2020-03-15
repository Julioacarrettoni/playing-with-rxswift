import FakeService
import RxSwift
import SwiftUI

struct ContentView: View {
    @State var globalState: GlobalState? = nil
    let disposeBag = DisposeBag()
    
    var body: some View {
        MapView(globalState: self.globalState)
            .edgesIgnoringSafeArea(.all)
            .onAppear(perform: self.setupAfterAppear)
    }
    
    func setupAfterAppear() {
        Service.shared.globalStateUpdates
            .subscribe(onNext: { globalState in
                self.globalState = globalState
            })
        .disposed(by: self.disposeBag)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
