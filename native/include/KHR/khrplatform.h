#ifndef __khrplatform_h_
#define __khrplatform_h_

#include <stdint.h>

#define KHRONOS_APICALL
#define KHRONOS_APIENTRY
#define KHRONOS_APIATTRIBUTES

typedef int32_t                 khronos_int32_t;
typedef uint32_t                khronos_uint32_t;
typedef int64_t                 khronos_int64_t;
typedef uint64_t                khronos_uint64_t;
typedef int8_t                  khronos_int8_t;
typedef uint8_t                 khronos_uint8_t;
typedef int16_t                 khronos_int16_t;
typedef uint16_t                khronos_uint16_t;
typedef float                   khronos_float_t;
typedef khronos_uint64_t        khronos_utime_nanoseconds_t;
typedef khronos_int64_t         khronos_stime_nanoseconds_t;

#endif
