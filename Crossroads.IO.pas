(*
    Unit owner :
       Pierr Yager <pierre.y@gmail.com>
*)

unit Crossroads.IO;

interface

uses
  Generics.Collections,
  Crossroads.IO.API;

type
  XSocket = (
    Pair,
    Publisher, Subscriber,
    Requester, Responder,
    Dealer, Router,
    Pull, Push,
    XPublisher, XSubscriber,
    Surveyor, Respondent,
    XSurveyor, XRespondent
  );

  MessageFlag = (DontWait, SendMore);
  MessageFlags = set of MessageFlag;

  IXSPair = interface
  ['{7F6D7BE5-7182-4972-96E1-4B5798608DDE}']
    { Server pair }
    function Bind(const Address: string): Integer;
    { Client pair }
    function Connect(const Address: string): Integer;
    { Socket Options }
    function SocketType: XSocket;
    { Required for XS.Subscriber pair }
    function Subscribe(const Filter: string): Integer;
    function HaveMore: Boolean;
    { Raw messages }
    function SendMessage(var Msg: TXSMsg; Flags: MessageFlags): Integer;
    function ReceiveMessage(var Msg: TXSMsg; Flags: MessageFlags): Integer;
    { Simple string message }
    function SendString(const Data: string; Flags: MessageFlags): Integer; overload;
    function SendString(const Data: string; DontWait: Boolean = False): Integer; overload;
    function ReceiveString(DontWait: Boolean = False): string;
    { Multipart string message }
    function SendStrings(const Data: array of string; DontWait: Boolean = False): Integer;
    function ReceiveStrings(const DontWait: Boolean = False): TArray<string>;
    { High Level Algorithgms - Forward message to another pair }
    procedure ForwardMessage(Pair: IXSPair);
  end;

  PollEvent = (PollIn, PollOut, PollErr);
  PollEvents = set of PollEvent;

  TXSPollEvent = reference to procedure (Events: PollEvents);

  IXSPoll = interface
    procedure RegisterPair(const Pair: IXSPair; Events: PollEvents = []; const Proc: TXSPollEvent = nil);
    function PollOnce(Timeout: Integer = -1): Integer;
    procedure FireEvents;
  end;

  XDevice = (
    Queue, Forwarder, Streamer
  );

  ICrossroads = interface
    ['{593FC079-23AD-451E-8877-11584E93D80E}']
    function Start(Kind: XSocket): IXSPair;
    procedure PollEmulatedDevice(Kind: XDevice; Frontend, Backend: IXSPair);
    function Poller: IXSPoll;
    function InitMessage(var Msg: TXSMsg; Size: Integer = 0): Integer;
    function CloseMessage(var Msg: TXSMsg): Integer;
  end;

  TCrossroads = class(TInterfacedObject, ICrossroads)
  private
    FContext: Pointer;
    FPairs: TList<IXSPair>;
  public
    constructor Create;
    destructor Destroy; override;
    function Start(Kind: XSocket): IXSPair;
    procedure PollEmulatedDevice(Kind: XDevice; Frontend, Backend: IXSPair);
    function Poller: IXSPoll;
    function InitMessage(var Msg: TXSMsg; Size: Integer = 0): Integer;
    function CloseMessage(var Msg: TXSMsg): Integer;
  end;

implementation

type
  TXSPair = class(TInterfacedObject, IXSPair)
  private
    FSocket: Pointer;
  public
    constructor Create(Socket: Pointer);
    destructor Destroy; override;
    { Server pair }
    function Bind(const Address: string): Integer;
    { Client pair }
    function Connect(const Address: string): Integer;
    { Required for XS.Subscriber pair }
    function Subscribe(const Filter: string): Integer;
    function HaveMore: Boolean;
    { Socket Options }
    function SocketType: XSocket;
    { Raw messages }
    function SendMessage(var Msg: TXSMsg; Flags: MessageFlags): Integer;
    function ReceiveMessage(var Msg: TXSMsg; Flags: MessageFlags): Integer;
    { Simple string message }
    function SendString(const Data: string; Flags: MessageFlags): Integer; overload;
    function SendString(const Data: string; DontWait: Boolean = False): Integer; overload;
    function ReceiveString(DontWait: Boolean = False): string;
    { Multipart string message }
    function SendStrings(const Data: array of string; DontWait: Boolean = False): Integer;
    function ReceiveStrings(const DontWait: Boolean = False): TArray<string>;
    { High Level Algorithgms - Forward message to another pair }
    procedure ForwardMessage(Pair: IXSPair);
  end;

  TXSPoll = class(TInterfacedObject, IXSPoll)
  private
    FPollItems: TArray<TXSPollItem>;
    FPollEvents: TArray<TXSPollEvent>;
  public
    procedure RegisterPair(const Pair: IXSPair; Events: PollEvents = []; const Event: TXSPollEvent = nil);
    function PollOnce(Timeout: Integer = -1): Integer;
    procedure FireEvents;
  end;

