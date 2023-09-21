//
//  CustomMenuView.swift
//  MapWalk
//
//  Created by MyMac on 21/09/23.
//

import UIKit

protocol CustomMenuDelegate: AnyObject {
    func didSelectAdd(polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?)
    func didSelectDelete(polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?)
}

class CustomMenuView: UIView {
    weak var delegate: CustomMenuDelegate?
    weak var polygonOverlay: MapPolygon?
    weak var polyLineOverlay: MapPolyline?
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 82.0/255.0, green: 82.0/255.0, blue: 80.0/255.0, alpha: 1.0)
        button.tintColor = .white
        button.setTitle("Add label", for: .normal)
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 82.0/255.0, green: 82.0/255.0, blue: 80.0/255.0, alpha: 1.0)
        button.tintColor = .white
        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        return button
    }()
    
    private let horizontalLine: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.2)
        return view
    }()
    
    init(frame: CGRect, delegate: CustomMenuDelegate?, polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?) {
        super.init(frame: frame)
        self.delegate = delegate
        self.polygonOverlay = polygonOverlay
        self.polyLineOverlay = polyLineOverlay
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        // Customize the appearance of the CustomMenuView here
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.withAlphaComponent(0.8).cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        
        // Add buttons to the view
        addSubview(addButton)
        addSubview(horizontalLine)
        addSubview(deleteButton)
        
        
        self.backgroundColor = UIColor(red: 82.0/255.0, green: 82.0/255.0, blue: 80.0/255.0, alpha: 1.0)
        // Layout constraints for buttons
        addButton.translatesAutoresizingMaskIntoConstraints = false
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            addButton.heightAnchor.constraint(equalToConstant: 40),
            
            horizontalLine.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 0),
            horizontalLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            horizontalLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            horizontalLine.heightAnchor.constraint(equalToConstant: 1),
            
            deleteButton.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor, constant: 0),
            deleteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            deleteButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Initialize buttons with alpha set to 0
        addButton.alpha = 0
        horizontalLine.alpha = 0
        deleteButton.alpha = 0
    }
    
    // Button actions
    @objc private func addTapped() {
        if let overlay = self.polygonOverlay {
            delegate?.didSelectAdd(polygonOverlay: overlay, polyLineOverlay: nil)
        }
        else if let overlay = self.polyLineOverlay {
            delegate?.didSelectAdd(polygonOverlay: nil, polyLineOverlay: overlay)
        }
    }
    
    @objc private func deleteTapped() {
        if let overlay = self.polygonOverlay {
            delegate?.didSelectDelete(polygonOverlay: overlay, polyLineOverlay: nil)
        }
        else if let overlay = self.polyLineOverlay {
            delegate?.didSelectDelete(polygonOverlay: nil, polyLineOverlay: overlay)
        }
    }
    
    // Method to show the buttons after animation completes
    func showButtons() {
        UIView.animate(withDuration: 0.2) {
            self.addButton.alpha = 1
            self.deleteButton.alpha = 1
            self.horizontalLine.alpha = 1
        }
    }
}
