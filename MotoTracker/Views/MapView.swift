import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool = false
    var polylines: [MKPolyline] = []
    var annotations: [MKPointAnnotation] = []
    
    // For tracking the user's location
    var trackingMode: MKUserTrackingMode = .none
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = trackingMode
        
        // Add polylines if provided
        for polyline in polylines {
            mapView.addOverlay(polyline)
        }
        
        // Add annotations if provided
        for annotation in annotations {
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map region
        mapView.setRegion(region, animated: true)
        
        // Update user location setting
        mapView.showsUserLocation = showsUserLocation
        
        // Update tracking mode
        if mapView.userTrackingMode != trackingMode {
            mapView.userTrackingMode = trackingMode
        }
        
        // Handle polylines
        mapView.removeOverlays(mapView.overlays)
        for polyline in polylines {
            mapView.addOverlay(polyline)
        }
        
        // Handle annotations
        mapView.removeAnnotations(mapView.annotations)
        for annotation in annotations {
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator for handling map delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // Styling the polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Customizing annotation views
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "CustomPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = UIColor.systemRed
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

extension MKPointAnnotation {
    static func createFrom(coordinate: CLLocationCoordinate2D, title: String, subtitle: String? = nil) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }
} 