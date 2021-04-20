//
//  PreviewListCollectionViewCell.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/03/04.
//

import UIKit
import ImageIO
import Foundation
import MobileCoreServices

class PreviewListCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var animatedPreview: UIImageView!
    @IBOutlet weak var previewImageCollection: UICollectionView!
    
    var canvas: Canvas!
    var previewListRect: UIView!
    
    let categoryList = CategoryList()
    var viewModel: PreviewListViewModel!
    var animatedPreviewViewModel: AnimatedPreviewViewModel!
    var cellWidth: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        animatedPreview.layer.shadowColor = UIColor.black.cgColor
        animatedPreview.layer.masksToBounds = false
        animatedPreview.layer.shadowOffset = CGSize(width: 0, height: 4)
        animatedPreview.layer.shadowRadius = 5
        animatedPreview.layer.shadowOpacity = 0.3
        
        // add gesture
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        previewImageCollection.addGestureRecognizer(gesture)
    }
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        let collectionView = previewImageCollection
        
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView?.indexPathForItem(at: gesture.location(in: collectionView)) else { return }
            collectionView?.beginInteractiveMovementForItem(at: targetIndexPath)
            collectionView?.cellForItem(at: targetIndexPath)?.alpha = 0.5
        case .changed:
            collectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView?.endInteractiveMovement()
            collectionView?.reloadData()
            updateCanvasData()
        default:
            collectionView?.cancelInteractiveMovement()
        }
    }
    
    @IBAction func tappedAdd(_ sender: Any) {
        canvas.uploadCanvsDataToPreviewList()
        viewModel.addItem()
        let selectedIndex = viewModel.selectedCellIndex
        previewImageCollection.contentOffset.x = CGFloat(selectedIndex) * cellWidth
        reloadPreviewListItems()
    }
    
    @IBAction func tappedAnimate(_ sender: Any) {
        let categoryPopupVC = UIStoryboard(name: "AnimatedPreviewPopupViewController", bundle: nil).instantiateViewController(identifier: "AnimatedPreviewPopupViewController") as! AnimatedPreviewPopupViewController
        categoryPopupVC.modalPresentationStyle = .overFullScreen
        categoryPopupVC.categorys = viewModel.getCategorys()
        categoryPopupVC.animatedPreviewViewModel = animatedPreviewViewModel
        categoryPopupVC.positionY = self.frame.maxY - animatedPreview.frame.maxY - 25
        self.window?.rootViewController?.present(categoryPopupVC, animated: true, completion: nil)
    }
    
    func reloadPreviewListItems() {
        self.previewImageCollection.reloadData()
        updateCanvasData()
    }
    
    func updateCanvasData() {
        let selectedIndex = viewModel.selectedCellIndex
        print("--------------\(selectedIndex)")
        let canvasData = viewModel.selectedCellItem.imageCanvasData
        canvas.changeCanvas(index: selectedIndex, canvasData: canvasData)
        canvas.setNeedsDisplay()
    }
}

extension PreviewListCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numsOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCell", for: indexPath) as? PreviewCell else {
            return UICollectionViewCell()
        }
        let preview = viewModel.item(at: indexPath.row)
        cell.updatePreview(item: preview, index: indexPath.row)
        
        let categoryIndex = categoryList.indexOfCategory(name: preview.category)
        cell.contentView.layer.backgroundColor = categoryList.item(at: categoryIndex).color.cgColor
        cell.contentView.layer.borderWidth = indexPath.item == viewModel.selectedCellIndex ? 2 : 0
        cell.contentView.layer.borderColor = UIColor.white.cgColor
        
        cellWidth = cell.bounds.width
        cell.index = indexPath.item
        return cell
    }
}

extension PreviewListCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rect = self.previewImageCollection.cellForItem(at: indexPath)!.frame
        let scroll = rect.minX - self.previewImageCollection.contentOffset.x
        
        let selectedIndex = viewModel.selectedCellIndex
        if indexPath.row == selectedIndex {
            let previewOptionPopupVC = UIStoryboard(name: "PreviewPopup", bundle: nil).instantiateViewController(identifier: "PreviewOptionPopupViewController") as! PreviewOptionPopupViewController
            
            let windowWidth: CGFloat = UIScreen.main.bounds.size.width
            let panelContainerViewController = windowWidth * 0.9
            let margin = (windowWidth - panelContainerViewController) / 2
            
            previewOptionPopupVC.popupArrowX = animatedPreview.bounds.maxX + margin + scroll + cellWidth / 2
            previewOptionPopupVC.viewModel = self.viewModel
            previewOptionPopupVC.animatedPreviewViewModel = self.animatedPreviewViewModel
            previewOptionPopupVC.popupPositionY = self.frame.maxY - animatedPreview.frame.maxY - 25
            previewOptionPopupVC.modalPresentationStyle = .overFullScreen
            self.window?.rootViewController?.present(previewOptionPopupVC, animated: true, completion: nil)
        }
        viewModel.selectedCellIndex = indexPath.item
        updateCanvasData()
    }
}

extension PreviewListCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sideLength = previewImageCollection.bounds.height
        return CGSize(width: sideLength, height: sideLength)
    }
    
    // Re-order
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = viewModel.removeItem(at: sourceIndexPath.row)
        viewModel.insertItem(at: destinationIndexPath.row, item)
        viewModel.selectedCellIndex = destinationIndexPath.row
        animatedPreviewViewModel.changeAnimatedPreview(isReset: false)
    }
}

class PreviewCell: UICollectionViewCell {
    @IBOutlet weak var previewCell: UIView!
    @IBOutlet weak var previewImage: UIImageView!
    
    var index: Int!
    var isSelectedCell: Bool = false
    
    func updatePreview(item: PreviewImage, index: Int) {
        previewImage.image = item.image
        self.index = index
    }
}

struct PreviewImage {
    let image: UIImage
    let category: String
    let imageCanvasData: String
}