{ TCrossroads }

constructor TCrossroads.Create;
begin
  inherited Create;
  FPairs := TList<IXSPair>.Create;
  FContext := xs_init;
end;

destructor TCrossroads.Destroy;
begin
  FPairs.Free;
  xs_term(FContext);
  inherited;
end;

function TCrossroads.Start(Kind: XSocket): IXSPair;
begin
  Result := TXSPair.Create(xs_socket(FContext, Ord(Kind)));
  FPairs.Add(Result);
end;

procedure TCrossroads.PollEmulatedDevice(Kind: XDevice; Frontend,
  Backend: IXSPair);
const
  R_OR_D = [XSocket.Router, XSocket.Dealer];
  P_OR_S = [XSocket.Publisher, XSocket.Subscriber];
  P_OR_P = [XSocket.Push, XSocket.Pull];
var
  P: IXSPoll;
  FST, BST: XSocket;
begin
  FST := Frontend.SocketType;
  BST := Backend.SocketType;
  if   ((Kind = XDevice.Queue)     and (FST <> BST) and (FST in R_OR_D) and (BST in R_OR_D))
    or ((Kind = XDevice.Forwarder) and (FST <> BST) and (FST in P_OR_S) and (BST in P_OR_S))
    or ((Kind = XDevice.Streamer)  and (FST <> BST) and (FST in P_OR_P) and (BST in P_OR_P))
  then
  begin
    P := Poller;

    P.RegisterPair(Frontend, [PollEvent.PollIn],
      procedure(Event: PollEvents)
      begin
        if PollEvent.PollIn in Event then
          Frontend.ForwardMessage(Backend);
      end
    );

    P.RegisterPair(Backend, [PollEvent.PollIn],
      procedure(Event: PollEvents)
      begin
        if PollEvent.PollIn in Event then
          Backend.ForwardMessage(Frontend);
      end
    );

    while True do
      if P.PollOnce > 0 then
        P.FireEvents;
  end;
end;

function TCrossroads.InitMessage(var Msg: TXSMsg; Size: Integer): Integer;
begin
  if Size = 0 then
    Result := xs_msg_init(@Msg)
  else
    Result := xs_msg_init_size(@Msg, Size)
end;

function TCrossroads.Poller: IXSPoll;
begin
  Result := TXSPoll.Create;
end;

function TCrossroads.CloseMessage(var Msg: TXSMsg): Integer;
begin
  Result := xs_msg_close(@Msg);
end;

{ TXSPair }

constructor TXSPair.Create(Socket: Pointer);
begin
  inherited Create;
  FSocket := Socket;
end;

destructor TXSPair.Destroy;
begin
  xs_close(FSocket);
  inherited;
end;

function TXSPair.Bind(const Address: string): Integer;
begin
  Result := xs_bind(FSocket, PAnsiChar(AnsiString(Address)));
end;

function TXSPair.Connect(const Address: string): Integer;
begin
  Result := xs_connect(FSocket, PAnsiChar(AnsiString(Address)));
end;

function TXSPair.Subscribe(const Filter: string): Integer;
var
  str: UTF8String;
begin
  str := UTF8String(Filter);
  Result := xs_setsockopt(FSocket, XS_SUBSCRIBE, PAnsiChar(str), Length(str));
end;

function TXSPair.HaveMore: Boolean;
var
  more: Integer;
  more_size: Cardinal;
begin
  more_size := SizeOf(more);
  xs_getsockopt(FSocket, XS_RCVMORE, @more, @more_size);
  Result := more > 0;
end;

function TXSPair.ReceiveMessage(var Msg: TXSMsg;
  Flags: MessageFlags): Integer;
