program requestreply_cli;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, ZeroMQ.Wrapper;

procedure Run;
var
  Z: IZeroMQ;
  Requester: IZMQPair;
  RequestCount: Integer;
  Reply: string;
begin
  Z := TZeroMQ.Create;
  Requester := Z.Start(ZMQ.Requester);
  Requester.Connect('tcp://localhost:5559');

  RequestCount := 0;
  while RequestCount < 10 do
  begin
    Inc(RequestCount);
    Requester.SendString('Hello');
    Reply := Requester.ReceiveString;
    WriteLn(Format('Received reply %2d [%s]', [RequestCount, Reply]));
  end;
end;

begin
  try
    Run;
    WriteLn;
    WriteLn('Press a key to continue...');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
