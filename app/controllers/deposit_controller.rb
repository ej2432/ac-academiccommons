class DepositController < ApplicationController
  
  def submit
    
    if(params[:acceptedAgreement] == "agree")
      uploaded_file = UploadedFile.save(params[:file], "data/self-deposit-uploads/#{params[:uni]}", params[:file].original_filename)
      file_download_url = root_url + "self-deposit/uploads/#{params[:uni]}/#{params[:file].original_filename}"
      Notifier.deliver_new_deposit(params, file_download_url)
    else
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "index"
    end
    
  end
  
end
