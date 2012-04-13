(*
    Unit owner :
       Pierr Yager <pierre.y@gmail.com>
*)

unit ZeroMQ.Wrapper;

interface

uses
  Generics.Collections,
  ZeroMQ.API;

type
  ZMQ = (
    Pair,
    Publisher, Subscriber,
    Requester, Responder,
    Dealer, Router,
    Pull, Push,
    XPublisher, XSubscriber
  );

  MessageFlag = (DontWait, SendMore);
  MessageFlags = set of MessageFlag;

  PollEvent = (PollIn, PollOut, PollErr);
  PollEvents = set of PollEvent;

  IZMQPair = interface
  ['{7F6D7BE5-7182-4972-96E1-4B5798608DDE}']
    function Connect(const Address: string): Integer;
    function Bind(const Address: string): Integer;
    function Subscribe(const Filter: string): Integer;
    function SendString(const Data: string; Flags: MessageFlags = []): Integer;
    function ReceiveString(Flags: MessageFlags = []): string;
    function ReceiveMessage(var Msg: TZmqMsg; Flags: MessageFlags = []): Integer;
  end;

  TZMQPollEvent = reference to procedure (Events: PollEvents);

  IZMQPoll = interface
    procedure RegisterPair(const Pair: IZMQPair; Events: PollEvents = []; const Proc: TZMQPollEvent = nil);
    function PollOnce(Timeout: Integer = -1): Integer;
    procedure FireEvents;
  end;

  IZeroMQ = interface
    ['{593FC079-23AD-451E-8877-11584E93D80E}']
    function Start(Kind: ZMQ): IZMQPair;
    function Poller: IZMQPoll;
    function InitMessage(var Msg: TZmqMsg; Size: Integer = 0): Integer;
    function CloseMessage(var Msg: TZmqMsg): Integer;
  end;

  TZeroMQ = class(TInterfacedObject, IZeroMQ)
  private
    FContext: Pointer;
    FPairs: TList<IZMQPair>;
  public
    constructor Create(IoThreads: Integer = 1);
    destructor Destroy; override;
    function Start(Kind: ZMQ): IZMQPair;
    function Poller: IZMQPoll;
    function InitMessage(var Msg: TZmqMsg; Size: Integer = 0): Integer;
    function CloseMessage(var Msg: TZmqMsg): Integer;
  end;

implementation

type
  TZMQPair = class(TInterfacedObject, IZMQPair)
  private
    FSocket: Pointer;
  public
    constructor Create(Socket: Pointer);
    destructor Destroy; override;
    function Bind(const Address: string): Integer;
    function Connect(const Address: string): Integer;
    function Subscribe(const Filter: string): Integer;
    function SendString(const Data: string; Flags: MessageFlags = []): Integer;
    function ReceiveString(Flags: MessageFlags = []): string;
    function ReceiveMessage(var Msg: TZmqMsg; Flags: MessageFlags = []): Integer;
  end;

  TZMQPoll = class(TInterfacedObject, IZMQPoll)
  private
    FPollItems: TArray<TZmqPollItem>;
    FPollEvents: TArray<TZMQPollEvent>;
  public
    procedure RegisterPair(const Pair: IZMQPair; Events: PollEvents = []; const Event: TZMQPollEvent = nil);
    function PollOnce(Timeout: Integer = -1): Integer;
    procedure FireEvents;
  end;

{ TZeroMQ }

constructor TZeroMQ.Create(IoThreads: Integer);
begin
  inherited Create;
  FPairs := TList<IZMQPair>.Create;
  FContext := zmq_init(IoThreads);
end;

destructor TZeroMQ.Destroy;
begin
  FPairs.Free;
  zmq_term(FContext);
  inherited;
end;

function TZeroMQ.Start(Kind: ZMQ): IZMQPair;
begin
  Result := TZMQPair.Create(zmq_socket(FContext, Ord(Kind)));
  FPairs.Add(Result);
end;

function TZeroMQ.InitMessage(var Msg: TZmqMsg; Size: Integer): Integer;
begin
  if Size = 0 then
    Result := zmq_msg_init(@Msg)
  else
    Result := zmq_msg_init_size(@Msg, Size)
end;

function TZeroMQ.Poller: IZMQPoll;
begin
  Result := TZMQPoll.Create;
end;

function TZeroMQ.CloseMessage(var Msg: TZmqMsg): Integer;
begin
  Result := zmq_msg_close(@Msg);
end;

{ TZMQPair }

constructor TZMQPair.Create(Socket: Pointer);
begin
  inherited Create;
  FSocket := Socket;
end;

destructor TZMQPair.Destroy;
begin
  zmq_close(FSocket);
  inherited;
end;

function TZMQPair.Bind(const Address: string): Integer;
begin
  Result := zmq_bind(FSocket, PAnsiChar(AnsiString(Address)));
end;

function TZMQPair.Connect(const Address: string): Integer;
begin
  Result := zmq_connect(FSocket, PAnsiChar(AnsiString(Address)));
end;

function TZMQPair.Subscribe(const Filter: string): Integer;
var
  str: UTF8String;
begin
  str := UTF8String(Filter);
  Result := zmq_setsockopt(FSocket, ZMQ_SUBSCRIBE, PAnsiChar(str), Length(str));
end;

function TZMQPair.ReceiveMessage(var Msg: TZmqMsg;
  Flags: MessageFlags): Integer;
begin
  Result := zmq_recvmsg(FSocket, @Msg, Byte(Flags));
end;

function TZMQPair.ReceiveString(Flags: MessageFlags): string;
var
  msg: TZmqMsg;
  str: UTF8String;
  len: Cardinal;
begin
  zmq_msg_init(@msg);
  if zmq_recvmsg(FSocket, @msg, Byte(Flags)) = 0 then
    Exit('');

  len := zmq_msg_size(@msg);
  SetLength(str, len);
  Move(zmq_msg_data(@msg)^, PAnsiChar(str)^, len);
  zmq_msg_close(@msg);
  Result := string(str);
end;

function TZMQPair.SendString(const Data: string; Flags: MessageFlags): Integer;
var
  msg: TZmqMsg;
  str: UTF8String;
  len: Integer;
begin
  str := UTF8String(Data);
  len := Length(str);
  zmq_msg_init_size(@msg, len);
  Move(PAnsiChar(str)^, zmq_msg_data(@msg)^, len);
  Result := zmq_sendmsg(FSocket, @msg, Byte(Flags));
  zmq_msg_close(@msg);
end;

{ TZMQPoll }

procedure TZMQPoll.RegisterPair(const Pair: IZMQPair; Events: PollEvents;
  const Event: TZMQPollEvent);
var
  P: PZmqPollItem;
begin
  SetLength(FPollItems, Length(FPollItems) + 1);
  P := @FPollItems[Length(FPollItems) - 1];
  P.socket := (Pair as TZMQPair).FSocket;
  P.fd := 0;
  P.events := Byte(Events);
  P.revents := 0;

  SetLength(FPollEvents, Length(FPollEvents) + 1);
  FPollEvents[Length(FPollEvents) - 1] := Event;
end;

function TZMQPoll.PollOnce(Timeout: Integer): Integer;
begin
  Result := zmq_poll(@FPollItems[0], Length(FPollItems), Timeout);
end;

procedure TZMQPoll.FireEvents;
var
  I: Integer;
begin
  for I := 0 to Length(FPollItems) - 1 do
    if (FPollEvents[I] <> nil) and ((FPollItems[I].revents and FPollItems[I].events) <> 0) then
      FPollEvents[I](PollEvents(Byte(FPollItems[I].revents)));
end;

end.
