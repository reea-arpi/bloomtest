class CompaniesController < ApplicationController
  # /
  def index
    # Search for companies from API
    @companies = get_companies_from_api

    # Get saved Companies numbers
    @saved_companies = Company.pluck(:company_number)
  end

  # /favorite_companies
  def favorite_companies
    # Gather all saved companies
    @companies = Company.all

    # Init saved_companies with empty Array
    @saved_companies = []
  end

  # /save_companies
  # save selected companies
  def save_companies
    # If there is any selected company
    if params[:selected_company]
      # Init reccord array
      records = []

      # get already saved companies, to prevent double records
      saved_companies = Company.pluck(:company_number)

      # get companies from API
      companies = get_companies_from_api

      # iterate through companies results
      companies['items'].each do |company|
        # add the company detail to records array
        # if it is a company selected by the user
        # if it is a new company record
        records << {
          title:            company['title'],
          company_number:   company['company_number'],
          company_status:   company['company_status'],
          description:      company['description'],
          address_snippet:  company['address_snippet'],
          address:          company['address'],
          company_type:     company['company_type'],
          date_of_creation: company['date_of_creation'],
          created_at: Time.now,
          updated_at: Time.now,
        } if params[:selected_company].include?(company['company_number']) && !saved_companies.include?(company['company_number'])
      end if companies['items']

      # insert all new data to Company table, if there is any
      Company.insert_all(records) if records.compact.length > 0
      message = "#{records.compact.length} companies were saved"
    else
      message = "No company were selected"
    end
    # redirect to root path
    redirect_to root_path(search_string: params[:search_string]), alert: message
  end

  def delete_companies
    # delete all selected company
    Company.where(company_number: params[:selected_company]).delete_all

    # redirect to favorite company page
    redirect_to favorite_companies_path, alert: "#{params[:selected_company].length} companies were removed"
  end

  private

  def get_companies_from_api
    # if there is nothing to search for, why bother
    return nil unless params[:search_string]

    # Init API Service
    companies_house_api = ChApiService.new

    # search for the required string
    companies_house_api.company_search(params[:search_string]) rescue nil
  end
end
