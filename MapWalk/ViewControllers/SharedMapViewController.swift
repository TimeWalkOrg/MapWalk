//
//  SharedMapViewController.swift
//  MapWalk
//
//  Created by MyMac on 03/10/23.
//

import UIKit

protocol SharedMapDelegate: AnyObject {
    func showSelectedMapFromURL(url: URL)
    func showCurrentMap()
}

class SharedMapViewController: UIViewController {

    weak var delegate: SharedMapDelegate?
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var lblNoContent: UILabel!
    var isOpenedMapDeleted = false
    var openedMapURL: URL?
    
    var arrKMLFiles: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    func setupView() {
        self.tblView.delegate = self
        self.tblView.dataSource = self
        self.tblView.register(UINib(nibName: "SharedMapTableViewCell", bundle: nil), forCellReuseIdentifier: "SharedMapTableViewCell")
        
        self.getKMLFiles()
        // corner radius
        viewContainer.layer.masksToBounds = true
        viewContainer.layer.cornerRadius = 10
        
        self.lblNoContent.isHidden = true
    }
    
    func showContentUnavailableView() {
        if #available(iOS 17.0, *) {
            self.lblNoContent.isHidden = true
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "map.fill")
            config.text = "No Shared Maps"
            config.secondaryText = "Your shared maps will appear here."
            config.imageProperties.tintColor = .gray
            config.textProperties.color = .gray
            config.secondaryTextProperties.color = .gray
            self.contentUnavailableConfiguration = config
        }
        else {
            // Fallback on earlier versions
            DispatchQueue.main.async {
                self.tblView.isHidden = true
                self.lblNoContent.isHidden = false
            }
        }
    }

    func getKMLFiles() {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedKMLFile) {
                let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
                
                for itemUrl in directoryContents {
                    self.arrKMLFiles.append(itemUrl)
                }
                
                self.tblView.reloadData()
                if self.arrKMLFiles.count == 0 {
                    self.showContentUnavailableView()
                }
            }
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}

extension SharedMapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrKMLFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SharedMapTableViewCell") as! SharedMapTableViewCell
        
        let url = self.arrKMLFiles[indexPath.row]
        cell.lblMapName.text = url.deletingPathExtension().lastPathComponent
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.showSelectedMapFromURL(url: self.arrKMLFiles[indexPath.row])
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Swipe-to-delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            self.showDeleteConfirmation(indexPath: indexPath)
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        //renameAction.backgroundColor = .blue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    @objc func showDeleteConfirmation(indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: "Delete Map",
            message: "Are you sure you want to delete?",
            preferredStyle: .actionSheet
        )
        
        let mapURL = self.arrKMLFiles[indexPath.row]
        let deleteAction = UIAlertAction(title: "Delete map", style: .destructive) { _ in
            // Performing the delete action
            
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedKMLFile) {
                let destinationURL = directoryURL.appendingPathComponent(mapURL.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try? FileManager.default.removeItem(at: destinationURL)
                    self.arrKMLFiles.remove(at: indexPath.row)
                    self.tblView.deleteRows(at: [indexPath], with: .automatic)
                    if self.openedMapURL != nil && self.openedMapURL == mapURL {
                        self.delegate?.showCurrentMap()
                    }
                }
                if self.arrKMLFiles.count == 0 {
                    self.delegate?.showCurrentMap()
                    self.showContentUnavailableView()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            // Set the source view for iPad and other devices with popover support
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
