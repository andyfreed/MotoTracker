import Foundation
import MapKit
import Combine
import SwiftUI
import AVFoundation

class NavigationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var destination: MKMapItem?
    @Published var currentRoute: MKRoute?
    @Published var allRoutes: [MKRoute] = []
    @Published var routeIsActive = false
    @Published var isCalculatingRoute = false
    @Published var navigationError: String?
    @Published var remainingDistance: CLLocationDistance = 0
    @Published var remainingTime: TimeInterval = 0
    @Published var currentStep: MKRoute.Step?
    @Published var nextStep: MKRoute.Step?
    @Published var currentStepRemainingDistance: CLLocationDistance = 0
    @Published var currentStepIndex: Int = 0
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var searchError: String?
    
    // MARK: - Private Properties
    private var locationManager: LocationManager?
    private var cancellables = Set<AnyCancellable>()
    private var monitoredRegions: [String: MKCoordinateRegion] = [:]
    private var stepProgress: Progress?
    private var routeProgress: Progress?
    private var lastLocation: CLLocation?
    private var navigatingToWaypoint: Bool = false
    
    // MARK: - Initialization
    init(locationManager: LocationManager? = nil) {
        super.init()
        self.locationManager = locationManager
        
        // Subscribe to location updates
        locationManager?.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateNavigation(with: location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Search for places matching the query
    func searchPlaces(query: String, near location: CLLocation? = nil, region: MKCoordinateRegion? = nil) {
        isSearching = true
        searchError = nil
        searchResults = []
        
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
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    self?.searchError = error.localizedDescription
                    return
                }
                
                guard let response = response else {
                    self?.searchError = "No results found"
                    return
                }
                
                self?.searchResults = response.mapItems
            }
        }
    }
    
    /// Calculate route to the destination
    func calculateRoute(to destination: MKMapItem, from source: CLLocation? = nil) {
        self.destination = destination
        self.isCalculatingRoute = true
        self.navigationError = nil
        self.currentRoute = nil
        self.allRoutes = []
        
        let request = MKDirections.Request()
        
        // Set source location
        if let source = source {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
        } else if let location = locationManager?.lastLocation {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        } else {
            self.isCalculatingRoute = false
            self.navigationError = "Current location is not available"
            return
        }
        
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isCalculatingRoute = false
                
                if let error = error {
                    self?.navigationError = error.localizedDescription
                    return
                }
                
                guard let response = response, !response.routes.isEmpty else {
                    self?.navigationError = "No routes found"
                    return
                }
                
                self?.allRoutes = response.routes
                self?.currentRoute = response.routes[0] // Select the first route
                self?.prepareRouteForNavigation()
            }
        }
    }
    
    /// Start active navigation
    func startNavigation() {
        guard currentRoute != nil else {
            navigationError = "No route available"
            return
        }
        
        routeIsActive = true
        currentStepIndex = 0
        
        // Initialize with the first step
        if let firstStep = currentRoute?.steps.first {
            currentStep = firstStep
            nextStep = currentRoute?.steps.count ?? 0 > 1 ? currentRoute?.steps[1] : nil
        }
        
        // Announce start of navigation
        if let destination = destination?.name {
            announceDirections("Starting navigation to \(destination)")
        } else {
            announceDirections("Starting navigation")
        }
        
        // Set up progress tracking
        setupRouteProgress()
    }
    
    /// Stop active navigation
    func stopNavigation() {
        routeIsActive = false
        destination = nil
        currentRoute = nil
        allRoutes = []
        currentStep = nil
        nextStep = nil
        currentStepIndex = 0
        remainingDistance = 0
        remainingTime = 0
        currentStepRemainingDistance = 0
        
        // Reset progress tracking
        stepProgress = nil
        routeProgress = nil
    }
    
    /// Select an alternative route
    func selectRoute(at index: Int) {
        guard index < allRoutes.count else { return }
        currentRoute = allRoutes[index]
        prepareRouteForNavigation()
    }
    
    // MARK: - Private Methods
    
    private func prepareRouteForNavigation() {
        guard let route = currentRoute else { return }
        
        // Set initial values
        remainingDistance = route.distance
        remainingTime = route.expectedTravelTime
        
        // Setup initial step
        if let firstStep = route.steps.first {
            currentStep = firstStep
            nextStep = route.steps.count > 1 ? route.steps[1] : nil
            currentStepRemainingDistance = firstStep.distance
        }
    }
    
    private func setupRouteProgress() {
        guard let route = currentRoute else { return }
        
        // Set up route progress
        routeProgress = Progress(totalUnitCount: Int64(route.distance))
        routeProgress?.completedUnitCount = 0
        
        // Set up step progress
        if let firstStep = route.steps.first {
            stepProgress = Progress(totalUnitCount: Int64(firstStep.distance))
            stepProgress?.completedUnitCount = 0
        }
    }
    
    private func updateNavigation(with location: CLLocation) {
        guard routeIsActive, let route = currentRoute else { return }
        
        // Calculate remaining distance to destination
        if let destinationCoordinate = destination?.placemark.coordinate {
            let destinationLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
            remainingDistance = location.distance(from: destinationLocation)
        }
        
        // Update current step and progress
        updateCurrentStep(with: location)
        
        // Check if we're near the destination
        if remainingDistance < 20 { // 20 meters threshold
            announceDirections("You have arrived at your destination")
            stopNavigation()
        }
        
        lastLocation = location
    }
    
    private func updateCurrentStep(with location: CLLocation) {
        guard let route = currentRoute, currentStepIndex < route.steps.count else { return }
        
        let currentStep = route.steps[currentStepIndex]
        
        // Calculate distance to next instruction point
        if let instructionCoordinate = currentStep.polyline.coordinate {
            let instructionLocation = CLLocation(latitude: instructionCoordinate.latitude, longitude: instructionCoordinate.longitude)
            currentStepRemainingDistance = location.distance(from: instructionLocation)
        }
        
        // Update step progress
        stepProgress?.completedUnitCount = Int64(currentStep.distance - currentStepRemainingDistance)
        
        // Check if we need to advance to the next step
        if currentStepRemainingDistance < 20 { // 20 meters threshold for step completion
            advanceToNextStep()
        }
    }
    
    private func advanceToNextStep() {
        guard let route = currentRoute, currentStepIndex < route.steps.count - 1 else { return }
        
        // Move to next step
        currentStepIndex += 1
        self.currentStep = route.steps[currentStepIndex]
        self.nextStep = currentStepIndex < route.steps.count - 1 ? route.steps[currentStepIndex + 1] : nil
        
        // Announce the new instruction
        if let instruction = currentStep?.instructions {
            announceDirections(instruction)
        }
        
        // Reset step progress
        if let stepDistance = currentStep?.distance {
            stepProgress = Progress(totalUnitCount: Int64(stepDistance))
            stepProgress?.completedUnitCount = 0
            currentStepRemainingDistance = stepDistance
        }
    }
    
    private func announceDirections(_ instruction: String) {
        // Implementation for voice guidance
        let utterance = AVSpeechUtterance(string: instruction)
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    // Returns a formatted string for the remaining distance
    func formattedRemainingDistance(with userSettings: UserSettings? = nil) -> String {
        let distanceInKilometers = remainingDistance / 1000
        
        if let settings = userSettings {
            return settings.formatDistance(distanceInKilometers)
        } else {
            return String(format: "%.1f km", distanceInKilometers)
        }
    }
    
    // Returns a formatted string for the remaining time
    func formattedRemainingTime() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remainingTime) ?? "Unknown"
    }
}

// MARK: - Helper Extensions

extension MKPolyline {
    var coordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else { return nil }
        
        var point = MKMapPoint()
        points().withMemoryRebound(to: MKMapPoint.self, capacity: 1) { pointer in
            point = pointer.pointee
        }
        
        return point.coordinate
    }
} 