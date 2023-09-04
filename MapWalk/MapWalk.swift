
// Importing required frameworks
import SwiftUI
import MapKit

// Main ContentView for the application
struct MapWalk: View {
    // State variables for managing the map's center and type
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Initial center at New York
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var mapType: MKMapType = .satellite // Start in Satellite mode
    @State private var highlighterOn = false // State for highlighter mode
    @State private var showMenu = false  // State for showing the hamburger menu
    @State private var points: [CGPoint] = [] // Points to draw
    
    var body: some View {
        // Using ZStack to overlay UI elements
        ZStack {
            // Embedding the custom Map View
            UserLocationMapView(coordinateRegion: $region, mapType: $mapType)
            
            // Separate drawing layer to capture touch events for drawing
            if highlighterOn {
                DrawingView(points: $points)
            }
            
            // Vertical Stack for UI elements
            VStack {
                // Top menu bar
                HStack {
                    // "MapWalk" title at the top left, adjusted font size and weight
                    Text("MapWalk")
                        .foregroundColor(mapType == .standard ? .black : .white)  // Black in Standard, White in Satellite
                        .font(.system(size: 32, weight: .heavy))  // Smaller size and more bold
                    Spacer()
                    // Hamburger menu button
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "list.dash")
                            .foregroundColor(.white)
                    }
                    .popover(isPresented: $showMenu) {  // Popover for the menu
                        VStack {
                            Spacer()
                            Text("Settings")
                                .padding()
                        }
                        .frame(height: 100)  // 3-item length menu
                    }
                }
                .padding()
                Spacer()
            }
            
            VStack {
                Spacer() // Spacer to push the following elements to the bottom
                
                // Icon bar at the bottom of the screen
                HStack {
                    Spacer() // Spacer to move the buttons to the right
                    
                    // Button for highlighter mode, using an icon
                    Button(action: toggleHighlighter) {
                        Image(systemName: "pencil.tip")  // Pen tip icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .foregroundColor(highlighterOn ? .blue : .gray)
                    }
                    .padding(.trailing, 17)  // 10% to the left
                    
                    // Single button for toggling map type, using an icon
                    Button(action: toggleMapType) {
                        Image(systemName: mapType == .standard ? "map.fill" : "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .foregroundColor(.white)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 52)  // 10% shorter
                .padding()
                .background(Color.black)  // Solid dark gray
            }
        }
    }
    
    // Function to toggle the map type between standard and satellite
    func toggleMapType() {
        mapType = (mapType == .standard) ? .satellite : .standard
    }
    
    // Function to toggle the highlighter mode
    func toggleHighlighter() {
        highlighterOn.toggle()
    }
}

// Custom View for Drawing
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
            .stroke(Color.blue, lineWidth: 8) // 2mm thick line
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

// UIViewRepresentable struct to integrate MKMapView into SwiftUI
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

// Main App struct
@main
struct MapWalkApp: App {
    var body: some Scene {
        WindowGroup {
            MapWalk()
        }
    }
}
