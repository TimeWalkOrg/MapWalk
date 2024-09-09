//
//  MapOverlayPopupVC.swift
//  MapWalk
//
//  Created by iMac on 14/08/24.
//

import UIKit
import PanModal
import PhotosUI

// MARK: - MapOverlayPopupVCDelegate
protocol MapOverlayPopupVCDelegate: AnyObject {
    func didSelectLocation(_ location: MapImageOverlays)
}

class MapOverlayPopupVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Variable
    var locationOptions: [MapImageOverlays] = []
    var selectedLocation: String = "None"
    
    var selectedMapImage: UIImage?
    var mapName: String?
    var mapYear: String?
    
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
        if let location = locationOptions.first(where: {$0.name == selectedLocation}) {
            delegate?.didSelectLocation(location)
        } else {
            print("Unable to find locaiton")
        }
    }
    
    func openMapImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func showAlert(isForMapName: Bool) {
        let title = isForMapName ? "Enter the map name" : "Enter the year of map"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { txtField in
            txtField.placeholder = isForMapName ? "Enter name" : "Enter year"
            txtField.keyboardType = isForMapName ? .default : .numberPad
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let text = (alert.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                self.showAlert(message: isForMapName ? "Please enter valide map name." : "Please enter valide map year.")
                self.selectedMapImage = nil
                self.mapName = nil
                self.mapYear = nil
                return
            }
            
            if isForMapName {
                self.mapName = text
                showAlert(isForMapName: false)
            } else {
                self.mapYear = text
                saveMapOverlay()
            }
        }
        
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.selectedMapImage = nil
            self.mapName = nil
            self.mapYear = nil
        }
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func saveMapOverlay() {
        if let mapImage = selectedMapImage, let name = mapName, let year = mapYear {
            let coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            let mapOverlay = CoreDataManager.shared.saveMapImageOverlay(
                name: "\(name) - \(year)",
                image: mapImage.pngData(), coordinates: "{\(coordinate.latitude),\(coordinate.longitude)}",
                midCoord: "{40.70524,-74.01091}",
                overlayTopLeftCoord: "{40.71077,-74.01834}",
                overlayTopRightCoord: "{40.71077,-74.00409}",
                overlayBottomLeftCoord: "{40.69918,-74.0183}", icon: mapImage.jpegData(compressionQuality: 0.7))
            self.locationOptions.append(mapOverlay)
            self.panModalPerformUpdates {
                self.collectionView.reloadData()
                
                if !locationOptions.isEmpty {
                    self.collectionView.scrollToItem(at: IndexPath(row: locationOptions.count-1, section: 0), at: .centeredVertically, animated: true)
                }
            }
        }
    }
    
    // MARK: - Action
    @IBAction func btnAddMapAction(_ sender: UIButton) {
        openMapImagePicker()
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
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.row > 3 {
           return configureContextMenu(index: indexPath.row)
        }
        return nil
    }
    
    func configureContextMenu(index: Int) -> UIContextMenuConfiguration {
        let context = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (action) -> UIMenu? in
            
            let cancel = UIAction(title: "Cancel", image: UIImage(systemName: "xmark"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil,attributes: .destructive, state: .off) { [weak self] _ in
                guard let self = self else { return }
                CoreDataManager.shared.deleteMapImageOverlay(overlayID: self.locationOptions[index].overlayID)
                self.locationOptions.remove(at: index)
                self.collectionView.reloadData()
            }
            
            return UIMenu(title: "Options", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [delete, cancel])
        }
        return context
    }
}

// MARK: - PHPickerViewControllerDelegate
extension MapOverlayPopupVC: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        if let result = results.first {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let image = object as? UIImage {
                            self.selectedMapImage = image
                            self.showAlert(isForMapName: true)
                        } else {
                            self.showAlert(title: "Oops!", message: "Unable to pick image.")
                        }
                    }
                }
            }
        }
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
