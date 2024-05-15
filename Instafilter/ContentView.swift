//
//  ContentView.swift
//  Instafilter
//
//  Created by Ricardo on 24/04/24.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import StoreKit
import UIKit

struct ContentView: View {
    @AppStorage("filterCount") var filterCount = 0  // Counts the number of times a filter is applied
    @Environment(\.requestReview) var requestReview // Request review after certain interactions
    
    // State variables for image processing
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var showingFilters = false
    
    let context = CIContext() // Core Image context to process the filter operations

    var body: some View {
        NavigationStack{
            ScrollView{
                VStack{
                    Spacer()
                    PhotosPicker(selection: $selectedItem){
                        if let processedImage {
                            processedImage
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .frame(height: 300)
                                .padding(.horizontal)
                        } else {
                            ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                        }
                    }.buttonStyle(.plain)
                        .onChange(of: selectedItem, loadImage)
                    
                    Spacer()
                    // Image picker component
                    
                    
                    // Filter controls, only appear if an image is loaded
                    if processedImage != nil {
                        VStack {
                            VStack{
                                HStack{
                                    
                                    Slider(value: $filterIntensity)
                                        .onChange(of: filterIntensity, applyProcessing)
                                    Text("Intensity")
                                        .padding(.horizontal)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 100,alignment: .trailing)
                                }
                                
                                HStack{
                                    Slider(value: $filterRadius)
                                        .onChange(of: filterRadius, applyProcessing)
                                    Text("Radius")
                                        .padding(.horizontal)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 100,alignment: .trailing)
                                }
                                
                                HStack{
                                    Slider(value: $filterScale)
                                        .onChange(of: filterScale, applyProcessing)
                                    Text("Scale")
                                        .padding(.horizontal)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 100,alignment: .trailing)
                                }
                            }
                            .padding()
                            .padding(.vertical,8)
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                    }
                }
                .frame(idealHeight: 500)
                
                // Filter and sharing options.
                
                
            }
            .navigationTitle("Instafilter")
            
        }
        
        .safeAreaInset(edge: .bottom){
            VStack{
                HStack{
                    Button(action: changeFilter) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 110, height: 50)
                                    .offset(x: 25, y: -20)
                                    .rotationEffect(.degrees(10))
                                    .foregroundStyle(.white)
                                
                                Text("Change Filter")
                                    .padding()
                                    .foregroundColor(.white.opacity(0.9))
                                    .fontWeight(.bold)
                                    .background(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.clear,
                                                        Color.white.opacity(0.2),
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 4
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                }
                .offset(x: -10)
                
                Text(currentFilter.name)
                    .foregroundStyle(LinearGradient(colors: [.secondary, .secondary.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .padding(.top,12)
                
                HStack{
                    Spacer()
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                            .labelStyle(.iconOnly)
                    } else {
                        ShareLink(item: "")
                            .labelStyle(.iconOnly)
                            .disabled(true)
                    }
                }
                .padding(.horizontal,30)
            }
            .padding(.top, 44)
            .padding(.bottom,8)
            .background(.background.opacity(0.8))
        }
        
        .confirmationDialog("Choose filter", isPresented: $showingFilters){
            // List of filters available for application
            Button("Crystallize") { setFilter(CIFilter.crystallize()) }
            Button("Edges") { setFilter(CIFilter.edges()) }
            Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
            Button("Pixellate") { setFilter(CIFilter.pixellate()) }
            Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
            Button("Vignette") { setFilter(CIFilter.vignette()) }
            Button("False Color") { setFilter(CIFilter.falseColor()) }
            Button("Noir") { setFilter(CIFilter.photoEffectNoir()) }
            Button("Cancel", role: .cancel) { }
        }
        
    }
    
    // Shows filter selection dialog
    func changeFilter(){
        showingFilters = true
    }
    
    // Loads image from PhotosPicker and applies the current filter
    func loadImage(){
        Task{
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else {return}
            guard let inputImage = UIImage(data: imageData) else {return}
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    // Applies the selected filter properties to the image
    func applyProcessing(){
        let inputKeys = currentFilter.inputKeys

        // Setting filter parameters based on availability
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }

        guard let outputImage = currentFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {return}
        
        processedImage = Image(uiImage: UIImage(cgImage: cgImage))
    }

    // Sets the selected filter and re-applies to the image
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        // Request a review after applying 5 different filters
        if filterCount >= 5 {
            filterCount = 0
            requestReview()
        }
    }
        
}

#Preview {
    ContentView()
}
