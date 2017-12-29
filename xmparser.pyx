import threading, time
from cpython.exc cimport PyErr_CheckSignals
from cpython cimport bool
from libc.stdint cimport uint16_t
from libc.stdlib cimport malloc, free
from xmp cimport *
from al cimport *

cdef ALCdevice * al_dev
cdef ALCcontext * al_ctx
cdef int NUM_BUFFERS = 6
cdef int BUFFER_SIZE = 4096
cdef ALuint source
cdef ALuint * buffers = <ALuint *>malloc(NUM_BUFFERS * sizeof(ALuint))

al_dev = alcOpenDevice(NULL)
al_ctx = alcCreateContext(al_dev, NULL)
alcMakeContextCurrent(al_ctx)
alGenBuffers(NUM_BUFFERS, buffers)
alGenSources(1, &source)

cdef xmp_context ctx
cdef xmp_frame_info fi
cdef int row, i
cdef char * b

b = <char *>malloc(BUFFER_SIZE)
ctx = xmp_create_context()
xmp_load_module(ctx, "zeta_force_level_2.xm")
xmp_start_player(ctx, 44100, 0)

cdef ALuint fmt = AL_FORMAT_STEREO16
cdef ALuint freq = 44100
for i in range(NUM_BUFFERS):
    xmp_play_buffer(ctx, b, BUFFER_SIZE, 0)
    alBufferData(buffers[i], fmt, b, BUFFER_SIZE, freq)
alSourceQueueBuffers(source, NUM_BUFFERS, buffers)
alSourcePlay(source)

cdef ALuint buffer
cdef ALint val
while xmp_play_buffer(ctx, b, BUFFER_SIZE, 0) == 0:
    alGetSourcei(source, AL_BUFFERS_PROCESSED, &val)
    while val <= 0:
        PyErr_CheckSignals()#to allow quitting
        alGetSourcei(source, AL_BUFFERS_PROCESSED, &val)
    xmp_get_frame_info(ctx, &fi)
    alSourceUnqueueBuffers(source, 1, &buffer)
    alBufferData(buffer, fmt, b, BUFFER_SIZE, freq)
    alSourceQueueBuffers(source, 1, &buffer)
    alGetSourcei(source, AL_SOURCE_STATE, &val)
    if val != AL_PLAYING:
        alSourcePlay(source)

xmp_end_player(ctx)
xmp_release_module(ctx)
xmp_free_context(ctx)

alDeleteSources(1, &source)
alDeleteBuffers(NUM_BUFFERS, buffers)
alcMakeContextCurrent(NULL)
alcDestroyContext(al_ctx)
alcCloseDevice(al_dev)
