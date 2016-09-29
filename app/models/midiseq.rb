require 'midilib/sequence'
require 'midilib/consts'
include MIDI
  
class Midiseq
  
  def weighted_rand(weights = {})
    puts weights.values.inject(&:+)
    #raise 'Probabilities must sum up to 1' unless weights.values.inject(&:+) == 1.0
  
    u = 0.0
    ranges = Hash[weights.map{ |v, p| [u += p, v] }]
  
    u = rand
    ranges.find{ |p, _| p > u }.last
  end
  
  def word
    weights = {'1'=> 0.11782, '01'=> 0.058502, '10'=> 0.26833, '11'=> 
  0.012812, '010'=> 0.11135, '100'=> 0.14486, '101'=> 
  0.022996, '110'=> 0.014323, '0100'=> 0.073127, '1000'=> 
  0.030520, '1010'=> 0.064848, '1100'=> 0.0035959, '01000'=> 
  0.014323, '01010'=> 0.0084912, '10000'=> 0.0034146, '10010'=> 
  0.0099115, '10100'=> 0.030248, '010100'=> 0.0039283, '100100'=> 
  0.0035657, '101000'=> 0.0030218}
     weighted_rand weights
  end
  
  def phrase
    10.times {self.word}
  end
  def initialize(numcycles)
    self.phrase
    tonebank=[[0,7],[2,9],[0,4],[2,7],[2,9],[2,9],[0,4],[2,9],[0,7],[2,7],[4,9],[4,9]]
    @datetime = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
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
    track.events << Tempo.new(Tempo.bpm_to_mpq(120))
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
    quarter_note_length = seq.note_to_delta('quarter')

    numcycles.times do
      tonebank.each do |f|
        track.events << NoteOn.new(0, 60+f[0], 127, 0) << NoteOn.new(0, 60+f[1], 127, 0)
        track.events << NoteOff.new(0, 60+f[0], 127, eighth_note_length) << NoteOff.new(0, 60+f[1], 127, 0)
      end
    end
    
    track = Track.new(seq)
    seq.tracks << track
    track.name = 'Solo'
    track.instrument = GM_PATCH_NAMES[0]
    #track.events << Controller.new(0, CC_VOLUME, 127)
    track.events << ProgramChange.new(0, 1, 0)
    track.events << NoteOn.new(0, 60, 127, 0) 
    track.events << NoteOff.new(0, 60, 127, eighth_note_length)

    #numcycles.times do
    #  tonebank.each do |f|
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
