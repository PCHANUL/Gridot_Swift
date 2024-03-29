//
//  ExportViewController.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/08/07.
//

import UIKit
import AVFoundation
import Foundation

import Photos
import PhotosUI

class ExportViewController: UIViewController {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var selectionPanelCV: UICollectionView!
    @IBOutlet weak var speedPickerView: UIPickerView!
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var gifView: UIView!
    @IBOutlet weak var gifBtn: UIButton!
    @IBOutlet weak var gifLabel: UILabel!
    @IBOutlet weak var gifLoading: UIActivityIndicatorView!
    
    @IBOutlet weak var pngView: UIView!
    @IBOutlet weak var pngBtn: UIButton!
    @IBOutlet weak var pngLabel: UILabel!
    @IBOutlet weak var pngLoading: UIActivityIndicatorView!
    
    @IBOutlet weak var optionView: UIView!
    @IBOutlet weak var optionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var optionContainerView: UIView!
    
    weak var superViewController: UIViewController!
    weak var optionViewController: ExportOptionViewController!
    weak var exportFramePanelCVC: ExportFramePanelCVC!
    weak var exportCategoryPanelCVC: ExportCategoryPanelCVC!
    var frameDataArr: [FrameData]!
    var selectedFrameCount: Int!
    var categoryData: [String]!
    var categoryDataNums: [Int]!
    var selectedData: Asset!
    var selectedIndex: Int!
    
    var speedList = ["0.2", "0.4", "0.6", "Speed", "1.0", "1.2", "1.5"]
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? ExportOptionViewController else { return }
        
        optionViewController = destination
        optionViewController.gifLabel = gifLabel
        optionViewController.pngLabel = pngLabel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSideCorner(target: backgroundView, side: "top", radius: backgroundView.frame.width / 25)
        setSideCorner(target: pngView, side: "all", radius: pngView.frame.height / 4)
        setSideCorner(target: gifView, side: "all", radius: gifView.frame.height / 4)
        setSideCorner(target: optionView, side: "all", radius: 15)
        setViewShadow(target: pngView, radius: 5, opacity: 0.2)
        setViewShadow(target: gifView, radius: 5, opacity: 0.2)
        setViewShadow(target: optionView, radius: 5, opacity: 0.1)
        
        // init picker row
        speedPickerView.selectRow(speedList.firstIndex(of: "Speed")!, inComponent: 0, animated: true)
        
        // init various
        frameDataArr = []
        categoryData = []
        categoryDataNums = []
        selectedFrameCount = 0
        
