/*
    Copyright (c) 2009-2012 250bpm s.r.o.
    Copyright (c) 2007-2010 iMatix Corporation
    Copyright (c) 2011 VMware, Inc.
    Copyright (c) 2007-2011 Other contributors as noted in the AUTHORS file

    This file is part of Crossroads I/O project.

    Crossroads I/O is free software; you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    Crossroads is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __XS_H_INCLUDED__
#define __XS_H_INCLUDED__

#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <stddef.h>
#if defined _WIN32
#include <winsock2.h>
#endif

/*  Handle DSO symbol visibility                                             */
#if defined _WIN32
#   if defined DLL_EXPORT
#       define XS_EXPORT __declspec(dllexport)
#   else
#       define XS_EXPORT __declspec(dllimport)
#   endif
#else
#   if defined __SUNPRO_C  || defined __SUNPRO_CC
#       define XS_EXPORT __global
#   elif (defined __GNUC__ && __GNUC__ >= 4) || defined __INTEL_COMPILER
#       define XS_EXPORT __attribute__ ((visibility("default")))
#   else
#       define XS_EXPORT
#   endif
#endif

/******************************************************************************/
/*  Crossroads versioning support.                                            */
/******************************************************************************/

/*  Version macros for compile-time API version detection                     */
#define XS_VERSION_MAJOR 1
#define XS_VERSION_MINOR 1
#define XS_VERSION_PATCH 0

#define XS_MAKE_VERSION(major, minor, patch) \
    ((major) * 10000 + (minor) * 100 + (patch))
#define XS_VERSION \
    XS_MAKE_VERSION(XS_VERSION_MAJOR, XS_VERSION_MINOR, XS_VERSION_PATCH)

/*  Run-time API version detection                                            */
XS_EXPORT void xs_version (int *major, int *minor, int *patch);

/******************************************************************************/
/*  Crossroads errors.                                                        */
/******************************************************************************/

/*  A number random enough not to collide with different errno ranges on      */
/*  different OSes. The assumption is that error_t is at least 32-bit type.   */
#define XS_HAUSNUMERO 156384712

/*  On Windows platform some of the standard POSIX errnos are not defined.    */
#ifndef ENOTSUP
#define ENOTSUP (XS_HAUSNUMERO + 1)
#endif
#ifndef EPROTONOSUPPORT
#define EPROTONOSUPPORT (XS_HAUSNUMERO + 2)
#endif
#ifndef ENOBUFS
#define ENOBUFS (XS_HAUSNUMERO + 3)
#endif
#ifndef ENETDOWN
#define ENETDOWN (XS_HAUSNUMERO + 4)
#endif
#ifndef EADDRINUSE
#define EADDRINUSE (XS_HAUSNUMERO + 5)
#endif
#ifndef EADDRNOTAVAIL
#define EADDRNOTAVAIL (XS_HAUSNUMERO + 6)
#endif
#ifndef ECONNREFUSED
#define ECONNREFUSED (XS_HAUSNUMERO + 7)
#endif
#ifndef EINPROGRESS
#define EINPROGRESS (XS_HAUSNUMERO + 8)
#endif
#ifndef ENOTSOCK
#define ENOTSOCK (XS_HAUSNUMERO + 9)
#endif
#ifndef EAFNOSUPPORT
#define EAFNOSUPPORT (XS_HAUSNUMERO + 10)
#endif

/*  Native Crossroads error codes.                                            */
#define EFSM (XS_HAUSNUMERO + 51)
#define ENOCOMPATPROTO (XS_HAUSNUMERO + 52)
#define ETERM (XS_HAUSNUMERO + 53)
#define EMTHREAD (XS_HAUSNUMERO + 54)  /*  Kept for backward compatibility.   */
                                       /*  Not used anymore.                  */

/*  This function retrieves the errno as it is known to Crossroads library.   */
/*  The goal of this function is to make the code 100% portable, including    */
/*  where Crossroads are compiled with certain CRT library (on Windows) is    */
/*  linked to an application that uses different CRT library.                 */
XS_EXPORT int xs_errno (void);

/*  Resolves system errors and Crossroads errors to human-readable string.    */
XS_EXPORT const char *xs_strerror (int errnum);

/******************************************************************************/
/*  Crossroads message definition.                                            */
/******************************************************************************/

typedef struct {unsigned char _ [32];} xs_msg_t;

typedef void (xs_free_fn) (void *data, void *hint);

XS_EXPORT int xs_msg_init (xs_msg_t *msg);
XS_EXPORT int xs_msg_init_size (xs_msg_t *msg, size_t size);
XS_EXPORT int xs_msg_init_data (xs_msg_t *msg, void *data,
    size_t size, xs_free_fn *ffn, void *hint);
XS_EXPORT int xs_msg_close (xs_msg_t *msg);
XS_EXPORT int xs_msg_move (xs_msg_t *dest, xs_msg_t *src);
XS_EXPORT int xs_msg_copy (xs_msg_t *dest, xs_msg_t *src);
XS_EXPORT void *xs_msg_data (xs_msg_t *msg);
XS_EXPORT size_t xs_msg_size (xs_msg_t *msg);
XS_EXPORT int xs_getmsgopt (xs_msg_t *msg, int option, void *optval,
    size_t *optvallen);

/******************************************************************************/
/*  Crossroads context definition.                                            */
/******************************************************************************/

#define XS_MAX_SOCKETS 1
#define XS_IO_THREADS 2
#define XS_PLUGIN 3

XS_EXPORT void *xs_init (void);
XS_EXPORT int xs_term (void *context);
XS_EXPORT int xs_setctxopt (void *context, int option, const void *optval,
    size_t optvallen);

