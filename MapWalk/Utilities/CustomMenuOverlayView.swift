//
//  CustomMenuOverlayView.swift
//  MapWalk
//
//  Created by MyMac on 21/09/23.
//

import UIKit

class CustomMenuOverlayView: UIView {
    var dismissAction: (() -> Void)?
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        dismissAction?()
    }
}
