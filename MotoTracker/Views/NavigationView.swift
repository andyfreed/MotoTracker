import SwiftUI
import MapKit

struct NavigationView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var showRouteOptions = false
    @State private var showNavigationSheet = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main Map View
            NavigationMapView(
                region: $locationManager.currentRegion,
                route: navigationManager.currentRoute,
                destination: navigationManager.destination?.placemark.coordinate
            )
            .ignoresSafeArea()
            
            // Top Search Bar
            VStack(spacing: 0) {
                searchBar
                
                if showSearchResults {
                    searchResultsList
                }
                
                if showRouteOptions && navigationManager.allRoutes.count > 1 {
                    routeOptionsList
                }
            }
            
            // Bottom Navigation Panel
            if navigationManager.destination != nil && !navigationManager.routeIsActive {
                routeInfoPanel
            }
            
            // Active Navigation Panel
            if navigationManager.routeIsActive {
                activeNavigationPanel
            }
        }
        .sheet(isPresented: $showNavigationSheet) {
            NavigationDetailsSheet()
        }
    }
    
    // MARK: - UI Components
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for a destination", text: $searchText, onCommit: {
                    searchForDestination()
                })
                .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.2), radius: 2)
            
            if !searchText.isEmpty {
                Button("Search") {
                    searchForDestination()
                }
                .padding(.trailing)
            }
        }
        .padding(.top, 60)
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    private var searchResultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(navigationManager.searchResults, id: \.self) { item in
                    Button(action: {
                        selectDestination(item)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown Location")
                                    .font(.headline)
                                
                                if let address = formatAddress(for: item) {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                }
                
                if navigationManager.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                }
                
                if let error = navigationManager.searchError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .background(Color(.systemBackground))
        }
        .frame(maxHeight: 300)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.2), radius: 5)
        .transition(.move(edge: .top))
    }
    
    private var routeOptionsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<navigationManager.allRoutes.count, id: \.self) { index in
                    let route = navigationManager.allRoutes[index]
                    RouteOptionCard(
                        route: route,
                        userSettings: userSettings,
                        isSelected: navigationManager.currentRoute == route,
                        onSelect: {
                            navigationManager.selectRoute(at: index)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    private var routeInfoPanel: some View {
        VStack(spacing: 0) {
            if let route = navigationManager.currentRoute, let destination = navigationManager.destination {
                VStack(spacing: 10) {
                    Text(destination.name ?? "Destination")
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text(navigationManager.formattedRemainingDistance(with: userSettings))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Distance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text(navigationManager.formattedRemainingTime())
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            navigationManager.startNavigation()
                        }) {
                            HStack {
                                Image(systemName: "location.north.fill")
                                Text("Start")
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showNavigationSheet = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Details")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                        
                        if navigationManager.allRoutes.count > 1 {
                            Button(action: {
                                withAnimation {
                                    showRouteOptions.toggle()
                                }
                            }) {
                                Image(systemName: "arrow.triangle.swap")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 5, y: -2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .padding(.horizontal)
        .transition(.move(edge: .bottom))
    }
    
    private var activeNavigationPanel: some View {
        VStack {
            Spacer()
            
            // Active Navigation Info
            VStack(spacing: 8) {
                if let step = navigationManager.currentStep {
                    HStack {
                        NavigationStepIndicator(step: step)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text(step.instructions)
                                .font(.headline)
                                .lineLimit(2)
                            
                            let distance = navigationManager.currentStepRemainingDistance
                            let formattedDistance = userSettings.formatDistance(distance / 1000)
                            Text("In \(formattedDistance)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showNavigationSheet = true
                        }) {
                            Image(systemName: "list.bullet")
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Show next step preview
                    if let nextStep = navigationManager.nextStep {
                        Divider()
                        
                        HStack {
                            NavigationStepIndicator(step: nextStep)
                                .frame(width: 40, height: 40)
                            
                            Text(nextStep.instructions)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                // Remaining trip info
                HStack {
                    VStack {
                        Text(navigationManager.formattedRemainingDistance(with: userSettings))
                            .font(.headline)
                        
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Stop Navigation Button
                    Button(action: {
                        navigationManager.stopNavigation()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Stop")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(navigationManager.formattedRemainingTime())
                            .font(.headline)
                        
                        Text("ETA")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, y: -2)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func searchForDestination() {
        guard !searchText.isEmpty else { return }
        
        withAnimation {
            showSearchResults = true
            showRouteOptions = false
        }
        
        navigationManager.searchPlaces(
            query: searchText,
            near: locationManager.lastLocation,
            region: locationManager.currentRegion
        )
    }
    
    private func selectDestination(_ mapItem: MKMapItem) {
        withAnimation {
            showSearchResults = false
            showRouteOptions = true
        }
        
        navigationManager.calculateRoute(
            to: mapItem,
            from: locationManager.lastLocation
        )
    }
    
    private func formatAddress(for mapItem: MKMapItem) -> String? {
        guard let placemark = mapItem.placemark else { return nil }
        
        var addressString = ""
        
        if let thoroughfare = placemark.thoroughfare {
            addressString = thoroughfare
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            addressString = subThoroughfare + " " + addressString
        }
        
        if let locality = placemark.locality {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += locality
        }
        
        if let administrativeArea = placemark.administrativeArea {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += administrativeArea
        }
        
        return addressString.isEmpty ? nil : addressString
    }
}

// MARK: - Helper Views

/// Displays the map with route overlay
struct NavigationMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var route: MKRoute?
    var destination: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = region
        
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        
        // Remove all annotations except user location
        let annotationsToRemove = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(annotationsToRemove)
        
        // Add route overlay if available
        if let route = route {
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            // Make sure the route is visible
            mapView.setVisibleMapRect(
                route.polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 80, left: 20, bottom: 100, right: 20),
                animated: true
            )
        }
        
        // Add destination annotation if available
        if let destination = destination {
            let annotation = MKPointAnnotation()
            annotation.coordinate = destination
            annotation.title = "Destination"
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NavigationMapView
        
        init(_ parent: NavigationMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "DestinationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                (annotationView as? MKMarkerAnnotationView)?.markerTintColor = .red
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

/// Card for displaying a route option
struct RouteOptionCard: View {
    let route: MKRoute
    let userSettings: UserSettings
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDistance(route.distance, with: userSettings))
                    .font(.headline)
                
                Spacer()
                
                Text(formatTime(route.expectedTravelTime))
                    .font(.headline)
            }
            
            HStack {
                if let transport = route.transportType.description {
                    Text(transport)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let firstStep = route.steps.first, let firstInstruction = firstStep.instructions, !firstInstruction.isEmpty {
                    Text(firstInstruction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .frame(width: 200)
        .onTapGesture {
            onSelect()
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance, with settings: UserSettings) -> String {
        let distanceInKm = distance / 1000
        return settings.formatDistance(distanceInKm)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: time) ?? "Unknown"
    }
}

/// Indicator for navigation step direction
struct NavigationStepIndicator: View {
    let step: MKRoute.Step
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
            
            Image(systemName: iconForStep())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
                .foregroundColor(.blue)
        }
    }
    
    private func iconForStep() -> String {
        let instructions = step.instructions.lowercased()
        
        if instructions.contains("u-turn") {
            return "arrow.uturn.left"
        } else if instructions.contains("left") {
            return "arrow.turn.up.left"
        } else if instructions.contains("right") {
            return "arrow.turn.up.right"
        } else if instructions.contains("continue") || instructions.contains("head") || instructions.contains("straight") {
            return "arrow.up"
        } else if instructions.contains("arrive") || instructions.contains("destination") {
            return "mappin.circle"
        } else {
            return "arrow.up"
        }
    }
}

/// Sheet showing detailed navigation instructions
struct NavigationDetailsSheet: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if let route = navigationManager.currentRoute {
                    Section(header: Text("Trip Overview")) {
                        HStack {
                            Label("Distance", systemImage: "map")
                            Spacer()
                            Text(navigationManager.formattedRemainingDistance(with: userSettings))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Time", systemImage: "clock")
                            Spacer()
                            Text(navigationManager.formattedRemainingTime())
                                .foregroundColor(.secondary)
                        }
                        
                        if let arrivalTime = Calendar.current.date(byAdding: .second, value: Int(route.expectedTravelTime), to: Date()) {
                            HStack {
                                Label("Arrival", systemImage: "calendar")
                                Spacer()
                                Text(formatTime(arrivalTime))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Turn-by-Turn Directions")) {
                        ForEach(0..<route.steps.count, id: \.self) { index in
                            let step = route.steps[index]
                            let isCurrentStep = index == navigationManager.currentStepIndex && navigationManager.routeIsActive
                            
                            HStack {
                                NavigationStepIndicator(step: step)
                                    .frame(width: 36, height: 36)
                                
                                VStack(alignment: .leading) {
                                    Text(step.instructions)
                                        .foregroundColor(isCurrentStep ? .blue : .primary)
                                        .fontWeight(isCurrentStep ? .bold : .regular)
                                    
                                    HStack {
                                        let distance = step.distance
                                        let formattedDistance = userSettings.formatDistance(distance / 1000)
                                        Text(formattedDistance)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Route Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Extensions

extension MKDirectionsTransportType {
    var description: String? {
        switch self {
        case .automobile:
            return "Driving"
        case .walking:
            return "Walking"
        case .transit:
            return "Transit"
        case .any:
            return "Travel"
        default:
            return nil
        }
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
            .environmentObject(LocationManager())
            .environmentObject(NavigationManager())
            .environmentObject(UserSettings())
    }
} 