import SwiftUI
import MapKit

struct ExtendedMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var route: MKRoute? = nil
    var destination: CLLocationCoordinate2D? = nil
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        
        // Clear existing overlays and annotations
        view.removeOverlays(view.overlays)
        
        // Remove all annotations except user location
        let annotationsToRemove = view.annotations.filter { !($0 is MKUserLocation) }
        view.removeAnnotations(annotationsToRemove)
        
        // Add route overlay if available
        if let route = route {
            view.addOverlay(route.polyline, level: .aboveRoads)
            
            // Make sure the route is visible
            view.setVisibleMapRect(
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
            view.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ExtendedMapView
        
        init(_ parent: ExtendedMapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
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
            guard !(annotation is MKUserLocation) else {
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