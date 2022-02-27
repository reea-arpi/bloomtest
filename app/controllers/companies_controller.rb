class CompaniesController < ApplicationController
  def index
    @companies = get_companies_from_api
    @saved_companies = Company.pluck(:company_number)
  end

  def favorite_companies
    @companies = Company.all
    @saved_companies = []
  end

  def save_companies
    if params[:selected_company]
      records = []
      saved_companies = Company.pluck(:company_number)
      companies = get_companies_from_api
      companies['items'].each do |company|
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

      Company.insert_all(records) if records.compact.length > 0
      message = "#{records.compact.length} companies were saved"
    else
      message = "No company were selected"
    end
    redirect_to root_path, alert: message
  end

  def delete_companies
    Company.where(company_number: params[:selected_company]).delete_all
    redirect_to favorite_companies_path, alert: "#{params[:selected_company].length} companies were removed"
  end

  private

  def get_companies_from_api
    return nil unless params[:search_string]
    companies_house_api = ChApiService.new
    companies_house_api.company_search(params[:search_string]) rescue nil
  end
end
