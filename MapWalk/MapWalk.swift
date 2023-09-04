// Importing required frameworks
import SwiftUI
import MapKit

// Main ContentView for the application
struct MapWalk: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // New York
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var mapType: MKMapType = .satellite
    @State private var highlighterOn = false
    @State private var showMenu = false
    @State private var points: [CGPoint] = []
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    UserLocationMapView(coordinateRegion: $region, mapType: $mapType)
                    
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
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 52)
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

@main
struct MapWalkApp: App {
    var body: some Scene {
        WindowGroup {
            MapWalk()
        }
    }
}

