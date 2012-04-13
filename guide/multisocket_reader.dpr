program multisocket_reader;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, ZeroMQ.API, ZeroMQ.Wrapper;

procedure Run;
var
  Z: IZeroMQ;
  Receiver, Subscriber: IZMQPair;
  RC: Integer;
  task, update: TZmqMsg;
begin
  Z := TZeroMQ.Create;
  Receiver := Z.Start(ZMQ.Pull);
  Receiver.Connect('tcp://localhost:5557');

  Subscriber := Z.Start(ZMQ.Subscriber);
  Subscriber.Connect('tcp://localhost:5556');
  Subscriber.Subscribe('10001 ');

  while True do
  begin
    repeat
      Z.InitMessage(task);
      RC := Receiver.ReceiveMessage(task, [MessageFlag.DontWait]);
      if RC = 0 then
      begin
        WriteLn('Process Task...');
        Sleep(10);
      end
      else if RC = -1 then
        WriteLn('Error code : ', zmq_errno);
      Z.CloseMessage(task);
    until RC <> 0;

    repeat
      Z.InitMessage(update);
      RC := Subscriber.ReceiveMessage(update, [MessageFlag.DontWait]);
      if RC = 0 then
      begin
        WriteLn('Process Weather Update...');
        Sleep(10);
      end
      else if RC = -1 then
        WriteLn('Error code : ', zmq_errno);
      Z.CloseMessage(update);
    until RC <> 0;

    Sleep(1);
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
