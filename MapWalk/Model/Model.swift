//
//  Model.swift
//  ARKit_Demo
//
//  Created by iMac on 03/09/24.
//

import Foundation
import SceneKit

// MARK: - Model
struct Model {
    
    // MARK: - Variables
    var name: String
    var root: String
    var position: SIMD3<Float> = SIMD3<Float>(-0.5, 0, 0.1)
    var scale: SCNVector3 = SCNVector3(x: 0.0003, y: 0.0003, z: 0.0003)
    var eulerAngles: SCNVector3 = SCNVector3(x: -1.6, y: 0, z: 0)
}
