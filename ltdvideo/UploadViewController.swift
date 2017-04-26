import Firebase
import UIKit
import Photos // needed?
import MobileCoreServices
import DZNEmptyDataSet
import AVFoundation
import DKImagePickerController
import FirebaseDatabase

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var progressLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    var urlTextView: UITextField!
//    var storageRef: FIRStorageReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restorationIdentifier = "UploadViewController"
        restorationClass = UploadViewController.self
        
        self.view.backgroundColor = UIColor.white
        
        self.progressLabel = UILabel(frame: CGRect(x:20, y:100, width:300, height:40))
        self.progressLabel.text = "Ready."
        view.addSubview(self.progressLabel)
        
        let uploadButton = UIButton(frame: CGRect(x:20, y:150, width:300, height:40))
        uploadButton.setTitle("Upload file", for: .normal)
        uploadButton.backgroundColor = .blue
        uploadButton.addTarget(self, action: #selector(selectAndUpload), for: .touchUpInside)
        
//        self.navigationController?.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(selectAndUpload))]
        self.navigationItem.rightBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(selectAndUpload))
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(signout))

//        view.addSubview(uploadButton)
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height + self.navigationController!.navigationBar.frame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        myTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        self.view.addSubview(myTableView)
        
        self.myTableView.emptyDataSetSource = self
        self.myTableView.emptyDataSetDelegate = self
        
        // A little trick for removing the cell separators
        self.myTableView.tableFooterView = UIView()
    }
    
    func signout() {
        
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
//        try! FIRAuth.auth()!.signOut()
//        self.removeFromParentViewController()
        dismiss(animated: true, completion: nil)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Upload a file. ")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Click the + to start.")
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "uploadicon")
    }
    
    func selectAndUpload2(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String] //[kUTTypeMovie as String]
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func selectAndUpload(_ sender: UIButton) {
        let pickerController = DKImagePickerController()
        
//        pickerCon
         pickerController.assetType = .allVideos
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            print("didSelectAssets")
            print(assets)
            assets.forEach { asset in
                self.uploadAsset(dk_asset: asset)
            }
        }
        
