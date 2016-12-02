require "person_class"
require "item_class"
require "ac_indexing"

module DepositorHelper
  AC_COLLECTION_NAME = 'collection:3'

  def notify_depositors_embargoed_item_added(pids)

    depositors = prepare_depositors_to_notify(pids)

    depositors.each do | depositor |
      logger.info "\n ============ notify_depositors_embargoed_item_added ============="
      logger.info "=== uni: #{depositor.uni}"
      logger.info "=== email: #{depositor.email}"
      logger.info "=== full_name: #{depositor.full_name}"

      depositor.items_list.each do | item |
        logger.info "------ "
        logger.info "------ item.pid: #{item.pid}"
        logger.info "------ item.title: #{item.title}"
        logger.info "------ item.handle: #{item.handle}"
      end

      Notifier.depositor_embargoed_notification(depositor).deliver_now
    end
  end

  def notify_depositors_item_added(pids)
    depositors = prepare_depositors_to_notify(pids)

    # Loops through each depositor and notifies them for each new item now available.
    depositors.each do | depositor |
      logger.info "====== Notifing Depositor of New Item ======"
      logger.info "=== Notifying #{depositor.full_name}(#{depositor.uni}) at #{depositor.email}"

      depositor.items_list.each do | item |
        logger.info "==== For #{item.title}, PID: #{item.pid}, Persistent URL: #{item.handle}"
      end

      Notifier.depositor_first_time_indexed_notification(depositor).deliver_now
    end
  end


  def prepare_depositors_to_notify(pids)
    depositors_to_notify = Hash.new

    pids.each do | pid |

      logger.info "=== Processing depositors for record: #{pid}"

      item = get_item(pid)

      logger.info "=== item created for pid: #{pid}"

      logger.debug "=== item.pid: #{item.pid}"
      logger.debug "=== item.title: #{item.title}"
      logger.debug "=== item.handle: #{item.handle}"
      logger.debug "=== item.authors_uni: #{item.authors_uni.size}"

      item.authors_uni.each do | uni |

        logger.info "=== process uni: #{uni} depositor for pid: #{pid}"

        if(!depositors_to_notify.key?(uni))
          depositor = get_depositor(uni)
          depositors_to_notify.store(uni, depositor)
        end

        depositor = depositors_to_notify[uni]
        depositor.items_list << item

        logger.info "=== process uni: #{uni} depositor for pid: #{pid} === finished"
      end
    end

    logger.info "====== depositors_to_notify.size: #{depositors_to_notify.size}"

    return depositors_to_notify.values
  end

  def get_depositor(uni)
    person = get_person_info(uni)

    (person.email == nil) ?  depositor_email = "#{person.uni}@columbia.edu" : depositor_email = person.email
    if (person.last_name == nil || person.first_name == nil)
       logger.info "==== uni: #{person.uni}  was not found in LDAP ==="
       depositor_name = nil
    else
      depositor_name = "#{person.first_name} #{person.last_name}"

      logger.info "name: #{depositor_name} was found in LDAP"
    end

    person.email = depositor_email
    person.full_name = depositor_name

    return person
  end

  # TODO: Make this into a module.
  def get_person_info(uni)
    entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", uni)) || []
    entry = entry.first

    email = nil
    last_name = nil
    first_name = nil

    if entry
      entry[:mail].kind_of?(Array) ? email = entry[:mail].first.to_s : email = entry[:mail].to_s
      entry[:sn].kind_of?(Array) ? last_name = entry[:sn].first.to_s : last_name = entry[:sn].to_s
      entry[:givenname].kind_of?(Array) ? first_name = entry[:givenname].first.to_s : first_name = entry[:givenname].to_s
    end

    person = Person.new

    person.uni = uni
    person.email = email
    person.last_name = last_name
    person.first_name = first_name

    return person
  end

  def process_indexing(params)
    logger.info "==== started ingest function ==="

    params.each do |key, value|
      logger.info "param: #{key} - #{value}"
    end

    if(params[:cancel])
      existing_time_id = existing_ingest_time_id(params[:cancel])
      if(existing_time_id)
        Process.kill "KILL", params[:cancel].to_i
        File.delete("#{Rails.root}/tmp/#{params[:cancel]}.index.pid")
        log_file = File.open("#{Rails.root}/log/ac-indexing/#{existing_time_id}.log", "a")
        log_file.write("CANCELLED")
        log_file.close
        flash.now[:notice] = "Ingest has been cancelled"
      else
        flash.now[:notice] = "Oh, um, we can't find the process ID #{params[:cancel]}, so we can't cancel it.  It's probably my fault, so I'm really sorry about that."
      end
    end

    # set time
    time = Time.new
    time_id = time.strftime("%Y%m%d-%H%M%S")
    @existing_ingest_pid = nil
    @existing_ingest_time_id = nil

    # clean up temp pid files for indexing runs
    Dir.glob("#{Rails.root}/tmp/*.index.pid") do |tmp_pid_file|
      first_namepart, *rest_namepart = File.basename(tmp_pid_file).split(/\./)
      @existing_ingest_time_id = existing_ingest_time_id(first_namepart)
      if(@existing_ingest_time_id == nil)
        File.delete(tmp_pid_file)
      else
        @existing_ingest_pid = first_namepart
      end
    end

    if(params[:commit] == "Commit" && @existing_ingest_time_id.nil? && !params[:cancel])
      collection = params[:collections].to_s.strip
      unless collection.blank? || (collection == AC_COLLECTION_NAME)
        flash.now[:notice] = "#{collection} is not a collection used by Academic Commons."
        return
      end

      items = params[:items] ? params[:items].gsub(/ /, ";") : ""

      @existing_ingest_pid = Process.fork do
        logger.info "==== started indexing ==="

        indexing_results = ACIndexing::reindex(
          {
            :collections => collection,
            :items => items,
            :overwrite => params[:overwrite],
            :metadata => params[:metadata],
            :fulltext => params[:fulltext],
            :delete_removed => params[:delete_removed],
            :time_id => time_id,
            :executed_by => params[:executed_by] || current_user.uid
          }
        )

        logger.info "===== finished indexing, starting notifications part ==="

        if(params[:notify])
          Notifier.reindexing_results(indexing_results[:errors].size.to_s, indexing_results[:indexed_count].to_s, indexing_results[:new_items].size.to_s, time_id).deliver
        end

        notify_depositors_item_added(indexing_results[:new_items])
      end

      Process.detach(@existing_ingest_pid)
      @existing_ingest_time_id = time_id.to_s

      logger.info "Started ingest with PID: #{@existing_ingest_pid} (#{@existing_ingest_time_id})"

      tmp_pid_file = File.new("#{Rails.root}/tmp/#{@existing_ingest_pid}.index.pid", "w+")
      tmp_pid_file.write(@existing_ingest_time_id)
      tmp_pid_file.close
    end
  end

  def existing_ingest_time_id(pid)
    if(pid_exists?(pid))
      running_tmp_pid_file = File.open("#{Rails.root}/tmp/#{pid}.index.pid")
      return running_tmp_pid_file.gets
    end
  end

  def pid_exists?(pid)
    `ps -p #{pid}`.include?(pid)
  end

  def get_item(pid)
    # Can probably just use the object returned by blacklight, solr document struct of some sort.
    result = Blacklight.default_index.search(:fl => 'author_uni,id,handle,title_display,free_to_read_start_date', :fq => "pid:\"#{pid}\"")["response"]["docs"]

    item = Item.new
    item.pid = result.first[:id]
    item.title = result.first[:title_display]
    item.handle = result.first[:handle]
    item.free_to_read_start_date = result.first[:free_to_read_start_date]

    item.authors_uni = []

    if(result.first[:author_uni] != nil)
      # item.authors_uni = result.first[:author_uni] || []
      item.authors_uni = fix_authors_array(result.first[:author_uni])
    end

    return item
  end

  def fix_authors_array(authors_uni)
    author_unis_clean = []

    authors_uni.each do | uni_str |
      author_unis_clean.push(uni_str.split(', '))
    end

    return author_unis_clean.flatten
  end
end
