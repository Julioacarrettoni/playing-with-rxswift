import FakeService
import SwiftUI
import RxSwift

struct ContentView: View {
    @State var globalState: GlobalState? = nil
    @State var isAutoPolling: Bool = false
    
    let disposeBag = DisposeBag()
    
    var body: some View {
        VStack {
            MapView(globalState: self.globalState)
            VStack {
                if !self.isAutoPolling {
                    Button(action: {
                        #warning("Missing implementation")
                    }) { Text("Refresh") }
                }
                Toggle(isOn: self.$isAutoPolling, label: { Text("Auto Polling") })
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .edgesIgnoringSafeArea(.horizontal)
        .edgesIgnoringSafeArea(.top)
    }
    
    private func refreshData() {
        Service.systemSingle
            .do(onError: { error in
                print("[\(#function)] ❌ request error: \(error)")
            })
            .subscribe(onSuccess: { globalState in
                self.globalState = globalState
                self.refreshData()
            }, onError: { error in
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
