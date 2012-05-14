(*
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

    Unit owners :
       Henri Gourvest <hgourvest@gmail.com>
       Pierr Yager <pierre.y@gmail.com>
*)

unit Crossroads.IO.API;

interface

uses
  winsock2;

const
  LIBXS = 'libxs.dll';

(******************************************************************************)
(*  Crossroads versioning support.                                                   *)
(******************************************************************************)

const
(*  Version macros for compile-time API version detection                     *)
  XS_VERSION_MAJOR = 1;
  XS_VERSION_MINOR = 1;
  XS_VERSION_PATCH = 1;

  XS_VERSION_ =
    XS_VERSION_MAJOR * 10000 +
    XS_VERSION_MINOR * 100 +
    XS_VERSION_PATCH;

(*  Run-time API version detection                                            *)
procedure xs_version (major, minor, patch: PInteger); cdecl; external LIBXS;

(******************************************************************************)
(*  Crossroads errors.                                                               *)
(******************************************************************************)

(*  A number random enough not to collide with different errno ranges on      *)
(*  different OSes. The assumption is that error_t is at least 32-bit type.   *)
const
  XS_HAUSNUMERO = 156384712;

(*  On Windows platform some of the standard POSIX errnos are not defined.    *)
  ENOTSUP         = (XS_HAUSNUMERO + 1);
  EPROTONOSUPPORT = (XS_HAUSNUMERO + 2);
  ENOBUFS         = (XS_HAUSNUMERO + 3);
  ENETDOWN        = (XS_HAUSNUMERO + 4);
  EADDRINUSE      = (XS_HAUSNUMERO + 5);
  EADDRNOTAVAIL   = (XS_HAUSNUMERO + 6);
  ECONNREFUSED    = (XS_HAUSNUMERO + 7);
  EINPROGRESS     = (XS_HAUSNUMERO + 8);
  ENOTSOCK        = (XS_HAUSNUMERO + 9);
  EAFNOSUPPORT    = (XS_HAUSNUMERO + 10);

(*  Native 0MQ error codes.                                                   *)
  EFSM           = (XS_HAUSNUMERO + 51);
  ENOCOMPATPROTO = (XS_HAUSNUMERO + 52);
  ETERM          = (XS_HAUSNUMERO + 53);
  EMTHREAD       = (XS_HAUSNUMERO + 54); (* Kept for backward compatibility.  *)
                                         (*  Not used anymore.                *)

(*  This function retrieves the errno as it is known to Crossroads library.   *)
(*  The goal of this function is to make the code 100% portable, including    *)
(*  where Crossroads are compiled with certain CRT library (on Windows)       *)
(*  is linked to an application that uses different CRT library.              *)
function xs_errno(): Integer; cdecl; external LIBXS;

(*  Resolves system errors and Crossroads errors to human-readable string.           *)
function xs_strerror(errnum: Integer): PAnsiChar; cdecl; external LIBXS;

(******************************************************************************)
(*  Crossroads message definition.                                                   *)
(******************************************************************************)

const
  XS_MAX_VSM_SIZE = 30;

type
  PXSMsg = ^TXSMsg;
  TXSMsg = record
  case Boolean of
   True: (
     content: Pointer;
     flags: Byte;
     vsm_size: Byte;
     vsm_data: array[0..XS_MAX_VSM_SIZE - 1] of Byte;
   );
   False: (
     _: array[0..(XS_MAX_VSM_SIZE + 1 + SizeOf(Pointer) + SizeOf(Byte) + SizeOf(Byte))] of Byte;
   );
  end;

  TXSFreeFunction = procedure(data, hint: Pointer); stdcall;

