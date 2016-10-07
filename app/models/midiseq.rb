require 'midilib/sequence'
require 'midilib/consts'
include MIDI
  
class Midiseq
  @@tonebank=[[0,7],[2,9],[0,4],[2,7],[2,9],[2,9],[0,4],[2,9],[0,7],[2,7],[4,9],[4,9]]
  
  def weighted_rand(weights = {})
    #raise 'Probabilities must sum up to 1' unless weights.values.inject(&:+) == 1.0
  
    u = 0.0
    ranges = Hash[weights.map{ |v, p| [u += p, v] }]
  
    u = rand
    ranges.find{ |p, _| p > u }.last
  end
  
  def word
    weights = {'2'=> 0.11782, '12'=> 0.058502, '21'=> 0.26833, '22'=> 
  0.012812, '121'=> 0.11135, '211'=> 0.14486, '212'=> 
  0.022996, '221'=> 0.014323, '1211'=> 0.073127, '2111'=> 
  0.030520, '2121'=> 0.064848, '2211'=> 0.0035959, '12111'=> 
  0.014323, '12121'=> 0.0084912, '21111'=> 0.0034146, '21121'=> 
  0.0099115, '21211'=> 0.030248, '121211'=> 0.0039283, '211211'=> 
  0.0035657, '212111'=> 0.0030218}
  

     weighted_rand weights
  end
  
  def phrase
      weightsbinom = {1=>0.016, 2=> 0.094, 3=> 0.23, 4=>0.31, 5=> 0.23, 6=>
  0.094, 7=> 0.016}
    Array.new(weighted_rand weightsbinom) {self.word}
  end
  
  def phraselength(testphrase)
    testphrase.map{ |k| "#{k}" }.join("1").split("").map {|s| s.to_i }.inject(:+)
  end
  
  def nextpitch(melcount, prevpitch)
    hupdown=Random.rand(2)
    60+@@tonebank[melcount.modulo(@@tonebank.length)][hupdown]
  end
  
  def initialize(numcycles, bpms)


    @datetime = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    @melody = Array.new
    @melodylength = 0
    
    #currentphrase = self.phrase
    #puts phraselength(currentphrase)
    #puts currentphrase
    
    loop do
      currentphrase = self.phrase
      @melodylength += phraselength(currentphrase)
      @melodylength += 3
      break if @melodylength >= @@tonebank.length*numcycles
      @melody.push(currentphrase)

    end

    
    #! /usr/bin/env ruby
    #
    # usage: from_scratch.rb
    #
    # This script shows you how to create a new sequence from scratch and save it
    # to a MIDI file. It creates a file called 'from_scratch.mid'.
    
    # Start looking for MIDI module classes in the directory above this one.
    # This forces us to use the local copy, even if there is a previously
    # installed version out there somewhere.
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
    

    numcycles.times do
      @@tonebank.each do |f|
        track.events << NoteOn.new(0, 60+f[0], 80, 0) << NoteOn.new(0, 60+f[1], 80, 0)
        track.events << NoteOff.new(0, 60+f[0], 80, eighth_note_length) << NoteOff.new(0, 60+f[1], 80, 0)
      end
    end
    
    
    track = Track.new(seq)
    seq.tracks << track
    track.name = 'Solo'
    track.instrument = GM_PATCH_NAMES[40]
    track.events << ProgramChange.new(0, 40, 0)
    #track.events << Controller.new(0, CC_VOLUME, 127)
    
    melodycount = 0
    previouspitch = 0
    
    @melody.each do |phr|
      phr.each do |wd|
        @phrrest=Random.rand(2)+2
        wd.split("").each do |h|
          @nextp=self.nextpitch(melodycount,0)
          track.events << NoteOn.new(0, @nextp, 100, 0) 
          track.events << NoteOff.new(0, @nextp, 100, h.to_i*eighth_note_length)
          melodycount+=h.to_i 
          

        end
        track.events << NoteOff.new(0, @nextp, 127, eighth_note_length)
        melodycount+=1
        #puts "-wd-"
        #puts "-wd- #{@melodycount} #{@melodycount.modulo(@@tonebank.length)} [#{@@tonebank[@melodycount.modulo(@@tonebank.length)][0]},#{@@tonebank[@melodycount.modulo(@@tonebank.length)][1]}]"

      end
      #puts "-phr-"
      track.events << NoteOff.new(0, 72, 127, @phrrest*eighth_note_length)
      melodycount +=@phrrest
      #track.events << NoteOn.new(0, 60+g.to_i, 127, 0) 
      #track.events << NoteOff.new(0, 60+g.to_i, 127, eighth_note_length)
    end

    #numcycles.times do
    #  @@tonebank.each do |f|
    #    track.events << NoteOn.new(0, 60+f[0], 127, 0) << NoteOn.new(0, 60+f[1], 127, 0)
    #    track.events << NoteOff.new(0, 60+f[0], 127, eighth_note_length) << NoteOff.new(0, 60+f[1], 127, 0)
    #  end
    #end

    
    # Calling recalc_times is not necessary, because that only sets the events'
    # start times, which are not written out to the MIDI file. The delta times are
    # what get written out.
    
    # track.recalc_times

    File.open('app/assets/data/tonebank_example_'+@datetime+'.mid', 'wb') { |file| seq.write(file) }

  end
end
