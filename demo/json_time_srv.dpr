program json_time_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows, System.SysUtils, ZeroMQ, SuperObject;

var
  Stopped: Boolean;

procedure Run;
var
  Z: IZeroMQ;
  Sender: IZMQPair;
  Json: ISuperObject;
  S: string;
  I: Integer;
begin
  Z := TZeroMQ.Create;
  Sender := Z.Start(ZMQSocket.Publisher);
  Sender.Bind('tcp://*:5550');
  Writeln('Started time server (TCP/5550)...');

  Json := SO(['date', '', 'time', '', 'garbage', '']);

  while not Stopped do
  begin
    SetLength(S, 1000000);
    for I := 1 to 1000000 do
      S[I] := Char(Random(26) + Ord('A'));

    Json.S['date']    := DateTimeToStr(Now);
    Json.I['time']    := DelphiToJavaDateTime(Now);
    Json.S['garbage'] := S;

    S := Json.AsString;
    Sender.SendStrings(['application/json', S]);
  end;
end;

function CatchQuitSignal(CtrlType: DWORD): BOOL; stdcall;
begin
  if CtrlType = CTRL_C_EVENT then
  begin
    WriteLn('Terminating server...');
    Stopped := True;
    Result := True
  end
  else
    Result := False;
end;

begin
  try
    SetConsoleCtrlHandler(@CatchQuitSignal, True);
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
