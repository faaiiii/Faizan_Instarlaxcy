//
//  GalleryController.swift
//  instarlaxcy
//
//  Created by Faizan Khalid on 17/04/2019.
//  Copyright © 2019 Faizan Khalid. All rights reserved.
//

import UIKit
import Kingfisher
import SKPhotoBrowser
import PKHUD

class GalleryController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var datasource = [FBImage]() { didSet {
        collectionView.reloadData()
        }}
    lazy var picker = ImagePicker(presentationController: self, delegate: self)
    override func viewDidLoad() {
        super.viewDidLoad()

        getData()

        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: reloadEvent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadOnDelete), name: reloadOnDeleteEvent, object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadImage))


        reloadDataPeriodly()
    }

    func reloadDataPeriodly() {
        run({ [weak self] in
            self?.getData()
            self?.reloadDataPeriodly()
            }, after: 60)
    }

    @objc func reloadOnDelete() {
        browser.dismissPhotoBrowser(animated: true)
        getData()
    }

    @objc func uploadImage() {
        if let barButton = navigationItem.rightBarButtonItem,
            let view = barButton.value(forKey: "view") as? UIView {
            picker.present(from: view)
        }
    }

    @objc func getData() {
        FirebaseConnector().getImages(completion: { [weak self] images in
            self?.datasource = images
            HUD.hide()
        })
    }

    func addButtonToBrowser(_ browser: SKPhotoBrowser) {
        let moreOptionButton = UIButton()
        moreOptionButton.translatesAutoresizingMaskIntoConstraints = false
        moreOptionButton.setImage(UIImage(named: "more"), for: .normal)
        moreOptionButton.addTarget(self, action: #selector(showMoreOption), for: .touchUpInside)
        browser.view.addSubview(moreOptionButton)
        moreOptionButton.topAnchor.constraint(equalTo: browser.view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
        moreOptionButton.rightAnchor.constraint(equalTo: browser.view.rightAnchor, constant: -16).isActive = true
        moreOptionButton.frame.size = CGSize(width: 44, height: 44)
    }

    @objc func showMoreOption(button: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Save",
                                           style: .default,
                                           handler: { [weak self] _ in
                                            self?.savePhoto()
        }))

        controller.addAction(UIAlertAction(title: "Delete",
                                           style: .destructive,
                                           handler: { [weak self] _ in
                                            self?.deletePhoto()
        }))

        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller.popoverPresentationController?.sourceView = button
        browser?.present(controller, animated: true)
    }
    var selectedIndex: Int?

    func deletePhoto() {
        guard let index = browser?.currentPageIndex else { return }
        let image = datasource[index]
        FirebaseConnector().deleteImage(image)
        HUD.show(.progress)
    }

    var browser: SKPhotoBrowser!
    func setupData(startIndex: Int) {
        let images = datasource.map({ raw -> SKPhoto in 
            let photo = SKPhoto.photoWithImageURL(raw.url)
            photo.shouldCachePhotoURLImage = true
            return photo
        })
        browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(startIndex)
        present(browser, animated: true)
        addButtonToBrowser(browser)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryImageCell", for: indexPath) as! GalleryImageCell
        cell.setData(data: datasource[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let edge = (UIScreen.main.bounds.width - 1) / 3
        return CGSize(width: UIScreen.main.bounds.width, height: 500)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        setupData(startIndex: indexPath.row)
    }
}

extension GalleryController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        guard let image = image else { return }
        FirebaseConnector().uploadImage(image: image)
        HUD.show(.progress)
    }
}

extension GalleryController {
    func savePhoto() {
        guard let index = browser?.currentPageIndex else { return }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? GalleryImageCell, let image = cell.imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            browser?.present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            browser?.present(ac, animated: true)
        }
    }
}

// run a function in schedule 
func run(_ action: @escaping () -> Void, after second: Double) {
    let triggerTime = DispatchTime.now() + .milliseconds(Int(second * 1000))
    DispatchQueue.main.asyncAfter(deadline: triggerTime) { action() }
}
