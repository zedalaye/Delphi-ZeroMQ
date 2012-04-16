program requestreply_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, ZeroMQ.Wrapper;

procedure Run;
var
  Z: IZeroMQ;
  Responder: IZMQPair;
  Request: string;
begin
  Z := TZeroMQ.Create;
  Responder := Z.Start(ZMQ.Responder);
  Responder.Connect('tcp://localhost:5560');

  while True do
  begin
    Request := Responder.ReceiveString;
    WriteLn('Received request: [', Request, ']');
    Sleep(1);
    Responder.SendString('World');
  end;
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
