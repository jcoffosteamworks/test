import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    
    var body: some View {
        VStack {
            if self.isActive {
                ContentView()
            } else {
                VStack {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Text("Teamworks AI")
                        .font(.custom("Manrope", size: 24))
                        .padding()
                }
                .onAppear {
                    withAnimation(.easeIn(duration: 2.0)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
