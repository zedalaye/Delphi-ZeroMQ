program demo_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows, System.SysUtils, ZeroMQ.Wrapper, SuperObject;

var
  Stopped: Boolean;

procedure Run;
var
  Z: IZeroMQ;
  Sender: IZMQPair;
  Json: ISuperObject;
begin
  Z := TZeroMQ.Create;
  Sender := Z.Start(ZMQ.Publisher);
  Sender.Bind('tcp://*:5550');
  Writeln('Started time server (TCP/5550)...');

  Json := SO(['time', '']);

  while not Stopped do
  begin
    Json.I['time'] := DelphiToJavaDateTime(Now);
    Sender.SendString(Json.AsString);
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
