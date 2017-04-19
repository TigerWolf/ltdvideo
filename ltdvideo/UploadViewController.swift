import Firebase
import UIKit
import Photos // needed?
import MobileCoreServices
import DZNEmptyDataSet
import GradientProgressBar

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var progressLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    var urlTextView: UITextField!
//    var storageRef: FIRStorageReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(selectAndUpload))

        
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
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Upload a file. ")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Click the + to start.")
    }
    
    func selectAndUpload(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String] //[kUTTypeMovie as String]
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)

//        userPhoto.image = image
        
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
            let videoPath = info[UIImagePickerControllerMediaURL] as! URL
            if let videoData = NSData(contentsOf: videoPath) as Data? {
                data = videoData
            }
            fileExtension = ".mp4"
        }
        
        // Create a reference to the file you want to upload
        let filePath = FIRAuth.auth()!.currentUser!.uid +
        "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(self.formattedDate())\(fileExtension)"

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


        
        
        
//        let progressBar = GradientProgressBar(progressViewStyle: UIProgressViewStyle)
//        progressBar.frame = cell.frame
//        progressBar.setProgress(progressFloat, animated: true)
        let progressBar = UIProgressView(frame: cell.frame)
        progressBar.progress = progressFloat
        progressBar.frame.origin.y = 20
        progressBar.frame.origin.x = 10
        progressBar.frame.size.width = progressBar.frame.width - 20

//        progressBar = GradientProgressBar
        cell.contentView.addSubview(progressBar)
        
        let progressString = String(describing: progressFraction)
        if snapshot.status == .success {
            progressBar.isHidden = true
            cell.textLabel!.text = "Upload successful."
            
            
        }
        
        
//        cell.textLabel!.text = "Uploading file: \(progressString)%"
        return cell
    }
}
