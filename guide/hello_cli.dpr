program hello_cli;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  madExcept,
  System.SysUtils, ZeroMQ;

procedure Run;
var
  Z: IZeroMQ;
  R: IZMQPair;
  request_nbr: Integer;
  S: string;
begin
  Z := TZeroMQ.Create;
  R := Z.Start(ZMQSocket.Requester);

  Writeln('Connecting to hello world server...');
  R.Connect('tcp://localhost:5555');

  request_nbr := 0;
  while request_nbr < 10 do
  begin
    Inc(request_nbr);
    WriteLn('Sending Hello');
    R.SendString('Hello');
    S := R.ReceiveString;
    WriteLn(' Received ', S);
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
