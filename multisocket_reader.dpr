program multisocket_reader;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, zeromq;

procedure Run;
var
  Z: IZeroMQ;
  Receiver, Subscriber: IZMQPair;
  RC: Integer;
  task: string;
  update: TZmqMsg;
begin
  Z := TZeroMQ.Create;
  Receiver := Z.Start(ZMQ.Pull);
  RC := Receiver.Connect('tcp://localhost:5557');

  Subscriber := Z.Start(ZMQ.Subscriber);
  RC := Subscriber.Connect('tcp://localhost:5556');
  RC := Subscriber.Subscribe('10001 ');

  while True do
  begin
    task := '';
    repeat
      task := Receiver.ReceiveString([MessageFlag.DontWait]);
      if task <> '' then
      begin
        WriteLn('Process Task...');
        Sleep(10);
      end;
    until task = '';

    RC := 0;
    repeat
      RC := Z.InitMessage(update);
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
