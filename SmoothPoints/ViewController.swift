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
    
    let toleranceSlider: UISlider = {
           let slider = UISlider()
           slider.minimumValue = 1.0
           slider.maximumValue = 10.0
           slider.value = 5.0
           slider.translatesAutoresizingMaskIntoConstraints = false
           return slider
       }()
       
       let resampleSlider: UISlider = {
           let slider = UISlider()
           slider.minimumValue = 5.0
           slider.maximumValue = 200.0
           slider.value = 20.0
           slider.translatesAutoresizingMaskIntoConstraints = false
           return slider
       }()
       
       let toleranceLabel: UILabel = {
           let label = UILabel()
           label.text = "Tolerance: 5.0"
           label.textAlignment = .left
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       let resampleLabel: UILabel = {
           let label = UILabel()
           label.text = "Resample: 20"
           label.textAlignment = .left
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Closed", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupSliders()
        view.backgroundColor = UIColor(red:1.0, green:0.8, blue:0.8, alpha: 1)
    }
    
    var drawingView:SmoothDrawingView? {
        get {
            return view as? SmoothDrawingView
        }
    }
    func setupSliders() {
        view.addSubview(toleranceSlider)
        view.addSubview(toleranceLabel)
        view.addSubview(resampleSlider)
        view.addSubview(resampleLabel)
        
        NSLayoutConstraint.activate([
            // Tolerance Slider
            toleranceSlider.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            toleranceSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            toleranceSlider.widthAnchor.constraint(equalToConstant: 200),
            
            // Tolerance Label
            toleranceLabel.centerYAnchor.constraint(equalTo: toleranceSlider.centerYAnchor),
            toleranceLabel.leadingAnchor.constraint(equalTo: toleranceSlider.trailingAnchor, constant: 10),
            toleranceLabel.widthAnchor.constraint(equalToConstant: 120),
            
            // Resample Slider
            resampleSlider.topAnchor.constraint(equalTo: toleranceSlider.bottomAnchor, constant: 10),
            resampleSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            resampleSlider.widthAnchor.constraint(equalToConstant: 200),
            
            // Resample Label
            resampleLabel.centerYAnchor.constraint(equalTo: resampleSlider.centerYAnchor),
            resampleLabel.leadingAnchor.constraint(equalTo: resampleSlider.trailingAnchor, constant: 10),
            resampleLabel.widthAnchor.constraint(equalToConstant: 120)
        ])
        
        // Add slider event handlers
        toleranceSlider.addTarget(self, action: #selector(toleranceChanged(_:)), for: .valueChanged)
        resampleSlider.addTarget(self, action: #selector(resampleChanged(_:)), for: .valueChanged)
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
        
        let closeBarButton = UIBarButtonItem(title: "Close Loop", style: .plain, target: self, action: #selector(toggleClosed))
        
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        navigationItem.leftBarButtonItems = [dropdownBarButton, flex ]
        navigationItem.rightBarButtonItems = [closeBarButton]
        
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
    @objc func toleranceChanged(_ sender: UISlider) {
        toleranceLabel.text = "Tolerance: \(String(format: "%.1f", sender.value))"
        // Update drawing view tolerance
        (view as? SmoothDrawingView)?.tolerance = CGFloat(sender.value)
    }
    
    @objc func resampleChanged(_ sender: UISlider) {
        resampleLabel.text = "Resample: \(Int(sender.value))"
    
        (view as? SmoothDrawingView)?.resampledSpace = CGFloat(sender.value)
    }
    
}
