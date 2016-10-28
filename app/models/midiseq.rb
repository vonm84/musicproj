require 'midilib/sequence'
require 'midilib/consts'
include MIDI
  
class Midiseq
  @@tonebank=[[0,7],[2,9],[0,4],[2,7],[2,9],[2,9],[0,4],[2,9],[0,7],[2,7],[4,9],[4,9]]
  @@wordweights={"2"=>1178, "12"=>585, "21"=>2683, "22"=>128, "121"=>1113, "211"=>1448, "212"=>229, "221"=>143, "1211"=>731, "2111"=>305, "2121"=>648, "2211"=>35, "12111"=>143, "12121"=>84, "21111"=>34, "21121"=>99, "21211"=>302, "121211"=>39, "211211"=>35, "212111"=>30} 
  @@phraseweights = {1=>11, 2=>40, 3=>80, 4=>100, 5=>80, 6=>40, 7=>11}

  def lev_dist(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) {Array.new(n+1)}

    (0..m).each {|i| d[i][0] = i}
    (0..n).each {|j| d[0][j] = j}
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                    d[i-1][j-1]       # no operation required
                  else
                    [ d[i-1][j]+1,    # deletion
                      d[i][j-1]+1,    # insertion
                      d[i-1][j-1]+1,  # substitution
                    ].min
                  end
      end
    end
    d[m][n]
  end
  
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
  
  def weighted_rand(weighted)
    max    = weighted.inject(0) { |sum, (item, weight)| sum + weight }
    target = rand(1..max)
 
    weighted.each do |item, weight|
      return item if target <= weight
      target -= weight
    end
  end
  
  def firstphrase(initlen)
        print "initlen:#{initlen}"
    #Array.new(weighted_rand @@phraseweights) {weighted_rand @@wordweights}
    Array.new(initlen.to_i) {weighted_rand @@wordweights}
  end
  
  def phrasevar(prevphrase, n)
    #print prevphrase
    #puts n
    #puts " "
    n.times do
      newlen = weighted_rand @@phraseweights.select { |key, value| (prevphrase.length-key.to_i).abs<=1 }
      case newlen-prevphrase.length
        when 1
          prevphrase.insert(rand(prevphrase.length), weighted_rand(@@wordweights))
        when 0
          pos = rand(prevphrase.length)
          prevphrase[pos]= weighted_rand @@wordweights.select { |key, value| lev_dist(prevphrase[pos],key).abs==1 }
        when -1
          prevphrase.delete_at(rand(prevphrase.length))
      end
    end
    return prevphrase
    #Array.new(weighted_rand @@phraseweights) {weighted_rand @@wordweights}
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
    #print " prevpitch: #{prevpitch}"
    #print " optall: #{optall}"
    optall.each do |optsing|
          @ps = nextpitchspan.select {|k,v| k==optsing}
          if @ps != {} then opt.merge! @ps end
    end

    opttotal = opt.values.reduce(:+)
    #opt.each {|key,value| opt[key]=opt[key]/opttotal.to_f}
    #puts "opt: #{opt}"
    raise "Melodic jump from #{prevpitch} to any of #{opt.keys.map {|a| a-prevpitch}} impossible at tonebank position #{melcount.modulo(@@tonebank.length)+1}" if opttotal==0
    weighted_rand opt
  end

  def initialize(numcycles, bpms, instr, bottom, top, initlen, rhythmvar, swing, shaker, repeat, numvals)

    @datetime = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    @melody = []
    @melodylength = 0
    @events=[]
    @shakerarr = shaker.values.to_a.map {|i| i.to_i}

    @@rangebottom=bottom
    @@rangetop = top
    @@swingarr=swing



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
    track.events << ProgramChange.new(0, 108, 0)
    
    
    eighth_note_length = seq.note_to_delta('eighth')
    swinglengths=[]
    melodycount = 0
    
    for i in 0..2 do
      swinglengths[i]=3 * eighth_note_length * @@swingarr[i]/@@swingarr.inject(:+)
    end
    
    swinglengths[-1]+=(3 * eighth_note_length - swinglengths.inject(:+))
    
  
    numcycles.times do
      @@tonebank.each do |f|
        track.events << NoteOn.new(1, 60+f[0], 80, 0) << NoteOn.new(1, 60+f[1], 80, 0)
        track.events << NoteOff.new(1, 60+f[0], 80, swinglengths[melodycount % 3]) << NoteOff.new(1, 60+f[1], 80, 0)
        melodycount +=1
      end
    end
    
    
    track = Track.new(seq)
    seq.tracks << track
    track.name = 'Shaker'
    track.events << ProgramChange.new(9, 1, 0)
  
    (0..melodycount).each do |i|
      track.events << NoteOn.new(9, 69, 80, 0) if @shakerarr[i % @shakerarr.length] == 1
      track.events << NoteOff.new(9, 69, 80, swinglengths[i % 3])
    end
    
    track = Track.new(seq)
    seq.tracks << track
    track.name = 'Solo'
    track.instrument = instr
    track.events << ProgramChange.new(1, GM_PATCH_NAMES.index(instr), 0)
    #track.events << Controller.new(0, CC_VOLUME, 127)
    
    melodycount = 0
    previouspitch = 60+@@tonebank[0][0]
    
    #construct the phrasing and rhythms

    prevphrase=[]
    loop do
      if @melody.length==0 then currentphrase = self.firstphrase(initlen) else currentphrase=self.phrasevar(prevphrase.clone,rand(rhythmvar.to_i+1)) end
      @melodylength += phraselength(currentphrase)
      @melodylength += 3
      break if @melodylength >= @@tonebank.length*numcycles
      @melody[@melody.length] = currentphrase 
      prevphrase=currentphrase
    end

    
    #construct the pitches
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
      
    @events.each do |ev|
      if ev[0]==1 then
        track.events << NoteOn.new(0, ev[1], 100, 0)
      end
        track.events << NoteOff.new(0, ev[1], 100, ev[2])
    end
    
    
    File.open('app/assets/data/tonebank_example_'+@datetime+'.mid', 'wb') { |file| seq.write(file) }

  end
end
