//
//  ViewController.swift
//  LUTFilters
//
//  Created by Muhammad  Farhan Akram on 19/09/2024.
//

import UIKit
import CoreImage

class ViewController: UIViewController {
    
    var originalImageView: UIImageView?
    var filteredImageView: UIImageView?
    var originalImage: UIImage?
    
    // Array of image names and a variable to track the current index
    let imageNames = ["Apple", "Apple1", "Apple2", "Apple3"]
    var currentImageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the initial image
        if let inputImage = UIImage(named: imageNames[currentImageIndex]) {
            self.originalImage = inputImage
            displayOriginalImage(inputImage)
            addFilterButtons()
            addNavigationButtons() // Add Next and Previous buttons
        } else {
            print("Failed to load the image from assets.")
        }
    }
    
    // Function to display the current image
    func displayOriginalImage(_ image: UIImage) {
        originalImageView?.removeFromSuperview() // Remove old image view if any
        
        let imageView = UIImageView(image: image)
        imageView.frame = self.view.bounds
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        self.originalImageView = imageView
    }
    
    // Add "Next" and "Previous" buttons to switch images
    func addNavigationButtons() {
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Next", for: .normal)
        nextButton.frame = CGRect(x: self.view.frame.width - 100, y: 50, width: 80, height: 40)
        nextButton.backgroundColor = .systemBlue
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.addTarget(self, action: #selector(nextImage), for: .touchUpInside)
        self.view.addSubview(nextButton)
        
        let prevButton = UIButton(type: .system)
        prevButton.setTitle("Previous", for: .normal)
        prevButton.frame = CGRect(x: 20, y: 50, width: 80, height: 40)
        prevButton.backgroundColor = .systemBlue
        prevButton.setTitleColor(.white, for: .normal)
        prevButton.addTarget(self, action: #selector(prevImage), for: .touchUpInside)
        self.view.addSubview(prevButton)
    }
    
    // Function to handle "Next" button tap
    @objc func nextImage() {
        // Remove the filtered image view if it exists
        filteredImageView?.removeFromSuperview()
        
        // Move to the next image
        currentImageIndex = (currentImageIndex + 1) % imageNames.count
        if let newImage = UIImage(named: imageNames[currentImageIndex]) {
            self.originalImage = newImage // Update the original image reference
            displayOriginalImage(newImage)
        } else {
            print("Failed to load the image.")
        }
    }

    // Function to handle "Previous" button tap
    @objc func prevImage() {
        // Remove the filtered image view if it exists
        filteredImageView?.removeFromSuperview()
        
        // Move to the previous image
        currentImageIndex = (currentImageIndex - 1 + imageNames.count) % imageNames.count
        if let newImage = UIImage(named: imageNames[currentImageIndex]) {
            self.originalImage = newImage // Update the original image reference
            displayOriginalImage(newImage)
        } else {
            print("Failed to load the image.")
        }
    }

    // Function to add four filter buttons
    func addFilterButtons() {
        let buttonTitles = ["Fujicolor_SuperHR100", "Fujifilm_QuickSnap", "Kodak_FunSaver", "Kodak_WaterSport"]
        
        let gridRows = 2
        let gridCols = 2
        let horizontalPadding: CGFloat = 10
        let verticalPadding: CGFloat = 10
        let buttonWidth = (self.view.frame.width - (horizontalPadding * CGFloat(gridCols + 1))) / CGFloat(gridCols)
        let buttonHeight: CGFloat = 50
        let startYPosition = self.view.frame.height - (CGFloat(gridRows) * (buttonHeight + verticalPadding)) - 20
        
        for (index, title) in buttonTitles.enumerated() {
            let row = index / gridCols
            let col = index % gridCols
            let buttonX = CGFloat(col) * (buttonWidth + horizontalPadding) + horizontalPadding
            let buttonY = startYPosition + CGFloat(row) * (buttonHeight + verticalPadding)
            
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: #selector(applyFilterButtonTapped(_:)), for: .touchUpInside)
            button.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.tag = index // Assign a tag to differentiate filters
            self.view.addSubview(button)
        }
    }


    
    // Function that handles filter button taps
    @objc func applyFilterButtonTapped(_ sender: UIButton) {
        guard let inputImage = originalImage else {
            print("Original image not found.")
            return
        }
        
        // Array of preset LUT file names
        let presets = ["PRESET_Fujicolor_SuperHR100", "PRESET_Fujifilm_QuickSnap", "PRESET_Kodak_FunSaver", "PRESET_Kodak_WaterSport"]
        
        // Get the preset based on the button tag
        let selectedPreset = presets[sender.tag]
        
        print("Attempting to apply LUT filter using: \(selectedPreset).cube")
        
        if let filteredImage = applyLUTFilter(to: inputImage, withCubeFile: selectedPreset) {
            print("LUT filter applied successfully.")
            filteredImageView?.removeFromSuperview() // Remove old filtered image view if any
            displayFilteredImage(filteredImage)
        } else {
            print("Failed to apply LUT filter.")
        }
    }
    
    func displayFilteredImage(_ image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.frame = self.view.bounds
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        self.filteredImageView = imageView
    }
    

}


extension ViewController{
    func applyLUTFilter(to inputImage: UIImage, withCubeFile fileName: String) -> UIImage? {
        guard let lutData = loadLUTFromCubeFile(fileName: fileName) else {
            print("Failed to load LUT file.")
            return nil
        }
        
        guard let ciImage = CIImage(image: inputImage),
              let filter = CIFilter(name: "CIColorCube") else {
            print("Failed to create CIColorCube filter.")
            return nil
        }
        
        let size = lutData.size
        let data = lutData.cubeData
        
        filter.setValue(size, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        print("Applying LUT filter with size \(size)...")
        
        if let outputImage = filter.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                print("Successfully created CGImage from filtered CIImage.")
                return UIImage(cgImage: cgImage)
            } else {
                print("Failed to create CGImage.")
            }
        } else {
            print("Failed to get output image from filter.")
        }
        
        return nil
    }
    
    func loadLUTFromCubeFile(fileName: String) -> (cubeData: Data, size: NSNumber)? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "cube") else {
            print("File not found: \(fileName).cube")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var lutSize: Int = 0
            var cubeValues: [Float] = []
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                let components = trimmedLine.components(separatedBy: .whitespaces)
                
                if components.count == 2 && components[0] == "LUT_3D_SIZE" {
                    if let size = Int(components[1]) {
                        lutSize = size
                        print("Parsed LUT_3D_SIZE: \(lutSize)")
                    }
                } else if components.count == 3, let r = Float(components[0]), let g = Float(components[1]), let b = Float(components[2]) {
                    cubeValues.append(contentsOf: [r, g, b])
                }
            }
            
            if lutSize == 0 {
                print("LUT size is zero. Something went wrong when parsing the file.")
                return nil
            }
            
            let floatSize = lutSize * lutSize * lutSize * 4
            var lutData = [Float](repeating: 0, count: floatSize)
            
            for i in 0..<(lutSize * lutSize * lutSize) {
                lutData[i * 4 + 0] = cubeValues[i * 3 + 0]
                lutData[i * 4 + 1] = cubeValues[i * 3 + 1]
                lutData[i * 4 + 2] = cubeValues[i * 3 + 2]
                lutData[i * 4 + 3] = 1.0
            }
            
            let data = Data(buffer: UnsafeBufferPointer(start: &lutData, count: lutData.count))
            return (data, NSNumber(value: lutSize))
        } catch {
            print("Error reading LUT file: \(error)")
            return nil
        }
    }
}
