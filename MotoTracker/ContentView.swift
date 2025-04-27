import SwiftUI
import UIKit
import MapKit

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var rideManager: RideManager
    @EnvironmentObject private var userSettings: UserSettings
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var selectedTab = 0
    @State private var showLocationPermissionAlert = false
    @State private var isLoggedIn = false
    @State private var username: String = ""
    @State private var navigationDestination: String = ""
    @State private var showingDestinationSearchResults = false
    @State private var avoidHighways: Bool = false
    @State private var avoidTolls: Bool = false
    @State private var showNavigationAlert: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Active Ride Tab
            NavigationView {
                if rideManager.isRecording {
                    // Inline ActiveRideView
                    VStack {
                        // Map view
                        ExtendedMapView(region: $locationManager.currentRegion)
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 300)
                        
                        // Current stats
                        HStack {
                            InlineStatBox(title: "Distance", value: formatDistance())
                            InlineStatBox(title: "Duration", value: formatDuration())
                        }
                        .padding()
                        
                        HStack {
                            InlineStatBox(title: "Speed", value: formatSpeed())
                            InlineStatBox(title: "Altitude", value: formatAltitude())
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Stop ride button
                        Button(action: {
                            locationManager.stopTracking()
                            rideManager.stopRide()
                        }) {
                            Text("Stop Ride")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .navigationTitle("Active Ride")
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    VStack {
                        ExtendedMapView(region: $locationManager.currentRegion)
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 300)
                            .overlay(alignment: .top) {
                                if !locationManager.isLocationAuthorized {
                                    Button(action: {
                                        showLocationPermissionAlert = true
                                    }) {
                                        Text("GPS Access Required")
                                            .font(.caption)
                                            .padding(8)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 50)
                                }
                            }
                        
                        if let errorMessage = locationManager.locationErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        VStack(spacing: 20) {
                            Text("Ready to ride?")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Track your motorcycle ride with GPS")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                if locationManager.isLocationAuthorized {
                                    locationManager.startTracking()
                                    rideManager.startRide()
                                } else {
                                    showLocationPermissionAlert = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "record.circle")
                                    Text("Start Tracking")
                                }
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    .navigationTitle("MotoTracker")
                    .alert("Location Permission Required", isPresented: $showLocationPermissionAlert) {
                        Button("Settings", role: .none) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        Button("Request Permission", role: .none) {
                            locationManager.requestLocationPermissions()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("MotoTracker needs GPS access to track your rides. Please grant location permissions in Settings.")
                    }
                }
            }
            .tabItem {
                Label("Record", systemImage: "record.circle")
            }
            .tag(0)
            
            // Navigation Tab
            NavigationView {
                // Enhanced navigation view implementation
                ZStack(alignment: .top) {
                    // Map view
                    ExtendedMapView(region: $locationManager.currentRegion)
                        .ignoresSafeArea()
                    
                    // Navigation controls
                    VStack(spacing: 0) {
                        // Search bar
                        VStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search for destination", text: $navigationDestination, onCommit: {
                                    if !navigationDestination.isEmpty {
                                        searchForDestination()
                                    }
                                })
                                .foregroundColor(.primary)
                                
                                if !navigationDestination.isEmpty {
                                    Button(action: {
                                        navigationDestination = ""
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
                            .padding(.top, 50)
                            .shadow(color: .black.opacity(0.2), radius: 2)
                            
                            // Show real search results from the NavigationManager
                            if !navigationManager.searchResults.isEmpty {
                                List {
                                    ForEach(navigationManager.searchResults, id: \.self) { item in
                                        Button(action: {
                                            // Select this destination
                                            selectDestination(item)
                                        }) {
                                            VStack(alignment: .leading) {
                                                Text(item.name ?? "Unknown Location")
                                                    .font(.headline)
                                                
                                                if let placemark = item.placemark {
                                                    Text(formatAddress(placemark))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            } else if navigationManager.isSearching {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            } else if navigationManager.searchError != nil {
                                Text(navigationManager.searchError ?? "Error")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                        .background(Color(.systemBackground).opacity(0.8))
                        
                        Spacer()
                        
                        // Bottom panel
                        VStack(spacing: 10) {
                            // Show route information if we have a route
                            if let route = navigationManager.currentRoute, let destination = navigationManager.destination {
                                VStack(spacing: 8) {
                                    Text(destination.name ?? "Destination")
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 20) {
                                        VStack {
                                            Text(navigationManager.formattedRemainingDistance(with: userSettings))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                            
                                            Text("Distance")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Divider()
                                            .frame(height: 30)
                                        
                                        VStack {
                                            Text(navigationManager.formattedRemainingTime())
                                                .font(.title3)
                                                .fontWeight(.bold)
                                            
                                            Text("Time")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding(.horizontal)
                            } else {
                                Text("Route Options")
                                    .font(.headline)
                            }
                            
                            // Route options
                            HStack {
                                Toggle("Avoid Highways", isOn: $avoidHighways)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Toggle("Avoid Tolls", isOn: $avoidTolls)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Navigation button - change label based on whether we have a route
                            Button(action: {
                                if navigationManager.currentRoute == nil && navigationDestination.isEmpty {
                                    showNavigationAlert = true
                                } else if navigationManager.currentRoute != nil {
                                    startNavigation()
                                } else if !navigationDestination.isEmpty {
                                    // We have a destination but no route yet, search for it
                                    searchForDestination()
                                }
                            }) {
                                Text(navigationManager.currentRoute != nil ? "Start Navigation" : "Search")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        .padding(.bottom)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, y: -2)
                        .padding()
                    }
                }
                .navigationTitle("Navigation")
                .navigationBarTitleDisplayMode(.inline)
                .alert(isPresented: $showNavigationAlert) {
                    Alert(
                        title: Text("Destination Required"),
                        message: Text("Please enter a destination before starting navigation."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .tabItem {
                Label("Navigate", systemImage: "location.fill")
            }
            .tag(5)
            
            // History Tab
            NavigationView {
                List {
                    if rideManager.rides.isEmpty {
                        Text("No rides recorded yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(rideManager.rides) { ride in
                            InlineRideRow(ride: ride, userSettings: userSettings)
                        }
                        .onDelete { indexSet in
                            rideManager.deleteRide(at: indexSet)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Ride History")
            }
            .tabItem {
                Label("History", systemImage: "list.bullet")
            }
            .tag(1)
            
            // Stats Tab
            NavigationView {
                VStack(spacing: 20) {
                    Text("Ride Statistics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    InlineStatCard(
                        title: "Total Distance",
                        value: rideManager.formattedTotalDistance(with: userSettings),
                        icon: "map"
                    )
                    
                    InlineStatCard(
                        title: "Total Duration",
                        value: rideManager.formattedTotalDuration,
                        icon: "clock"
                    )
                    
                    InlineStatCard(
                        title: "Average Speed",
                        value: rideManager.formattedAverageSpeed(with: userSettings),
                        icon: "speedometer"
                    )
                    
                    if let longestRide = rideManager.longestRide {
                        SectionTitle(title: "Longest Ride")
                        
                        RideInfoCard(
                            title: longestRide.name,
                            distance: userSettings.formatDistance(longestRide.distance / 1000),
                            date: formattedSimpleDate(longestRide.startTime)
                        )
                    }
                    
                    if let fastestRide = rideManager.fastestRide {
                        SectionTitle(title: "Fastest Ride")
                        
                        RideInfoCard(
                            title: fastestRide.name,
                            distance: userSettings.formatDistance(fastestRide.distance / 1000),
                            date: formattedSimpleDate(fastestRide.startTime)
                        )
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Statistics")
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(2)
            
            // Profile/Account Tab
            NavigationView {
                ProfileView(isLoggedIn: $isLoggedIn, username: $username)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(3)
            
            // Settings Tab
            NavigationView {
                Form {
                    Section(header: Text("Measurement System")) {
                        Picker("Units", selection: $userSettings.unitSystem) {
                            Text("Metric (km, km/h)").tag(UserSettings.UnitSystem.metric)
                            Text("Imperial (mi, mph)").tag(UserSettings.UnitSystem.imperial)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Units:")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            HStack {
                                Text("Distance:")
                                Spacer()
                                Text(userSettings.unitSystem.distanceUnit)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Speed:")
                                Spacer()
                                Text(userSettings.unitSystem.speedUnit)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Altitude:")
                                Spacer()
                                Text(userSettings.unitSystem.altitudeUnit)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section(header: Text("App Settings")) {
                        HStack {
                            Label("Notifications", systemImage: "bell")
                            Spacer()
                            Text("Coming soon")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Privacy", systemImage: "hand.raised")
                            Spacer()
                            Text("Coming soon")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("About")) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // Check for location permissions when app starts
            locationManager.checkLocationAuthorization()
        }
    }
    
    // Helper functions for the inline ActiveRideView
    private func formatDistance() -> String {
        guard let points = rideManager.activeRide?.locationPoints, points.count > 1 else { 
            return "0.0 \(userSettings.unitSystem.distanceUnit)" 
        }
        
        let totalDistance = calculateDistanceForPoints(points)
        let distanceInKilometers = totalDistance / 1000
        return userSettings.formatDistance(distanceInKilometers)
    }
    
    private func calculateDistanceForPoints(_ points: [LocationPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        
        var totalDistance = 0.0
        for i in 0..<points.count-1 {
            let start = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
            let end = CLLocation(latitude: points[i+1].latitude, longitude: points[i+1].longitude)
            totalDistance += end.distance(from: start)
        }
        
        return totalDistance
    }
    
    private func formatDuration() -> String {
        guard let startTime = rideManager.activeRide?.startTime else { return "00:00" }
        
        let duration = Date().timeIntervalSince(startTime)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: duration) ?? "00:00:00"
    }
    
    private func formatSpeed() -> String {
        guard let location = locationManager.lastLocation else {
            return "0 \(userSettings.unitSystem.speedUnit)"
        }
        
        let speedInKmh = location.speed > 0 ? location.speed * 3.6 : 0
        return userSettings.formatSpeed(speedInKmh)
    }
    
    private func formatAltitude() -> String {
        guard let location = locationManager.lastLocation else {
            return "0 \(userSettings.unitSystem.altitudeUnit)"
        }
        
        return userSettings.formatAltitude(location.altitude)
    }
    
    private func formattedSimpleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Navigation Methods
    
    private func searchForDestination() {
        // Hide any previously shown mock results
        showingDestinationSearchResults = false
        
        // Directly invoke the method on the NavigationManager instance
        let query = navigationDestination
        let location = locationManager.lastLocation
        let region = locationManager.currentRegion
        
        // Create a search request manually since we can't directly call methods
        DispatchQueue.main.async {
            self.navigationManager.isSearching = true
            self.navigationManager.searchError = nil
            self.navigationManager.searchResults = []
            
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = query
            
            if let region = region {
                searchRequest.region = region
            } else if let location = location {
                searchRequest.region = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 5000,
                    longitudinalMeters: 5000
                )
            }
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                DispatchQueue.main.async {
                    self.navigationManager.isSearching = false
                    
                    if let error = error {
                        self.navigationManager.searchError = error.localizedDescription
                        return
                    }
                    
                    guard let response = response else {
                        self.navigationManager.searchError = "No results found"
                        return
                    }
                    
                    self.navigationManager.searchResults = response.mapItems
                }
            }
        }
    }
    
    private func selectDestination(_ mapItem: MKMapItem) {
        // We've selected a destination from search results
        navigationDestination = mapItem.name ?? "Selected Location"
        
        // Create a route calculation request
        DispatchQueue.main.async {
            self.navigationManager.destination = mapItem
            self.navigationManager.isCalculatingRoute = true
            self.navigationManager.navigationError = nil
            self.navigationManager.currentRoute = nil
            self.navigationManager.allRoutes = []
            
            let request = MKDirections.Request()
            
            // Set source location
            if let location = self.locationManager.lastLocation {
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            } else {
                self.navigationManager.isCalculatingRoute = false
                self.navigationManager.navigationError = "Current location is not available"
                return
            }
            
            request.destination = mapItem
            request.transportType = .automobile
            request.requestsAlternateRoutes = true
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                DispatchQueue.main.async {
                    self.navigationManager.isCalculatingRoute = false
                    
                    if let error = error {
                        self.navigationManager.navigationError = error.localizedDescription
                        return
                    }
                    
                    guard let response = response, !response.routes.isEmpty else {
                        self.navigationManager.navigationError = "No routes found"
                        return
                    }
                    
                    self.navigationManager.allRoutes = response.routes
                    self.navigationManager.currentRoute = response.routes[0] // Select the first route
                    
                    // Prepare the route for navigation
                    guard let route = self.navigationManager.currentRoute else { return }
                    
                    // Set initial values
                    self.navigationManager.remainingDistance = route.distance
                    self.navigationManager.remainingTime = route.expectedTravelTime
                    
                    // Setup initial step
                    if let firstStep = route.steps.first {
                        self.navigationManager.currentStep = firstStep
                        self.navigationManager.nextStep = route.steps.count > 1 ? route.steps[1] : nil
                        self.navigationManager.currentStepRemainingDistance = firstStep.distance
                    }
                }
            }
        }
    }
    
    private func startNavigation() {
        if navigationManager.currentRoute == nil {
            showNavigationAlert = true
            return
        }
        
        DispatchQueue.main.async {
            self.navigationManager.routeIsActive = true
            self.navigationManager.currentStepIndex = 0
            
            // Initialize with the first step
            if let firstStep = self.navigationManager.currentRoute?.steps.first {
                self.navigationManager.currentStep = firstStep
                self.navigationManager.nextStep = self.navigationManager.currentRoute?.steps.count ?? 0 > 1 ? self.navigationManager.currentRoute?.steps[1] : nil
            }
            
            // Announce that we're starting navigation
            print("Starting navigation to \(self.navigationDestination)")
        }
    }
    
    // Helper to format address from placemark
    private func formatAddress(_ placemark: CLPlacemark) -> String {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
}

// Helper views for Statistics
struct InlineStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .frame(width: 50)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .bold()
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SectionTitle: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
        }
        .padding(.top)
    }
}

struct RideInfoCard: View {
    let title: String
    let distance: String
    let date: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            HStack {
                Label(distance, systemImage: "map")
                Spacer()
                Label(date, systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// RideRow for displaying each ride in the list
struct InlineRideRow: View {
    let ride: Ride
    let userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ride.name)
                .font(.headline)
            
            HStack {
                Label {
                    Text(formattedDate(ride.startTime))
                } icon: {
                    Image(systemName: "calendar")
                }
                
                Spacer()
                
                Label {
                    Text(ride.formattedDuration)
                } icon: {
                    Image(systemName: "clock")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            HStack {
                Label {
                    Text(userSettings.formatDistance(ride.distance / 1000))
                } icon: {
                    Image(systemName: "map")
                }
                
                Spacer()
                
                Label {
                    Text(userSettings.formatSpeed(ride.averageSpeed * 3.6))
                } icon: {
                    Image(systemName: "speedometer")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InlineStatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack {
            if isLoggedIn {
                // Logged-in view
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text(username)
                        .font(.title)
                        .bold()
                    
                    Text(email)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ride Statistics")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "map")
                            Text("Total Rides: Coming soon")
                        }
                        
                        HStack {
                            Image(systemName: "speedometer")
                            Text("Top Speed: Coming soon")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .alert(isPresented: $showingLogoutAlert) {
                    Alert(
                        title: Text("Sign Out"),
                        message: Text("Are you sure you want to sign out?"),
                        primaryButton: .destructive(Text("Sign Out")) {
                            isLoggedIn = false
                            username = ""
                            email = ""
                        },
                        secondaryButton: .cancel()
                    )
                }
            } else {
                // Login view
                VStack(spacing: 20) {
                    Text("Sign In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button(action: {
                        // Simple sign in - just set as logged in
                        if !email.isEmpty {
                            isLoggedIn = true
                            username = email.components(separatedBy: "@").first ?? "User"
                        }
                    }) {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Simple sign up - just set as logged in
                        if !email.isEmpty {
                            isLoggedIn = true
                            username = email.components(separatedBy: "@").first ?? "User"
                        }
                    }) {
                        Text("Sign Up")
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Account")
    }
} 