import contextlib, os, signal, threading, time

cdef class AudioSystem:
    
    def __init__(self):
        self.al_device = alcOpenDevice(NULL)
        self.al_context = alcCreateContext(self.al_device, NULL)
        self.context = xmp_create_context()
        self.sources = []
        self.listener = AudioListener()
        alcMakeContextCurrent(self.al_context)

    def add_source(self, AudioSource source):
        self.sources.append(source)
    
    def remove_source(self, AudioSource source):
        self.sources.remove(source)
        
    def load_from_path(self, str file_path, int frequency=44100, int chunk_size=4096):
        cdef uint16_t * chunk = <uint16_t *>malloc(chunk_size)
        cdef int flags = XMP_FORMAT_MONO
        cdef int num_chunks = 0
        cdef uint16_t * buffer_
        cdef int buffer_size
        cdef bytes bytes_file_path = file_path.encode()
        cdef char * c_file_path = bytes_file_path
        cdef AudioBuffer out
        
        xmp_load_module(self.context, c_file_path)
        xmp_start_player(self.context, frequency, flags)
        while xmp_play_buffer(self.context, chunk, chunk_size, 1) == 0:
            num_chunks += 1
        xmp_end_player(self.context)
        
        xmp_start_player(self.context, frequency, flags)
        buffer_size = num_chunks * chunk_size
        buffer_ = <uint16_t *>malloc(buffer_size)
        xmp_play_buffer(self.context, buffer_, buffer_size, 0)
        xmp_end_player(self.context)
        
        xmp_release_module(self.context)
        free(chunk)
        
        out = AudioBuffer(<uint16_t[:buffer_size]>buffer_, frequency)
        return out
        
    
    def quit(self, *args, **kwargs):
        print(args)
        print(kwargs)
        alcDestroyContext(self.al_context)
        alcCloseDevice(self.al_device)
    
    def update(self):
        self.listener.update()
        cdef AudioSource source
        cdef AudioBuffer buffer_
        cdef ALint state
        for i in range(len(self.sources)):
            source = self.sources[i]
            buffer_ = <AudioBuffer>source.buffer_
            buffer_.update()
            source.update()

cdef class AudioBuffer:
    
    def __init__(self, uint16_t[:] data, int frequency):
        alGenBuffers(1, &self.al_id)
        self.data = data
        self.frequency = frequency
    
    def __dealloc__(self):
        alDeleteBuffers(1, &self.al_id)
    
    cdef update(self):
        alBufferData(self.al_id, AL_FORMAT_MONO16, &self.data[0], len(self.data), self.frequency)