function xs_msg_init(msg: PXSMsg): Integer; cdecl; external LIBXS;
function xs_msg_init_size(msg: PXSMsg; size: Cardinal): Integer; cdecl; external LIBXS;
function xs_msg_init_data(msg: PXSMsg; data: Pointer; size: Cardinal; ffn: TXSFreeFunction; hint: Pointer): Integer; cdecl; external LIBXS;
function xs_msg_close(msg: PXSMsg): Integer; cdecl; external LIBXS;
function xs_msg_move(dest, src: PXSMsg): Integer; cdecl; external LIBXS;
function xs_msg_copy(dest, src: PXSMsg): Integer; cdecl; external LIBXS;
function xs_msg_data(msg: PXSMsg): Pointer; cdecl; external LIBXS;
function xs_msg_size(msg: PXSMsg): Cardinal; cdecl; external LIBXS;
function xs_getmsgopt (msg: PXSMsg; option: Integer; optval: Pointer; optvallen: PCardinal): Integer; cdecl; external LIBXS;

(******************************************************************************)
(*  Crossroads context definition.                                            *)
(******************************************************************************)

const
  XS_MAX_SOCKETS = 1;
  XS_IO_THREADS = 2;
  XS_PLUGIN = 3;

function xs_init(): Pointer; cdecl; external LIBXS;
function xs_term (context: Pointer): Integer; cdecl; external LIBXS;
function xs_setctxopt(context: Pointer; option: Integer; const optval: Pointer; optvallen: Cardinal): Integer; cdecl; external LIBXS;

(******************************************************************************)
(*  Crossroads socket definition.                                                    *)
(******************************************************************************)
const
(*  Socket types.                                                             *)
  XS_PAIR        = 0;
  XS_PUB         = 1;
  XS_SUB         = 2;
  XS_REQ         = 3;
  XS_REP         = 4;
  XS_DEALER      = 5;
  XS_ROUTER      = 6;
  XS_PULL        = 7;
  XS_PUSH        = 8;
  XS_XPUB        = 9;
  XS_XSUB        = 10;
  XS_SURVEYOR    = 11;
  XS_RESPONDENT  = 12;
  XS_XSURVEYOR   = 13;
  XS_XRESPONDENT = 14;

(*  Legacy socket type aliases.                                               *)
  XS_XREQ = XS_DEALER;
  XS_XREP = XS_ROUTER;

(*  Socket options.                                                           *)
  XS_AFFINITY            = 4;
  XS_IDENTITY            = 5;
  XS_SUBSCRIBE           = 6;
  XS_UNSUBSCRIBE         = 7;
  XS_RATE                = 8;
  XS_RECOVERY_IVL        = 9;
  XS_SNDBUF              = 11;
  XS_RCVBUF              = 12;
  XS_RCVMORE             = 13;
  XS_FD                  = 14;
  XS_EVENTS              = 15;
  XS_TYPE                = 16;
  XS_LINGER              = 17;
  XS_RECONNECT_IVL       = 18;
  XS_BACKLOG             = 19;
  XS_RECONNECT_IVL_MAX   = 21;
  XS_MAXMSGSIZE          = 22;
  XS_SNDHWM              = 23;
  XS_RCVHWM              = 24;
  XS_MULTICAST_HOPS      = 25;
  XS_RCVTIMEO            = 27;
  XS_SNDTIMEO            = 28;
  XS_IPV4ONLY            = 31;
  XS_KEEPALIVE           = 32;
  XS_PROTOCOL            = 33;
  XS_SURVEY_TIMEOUT      = 35;

(*  Message options                                                           *)
  XS_MORE = 1;

(*  Send/recv options.                                                        *)
  XS_DONTWAIT = 1;
  XS_SNDMORE  = 2;

