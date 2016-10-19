require 'midilib/sequence'
require 'midilib/consts'
include MIDI
  
class Midiseq
  @@tonebank=[[0,7],[2,9],[0,4],[2,7],[2,9],[2,9],[0,4],[2,9],[0,7],[2,7],[4,9],[4,9]]
  @@wordweights={"2"=>1178, "12"=>585, "21"=>2683, "22"=>128, "121"=>1113, "211"=>1448, "212"=>229, "221"=>143, "1211"=>731, "2111"=>305, "2121"=>648, "2211"=>35, "12111"=>143, "12121"=>84, "21111"=>34, "21121"=>99, "21211"=>302, "121211"=>39, "211211"=>35, "212111"=>30} 
  @@phraseweights = {1=>11, 2=>40, 3=>80, 4=>100, 5=>80, 6=>40, 7=>11}
  @@rangebottom=0
  @@rangetop=0
  @@maxintervalspan=0
  @@swingarr=[]
  
  def nested_arrays_of_pairs_to_hash(array)
  result = {}
  array.each do |elem|
    second = if elem.last.is_a?(Array)
      nested_arrays_to_hash(elem.last)
    else
      elem.last
    end
    result.merge!({elem.first => second})
  end
  result
  end
  
  def swingtotal(start,stop,arr)
    total=0
    for i in start..stop
      total+=arr[i%3]
    end
    total
  end
  
  def binomarray(m, centre)
    n=2*m-2
    ary = Array.new(n+1)
    for k in 0..ary.size-1
      ary[k]= if k == 0 then [k+centre-@@maxintervalspan+1,1] else [k+centre-@@maxintervalspan+1,(1+n-k..n).inject(:*)/(1..k).inject(:*)] end
    end
    nested_arrays_of_pairs_to_hash ary
  end
  

  
  def weighted_rand(weighted)
    max    = weighted.inject(0) { |sum, (item, weight)| sum + weight }
    target = rand(1..max)
 
    weighted.each do |item, weight|
      return item if target <= weight
      target -= weight
    end
  end
  
  
  
  def phrase
    Array.new(weighted_rand @@phraseweights) {weighted_rand @@wordweights}
  end
  
  def phraselength(testphrase)
    testphrase.map{ |k| "#{k}" }.join("1").split("").map {|s| s.to_i }.inject(:+)
  end
  
  
  
  def numvalstranspose(center,numvals)
    ary = numvals.to_a
    ary.each do |i|
      i[0]=i[0].to_i+center-12
      i[1]=i[1].to_i
    end
    nested_arrays_of_pairs_to_hash ary
  end
  
  def nextpitch(melcount, prevpitch, numvals)
    tonebankopt=@@tonebank[melcount.modulo(@@tonebank.length)]
    nextpitchspan=numvalstranspose(prevpitch,numvals)
    optall=[]
    opt={}
    
    for i in @@rangebottom..@@rangetop
      tonebankopt.each do |tb|
        if i.modulo(@@tonebank.length)==tb.modulo(@@tonebank.length) then optall.push i end
      end
    end
    print " prevpitch: #{prevpitch}"
    print " optall: #{optall}"
    optall.each do |optsing|
          @ps = nextpitchspan.select {|k,v| k==optsing}
          if @ps != {} then opt.merge! @ps end
    end

    opttotal = opt.values.reduce(:+)
    #opt.each {|key,value| opt[key]=opt[key]/opttotal.to_f}
    print "opt: #{opt}"
    raise "Impossible melodic jump from #{prevpitch} to #{opt} at tonebank position #{melcount.modulo(@@tonebank.length)+1}" if opttotal==0
    puts ""
    weighted_rand opt
  end

  def initialize(numcycles, bpms, span, bottom, top, swing, repeat, numvals)

    @datetime = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    @melody = Array.new
    @melodylength = 0
    @events=[]
    @evjoined=[]
 
    @@maxintervalspan=span
    @@rangebottom=bottom
    @@rangetop = top
    @@swingarr=swing

    #print numvals
    loop do
      currentphrase = self.phrase
      @melodylength += phraselength(currentphrase)
      @melodylength += 3
      break if @melodylength >= @@tonebank.length*numcycles
      @melody.push(currentphrase)

    end

    

    $LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')
    

    seq = Sequence.new()
    
    # Create a first track for the sequence. This holds tempo events and stuff
    # like that.
    track = Track.new(seq)
    seq.tracks << track
    track.events << Tempo.new(Tempo.bpm_to_mpq(bpms).to_i)
    track.events << TimeSig.new(6,3,24,8,0)
    track.events << MetaEvent.new(META_SEQ_NAME, 'Tonebank Example')
    
    
    # Create a track to hold the notes. Add it to the sequence.
    track = Track.new(seq)
    seq.tracks << track
    track.name = 'Tonebank'
    track.instrument = GM_PATCH_NAMES[108]
    #track.events << Controller.new(0, CC_VOLUME, 127)
    track.events << ProgramChange.new(0, 108, 0)
    
    
    eighth_note_length = seq.note_to_delta('eighth')
    swinglengths=[]
    melodycount = 0
    
    for i in 0..2 do
      swinglengths[i]=3 * eighth_note_length * @@swingarr[i]/@@swingarr.inject(:+)
    end
  
    numcycles.times do
      @@tonebank.each do |f|
        track.events << NoteOn.new(0, 60+f[0], 60, 0) << NoteOn.new(0, 60+f[1], 60, 0)
        track.events << NoteOff.new(0, 60+f[0], 60, swinglengths[melodycount % 3]) << NoteOff.new(0, 60+f[1], 60, 0)
        melodycount +=1
      end
    end
    
    
    track = Track.new(seq)
    seq.tracks << track
    track.name = 'Solo'
    track.instrument = GM_PATCH_NAMES[40]
    track.events << ProgramChange.new(0, 40, 0)
    #track.events << Controller.new(0, CC_VOLUME, 127)
    
    melodycount = 0
    previouspitch = 60+@@tonebank[0][0]
    
    @melody.each do |phr|
      phr.each do |wd|
        @phrrest=Random.rand(2)+2
        wd.split("").each do |h|
          @nextp=self.nextpitch(melodycount,previouspitch,numvals)
          @events.push [1, @nextp,swingtotal(melodycount,melodycount+h.to_i-1,swinglengths)]
          previouspitch=@nextp
          melodycount+=h.to_i 
        end
        @events.push [0, @nextp,swinglengths[melodycount % 3]]
        melodycount+=1
      end
      @events.push [0, @nextp,swingtotal(melodycount,melodycount+@phrrest-1,swinglengths)]
      melodycount +=@phrrest
    end

    
    if repeat == "1" then 
      loop do
      numchanges=0

      (1..@events.length-1).each do |i|
        if (1==@events[i-1][0] && 1==@events[i][0] && @events[i-1][1]==@events[i][1]) then
          numchanges+=1
          @events[i-1][2]+=@events[i][2]
          @events.delete_at i
          i-=1
        end
        break if i>=@events.length
      end
      break if numchanges==0
      end
    end
    #@evjoined[0] = @events[0]
    #j=0
    
    #(1..@events.length-1).each do |i|
    #for i in 1..@events.length-1
    #  print "Before: #{@events[i][2]}"
      #if (1==@events[i-1][0] && 1==@events[i][0] && @events[i-1][1]==@events[i][1]) then

        #puts "LAST: #{@evjoined.last} " 
        #puts "LAST[2]: #{@evjoined.last[2]} "
        #print "Before: #{@events[i]}"
        #@evjoined[j][2] += @events[i][2]
        #print "After: #{@events[i]}"
        #puts "LAST[2] after: #{@evjoined.last[2]} "
        
      #else
        #j+=1
        #@evjoined[j] = @events[i]

      #end
    #puts "After: #{@events[i][2]}"
    #end
  
    
    #@evjoined.each do |f|
    #  puts "[#{f[0]},#{f[1]},#{f[2]}]"
    #end
    

      
    @events.each do |ev|
      if ev[0]==1 then
        track.events << NoteOn.new(0, ev[1], 100, 0)
      end
        track.events << NoteOff.new(0, ev[1], 100, ev[2])
    end
    
    
    File.open('app/assets/data/tonebank_example_'+@datetime+'.mid', 'wb') { |file| seq.write(file) }

  end
end