        // get time data
        selectedData = CoreData.shared.getAsset(index: selectedIndex)
        guard let time = decompressDataInt32(selectedData.gridData!, CGSize(width: 100, height: 100)) else { return }
        for frame in time.frames {
            
            // set frameDataArr
            frameDataArr.append(FrameData(data: frame, isSelected: false))
            
            // set categoryData
            // 중복된 카테고리의 수를 categoryDataNums에 저장
            if categoryData.last == frame.category {
                categoryDataNums[categoryData.count - 1] += 1
            } else {
                categoryData.append(frame.category)
                categoryDataNums.append(0)
            }
        }
    }
    
    @IBAction func tappedBackground(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tappedOption(_ sender: Any) {
        let stackViewHeight: CGFloat
        
        stackViewHeight = CGFloat(optionViewController.optionStackView.arrangedSubviews.count) * 50
        if (optionViewHeight.constant == 30) {
            optionContainerView.isHidden = false
            optionViewHeight.constant += stackViewHeight
        } else {
            optionContainerView.isHidden = true
            optionViewHeight.constant -= stackViewHeight
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func tappedReset(_ sender: Any) {
        for index in 0..<frameDataArr.count {
            frameDataArr[index].isSelected = false
        }
        selectedFrameCount = 0
        checkSelectedFrameStatus()
    }
    
    @IBAction func tappedSave(_ sender: UIButton) {
        let speed: Double
        let exportData: ExportData
        let exportImageManager: ExportImageManager
            
        speed = Double(0.05) * (7 - Double(speedPickerView.selectedRow(inComponent: 0)))
        exportData = ExportData(
            title: (selectedData.title == "" ? "untitled" : selectedData.title)!,
            imageSize: getSelectedImageSize(),
            imageBackgroundColor: optionViewController.selectedBackgroundColor,
            isCategoryAdded: optionViewController.addCategoryColor.isOn,
            frameDataArr: self.frameDataArr
        )
        exportImageManager = ExportImageManager()

        print("save", sender.tag)
        
        // case 0 = png, case 1 = gif
        switch sender.tag {
        case 0:
            pngLoading.startAnimating()
            OperationQueue.main.addOperation {
                switch self.pngLabel.text {
                case "PNG":
                    let url = exportImageManager.exportPng(exportData)
                    self.presentActivityView(item: url)
                case "Sprite":
                    let url = exportImageManager.exportSprite(exportData)
                    self.presentActivityView(item: url)
                default:
                    return
                }
                self.pngLoading.stopAnimating()
            }
        case 1:
            gifLoading.startAnimating()
            OperationQueue.main.addOperation {
                switch self.gifLabel.text {
                case "GIF":
                    let url = exportImageManager.exportGif(exportData, speed)
                    self.presentActivityView(item: url)
                case "LivePhoto":
                    exportImageManager.exportLivePhoto(exportData, speed)
                    self.showToast(message: "done", targetView: self)
                default:
                    return
                }
                self.gifLoading.stopAnimating()
            }
        default:
            return
        }
    }
    
    func getSelectedImageSize() -> CGSize {
        switch optionViewController.imageSizeValue.selectedSegmentIndex {
        case 0:
            return CGSize(width: 128, height: 128)
        case 1:
            return CGSize(width: 256, height: 256)
        default:
            return CGSize(width: 512, height: 512)
        }
    }
    
    func presentActivityView(item: Any) {
        let activity = UIActivityViewController(
            activityItems: [item],
            applicationActivities: nil
        )
        present(activity, animated: true, completion: nil)
        activity.completionWithItemsHandler = {
            (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
            switch completed {
            case true:
                print("success")
                self.showToast(message: "done", targetView: self)
            default:
                print("cancel")
            }
        }
    }
    
    func presentActivityView(item: [URL]) {
        let activity = UIActivityViewController(
            activityItems: item,
            applicationActivities: nil
        )
        
        present(activity, animated: true, completion: nil)
        activity.completionWithItemsHandler = {
            (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
            switch completed {
            case true:
                print("success")
                self.showToast(message: "done", targetView: self)
            default:
                print("cancel")
            }
        }
    }
    
    func showToast(message : String, targetView: UIViewController) {
        let alert = UIAlertController(
            title: "complete",
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let goToLibrary = UIAlertAction(title: "go to library", style: UIAlertAction.Style.default) { UIAlertAction in
            UIApplication.shared.open(URL(string: "photos-redirect://")!)
        }
        let confirmAction = UIAlertAction(title: "confirm", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(goToLibrary)
        alert.addAction(confirmAction)
        present(alert, animated: true, completion: nil)
    }
    
    func checkSelectedFrameStatus() {
        switch selectedFrameCount {
        case 0:
            resetBtn.layer.opacity = 0.5
            pngView.layer.opacity = 0.5
            gifView.layer.opacity = 0.5
            resetBtn.isEnabled = false
            pngBtn.isEnabled = false
            gifBtn.isEnabled = false
            pngLabel.text = "PNG"
            textLabel.text = "출력할 프레임을 선택하세요"
        case 1:
            resetBtn.layer.opacity = 1
            pngView.layer.opacity = 1
            gifView.layer.opacity = 0.5
            resetBtn.isEnabled = true
            pngBtn.isEnabled = true
            gifBtn.isEnabled = false
            pngLabel.text = "PNG"
            textLabel.text = "출력할 형식에 맞는 버튼을 클릭하세요"
        default:
            resetBtn.layer.opacity = 1
            pngView.layer.opacity = 1
            gifView.layer.opacity = 1
            resetBtn.isEnabled = true
            pngBtn.isEnabled = true
            gifBtn.isEnabled = true
            textLabel.text = "출력할 형식에 맞는 버튼을 클릭하세요"
        }
        exportFramePanelCVC.frameCV.reloadData()
    }
}

extension ExportViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return speedList.count
    }
}

extension ExportViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel

        if (pickerLabel == nil)
        {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "System", size: 16)
            pickerLabel?.textAlignment = .center
        }
        
        pickerLabel?.text = speedList[row]
        return pickerLabel!
    }
}

extension ExportViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExportFramePanelCVC", for: indexPath) as? ExportFramePanelCVC else { return UICollectionViewCell() }
            exportFramePanelCVC = cell
            cell.superCollectionView = self
            cell.frames = frameDataArr
            let opacity = self.traitCollection.userInterfaceStyle == .dark ? 0.5 : 0.1
            setViewShadow(target: cell, radius: 5, opacity: Float(opacity))
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExportCategoryPanelCVC", for: indexPath) as? ExportCategoryPanelCVC else { return UICollectionViewCell() }
            exportCategoryPanelCVC = cell
            cell.superCollectionView = self
            cell.categorys = categoryData
            cell.categoryNums = categoryDataNums
            cell.frameOneSideLen = ((selectionPanelCV.frame.height - 60) / 3 * 2) - 5
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}

extension ExportViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (indexPath.row == 0) {
            return CGSize(
                width: selectionPanelCV.frame.width,
                height: (selectionPanelCV.frame.height - 60) / 3 * 2
            )
        } else {
            return CGSize(
                width: selectionPanelCV.frame.width,
                height: (selectionPanelCV.frame.height - 60) / 3
            )
        }
    }
}


func animateImages(_ data: Time?, targetImageView: UIImageView) {
    let images: [UIImage]
    
    if (data == nil) { return }
    images = data!.frames.map { frame in
        return frame.renderedImage
    }
    targetImageView.animationImages = images
    targetImageView.animationDuration = TimeInterval(images.count)
    targetImageView.startAnimating()
}
