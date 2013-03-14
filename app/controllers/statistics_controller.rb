class StatisticsController < ApplicationController
  layout "application"
  before_filter :require_admin, :except => [:unsubscribe_monthly]
  include Blacklight::SolrHelper
  include StatisticsHelper

  def unsubscribe_monthly
    author_id = params[:author_id]

    if author_id && author_id.to_s.crypt("xZ") == params[:chk]
      epref = EmailPreference.find_by_author(author_id)
      if epref
        epref.update_attributes(:monthly_opt_out => true)
      else
        EmailPreference.create!(:author => author_id, :monthly_opt_out => true)
      end
    else
      error=true
    end

    if error 
      flash[:error] = "There was an error with your unsubscribe request"
    else
      flash[:notice] = "Unsubscribe request successful"
    end

    redirect_to root_url
  end

  def all_author_monthlies
    
    params[:email_template] ||= "Normal"

    ids = Blacklight.solr.find(:per_page => 100000, :page => 1, :fl => "author_uni")["response"]["docs"].collect { |f| f["author_uni"] }.flatten.compact.uniq - EmailPreference.find_all_by_monthly_opt_out(true).collect(&:author)

    alternate_emails = Hash[EmailPreference.find(:all, :conditions => "email is NOT NULL").collect { |ep| [ep.author, ep.email] }.flatten]
    @authors = ids.collect { |id| {:id => id, :email => alternate_emails[id] || "#{id}@columbia.edu"}}

    if params[:commit] == "Send"
      @authors.each do |author|
        author_id = author[:id]
        startdate = Date.parse(params[:month] + " " + params[:year])

        results, stats, totals  = get_monthly_author_stats(:startdate => startdate, :include_zeroes => false, :author_id => author_id)

        if totals.values.sum != 0 || params[:include_zeroes]
    
          case params[:email_template]
          when "Normal"
            Notifier.author_monthly(author[:email], author_id, startdate, results, stats, totals,request).deliver
          else
            Notifier.author_monthly_first(author[:email], author_id, startdate, results, stats, totals,request).deliver

          end  
        end
      end
    end
  end

 def author_monthly
   statistical_reporting
   render :template => 'statistics/statistical_reporting'
 end
 
 def statistical_reporting  
  
    if (params[:month_from].nil? || params[:month_to].nil? || params[:year_from].nil? || params[:year_to].nil?)
      
      params[:month_from] = "Apr"
      params[:year_from] = "2011"
      params[:month_to] = (Date.today - 1.months).strftime("%b")
      params[:year_to] = (Date.today).strftime("%Y")
      
      params[:include_zeroes] = true
      
    end
      
      
      startdate = Date.parse(params[:month_from] + " " + params[:year_from])
      enddate = Date.parse(params[:month_to] + " " + params[:year_to])
     
      if params[:commit].in?('View', "Email", "Get Usage Stats")
      
        @results, @stats, @totals =  get_author_stats(startdate, 
                                                      enddate,
                                                      params[:search_criteria],
                                                      nil,
                                                      params[:include_zeroes],
                                                      params[:facet],
                                                      params[:include_streaming_views]
                                                      )
        if (@results.size == 0)    
          setMessageAndVariables 
          return
        end
        
        if params[:commit] == "Email"
          case params[:email_template]
          when "Normal"
            Notifier.author_monthly(params[:email_destination], params[:search_criteria], startdate, enddate, @results, @stats, @totals, request, params[:include_streaming_views]).deliver
          else 
            Notifier.author_monthly_first(params[:email_destination], params[:search_criteria], startdate, enddate, @results, @stats, @totals, request, params[:include_streaming_views]).deliver
          end  
        end
      end
      
      if params[:commit] == "Download CSV report"
        csv_report = cvsReport( startdate,
                                enddate,
                                params[:search_criteria],
                                params[:include_zeroes],
                                params[:recent_first],
                                params[:facet],
                                params[:include_streaming_views]
                               )
                               
         if(csv_report != nil)
           send_data csv_report, :type=>"application/csv", :filename=>params[:search_criteria] + "_monthly_statistics.csv" 
         end                        
      end 
  end

  def search_history
    @search_types = [["Item",'id'],["UNI","author_uni"],["Genre","genre_search"]]
    params[:event] ||= ['View']

    six_months_ago = Date.today - 6.months
    next_month = Date.today + 1.months
    params[:start_date] ||= Date.civil(six_months_ago.year, six_months_ago.month).to_formatted_s(:datepicker)
    params[:end_date] ||= (Date.civil(next_month.year, next_month.month) - 1.day).to_formatted_s(:datepicker)

    if params[:commit] == "View Statistics"

      unless params[:search_value]
        flash[:warning] = "You must specify a search value."

      else
        @fq = params[:search_type] + ":" + params[:search_value].gsub(/:/,'\\:')

        @ids = Blacklight.solr.find(:per_page => 100000, :sort => "title_display asc" , :fq => @fq, :fl => 'id', :page => 1)["response"]["docs"].collect { |r| r['id'] }

        @results = Statistic.count_intervals(:identifier => @ids, :event => params[:event], :start_date => DateTime.parse(params[:start_date]), :end_date => DateTime.parse(params[:end_date]), :group => params[:group].downcase.to_sym)
        date_format = ("chart_" + params[:group]).downcase.to_sym

        chart_params = {:size => "700x400", :title => "Statistics for #{params[:id]}|#{params[:start_date]} to #{params[:end_date]}", :axis_with_labels => "x,y,x", :data => [], :legend => [], :bg => "F6F6F6", :line_colors => [], :custom => "chxs=0,676767,11.5,0,lt,676767"}
          events = @results.keys
        data_hash = Hash.new { |h,k| h[k] = [] }
        max_y = (([@results.values.collect { |s| s.values }.flatten.max.to_i].max))    
        y_labels = (0..1).collect { |part| part * max_y / 1 }

        dates = @results.values.collect { |s| s.keys}.flatten.uniq.sort
        formatted_dates = dates.collect { |d| d.to_formatted_s(date_format) }
        dates_top = []
        dates_bottom = []

        legend_hash = { 'View' => "Views", 'Download' => "Downloads" }
        colors_hash = { 'View' => "0022FF", 'Download' => "FF00CC" }

        if formatted_dates.length > 15
          formatted_dates.each_with_index do |date, i|
            dates_top << (i % 2 == 0 ? date : "")
            dates_bottom << (i % 2 == 0 ? "" : date)
          end
          chart_params[:axis_labels] = [dates_top, y_labels, dates_bottom]
        else
          chart_params[:axis_labels] = [formatted_dates, y_labels, []]
        end

        dates.each do |date|
          events.each do |event|
            val = @results[event][date] 
            val = val.nil? || val == {} ? 0 : val
            data_hash[event] << val
          end
        end

        events.each do |event|
          chart_params[:data] << data_hash[event]
          chart_params[:legend] << legend_hash[event]
          chart_params[:line_colors] << colors_hash[event]
        end

        chart_params[:line_colors] = chart_params[:line_colors].join(",")
        if params[:group] == "Year"
          chart_params[:custom] += "&chma=150,25,25,25"
          @chart = Gchart.bar(chart_params.merge(:stacked => false))
        else
          chart_params[:custom] += "&chma=50,25,25,25"
          @chart = Gchart.line(chart_params)
        end
      end
    end


  end

  private


  def get_monthly_author_stats(options = {})
  startdate = options[:startdate]
    author_id = options[:author_id]
    enddate = startdate + 1.month

    results = Blacklight.solr.find(:per_page => 100000, :sort => "title_display asc" , :fq => "author_uni:#{author_id}", :fl => "title_display,id", :page => 1)["response"]["docs"]
    ids = results.collect { |r| r['id'].to_s.strip }
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    download_ids = Hash.new { |h,k| h[k] = [] } 
    ids.each do |doc_id|
      download_ids[doc_id] |= fedora_server.item(doc_id).listMembers.collect(&:pid)
