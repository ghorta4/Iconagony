class_name ReplayFile

var RNGSeed : int = 0 #For rng consistency, of course...
var MIDI = {} 
#Files are stored like MIDI: keys are frame number, values are an array with: State name, input values, flip, skills picked up. Like a digital trumpet, in a way... or a harmonica...
#Note to self: Some other data may be stored here, so remember that some frames may have ONLY data

var InitialLoadout = [] #Array with moves, to be serialized and deserialized for storage. There's no way to know exactly what moves will do and if MIDI input will properly
#simulate it, so just simulate having it on the character...

var MoveRelocations = {}
#Like the MIDI file, except the values instead bear a number of sets of 4 integers representing where moves were relocated during combat.
