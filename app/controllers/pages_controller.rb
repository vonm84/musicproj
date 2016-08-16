class PagesController < ApplicationController
  def index
      # session[:numnotes] = 14
  end

  def contact
  end

  

  def about
  end
  
  def result
     @numn=params[:session][:numnotes]
    if File.exists?("outputfile.ly")
      File.delete( "outputfile.ly")
    end
    
    output = File.open( "outputfile.ly","w")
    ary = [["c'8", "g'8"], ["d'","a'"], ["c'","e'"],["d'","g'"],["d'","a'"],["d'","a'"],
           ["c'","e'"], ["d'","a'"], ["c'","g'"], ["d'","g'"],["e'","a'"],["e'","a'"]
           ]
   
    output << "{ \\time 6/8 "
    ary.each do |elem|
        if Random.rand(2) == 0
            if Random.rand(2) ==0
                output << elem[0]
            else
                output << elem[1]
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