begin
  Result := xs_recvmsg(FSocket, @Msg, Byte(Flags));
end;

function TXSPair.ReceiveString(DontWait: Boolean): string;
var
  msg: TXSMsg;
  str: UTF8String;
  len: Cardinal;
begin
  xs_msg_init(@msg);
  if xs_recvmsg(FSocket, @msg, Ord(DontWait)) = 0 then
    Exit('');

  len := xs_msg_size(@msg);
  SetLength(str, len);
  Move(xs_msg_data(@msg)^, PAnsiChar(str)^, len);
  xs_msg_close(@msg);
  Result := string(str);
end;

function TXSPair.ReceiveStrings(const DontWait: Boolean): TArray<string>;
var
  L: TList<string>;
begin
  L := TList<string>.Create;
  try
    repeat
      L.Add(ReceiveString(DontWait));
    until not HaveMore;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TXSPair.SendMessage(var Msg: TXsMsg; Flags: MessageFlags): Integer;
begin
  Result := xs_sendmsg(FSocket, @Msg, Byte(Flags));
end;

function TXSPair.SendString(const Data: string; Flags: MessageFlags): Integer;
var
  msg: TXsMsg;
  str: UTF8String;
  len: Integer;
begin
  str := UTF8String(Data);
  len := Length(str);
  Result := xs_msg_init_size(@msg, len);
  if Result = 0 then
  begin
    Move(PAnsiChar(str)^, xs_msg_data(@msg)^, len);
    Result := SendMessage(msg, Flags);
    xs_msg_close(@msg);
  end;
end;

function TXSPair.SendString(const Data: string; DontWait: Boolean): Integer;
begin
  Result := SendString(Data, MessageFlags(Ord(DontWait)));
end;

function TXSPair.SendStrings(const Data: array of string;
  DontWait: Boolean): Integer;
var
  I: Integer;
  Flags: MessageFlags;
begin
  Result := 0;
  if Length(Data) = 1 then
    Result := SendString(Data[0], DontWait)
  else
  begin
    Flags := [MessageFlag.SendMore] + MessageFlags(Ord(DontWait));
    for I := Low(Data) to High(Data) do
    begin
      if I = High(Data) then
        Exclude(Flags, MessageFlag.SendMore);
      Result := SendString(Data[I], Flags);
      if Result < 0 then
        Break;
    end;
  end;
end;

function TXSPair.SocketType: XSocket;
var
  RawType: Integer;
  OptionSize: Integer;
begin
  RawType := 0;
  OptionSize := SizeOf(RawType);
  xs_getsockopt(FSocket, XS_TYPE, @RawType, @OptionSize);
  Result := XSocket(RawType)
end;

procedure TXSPair.ForwardMessage(Pair: IXSPair);
const
  SEND_FLAGS: array[Boolean] of Byte = (0, XS_SNDMORE);
var
  msg: TXSMsg;
  flag: Byte;
begin
  repeat
    xs_msg_init(@msg);
    xs_recvmsg(FSocket, @msg, 0);
    flag := SEND_FLAGS[HaveMore];
    xs_sendmsg((Pair as TXSPair).FSocket, @msg, flag);
    xs_msg_close(@msg);
  until flag = 0;
end;

{ TXSPoll }

procedure TXSPoll.RegisterPair(const Pair: IXSPair; Events: PollEvents;
  const Event: TXSPollEvent);
var
  P: PXSPollItem;
begin
  SetLength(FPollItems, Length(FPollItems) + 1);
  P := @FPollItems[Length(FPollItems) - 1];
  P.socket := (Pair as TXSPair).FSocket;
  P.fd := 0;
  P.events := Byte(Events);
  P.revents := 0;

  SetLength(FPollEvents, Length(FPollEvents) + 1);
  FPollEvents[Length(FPollEvents) - 1] := Event;
end;

function TXSPoll.PollOnce(Timeout: Integer): Integer;
begin
  Result := xs_poll(@FPollItems[0], Length(FPollItems), Timeout);
end;

procedure TXSPoll.FireEvents;
var
  I: Integer;
begin
  for I := 0 to Length(FPollItems) - 1 do
    if (FPollEvents[I] <> nil) and ((FPollItems[I].revents and FPollItems[I].events) <> 0) then
      FPollEvents[I](PollEvents(Byte(FPollItems[I].revents)));
end;

end.
