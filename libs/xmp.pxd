cdef extern from "xmp.h" nogil:
    ctypedef char * xmp_context
    cdef enum: XMP_MAX_CHANNELS
    cdef enum: XMP_MAX_FRAMESIZE
    cdef enum: XMP_FORMAT_UNSIGNED
    cdef enum: XMP_FORMAT_MONO

    cdef struct xmp_channel_info:
        pass

    cdef struct xmp_frame_info:
        int pos
        int pattern
        int row
        int num_rows
        int frame
        int speed
        int bpm
        int time
        int total_time
        int frame_time
        void *buffer
        int buffer_size
        int total_size
        int volume
        int loop_count
        int virt_channels
        int virt_used
        int sequence
        xmp_channel_info[XMP_MAX_CHANNELS] channel_info

    xmp_context xmp_create_context()
    void xmp_free_context(xmp_context c)
    int xmp_load_module(xmp_context c, char *path)
    int xmp_start_player(xmp_context c, int rate, int format)
    int xmp_play_frame(xmp_context c)
    void xmp_get_frame_info(xmp_context c, xmp_frame_info *info)
    int xmp_play_buffer(xmp_context c, void *buffer, int size, int loop)
    void xmp_end_player(xmp_context c)
    void xmp_release_module(xmp_context c)
    
