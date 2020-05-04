import FakeService
import SwiftUI
import RxSwift

struct ContentView: View {
    @State private var globalState: GlobalState? = nil
    @State private var showingAlert: Bool = false
    @State private var isAutoPolling: Bool = false {
        didSet {
            if self.isAutoPolling {
                self.autoPoll()
            }
        }
    }
    
    let disposeBag = DisposeBag()
    
    var body: some View {
        VStack {
            MapView(globalState: self.globalState)
            VStack {
                if !self.isAutoPolling {
                    Button(action: {
                        self.refresh()
                    }) { Text("Refresh") }
                }
                Toggle(isOn: Binding(get: {
                    self.isAutoPolling
                }, set: {
                    self.isAutoPolling = $0
                }), label: { Text("Auto Polling") })
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text("There was an error, please try again later."), dismissButton: .default(Text("OK")))
        }
        .edgesIgnoringSafeArea(.horizontal)
        .edgesIgnoringSafeArea(.top)
    }
    
    private func fetchGlobalState(from function: String = #function) -> Single<GlobalState> {
        return Service.systemSingle
            .do(onError: { error in
                print("[\(function)] ❌ request error: \(error)")
            })
    }
    
    private func refresh() {
        self.fetchGlobalState()
            .subscribe(onSuccess: { globalState in
                self.globalState = globalState
            }, onError: { error in
                self.showErrorAlert()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func autoPoll() {
        self.fetchGlobalState()
            .subscribe(onSuccess: { globalState in
                self.globalState = globalState
                if self.isAutoPolling {
                    self.autoPoll()
                }
            }, onError: { error in
                if self.isAutoPolling {
                    self.autoPoll()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func showErrorAlert() {
        self.showingAlert = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
