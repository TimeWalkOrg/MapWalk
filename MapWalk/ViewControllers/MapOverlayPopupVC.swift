//
//  MapOverlayPopupVC.swift
//  MapWalk
//
//  Created by iMac on 14/08/24.
//

import UIKit
import PanModal

// MARK: - MapOverlayPopupVCDelegate
protocol MapOverlayPopupVCDelegate: AnyObject {
    //func didSelectLocation(_ location: (name: String, coordinate: CLLocationCoordinate2D, image: UIImage?))
    func didSelectLocation(_ location: MapImageOverlays)
}

class MapOverlayPopupVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Variable
//    var locationOptions: [(name: String, coordinate: CLLocationCoordinate2D, image: UIImage?)] = []
//    var selectedLocationName: String = "None"
//    var selectedLocation: (name: String, coordinate: CLLocationCoordinate2D, image: UIImage?) = (name: "None", coordinate: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), image: nil)
    
    var locationOptions: [MapImageOverlays] = []
    var selectedLocation: String = "None"
    
    weak var delegate: MapOverlayPopupVCDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Functions
    func setupUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "MapCollectionCell", bundle: nil), forCellWithReuseIdentifier: "MapCollectionCell")
    }
    
    func panModalWillDismiss() {
        delegate?.didSelectLocation(locationOptions.first(where: {$0.name == selectedLocation})!)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension MapOverlayPopupVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locationOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MapCollectionCell", for: indexPath) as! MapCollectionCell
        let location = locationOptions[indexPath.row]
        cell.setup(image: UIImage(data: location.icon ?? Data()), name: location.name ?? "-", isSelected: location.name == selectedLocation)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedLocation = locationOptions[indexPath.row].name ?? "None"
        self.dismiss(animated: true)
        delegate?.didSelectLocation(locationOptions[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 15
        let numberOfItemsPerRow: CGFloat = 3
        let width = (collectionView.bounds.width - (totalSpacing * (numberOfItemsPerRow - 1))) / numberOfItemsPerRow
        return CGSize(width: width, height: 90)
    }
}

// MARK: - PanModalPresentable
extension MapOverlayPopupVC: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return collectionView
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(280)
    }

    var longFormHeight: PanModalHeight {
        return .contentHeight(280)
    }

    var cornerRadius: CGFloat {
        return 0
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var panModalBackgroundColor: UIColor {
        return .black.withAlphaComponent(0.52)
    }
    
    var allowsTapToDismiss: Bool {
        return true
    }
    
    var allowsDragToDismiss: Bool {
        return true
    }
}
