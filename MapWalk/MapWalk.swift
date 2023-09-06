// Importing required frameworks
import SwiftUI
import MapKit
import CoreLocation

// Main ContentView for the application
struct MapWalk: View {
    @ObservedObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion()
    @State private var mapType: MKMapType = .satellite
    @State private var highlighterOn = false
    @State private var showMenu = false
    @State private var points: [CGPoint] = []
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    UserLocationMapView(coordinateRegion: $region, mapType: $mapType)
                        .onAppear {
                            region = MKCoordinateRegion(
                                center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 40.704978680390475, longitude: -74.01368692013155), // sets to current location or defaults to specified lat-long if location is not available
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // sets the zoom level
                            )
                        }
                    if highlighterOn {
                        DrawingView(points: $points)
                            .background(Color.white.opacity(0.2))
                            .zIndex(1)
                            .allowsHitTesting(true)  // Capture gestures when highlighter is on
                    } else {
                        DrawingView(points: $points)
                            .background(Color.clear)
                            .zIndex(0)
                            .allowsHitTesting(false)  // Pass-through gestures when highlighter is off
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 10)
                // Icon bar at the bottom
                HStack {
                    Spacer()
                    Button(action: toggleHighlighter) {
                        Image(systemName: "pencil.tip")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .foregroundColor(highlighterOn ? .blue : .gray)
                    }
                    .padding(.trailing, 17)
                    
                    Button(action: toggleMapType) {
                        Image(systemName: mapType == .standard ? "map.fill" : "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .foregroundColor(.white)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 53)
                .padding()
                .background(Color.black)
            }
            
            // Top menu bar
            VStack {
                HStack {
                    Text("MapWalk")
                        .foregroundColor(mapType == .standard ? .black : .white)
                        .font(.system(size: 32, weight: .heavy))
                    Spacer()
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "list.dash")
                            .foregroundColor(.white)
                    }
                    .popover(isPresented: $showMenu) {
                        VStack {
                            Spacer()
                            Text("Settings").padding()
                        }
                        .frame(height: 100)
                    }
                }
                .padding()
                Spacer()
            }
        }
    }
    
    func toggleMapType() {
        mapType = (mapType == .standard) ? .satellite : .standard
    }
    
    func toggleHighlighter() {
        highlighterOn.toggle()
    }
}

struct DrawingView: View {
    @Binding var points: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for point in points {
                    path.move(to: point)
                    path.addLine(to: point)
                }
            }
            .stroke(Color.blue, lineWidth: 8)
            .background(Color.clear)
            .gesture(
                DragGesture(minimumDistance: 0.1)
                    .onChanged({ value in
                        let point = CGPoint(x: value.location.x, y: value.location.y - geometry.frame(in: .global).minY)
                        self.points.append(point)
                        print(self.points)
                    })
            )
        }
    }
}

struct UserLocationMapView: UIViewRepresentable {
    @Binding var coordinateRegion: MKCoordinateRegion
    @Binding var mapType: MKMapType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(coordinateRegion, animated: true)
        uiView.mapType = mapType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UserLocationMapView
        init(_ parent: UserLocationMapView) {
            self.parent = parent
        }
    }
}

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            print("Location access was denied or restricted.")
        case .notDetermined:
            print("User has not yet made a choice about location permission.")
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location access was granted.")
        @unknown default:
            print("A new case was added to CLAuthorizationStatus that we have not handled.")
        }
    }
}
