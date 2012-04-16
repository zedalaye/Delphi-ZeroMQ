(*
    Copyright (c) 2007-2011 iMatix Corporation
    Copyright (c) 2007-2011 Other contributors as noted in the AUTHORS file

    This file is part of 0MQ.

    0MQ is free software; you can redistribute it and/or modify it under
    the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    0MQ is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Unit owners :
       Henri Gourvest <hgourvest@gmail.com>
       Pierr Yager <pierre.y@gmail.com>
*)

unit ZeroMQ.API;

interface

uses
  winsock2;

const
  LIBZEROMQ = 'libzmq.dll';

{.$DEFINE EXPERIMENTAL}

(******************************************************************************)
(*  0MQ versioning support.                                                   *)
(******************************************************************************)

const
(*  Version macros for compile-time API version detection                     *)
  ZMQ_VERSION_MAJOR = 3;
  ZMQ_VERSION_MINOR = 1;
{$IFNDEF EXPERIMENTAL}
  ZMQ_VERSION_PATCH = 0;
{$ELSE}
  ZMQ_VERSION_PATCH = 1;
{$ENDIF}

  ZMQ_VERSION_ =
    ZMQ_VERSION_MAJOR * 10000 +
    ZMQ_VERSION_MINOR * 100 +
    ZMQ_VERSION_PATCH;

(*  Run-time API version detection                                            *)
procedure zmq_version (major, minor, patch: PInteger); cdecl; external LIBZEROMQ;

(******************************************************************************)
(*  0MQ errors.                                                               *)
(******************************************************************************)

(*  A number random enough not to collide with different errno ranges on      *)
(*  different OSes. The assumption is that error_t is at least 32-bit type.   *)
const
  ZMQ_HAUSNUMERO = 156384712;

(*  On Windows platform some of the standard POSIX errnos are not defined.    *)
  ENOTSUP         = (ZMQ_HAUSNUMERO + 1);
  EPROTONOSUPPORT = (ZMQ_HAUSNUMERO + 2);
  ENOBUFS         = (ZMQ_HAUSNUMERO + 3);
  ENETDOWN        = (ZMQ_HAUSNUMERO + 4);
  EADDRINUSE      = (ZMQ_HAUSNUMERO + 5);
  EADDRNOTAVAIL   = (ZMQ_HAUSNUMERO + 6);
  ECONNREFUSED    = (ZMQ_HAUSNUMERO + 7);
  EINPROGRESS     = (ZMQ_HAUSNUMERO + 8);
  ENOTSOCK        = (ZMQ_HAUSNUMERO + 9);
  EAFNOSUPPORT    = (ZMQ_HAUSNUMERO + 10);
  EHOSTUNREACH    = (ZMQ_HAUSNUMERO + 11);

(*  Native 0MQ error codes.                                                   *)
  EFSM           = (ZMQ_HAUSNUMERO + 51);
  ENOCOMPATPROTO = (ZMQ_HAUSNUMERO + 52);
  ETERM          = (ZMQ_HAUSNUMERO + 53);
  EMTHREAD       = (ZMQ_HAUSNUMERO + 54);

(*  This function retrieves the errno as it is known to 0MQ library. The goal *)
(*  of this function is to make the code 100% portable, including where 0MQ   *)
(*  compiled with certain CRT library (on Windows) is linked to an            *)
(*  application that uses different CRT library.                              *)
  function zmq_errno(): Integer; cdecl; external LIBZEROMQ;

(*  Resolves system errors and 0MQ errors to human-readable string.           *)
  function zmq_strerror(errnum: Integer): PAnsiChar; cdecl; external LIBZEROMQ;

{$IFDEF EXPERIMENTAL}
(******************************************************************************)
(*  0MQ infrastructure (a.k.a. context) initialisation & termination.         *)
(******************************************************************************)
const
(*  New API                                                                   *)
(*  Context options                                                           *)
  ZMQ_IO_THREADS  = 1;
  ZMQ_MAX_SOCKETS = 2;

