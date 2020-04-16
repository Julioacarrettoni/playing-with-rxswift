import SwiftUI
import MapKit
import FakeService

struct MapView: UIViewRepresentable {
    var globalState: GlobalState?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.refreshAnnotations(for: mapView)
        
        let centralLocation = Location.centralLocation
        let coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centralLocation.lat, longitude: centralLocation.lng), latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if self.globalState != context.coordinator.globalState {
            context.coordinator.globalState = self.globalState
            context.coordinator.refreshAnnotations(for: view)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var globalState: GlobalState?

        init(_ parent: MapView) {
            self.parent = parent
            self.globalState = parent.globalState
        }
        
        func refreshAnnotations(for mapView: MKMapView) {
            let updatedAnnotations = self.globalState?.makeAnnotations() ?? []
            let currentAnnotations = mapView.annotations.compactMap{ $0 as? TrackerPointAnnotation }
            let newAnnotations = updatedAnnotations.filter { annotation in !currentAnnotations.contains(where: { $0.kind == annotation.kind }) }
            let existingAnnotations = updatedAnnotations.filter { annotation in currentAnnotations.contains(where: { $0.kind == annotation.kind })}
            let oldAnnotations = currentAnnotations.filter { annotation in !updatedAnnotations.contains(where: { $0.kind == annotation.kind })}
            
            mapView.removeAnnotations(oldAnnotations)
            mapView.addAnnotations(newAnnotations)
            
            UIView.animate(withDuration: 1.0) {
                for annotation in existingAnnotations {
                    if let existingAnnotation = currentAnnotations.first(where: { $0.kind == annotation.kind }) {
                        if existingAnnotation.kind.requiresRefresh(comparedTo: annotation.kind) {
                            if let annotationView = mapView.view(for: existingAnnotation),
                                let image = annotation.kind.icon {
                                annotationView.image = image
                                annotationView.centerOffset = image.annotationImageOffset
                            }
                        }
                        existingAnnotation.kind = annotation.kind
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let trackerAnnotation = annotation as? TrackerPointAnnotation else {
                fatalError()
            }

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: trackerAnnotation.kind.identifier)

            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: trackerAnnotation.kind.identifier)
                annotationView?.canShowCallout = true
                annotationView?.calloutOffset = .zero
                annotationView?.clusteringIdentifier = nil
            } else {
                annotationView?.annotation = annotation
            }
            let image = trackerAnnotation.kind.icon
            annotationView?.image = image
            annotationView?.centerOffset = image?.annotationImageOffset ?? .zero

            return annotationView
        }
    }
}

// MARK: -
extension GlobalState {
    func makeAnnotations() -> [TrackerPointAnnotation] {
        let central = TrackerPointAnnotation(kind: .central(self.central))
        let couriers = self.couriers.map { TrackerPointAnnotation(kind: .courier($0)) }
        let destinations = self.packages.filter{ !$0.delivered }.map { TrackerPointAnnotation(kind: .destination($0.destination)) }
        
        return [central] + couriers + destinations
    }
}

final class TrackerPointAnnotation: MKPointAnnotation {
    enum Kind: Equatable {
        case courier(Courier)
        case central(Location)
        case destination(Location)
        
        var title: String {
            switch self {
                case .courier(let courier):
                    return courier.name
                case .central:
                 return "Central"
                case .destination:
                return "Client"
            }
        }
        
        var locationCoordinate: CLLocationCoordinate2D {
            switch self {
                case .courier(let courier):
                    return CLLocationCoordinate2D(latitude: courier.location.lat, longitude: courier.location.lng)
                case .central(let location), .destination(let location):
                    return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                
            }
        }
        
        var icon: UIImage? {
            switch self {
                case .courier(let courier):
                    if courier.vehicleId != nil {
                        return UIImage(systemName: "car.fill")
                    } else {
                        return UIImage(systemName: "person.crop.circle.fill")
                }
                case .central:
                    return UIImage(systemName: "square.and.arrow.up")
                case .destination:
                    return UIImage(systemName: "square.and.arrow.down")
            }
        }
        
        var identifier: String { "Marker" }
        static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
                case (.courier(let lhsCourier), .courier(let rhsCourier)):
                    return lhsCourier.id == rhsCourier.id
                case (.central, .central):
                    return true
                case (.destination(let lhsDestination), .destination(let rhsDestination)):
                    return lhsDestination == rhsDestination
                case (_, _):
                    return false
            }
        }
        
        func requiresRefresh(comparedTo other: Kind) -> Bool {
            switch (self, other) {
                case (.courier(let lhsCourier), .courier(let rhsCourier)):
                    return lhsCourier.vehicleId != rhsCourier.vehicleId
                case (_, _):
                    return false
            }
        }
    }
    
    var kind: Kind {
        didSet {
            self.title = kind.title
            self.coordinate = kind.locationCoordinate
        }
    }
    
    init(kind: Kind) {
        self.kind = kind
        super.init()
        self.title = kind.title
        self.coordinate = kind.locationCoordinate
    }
}

extension UIImage {
    var annotationImageOffset: CGPoint {
        .zero
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(globalState: nil)
    }
}
