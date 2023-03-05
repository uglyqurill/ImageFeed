import UIKit

protocol ImagesListCellDelegate: AnyObject {
    //func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    weak var delegate: ImagesListCellDelegate?
    
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var dateLabel: UILabel!
    static let reuseIdentifier = "ImagesListCell"
    
    var imageURL: URL?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageURL = nil
        // NOTE: This is debatable decision, but for best performance
        // we better cancel currently unneeded tasks
        cellImage.kf.cancelDownloadTask()
    }
}