//        self.presentViewController(pickerController, animated: true) {}
        self.present(pickerController, animated: true)
    }
    
    func storeFilenameInDB(metadata: FIRStorageMetadata) {
        
        let downloadURL = metadata.downloadURL()
        
        let ref = FIRDatabase.database().reference()
        let key = ref.child("users").childByAutoId().key
        
        var dictionaryUser: [String: String] = ["":""]
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let result = formatter.string(from: date)

        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            // The user's ID, unique to the Firebase project.
            // Do NOT use this value to authenticate with your backend server,
            // if you have one. Use getTokenWithCompletion:completion: instead.
            let uid = user.uid
            let email = user.email
            
            dictionaryUser = [
                "uid": uid,
                "userName": email!,
                "imageUrl": downloadURL?.absoluteString ?? "",
                "path": metadata.path!,
                "created": result
            ]
        }
        
        let childUpdates = ["/users/\(key)": dictionaryUser]
        ref.updateChildValues(childUpdates, withCompletionBlock: { (error, ref) -> Void in
            //save
        })
        
    }
    
    func uploadAsset(dk_asset: DKAsset){

        dk_asset.fetchAVAssetWithCompleteBlock({(asset: AVAsset?, info: [AnyHashable : Any]?) in
            let asset = asset as? AVURLAsset
            do {
                let video = try NSData(contentsOf: (asset?.url)!, options: .mappedIfSafe)
                self.uploadData(data: video)
            } catch {
                print(error)
                return
            }

        })
        
        // OLD Method - may need to use later if we use a different image picker?
        
//        let phAsset = dk_asset.originalAsset
        
//        let manager = PHImageManager()
//        manager.requestAVAsset(forVideo: phAsset!, options: nil, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
//            DispatchQueue.main.async(execute: {
//
//                let asset = asset as? AVURLAsset
//
//                do {
//                let video = try NSData(contentsOf: (asset?.url)!, options: .mappedIfSafe)
//                    self.uploadData(data: video)
//                } catch {
//                    print(error)
//                    return
//                }
//            })
//        })
        
    }
    
    func uploadData(data: NSData){
        let storage = FIRStorage.storage()
        // Create a root reference
        let storageRef = storage.reference()
        
        FIRAnalytics.logEvent(withName: "upload_started", parameters: nil)
        

        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        let fileExtension = ".mp4"
        // Create a reference to the file you want to upload
        let filePath = FIRAuth.auth()!.currentUser!.uid +
        "/\(year)-\(month)/\(self.formattedDate())\(fileExtension)"
        
        let riversRef = storageRef.child(filePath)
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = riversRef.put(data as Data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            if let error = error {
                print("Error uploading: \(error)")
                DispatchQueue.main.async {
                    self.urlTextView.text = "Upload Failed"
                }
                return
            }
            self.uploadSuccess(metadata, storagePath: filePath)
            
            // Metadata contains file metadata such as size, content-type, and download URL.
            //            let downloadURL = metadata.downloadURL
        }
        
        // Add a progress observer to an upload task
        uploadTask.observe(.progress) { snapshot in
            // A progress event occured
            NSLog("\(snapshot)")
            //            var progressFraction = snapshot.progress?.fractionCompleted ?? 0.0
            //            progressFraction = (progressFraction * 100).rounded()
            //
            //            let progressString = String(describing: progressFraction)
            //            self.progressLabel.text = "\(progressString)%"
            self.myTableView.reloadData()
        }
        
        self.files.append(uploadTask)
        self.myTableView.reloadData()

    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        
        let mediaType = info[UIImagePickerControllerMediaType] as? String
        
        let storage = FIRStorage.storage()
        
        // Create a root reference
        let storageRef = storage.reference()
        
        // Data in memory
        var data = Data()
        var fileExtension = ""
        
        if "public.image" == mediaType {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            data = UIImageJPEGRepresentation(image, 0.8)!
            fileExtension = ".jpg"
        }
         if "public.movie" == mediaType {
//            let asset = AVAsset(url: info[UIImagePickerControllerReferenceURL] as! URL)
//            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
//            
//            var time = asset.duration
//            time.value = min(time.value, 2)
//            
//            do {
//                let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
//                let image = UIImage(cgImage: imageRef)
//            } catch {
//                print("error")
////                return nil
//            }
            
            let videoPath = info[UIImagePickerControllerMediaURL] as! URL
            if let videoData = NSData(contentsOf: videoPath) as Data? {
                data = videoData
            }
            fileExtension = ".mp4"
        }
        
        FIRAnalytics.logEvent(withName: "upload_started", parameters: nil)
        
        
        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        // Create a reference to the file you want to upload
        let filePath = FIRAuth.auth()!.currentUser!.uid +
        "/\(year)-\(month)/\(self.formattedDate())\(fileExtension)"

        let riversRef = storageRef.child(filePath)
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = riversRef.put(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            if let error = error {
                print("Error uploading: \(error)")
                self.urlTextView.text = "Upload Failed"
                return
            }
            self.uploadSuccess(metadata, storagePath: filePath)

            // Metadata contains file metadata such as size, content-type, and download URL.
//            let downloadURL = metadata.downloadURL
        }
        
        // Add a progress observer to an upload task
        let progressItem = uploadTask.observe(.progress) { snapshot in
            // A progress event occured
            NSLog("\(snapshot)")
//            var progressFraction = snapshot.progress?.fractionCompleted ?? 0.0
//            progressFraction = (progressFraction * 100).rounded()
//            
//            let progressString = String(describing: progressFraction)
//            self.progressLabel.text = "\(progressString)%"
            self.myTableView.reloadData()
        }
        
//        uploadTask.snapshot.progress
        
        self.files.append(uploadTask)
        self.myTableView.reloadData()
        
    }
    
    func formattedDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func uploadSuccess(_ metadata: FIRStorageMetadata, storagePath: String) {
        print("Upload Succeeded!")
        
        
        // store downloadURL in db
        
        self.storeFilenameInDB(metadata: metadata)

        FIRAnalytics.logEvent(withName: "upload_complete", parameters: nil)
        self.progressLabel.text = "Upload done!"
    }
    
    private var files = [FIRStorageUploadTask]() //["First","Second","Third"]
    private var myTableView: UITableView!
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("Num: \(indexPath.row)")
//        print("Value: \(files[indexPath.row])")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
//        cell.textLabel!.text = "\(files[indexPath.row])"
        let snapshot = files[indexPath.row].snapshot
        var progressFraction = snapshot.progress?.fractionCompleted ?? 0.0
        let progressFloat = Float(progressFraction)
        progressFraction = (progressFraction * 100).rounded()


//        snapshot.reference.storage.
        NSLog("uploaded date: \(snapshot.metadata?.timeCreated)")
        
        
//        let progressBar = GradientProgressBar(progressViewStyle: UIProgressViewStyle)
//        progressBar.frame = cell.frame
//        progressBar.setProgress(progressFloat, animated: true)
        let progressBar = UIProgressView(frame: cell.frame)
        progressBar.progress = progressFloat
        progressBar.frame.origin.y = 0
        progressBar.frame.origin.x = 0
//        progressBar.frame.size.width = progressBar.frame.width - 20

//        progressBar = GradientProgressBar
        cell.contentView.addSubview(progressBar)
        cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "uploadicon"))
        
        
        let progressString = String(describing: progressFraction)
        
        NSLog("\(snapshot.metadata?.size)")
        cell.textLabel!.text = "Uploading file: \(progressString)%"
        
        if snapshot.status == .success {
            //            progressBar.isHidden = true
            progressBar.removeFromSuperview()
            cell.textLabel!.text = "Upload successful."
            cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "tick"))
            
        }
        
        // TODO: Works on all phone sizes
        cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        
        
        return cell
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(files, forKey: "files")
        NSLog("restore")
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        if let filesData = coder.decodeObject(forKey: "files") as? [FIRStorageUploadTask] {
            files = filesData
        }
        NSLog("destore")
        super.decodeRestorableState(with: coder)
    }
}

extension UploadViewController: UIViewControllerRestoration {
    
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        let vc = UploadViewController()
        return vc
    }
}