cdef class AudioSource:
    
    def __init__(self):
        #self._app.audio_system.sources.append(self)
        alGenSources(1, &self.al_id)
        
        self.buffer_ = None
        self.looping = False
        self.pitch = 1.0
        self.gain = 1.0
        self.direction = (0, 0, 0)
        self.position = (0, 0, 0)
        self.velocity = (0, 0, 0)
        self._action = "none"
        self._state = "initial"
        self._previous_offset = 0
        self._current_offset = 0
        
        self.max_distance = FLT_MAX
        self.rolloff_factor = 1.0
        self.reference_distance = 1.0
        self.min_gain = 0.0
        self.max_gain = 1.0
        self.cone_outer_gain = 0.0
        self.cone_inner_angle = 360.0
        self.cone_outer_angle = 360.0
        self.relative = False
        
    def __dealloc__(self):
        alDeleteSources(1, &self.al_id)
        #self._app.audio_system.sources.append(self)
    
    cpdef str get_state(self):
        return self._state

    cpdef str get_action(self):
        return self._action

    cpdef set_action(self, str new_action):
        self._action = new_action
        #self._app.event_system.emit("audio_action", {"source": self, "action": self._action})
    
    cpdef set_offset(self, str offset_format, float new_offset):
        if offset_format == "second":
            alSourcef(self.al_id, AL_SEC_OFFSET, new_offset)
        elif offset_format == "sample":
            alSourcef(self.al_id, AL_SAMPLE_OFFSET, new_offset)
        elif offset_format == "byte":
            alSourcei(self.al_id, AL_BYTE_OFFSET, <ALint>new_offset)
        else:
            raise ValueError("invalid offset_format value")

    cpdef float get_offset(self, str offset_format):
        cdef float offset
        cdef int * offset_int_ptr
        if offset_format == "second":
            alGetSourcef(self.al_id, AL_SEC_OFFSET, &offset)
        elif offset_format == "sample":
            alGetSourcef(self.al_id, AL_SAMPLE_OFFSET, &offset)
        elif offset_format == "byte":
            alGetSourcei(self.al_id, AL_BYTE_OFFSET, <ALint *>&offset)
            offset_int_ptr = <int *>&offset
            return offset_int_ptr[0]
        else:
            raise ValueError("invalid offset_format value")
        return float(offset)
    
    cpdef play(self):
        self.set_action("play")
        
    cpdef pause(self):
        self.set_action("pause")
        
    cpdef stop(self):
        self.set_action("stop")
        
    cpdef rewind(self):
        self.set_action("rewind")
        
    cdef update(self):
        cdef int state
        cdef int offset
        alGetSourcei(self.al_id, AL_SOURCE_STATE, &state)
        if state == AL_INITIAL:
            self._state = "initial"
        elif state == AL_PLAYING:
            self._state = "playing"
        elif state == AL_PAUSED:
            self._state = "paused"
        elif state == AL_STOPPED:
            self._state = "stopped"
        
        alSourcei(self.al_id, AL_BUFFER, self.buffer_.al_id)
        self._current_offset = self.get_offset("byte")
        self._previous_offset = self._current_offset
        
        alSourcei(self.al_id, AL_LOOPING, <int>self.looping)
        alSourcef(self.al_id, AL_PITCH, self.pitch)
        alSourcef(self.al_id, AL_GAIN, self.gain)
        alSourcefv(self.al_id, AL_DIRECTION, self.direction)
        alSourcefv(self.al_id, AL_POSITION, self.position)
        alSourcefv(self.al_id, AL_VELOCITY, self.velocity)
        alSourcef(self.al_id, AL_MAX_DISTANCE, self.max_distance)
        alSourcef(self.al_id, AL_ROLLOFF_FACTOR, self.rolloff_factor)
        alSourcef(self.al_id, AL_REFERENCE_DISTANCE, self.reference_distance)
        alSourcef(self.al_id, AL_MIN_GAIN, self.min_gain)
        alSourcef(self.al_id, AL_MAX_GAIN, self.max_gain)
        alSourcef(self.al_id, AL_CONE_OUTER_GAIN, self.cone_outer_gain)
        alSourcef(self.al_id, AL_CONE_INNER_ANGLE, self.cone_inner_angle)
        alSourcef(self.al_id, AL_CONE_OUTER_ANGLE, self.cone_outer_angle)
        alSourcei(self.al_id, AL_SOURCE_RELATIVE, int(self.relative))
        
        if self._action == "play":
            alSourcePlay(self.al_id)
        elif self._action == "pause":
            alSourcePause(self.al_id)
        elif self._action == "stop":
            alSourceStop(self.al_id)
        elif self._action == "rewind":
            alSourceRewind(self.al_id)
        self._action = "none"

cdef class AudioListener:
    
    def __init__(self):
        self.position = (0, 0, 0)
        self.velocity = (0, 0, 0)
        self.gain = 1.0
        self.orientation_at = (0, 0, -1)
        self.orientation_up = (0, 1, 0)
    
    cdef update(self):
        cdef float[6] at_up
        at_up[:3] = self.orientation_at
        at_up[3:] = self.orientation_up
        alListenerfv(AL_POSITION, self.position)
        alListenerfv(AL_VELOCITY, self.velocity)
        alListenerf(AL_GAIN, self.gain)
        alListenerfv(AL_ORIENTATION, at_up)

