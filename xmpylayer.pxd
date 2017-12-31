from cpython.exc cimport PyErr_CheckSignals
from cpython cimport bool
from libc.float cimport FLT_MAX
from libc.stdint cimport uint16_t
from libc.stdlib cimport malloc, free
from libs.xmp cimport *
from libs.al cimport *

cdef class AudioSystem:
    cdef ALCdevice * al_device
    cdef ALCcontext * al_context
    cdef xmp_context context
    cdef list sources
    cdef AudioListener listener

cdef class AudioBuffer:
    cdef ALuint al_id 
    cdef public str format_
    cdef public uint16_t[:] data
    cdef public int frequency
    cdef update(self)

cdef class AudioSource:
    cdef ALuint al_id
    cdef str _state
    cdef str _action
    cdef float _previous_offset
    cdef float _current_offset
    cdef public AudioBuffer buffer_
    cdef public bool looping
    cdef public float pitch
    cdef public float gain
    cdef public float[3] direction
    cdef public float[3] position
    cdef public float[3] velocity
    cdef public float max_distance
    cdef public float rolloff_factor
    cdef public float reference_distance
    cdef public float min_gain
    cdef public float max_gain
    cdef public float cone_outer_gain
    cdef public float cone_inner_angle
    cdef public float cone_outer_angle
    cdef public bool relative
    cpdef set_offset(self, str offset_format, float new_offset)
    cpdef float get_offset(self, str offset_format)
    cpdef str get_state(self)
    cpdef str get_action(self)
    cpdef set_action(self, str new_action)
    cpdef play(self)
    cpdef pause(self)
    cpdef stop(self)
    cpdef rewind(self)
    cdef update(self)

cdef class AudioListener:
    cdef public float[3] position
    cdef public float[3] velocity
    cdef public float gain
    cdef public float[3] orientation_at
    cdef public float[3] orientation_up    
    cdef update(self)
