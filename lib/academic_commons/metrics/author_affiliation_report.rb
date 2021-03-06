require 'csv'

module AcademicCommons
  module Metrics
    module AuthorAffiliationReport
      def self.generate_csv(current_user = nil)
        # Usage stats for all items
        solr_params = { q: nil } # sort by id?

        usage_stats = UsageStatistics.new(solr_params: solr_params).calculate_lifetime

        headers = [
          'doi', 'legacy id', 'lifetime downloads', 'lifetime views',
          'department ac', 'genre', 'creation date', 'multi-author count',
          'author uni', 'author name', 'ldap author title',
          'ldap organizational unit'
        ]

        ldap_user = {} # Caching ldap user details.
        rows = []

        ldap = Cul::LDAP.new

        usage_stats.each do |item_stats|
          # retrieve entire solr document
          results = AcademicCommons.search { |p| p.id(item_stats.id) }

          if results.docs.count == 1
            doc = results.docs.first
          else
            Rails.logger.warn("Document not found for #{item_stats.id}")
            next
          end

          start_of_row = [
            doc[:cul_doi_ssi],
            doc[:fedora3_pid_ssi],
            item_stats.get_stat(Statistic::DOWNLOAD, LIFETIME),
            item_stats.get_stat(Statistic::VIEW, LIFETIME),
            doc.fetch(:department_ssim, []).join(', '),
            doc.fetch(:genre_ssim, []).join(', '),
            doc[:system_create_dtsi]
          ]

          author_count = 1

          # For each author_uni_ssim add a row...
          doc.fetch(:author_uni_ssim, []).each do |uni|
            row = CSV::Row.new(headers, start_of_row)

            row['author uni'] = uni
            row['multi-author count'] = author_count

            # query ldap for more information about this author
            person = ldap_user.fetch(uni, nil)
            if person.nil?
              person = ldap.find_by_uni(uni)
              ldap_user[uni] = person
            end

            row['author name'] = person&.name
            row['ldap author title'] = person&.title
            row['ldap organizational unit'] = person&.organizational_unit

            author_count += 1

            rows.append(row)
          end

          # For each author that does not have a author, row with just basic item information
          total_authors = doc.fetch(:author_ssim, []).count
          while(total_authors >= author_count) do
            row = CSV::Row.new(headers, start_of_row)
            row['multi-author count'] = author_count

            author_count += 1
            rows.append(row)
          end

        end

        timestamp = Time.current.localtime.strftime('%FT%R')

         csv =  CSV.generate_line(['Author Affiliation Report'])
         csv << CSV.generate_line(['Report Generated By:', current_user || 'N/A', 'Report Generated:', timestamp])
         csv << CSV.generate_line([])
         csv << CSV::Table.new(rows).to_s
         csv
      end
    end
  end
end
