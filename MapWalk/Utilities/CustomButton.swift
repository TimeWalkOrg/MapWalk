//
//  CustomButton.swift
//  MapWalk
//
//  Created by MyMac on 18/09/23.
//

import Foundation
import UIKit

class CustomButton: UIButton {

    var onContextMenuDismissed: (() -> Void)?

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
        
        // Notify the closure when the context menu is about to be dismissed
        onContextMenuDismissed?()
    }
}