function xs_socket(p: Pointer; kind: Integer): Pointer; cdecl; external LIBXS;
function xs_close(s: Pointer): Integer; cdecl; external LIBXS;
function xs_setsockopt(s: Pointer; option: Integer; const optval: Pointer; optvallen: Cardinal): Integer; cdecl; external LIBXS;
function xs_getsockopt (s: Pointer; option: Integer; optval: Pointer; optvallen: PCardinal): Integer; cdecl; external LIBXS;
function xs_bind(s: Pointer; const addr: PAnsiChar): Integer; cdecl; external LIBXS;
function xs_connect(s: Pointer; const addr: PAnsiChar): Integer; cdecl; external LIBXS;
function xs_shutdown (s: Pointer; how: Integer): Integer; cdecl; external LIBXS;
function xs_send(s: Pointer; const buf: Pointer; len: Cardinal; flags: Integer): Integer; cdecl; external LIBXS;
function xs_recv(s, buf: Pointer; len: Cardinal; flags: Integer): Integer; cdecl; external LIBXS;
function xs_sendmsg(s: Pointer; msg: PXSMsg; flags: Integer): Integer; cdecl; external LIBXS;
function xs_recvmsg(s: Pointer; msg: PXSMsg; flags: Integer): Integer; cdecl; external LIBXS;

(******************************************************************************)
(*  I/O multiplexing.                                                         *)
(******************************************************************************)

const
  XS_POLLIN  = 1;
  XS_POLLOUT = 2;
  XS_POLLERR = 4;

type
  PXSPollItem = ^TXSPollItem;
  TXSPollItem = record
    socket: Pointer;
    fd: TSocket;
    events: SmallInt;
    revents: SmallInt;
  end;

function xs_poll(items: PXSPollItem; nitems: Integer; timeout: LongInt): Integer; cdecl; external LIBXS;

(******************************************************************************)
(*  The following utility functions are exported for use from language        *)
(*  bindings in performance tests, for the purpose of consistent results in   *)
(*  such tests.  They are not considered part of the core XS API per se,      *)
(*  use at your own risk!                                                     *)
(******************************************************************************)

(*  Starts the stopwatch. Returns the handle to the watch.                    *)
function xs_stopwatch_start: Pointer; cdecl; external LIBXS;

(*  Stops the stopwatch. Returns the number of microseconds elapsed since     *)
(*  the stopwatch was started.                                                *)
function xs_stopwatch_stop(watch: Pointer): Cardinal; cdecl; external LIBXS;

(******************************************************************************)
(*  The API for pluggable filters.                                            *)
(*  THIS IS EXPERIMENTAL WORK AND MAY CHANGE WITHOUT PRIOR NOTICE.            *)
(******************************************************************************)

const
  XS_FILTER = 34;

  XS_PLUGIN_FILTER  = 1;

  XS_FILTER_ALL = 0;
  XS_FILTER_PREFIX = 1;

type
  PXSFilter = ^TXSFilter;
  TXSFilter = record
    kind: Integer;
    version: Integer;

    id: function(core: Pointer): Integer; cdecl;
    pf_create: function(core: Pointer): Pointer; cdecl;
    pf_destroy: procedure(core, pf: Pointer); cdecl;
    pf_subscribe: function(core, pf, subscriber: Pointer; const data: PByte; size: Cardinal): Integer; cdecl;
    pf_unsubscribe: function(core, pf, subscriber: Pointer; const data: PByte; size: Cardinal): Integer; cdecl;
    pf_unsubscribe_all: procedure(core, pf, subscriber: Pointer); cdecl;
    pf_match: procedure(core, pf: Pointer; const data: PByte; size: Cardinal); cdecl;

    sf_create: function(core: Pointer): Pointer; cdecl;
    sf_destroy: procedure(core, sf: Pointer); cdecl;
    sf_subscribe: function(core, sf: Pointer; const data: PByte; size: Cardinal): Integer; cdecl;
    sf_unsubscribe: function(core, sf: Pointer; const data: PByte; size: Cardinal): Integer; cdecl;
    sf_match: procedure(core, sf: Pointer; const data: PByte; size: Cardinal); cdecl;
  end;

function xs_filter_subscribed (core: Pointer; const data: PByte; size: Cardinal): Integer; cdecl; external LIBXS;
function xs_filter_unsubscribed (core: Pointer; const data: PByte; size: Cardinal): Integer; cdecl; external LIBXS;
function xs_filter_matching (core, subscriber: Pointer): Integer; cdecl; external LIBXS;

implementation

end.
