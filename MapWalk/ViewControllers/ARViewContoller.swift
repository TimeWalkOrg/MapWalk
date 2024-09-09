//
//  ARViewContoller.swift
//  ARKit_Demo
//
//  Created by iMac on 02/09/24.
//

//import UIKit
//import SceneKit
//import ARKit
//
//class ARVC: UIViewController {
//
//    // MARK: - IBOutlet
//    @IBOutlet var sceneView: ARSCNView!
//
//    // MARK: - Variable
//    private var modelNodes: [String: SCNNode] = [:]
//
//    // MARK: - Lifecycle Methods
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupSceneView()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        checkCameraPermission()
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        // Pause the view's session
//        sceneView.session.pause()
//    }
//
//    // MARK: - Functions
//    private func setupSceneView() {
//        sceneView.delegate = self
//        sceneView.showsStatistics = true
//        sceneView.autoenablesDefaultLighting = true
//        sceneView.scene = SCNScene()
//    }
//
//    private func checkCameraPermission() {
//        sceneView.session.pause()
//
//        checkCameraPermission { [weak self] isGranted in
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//
//                if isGranted {
//                    self.startARSession()
//                } else {
//                    self.showPermissionAlert()
//                }
//            }
//        }
//    }
//
//
//    private func startARSession() {
//        let configuration = ARWorldTrackingConfiguration()
//        sceneView.session.run(configuration)
//
//        // Define model names and positions
//        let arrModels: [Model] = [
//            Model(name: "home1.usdz", root: "root", position: SIMD3<Float>(-0.5, 0, 0.1)),
//            Model(name: "home2.usdz", root: "root", position: SIMD3<Float>(-0.7, 0, 0.1)),
//            Model(name: "home3.usdz", root: "scene", position: SIMD3<Float>(-0.9, 0, 0.1)),
//            Model(name: "court.usdz", root: "scene", position: SIMD3<Float>(-0.11, 0, 0.1))
//
//        ]
//
//        for model in arrModels {
//            placeModel(model: model)
//        }
//    }
//
//    private func placeModel(model: Model) {
//
//        let modelName = model.name
//        guard let scene = SCNScene(named: modelName) else {
//            print("Can't inititalize Scene")
//            return
//        }
//
//        guard let rootNode = scene.rootNode.childNode(withName: model.root, recursively: true) else {
//            print("Error loading the model: \(modelName)")
//            return
//        }
//
//
//        // Scale and position the node as needed
//        rootNode.scale = model.scale
//        rootNode.eulerAngles = model.eulerAngles
//
//        let transform = simd_float4x4(translation: model.position)
//        let anchor = ARAnchor(name: "\(modelName)Anchor", transform: transform)
//        sceneView.session.add(anchor: anchor)
//
//        // Store the node
//        modelNodes[modelName] = rootNode
//    }
//}
//
//// MARK: - ARSCNViewDelegate
//extension ARVC: ARSCNViewDelegate {
//
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        guard let modelName = anchor.name?.replacingOccurrences(of: "Anchor", with: "") else { return nil }
//        return createNode(with: modelNodes[modelName])
//    }
//
//    // Create a node and add the corresponding model node
//    private func createNode(with modelNode: SCNNode?) -> SCNNode? {
//        guard let modelNode = modelNode else { return nil }
//        let node = SCNNode()
//        node.addChildNode(modelNode.clone()) // Use clone to avoid reusing the same node
//        return node
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
//        node.enumerateChildNodes { childNode, _ in
//            childNode.removeFromParentNode()
//            print("Removed Child node")
//        }
//    }
//}

import UIKit
import SceneKit
import ARKit

class ARViewContoller: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var btnClose: UIButton!
    
    // MARK: - Variable
    private var modelNodes: [String: SCNNode] = [:]
    private var lastModelEndPositionX: Float = -0.0
    private let specificDistance: Float = -0.3
    
    // MARK: - Action
    @IBAction func btnClose(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnClose.layer.cornerRadius = 10
        setupSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Functions
    private func setupSceneView() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = SCNScene()
    }
    
    private func checkCameraPermission() {
        sceneView.session.pause()
        
        checkCameraPermission { [weak self] isGranted in
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
                guard let self = self else { return }
                
                if isGranted {
                    self.startARSession()
                } else {
                    self.showPermissionAlert()
                }
            }
        }
    }
    
    
    private func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        // Define model names
        let arrModels: [Model] = [
            Model(name: "home1.usdz", root: "root"),
            Model(name: "home2.usdz", root: "root"),
            Model(name: "home1.usdz", root: "root"),
            Model(name: "home2.usdz", root: "root")
        ]
        
        for model in arrModels {
            placeModel(model: model)
        }
    }
    
    private func placeModel(model: Model) {
        let modelName = model.name
        guard let scene = SCNScene(named: modelName) else {
            print("Can't initialize Scene")
            return
        }

        guard let rootNode = scene.rootNode.childNode(withName: model.root, recursively: true) else {
            print("Error loading the model: \(modelName)")
            return
        }

        // Scale and position the node as needed
        rootNode.scale = model.scale
        rootNode.eulerAngles = model.eulerAngles
        
        // Calculate model size after scaling
        let (min, max) = rootNode.boundingBox
        let modelWidth = (max.x - min.x) * rootNode.scale.x

        // Update model's X position based on the last model's end position and a specific distance
        let modelPositionX = (lastModelEndPositionX + specificDistance)
        let position = SCNVector3(modelPositionX, model.position.y, model.position.z)
        lastModelEndPositionX = modelPositionX + modelWidth

        print("Width: \(modelWidth)")
        print("Position: \(position)")
        print("Last X: \(lastModelEndPositionX)\n")
        
        // Update the last model's end position

        // Set the model's position
        rootNode.position = position

        let transform = simd_float4x4(translation: SIMD3<Float>(modelPositionX, model.position.y, model.position.z))
        let anchor = ARAnchor(name: "\(modelName)Anchor", transform: transform)
        sceneView.session.add(anchor: anchor)
        
        // Store the node
        modelNodes[modelName] = rootNode
    }
}

// MARK: - ARSCNViewDelegate
extension ARViewContoller: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let modelName = anchor.name?.replacingOccurrences(of: "Anchor", with: "") else { return nil }
        return createNode(with: modelNodes[modelName])
    }
    
    // Create a node and add the corresponding model node
    private func createNode(with modelNode: SCNNode?) -> SCNNode? {
        guard let modelNode = modelNode else { return nil }
        let node = SCNNode()
        node.addChildNode(modelNode.clone()) // Use clone to avoid reusing the same node
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        node.enumerateChildNodes { childNode, _ in
            childNode.removeFromParentNode()
            print("Removed Child node")
        }
    }
}
