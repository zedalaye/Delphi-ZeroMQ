program requestreply_broker_device;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, ZeroMQ.Wrapper;

procedure Run;
var
  Z: IZeroMQ;
  Frontend, Backend: IZMQPair;
begin
  Z := TZeroMQ.Create;
  Frontend := Z.Start(ZMQ.Router);
  Frontend.Bind('tcp://*:5559');

  Backend := Z.Start(ZMQ.Dealer);
  Backend.Bind('tcp://*:5560');

  Z.StartDevice(ZMQDevice.Queue, Frontend, Backend);
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
