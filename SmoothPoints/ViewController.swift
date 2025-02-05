//
//  ViewController.swift
//  SmoothPoints
//
//  Created by Todd Vanderlin on 2/5/25.
//

import UIKit


class ViewController: UIViewController {
    
    var dropdownBarButton:UIBarButtonItem!
    let interpolationMethods = ["Cubic", "Hermite", "Bezier", "Catmull-Rom"]
    var selectedMethod: InterpolationMethod = .catmullRom {
        didSet {
            dropdownBarButton.title = selectedMethod.rawValue
        }
    }
    
    let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 10.0
        slider.value = 5.0
        slider.widthAnchor.constraint(equalToConstant: 150).isActive = true // Set fixed width for compact UI
        return slider
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Closed", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        view.backgroundColor = UIColor(red:1.0, green:0.8, blue:0.8, alpha: 1)
    }
    
    var drawingView:SmoothDrawingView? {
        get {
            return view as? SmoothDrawingView
        }
    }
    
    func setupNavigationBar() {
        
        let menu = UIMenu(title: "Select Interpolation", children: InterpolationMethod.allCases.map { method in
            UIAction(title: method.rawValue, handler: { _ in
                self.selectedMethod = method
                self.drawingView?.interpolationMethod = method
            })
        })
        
        dropdownBarButton = UIBarButtonItem(title: "Interpolation", menu: menu)
        selectedMethod = .catmullRom
        
        
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        let sliderBarButton = UIBarButtonItem(customView: slider)
        
        let closeBarButton = UIBarButtonItem(title: "Close Loop", style: .plain, target: self, action: #selector(toggleClosed))
       
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        navigationItem.leftBarButtonItems = [dropdownBarButton, flex ]
        navigationItem.rightBarButtonItems = [closeBarButton, sliderBarButton]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc func toggleClosed() {
        guard let v = drawingView else { return }
        v.shouldClose = !v.shouldClose
    }
    @objc func sliderValueChanged(_ sender: UISlider) {
        print("Slider Value: \(sender.value)")
        guard let v = self.view as? SmoothDrawingView else { return }
        v.tolerance = CGFloat(sender.value)
        v.updatePath()
    }
    
}
