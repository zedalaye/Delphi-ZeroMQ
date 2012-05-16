program requestreply_broker;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, ZeroMQ;

procedure Run;
var
  Z: IZeroMQ;
  Frontend, Backend: IZMQPair;
  Poller: IZMQPoll;
begin
  Z := TZeroMQ.Create;

  Frontend := Z.Start(ZMQSocket.Router);
  Frontend.Bind('tcp://*:5559');

  Backend := Z.Start(ZMQSocket.Dealer);
  Backend.Bind('tcp://*:5560');

  Poller := Z.Poller;

  Poller.RegisterPair(Frontend, [PollEvent.PollIn],
    procedure(Event: PollEvents)
    begin
      if PollEvent.PollIn in Event then
        Frontend.ForwardMessage(Backend);
    end
  );

  Poller.RegisterPair(Backend, [PollEvent.PollIn],
    procedure(Event: PollEvents)
    begin
      if PollEvent.PollIn in Event then
        Backend.ForwardMessage(Frontend);
    end
  );

  while True do
    if Poller.PollOnce > 0 then
      Poller.FireEvents;
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
