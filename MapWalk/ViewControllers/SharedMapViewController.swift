//
//  SharedMapViewController.swift
//  MapWalk
//
//  Created by MyMac on 03/10/23.
//

import UIKit

protocol SharedMapDelegate: AnyObject {
    func showSelectedMapFromURL(url: URL)
}

class SharedMapViewController: UIViewController {

    weak var delegate: SharedMapDelegate?
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var viewContainer: UIView!
    
    var arrKMLFiles: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    func setupView() {
        self.getKMLFiles()
        self.tblView.delegate = self
        self.tblView.dataSource = self
        self.tblView.register(UINib(nibName: "SharedMapTableViewCell", bundle: nil), forCellReuseIdentifier: "SharedMapTableViewCell")
        
        // corner radius
        viewContainer.layer.masksToBounds = true
        viewContainer.layer.cornerRadius = 10
    }

    func getKMLFiles() {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedKMLFile) {
                let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
                
                for itemUrl in directoryContents {
                    self.arrKMLFiles.append(itemUrl)
                }
                self.tblView.reloadData()
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
}
