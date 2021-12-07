//
//  SavingNoticeViewController.swift
//  SegmentCamera
//
//  Created by 間嶋大輔 on 2020/03/05.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit

class SavingNoticeViewController: UIViewController {
//    var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
//        addBannerViewToView(bannerView)
//        bannerView.adUnitID = "ca-app-pub-2305302958433771/1634689022"
//        bannerView.rootViewController = self
//        bannerView.load(GADRequest())
//        bannerView.delegate = self
//        bannerView.adSize = kGADAdSizeMediumRectangle
        // Do any additional setup after loading the view.
    }
    
//    func addBannerViewToView(_ bannerView: GADBannerView) {
//     bannerView.translatesAutoresizingMaskIntoConstraints = false
//     view.addSubview(bannerView)
//     view.addConstraints(
//       [NSLayoutConstraint(item: bannerView,
//                           attribute: .bottom,
//                           relatedBy: .equal,
//                           toItem: bottomLayoutGuide,
//                           attribute: .top,
//                           multiplier: 1,
//                           constant: 0),
//        NSLayoutConstraint(item: bannerView,
//                           attribute: .centerX,
//                           relatedBy: .equal,
//                           toItem: view,
//                           attribute: .centerX,
//                           multiplier: 1,
//                           constant: 0)
//       ])
//    }
//
//    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
//         print("adViewDidReceiveAd")
//       }
//
//       /// Tells the delegate an ad request failed.
//       func adView(_ bannerView: GADBannerView,
//           didFailToReceiveAdWithError error: GADRequestError) {
//         print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
//       }
//
//       /// Tells the delegate that a full-screen view will be presented in response
//       /// to the user clicking on an ad.
//       func adViewWillPresentScreen(_ bannerView: GADBannerView) {
//         print("adViewWillPresentScreen")
//       }
//
//       /// Tells the delegate that the full-screen view will be dismissed.
//       func adViewWillDismissScreen(_ bannerView: GADBannerView) {
//         print("adViewWillDismissScreen")
//       }
//
//       /// Tells the delegate that the full-screen view has been dismissed.
//       func adViewDidDismissScreen(_ bannerView: GADBannerView) {
//         print("adViewDidDismissScreen")
//       }
//
//    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
//      print("adViewWillLeaveApplication")
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        view.layer.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1957558474)
        var noticeWidth = CGFloat.zero
        if view.bounds.width < view.bounds.height {
            noticeWidth = view.bounds.width - 40
        } else {
            noticeWidth = view.bounds.height - 40
        }
        NoticeView.frame = CGRect(x: view.center.x - (noticeWidth * 0.5), y: view.center.y - (noticeWidth * 0.5), width: noticeWidth, height: noticeWidth)
        NoticeLabel.frame = CGRect(x: 10, y: 0, width: noticeWidth, height: noticeWidth * 0.2)
        originalImageView.frame = CGRect(x: 20, y: NoticeLabel.frame.maxY, width: noticeWidth * 0.5 - 30, height: noticeWidth * 0.6)
        editedImageView.frame = CGRect(x: originalImageView.frame.maxX + 10, y: NoticeLabel.frame.maxY, width: noticeWidth * 0.5 - 30, height: noticeWidth * 0.6)
        OKLabel.frame = CGRect(x: 0, y: noticeWidth * 0.8, width: noticeWidth, height: noticeWidth * 0.2)
        view.addSubview(NoticeView)
        NoticeView.addSubview(NoticeLabel)
        NoticeView.addSubview(OKLabel)
        NoticeView.addSubview(originalImageView)
        NoticeView.addSubview(editedImageView)
        NoticeView.backgroundColor = .white
        NoticeLabel.text = NSLocalizedString("Saved to Library", comment: "")
        OKLabel.text =  NSLocalizedString("OK", comment: "")
        NoticeLabel.textAlignment = .center
        OKLabel.textAlignment = .center
        NoticeLabel.adjustsFontSizeToFitWidth = true
        OKLabel.adjustsFontSizeToFitWidth = true
        OKLabel.backgroundColor = .darkGray
        OKLabel.textColor = .white
        NoticeLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        OKLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        NoticeView.layer.cornerRadius = 10
        NoticeView.clipsToBounds = true
        originalImageView.contentMode = .scaleAspectFit
        editedImageView.contentMode = .scaleAspectFit
        let okTap = UITapGestureRecognizer(target: self, action: #selector(OKButton))
        OKLabel.addGestureRecognizer(okTap)
        OKLabel.isUserInteractionEnabled = true
    }
    
    var NoticeView = UIView()
    var NoticeLabel = UILabel()
    var OKLabel = UILabel()
    
    var originalImageView = UIImageView()
    var editedImageView = UIImageView()
    
    var originalImage:UIImage? {
        didSet {
            originalImageView.image = originalImage
        }
    }
    
    var editedImage:UIImage? {
        didSet {
            editedImageView.image = editedImage
        }
    }
    
    @objc func OKButton() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

           var tapLocation: CGPoint = CGPoint()
           let touch = touches.first
           tapLocation = touch!.location(in: self.view)

           if !NoticeView.frame.contains(tapLocation) {
               self.dismiss(animated: false, completion: nil)
           }
       }
    
    override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
