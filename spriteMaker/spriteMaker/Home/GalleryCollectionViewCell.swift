//
//  GalleryCollectionViewCell.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/08/16.
//

import UIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var menuStackView: UIStackView!
    
    weak var mainViewController: UIViewController!
    weak var superViewController: ViewController!
    var coreData: CoreData!
    var timeMachineVM: TimeMachineViewModel!
    
    var initSelectedIndex: Int!
    var isLoaded: Bool = false
    
    override func layoutSubviews() {
        if (isLoaded == false) {
            isLoaded = true
            superViewController.coreData.retriveData()
            coreData = superViewController.coreData
            initSelectedIndex = coreData.selectedIndex
            timeMachineVM = TimeMachineViewModel()
        }
    }
}

extension GalleryCollectionViewCell {
    
    @IBAction func tappedAddBtn(_ sender: Any = 0) {
        coreData.createData(title: "untitled", data: "", thumbnail: UIImage(named: "empty")!)
        coreData.setSelectedIndexToFirst()
        collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        collectionView.reloadData()
    }
    
    @IBAction func tappedCopyBtn(_ sender: Any) {
        let alert = UIAlertController(title: "복사", message: "선택된 아이템을 복사하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [self] UIAlertAction in
            coreData.copySelectedData()
            coreData.setSelectedIndexToFirst()
            collectionView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        mainViewController.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func tappedImportBtn(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        mainViewController.present(imagePicker, animated: true)
    }
    
    @IBAction func tappedExportBtn(_ sender: Any) {
        let alert = UIAlertController(title: "출력", message: "선택된 아이템을 출력하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { UIAlertAction in
            
            guard let exportVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ExportViewController") as? ExportViewController else { return }
            exportVC.superViewController = self.superViewController
            self.window?.rootViewController?.present(exportVC, animated: false, completion: nil)
        }))
        mainViewController.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func tappedRemoveBtn(_ sender: Any) {
        let alert = UIAlertController(title: "제거", message: "선택된 아이템을 제거하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { [self] UIAlertAction in
            coreData.deleteData(index: coreData.selectedIndex)
            collectionView.reloadData()
        }))
        mainViewController.present(alert, animated: true, completion: nil)
    }
}

extension GalleryCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return coreData.numsOfData
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpriteCollectionViewCell", for: indexPath) as? SpriteCollectionViewCell else { return UICollectionViewCell() }
        
        cell.index = coreData.numsOfData - indexPath.row - 1
        guard let data = coreData.getData(index: cell.index) else { return cell }
        
        // set title
        cell.titleTextField.text = data.title
        
        // selectedData outline
        if (coreData.selectedIndex == cell.index) {
            cell.spriteImage.layer.borderWidth = 1
        } else {
            cell.spriteImage.layer.borderWidth = 0
        }
        cell.spriteImage.layer.borderColor = UIColor.white.cgColor
        if let imageData = data.thumbnail {
            cell.spriteImage.image = UIImage(data: imageData)
        }
        return cell
    }
}

extension GalleryCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = coreData.numsOfData - indexPath.row - 1
        
        if (coreData.selectedIndex == index) {
            superViewController.changeToggle(toggleName: "draw")
        } else {
            coreData.changeSelectedIndex(index: index)
            collectionView.reloadData()
        }
    }
}

extension GalleryCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        
        width = (self.bounds.width / 2) - 30
        height = (self.bounds.width / 2)
        return CGSize(width: width, height: height)
    }
}

extension GalleryCollectionViewCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            let flipedImage = flipImageVertically(originalImage: pickedImage)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: pickedImage.cgImage!.width / 2, height: pickedImage.cgImage!.height / 2))
            let image = renderer.image { context in
                context.cgContext.draw(
                    flipedImage.cgImage!,
                    in: CGRect(x: 0, y: 0, width: pickedImage.cgImage!.width / 2, height: pickedImage.cgImage!.height / 2))
            }
            
            var frames: [Frame] = []
            
            for y in 0...10 {
                for x in 0...10 {
                    let grid = Grid()
                    for i in 0...15 {
                        for j in 0...15 {
                            guard let color = image.getPixelColor(pos: CGPoint(x: i + (x * 16), y: j + (y * 16))) else { return }
                            if (color.cgColor.alpha != 0) {
                                grid.addLocation(hex: color.hexa!, x: i, y: j)
                            }
                        }
                    }
                    let renderedImage = superViewController.canvas.canvasRenderer.image { context in
                        superViewController.canvas.drawSeletedPixels(context.cgContext, grid: grid.gridLocations)
                    }
                    let layer = Layer(gridData: matrixToString(grid: grid.gridLocations), renderedImage: renderedImage, ishidden: false)
                    let frame = Frame(layers: [layer], renderedImage: renderedImage, category: "Default")
                    frames.append(frame)
                }
            }
            
            let data = timeMachineVM.compressData(frames: frames, selectedFrame: 0, selectedLayer: 0)
            coreData.createData(title: "untitled", data: data, thumbnail: frames[0].renderedImage)
            
            coreData.setSelectedIndexToFirst()
            collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            collectionView.reloadData()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

class SpriteCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var spriteImage: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    var index: Int!
    
    override func awakeFromNib() {
        setSideCorner(target: spriteImage, side: "all", radius: spriteImage.bounds.width / 15)
        setViewShadow(target: self, radius: 5, opacity: 0.5)
        titleTextField.layer.borderColor = UIColor.black.cgColor
    }
}

extension SpriteCollectionViewCell: UITextFieldDelegate {
      func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        CoreData().updateTitle(title: textField.text!, index: index)
        titleTextField.resignFirstResponder()
        return true
      }
    
}
