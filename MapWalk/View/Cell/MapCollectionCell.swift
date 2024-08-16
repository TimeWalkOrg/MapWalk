//
//  MapCollectionCell.swift
//  MapWalk
//
//  Created by iMac on 14/08/24.
//

import UIKit

class MapCollectionCell: UICollectionViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    
    // MARK: - Lifecycle Method
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: - Function
    func setup(image: UIImage?, name: String, isSelected: Bool) {
        imgView.image = image
        lblName.text = name
        viewContainer.BorderWidth = isSelected ? 3 : 0
        viewContainer.BorderColor =  isSelected ? UIColor(hexString: "2F61C5") : .clear
    }
}
