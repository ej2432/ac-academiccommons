require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  let(:empty_response) { Blacklight::Solr::Response.new({}, {}) }

  describe "#index" do
    context "format: rss" do
      context "search query" do
        let(:query) { 'alice' }
        let(:expected_params) do
          {
            page: nil,
            qt: 'search',
            q: query,
            fq: ["has_model_ssim:\"info:fedora/ldpd:ContentAggregator\""],
            sort: 'record_creation_date desc',
            rows: '500',
            fl: 'title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet'
          }
        end

        it "correctly creates solr query" do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', hash_including(expected_params))
            .and_return(empty_response)
          get :index, q: query, format: 'rss'
        end

        it 'returns rss feed with appropriate information'
      end

      context "search query with row limit" do
        let(:query) { 'alice' }
        let(:expected_params) do
          {
             page: nil,
             qt: 'search',
             q: query,
             fq: ["has_model_ssim:\"info:fedora/ldpd:ContentAggregator\""],
             sort: 'record_creation_date desc',
             rows: '10',
             fl: 'title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet'
          }
        end

        it "correctly creates solr query" do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', hash_including(expected_params))
            .and_return(empty_response)
          get :index, q: query, rows: '10', format: 'rss'
        end
      end

      context 'when filtering by organization using :f' do
        # /catalog.rss?f%5Borganization_facet%5D%5B%5D=Teachers+College&sort=record_creation_date+desc
        let(:expected_params) do
          {
            "qt" => "search",
            "facet.field" =>
              ["author_facet", "department_facet", "subject_facet", "genre_facet", "pub_date_facet", "series_facet", "language", "type_of_resource_facet"],
            "facet.query" => [],
            "facet.pivot" => [],
            "fq"=> ["has_model_ssim:\"info:fedora/ldpd:ContentAggregator\"", "{!raw f=organization_facet}Teachers College"],
            "hl.fl" => [],
            "rows" => 100,
            "q" => "",
            "facet" => true,
            "f.author_facet.facet.limit"=>3,
            "f.department_facet.facet.limit"=>3,
            "f.subject_facet.facet.limit"=>3,
            "f.genre_facet.facet.limit"=>3,
            "f.pub_date_facet.facet.limit"=>3,
            "f.series_facet.facet.limit"=>3,
            "sort"=>"record_create_date desc",
            "fl" => "title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet"
          }
        end

        it 'correctly creates solr query' do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', expected_params)
            .and_return(empty_response)
          get :index, f: { 'organization_facet' => ['Teachers College'] },
               sort: 'record_create_date desc', format: 'rss'
        end
      end

      context 'facets by department'

      context "filters users by uni" do
        let(:uni_filter) { 'author_uni:abc123' }
        let(:expected_params) do
          {
            qt: 'search',
            fq: [uni_filter, "has_model_ssim:\"info:fedora/ldpd:ContentAggregator\""],
            page: nil,
            q: '',
            sort: 'record_creation_date desc',
            rows: '500',
            fl: 'title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet'
          }
        end

        it 'merges :fq parameter' do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', hash_including(expected_params))
            .and_return(empty_response)
          get :index, fq: 'author_uni:abc123', format: 'rss'
        end
      end
    end
  end

  describe '#custom_results' do
    context 'when :fq in request' do
      let(:uni_filter) { 'author_uni:abc123' }
      let(:expected_params) do
        {
          qt: 'search',
          fq: [uni_filter, "has_model_ssim:\"info:fedora/ldpd:ContentAggregator\""],
          page: nil,
          q: '',
          sort: 'record_creation_date desc',
          rows: '500',
          fl: 'title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet'
        }
      end

      before :each do
        allow(@controller).to receive(:params).and_return( { fq: uni_filter } )
      end

      it 'correctly merges :fq parameters' do
        expect(@controller.repository).to receive(:send_and_receive)
          .with('select', expected_params)
          .and_return(empty_response)
        @controller.instance_eval { custom_results }
      end
    end
  end
end