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

  { For now, as long as I can only compile libzmq 3.1.0 beta on my Windows box,
    ZeroMQ devices are emulated by ZeroMQ.Wrapper with IZMQPoll and by forwarding
    messages between Frontend and Backend the two directions }

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
