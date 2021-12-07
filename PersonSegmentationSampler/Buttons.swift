//
//  Buttons.swift
//  SegmentCamera
//
//  Created by 間嶋大輔 on 2020/03/04.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit

extension EditViewController {
     func buttonSetting() {
        if view.bounds.width > view.bounds.height {
            PreviewView.frame = view.bounds
            
            backgroundView.frame = CGRect(x: view.bounds.maxX - (view.bounds.width * 0.25), y: 0, width: view.bounds.width  * 0.25, height: view.bounds.height)
            let buttonHeight = backgroundView.bounds.width * 0.33
            
            
            BlurButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8) , y: backgroundView.center.y + (buttonHeight * 2), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
             BlurLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.2) , y: backgroundView.center.y + (buttonHeight * 2), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            AlphaButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8), y: backgroundView.center.y + (buttonHeight * 1.0), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            ColorButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8), y: backgroundView.center.y , width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            ColorLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.2), y: backgroundView.center.y , width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            FiltersButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8), y: backgroundView.center.y - buttonHeight, width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            AlphaLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.2) , y: backgroundView.center.y + (buttonHeight * 1.0), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            FilterLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.2), y: backgroundView.center.y - buttonHeight, width: buttonHeight * 0.5, height: buttonHeight * 0.5)

        } else {
            PreviewView.frame = view.bounds

            backgroundView.frame = CGRect(x: 0, y: view.bounds.maxY - (view.bounds.height * 0.25), width: view.bounds.width, height: view.bounds.height * 0.25)
            let buttonHeight = backgroundView.bounds.height * 0.33
            
            BlurButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 2.5), y: backgroundView.center.y - (buttonHeight * 0.8), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            BlurLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 2.5), y: backgroundView.center.y - (buttonHeight * 0.3) , width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            AlphaButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 1.5), y: backgroundView.center.y - (buttonHeight * 0.8), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            ColorButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.5), y: backgroundView.center.y - (buttonHeight * 0.8), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            FiltersButton.frame = CGRect(x: backgroundView.center.x + (buttonHeight * 0.5), y: backgroundView.center.y - (buttonHeight * 0.8), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            FilterLabel.frame = CGRect(x: backgroundView.center.x + (buttonHeight * 0.5), y: backgroundView.center.y - (buttonHeight * 0.3), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            AlphaLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 1.5), y: backgroundView.center.y - (buttonHeight * 0.3) , width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            ColorLabel.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.5), y: backgroundView.center.y - (buttonHeight * 0.3) , width: buttonHeight * 0.5, height: buttonHeight * 0.5)
        }
    }
    
     func buttonAdding(){
        AlphaButton.image = UIImage(systemName: "person.crop.circle.badge.minus")
        ColorButton.image = UIImage(systemName: "person.crop.circle.fill.badge.plus")
        BlurButton.image = UIImage(systemName: "person.crop.square.fill")
        FiltersButton.image = UIImage(systemName: "rectangle.stack.person.crop")
        AlphaLabel.text = NSLocalizedString("Trans", comment: "")
        BlurLabel.text = NSLocalizedString("Blur", comment: "")
        ColorLabel.text = NSLocalizedString("Image", comment: "")
        FilterLabel.text = NSLocalizedString("Filters", comment: "")
        
        AlphaButton.tintColor = UIColor.darkGray
        BlurButton.tintColor = UIColor.darkGray
        ColorButton.tintColor = UIColor.darkGray
        FiltersButton.tintColor = UIColor.darkGray
        AlphaLabel.textColor = UIColor.darkGray
        FilterLabel.textColor = UIColor.darkGray

        BlurLabel.textColor = UIColor.darkGray
        ColorLabel.textColor = UIColor.darkGray
        
        ColorLabel.textAlignment = .center
        AlphaLabel.textAlignment = .center
        FilterLabel.textAlignment = .center

        BlurLabel.textAlignment = .center
     
        AlphaLabel.adjustsFontSizeToFitWidth = true
        FilterLabel.adjustsFontSizeToFitWidth = true
        BlurLabel.adjustsFontSizeToFitWidth = true
   
        ColorLabel.adjustsFontSizeToFitWidth = true
        
        backgroundView.backgroundColor = UIColor.white
        backgroundView.alpha = 0.5
        
        let symbolConfig = UIImage.SymbolConfiguration(weight: .thin)
        FiltersButton.preferredSymbolConfiguration = symbolConfig
        FiltersButton.contentMode = .scaleAspectFill
        ColorButton.preferredSymbolConfiguration = symbolConfig
        ColorButton.contentMode = .scaleAspectFill
        AlphaButton.preferredSymbolConfiguration = symbolConfig
        AlphaButton.contentMode = .scaleAspectFill
        BlurButton.preferredSymbolConfiguration = symbolConfig
        BlurButton.contentMode = .scaleAspectFill
        view.addSubview(backgroundView)
        view.addSubview(AlphaButton)
        view.addSubview(BlurButton)
        view.addSubview(BlurLabel)
        view.addSubview(AlphaLabel)
        view.addSubview(ColorButton)
        view.addSubview(ColorLabel)
        view.addSubview(FiltersButton)
        view.addSubview(FilterLabel)

        
        view.bringSubviewToFront(AlphaButton)
        view.bringSubviewToFront(AlphaLabel)
 
        view.bringSubviewToFront(BlurButton)
        view.bringSubviewToFront(BlurLabel)
        view.bringSubviewToFront(ColorButton)
        view.bringSubviewToFront(ColorLabel)
        view.bringSubviewToFront(FilterLabel)

      
        ColorButton.isUserInteractionEnabled = true
        ColorLabel.isUserInteractionEnabled = true
        AlphaButton.isUserInteractionEnabled = true
        FiltersButton.isUserInteractionEnabled = true
        AlphaLabel.isUserInteractionEnabled = true
        FilterLabel.isUserInteractionEnabled = true

        BlurLabel.isUserInteractionEnabled = true
        BlurButton.isUserInteractionEnabled = true
        
        let addGesture = UITapGestureRecognizer(target: self, action: #selector(alpha))
        let addGesture4Label = UITapGestureRecognizer(target: self, action: #selector(alpha))
        AlphaButton.addGestureRecognizer(addGesture)
        AlphaLabel.addGestureRecognizer(addGesture4Label)
        

        let blurTap = UITapGestureRecognizer(target: self, action: #selector(blur))
        let blurTap2 = UITapGestureRecognizer(target: self, action: #selector(blur))
        
        BlurButton.addGestureRecognizer(blurTap)
        BlurLabel.addGestureRecognizer(blurTap2)
        let cameraTap = UITapGestureRecognizer(target: self, action: #selector(Image))
        let cameraTap4Label = UITapGestureRecognizer(target: self, action: #selector(Image))
        ColorButton.addGestureRecognizer(cameraTap)
        ColorLabel.addGestureRecognizer(cameraTap4Label)
        
        let filterTap = UITapGestureRecognizer(target: self, action: #selector(Filters))
        let filterTap2 = UITapGestureRecognizer(target: self, action: #selector(Filters))
        FiltersButton.addGestureRecognizer(filterTap)
        FilterLabel.addGestureRecognizer(filterTap2)
        
    }
}