/******************************************************************************/
/*  Crossroads socket definition.                                             */
/******************************************************************************/

/*  Socket types.                                                             */
#define XS_PAIR 0
#define XS_PUB 1
#define XS_SUB 2
#define XS_REQ 3
#define XS_REP 4
#define XS_XREQ 5
#define XS_XREP 6
#define XS_PULL 7
#define XS_PUSH 8
#define XS_XPUB 9
#define XS_XSUB 10
#define XS_SURVEYOR 11
#define XS_RESPONDENT 12
#define XS_XSURVEYOR 13
#define XS_XRESPONDENT 14

/*  Legacy socket type aliases.                                               */
#define XS_ROUTER XS_XREP
#define XS_DEALER XS_XREQ

/*  Socket options.                                                           */
#define XS_AFFINITY 4
#define XS_IDENTITY 5
#define XS_SUBSCRIBE 6
#define XS_UNSUBSCRIBE 7
#define XS_RATE 8
#define XS_RECOVERY_IVL 9
#define XS_SNDBUF 11
#define XS_RCVBUF 12
#define XS_RCVMORE 13
#define XS_FD 14
#define XS_EVENTS 15
#define XS_TYPE 16
#define XS_LINGER 17
#define XS_RECONNECT_IVL 18
#define XS_BACKLOG 19
#define XS_RECONNECT_IVL_MAX 21
#define XS_MAXMSGSIZE 22
#define XS_SNDHWM 23
#define XS_RCVHWM 24
#define XS_MULTICAST_HOPS 25
#define XS_RCVTIMEO 27
#define XS_SNDTIMEO 28
#define XS_IPV4ONLY 31
#define XS_KEEPALIVE 32
#define XS_PROTOCOL 33
#define XS_SURVEY_TIMEOUT 35

/*  Message options                                                           */
#define XS_MORE 1

/*  Send/recv options.                                                        */
#define XS_DONTWAIT 1
#define XS_SNDMORE 2

XS_EXPORT void *xs_socket (void *context, int type);
XS_EXPORT int xs_close (void *s);
XS_EXPORT int xs_setsockopt (void *s, int option, const void *optval,
    size_t optvallen); 
XS_EXPORT int xs_getsockopt (void *s, int option, void *optval,
    size_t *optvallen);
XS_EXPORT int xs_bind (void *s, const char *addr);
XS_EXPORT int xs_connect (void *s, const char *addr);
XS_EXPORT int xs_shutdown (void *s, int how);
XS_EXPORT int xs_send (void *s, const void *buf, size_t len, int flags);
XS_EXPORT int xs_recv (void *s, void *buf, size_t len, int flags);
XS_EXPORT int xs_sendmsg (void *s, xs_msg_t *msg, int flags);
XS_EXPORT int xs_recvmsg (void *s, xs_msg_t *msg, int flags);

/******************************************************************************/
/*  I/O multiplexing.                                                         */
/******************************************************************************/

#define XS_POLLIN 1
#define XS_POLLOUT 2
#define XS_POLLERR 4

typedef struct
{
    void *socket;
#if defined _WIN32
    SOCKET fd;
#else
    int fd;
#endif
    short events;
    short revents;
} xs_pollitem_t;

XS_EXPORT int xs_poll (xs_pollitem_t *items, int nitems, int timeout);

/******************************************************************************/
/*  The following utility functions are exported for use from language        */
/*  bindings in performance tests, for the purpose of consistent results in   */
/*  such tests.  They are not considered part of the core XS API per se,      */
/*  use at your own risk!                                                     */
/******************************************************************************/

/*  Starts the stopwatch. Returns the handle to the watch.                    */
XS_EXPORT void *xs_stopwatch_start (void);

/*  Stops the stopwatch. Returns the number of microseconds elapsed since     */
/*  the stopwatch was started.                                                */
XS_EXPORT unsigned long xs_stopwatch_stop (void *watch);

/******************************************************************************/
/*  The API for pluggable filters.                                            */
/*  THIS IS EXPERIMENTAL WORK AND MAY CHANGE WITHOUT PRIOR NOTICE.            */
/******************************************************************************/

#define XS_FILTER 34

#define XS_PLUGIN_FILTER 1

#define XS_FILTER_ALL 0
#define XS_FILTER_PREFIX 1

typedef struct
{
    int type;
    int version;

    int (*id) (void *core);
    void *(*pf_create) (void *core);
    void (*pf_destroy) (void *core, void *pf);
    int (*pf_subscribe) (void *core, void *pf, void *subscriber,
        const unsigned char *data, size_t size);
    int (*pf_unsubscribe) (void *core, void *pf, void *subscriber,
        const unsigned char *data, size_t size);
    void (*pf_unsubscribe_all) (void *core, void *pf, void *subscriber);
    void (*pf_match) (void *core, void *pf,
        const unsigned char *data, size_t size);

    void *(*sf_create) (void *core);
    void (*sf_destroy) (void *core, void *sf);
    int (*sf_subscribe) (void *core, void *sf,
        const unsigned char *data, size_t size);
    int (*sf_unsubscribe) (void *core, void *sf,
        const unsigned char *data, size_t size);
    int (*sf_match) (void *core, void *sf,
        const unsigned char *data, size_t size);

} xs_filter_t;

XS_EXPORT int xs_filter_subscribed (void *core,
    const unsigned char *data, size_t size);

XS_EXPORT int xs_filter_unsubscribed (void *core,
    const unsigned char *data, size_t size);

XS_EXPORT int xs_filter_matching (void *core, void *subscriber);

#undef XS_EXPORT

#ifdef __cplusplus
}
#endif

#endif

