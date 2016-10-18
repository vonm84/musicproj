require 'midilib/sequence'
require 'midilib/consts'
include MIDI
  
class Midiseq
  @@tonebank=[[0,7],[2,9],[0,4],[2,7],[2,9],[2,9],[0,4],[2,9],[0,7],[2,7],[4,9],[4,9]]
  @@wordweights= {'2'=> 0.11782, '12'=> 0.058502, '21'=> 0.26833, '22'=> 
  0.012812, '121'=> 0.11135, '211'=> 0.14486, '212'=> 
  0.022996, '221'=> 0.014323, '1211'=> 0.073127, '2111'=> 
  0.030520, '2121'=> 0.064848, '2211'=> 0.0035959, '12111'=> 
  0.014323, '12121'=> 0.0084912, '21111'=> 0.0034146, '21121'=> 
  0.0099115, '21211'=> 0.030248, '121211'=> 0.0039283, '211211'=> 
  0.0035657, '212111'=> 0.0030218}
  @@phraseweights = {1=>0.017, 2=> 0.094, 3=> 0.23, 4=>0.31, 5=> 0.23, 6=> 0.094, 7=> 0.016}
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
      total+=arr[i%4]
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
  
  def weighted_rand(weights)
    #raise 'Probabilities must sum up to 1' unless weights.values.inject(&:+) == 1.0
  
    u = 0.0
    ranges = Hash[weights.map{ |v, p| [u += p, v] }]
    loop do
      u = rand
      break if ranges.find{ |p, _| p > u }!=nil
    end
    ranges.find{ |p, _| p > u }.last
  end
  
  
  
  def phrase
    Array.new(weighted_rand @@phraseweights) {weighted_rand @@wordweights}
  end
  
  def phraselength(testphrase)
    testphrase.map{ |k| "#{k}" }.join("1").split("").map {|s| s.to_i }.inject(:+)
  end
  
  def nextpitch(melcount, prevpitch)
    tonebankopt=@@tonebank[melcount.modulo(@@tonebank.length)]
    nextpitchspan=binomarray(@@maxintervalspan,prevpitch)

    optall=[]
    opt={}
    
    for i in @@rangebottom..@@rangetop
      tonebankopt.each do |tb|
        if i.modulo(@@tonebank.length)==tb.modulo(@@tonebank.length) then optall.push i end
      end
    end
  
    optall.each do |optsing|
          @ps = nextpitchspan.select {|k,v| k==optsing}
          if @ps != {} then opt.merge! @ps end
    end

    opttotal = opt.values.reduce(:+)
    opt.each {|key,value| opt[key]=opt[key]/opttotal.to_f}
    #print opt
    
    #print " || "
    weighted_rand opt
    #optall.sample
    
  end

  def initialize(numcycles, bpms, span, bottom, top, swing, repeat)

    @datetime = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    @melody = Array.new
    @melodylength = 0
    @events=[]
    @evjoined=[]
 
    @@maxintervalspan=span
    @@rangebottom=bottom
    @@rangetop = top
    @@swingarr=swing

    
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
    
    for i in 0..3 do
      swinglengths[i]=4 * eighth_note_length * @@swingarr[i]/@@swingarr.inject(:+)
    end
  
    numcycles.times do
      @@tonebank.each do |f|
        track.events << NoteOn.new(0, 60+f[0], 60, 0) << NoteOn.new(0, 60+f[1], 60, 0)
        track.events << NoteOff.new(0, 60+f[0], 60, swinglengths[melodycount % 4]) << NoteOff.new(0, 60+f[1], 60, 0)
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
          @nextp=self.nextpitch(melodycount,previouspitch)
          @events.push [1, @nextp,swingtotal(melodycount,melodycount+h.to_i-1,swinglengths)]
          previouspitch=@nextp
          melodycount+=h.to_i 
        end
        @events.push [0, @nextp,swinglengths[melodycount % 4]]
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
      print "numchanges: #{numchanges}"
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
  
    puts " "
    @events.each do |f|
      puts "[#{f[0]},#{f[1]},#{f[2]}]"
    end
    puts "L:#{@events.length}"
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
