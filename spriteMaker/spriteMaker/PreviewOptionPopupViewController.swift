//
//  PreviewOptionPopupViewController.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/02/26.
//

import UIKit

class PreviewOptionPopupViewController: UIViewController {
    @IBOutlet var popupSuperView: UIView!
    @IBOutlet weak var popupOption: UIView!
    @IBOutlet weak var popupArror: UIImageView!
    @IBOutlet weak var popupNum: UILabel!
    @IBOutlet weak var popupImage: UIImageView!
    @IBOutlet weak var removeView: UIView!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    
    var popupRectY: CGFloat!
    var popupArrorX: CGFloat!
    
    var selectedCell: Int!
    var viewModel: PreviewListViewModel!
    var previewListViewController: PreviewListViewController!
    var animatedPreviewClass: AnimatedPreviewClass!
    let categoryList = CategoryList()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottomInset = UIApplication.shared.windows[0].safeAreaInsets.bottom / 2
        let topSafeArea = UIApplication.shared.windows[0].safeAreaInsets.top
        let topAnchor = popupRectY! - topSafeArea
        let leadingAnchor = popupArrorX! - popupArror.frame.width / 2
        
        popupArror.leadingAnchor.constraint(equalTo: popupOption.leadingAnchor, constant: leadingAnchor).isActive = true
        popupOption.topAnchor.constraint(equalTo: popupSuperView.topAnchor, constant: topAnchor).isActive = true
        removeView.heightAnchor.constraint(equalToConstant: removeView.frame.height + bottomInset).isActive = true
        removeButton.centerYAnchor.constraint(equalTo: removeView.centerYAnchor, constant: bottomInset / -2).isActive = true
        
        popupNum.text = "#\(selectedCell! + 1)"
        popupImage.image = viewModel.item(at: selectedCell).image
    }
    
    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        let center = popupSuperView.frame.height / 2
        
        switch gesture.state {
        case .changed:
            let movement = popupSuperView.center.y + gesture.translation(in: popupOption).y
            if movement > center {
                popupSuperView.center.y = popupSuperView.center.y + gesture.translation(in: popupOption).y
                gesture.setTranslation(CGPoint.zero, in: popupSuperView)
            }
        case .ended:
            if popupSuperView.frame.minY > popupSuperView.frame.height / 10 {
                dismiss(animated: true, completion: nil)
            } else {
                popupSuperView.center.y = center
            }
        default: break
        }
    }
    
    @IBAction func tappedRemoveButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        let _ = viewModel.removeItem(at: selectedCell!)
    }
    @IBAction func closePopup(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PreviewOptionPopupViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryList.numsOfCategory
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as? CategoryCell else {
            return UICollectionViewCell()
        }
        let selectedItem = viewModel.item(at: selectedCell)
        let category = categoryList.item(at: indexPath.row)
        let sizeUnit = cell.layer.frame.height * 0.4
        
        cell.categoryName.font = UIFont.systemFont(ofSize: sizeUnit, weight: UIFont.Weight.heavy)
        cell.categoryName.text = category.text
        cell.backgroundColor = category.color
        cell.layer.cornerRadius = sizeUnit
        cell.layer.borderWidth = selectedItem.category == category.text ? (sizeUnit / 7) : 0
        cell.layer.borderColor = UIColor.white.cgColor
        return cell
    }
}

extension PreviewOptionPopupViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let categoryName = categoryList.item(at: indexPath.row).text
        let oldItem = viewModel.item(at: selectedCell)
        let newItem = PreviewImage(image: oldItem.image, category: categoryName, imageCanvasData: oldItem.imageCanvasData)
        viewModel.updateItem(at: selectedCell, previewImage: newItem)
        animatedPreviewClass.changeAnimatedPreview(isReset: false)
        categoryCollectionView.reloadData()
    }
}

extension PreviewOptionPopupViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin: CGFloat = 10
        let height = categoryCollectionView.bounds.height - margin * 2
        let width = height * 2
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let halfOfCellWidth = categoryCollectionView.bounds.height - 10 * 2
        let sideInset = view.bounds.width / 2 - halfOfCellWidth
        
        let selectedItem = viewModel.item(at: selectedCell)
        let selectedIndex: CGFloat = CGFloat(categoryList.indexOfCategory(name: selectedItem.category))
        categoryCollectionView.setContentOffset(CGPoint(x: (halfOfCellWidth * 2 + 10) * selectedIndex, y: 0), animated: true)
        
        return UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
    }
}

class CategoryCell: UICollectionViewCell {
    @IBOutlet weak var categoryName: UILabel!
}

class CategoryList {
    private var categorys: [Category] = [
        Category(text: "Default", color: UIColor(red: 44/255, green: 44/255, blue: 47/255, alpha: 1)),
        Category(text: "Move", color: UIColor(red: 25/255, green: 122/255, blue: 60/255, alpha: 1)),
        Category(text: "Jump", color: UIColor(red: 158/255, green: 146/255, blue: 13/255, alpha: 1)),
        Category(text: "Attack", color: UIColor(red: 153/255, green: 53/255, blue: 14/255, alpha: 1)),
        Category(text: "Skill", color: UIColor(red: 90/255, green: 0/255, blue: 146/255, alpha: 1)),
    ]
    
    func addCategory(newCategory: Category) {
        categorys.append(newCategory)
    }
    
    var numsOfCategory: Int {
        return categorys.count
    }
    
    func getCategoryColor(category: String) -> UIColor {
        let index = indexOfCategory(name: category)
        let category = item(at: index)
        return category.color
    }
    
    func item(at index: Int) -> Category {
        return categorys[index]
    }
    
    func indexOfCategory(name text: String) -> Int {
        return categorys.firstIndex(where: { $0.text == text }) ?? -1
    }
    
    func updateCategory(category: Category) {
        let index = self.indexOfCategory(name: category.text)
        if index != -1 {
            categorys[index] = category
        }
    }
    
    func removeCategory(category: Category) {
        let index = self.indexOfCategory(name: category.text)
        categorys.remove(at: index)
    }
}

struct Category {
    let text: String
    let color: UIColor
}


