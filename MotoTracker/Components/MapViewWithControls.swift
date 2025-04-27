import SwiftUI
import MapKit

struct MapViewWithControls: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var isRecording: Bool
    
    var body: some View {
        ZStack {
            // Map view
            Map(coordinateRegion: $locationManager.currentRegion,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow))
            .edgesIgnoringSafeArea(.all)
            
            // Polyline overlay for route (to be implemented)
            
            // Controls overlay
            VStack {
                Spacer()
                
                HStack {
                    // Center on user location button
                    Button(action: {
                        locationManager.centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // Record button
                    Button(action: {
                        if isRecording {
                            locationManager.stopTracking()
                        } else {
                            locationManager.startTracking()
                        }
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(isRecording ? .red : .green)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct MapViewWithControls_Previews: PreviewProvider {
    static var previews: some View {
        MapViewWithControls(
            locationManager: LocationManager(),
            isRecording: .constant(false)
        )
    }
} 