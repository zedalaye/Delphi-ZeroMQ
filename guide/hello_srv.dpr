program hello_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, zeromq;

var
  Z: IZeroMQ;
  R: IZMQPair;
  S: string;
begin
  try
    Z := TZeroMQ.Create(1);
    R := Z.Start(ZMQ.Responder);
    WriteLn('Starting Hello World Server');
    R.Bind('tcp://*:5555');
    repeat
      S := R.ReceiveString;
      WriteLn('Received ', S);
      Sleep(10);
      WriteLn(' Sending World');
      R.SendString('World');
    until False;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
