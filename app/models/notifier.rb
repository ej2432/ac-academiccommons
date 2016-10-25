class Notifier < ActionMailer::Base
  MAX_FILE_SIZE = 1024 * 1024 * 25 # Max file size (25 MB) that can be emailed in KB.

  def statistics_by_search(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams)
    statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, nil)
  end

  def author_monthly(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, optional_note)
    statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, optional_note)
  end

  def author_monthly_first(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams)
    statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, nil)
  end

  def statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, optional_note)
    @request = request
    @author_id = author_id
    @stats = stats
    @totals = totals
    @results = results
    @start_date = start_date.strftime("%b %Y")
    @end_date = end_date.strftime("%b %Y")
    recipients = to_address
    from = Rails.application.config.emails['mail_deliverer']
    full_from = "\"Academic Commons\" <#{from}>"


    subject = "Academic Commons Monthly Download Report for #{@start_date} - #{@end_date}"
    content_type = 'text/html'
    @streams = show_streams
    @optional_note = optional_note

    mail(:to => recipients, :from => full_from, :subject => subject, :content_type => content_type)

    logger.debug("Report sent for: " + author_id + " to: " + to_address)
  end

  def new_deposit(root_url, deposit, attach_file = true)
    @agreement_version = deposit.agreement_version
    @uni = deposit.uni
    @name = deposit.name
    @email = deposit.email
    @title = deposit.title
    @authors = deposit.authors
    @abstract = deposit.abstract
    @url = deposit.url
    @doi_pmcid = deposit.doi_pmcid
    @notes = deposit.notes
    @record_url = root_url + "admin/deposits/" + deposit.id.to_s

    filepath = File.join(Rails.root, deposit.file_path)
    if attach_file && File.size(filepath) < MAX_FILE_SIZE  # Tries to attach file if under 25MB.
      attachments[File.basename(filepath)] = File.read(filepath)
    end

    @file_download_url = root_url + "admin/deposits/" + deposit.id.to_s + "/file"
    recipients = Rails.application.config.emails['mail_deposit_recipients']
    from = Rails.application.config.emails['mail_deliverer']
    subject = "SD"
    subject.concat(" #{@uni} -") if @uni
    subject.concat(" #{@title.truncate(50)}")

    mail(:to => recipients, :from => from, :subject => subject)
  end

  def new_author_agreement(request)
    @name = request[:name]
    @email = request[:email]
    @agreement_version = request["AC-agreement-version"]
    recipients = Rails.application.config.emails['mail_deposit_recipients']
    from = Rails.application.config.emails['mail_deliverer']
    subject = "Academic Commons Author Agreement Accepted"
    content_type = 'text/html'

    mail(:to => recipients, :from => from, :subject => subject, :content_type => content_type)
  end

  def student_agreement(uni, name, email, advisor, department, empbargo, attachment_path)
    @uni = uni
    @name = name
    @email = email
    @advisor = advisor
    @department = department
    @empbargo = empbargo

    recipients = Rails.application.config.emails['mail_deposit_recipients']
    from = Rails.application.config.emails['mail_deliverer']
    subject = "Academic Commons Student Agreement Accepted"

    attachments.inline['agreement.pdf'] = { mime_type: 'application/x-pdf',
                                            content: File.read(attachment_path) }
    mail(:to => recipients, :from => from, :subject => subject)
  end

  def statistics_report_with_csv_attachment(recipients, from, subject, message, prepared_attachments)

   prepared_attachments.each do |file_name, content|
    attachments.inline[file_name] = {mime_type: 'text/csv', content: content }
   end

    mail(:to => recipients, :from => from, :subject => subject) do |f|
      f.text { render :text => message }
    end
  end

  def reindexing_results( errors_count, indexed_count, new_items_count, time_id )

      log = {}
      log[:time_id] = time_id.to_s
      log[:year] = time_id[0..3].to_i
      log[:month] = time_id[4..5].to_i
      log[:day] = time_id[6..7].to_i
      log[:hour] = time_id[9..10].to_i
      log[:minute] = time_id[11..12].to_i
      log[:second] = time_id[13..14].to_i
      log[:time] = Time.mktime(log[:year], log[:month], log[:day], log[:hour], log[:minute], log[:second]).strftime("%B %e, %Y %r")

      recipients = Rails.application.config.emails['indexing_report_recipients']
      from = Rails.application.config.emails['mail_deliverer']
      subject = "Academic Commons - Daily Reindexing Report"
      content_type = 'text/html'

      @errors_count = errors_count
      @indexed_count = indexed_count
      @new_items_count = new_items_count
      @time_id = time_id
      @existing_time = log[:time]

      mail(:to => recipients, :from => from, :subject => subject, :content_type => content_type)

  end


  def reindexing_summary(params, time_id)

      recipients = Rails.application.config.emails['indexing_report_recipients']
      from = Rails.application.config.emails['mail_deliverer']
      subject = "Academic Commons - Daily Reindexing Summary Report"
      content_type = 'text/html'

      @params = params
      @new_indexed = params[:new_indexed] == nil ? [] : params[:new_indexed].split(',')
      @new_embargoed = params[:embargo_new] == nil ? [] : params[:embargo_new].split(',')
      @embargo_new_released = params[:embargo_new_released] == nil ? [] : params[:embargo_new_released].split(',')
      @failed = params[:failed] == nil ? [] : params[:failed].split(',')
      @time_id = time_id

      mail(:to => recipients, :from => from, :subject => subject, :content_type => content_type)
  end


  def depositor_first_time_indexed_notification(depositor)

    @depositor = depositor
    subject = 'Your submitted items are now available in Academic Commons'
    content_type = 'text/html'
    bcc = Rails.application.config.emails['deposit_notification_bcc']
    from = Rails.application.config.emails['mail_deliverer']
    recipients = depositor.email

    if(Rails.application.config.prod_environment)
      mail(:to => recipients, :bcc => bcc, :from => from, :subject => subject, :content_type => content_type)
      logger.info "=== new Item notification was sent to : " + recipients.to_s + ", bcc: " + bcc.to_s
    else
      subject = subject + ' - test'
      mail(:to => bcc, :from => from, :subject => subject, :content_type => content_type)
      logger.info "=== new Item notification was sent to : " + bcc.to_s
    end
  end

  def depositor_embargoed_notification(depositor)

    @depositor = depositor
    subject = 'Your submitted items are now available in Academic Commons'
    content_type = 'text/html'
    bcc = Rails.application.config.emails['deposit_notification_bcc']
    from = Rails.application.config.emails['mail_deliverer']
    recipients = depositor.email

    if(Rails.application.config.prod_environment)
      mail(:to => recipients, :bcc => bcc, :from => from, :subject => subject, :content_type => content_type)
      logger.info "=== new Item notification was sent to : " + recipients.to_s + ", bcc: " + bcc.to_s
    else
      subject = subject + ' - test'
      mail(:to => bcc, :from => from, :subject => subject, :content_type => content_type)
      logger.info "=== new Item notification was sent to : " + bcc.to_s
    end
  end


end
