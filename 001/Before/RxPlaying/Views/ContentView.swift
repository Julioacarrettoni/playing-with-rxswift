import FakeService
import SwiftUI

struct ContentView: View {
    @State var globalState: GlobalState? = nil
    
    var body: some View {
        MapView(globalState: self.globalState)
            .edgesIgnoringSafeArea(.all)
            .onAppear(perform: self.refreshData)
    }
    
    private func refreshData() {
        Service.getSystemState() { globalState in
            self.globalState = globalState
            self.refreshData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
