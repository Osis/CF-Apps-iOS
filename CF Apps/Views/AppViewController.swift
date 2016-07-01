import Foundation
import UIKit
import Alamofire
import DATAStack
import Sync
import SwiftyJSON
import SafariServices

class AppViewController: UIViewController {
    @IBOutlet var servicesTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet var instancesTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var diskLabel: UILabel!
    @IBOutlet var memoryLabel: UILabel!
    @IBOutlet var buildpackLabel: UILabel!
    @IBOutlet var commandLabel: UILabel!
    @IBOutlet var servicesTableView: UITableView!
    @IBOutlet var instancesTableView: UITableView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var browseButton: UIBarButtonItem!
    
    var dataStack: DATAStack?
    var app: CFApp?
    var refreshControl: UIRefreshControl!
    var url: NSURL?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        self.browseButton.enabled = false
        addRefreshControl()
        loadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "logs") {
            let controller = segue.destinationViewController as! LogsViewController
            controller.appGuid = self.app!.guid
        } else if (segue.identifier == "events") {
            let controller = segue.destinationViewController as! EventsViewController
            controller.appGuid = self.app!.guid
        }
    }
    
    func loadData() {
        fetchSummary()
        
        if (app!.statusImageName() == "started") {
            fetchStats()
        } else {
            hideInstancesTable()
        }
    }
    
    func hideInstancesTable() {
        self.instancesTableView.hidden = true
        self.instancesTableHeightConstraint.constant = 0
    }
    
    func fetchSummary() {
        servicesTableView.tableFooterView = LoadingIndicatorView()
        let urlRequest = CFRequest.AppSummary(app!.guid)
        CFApi().request(urlRequest,
            success: { (json) in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.handleSummaryResponse(json)
                    self.refreshControl.endRefreshing()
                }
            },
            error: { (statusCode) in
                print([statusCode])
        })
    }
    
    func addRefreshControl() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Refresh Summary")
        self.refreshControl.addTarget(self, action: #selector(AppViewController.loadData), forControlEvents: UIControlEvents.ValueChanged)
        self.scrollView.insertSubview(self.refreshControl, atIndex: 0)
    }
    
    func handleSummaryResponse(json: JSON) {
        let delegate = servicesTableView.delegate as! ServicesViewController
        delegate.services = json["services"]
        
        CFStore(dataStack: self.dataStack!).syncApp(json.dictionaryObject!, guid: self.app!.guid, completion: { (error) in
            self.setSummary(self.app!.guid)
        })
        
        dispatch_async(dispatch_get_main_queue(), {
            self.servicesTableView.tableFooterView = nil
            self.servicesTableView.reloadData()
            let height = self.servicesTableView.contentSize.height
            self.servicesTableHeightConstraint.constant = height
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
    }
    
    func fetchStats() {
        instancesTableView.tableFooterView = LoadingIndicatorView()
        
        let urlRequest = CFRequest.AppStats(app!.guid)
        CFApi().request(urlRequest,
            success: { (json) in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.handleStatsResponse(json)
                }
            },
            error: { (statusCode) in
                print([statusCode])
        })
    }
    
    func handleStatsResponse(json: JSON) {
        showInstances(json)
        toggleBrowsing(json)
    }
    
    func showInstances(json: JSON) {
        let delegate = instancesTableView.delegate as! InstancesViewConroller
        delegate.instances = json
        dispatch_async(dispatch_get_main_queue(), {
            self.instancesTableView.tableFooterView = nil
            self.instancesTableView.reloadData()
            let height = self.instancesTableView.contentSize.height
            self.instancesTableHeightConstraint.constant = height
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
    }
    
    func toggleBrowsing(json: JSON) {
        if let urlString = Instance(json: json["0"]).uri() {
            dispatch_async(dispatch_get_main_queue()) {
                self.url = NSURL(string: urlString)
                self.browseButton.enabled = true
                self.browseButton.customView?.alpha = 1
            }
        } else {
            self.browseButton.enabled = false
        }
    }
    
    func setSummary(guid: String) {
        do {
            self.app = try CFStore(dataStack: self.dataStack!).fetchApp(app!.guid)
            
            nameLabel.text = app!.name
            stateLabel.text = app!.state
            buildpackLabel.text = app!.activeBuildpack()
            memoryLabel.text = app!.formattedMemory()
            diskLabel.text = app!.formattedDiskQuota()
            commandLabel.text = app!.command
        } catch {
            self.app = nil
            nameLabel.text = "Error"
        }
    }
    
    @IBAction func browseButtonPushed(sender: UIBarButtonItem) {
        let safariController = SFSafariViewController(URL: self.url!)
        presentViewController(safariController, animated: true, completion: nil)
    }
}
