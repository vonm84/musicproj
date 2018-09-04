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
        params[:session][:minrhythmvar].to_i,
        params[:session][:maxrhythmvar].to_i,
        params[:session][:swing],
        params[:session][:shaker],
        params[:session][:repeat],
        params[:session][:numvals],
        params[:session][:tsnum].to_i,
        params[:session][:divs].to_i,
        params[:session][:tonebankinstr]
        )
        send_file 'app/assets/data/tonebank_example_'+@newmidiseq.instance_variable_get("@datetime")+'.mid'
    
  end
 end