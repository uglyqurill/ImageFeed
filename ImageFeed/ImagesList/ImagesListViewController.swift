import UIKit
import Kingfisher

class ImagesListViewController: UIViewController {
    
    // MARK: - Private properties
    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    private var photos: [Photo] = []

    private let notificationCenter = NotificationCenter.default
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?
    
    @IBOutlet private var tableView: UITableView!

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        imagesListServiceObserver = notificationCenter.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableViewAnimated()
        }

        photos = imagesListService.photos
    }
    
    // MARK: - Override methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupView() {
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func updateTableViewAnimated() {
        let oldPhotoCount = photos.count
        let newPhotoCount = imagesListService.photos.count
        photos = imagesListService.photos
        
        if oldPhotoCount != newPhotoCount {
            tableView.performBatchUpdates {
                let indexPath = (oldPhotoCount..<newPhotoCount).map { IndexPath(row: $0, section: 0)}
                tableView.insertRows(at: indexPath, with: .automatic)
            }
        }
    }
    
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let photo = photos[indexPath.row]
        if let cell = cell as? ImagesListCell, let url = URL(string: photo.thumbImageURL) {
            cell.imageURL = url
            cell.cellImage.kf.indicatorType = .activity
            cell.cellImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "thumb_image_placeholder"),
                options: [KingfisherOptionsInfoItem.loadDiskFileSynchronously]
            ) { [weak cell, weak tableView] result in
                guard let cell = cell else { return }
                switch result {
                case .success:
                    // IMPORTANT: The callback may be called after the cell is reused for a different url.
                    // So we test if the cell was reused or not.
                    // If the cell.imageURL has changed, than callback is comming from an old indexPath.
                    if cell.imageURL == url {
                        guard let tableView = tableView else { return }
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }

                case .failure:
                    break // do nothing
                }
            }
            setDescriptionLabel(for: cell, photo: photo)
            setLikeButtonImage(for: cell, isLiked: photo.isLiked)
            cell.delegate = self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    private func setDescriptionLabel(for cell: ImagesListCell, photo: Photo) {
        if let date = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: date)
        } else {
            cell.dateLabel.text = nil
        }
    }
    
    private func setLikeButtonImage(for cell: ImagesListCell, isLiked: Bool) {
        let likeButtonImageName = isLiked ? "like_button_on" : "like_button_off"
        let likeButtonImage = UIImage(named: likeButtonImageName)
        cell.likeButton.setImage(likeButtonImage, for: .normal)
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
}

extension ImagesListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else { fatalError("Failed to prepare for \(showSingleImageSegueIdentifier)") }
            if let largeURL = URL(string: photos[indexPath.item].largeImageURL) {
                viewController.image = largeURL
            }
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
//    func imageListCellDidTapLike(_ cell: ImagesListCell) {
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        let photo = photos[indexPath.row]
//
//        UIBlockingProgressHUD.show()
//        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
//            UIBlockingProgressHUD.dismiss()
//            guard let self = self else { return }
//
//            switch result {
//            case .success:
//                self.photos = self.imagesListService.photos
//                self.setLikeButtonImage(for: cell, isLiked: self.photos[indexPath.row].isLiked)
//
//            case .failure:
//                UIBlockingProgressHUD.showError(NSLocalizedString("Something went wrong. Please try again.", comment: ""))
//            }
//        }
//    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        guard
            let url = URL(string: photo.thumbImageURL),
            let image = ImageCache.default.retrieveImageInMemoryCache(forKey: url.absoluteString, options: nil)
        else { return 160 }

        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = image.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}

