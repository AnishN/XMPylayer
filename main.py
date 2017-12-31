from xmpylayer import AudioSystem, AudioBuffer, AudioSource, AudioListener

system = AudioSystem()
zeta = system.load_from_path("zeta_force_level_2.xm")
zeta_source = AudioSource()
zeta_source.buffer_ = zeta
zeta_source.play()
#zeta_source.looping = True#loops from the beginning though, need to loop manually

offset = 40.3
zeta_source.set_offset("second", offset)
system.add_source(zeta_source)

while True:
    if zeta_source.get_offset("second") >= 45.0:#stop the music early
        zeta_source.set_offset("second", offset)#prepare to go insane as it restarts @ 40.3 seconds in...
    system.update()
