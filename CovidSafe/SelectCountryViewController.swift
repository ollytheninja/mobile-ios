//
//  SelectCountryViewController.swift
//  CovidSafe
//
//  Copyright © 2020 Australian Government. All rights reserved.
//

import UIKit
import FlagKit
import SafariServices

struct Country {
    var name: String!
    var isoCode: String!
    var phoneCode: String!
    var flag: Flag?
}

class SelectCountryViewController: UITableViewController, UISearchResultsUpdating {
    
    let searchController = UISearchController(searchResultsController: nil)
    let AU_OPTIONS_KEY = "OptionsForAustralia"

    var countriesTableData: Dictionary<String, [Country]> = [:]
    let countriesSortedByName = CountriesData.countries.sorted(by: { (country1, country2) -> Bool in
        country1.name < country2.name
    })
    var filteredCountriesTableData: [Country] = []
    var countrySelectionDelegate: CountrySelectionDelegate?
    
    var countriesSectionTitles: [String] = []
    var isSearchBarEmpty = true
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "SelectCountryTitle".localizedString()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        self.navigationItem.titleView = label
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor.white
        //Set search bar
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
            searchController.hidesNavigationBarDuringPresentation = false
            searchController.dimsBackgroundDuringPresentation = false
            automaticallyAdjustsScrollViewInsets = false
        }
        
        // Create the data source of the countries table
        let norfolkIslandCountry = Country(name: "Country_AU2".localizedString(), isoCode: "AU2", phoneCode: "672", flag: Flag(countryCode: "AU"))
        let australiaCountry = Country(name: "Country_AU".localizedString(), isoCode: "AU", phoneCode: "61", flag: Flag(countryCode: "AU"))
        countriesTableData.updateValue([australiaCountry, norfolkIslandCountry], forKey: AU_OPTIONS_KEY)
        countriesSectionTitles.append(" ")
        
        for country in countriesSortedByName {
            let initial = String(country.name[country.name.startIndex])
            var sectionCountries: [Country] = countriesTableData[initial] ?? []
            if sectionCountries.count == 0 {
                countriesSectionTitles.append(initial)
            }
            sectionCountries.append(country)
            countriesTableData.updateValue(sectionCountries, forKey: initial)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //this is to show the search bar initially
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            if !UIAccessibility.isVoiceOverRunning {
                navigationItem.hidesSearchBarWhenScrolling = true
            }
        }
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: self.navigationItem.titleView )
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let searchBarText = searchBar.text?.lowercased() ?? ""
        if (searchBarText == "") {
            isSearchBarEmpty = true
            filteredCountriesTableData = []
            tableView.reloadData()
            return
        }
        isSearchBarEmpty = false
        filteredCountriesTableData = countriesSortedByName.filter({ (country) -> Bool in
            let countryName = country.name.lowercased()
            let searchCriteria = searchBarText.lowercased()
            if countryName.contains(searchCriteria) {
                return true
            }
            return false
        })
        tableView.reloadData()
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if !isFiltering {
            return countriesSectionTitles
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var country: Country
        if !isFiltering {
            var sectionIndex = AU_OPTIONS_KEY
            if indexPath.section > 0 {
                sectionIndex = countriesSectionTitles[indexPath.section]
            }
            guard let sectionCountries = countriesTableData[sectionIndex] else {
                return
            }
            country = sectionCountries[indexPath.row]
        } else {
            country = filteredCountriesTableData[indexPath.row]
        }
        countrySelectionDelegate?.setCountry(country: country)
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isFiltering {
            if section == 0 {
                return "AustraliaSectionTitle".localizedString()
            }

            return countriesSectionTitles[section]
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isFiltering {
            var sectionIndex = AU_OPTIONS_KEY
            if section > 0 {
                sectionIndex = countriesSectionTitles[section]
            }
            return countriesTableData[sectionIndex]?.count ?? 0
        } else {
            return filteredCountriesTableData.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if !isFiltering {
            return countriesSectionTitles.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath) as! CountryCellViewCell
        var country: Country
        
        if !isFiltering {
            var sectionIndex = AU_OPTIONS_KEY
            if indexPath.section > 0 {
                sectionIndex = countriesSectionTitles[indexPath.section]
            }
            guard let sectionCountries = countriesTableData[sectionIndex] else {
                return cell
            }
            
            country = sectionCountries[indexPath.row]
        } else {
            country = filteredCountriesTableData[indexPath.row]
        }
        
        cell.countryTitleLabel.text = country.name
        cell.countryPhoneLabel.text = "+\(country.phoneCode ?? "")"
        cell.countryFlagImageView.image = country.flag?.originalImage

        return cell
    }
    
}

class CountryCellViewCell: UITableViewCell {
    
    @IBOutlet weak var countryTitleLabel: UILabel!
    @IBOutlet weak var countryPhoneLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
}
