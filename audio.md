# Pico-8 Audio Information

## Audio API (from manual)

    sfx n [channel [offset [length]]]

	play sfx n on channel (0..3) from note offset (0..31) for length notes
	n -1 to stop sound on that channel
	n -2 to release sound on that channel from looping
	Any music playing on the channel will be halted
	offset in number of notes (0..31)

	channel -1 (default) to automatically choose a channel that is not being used
	channel -2 to stop the sound from playing on any channel
	
		
    music [n [fade_len [channel_mask]]]

	play music starting from pattern n (0..63)
	n -1 to stop music
	fade_len in ms (default: 0)
	channel_mask specifies which channels to reserve for music only
		e.g. to play on channels 0..2: 1+2+4 = 7

	Reserved channels can still be used to play sound effects on, but only when that
	channel index is explicitly requested by sfx().

## Tutorials
[Audio System Tutorials](https://www.youtube.com/playlist?list=PLjZAika8vyZkyOjoCp0EbHeIFZ8MLlhvg)