(*  Default for new contexts                                                  *)
  ZMQ_IO_THREADS_DFLT  = 1;
  ZMQ_MAX_SOCKETS_DFLT = 1024;

function zmq_ctx_new(): Pointer; cdecl; external LIBZEROMQ;
function zmq_ctx_destroy(context: Pointer): Integer; cdecl; external LIBZEROMQ;
function zmq_ctx_set(context: Pointer; option, optval: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_ctx_get(context: Pointer; option: Integer): Integer; cdecl; external LIBZEROMQ;
{$ENDIF}

(*  Old (legacy) API                                                          *)
function zmq_init(io_threads: Integer): Pointer; cdecl; external LIBZEROMQ;
function zmq_term (context: Pointer): Integer; cdecl; external LIBZEROMQ;

(******************************************************************************)
(*  0MQ message definition.                                                   *)
(******************************************************************************)

type
  PZmqMsg = ^TZmqMsg;
  TZmqMsg = record
    _: array[0..31] of Byte;
  end;

  TZmqFreeFunction = procedure(data, hint: Pointer); stdcall;

function zmq_msg_init(msg: PZmqMsg): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_init_size(msg: PZmqMsg; size: Cardinal): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_init_data(msg: PZmqMsg; data: Pointer; size: Cardinal; ffn: TZmqFreeFunction; hint: Pointer): Integer; cdecl; external LIBZEROMQ;
{$IFDEF EXPERIMENTAL}
function zmq_msg_send(msg: PZmqMsg; s: Pointer; flags: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_recv(msg: PZmqMsg; s: Pointer; flags: Integer): Integer; cdecl; external LIBZEROMQ;
{$ENDIF}
function zmq_msg_close(msg: PZmqMsg): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_move(dest, src: PZmqMsg): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_copy(dest, src: PZmqMsg): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_data(msg: PZmqMsg): Pointer; cdecl; external LIBZEROMQ;
function zmq_msg_size(msg: PZmqMsg): Cardinal; cdecl; external LIBZEROMQ;
function zmq_getmsgopt (msg: PZmqMsg; option: Integer; optval: Pointer; optvallen: PCardinal): Integer; cdecl; external LIBZEROMQ;
{$IFDEF EXPERIMENTAL}
function zmq_msg_more(msg: PZmqMsg): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_get(msg: PZmqMsg; option: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_msg_set(msg: PZmqMsg; option, optval: Integer): Integer; cdecl; external LIBZEROMQ;
{$ENDIF}

(******************************************************************************)
(*  0MQ socket definition.                                                    *)
(******************************************************************************)
const
(*  Socket types.                                                             *)
  ZMQ_PAIR   = 0;
  ZMQ_PUB    = 1;
  ZMQ_SUB    = 2;
  ZMQ_REQ    = 3;
  ZMQ_REP    = 4;
  ZMQ_DEALER = 5;
  ZMQ_ROUTER = 6;
  ZMQ_PULL   = 7;
  ZMQ_PUSH   = 8;
  ZMQ_XPUB   = 9;
  ZMQ_XSUB   = 10;

(*  Deprecated aliases                                                        *)
  ZMQ_XREQ = ZMQ_DEALER;
  ZMQ_XREP = ZMQ_ROUTER;

(*  Socket options.                                                           *)
  ZMQ_AFFINITY            = 4;
  ZMQ_IDENTITY            = 5;
  ZMQ_SUBSCRIBE           = 6;
  ZMQ_UNSUBSCRIBE         = 7;
  ZMQ_RATE                = 8;
  ZMQ_RECOVERY_IVL        = 9;
  ZMQ_SNDBUF              = 11;
  ZMQ_RCVBUF              = 12;
  ZMQ_RCVMORE             = 13;
  ZMQ_FD                  = 14;
  ZMQ_EVENTS              = 15;
  ZMQ_TYPE                = 16;
  ZMQ_LINGER              = 17;
  ZMQ_RECONNECT_IVL       = 18;
  ZMQ_BACKLOG             = 19;
  ZMQ_RECONNECT_IVL_MAX   = 21;
  ZMQ_MAXMSGSIZE          = 22;
  ZMQ_SNDHWM              = 23;
  ZMQ_RCVHWM              = 24;
  ZMQ_MULTICAST_HOPS      = 25;
  ZMQ_RCVTIMEO            = 27;
  ZMQ_SNDTIMEO            = 28;
  ZMQ_IPV4ONLY            = 31;
{$IFDEF EXPERIMENTAL}
  ZMQ_LAST_ENDPOINT       = 32;
  ZMQ_FAIL_UNROUTABLE     = 33;
  ZMQ_TCP_KEEPALIVE       = 34;
  ZMQ_TCP_KEEPALIVE_CNT   = 35;
  ZMQ_TCP_KEEPALIVE_IDLE  = 36;
  ZMQ_TCP_KEEPALIVE_INTVL = 37;
{$ENDIF}

(*  Message options                                                           *)
  ZMQ_MORE = 1;

(*  Send/recv options.                                                        *)
  ZMQ_DONTWAIT = 1;
  ZMQ_SNDMORE  = 2;

function zmq_socket(p: Pointer; kind: Integer): Pointer; cdecl; external LIBZEROMQ;
function zmq_close(s: Pointer): Integer; cdecl; external LIBZEROMQ;
function zmq_setsockopt(s: Pointer; option: Integer; const optval: Pointer; optvallen: Cardinal): Integer; cdecl; external LIBZEROMQ;
function zmq_getsockopt (s: Pointer; option: Integer; optval: Pointer; optvallen: PCardinal): Integer; cdecl; external LIBZEROMQ;
function zmq_bind(s: Pointer; const addr: PAnsiChar): Integer; cdecl; external LIBZEROMQ;
function zmq_connect(s: Pointer; const addr: PAnsiChar): Integer; cdecl; external LIBZEROMQ;
function zmq_send(s: Pointer; const buf: Pointer; len: Cardinal; flags: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_recv(s, buf: Pointer; len: Cardinal; flags: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_sendmsg(s: Pointer; msg: PZmqMsg; flags: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_recvmsg(s: Pointer; msg: PZmqMsg; flags: Integer): Integer; cdecl; external LIBZEROMQ;

(******************************************************************************)
(*  I/O multiplexing.                                                         *)
(******************************************************************************)

const
  ZMQ_POLLIN = 1;
  ZMQ_POLLOUT = 2;
  ZMQ_POLLERR = 4;

type
  PZmqPollItem = ^TZmqPollItem;
  TZmqPollItem = record
    socket: Pointer;
    fd: TSocket;
    events: SmallInt;
    revents: SmallInt;
  end;

function zmq_poll(items: PZmqPollItem; nitems: Integer; timeout: LongInt): Integer; cdecl; external LIBZEROMQ;

{$IFDEF EXPERIMENTAL}
(******************************************************************************)
(*  Experimental                                                              *)
(******************************************************************************)
type
  PZMQIOVec = ^TZMQIOVec;
  TZMQIOVec = record
    iov_base: Pointer;
    iov_len: Cardinal;
  end;

function zmq_sendiov(s: Pointer; iov: PZMQIOVec; count: Cardinal; flags: Integer): Integer; cdecl; external LIBZEROMQ;
function zmq_recviov(s: Pointer; iov: PZMQIOVec; count: PCardinal; flags: Integer): Integer; cdecl; external LIBZEROMQ;

(******************************************************************************)
(*  Devices - Experimental.                                                   *)
(******************************************************************************)

const
  ZMQ_STREAMER  = 1;
  ZMQ_FORWARDER = 2;
  ZMQ_QUEUE     = 3;

function zmq_device(device: Integer; insocket, outsocket: Pointer): Integer; cdecl; external LIBZEROMQ;
{$ENDIF}

implementation

end.
