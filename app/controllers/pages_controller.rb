class PagesController < ApplicationController


  def index
    @articles=Article.all
  end
  
  def testing
      
  end

  def contact
  end

  

  def about
  end
  
  def testresult
  end
  
  def result
        @newmidiseq=Midiseq.new(params[:session][:tonebank],
        params[:session][:numcycles].to_i,
        params[:session][:bpm].to_i,
        params[:session][:instr],
        params[:session][:bottom].to_i,
        params[:session][:top].to_i,
        params[:session][:initlen].to_i,
        params[:session][:rhythmvar].to_i,
        [params[:session][:swing1].to_i,params[:session][:swing2].to_i,params[:session][:swing3].to_i],
        params[:session][:shaker],
        params[:session][:repeat],
        params[:session][:numvals]
        )
        send_file 'app/assets/data/tonebank_example_'+@newmidiseq.instance_variable_get("@datetime")+'.mid'
    
  end
 end