#      download_ids[doc_id] |=  fedora_server.item(doc_id).describedBy.collect(&:pid)
    end
    stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 }}
    totals = Hash.new { |h,k| h[k] = 0 }


    stats['View'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", ids,startdate, enddate])

    stats_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", download_ids.values.flatten,startdate, enddate])
    download_ids.each_pair do |doc_id, downloads|

      stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
    end


    stats['View Lifetime'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?)", ids])


    stats_lifetime_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?)" , download_ids.values.flatten])
    download_ids.each_pair do |doc_id, downloads|

      stats['Download Lifetime'][doc_id] = downloads.collect { |download_id| stats_lifetime_downloads[download_id] || 0 }.sum
    end
    stats.keys.each { |key| totals[key] = stats[key].values.sum }


stats['View'] = convertOrderedHash(stats['View'])
stats['View Lifetime'] = convertOrderedHash(stats['View Lifetime'])

    results.reject! { |r| (stats['View'][r['id'][0]] || 0) == 0 &&  (stats['Download'][r['id']] || 0) == 0 } unless params[:include_zeroes]
    results.sort! do |x,y|
      result = (stats['Download'][y['id']] || 0) <=> (stats['Download'][x['id']] || 0) 
      result = x["title_display"] <=> y["title_display"] if result == 0
      result
    end

    return results, stats, totals

  end

def convertOrderedHash(ohash)
	a =  ohash.to_a
	oh = {}
	a.each{|x|  oh[x[0]] = x[1]} 
	return oh
end


  ##################
  # Config-lookup methods. Should be moved to a module of some kind, once
  # all this stuff is modulized. But methods to look up config'ed values,
  # so logic for lookup is centralized in case storage methods changes.
  # Such methods need to be available from controller and helper sometimes,
  # so they go in controller with helper_method added.
  # TODO: Move to a module, and make them look inside the controller
  # for info instead of in global Blacklight.config object!
  ###################

  # Look up configged facet limit for given facet_field. If no
  # limit is configged, may drop down to default limit (nil key)
  # otherwise, returns nil for no limit config'ed. 
  def facet_limit_for(facet_field)
    limits_hash = facet_limit_hash
    return nil unless limits_hash

    limit = limits_hash[facet_field]
    limit = limits_hash[nil] unless limit

    return limit
  end
  helper_method :facet_limit_for
  # Returns complete hash of key=facet_field, value=limit.
  # Used by SolrHelper#solr_search_params to add limits to solr
  # request for all configured facet limits.
  def facet_limit_hash
    Blacklight.config[:facet][:limits]           
  end
  helper_method :facet_limit_hash
end
