import FakeService
import SwiftUI
import RxSwift

struct ContentView: View {
    @State var globalState: GlobalState? = nil
    let disposeBag = DisposeBag()
    
    var body: some View {
        MapView(globalState: self.globalState)
            .edgesIgnoringSafeArea(.all)
            .onAppear(perform: self.refreshData)
    }
    
    private func refreshData() {
        Service.getSystemState()
            .subscribe(onSuccess: { globalState in
                self.globalState = globalState
                self.refreshData()
            })
            .disposed(by: self.disposeBag)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
