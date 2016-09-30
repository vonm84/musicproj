class PagesController < ApplicationController


  def index

  end

  def contact
  end

  

  def about
  end
  
  def result
        @newmidiseq=Midiseq.new(params[:session][:numcycles].to_i,params[:session][:bpm].to_i)
        send_file 'app/assets/data/tonebank_example_'+@newmidiseq.instance_variable_get("@datetime")+'.mid'
    
  end
  
  def resultold
 
    
    @numn=params[:session][:numbars].to_i
     
    if File.exists?("outputfile.ly")
      #File.delete( "outputfile.ly")
    end
    
    output = File.open( "outputfile.ly","w")
    ary = [["c'8", "g'8"], ["d'","a'"], ["c'","e'"],["d'","g'"],["d'","a'"],["d'","a'"],
           ["c'","e'"], ["d'","a'"], ["c'","g'"], ["d'","g'"],["e'","a'"],["e'","a'"]
           ]
           
    aryrand = Array.new(11, 0)
    for i in 0..@numn-1
        aryrand[i]=1
    end
    
    aryrand = aryrand.shuffle
    
    
   output << "\\paper {
  \#(set-paper-size \"a6\")
    }
    "
    output << "{ \\time 6/8 "
#    ary.each do |elem|
#        if Random.rand(2) == 0
#            if Random.rand(2) ==0
#                output << elem[0]
#            else
#                output << elem[1]
#            end
#        else 
#            output << "r8"
#        end
#    end
   
    for i in 0..11
        if aryrand[i]==1
            if Random.rand(2) ==0
                output << ary[i][0]
            else
                output << ary[i][1]
            end    
        else
            output << "r8"
        end
    end
   
   
    output << "}"
    output.close 
    if File.exists?("app/assets/images/outputfile.png")
        File.delete( "app/assets/images/outputfile.png")
    end
    Kernel.system( "lilypond --png -o app/assets/images outputfile.ly" )
  end
  

end
