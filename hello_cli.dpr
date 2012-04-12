program hello_cli;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, zeromq;


procedure doit;
var
  Z: IZeroMQ;
  R: IZMQPair;
  request_nbr: Integer;
  S: string;
begin
  try
    Z := TZeroMQ.Create(1);
    R := Z.Start(ZMQ.Requester);
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
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end;

begin
  doit;
end.
