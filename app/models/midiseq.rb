require 'midilib/sequence'
require 'midilib/consts'
include MIDI
  
class Midiseq

  def initialize
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
    
    # Give the track a name and an instrument name (optional).
    #track.name = 'Tonebank Example'
    track.instrument = GM_PATCH_NAMES[0]
    
    # Add a volume controller event (optional).
    #track.events << Controller.new(0, CC_VOLUME, 127)
    
    # Add events to the track: a major scale. Arguments for note on and note off
    # constructors are channel, note, velocity, and delta_time. Channel numbers
    # start at zero. We use the new Sequence#note_to_delta method to get the
    # delta time length of a single quarter note.
    track.events << ProgramChange.new(0, 1, 0)
    eighth_note_length = seq.note_to_delta('eighth')
    quarter_note_length = seq.note_to_delta('quarter')
    6.times do
      track.events << NoteOn.new(0, 60, 127, 0) << NoteOn.new(0, 63, 127, 0)
      track.events << NoteOff.new(0, 60, 127, eighth_note_length) << NoteOff.new(0, 63, 127, 0)
    end
    #[0, 2, 4, 5, 7, 9, 11, 12].each do |offset|
    #  track.events << NoteOn.new(0, 64 + offset, 127, 0)
    #  track.events << NoteOff.new(0, 64 + offset, 127, eighth_note_length)
    #end
    
    # Calling recalc_times is not necessary, because that only sets the events'
    # start times, which are not written out to the MIDI file. The delta times are
    # what get written out.
    
    # track.recalc_times
  
    File.open('app/assets/data/tonebank_example_'+@datetime+'.mid', 'wb') { |file| seq.write(file) }

  end
end
