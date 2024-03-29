//
//  PreviewListCollectionViewCell.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/05/06.
//

import UIKit

class PreviewListCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var previewImageCollection: UICollectionView!
    
    var canvas: Canvas!
    var animatedPreviewVM: AnimatedPreviewViewModel!
    var layerVM: LayerListViewModel!
    var panelCollectionView: UICollectionView!
    var animatedPreview: UIImageView!
    var previewAndLayerCVC: PreviewAndLayerCollectionViewCell!
    
    let categoryListVM = CategoryListViewModel()
    var cellWidth: CGFloat!
    var isInit: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // add gesture
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        previewImageCollection.addGestureRecognizer(gesture)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        previewImageCollection.reloadData()
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
    
    func reloadPreviewListItems() {
        self.previewImageCollection.reloadData()
        updateCanvasData()
    }
    
    func updateCanvasData() {
        guard let layer = layerVM.selectedLayer else { return }
        let gridData = layer.data
        canvas.changeGrid(index: layerVM.selectedLayerIndex, gridData: gridData)
        canvas.setNeedsDisplay()
    }
}

extension PreviewListCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return layerVM.numsOfFrames + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.row {
        case layerVM.numsOfFrames:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddFrameCell", for: indexPath) as? AddFrameCell else {
                return UICollectionViewCell()
            }
            cell.previewListCVC = self
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCell", for: indexPath) as? PreviewCell else {
                return UICollectionViewCell()
            }
            guard let previewItem = layerVM.getFrame(at: indexPath.row) else {
                print("error")
                return UICollectionViewCell()
            }
            cell.updatePreview(frame: previewItem, index: indexPath.row)

            let categoryIndex = categoryListVM.indexOfCategory(name: previewItem.category)
            cell.categoryColor.layer.backgroundColor = categoryListVM.item(at: categoryIndex).color.cgColor
            setSelectedViewOutline(cell, indexPath.item == layerVM.selectedFrameIndex)
            cellWidth = cell.bounds.width
            cell.index = indexPath.item
            return cell
        }
    }
}

extension PreviewListCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        canvas.switchToolsInitSetting()
        
        if indexPath.row == layerVM.selectedFrameIndex {
            guard let previewOptionPopupVC = UIStoryboard(name: "PreviewPopup", bundle: nil).instantiateViewController(identifier: "PreviewOptionPopupViewController") as? PreviewOptionPopupViewController else { return }
            guard let popupPosition = getPopupViewPosition(indexPath: indexPath) else { return }
            
            previewOptionPopupVC.popupArrowX = popupPosition.x
            previewOptionPopupVC.popupPositionY = popupPosition.y
            previewOptionPopupVC.previewListCVC = self
            previewOptionPopupVC.viewModel = self.layerVM
            previewOptionPopupVC.animatedPreviewVM = self.animatedPreviewVM
            previewOptionPopupVC.modalPresentationStyle = .overFullScreen
            self.window?.rootViewController?.present(previewOptionPopupVC, animated: false, completion: nil)
        } else if (indexPath.row < layerVM.numsOfFrames) {
            layerVM.selectedFrameIndex = indexPath.item
            layerVM.selectedLayerIndex = 0
            layerVM.reloadLayerList()
            updateCanvasData()
        }
        previewImageCollection.reloadData()
    }
    
    private func getPopupViewPosition(indexPath: IndexPath) -> CGPoint? {
        var pos: CGPoint
        guard let selectedCell = previewImageCollection.cellForItem(at: indexPath) else { return nil }
        let selectedCellFrame = selectedCell.frame
        let scrollX = selectedCellFrame.minX - previewImageCollection.contentOffset.x
        
        pos = CGPoint(x: 0, y: 0)
        
        pos.x += previewAndLayerCVC.drawingVC.panelCollectionView.frame.minX
        pos.x += previewAndLayerCVC.previewAndLayerCVC.frame.minX
        pos.x += scrollX
        pos.x += selectedCellFrame.width / 2
        
        pos.y += previewAndLayerCVC.drawingVC.panelCollectionView.frame.minY
        pos.y += previewAndLayerCVC.drawingVC.navigationController?.navigationBar.frame.height ?? 0
        pos.y += previewAndLayerCVC.previewAndLayerCVC.frame.maxY
        pos.y -= 10 + panelCollectionView.contentOffset.y
        
        return pos
    }
}

extension PreviewListCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sideLength = previewImageCollection.bounds.height - 2
        return CGSize(width: sideLength - 5, height: sideLength)
    }
    
    // Re-order
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if (layerVM.reorderFrame(dst: destinationIndexPath.row, src: sourceIndexPath.row)) {
            animatedPreviewVM.changeAnimatedPreview()
            canvas.timeMachineVM.addTime()
            previewImageCollection.setNeedsDisplay()
        }
    }
}

class PreviewCell: UICollectionViewCell {
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var categoryColor: UIView!
    @IBOutlet weak var previewCell: UIView!
    var isSelectedCell: Bool = false
    var index: Int!
    
    override func awakeFromNib() {
        setViewShadow(target: previewImage, radius: 3, opacity: 0.2)
    }
    
    func updatePreview(frame: Frame, index: Int) {
        previewImage.image = frame.renderedImage
        self.index = index
    }
}

class AddFrameCell: UICollectionViewCell {
    var previewListCVC: PreviewListCollectionViewCell!
    
    override func layoutSubviews() {
        setSideCorner(target: self, side: "all", radius: self.frame.width / 7)
        setViewShadow(target: self, radius: 3, opacity: 0.2)
    }
    
    @IBAction func tappedAdd(_ sender: Any) {
        let contentX: CGFloat
        
        previewListCVC.canvas.switchToolsInitSetting()
        
        previewListCVC.layerVM.selectedLayerIndex = 0;
        previewListCVC.layerVM.selectedFrameIndex += 1;
        previewListCVC.layerVM.addEmptyFrame(index: previewListCVC.layerVM.selectedFrameIndex)
        
        contentX = CGFloat(previewListCVC.layerVM.selectedFrameIndex) * previewListCVC.cellWidth
        previewListCVC.previewImageCollection.contentOffset.x = contentX
        previewListCVC.reloadPreviewListItems()
        previewListCVC.canvas.timeMachineVM.addTime()
    }
}
