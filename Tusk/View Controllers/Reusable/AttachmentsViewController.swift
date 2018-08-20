//
//  AttachmentsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/18/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import NYTPhotoViewer
import MastodonKit

class AttachmentsViewController: NYTPhotosViewController {
    private let dataHandler: AttachmentsViewControllerDataHandler
    
    convenience init(attachments: [Attachment], initialAttachment: Attachment?) {
        let dataHandler = AttachmentsViewControllerDataHandler(attachments: attachments)
        self.init(dataSource: dataHandler, initialPhoto: dataHandler.photo(for: initialAttachment), delegate: dataHandler)
    }
    
    override init(dataSource: NYTPhotoViewerDataSource, initialPhoto: NYTPhoto?, delegate: NYTPhotosViewControllerDelegate?) {
        guard let dataHandler = dataSource as? AttachmentsViewControllerDataHandler else { fatalError("AttachmentsViewController may only have AttachmentsViewControllerDataHandler as data source") }
        self.dataHandler = dataHandler
        super.init(dataSource: dataSource, initialPhoto: initialPhoto, delegate: delegate)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class AttachmentsViewControllerDataHandler: NSObject, NYTPhotosViewControllerDelegate, NYTPhotoViewerDataSource {
    var numberOfPhotos: NSNumber? { return NSNumber(integerLiteral: self.photos.count) }
    let photos: [AttachmentPhoto]
    
    init(attachments: [Attachment]) {
        self.photos = attachments.map { (attachment) in AttachmentPhoto(attachment: attachment) }
    }
    
    func photo(for attachment: Attachment?) -> NYTPhoto? {
        guard let attachment = attachment else { return nil }
        return self.photos.first { (photo) in photo.attachment == attachment }
    }

    func index(of photo: NYTPhoto) -> Int {
        guard let photo = photo as? AttachmentPhoto else { return NSNotFound }
        guard let index = self.photos.index(of: photo) else { return NSNotFound }
        return index
    }
    
    func photo(at photoIndex: Int) -> NYTPhoto? {
        guard photoIndex < self.photos.count else { return nil }
        return self.photos[photoIndex]
    }
}

fileprivate class AttachmentPhoto: NSObject, NYTPhoto {
    let attachment: Attachment
    var image: UIImage? { return try? UIImage(contentsOf: URL(string: attachment.url), cachePolicy: .reloadRevalidatingCacheData) }
    var imageData: Data? { return try? Data(contentsOf: URL(string: attachment.url)!) }
    var placeholderImage: UIImage? { return nil }
    var attributedCaptionTitle: NSAttributedString? { return nil }
    var attributedCaptionSummary: NSAttributedString? { return nil }
    var attributedCaptionCredit: NSAttributedString? { return nil }
    
    init(attachment: Attachment) {
        self.attachment = attachment
    }
}
