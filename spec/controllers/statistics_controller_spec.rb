require 'spec_helper'

describe StatisticsController, :type => :controller do
  before do
    @non_admin = double(User)
    allow(@non_admin).to receive(:admin).and_return(false)
  end
  # require_admin
  [:all_author_monthlies, :author_monthly, :search_history, :school_docs_size,
   :single_pid_count, :single_pid_stats, :school_stats, :stats_by_event,
   :docs_size_by_query_facets, :facetStatsByEvent, :common_statistics_csv,
   :generic_statistics, :school_statistics, :send_csv_report].each do |action|
    describe action do
      context "without being logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end
        it "redirects to new_user_session_path" do
          get action
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(new_user_session_url)
        end
      end
      context "logged in as a non-admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@non_admin)
        end
        it "fails" do
          get action
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(access_denied_url)
        end
      end
    end
  end
  # require_user
  describe 'unsubscribe_monthly' do
    context "without being logged in" do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end
      it "redirects to new_user_session_path" do
        get :unsubscribe_monthly
        expect(response.status).to eql(302)
        expect(response.headers['Location']).to eql(new_user_session_url)
      end
    end
    context "logged in as a non-admin user" do
      before do
        allow(controller).to receive(:current_user).and_return(@non_admin)
        allow(controller).to receive(:statistical_reporting)
      end
      it "succeeds" do
        get :unsubscribe_monthly
        expect(response.status).to eql(302)
        expect(response.headers['Location']).to eql(root_url)
      end
    end
  end

  # require_user
  [:usage_reports, :statistical_reporting].each do |action|
    describe action do
      context "without being logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end
        it "redirects to new_user_session_path" do
          get action
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(new_user_session_url)
        end
      end
      context "logged in as a non-admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@non_admin)
          allow(controller).to receive(:statistical_reporting)
        end
        it "succeeds" do
          get action
          expect(response.status).to eql(200)
        end
      end
    end
  end
end