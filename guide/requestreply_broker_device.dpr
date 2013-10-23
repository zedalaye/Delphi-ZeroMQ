program requestreply_broker_device;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  madExcept,
  System.SysUtils, ZeroMQ;

procedure Run;
var
  Z: IZeroMQ;
  Frontend, Backend: IZMQPair;
begin
  Z := TZeroMQ.Create;

  Frontend := Z.Start(ZMQSocket.Router);
  Frontend.Bind('tcp://*:5559');

  Backend := Z.Start(ZMQSocket.Dealer);
  Backend.Bind('tcp://*:5560');

  Z.StartProxy(Frontend, Backend);
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
